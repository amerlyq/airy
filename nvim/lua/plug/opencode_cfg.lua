-- Minimal config (only non-default overrides)

require("opencode").setup({
  default_mode = "plan",  -- DFL=build

  keymaps = {
    -- Explicit open/close (so you don't depend on defaults)
    open = "<leader>oC",
    close = "<leader>oc",

    -- Mode control: Plan <-> Build (your architectural gate)
    switch_mode = "<leader>om",

    -- Diff navigation for fast single-pass review
    diff_open = "<leader>od",
    diff_next = "]e",
    diff_prev = "[e",

    -- Revert just the last AI step (prompt-granular undo)
    diff_revert_all_last_prompt = "<leader>oR",
    diff_revert_this_last_prompt = "<leader>or",

    -- Context steering (tight iteration cleanup loop)
    add_visual_selection = "<leader>oa",
    clear_context = "<leader>oX",

    -- Intentionally NOT setting quick_chat (o/)
    -- to avoid auto-applied edits workflow.
  },
})
