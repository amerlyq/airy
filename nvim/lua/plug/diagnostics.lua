--SRC https://github.com/rachartier/tiny-inline-diagnostic.nvim

vim.diagnostic.config({
    virtual_text = false,  -- Turns off native right-side inline text
    virtual_lines = false, -- Turns off native under-the-line multiline text
    -- Crucial: Prevents native jumps from automatically opening the float window
    jump = {
        on_jump = false,
    },
})

-- Jump to next diagnostic without spawning the native window
vim.keymap.set("n", "]d", function()
    if vim.diagnostic.jump then
        -- Modern Neovim (>= 0.11) API syntax
        vim.diagnostic.jump({ count = 1, float = false })
    else
        -- Legacy Neovim (0.10) API fallback syntax
        vim.diagnostic.goto_next({ float = false })
    end
end, { desc = "Next diagnostic (No native float)" })


-- Jump to previous diagnostic without spawning the native window
vim.keymap.set("n", "[d", function()
    if vim.diagnostic.jump then
        -- Modern Neovim (>= 0.11) API syntax
        vim.diagnostic.jump({ count = -1, float = false })
    else
        -- Legacy Neovim (0.10) API fallback syntax
        vim.diagnostic.goto_prev({ float = false })
    end
end, { desc = "Prev diagnostic (No native float)" })



require("tiny-inline-diagnostic").setup({
--     -- Choose a preset style for diagnostic appearance
--     -- Available: "modern", "classic", "minimal", "powerline", "ghost", "simple", "nonerdfont", "amongus"
--     preset = "modern",
--
--     -- Make diagnostic background transparent
--     transparent_bg = false,
--
    -- True: Make cursorline background transparent for diagnostics
    -- False: Prevents clear-down events when the cursor lands on empty space
    transparent_cursorline = false,
--
--     -- Customize highlight groups for colors
--     -- Use Neovim highlight group names or hex colors like "#RRGGBB"
--     hi = {
--         error = "DiagnosticError",     -- Highlight for error diagnostics
--         warn = "DiagnosticWarn",       -- Highlight for warning diagnostics
--         info = "DiagnosticInfo",       -- Highlight for info diagnostics
--         hint = "DiagnosticHint",       -- Highlight for hint diagnostics
--         arrow = "NonText",             -- Highlight for the arrow pointing to diagnostic
--         background = "CursorLine",     -- Background highlight for diagnostics
--         mixing_color = "Normal",       -- Color to blend background with (or "None")
--     },
--
--     -- List of filetypes to disable the plugin for
--     disabled_ft = {},
--
    options = {
        -- Display the source of diagnostics (e.g., "lua_ls", "pyright")
        show_source = {
            enabled = true,           -- Enable showing source names
            if_many = false,           -- Only show source if multiple sources exist for the same diagnostic
        },
--
--         -- Display the diagnostic code of diagnostics (e.g., "F401", "no-dupe-args")
--         show_code = true,
--
--         -- Use icons from vim.diagnostic.config instead of preset icons
--         use_icons_from_diagnostic = false,
--
--         -- Color the arrow to match the severity of the first diagnostic
--         set_arrow_to_diag_color = false,
--
--
--         -- Throttle update frequency in milliseconds to improve performance
--         -- Higher values reduce CPU usage but may feel less responsive
--         -- Set to 0 for immediate updates (may cause lag on slow systems)
--         throttle = 20,
--
--         -- Minimum number of characters before wrapping long messages
--         softwrap = 30,
--
--         -- Control how diagnostic messages are displayed
--         -- NOTE: When using display_count = true, you need to enable multiline diagnostics with multilines.enabled = true
--         --       If you want them to always be displayed, you can also set multilines.always_show = true.
        add_messages = {
            messages = true,           -- Show full diagnostic messages
            display_count = false,     -- Show diagnostic count instead of messages when cursor not on line
            use_max_severity = false,  -- When counting, only show the most severe diagnostic
            show_multiple_glyphs = true, -- Show multiple icons for multiple diagnostics of same severity
        },

        -- Settings for multiline diagnostics
        multilines = {
            enabled = true,           -- Enable support for multiline diagnostic messages
            always_show = true,       -- Always show messages on all lines of multiline diagnostics
            trim_whitespaces = false,  -- Remove leading/trailing whitespace from each line
            tabstop = 4,               -- Number of spaces per tab when expanding tabs
            -- Restrict which severities are shown on non-cursor lines
            -- With always_show = true: listed severities stay visible on every line,
            -- all other severities only appear on the cursor line
            severity = nil,            -- e.g. { vim.diagnostic.severity.ERROR }
          },
--
        -- Show all diagnostics on the current cursor line, not just those under the cursor
        show_all_diags_on_cursorline = true,

        -- Only show diagnostics when the cursor is directly over them, no fallback to line diagnostics
        show_diags_only_under_cursor = false,
--
--         -- Display related diagnostics from LSP relatedInformation
--         show_related = {
--             enabled = true,           -- Enable displaying related diagnostics
--             max_count = 3,             -- Maximum number of related diagnostics to show per diagnostic
--         },
--
--         -- Enable diagnostics display in insert mode
--         -- May cause visual artifacts; consider setting throttle to 0 if enabled
--         enable_on_insert = false,
--
--         -- Enable diagnostics display in select mode (e.g., during auto-completion)
--         enable_on_select = false,
--
--         -- Handle messages that exceed the window width
--         overflow = {
--             mode = "wrap",             -- "wrap": split into lines, "none": no truncation, "oneline": keep single line
--             padding = 0,               -- Extra characters to trigger wrapping earlier
--         },
--
--         -- Break long messages into separate lines
--         break_line = {
--             enabled = false,           -- Enable automatic line breaking
--             after = 30,                -- Number of characters before inserting a line break
--         },
--
--         -- Custom function to format diagnostic messages
--         -- Receives diagnostic object, returns formatted string
--         -- Example: function(diag) return diag.message .. " [" .. diag.source .. "]" end
--         format = nil,
--
--         -- Virtual text display priority
--         -- Higher values appear above other plugins (e.g., GitBlame)
--         virt_texts = {
--             priority = 2048,
--         },
--
--         -- Filter diagnostics by severity levels
--         -- Remove severities you don't want to display
--         severity = {
--             vim.diagnostic.severity.ERROR,
--             vim.diagnostic.severity.WARN,
--             vim.diagnostic.severity.INFO,
--             vim.diagnostic.severity.HINT,
--         },
--
--         -- Events that trigger attaching diagnostics to buffers
--         -- Default is {"LspAttach"}; change only if plugin doesn't work with your LSP setup
--         overwrite_events = nil,
--
        -- Automatically disable diagnostics when opening diagnostic float windows
        override_open_float = true,
--
--         -- Experimental options, subject to misbehave in future NeoVim releases
--         experimental = {
--           -- Make diagnostics not mirror across windows containing the same buffer
--           -- See: https://github.com/rachartier/tiny-inline-diagnostic.nvim/issues/127
--           use_window_local_extmarks = false,
--         },
    },
--     signs = {
--         left = "",
--         right = "",
--         diag = "●",
--         arrow = "    ",
--         up_arrow = "    ",
--         vertical = " │",
--         vertical_end = " └",
--     },
--     blend = {
--         factor = 0.22,
--     },
})


-- OR: dynamic toggle
-- vim.api.nvim_create_autocmd("LspAttach", {
--     group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
--     callback = function(args)
--         local bufnr = args.buf
--
--         -- Fast function to check if the current cursor line is completely empty
--         local function is_line_empty()
--             local line = vim.api.nvim_get_current_line()
--             return line:match("^%s*$") ~= nil
--         end
--
--         -- Handle the seamless toggle between global virtual_lines and tiny-inline
--         local function dynamic_diagnostic_toggle()
--             if is_line_empty() then
--                 -- On an empty line: Show native virtual_lines globally across the file
--                 vim.diagnostic.config({
--                     virtual_text = false,
--                     virtual_lines = true, -- Native virtual lines reveal everything
--                     jump = { float = false },
--                 }, bufnr)
--             else
--                 -- On a code line: Turn off global lines to let tiny-inline do its work isolates
--                 vim.diagnostic.config({
--                     virtual_text = false,
--                     virtual_lines = false, -- Hide native global layers
--                     jump = { float = false },
--                 }, bufnr)
--             end
--         end
--
--         -- Run the check immediately when entering a buffer
--         dynamic_diagnostic_toggle()
--
--         -- Trigger the check every time the cursor changes lines
--         vim.api.nvim_create_autocmd("CursorMoved", {
--             buffer = bufnr,
--             callback = dynamic_diagnostic_toggle,
--         })
--
--         -- Safe buffer-local jump mappings (ensuring no native jumps force open a float)
--         local opts = { buffer = bufnr, remap = false }
--         vim.keymap.set("n", "]d", function()
--             if vim.diagnostic.jump then
--                 vim.diagnostic.jump({ count = 1, float = false })
--             else
--                 vim.diagnostic.goto_next({ float = false })
--             end
--         end, opts)
--
--         vim.keymap.set("n", "[d", function()
--             if vim.diagnostic.jump then
--                 vim.diagnostic.jump({ count = -1, float = false })
--             else
--                 vim.diagnostic.goto_prev({ float = false })
--             end
--         end, opts)
--     end,
-- })
