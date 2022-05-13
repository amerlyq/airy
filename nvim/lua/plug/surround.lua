require("surround").setup {
  prefix = "q",
  context_offset = 20,
  load_autogroups = false,
  mappings_style = "sandwich",
  -- FIXME: use <C-q> inof <C-s> for insert
  map_insert_mode = true,
  -- quotes = { "'", '"' },
  -- brackets = { "(", '{', '[' },
  -- space_on_closing_char = false,
  pairs = {
    nestable = {
      ["("] = { "(", ")" },
      ["["] = { "[", "]" },
      ["{"] = { "{", "}" },
      ["<"] = { "<", ">" },
    },
    linear = {
      -- q = { "'", "'" },
      -- t = { "`", "`" },
      -- d = { '"', '"' },
      b = { "<b>", "</b>" },
      i = { "<i>", "</i>" },
      u = { "<u>", "</u>" },
    },
  },
}
