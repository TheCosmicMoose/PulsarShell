// pulsar-btagent is a BlueZ pairing agent for the Quickshell Bluetooth flyout.
//
// BlueZ asks the default agent to show or confirm PINs and passkeys while
// pairing. This program registers as that agent and forwards every request to
// Quickshell, which shows it in the Bluetooth flyout and writes the answer back.
//
// Protocol (one message per line):
//
//	stdout -> Quickshell, JSON:
//	  {"id":3,"type":"confirm","device":"/org/bluez/hci0/dev_..","name":"Pixel 8","passkey":"012345"}
//	  type is one of:
//	    confirm        - does the passkey match the one on the device?  answer yes/no
//	    authorize      - allow this device to pair (no passkey)?        answer yes/no
//	    pin            - type the PIN shown on / used by the device      answer the PIN
//	    passkey        - type the 6-digit passkey shown on the device    answer the number
//	    display-pin    - show this PIN; the user types it on the device  (no answer)
//	    display-passkey- show this passkey; type it on the device        (no answer)
//	    cancel         - BlueZ cancelled the request with this id (id 0: all)
//	    ready          - the agent is registered
//
//	stdin <- Quickshell:
//	  "<id> <answer>"   e.g. "3 yes", "4 0000", "5 no"
//
// The agent exits when stdin closes (Quickshell quit or restarted it).
package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/godbus/dbus/v5"
)

const (
	agentPath  = dbus.ObjectPath("/org/pulsar/btagent")
	agentIface = "org.bluez.Agent1"
	// KeyboardDisplay: we can both show a passkey and let the user type one,
	// which lets BlueZ pick the most secure method the other device supports.
	capability = "KeyboardDisplay"
	// How long to wait for the user before rejecting. BlueZ gives up on its own
	// side after a while too.
	answerTimeout = 90 * time.Second
)

var (
	errRejected = dbus.NewError("org.bluez.Error.Rejected", []interface{}{"Rejected by user"})
	errCanceled = dbus.NewError("org.bluez.Error.Canceled", []interface{}{"Canceled"})
)

type message struct {
	ID      int    `json:"id"`
	Type    string `json:"type"`
	Device  string `json:"device,omitempty"`
	Name    string `json:"name,omitempty"`
	Passkey string `json:"passkey,omitempty"`
	Pin     string `json:"pin,omitempty"`
}

type agent struct {
	conn *dbus.Conn

	mu      sync.Mutex
	nextID  int
	pending map[int]chan string
	out     *json.Encoder
}

func (a *agent) send(m message) {
	a.mu.Lock()
	defer a.mu.Unlock()
	if err := a.out.Encode(m); err != nil {
		log.Printf("write: %v", err)
	}
}

// ask sends a request and waits for Quickshell's answer. ok is false if the
// request was cancelled or timed out.
func (a *agent) ask(m message) (answer string, ok bool) {
	ch := make(chan string, 1)
	a.mu.Lock()
	a.nextID++
	m.ID = a.nextID
	a.pending[m.ID] = ch
	a.mu.Unlock()

	a.send(m)

	defer func() {
		a.mu.Lock()
		delete(a.pending, m.ID)
		a.mu.Unlock()
	}()

	select {
	case ans, open := <-ch:
		return ans, open
	case <-time.After(answerTimeout):
		a.send(message{ID: m.ID, Type: "cancel"})
		return "", false
	}
}

// notify sends a request that needs no answer.
func (a *agent) notify(m message) {
	a.mu.Lock()
	a.nextID++
	m.ID = a.nextID
	a.mu.Unlock()
	a.send(m)
}

func (a *agent) answer(id int, value string) {
	a.mu.Lock()
	ch, found := a.pending[id]
	a.mu.Unlock()
	if found {
		ch <- value
	}
}

func (a *agent) cancelAll() {
	a.mu.Lock()
	for id, ch := range a.pending {
		close(ch)
		delete(a.pending, id)
	}
	a.mu.Unlock()
	a.send(message{ID: 0, Type: "cancel"})
}

// deviceName returns the device's alias, or its address if it has none.
func (a *agent) deviceName(dev dbus.ObjectPath) string {
	obj := a.conn.Object("org.bluez", dev)
	if v, err := obj.GetProperty("org.bluez.Device1.Alias"); err == nil {
		if s, ok := v.Value().(string); ok && s != "" {
			return s
		}
	}
	// /org/bluez/hci0/dev_AA_BB_CC_DD_EE_FF -> AA:BB:CC:DD:EE:FF
	p := string(dev)
	if i := strings.LastIndex(p, "/dev_"); i >= 0 {
		return strings.ReplaceAll(p[i+len("/dev_"):], "_", ":")
	}
	return p
}

func (a *agent) devicePaired(dev dbus.ObjectPath) bool {
	v, err := a.conn.Object("org.bluez", dev).GetProperty("org.bluez.Device1.Paired")
	if err != nil {
		return false
	}
	b, _ := v.Value().(bool)
	return b
}

func (a *agent) request(typ string, dev dbus.ObjectPath) message {
	return message{Type: typ, Device: string(dev), Name: a.deviceName(dev)}
}

// ---- org.bluez.Agent1 ----

func (a *agent) Release() *dbus.Error {
	a.cancelAll()
	return nil
}

func (a *agent) RequestPinCode(dev dbus.ObjectPath) (string, *dbus.Error) {
	ans, ok := a.ask(a.request("pin", dev))
	if !ok || ans == "" {
		return "", errRejected
	}
	return ans, nil
}

func (a *agent) DisplayPinCode(dev dbus.ObjectPath, pin string) *dbus.Error {
	m := a.request("display-pin", dev)
	m.Pin = pin
	a.notify(m)
	return nil
}

func (a *agent) RequestPasskey(dev dbus.ObjectPath) (uint32, *dbus.Error) {
	ans, ok := a.ask(a.request("passkey", dev))
	if !ok {
		return 0, errRejected
	}
	n, err := strconv.ParseUint(strings.TrimSpace(ans), 10, 32)
	if err != nil || n > 999999 {
		return 0, errRejected
	}
	return uint32(n), nil
}

func (a *agent) DisplayPasskey(dev dbus.ObjectPath, passkey uint32, entered uint16) *dbus.Error {
	// Called again as the user types on the device; only show it once.
	if entered > 0 {
		return nil
	}
	m := a.request("display-passkey", dev)
	m.Passkey = fmt.Sprintf("%06d", passkey)
	a.notify(m)
	return nil
}

func (a *agent) RequestConfirmation(dev dbus.ObjectPath, passkey uint32) *dbus.Error {
	m := a.request("confirm", dev)
	m.Passkey = fmt.Sprintf("%06d", passkey)
	if ans, ok := a.ask(m); !ok || ans != "yes" {
		return errRejected
	}
	return nil
}

func (a *agent) RequestAuthorization(dev dbus.ObjectPath) *dbus.Error {
	if ans, ok := a.ask(a.request("authorize", dev)); !ok || ans != "yes" {
		return errRejected
	}
	return nil
}

// AuthorizeService is called when a device connects to a profile on this
// machine. Paired devices are allowed; anything else is refused.
func (a *agent) AuthorizeService(dev dbus.ObjectPath, uuid string) *dbus.Error {
	if a.devicePaired(dev) {
		return nil
	}
	return errRejected
}

func (a *agent) Cancel() *dbus.Error {
	a.cancelAll()
	return nil
}

// ---- registration ----

func (a *agent) register() error {
	mgr := a.conn.Object("org.bluez", "/org/bluez")
	if err := mgr.Call("org.bluez.AgentManager1.RegisterAgent", 0, agentPath, capability).Err; err != nil {
		return fmt.Errorf("RegisterAgent: %w", err)
	}
	if err := mgr.Call("org.bluez.AgentManager1.RequestDefaultAgent", 0, agentPath).Err; err != nil {
		return fmt.Errorf("RequestDefaultAgent: %w", err)
	}
	return nil
}

func (a *agent) unregister() {
	a.conn.Object("org.bluez", "/org/bluez").Call("org.bluez.AgentManager1.UnregisterAgent", 0, agentPath)
}

// watchBluez re-registers the agent whenever bluetoothd (re)starts.
func (a *agent) watchBluez() {
	if err := a.conn.AddMatchSignal(
		dbus.WithMatchInterface("org.freedesktop.DBus"),
		dbus.WithMatchMember("NameOwnerChanged"),
		dbus.WithMatchArg(0, "org.bluez"),
	); err != nil {
		log.Printf("watch bluez: %v", err)
		return
	}
	signals := make(chan *dbus.Signal, 8)
	a.conn.Signal(signals)
	for sig := range signals {
		if sig.Name != "org.freedesktop.DBus.NameOwnerChanged" || len(sig.Body) < 3 {
			continue
		}
		if newOwner, _ := sig.Body[2].(string); newOwner != "" {
			// Give bluetoothd a moment to export its objects.
			time.Sleep(500 * time.Millisecond)
			if err := a.register(); err != nil {
				log.Printf("re-register: %v", err)
			} else {
				a.send(message{Type: "ready"})
			}
		}
	}
}

func main() {
	log.SetFlags(0)
	log.SetPrefix("pulsar-btagent: ")

	conn, err := dbus.ConnectSystemBus()
	if err != nil {
		log.Fatalf("system bus: %v", err)
	}
	defer conn.Close()

	a := &agent{
		conn:    conn,
		pending: map[int]chan string{},
		out:     json.NewEncoder(os.Stdout),
	}

	if err := conn.Export(a, agentPath, agentIface); err != nil {
		log.Fatalf("export: %v", err)
	}

	// bluetoothd may not be running yet (or at all); keep going either way
	// and register when it appears.
	if err := a.register(); err != nil {
		log.Printf("%v (will retry when bluetoothd starts)", err)
	} else {
		a.send(message{Type: "ready"})
	}
	go a.watchBluez()

	// Answers from Quickshell. EOF means Quickshell went away.
	in := bufio.NewScanner(os.Stdin)
	for in.Scan() {
		line := strings.TrimSpace(in.Text())
		idStr, value, _ := strings.Cut(line, " ")
		id, err := strconv.Atoi(idStr)
		if err != nil {
			log.Printf("bad answer %q", line)
			continue
		}
		a.answer(id, value)
	}

	a.cancelAll()
	a.unregister()
}
