local M = {}
M.__index = M

local NOOP = function() end

local function build_items()
  local kind = require('blink.cmp.types').CompletionItemKind.Keyword
  local items = {}  -- ALT: = { "foo", "bar", "baz", "qux", "myCustomFunction" }
  for hlgrp, vrgx in pairs(require('notches.spec').patterns) do
    -- hlgrp = hlgrp:gsub('^Notch', '')
    vrgx = vrgx:gsub('[\\]', '')
    for word in string.gmatch(vrgx, '([^|]+)') do
      table.insert(items, { label = word, kind = kind, insertText = word,
        -- FUT: populate comments from /d/just/flower/notches/spec.py
        documentation = { kind = "markdown", value = "`:" .. hlgrp .. "`" },
      })
    end
  end
  return items
end

local cached_items = build_items()

local function shallow_copy_items(items)
  local out = {}
  for i, item in ipairs(items) do
    out[i] = { label = item.label, kind = item.kind, insertText = item.insertText, documentation = item.documentation }
  end
  return out
end

function M.new(opts)
  return setmetatable({ opts = opts }, M)
end

function M:get_completions(ctx, callback)
  -- CHECK: blink mutates returned items, so hand out a deep copy each time
  callback({ items = shallow_copy_items(cached_items),
    is_incomplete_backward = false,
    is_incomplete_forward = false
  })
  return NOOP -- no-op cancel fn, request is synchronous
end

return M
