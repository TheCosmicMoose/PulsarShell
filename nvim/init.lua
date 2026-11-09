--[[

-- ============================================================
-- SECTION 1: OPTIONS
-- Core Neovim settings, leaders, options
-- ============================================================
do
  -- Enable faster startup by caching compiled Lua modules
  vim.loader.enable()

  -- Set <space> as the leader key
  -- See `:help mapleader`
  --  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
  vim.g.mapleader = ' '
  vim.g.maplocalleader = ' '

  -- Set to true if you have a Nerd Font installed and selected in the terminal
  vim.g.have_nerd_font = true

  -- [[ Setting options ]]
  --  See `:help vim.o`
  -- NOTE: You can change these options as you wish!
  --  For more options, you can see `:help option-list`

  -- Make line numbers default
  vim.o.number = true
  -- You can also add relative line numbers, to help with jumping.
  --  Experiment for yourself to see if you like it!
  -- vim.o.relativenumber = true

  -- Enable mouse mode, can be useful for resizing splits for example!
  vim.o.mouse = 'a'

  -- Don't show the mode, since it's already in the status line
  vim.o.showmode = false

  -- Sync clipboard between OS and Neovim.
  --  Schedule the setting after `UiEnter` because it can increase startup-time.
  --  Remove this option if you want your OS clipboard to remain independent.
  --  See `:help 'clipboard'`
  vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)

  -- Enable break indent
  vim.o.breakindent = true

  -- Enable undo/redo changes even after closing and reopening a file
  vim.o.undofile = true

  -- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
  vim.o.ignorecase = true
  vim.o.smartcase = true

  -- Keep signcolumn on by default
  vim.o.signcolumn = 'yes'

  -- Decrease update time
  vim.o.updatetime = 250

  -- Decrease mapped sequence wait time
  vim.o.timeoutlen = 300

  -- Configure how new splits should be opened
  vim.o.splitright = true
  vim.o.splitbelow = true

  -- Sets how neovim will display certain whitespace characters in the editor.
  --  See `:help 'list'`
  --  and `:help 'listchars'`
  --
  --  Notice listchars is set using `vim.opt` instead of `vim.o`.
  --  It is very similar to `vim.o` but offers an interface for conveniently interacting with tables.
  --   See `:help lua-options`
  --   and `:help lua-guide-options`
  vim.o.list = true
  vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

  -- Preview substitutions live, as you type!
  vim.o.inccommand = 'split'

  -- Show which line your cursor is on
  vim.o.cursorline = true

  -- Minimal number of screen lines to keep above and below the cursor.
  vim.o.scrolloff = 10

  -- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
  -- instead raise a dialog asking if you wish to save the current file(s)
  -- See `:help 'confirm'`
  vim.o.confirm = true


-- ============================================================
-- SECTION 2: KEYMAPS & AUTOCMDS
-- basic keymaps, basic autocmds
-- ============================================================
do
  -- [[ Basic Keymaps ]]
  --  See `:help vim.keymap.set()`

  -- Clear highlights on search when pressing <Esc> in normal mode
  --  See `:help hlsearch`
  vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

  -- Diagnostic Config & Keymaps
  --  See `:help vim.diagnostic.Opts`
  vim.diagnostic.config {
    update_in_insert = false,
    severity_sort = true,
    float = { border = 'rounded', source = 'if_many' },
    underline = { severity = { min = vim.diagnostic.severity.WARN } },

    -- Can switch between these as you prefer
    virtual_text = true, -- Text shows up at the end of the line
    virtual_lines = false, -- Text shows up underneath the line, with virtual lines

    -- Auto open the float, so you can easily read the errors when jumping with `[d` and `]d`
    jump = {
      on_jump = function(_, bufnr)
        vim.diagnostic.open_float {
          bufnr = bufnr,
          scope = 'cursor',
          focus = false,
        }
      end,
    },
  }

  vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

  -- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
  -- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
  -- is not what someone will guess without a bit more experience.
  --
  -- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
  -- or just use <C-\><C-n> to exit terminal mode
  vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

  -- TIP: Disable arrow keys in normal mode
  vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
  vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
  vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
  vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

  -- Keybinds to make split navigation easier.
  --  Use CTRL+<hjkl> to switch between windows
  --
  --  See `:help wincmd` for a list of all window commands
  vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
  vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
  vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
  vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

  -- NOTE: Some terminals have colliding keymaps or are not able to send distinct keycodes
  -- vim.keymap.set("n", "<C-S-h>", "<C-w>H", { desc = "Move window to the left" })
  -- vim.keymap.set("n", "<C-S-l>", "<C-w>L", { desc = "Move window to the right" })
  -- vim.keymap.set("n", "<C-S-j>", "<C-w>J", { desc = "Move window to the lower" })
  -- vim.keymap.set("n", "<C-S-k>", "<C-w>K", { desc = "Move window to the upper" })

  -- [[ Basic Autocommands ]]
  --  See `:help lua-guide-autocommands`

  -- Highlight when yanking (copying) text
  --  Try it with `yap` in normal mode
  --  See `:help vim.hl.on_yank()`
  vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Highlight when yanking (copying) text',
    group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
    callback = function() vim.hl.on_yank() end,
  })
end

-- ============================================================
-- SECTION 3: PLUGIN MANAGER INTRO
-- vim.pack intro, build hooks
-- ============================================================
do
  -- [[ Intro to `vim.pack` ]]
  -- `vim.pack` is a new plugin manager built into Neovim,
  --  which provides a Lua interface for installing and managing plugins.
  --
  --  See `:help vim.pack`, `:help vim.pack-examples` or the
  --  excellent blog post from the creator of vim.pack and mini.nvim:
  --  https://echasnovski.com/blog/2026-03-13-a-guide-to-vim-pack
  --
  --  To inspect plugin state and pending updates, run
  --    :lua vim.pack.update(nil, { offline = true })
  --
  --  To update plugins, run
  --    :lua vim.pack.update()
  --
  --
  --  Throughout the rest of the config there will be examples
  --  of how to install and configure plugins using `vim.pack`.
  --
  --  In this section we set up some autocommands to run build
  --  steps for certain plugins after they are installed or updated.

  local function run_build(name, cmd, cwd)
    local result = vim.system(cmd, { cwd = cwd }):wait()
    if result.code ~= 0 then
      local stderr = result.stderr or ''
      local stdout = result.stdout or ''
      local output = stderr ~= '' and stderr or stdout
      if output == '' then output = 'No output from build command.' end
      vim.notify(('Build failed for %s:\n%s'):format(name, output), vim.log.levels.ERROR)
    end
  end

  -- This autocommand runs after a plugin is installed or updated and
  --  runs the appropriate build command for that plugin if necessary.
  --
  -- See `:help vim.pack-events`
  vim.api.nvim_create_autocmd('PackChanged', {
    callback = function(ev)
      local name = ev.data.spec.name
      local kind = ev.data.kind
      if kind ~= 'install' and kind ~= 'update' then return end

      if name == 'telescope-fzf-native.nvim' and vim.fn.executable 'make' == 1 then
        run_build(name, { 'make' }, ev.data.path)
        return
      end

      if name == 'LuaSnip' then
        if vim.fn.has 'win32' ~= 1 and vim.fn.executable 'make' == 1 then run_build(name, { 'make', 'install_jsregexp' }, ev.data.path) end
        return
      end

      if name == 'nvim-treesitter' then
        if not ev.data.active then vim.cmd.packadd 'nvim-treesitter' end
        vim.cmd 'TSUpdate'
        return
      end
    end,
  })
end

---Because most plugins are hosted on GitHub, you can use the helper
---function to have less repetition in the following sections.
---@param repo string
---@return string
local function gh(repo) return 'https://github.com/' .. repo end

  vim.pack.add({
      'https://github.com/nvim-treesitter/nvim-treesitter',
      'https://github.com/nvim-mini/mini.nvim',            -- if you use the mini.nvim suite
      -- 'https://github.com/nvim-mini/mini.icons',        -- if you use standalone mini plugins
      -- 'https://github.com/nvim-tree/nvim-web-devicons', -- if you prefer nvim-web-devicons
      'https://github.com/MeanderingProgrammer/render-markdown.nvim',
  })
  require('render-markdown').setup({}) -- only mandatory if you want to set custom options
-- ============================================================
-- SECTION 4: UI / CORE UX PLUGINS
-- guess-indent, gitsigns, which-key, colorscheme, todo-comments, mini modules
-- ============================================================
do
  -- [[ Installing and Configuring Plugins ]]
  --
  -- To install a plugin simply call `vim.pack.add` with its git url.
  -- This will download the default branch of the plugin, which will usually be `main` or `master`
  -- You can also have more advanced specs, which we will talk about later.
  --
  -- For most plugins its not enough to install them, you also need to call their `.setup()` to start them.
  --
  -- For example, lets say we want to install `guess-indent.nvim` - a plugin for
  -- automatically detecting and setting the indentation.
  --
  -- We first install it from https://github.com/NMAC427/guess-indent.nvim
  -- and then call its `setup()` function to start it with default settings.
  vim.pack.add { gh 'NMAC427/guess-indent.nvim' }
    require('guess-indent').setup {}

  require('render-markdown').setup({
        -- Whether markdown should be rendered by default.
        enabled = true,
        -- Vim modes that will show a rendered view of the markdown file, :h mode(), for all enabled
        -- components. Individual components can be enabled for other modes. Remaining modes will be
        -- unaffected by this plugin.
        render_modes = { 'n', 'c', 't' },
        -- Milliseconds that must pass before updating marks, updates occur.
        -- within the context of the visible window, not the entire buffer.
        debounce = 100,
        -- Pre configured settings that will attempt to mimic various target user experiences.
        -- User provided settings will take precedence.
        -- | obsidian | mimic Obsidian UI                                          |
        -- | lazy     | will attempt to stay up to date with LazyVim configuration |
        -- | none     | does nothing                                               |
        preset = 'none',
        -- The level of logs to write to file: vim.fn.stdpath('state') .. '/render-markdown.log'.
        -- Only intended to be used for plugin development / debugging.
        log_level = 'error',
        -- Print runtime of main update method.
        -- Only intended to be used for plugin development / debugging.
        log_runtime = false,
        -- Filetypes this plugin will run on.
        file_types = { 'markdown' },
        -- Maximum file size (in MB) that this plugin will attempt to render.
        -- File larger than this will effectively be ignored.
        max_file_size = 10.0,
        -- Takes buffer as input, if it returns true this plugin will not attach to the buffer.
        ignore = function()
            return false
        end,
        -- Whether markdown should be rendered when nested inside markdown, i.e. markdown code block
        -- inside markdown file.
        nested = true,
        -- Additional events that will trigger this plugin's render loop.
        change_events = {},
        -- Whether the treesitter highlighter should be restarted after this plugin attaches to its
        -- first buffer for the first time. May be necessary if this plugin is lazy loaded to clear
        -- highlights that have been dynamically disabled.
        restart_highlighter = false,
        injections = {
            -- Out of the box language injections for known filetypes that allow markdown to be interpreted
            -- in specified locations, see :h treesitter-language-injections.
            -- Set enabled to false in order to disable.

            gitcommit = {
                enabled = true,
                query = [[
                    ((message) @injection.content
                        (#set! injection.combined)
                        (#set! injection.include-children)
                        (#set! injection.language "markdown"))
                ]],
            },
        },
        patterns = {
            -- Highlight patterns to disable for filetypes, i.e. lines concealed around code blocks

            markdown = {
                disable = true,
                directives = {
                    { id = 17, name = 'conceal_lines' },
                    { id = 18, name = 'conceal_lines' },
                },
            },
        },
        anti_conceal = {
            -- This enables hiding added text on the line the cursor is on.
            enabled = true,
            -- Modes to disable anti conceal feature.
            disabled_modes = false,
            -- Number of lines above cursor to show.
            above = 0,
            -- Number of lines below cursor to show.
            below = 0,
            -- Which elements to always show, ignoring anti conceal behavior. Values can either be
            -- booleans to fix the behavior or string lists representing modes where anti conceal
            -- behavior will be ignored. Valid values are:
            --   bullet
            --   callout
            --   check_icon, check_scope
            --   code_background, code_border, code_language
            --   dash
            --   head_background, head_border, head_icon
            --   indent
            --   latex
            --   link
            --   quote
            --   sign
            --   table_border
            --   virtual_lines
            ignore = {
                code_background = true,
                indent = true,
                sign = true,
                virtual_lines = true,
            },
        },
        padding = {
            -- Highlight to use when adding whitespace, should blend in with background.
            highlight = 'RenderMarkdownPadding',
        },
        latex = {
            -- Turn on / off latex rendering.
            enabled = true,
            -- Additional modes to render latex.
            render_modes = false,
            -- Executable used to convert latex formula to rendered unicode.
            -- If a list is provided the commands run in order until the first success.
            converter = { 'utftex', 'latex2text' },
            -- Render inline latex formulas.
            inline = true,
            -- Render block latex formulas.
            block = true,
            -- Highlight for latex blocks.
            highlight = 'RenderMarkdownMath',
            -- Determines where latex formula is rendered relative to block.
            -- | above   | above latex block                               |
            -- | below   | below latex block                               |
            -- | center  | centered with latex block (must be single line) |
            -- | replace | replace latex block with rendered formula       |
            position = 'center',
            -- Number of empty lines above latex blocks.
            top_pad = 0,
            -- Number of empty lines below latex blocks.
            bottom_pad = 0,
        },
        on = {
            -- Called when plugin initially attaches to a buffer.
            attach = function() end,
            -- Called before adding marks to the buffer for the first time.
            initial = function() end,
            -- Called after plugin renders a buffer.
            render = function() end,
            -- Called after plugin clears a buffer.
            clear = function() end,
        },
        completions = {
            -- Settings for blink.cmp completions source
            blink = { enabled = false },
            -- Settings for coq_nvim completions source
            coq = { enabled = false },
            -- Settings for in-process language server completions
            lsp = { enabled = false },
            filter = {
                callout = function()
                    -- example to exclude obsidian callouts
                    -- return value.category ~= 'obsidian'
                    return true
                end,
                checkbox = function()
                    return true
                end,
            },
        },
        heading = {
            -- Useful context to have when evaluating values.
            -- | level    | the number of '#' in the heading marker         |
            -- | sections | for each level how deeply nested the heading is |

            -- Turn on / off heading icon & background rendering.
            enabled = true,
            -- Additional modes to render headings.
            render_modes = false,
            -- Turn on / off atx heading rendering.
            atx = true,
            -- Turn on / off setext heading rendering.
            setext = true,
            -- Turn on / off sign column related rendering.
            sign = true,
            -- Replaces '#+' of 'atx_h._marker'.
            -- Output is evaluated depending on the type.
            -- | function | `value(context)`              |
            -- | string[] | `cycle(value, context.level)` |
            icons = { '󰲡 ', '󰲣 ', '󰲥 ', '󰲧 ', '󰲩 ', '󰲫 ' },
            -- Determines how icons fill the available space.
            -- | eol     | '#'s are concealed and icon is placed at right most column   |
            -- | right   | '#'s are concealed and icon is appended to right side        |
            -- | inline  | '#'s are concealed and icon is inlined on left side          |
            -- | overlay | icon is left padded with spaces and overlayed hiding all '#' |
            position = 'overlay',
            -- Added to the sign column if enabled.
            -- Output is evaluated by `cycle(value, context.level)`.
            signs = { '󰫎 ' },
            -- Width of the heading background.
            -- | block | width of the heading text |
            -- | full  | full width of the window  |
            -- Can also be a list of the above values evaluated by `clamp(value, context.level)`.
            width = 'full',
            -- Amount of margin to add to the left of headings.
            -- Margin available space is computed after accounting for padding.
            -- If a float < 1 is provided it is treated as a percentage of available window space.
            -- Can also be a list of numbers evaluated by `clamp(value, context.level)`.
            left_margin = 0,
            -- Amount of padding to add to the left of headings.
            -- Output is evaluated using the same logic as 'left_margin'.
            left_pad = 0,
            -- Amount of padding to add to the right of headings when width is 'block'.
            -- Output is evaluated using the same logic as 'left_margin'.
            right_pad = 0,
            -- Minimum width to use for headings when width is 'block'.
            -- Can also be a list of integers evaluated by `clamp(value, context.level)`.
            min_width = 0,
            -- Determines if a border is added above and below headings.
            -- Can also be a list of booleans evaluated by `clamp(value, context.level)`.
            border = false,
            -- Always use virtual lines for heading borders instead of attempting to use empty lines.
            border_virtual = false,
            -- Highlight the start of the border using the foreground highlight.
            border_prefix = false,
            -- Used above heading for border.
            above = '▄',
            -- Used below heading for border.
            below = '▀',
            -- Highlight for the heading icon and extends through the entire line.
            -- Output is evaluated by `clamp(value, context.level)`.
            backgrounds = {
                'RenderMarkdownH1Bg',
                'RenderMarkdownH2Bg',
                'RenderMarkdownH3Bg',
                'RenderMarkdownH4Bg',
                'RenderMarkdownH5Bg',
                'RenderMarkdownH6Bg',
            },
            -- Highlight for the heading and sign icons.
            -- Output is evaluated using the same logic as 'backgrounds'.
            foregrounds = {
                'RenderMarkdownH1',
                'RenderMarkdownH2',
                'RenderMarkdownH3',
                'RenderMarkdownH4',
                'RenderMarkdownH5',
                'RenderMarkdownH6',
            },
            -- Define custom heading patterns which allow you to override various properties based on
            -- the contents of a heading.
            -- The key is for healthcheck and to allow users to change its values, value type below.
            -- | pattern    | matched against the heading text @see :h lua-patterns |
            -- | icon       | optional override for the icon                        |
            -- | background | optional override for the background                  |
            -- | foreground | optional override for the foreground                  |
            custom = {},
        },
        paragraph = {
            -- Useful context to have when evaluating values.
            -- | text | text value of the node |

            -- Turn on / off paragraph rendering.
            enabled = true,
            -- Additional modes to render paragraphs.
            render_modes = false,
            -- Amount of margin to add to the left of paragraphs.
            -- If a float < 1 is provided it is treated as a percentage of available window space.
            -- Output is evaluated depending on the type.
            -- | function | `value(context)` |
            -- | number   | `value`          |
            left_margin = 0,
            -- Amount of padding to add to the first line of each paragraph.
            -- Output is evaluated using the same logic as 'left_margin'.
            indent = 0,
            -- Minimum width to use for paragraphs.
            min_width = 0,
        },
        code = {
            -- Turn on / off code block & inline code rendering.
            enabled = true,
            -- Additional modes to render code blocks.
            render_modes = false,
            -- Turn on / off sign column related rendering.
            sign = true,
            -- Whether to conceal nodes at the top and bottom of code blocks.
            conceal_delimiters = true,
            -- Turn on / off language heading related rendering.
            language = true,
            -- Determines where language icon is rendered.
            -- | center | center of code block |
            -- | right  | right of code block  |
            -- | left   | left of code block   |
            position = 'left',
            -- Whether to include the language icon above code blocks.
            language_icon = true,
            -- Whether to include the language name above code blocks.
            language_name = true,
            -- Whether to include the language info above code blocks.
            language_info = true,
            -- Amount of padding to add around the language.
            -- If a float < 1 is provided it is treated as a percentage of available window space.
            language_pad = 0,
            -- A list of language names for which rendering will be disabled.
            disable = {},
            -- A list of language names for which background highlighting will be disabled.
            -- Likely because that language has background highlights itself.
            -- Use a boolean to make behavior apply to all languages.
            -- Borders above & below blocks will continue to be rendered.
            disable_background = { 'diff' },
            -- Number of lines from start/end to skip rendering background.
            background_inset = 1,
            -- Width of the code block background.
            -- | block | width of the code block  |
            -- | full  | full width of the window |
            width = 'full',
            -- Amount of margin to add to the left of code blocks.
            -- If a float < 1 is provided it is treated as a percentage of available window space.
            -- Margin available space is computed after accounting for padding.
            left_margin = 0,
            -- Amount of padding to add to the left of code blocks.
            -- If a float < 1 is provided it is treated as a percentage of available window space.
            left_pad = 0,
            -- Amount of padding to add to the right of code blocks when width is 'block'.
            -- If a float < 1 is provided it is treated as a percentage of available window space.
            right_pad = 0,
            -- Minimum width to use for code blocks when width is 'block'.
            min_width = 0,
            -- Determines how the top / bottom of code block are rendered.
            -- | none  | do not render a border                               |
            -- | thick | use the same highlight as the code body              |
            -- | thin  | when lines are empty overlay the above & below icons |
            -- | hide  | conceal lines unless language name or icon is added  |
            border = 'hide',
            -- Used above code blocks to fill remaining space around language.
            language_border = '█',
            -- Added to the left of language.
            language_left = '',
            -- Added to the right of language.
            language_right = '',
            -- Used above code blocks for thin border.
            above = '▄',
            -- Used below code blocks for thin border.
            below = '▀',
            -- Turn on / off inline code related rendering.
            inline = true,
            -- Icon to add to the left of inline code.
            inline_left = '',
            -- Icon to add to the right of inline code.
            inline_right = '',
            -- Padding to add to the left & right of inline code.
            inline_pad = 0,
            -- Priority to assign to code background highlight.
            priority = 140,
            -- Highlight for code blocks.
            highlight = 'RenderMarkdownCode',
            -- Highlight for code info section, after the language.
            highlight_info = 'RenderMarkdownCodeInfo',
            -- Highlight for language, overrides icon provider value.
            highlight_language = nil,
            -- Highlight for border, use false to add no highlight.
            highlight_border = 'RenderMarkdownCodeBorder',
            -- Highlight for language, used if icon provider does not have a value.
            highlight_fallback = 'RenderMarkdownCodeFallback',
            -- Highlight for inline code.
            highlight_inline = 'RenderMarkdownCodeInline',
            -- Highlight for inline code left icon, default to reverse of highlight_inline.
            highlight_inline_left = nil,
            -- Highlight for inline code right icon, default to reverse of highlight_inline.
            highlight_inline_right = nil,
            -- Determines how code blocks & inline code are rendered.
            -- | none     | { enabled = false }                           |
            -- | normal   | { language = false }                          |
            -- | language | { disable_background = true, inline = false } |
            -- | full     | uses all default values                       |
            style = 'full',
        },
        dash = {
            -- Useful context to have when evaluating values.
            -- | width | width of the current window |

            -- Turn on / off thematic break rendering.
            enabled = true,
            -- Additional modes to render dash.
            render_modes = false,
            -- Replaces '---'|'***'|'___'|'* * *' of 'thematic_break'.
            -- The icon gets repeated across the window's width.
            icon = '─',
            -- Width of the generated line.
            -- If a float < 1 is provided it is treated as a percentage of available window space.
            -- Output is evaluated depending on the type.
            -- | function | `value(context)`    |
            -- | number   | `value`             |
            -- | full     | width of the window |
            width = 'full',
            -- Amount of margin to add to the left of dash.
            -- If a float < 1 is provided it is treated as a percentage of available window space.
            left_margin = 0,
            -- Priority to assign to dash.
            priority = nil,
            -- Highlight for the whole line generated from the icon.
            highlight = 'RenderMarkdownDash',
        },
        document = {
            -- Turn on / off document rendering.
            enabled = true,
            -- Additional modes to render document.
            render_modes = false,
            -- Ability to conceal arbitrary ranges of text based on lua patterns, @see :h lua-patterns.
            -- Relies entirely on user to set patterns that handle their edge cases.
            conceal = {
                -- Matched ranges will be concealed using character level conceal.
                char_patterns = {},
                -- Matched ranges will be concealed using line level conceal.
                line_patterns = {},
            },
        },
        bullet = {
            -- Useful context to have when evaluating values.
            -- | level | how deeply nested the list is, 1-indexed          |
            -- | index | how far down the item is at that level, 1-indexed |
            -- | value | text value of the marker node                     |

            -- Turn on / off list bullet rendering
            enabled = true,
            -- Additional modes to render list bullets
            render_modes = false,
            -- Replaces '-'|'+'|'*' of 'list_item'.
            -- If the item is a 'checkbox' a conceal is used to hide the bullet instead.
            -- Output is evaluated depending on the type.
            -- | function   | `value(context)`                                    |
            -- | string     | `value`                                             |
            -- | string[]   | `cycle(value, context.level)`                       |
            -- | string[][] | `clamp(cycle(value, context.level), context.index)` |
            icons = { '●', '○', '◆', '◇' },
            -- Replaces 'n.'|'n)' of 'list_item'.
            -- Output is evaluated using the same logic as 'icons'.
            ordered_icons = function(ctx)
                local value = vim.trim(ctx.value)
                local index = tonumber(value:sub(1, #value - 1)) or 0
                return ('%d.'):format(index > 1 and index or ctx.index)
            end,
            -- Padding to add to the left of bullet point.
            -- Output is evaluated depending on the type.
            -- | function | `value(context)` |
            -- | integer  | `value`          |
            left_pad = 0,
            -- Padding to add to the right of bullet point.
            -- Output is evaluated using the same logic as 'left_pad'.
            right_pad = 0,
            -- Highlight for the bullet icon.
            -- Output is evaluated using the same logic as 'icons'.
            highlight = 'RenderMarkdownBullet',
            -- Highlight for item associated with the bullet point.
            -- Output is evaluated using the same logic as 'icons'.
            scope_highlight = {},
            -- Priority to assign to scope highlight.
            scope_priority = nil,
        },
        checkbox = {
            -- Checkboxes are a special instance of a 'list_item' that start with a 'shortcut_link'.
            -- There are two special states for unchecked & checked defined in the markdown grammar.

            -- Turn on / off checkbox state rendering.
            enabled = true,
            -- Additional modes to render checkboxes.
            render_modes = false,
            -- Render the bullet point before the checkbox.
            bullet = false,
            -- Padding to add to the left of checkboxes.
            left_pad = 0,
            -- Padding to add to the right of checkboxes.
            right_pad = 1,
            unchecked = {
                -- Replaces '[ ]' of 'task_list_marker_unchecked'.
                icon = '󰄱 ',
                -- Highlight for the unchecked icon.
                highlight = 'RenderMarkdownUnchecked',
                -- Highlight for item associated with unchecked checkbox.
                scope_highlight = nil,
            },
            checked = {
                -- Replaces '[x]' of 'task_list_marker_checked'.
                icon = '󰱒 ',
                -- Highlight for the checked icon.
                highlight = 'RenderMarkdownChecked',
                -- Highlight for item associated with checked checkbox.
                scope_highlight = nil,
            },
            -- Define custom checkbox states, more involved, not part of the markdown grammar.
            -- As a result this requires neovim >= 0.10.0 since it relies on 'inline' extmarks.
            -- The key is for healthcheck and to allow users to change its values, value type below.
            -- | raw             | matched against the raw text of a 'shortcut_link'           |
            -- | rendered        | replaces the 'raw' value when rendering                     |
            -- | highlight       | highlight for the 'rendered' icon                           |
            -- | scope_highlight | optional highlight for item associated with custom checkbox |
            -- stylua: ignore
            custom = {
                todo = { raw = '[-]', rendered = '󰥔 ', highlight = 'RenderMarkdownTodo', scope_highlight = nil },
            },
            -- Priority to assign to scope highlight.
            scope_priority = nil,
        },
        quote = {
            -- Turn on / off block quote & callout rendering.
            enabled = true,
            -- Additional modes to render quotes.
            render_modes = false,
            -- Replaces '>' of 'block_quote'.
            icon = '▋',
            -- Whether to repeat icon on wrapped lines. Requires neovim >= 0.10. This will obscure text
            -- if incorrectly configured with :h 'showbreak', :h 'breakindent' and :h 'breakindentopt'.
            -- A combination of these that is likely to work follows.
            -- | showbreak      | '  ' (2 spaces)   |
            -- | breakindent    | true              |
            -- | breakindentopt | '' (empty string) |
            -- These are not validated by this plugin. If you want to avoid adding these to your main
            -- configuration then set them in win_options for this plugin.
            repeat_linebreak = false,
            -- Highlight for the quote icon.
            -- If a list is provided output is evaluated by `cycle(value, level)`.
            highlight = {
                'RenderMarkdownQuote1',
                'RenderMarkdownQuote2',
                'RenderMarkdownQuote3',
                'RenderMarkdownQuote4',
                'RenderMarkdownQuote5',
                'RenderMarkdownQuote6',
            },
        },
        render = {
            -- Whether to render when window is in diff-mode.
            diff = false,
        },
        pipe_table = {
            -- Turn on / off pipe table rendering.
            enabled = true,
            -- Additional modes to render pipe tables.
            render_modes = false,
            -- Pre configured settings largely for setting table border easier.
            -- | heavy  | use thicker border characters     |
            -- | double | use double line border characters |
            -- | round  | use round border corners          |
            -- | none   | does nothing                      |
            preset = 'none',
            -- Determines how individual cells of a table are rendered.
            -- | overlay | writes completely over the table, removing conceal behavior and highlights |
            -- | raw     | replaces only the '|' characters in each row, leaving the cells unmodified |
            -- | padded  | raw + cells are padded to maximum visual width for each column             |
            -- | trimmed | padded except empty space is subtracted from visual width calculation      |
            cell = 'padded',
            -- Fit wide tables to the current window by wrapping individual cells.
            wrap = true,
            -- Draw a horizontal line between every body row.
            grid = false,
            -- Adjust the computed width of table cells using custom logic.
            cell_offset = function()
                return 0
            end,
            -- Amount of space to put between cell contents and border.
            padding = 1,
            -- Minimum column width to use for padded or trimmed cell.
            min_width = 0,
            -- Characters used to replace table border.
            -- Correspond to top(3), delimiter(3), bottom(3), vertical, & horizontal.
            -- stylua: ignore
            border = {
                '┌', '┬', '┐',
                '├', '┼', '┤',
                '└', '┴', '┘',
                '│', '─',
            },
            -- Turn on / off top & bottom lines.
            border_enabled = true,
            -- Priority to assign to table border.
            border_priority = nil,
            -- Always use virtual lines for table borders instead of attempting to use empty lines.
            -- Will be automatically enabled if indentation module is enabled.
            border_virtual = false,
            -- Gets placed in delimiter row for each column, position is based on alignment.
            alignment_indicator = '━',
            -- Highlight for table heading, delimiter, and the line above.
            head = 'RenderMarkdownTableHead',
            -- Highlight for everything else, main table rows and the line below.
            row = 'RenderMarkdownTableRow',
            -- Determines how the table as a whole is rendered.
            -- | none   | { enabled = false }        |
            -- | normal | { border_enabled = false } |
            -- | full   | uses all default values    |
            style = 'full',
        },
        callout = {
            -- Callouts are a special instance of a 'block_quote' that start with a 'shortcut_link'.
            -- The key is for healthcheck and to allow users to change its values, value type below.
            -- | raw        | matched against the raw text of a 'shortcut_link', case insensitive |
            -- | rendered   | replaces the 'raw' value when rendering                             |
            -- | highlight  | highlight for the 'rendered' text and quote markers                 |
            -- | quote_icon | optional override for quote.icon value for individual callout       |
            -- | category   | optional metadata useful for filtering                              |

            note      = { raw = '[!NOTE]',      rendered = '󰋽 Note',      highlight = 'RenderMarkdownInfo',    category = 'github'   },
            tip       = { raw = '[!TIP]',       rendered = '󰌶 Tip',       highlight = 'RenderMarkdownSuccess', category = 'github'   },
            important = { raw = '[!IMPORTANT]', rendered = '󰅾 Important', highlight = 'RenderMarkdownHint',    category = 'github'   },
            warning   = { raw = '[!WARNING]',   rendered = '󰀪 Warning',   highlight = 'RenderMarkdownWarn',    category = 'github'   },
            caution   = { raw = '[!CAUTION]',   rendered = '󰳦 Caution',   highlight = 'RenderMarkdownError',   category = 'github'   },
            -- Obsidian: https://help.obsidian.md/Editing+and+formatting/Callouts
            abstract  = { raw = '[!ABSTRACT]',  rendered = '󰨸 Abstract',  highlight = 'RenderMarkdownInfo',    category = 'obsidian' },
            summary   = { raw = '[!SUMMARY]',   rendered = '󰨸 Summary',   highlight = 'RenderMarkdownInfo',    category = 'obsidian' },
            tldr      = { raw = '[!TLDR]',      rendered = '󰨸 Tldr',      highlight = 'RenderMarkdownInfo',    category = 'obsidian' },
            info      = { raw = '[!INFO]',      rendered = '󰋽 Info',      highlight = 'RenderMarkdownInfo',    category = 'obsidian' },
            todo      = { raw = '[!TODO]',      rendered = '󰗡 Todo',      highlight = 'RenderMarkdownInfo',    category = 'obsidian' },
            hint      = { raw = '[!HINT]',      rendered = '󰌶 Hint',      highlight = 'RenderMarkdownSuccess', category = 'obsidian' },
            success   = { raw = '[!SUCCESS]',   rendered = '󰄬 Success',   highlight = 'RenderMarkdownSuccess', category = 'obsidian' },
            check     = { raw = '[!CHECK]',     rendered = '󰄬 Check',     highlight = 'RenderMarkdownSuccess', category = 'obsidian' },
            done      = { raw = '[!DONE]',      rendered = '󰄬 Done',      highlight = 'RenderMarkdownSuccess', category = 'obsidian' },
            question  = { raw = '[!QUESTION]',  rendered = '󰘥 Question',  highlight = 'RenderMarkdownWarn',    category = 'obsidian' },
            help      = { raw = '[!HELP]',      rendered = '󰘥 Help',      highlight = 'RenderMarkdownWarn',    category = 'obsidian' },
            faq       = { raw = '[!FAQ]',       rendered = '󰘥 Faq',       highlight = 'RenderMarkdownWarn',    category = 'obsidian' },
            attention = { raw = '[!ATTENTION]', rendered = '󰀪 Attention', highlight = 'RenderMarkdownWarn',    category = 'obsidian' },
            failure   = { raw = '[!FAILURE]',   rendered = '󰅖 Failure',   highlight = 'RenderMarkdownError',   category = 'obsidian' },
            fail      = { raw = '[!FAIL]',      rendered = '󰅖 Fail',      highlight = 'RenderMarkdownError',   category = 'obsidian' },
            missing   = { raw = '[!MISSING]',   rendered = '󰅖 Missing',   highlight = 'RenderMarkdownError',   category = 'obsidian' },
            danger    = { raw = '[!DANGER]',    rendered = '󱐌 Danger',    highlight = 'RenderMarkdownError',   category = 'obsidian' },
            error     = { raw = '[!ERROR]',     rendered = '󱐌 Error',     highlight = 'RenderMarkdownError',   category = 'obsidian' },
            bug       = { raw = '[!BUG]',       rendered = '󰨰 Bug',       highlight = 'RenderMarkdownError',   category = 'obsidian' },
            example   = { raw = '[!EXAMPLE]',   rendered = '󰉹 Example',   highlight = 'RenderMarkdownHint' ,   category = 'obsidian' },
            quote     = { raw = '[!QUOTE]',     rendered = '󱆨 Quote',     highlight = 'RenderMarkdownQuote',   category = 'obsidian' },
            cite      = { raw = '[!CITE]',      rendered = '󱆨 Cite',      highlight = 'RenderMarkdownQuote',   category = 'obsidian' },
        },
        link = {
            -- Turn on / off inline link icon rendering.
            enabled = true,
            -- Additional modes to render links.
            render_modes = false,
            -- How to handle footnote links, start with a '^'.
            footnote = {
                -- Turn on / off footnote rendering.
                enabled = true,
                -- Inlined with content.
                icon = '󰯔 ',
                -- Custom processing for footnote body to show.
                -- Runs before prefix / suffix are added and superscript processing.
                body = function(ctx)
                    return ctx.text
                end,
                -- Replace value with superscript equivalent.
                superscript = true,
                -- Added before link content.
                prefix = '',
                -- Added after link content.
                suffix = '',
            },
            -- Inlined with 'image' elements.
            image = '󰥶 ',
            -- Check custom for 'image' elements.
            image_custom = true,
            -- Inlined with 'email_autolink' elements.
            email = '󰀓 ',
            -- Fallback icon for 'inline_link' and 'uri_autolink' elements.
            hyperlink = '󰌹 ',
            -- Applies to the inlined icon as a fallback.
            highlight = 'RenderMarkdownLink',
            -- Applies to the link title.
            highlight_title = 'RenderMarkdownLinkTitle',
            -- Applies to WikiLink elements.
            wiki = {
                -- Turn on / off WikiLink rendering.
                enabled = true,
                -- Inlined with content.
                icon = '󱗖 ',
                -- Hide destination if there is an alias.
                conceal_destination = true,
                -- Custom processing for WikiLink body to show.
                body = function()
                    return nil
                end,
                -- Applies to the inlined icon.
                highlight = 'RenderMarkdownWikiLink',
                -- Highlight for item associated with the WikiLink.
                scope_highlight = nil,
            },
            -- Define custom destination patterns so icons can quickly inform you of what a link
            -- contains. Applies to 'image', 'inline_link', 'uri_autolink', and WikiLink nodes.
            -- When multiple patterns match a link the one with the longer pattern is used.
            -- The key is for healthcheck and to allow users to change its values, value type below.
            -- | icon      | gets inlined before the link text                               |
            -- | pattern   | matched against the destination text                            |
            -- | kind      | optional determines how pattern is checked                      |
            -- |           | pattern | @see :h lua-patterns, is the default if not set       |
            -- |           | prefix  | @see :h vim.startswith()                              |
            -- |           | suffix  | @see :h vim.endswith()                                |
            -- |           | url     | similar to pattern with additional prefix checks      |
            -- | priority  | optional used when multiple match, uses pattern length if empty |
            -- | highlight | optional highlight for 'icon', uses fallback highlight if empty |
            -- stylua: ignore
            custom = {
                web = { icon = '󰖟 ', pattern = '^http' },
                apple = { icon = ' ', pattern = 'apple%.com', kind = 'url' },
                discord = { icon = '󰙯 ', pattern = 'discord%.com', kind = 'url' },
                github = { icon = '󰊤 ', pattern = 'github%.com', kind = 'url' },
                gitlab = { icon = '󰮠 ', pattern = 'gitlab%.com', kind = 'url' },
                google = { icon = '󰊭 ', pattern = 'google%.com', kind = 'url' },
                hackernews = { icon = ' ', pattern = 'ycombinator%.com', kind = 'url' },
                linkedin = { icon = '󰌻 ', pattern = 'linkedin%.com', kind = 'url' },
                microsoft = { icon = ' ', pattern = 'microsoft%.com', kind = 'url' },
                neovim = { icon = ' ', pattern = 'neovim%.io', kind = 'url' },
                reddit = { icon = '󰑍 ', pattern = 'reddit%.com', kind = 'url' },
                slack = { icon = '󰒱 ', pattern = 'slack%.com', kind = 'url' },
                stackoverflow = { icon = '󰓌 ', pattern = 'stackoverflow%.com', kind = 'url' },
                steam = { icon = ' ', pattern = 'steampowered%.com', kind = 'url' },
                twitter = { icon = ' ', pattern = 'twitter%.com', kind = 'url' },
                wikipedia = { icon = '󰖬 ', pattern = 'wikipedia%.org', kind = 'url' },
                x = { icon = ' ', pattern = 'x%.com', kind = 'url' },
                youtube = { icon = '󰗃 ', pattern = 'youtube[^.]*%.com', kind = 'url' },
                youtube_short = { icon = '󰗃 ', pattern = 'youtu%.be', kind = 'url' },
            },
        },
        sign = {
            -- Turn on / off sign rendering.
            enabled = true,
            -- Priority to assign to sign.
            priority = nil,
            -- Applies to background of sign text.
            highlight = 'RenderMarkdownSign',
        },
        inline_highlight = {
            -- Mimics Obsidian inline highlights when content is surrounded by double equals.
            -- The equals on both ends are concealed and the inner content is highlighted.

            -- Turn on / off inline highlight rendering.
            enabled = true,
            -- Additional modes to render inline highlights.
            render_modes = false,
            -- Applies to background of surrounded text.
            highlight = 'RenderMarkdownInlineHighlight',
            -- Define custom highlights based on text prefix.
            -- The key is for healthcheck and to allow users to change its values, value type below.
            -- | prefix    | matched against text body, @see :h vim.startswith() |
            -- | highlight | highlight for text body                             |
            custom = {},
        },
        indent = {
            -- Mimic org-indent-mode behavior by indenting everything under a heading based on the
            -- level of the heading. Indenting starts from level 2 headings onward by default.

            -- Turn on / off org-indent-mode.
            enabled = false,
            -- Additional modes to render indents.
            render_modes = false,
            -- Amount of additional padding added for each heading level.
            per_level = 2,
            -- Heading levels <= this value will not be indented.
            -- Use 0 to begin indenting from the very first level.
            skip_level = 1,
            -- Do not indent heading titles, only the body.
            skip_heading = false,
            -- Prefix added when indenting, one per level.
            icon = '▎',
            -- Priority to assign to extmarks.
            priority = 0,
            -- Applied to icon.
            highlight = 'RenderMarkdownIndent',
        },
        html = {
            -- Turn on / off all HTML rendering.
            enabled = true,
            -- Additional modes to render HTML.
            render_modes = false,
            comment = {
                -- Useful context to have when evaluating values.
                -- | text | text value of the comment node |

                -- Turn on / off HTML comment concealing.
                conceal = true,
                -- Text to inline before the concealed comment.
                -- Output is evaluated depending on the type.
                -- | function | `value(context)` |
                -- | string   | `value`          |
                -- | nil      | nothing          |
                text = nil,
                -- Highlight for the inlined text.
                highlight = 'RenderMarkdownHtmlComment',
            },
            -- HTML tags whose start and end will be hidden and icon shown.
            -- The key is matched against the tag name, value type below.
            -- | icon            | optional icon inlined at start of tag           |
            -- | highlight       | optional highlight for the icon                 |
            -- | scope_highlight | optional highlight for item associated with tag |
            tag = {},
        },
        win_options = {
            -- Window options to use that change between rendered and raw view.

            -- @see :h 'conceallevel'
            conceallevel = {
                -- Used when not being rendered, get user setting.
                default = vim.o.conceallevel,
                -- Used when being rendered, concealed text is completely hidden.
                rendered = 3,
            },
            -- @see :h 'concealcursor'
            concealcursor = {
                -- Used when not being rendered, get user setting.
                default = vim.o.concealcursor,
                -- Used when being rendered, show concealed text in all modes.
                rendered = '',
            },
        },
        overrides = {
            -- More granular configuration mechanism, allows different aspects of buffers to have their own
            -- behavior. Values default to the top level configuration if no override is provided. Supports
            -- the following fields:
            --   enabled, render_modes, debounce, anti_conceal, bullet, callout, checkbox, code, dash,
            --   document, heading, html, indent, inline_highlight, latex, link, padding, paragraph,
            --   pipe_table, quote, sign, win_options, yaml

            -- Override for different buflisted values, @see :h 'buflisted'.
            buflisted = {},
            -- Override for different buftype values, @see :h 'buftype'.
            buftype = {
                nofile = {
                    render_modes = true,
                    sign = { enabled = false },
                },
            },
            -- Override for different filetype values, @see :h 'filetype'.
            filetype = {},
            -- Override for preview buffer.
            preview = {
                render_modes = true,
            },
        },
        custom_handlers = {
            -- Mapping from treesitter language to user defined handlers.
            -- @see [Custom Handlers](doc/custom-handlers.md)
        },
        yaml = {
            -- Turn on / off all yaml rendering.
            enabled = true,
            -- Additional modes to render yaml.
            render_modes = false,
        },
    })

  -- Here is a more advanced configuration example that passes options to `gitsigns.nvim`
  --
  -- See `:help gitsigns` to understand what each configuration key does.
  -- Adds git related signs to the gutter, as well as utilities for managing changes
  vim.pack.add { gh 'lewis6991/gitsigns.nvim' }
  require('gitsigns').setup {
    signs = {
      add = { text = '+' }, ---@diagnostic disable-line: missing-fields
      change = { text = '~' }, ---@diagnostic disable-line: missing-fields
      delete = { text = '_' }, ---@diagnostic disable-line: missing-fields
      topdelete = { text = '‾' }, ---@diagnostic disable-line: missing-fields
      changedelete = { text = '~' }, ---@diagnostic disable-line: missing-fields
    },
  }

  -- Useful plugin to show you pending keybinds.
  vim.pack.add { gh 'folke/which-key.nvim' }
  require('which-key').setup {
    -- Delay between pressing a key and opening which-key (milliseconds)
    delay = 0,
    icons = { mappings = vim.g.have_nerd_font },
    -- Document existing key chains
    spec = {
      { '<leader>s', group = '[S]earch', mode = { 'n', 'v' } },
      { '<leader>t', group = '[T]oggle' },
      { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } }, -- Enable gitsigns recommended keymaps first
      { 'gr', group = 'LSP Actions', mode = { 'n' } },
    },
  }

    -- [[ Colorscheme ]]
    -- Use my nvim module to pull the nvim colorscheme from the pulsar_shell current theme.
    require("pulsar_theme").setup({
        transparent = true,
        watch = true
  })

  -- Highlight todo, notes, etc in comments
  vim.pack.add { gh 'folke/todo-comments.nvim' }
  require('todo-comments').setup { signs = false }

  -- [[ mini.nvim ]]
  --  A collection of various small independent plugins/modules
  vim.pack.add { gh 'nvim-mini/mini.nvim' }

  -- If a nerd font is available, load the icons module for pretty icons in various plugins.
  if vim.g.have_nerd_font then
    require('mini.icons').setup()
    -- Used for backwards compatibility with plugins that require `nvim-web-devicons` (e.g. telescope.nvim)
    MiniIcons.mock_nvim_web_devicons()
  end

  -- Better Around/Inside textobjects
  --
  -- Examples:
  --  - va)  - [V]isually select [A]round [)]paren
  --  - yiiq - [Y]ank [I]nside [I]+1 [Q]uote
  --  - ci'  - [C]hange [I]nside [']quote
  require('mini.ai').setup {
    -- NOTE: Avoid conflicts with the built-in incremental selection mappings on Neovim>=0.12 (see `:help treesitter-incremental-selection`)
    mappings = {
      around_next = 'aa',
      inside_next = 'ii',
    },
    n_lines = 500,
  }

  -- Add/delete/replace surroundings (brackets, quotes, etc.)
  --
  -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
  -- - sd'   - [S]urround [D]elete [']quotes
  -- - sr)'  - [S]urround [R]eplace [)] [']
  require('mini.surround').setup()

  -- Simple and easy statusline.
  --  You could remove this setup call if you don't like it,
  --  and try some other statusline plugin
  local statusline = require 'mini.statusline'
  -- Set `use_icons` to true if you have a Nerd Font
  statusline.setup { use_icons = vim.g.have_nerd_font }

  -- You can configure sections in the statusline by overriding their
  -- default behavior. For example, here we set the section for
  -- cursor location to LINE:COLUMN
  ---@diagnostic disable-next-line: duplicate-set-field
  statusline.section_location = function() return '%2l:%-2v' end

  -- ... and there is more!
  --  Check out: https://github.com/nvim-mini/mini.nvim
end

-- ============================================================
-- SECTION 5: SEARCH & NAVIGATION
-- Telescope setup, keymaps, LSP picker mappings
-- ============================================================
do
  -- [[ Fuzzy Finder (files, lsp, etc) ]]
  --
  -- Telescope is a fuzzy finder that comes with a lot of different things that
  -- it can fuzzy find! It's more than just a "file finder", it can search
  -- many different aspects of Neovim, your workspace, LSP, and more!
  --
  -- There are lots of other alternative pickers (like snacks.picker, or fzf-lua)
  -- so feel free to experiment and see what you like!
  --
  -- The easiest way to use Telescope, is to start by doing something like:
  --  :Telescope help_tags
  --
  -- After running this command, a window will open up and you're able to
  -- type in the prompt window. You'll see a list of `help_tags` options and
  -- a corresponding preview of the help.
  --
  -- Two important keymaps to use while in Telescope are:
  --  - Insert mode: <c-/>
  --  - Normal mode: ?
  --
  -- This opens a window that shows you all of the keymaps for the current
  -- Telescope picker. This is really useful to discover what Telescope can
  -- do as well as how to actually do it!

  ---@type (string|vim.pack.Spec)[]
  local telescope_plugins = {
    gh 'nvim-lua/plenary.nvim',
    gh 'nvim-telescope/telescope.nvim',
    gh 'nvim-telescope/telescope-ui-select.nvim',
  }
  if vim.fn.executable 'make' == 1 then table.insert(telescope_plugins, gh 'nvim-telescope/telescope-fzf-native.nvim') end

  -- NOTE: You can install multiple plugins at once
  vim.pack.add(telescope_plugins)

  -- See `:help telescope` and `:help telescope.setup()`
  require('telescope').setup {
    -- You can put your default mappings / updates / etc. in here
    --  All the info you're looking for is in `:help telescope.setup()`
    --
    -- defaults = {
    --   mappings = {
    --     i = { ['<c-enter>'] = 'to_fuzzy_refine' },
    --   },
    -- },
    -- pickers = {}
    extensions = {
      ['ui-select'] = { require('telescope.themes').get_dropdown() },
    },
  }

  -- Enable Telescope extensions if they are installed
  pcall(require('telescope').load_extension, 'fzf')
  pcall(require('telescope').load_extension, 'ui-select')

  -- See `:help telescope.builtin`
  local builtin = require 'telescope.builtin'
  vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
  vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
  vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
  vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
  vim.keymap.set({ 'n', 'v' }, '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
  vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
  vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
  vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
  vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
  vim.keymap.set('n', '<leader>sc', builtin.commands, { desc = '[S]earch [C]ommands' })
  vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

  -- Add Telescope-based LSP pickers when an LSP attaches to a buffer.
  -- If you later switch picker plugins, this is where to update these mappings.
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('telescope-lsp-attach', { clear = true }),
    callback = function(event)
      local buf = event.buf

      -- Find references for the word under your cursor.
      vim.keymap.set('n', 'grr', builtin.lsp_references, { buffer = buf, desc = '[G]oto [R]eferences' })

      -- Jump to the implementation of the word under your cursor.
      -- Useful when your language has ways of declaring types without an actual implementation.
      vim.keymap.set('n', 'gri', builtin.lsp_implementations, { buffer = buf, desc = '[G]oto [I]mplementation' })

      -- Jump to the definition of the word under your cursor.
      -- This is where a variable was first declared, or where a function is defined, etc.
      -- To jump back, press <C-t>.
      vim.keymap.set('n', 'grd', builtin.lsp_definitions, { buffer = buf, desc = '[G]oto [D]efinition' })

      -- Fuzzy find all the symbols in your current document.
      -- Symbols are things like variables, functions, types, etc.
      vim.keymap.set('n', 'gO', builtin.lsp_document_symbols, { buffer = buf, desc = 'Open Document Symbols' })

      -- Fuzzy find all the symbols in your current workspace.
      -- Similar to document symbols, except searches over your entire project.
      vim.keymap.set('n', 'gW', builtin.lsp_dynamic_workspace_symbols, { buffer = buf, desc = 'Open Workspace Symbols' })

      -- Jump to the type of the word under your cursor.
      -- Useful when you're not sure what type a variable is and you want to see
      -- the definition of its *type*, not where it was *defined*.
      vim.keymap.set('n', 'grt', builtin.lsp_type_definitions, { buffer = buf, desc = '[G]oto [T]ype Definition' })
    end,
  })

  -- Override default behavior and theme when searching
  vim.keymap.set('n', '<leader>/', function()
    -- You can pass additional configuration to Telescope to change the theme, layout, etc.
    builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
      winblend = 10,
      previewer = false,
    })
  end, { desc = '[/] Fuzzily search in current buffer' })

  -- It's also possible to pass additional configuration options.
  --  See `:help telescope.builtin.live_grep()` for information about particular keys
  vim.keymap.set(
    'n',
    '<leader>s/',
    function()
      builtin.live_grep {
        grep_open_files = true,
        prompt_title = 'Live Grep in Open Files',
      }
    end,
    { desc = '[S]earch [/] in Open Files' }
  )

  -- Shortcut for searching your Neovim configuration files
  vim.keymap.set('n', '<leader>sn', function() builtin.find_files { cwd = vim.fn.stdpath 'config', follow = true } end, { desc = '[S]earch [N]eovim files' })
end

-- ============================================================
-- SECTION 6: LSP
-- LSP keymaps, server configuration, Mason tools installations
-- ============================================================
do
  -- [[ LSP Configuration ]]
  -- Brief aside: **What is LSP?**
  --
  -- LSP is an initialism you've probably heard, but might not understand what it is.
  --
  -- LSP stands for Language Server Protocol. It's a protocol that helps editors
  -- and language tooling communicate in a standardized fashion.
  --
  -- In general, you have a "server" which is some tool built to understand a particular
  -- language (such as `gopls`, `lua_ls`, `rust_analyzer`, etc.). These Language Servers
  -- (sometimes called LSP servers, but that's kind of like ATM Machine) are standalone
  -- processes that communicate with some "client" - in this case, Neovim!
  --
  -- LSP provides Neovim with features like:
  --  - Go to definition
  --  - Find references
  --  - Autocompletion
  --  - Symbol Search
  --  - and more!
  --
  -- Thus, Language Servers are external tools that must be installed separately from
  -- Neovim. This is where `mason` and related plugins come into play.
  --
  -- If you're wondering about lsp vs treesitter, you can check out the wonderfully
  -- and elegantly composed help section, `:help lsp-vs-treesitter`

  -- Useful status updates for LSP.
  vim.pack.add { gh 'j-hui/fidget.nvim' }
  require('fidget').setup {}

  --  This function gets run when an LSP attaches to a particular buffer.
  --    That is to say, every time a new file is opened that is associated with
  --    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
  --    function will be executed to configure the current buffer
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
    callback = function(event)
      -- NOTE: Remember that Lua is a real programming language, and as such it is possible
      -- to define small helper and utility functions so you don't have to repeat yourself.
      --
      -- In this case, we create a function that lets us more easily define mappings specific
      -- for LSP related items. It sets the mode, buffer and description for us each time.
      local map = function(keys, func, desc, mode)
        mode = mode or 'n'
        vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
      end

      -- Rename the variable under your cursor.
      --  Most Language Servers support renaming across files, etc.
      map('grn', vim.lsp.buf.rename, '[R]e[n]ame')

      -- Execute a code action, usually your cursor needs to be on top of an error
      -- or a suggestion from your LSP for this to activate.
      map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })

      -- WARN: This is not Goto Definition, this is Goto Declaration.
      --  For example, in C this would take you to the header.
      map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

      -- The following two autocommands are used to highlight references of the
      -- word under your cursor when your cursor rests there for a little while.
      --    See `:help CursorHold` for information about when this is executed
      --
      -- When you move your cursor, the highlights will be cleared (the second autocommand).
      local client = vim.lsp.get_client_by_id(event.data.client_id)
      if client and client:supports_method('textDocument/documentHighlight', event.buf) then
        local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
        vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
          buffer = event.buf,
          group = highlight_augroup,
          callback = vim.lsp.buf.document_highlight,
        })

        vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
          buffer = event.buf,
          group = highlight_augroup,
          callback = vim.lsp.buf.clear_references,
        })

        vim.api.nvim_create_autocmd('LspDetach', {
          group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
          callback = function(event2)
            vim.lsp.buf.clear_references()
            vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
          end,
        })
      end

      -- The following code creates a keymap to toggle inlay hints in your
      -- code, if the language server you are using supports them
      --
      -- This may be unwanted, since they displace some of your code
      if client and client:supports_method('textDocument/inlayHint', event.buf) then
        map('<leader>th', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end, '[T]oggle Inlay [H]ints')
      end
    end,
  })

  -- Enable the following language servers
  --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
  --  See `:help lsp-config` for information about keys and how to configure
  ---@type table<string, vim.lsp.Config>
  local servers = {
    -- clangd = {},
    gopls = {},
    -- pyright = {},
    -- rust_analyzer = {},
    --
    -- Some languages (like typescript) have entire language plugins that can be useful:
    --    https://github.com/pmizio/typescript-tools.nvim
    --
    -- But for many setups, the LSP (`ts_ls`) will work just fine
    -- ts_ls = {},

    stylua = {}, -- Used to format Lua code

    -- Special Lua Config, as recommended by neovim help docs
    lua_ls = {
      on_init = function(client)
        client.server_capabilities.documentFormattingProvider = false -- Disable formatting (formatting is done by stylua)

        if client.workspace_folders then
          local path = client.workspace_folders[1].name
          if path ~= vim.fn.stdpath 'config' and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then return end
        end

        local current_settings = client.config.settings --[[@as lspconfig.settings.lua_ls]]
        client.config.settings.Lua = vim.tbl_deep_extend('force', current_settings.Lua, {
          runtime = {
            version = 'LuaJIT',
            path = { 'lua/?.lua', 'lua/?/init.lua' },
          },
          workspace = {
            checkThirdParty = false,
            -- NOTE: this is a lot slower and will cause issues when working on your own configuration.
            --  See https://github.com/neovim/nvim-lspconfig/issues/3189
            library = vim.tbl_extend('force', vim.api.nvim_get_runtime_file('', true), {
              '${3rd}/luv/library',
              '${3rd}/busted/library',
            }),
          },
        })
      end,
      ---@type lspconfig.settings.lua_ls
      settings = {
        Lua = {
          format = { enable = false }, -- Disable formatting (formatting is done by stylua)
        },
      },
    },
  }

  vim.pack.add {
    gh 'neovim/nvim-lspconfig',
    gh 'mason-org/mason.nvim',
    gh 'mason-org/mason-lspconfig.nvim',
    gh 'WhoIsSethDaniel/mason-tool-installer.nvim',
  }

  -- Automatically install LSPs and related tools to stdpath for Neovim
  require('mason').setup {}

  -- Translates between nvim-lspconfig server names and mason.nvim package names (e.g. lua_ls <-> lua-language-server)
  require('mason-lspconfig').setup {
    automatic_enable = false, -- Change this to true if you want to automatically enable servers that are installed manually (e.g. via :Mason / :MasonInstall)
  }

  -- Ensure the servers and tools above are installed
  --
  -- To check the current status of installed tools and/or manually install
  -- other tools, you can run
  --    :Mason
  --
  -- You can press `g?` for help in this menu.
  local ensure_installed = vim.tbl_keys(servers or {})
  vim.list_extend(ensure_installed, {
    -- You can add other tools here that you want Mason to install
  })

  require('mason-tool-installer').setup { ensure_installed = ensure_installed }

  for name, server in pairs(servers) do
    vim.lsp.config(name, server)
    vim.lsp.enable(name)
  end
end

-- ============================================================
-- SECTION 7: FORMATTING
-- conform.nvim setup and keymap
-- ============================================================
do
  -- [[ Formatting ]]
  vim.pack.add { gh 'stevearc/conform.nvim' }
  require('conform').setup {
    notify_on_error = false,
    format_on_save = function(bufnr)
      -- You can specify filetypes to autoformat on save here:
      local enabled_filetypes = {
        -- lua = true,
        -- python = true,
      }
      if enabled_filetypes[vim.bo[bufnr].filetype] then
        return { timeout_ms = 500 }
      else
        return nil
      end
    end,
    default_format_opts = {
      lsp_format = 'fallback', -- Use external formatters if configured below, otherwise use LSP formatting. Set to `false` to disable LSP formatting entirely.
    },
    -- You can also specify external formatters in here.
    formatters_by_ft = {
      -- rust = { 'rustfmt' },
      -- Conform can also run multiple formatters sequentially
      -- python = { "isort", "black" },
      --
      -- You can use 'stop_after_first' to run the first available formatter from the list
      -- javascript = { "prettierd", "prettier", stop_after_first = true },
    },
  }

  vim.keymap.set({ 'n', 'v' }, '<leader>f', function() require('conform').format { async = true } end, { desc = '[F]ormat buffer' })
end

-- ============================================================
-- SECTION 8: AUTOCOMPLETE & SNIPPETS
-- blink.cmp and luasnip setup
-- ============================================================
do
  -- [[ Snippet Engine ]]

  -- NOTE: You can also specify plugin using a version range for its git tag.
  --  See `:help vim.version.range()` for more info
  vim.pack.add { { src = gh 'L3MON4D3/LuaSnip', version = vim.version.range '2.*' } }
  require('luasnip').setup {}

  -- `friendly-snippets` contains a variety of premade snippets.
  --    See the README about individual language/framework/plugin snippets:
  --    https://github.com/rafamadriz/friendly-snippets
  --
  -- vim.pack.add { gh 'rafamadriz/friendly-snippets' }
  -- require('luasnip.loaders.from_vscode').lazy_load()

  -- [[ Autocomplete Engine ]]
  vim.pack.add { { src = gh 'saghen/blink.cmp', version = vim.version.range '1.*' } }
  require('blink.cmp').setup {
    keymap = {
      -- 'default' (recommended) for mappings similar to built-in completions
      --   <c-y> to accept ([y]es) the completion.
      --    This will auto-import if your LSP supports it.
      --    This will expand snippets if the LSP sent a snippet.
      -- 'super-tab' for tab to accept
      -- 'enter' for enter to accept
      -- 'none' for no mappings
      --
      -- For an understanding of why the 'default' preset is recommended,
      -- you will need to read `:help ins-completion`
      --
      -- No, but seriously. Please read `:help ins-completion`, it is really good!
      --
      -- All presets have the following mappings:
      -- <tab>/<s-tab>: move to right/left of your snippet expansion
      -- <c-space>: Open menu or open docs if already open
      -- <c-n>/<c-p> or <up>/<down>: Select next/previous item
      -- <c-e>: Hide menu
      -- <c-k>: Toggle signature help
      --
      -- See `:help blink-cmp-config-keymap` for defining your own keymap
      preset = 'default',

      -- For more advanced Luasnip keymaps (e.g. selecting choice nodes, expansion) see:
      --    https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
    },

    appearance = {
      -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
      -- Adjusts spacing to ensure icons are aligned
      nerd_font_variant = 'mono',
    },

    completion = {
      -- By default, you may press `<c-space>` to show the documentation.
      -- Optionally, set `auto_show = true` to show the documentation after a delay.
      documentation = { auto_show = false, auto_show_delay_ms = 500 },
    },

    sources = {
      default = { 'lsp', 'path', 'snippets' },
    },

    snippets = { preset = 'luasnip' },

    -- Blink.cmp includes an optional, recommended rust fuzzy matcher,
    -- which automatically downloads a prebuilt binary when enabled.
    --
    -- By default, we use the Lua implementation instead, but you may enable
    -- the rust implementation via `'prefer_rust_with_warning'`
    --
    -- See `:help blink-cmp-config-fuzzy` for more information
    fuzzy = { implementation = 'lua' },

    -- Shows a signature help window while you type arguments for a function
    signature = { enabled = true },
  }
end

-- ============================================================
-- SECTION 9: TREESITTER
-- Parser installation, syntax highlighting, folds, indentation
-- ============================================================
do
  -- [[ Configure Treesitter ]]
  --  Used to highlight, edit, and navigate code
  --
  --  See `:help nvim-treesitter-intro`

  -- NOTE: You can also specify a branch or a specific commit
  vim.pack.add { { src = gh 'nvim-treesitter/nvim-treesitter', version = 'main' } }

  -- Ensure basic parsers are installed
  local parsers = { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc' }
  require('nvim-treesitter').install(parsers)

  ---@param buf integer
  ---@param language string
  local function treesitter_try_attach(buf, language)
    -- Check if a parser exists and load it
    if not vim.treesitter.language.add(language) then return end
    -- Enable syntax highlighting and other treesitter features
    vim.treesitter.start(buf, language)

    -- Enable treesitter based folds
    -- For more info on folds see `:help folds`
    -- vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
    -- vim.wo.foldmethod = 'expr'

    -- Check if treesitter indentation is available for this language, and if so enable it
    -- in case there is no indent query, the indentexpr will fallback to the vim's built in one
    local has_indent_query = vim.treesitter.query.get(language, 'indents') ~= nil

    -- Enable treesitter based indentation
    if has_indent_query then vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()" end
  end

  local available_parsers = require('nvim-treesitter').get_available()
  vim.api.nvim_create_autocmd('FileType', {
    callback = function(args)
      local buf, filetype = args.buf, args.match

      local language = vim.treesitter.language.get_lang(filetype)
      if not language then return end

      local installed_parsers = require('nvim-treesitter').get_installed 'parsers'

      if vim.tbl_contains(installed_parsers, language) then
        -- Enable the parser if it is already installed
        treesitter_try_attach(buf, language)
      elseif vim.tbl_contains(available_parsers, language) then
        -- If a parser is available in `nvim-treesitter`, auto-install it and enable it after the installation is done
        require('nvim-treesitter').install(language):await(function() treesitter_try_attach(buf, language) end)
      else
        -- Try to enable treesitter features in case the parser exists but is not available from `nvim-treesitter`
        treesitter_try_attach(buf, language)
      end
    end,
  })
end

-- ============================================================
-- SECTION 10: OPTIONAL EXAMPLES / NEXT STEPS
-- kickstart.plugins.* examples
-- ============================================================
do
  -- The following comments only work if you have downloaded the kickstart repo, not just copy pasted the
  -- init.lua. If you want these files, they are in the repository, so you can just download them and
  -- place them in the correct locations.

  -- NOTE: Next step on your Neovim journey: Add/Configure additional plugins for Kickstart
  --
  --  Here are some example plugins that I've included in the Kickstart repository.
  --  Uncomment any of the lines below to enable them (you will need to restart nvim).
  --
  -- require 'kickstart.plugins.debug'
  -- require 'kickstart.plugins.indent_line'
  -- require 'kickstart.plugins.lint'
  -- require 'kickstart.plugins.autopairs'
  -- require 'kickstart.plugins.neo-tree'
  -- require 'kickstart.plugins.gitsigns' -- adds gitsigns recommended keymaps

  -- NOTE: You can add your own plugins, configuration, etc from `lua/custom/plugins/*.lua`
  --
  --  Uncomment the following line and add your plugins to `lua/custom/plugins/*.lua` to get going.
  -- require 'custom.plugins'
end

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
