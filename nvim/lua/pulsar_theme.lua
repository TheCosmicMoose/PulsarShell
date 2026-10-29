-- pulsar_theme.lua
--
-- Reads the shell's current_theme.json and applies it as a Neovim colorscheme.
-- Put this file at ~/.config/nvim/lua/pulsar_theme.lua
--
-- Usage (init.lua):
--   require("pulsar_theme").setup()
--
-- Options (all optional):
--   transparent = true   -- leave the editor background unpainted so the
--                        -- terminal's opacity/blur shows through
--   watch       = true   -- re-apply automatically when the theme file changes
--   path        = "..."  -- override the theme file location

local M = {}

-- vim.uv exists on Neovim 0.10+; older versions call it vim.loop.
local uv = vim.uv or vim.loop

M.opts = {
  transparent = true,
  watch = true,
  path = nil,
}

local function notify(msg)
  vim.notify("pulsar_theme: " .. msg, vim.log.levels.WARN)
end

-- Same location the Go program writes to (os.UserConfigDir()).
local function theme_path()
  if M.opts.path then
    return M.opts.path
  end
  local base = vim.env.XDG_CONFIG_HOME
  if base == nil or base == "" then
    base = vim.env.HOME .. "/.config"
  end
  return base .. "/pulsar_shell_theme/current_theme.json"
end

-- Read the file and decode the JSON. Returns the decoded table, or nil and a
-- message describing what went wrong.
local function load(path)
  local f, err = io.open(path, "r")
  if not f then
    return nil, "cannot open " .. path .. " (" .. tostring(err) .. ")"
  end
  local text = f:read("*a")
  f:close()

  local ok, data = pcall(vim.json.decode, text)
  if not ok then
    return nil, "invalid JSON in " .. path .. ": " .. tostring(data)
  end
  if type(data) ~= "table" or type(data.colors) ~= "table" then
    return nil, path .. " has no \"colors\" section"
  end
  return data
end

-- Wrap the colors table so that asking for a color that doesn't exist raises
-- a clear error instead of silently returning nil.
local function strict(colors)
  return setmetatable({}, {
    __index = function(_, key)
      local v = colors[key]
      if v == nil then
        error('theme is missing color "' .. key .. '"', 0)
      end
      return v
    end,
  })
end

-- build maps theme colors onto highlight groups. This is the part to edit if
-- you want to change which color goes where. Returns the highlight table and
-- the 16 colors for Neovim's built-in :terminal.
local function build(c, opts)
  -- The editor background. NONE lets the terminal's opacity show through.
  local base = opts.transparent and "NONE" or c.bgPrimary

  local g = {
    -- Editor
    Normal = { fg = c.textPrimary, bg = base },
    NormalNC = { link = "Normal" },
    NormalFloat = { fg = c.textPrimary, bg = c.bgModule },
    FloatBorder = { fg = c.accentGray, bg = c.bgModule },
    FloatTitle = { fg = c.highlightOrange, bg = c.bgModule, bold = true },
    SignColumn = { bg = base },
    EndOfBuffer = { fg = c.bgModule, bg = base },
    NonText = { fg = c.bgModule },
    Whitespace = { fg = c.bgModule },
    LineNr = { fg = c.accentGray, bg = base },
    CursorLine = { bg = c.bgSecondary },
    CursorLineNr = { fg = c.highlightYellow, bg = c.bgSecondary, bold = true },
    ColorColumn = { bg = c.bgSecondary },
    Folded = { fg = c.highlightGray, bg = c.bgSecondary },
    FoldColumn = { fg = c.accentGray, bg = base },
    WinSeparator = { fg = c.accentGray, bg = base },
    VertSplit = { link = "WinSeparator" },
    MatchParen = { fg = c.highlightOrange, bg = c.bgModule, bold = true },

    -- Selection and search
    Visual = { fg = c.selectionFg, bg = c.selectionBg },
    VisualNOS = { link = "Visual" },
    Search = { fg = c.bgPrimary, bg = c.highlightYellow },
    IncSearch = { fg = c.bgPrimary, bg = c.highlightOrange },
    CurSearch = { link = "IncSearch" },
    Substitute = { fg = c.bgPrimary, bg = c.highlightRed },

    -- Menus, statusline, tabline
    Pmenu = { fg = c.textPrimary, bg = c.bgModule },
    PmenuSel = { fg = c.selectionFg, bg = c.selectionBg },
    PmenuSbar = { bg = c.bgSecondary },
    PmenuThumb = { bg = c.accentGray },
    WildMenu = { link = "PmenuSel" },
    StatusLine = { fg = c.textPrimary, bg = c.bgModule },
    StatusLineNC = { fg = c.highlightGray, bg = c.bgSecondary },
    TabLine = { fg = c.highlightGray, bg = c.bgSecondary },
    TabLineSel = { fg = c.highlightOrange, bg = c.bgModule, bold = true },
    TabLineFill = { bg = c.bgSecondary },

    -- Messages
    ErrorMsg = { fg = c.highlightRed, bold = true },
    WarningMsg = { fg = c.highlightYellow },
    MoreMsg = { fg = c.highlightGreen },
    ModeMsg = { fg = c.highlightYellow, bold = true },
    Question = { fg = c.highlightGreen },
    Title = { fg = c.highlightOrange, bold = true },
    Directory = { fg = c.highlightBlue },

    -- Syntax (Neovim's treesitter and LSP groups link to these by default)
    Comment = { fg = c.highlightGray, italic = true },
    Constant = { fg = c.highlightPurple },
    String = { fg = c.highlightGreen },
    Character = { link = "String" },
    Number = { link = "Constant" },
    Boolean = { link = "Constant" },
    Float = { link = "Constant" },
    Identifier = { fg = c.textPrimary },
    Function = { fg = c.highlightBlue },
    Statement = { fg = c.highlightRed },
    Conditional = { link = "Statement" },
    Repeat = { link = "Statement" },
    Label = { link = "Statement" },
    Keyword = { link = "Statement" },
    Exception = { link = "Statement" },
    Operator = { fg = c.textSecondary },
    PreProc = { fg = c.highlightAqua },
    Include = { link = "PreProc" },
    Define = { link = "PreProc" },
    Macro = { link = "PreProc" },
    PreCondit = { link = "PreProc" },
    Type = { fg = c.highlightYellow },
    StorageClass = { link = "Type" },
    Structure = { link = "Type" },
    Typedef = { link = "Type" },
    Special = { fg = c.highlightOrange },
    SpecialChar = { link = "Special" },
    Tag = { link = "Special" },
    Delimiter = { fg = c.textSecondary },
    SpecialComment = { link = "Special" },
    Debug = { link = "Special" },
    Underlined = { fg = c.highlightBlue, underline = true },
    Error = { fg = c.highlightRed },
    Todo = { fg = c.bgPrimary, bg = c.highlightYellow, bold = true },

    -- Diagnostics
    DiagnosticError = { fg = c.highlightRed },
    DiagnosticWarn = { fg = c.highlightYellow },
    DiagnosticInfo = { fg = c.highlightBlue },
    DiagnosticHint = { fg = c.highlightAqua },
    DiagnosticOk = { fg = c.highlightGreen },
    DiagnosticUnderlineError = { undercurl = true, sp = c.highlightRed },
    DiagnosticUnderlineWarn = { undercurl = true, sp = c.highlightYellow },
    DiagnosticUnderlineInfo = { undercurl = true, sp = c.highlightBlue },
    DiagnosticUnderlineHint = { undercurl = true, sp = c.highlightAqua },
    SpellBad = { undercurl = true, sp = c.highlightRed },
    SpellCap = { undercurl = true, sp = c.highlightYellow },
    SpellLocal = { undercurl = true, sp = c.highlightBlue },
    SpellRare = { undercurl = true, sp = c.highlightPurple },

    -- Diffs and git
    DiffAdd = { fg = c.highlightGreen, bg = c.bgModule },
    DiffChange = { fg = c.highlightYellow, bg = c.bgSecondary },
    DiffDelete = { fg = c.highlightRed, bg = c.bgModule },
    DiffText = { fg = c.bgPrimary, bg = c.highlightYellow },
    Added = { fg = c.highlightGreen },
    Changed = { fg = c.highlightYellow },
    Removed = { fg = c.highlightRed },
  }

  -- Colors for :terminal buffers, same layout as the kitty ANSI mapping.
  local term = {
    c.bgPrimary, c.highlightRed, c.highlightGreen, c.highlightYellow,
    c.highlightBlue, c.highlightPurple, c.highlightAqua, c.textSecondary,
    c.highlightGray, c.highlightRed, c.highlightGreen, c.highlightYellow,
    c.highlightBlue, c.highlightPurple, c.highlightAqua, c.textPrimary,
  }

  return g, term
end

-- apply reads the theme file and applies it. If anything is wrong with the
-- file, it warns and leaves the current colors alone.
function M.apply()
  local data, err = load(theme_path())
  if not data then
    notify(err)
    return false
  end

  -- Build everything first. If a color is missing this fails here, before we
  -- clear any existing highlights.
  local ok, groups, term = pcall(build, strict(data.colors), M.opts)
  if not ok then
    notify(groups) -- on failure, pcall's second value is the error message
    return false
  end

  vim.cmd("highlight clear")
  if vim.fn.exists("syntax_on") == 1 then
    vim.cmd("syntax reset")
  end
  vim.o.termguicolors = true
  vim.o.background = "dark"
  vim.g.colors_name = "pulsar"

  for name, attrs in pairs(groups) do
    vim.api.nvim_set_hl(0, name, attrs)
  end
  for i, color in ipairs(term) do
    vim.g["terminal_color_" .. (i - 1)] = color
  end

  -- Let plugins that react to colorscheme changes (statuslines, etc.) refresh.
  vim.api.nvim_exec_autocmds("ColorScheme", { pattern = "pulsar", modeline = false })
  return true
end

local watcher = nil
local pending = false

-- watch re-applies the theme whenever the file changes.
--
-- The Go program replaces the file with an atomic rename, which swaps in a
-- brand new file. Watching the file itself would stop working after the first
-- change, so we watch the directory and filter by file name.
function M.watch()
  if watcher then
    return
  end
  local path = theme_path()
  local dir, file = vim.fs.dirname(path), vim.fs.basename(path)

  local w = uv.new_fs_event()
  if not w then
    return
  end
  -- start() fails if the directory doesn't exist yet (the theme program hasn't
  -- run). In that case we quietly skip watching.
  local started = w:start(dir, {}, function(werr, filename)
    if werr or filename ~= file then
      return
    end
    -- This callback runs outside the main loop, so hand off to the main loop.
    vim.schedule(function()
      if pending then
        return
      end
      pending = true
      -- One save can produce several events; wait briefly and apply once.
      vim.defer_fn(function()
        pending = false
        M.apply()
      end, 100)
    end)
  end)
  if started == 0 or started == true then
    watcher = w
  else
    w:close()
  end
end

function M.setup(opts)
  M.opts = vim.tbl_extend("force", M.opts, opts or {})
  M.apply()
  if M.opts.watch then
    M.watch()
  end
end

return M
