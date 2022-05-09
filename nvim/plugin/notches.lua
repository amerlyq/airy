--%DEBUG: :echo getmatches()

local highlights = {
  NotchAdd = { fg='#5faf00', ctermfg=76, bold=true },
  NotchAlt = { fg='#dfaf00', ctermfg=178, bold=true },
  NotchCom = { fg='#958e68', ctermfg=101, bold=true },
  NotchDev = { fg='#0087ff', ctermfg=33, bold=true },
  NotchDid = { fg='#767676', ctermfg=243, bold=true },
  NotchErr = { fg='#ff2525', ctermfg=196, bold=true },
  NotchFix = { fg='#ff5f00', ctermfg=202, bold=true },
  NotchHdr = { fg='#004fff', ctermfg=27, bold=true },
  NotchInf = { fg='#00afdf', ctermfg=38, bold=true },
  NotchMsg = { fg='#5f5fdf', ctermfg=62, bold=true },
  NotchRef = { fg='#00af00', ctermfg=28, bold=true },
  NotchRul = { fg='#1f881f', ctermfg=22, bold=true },
  NotchSem = { fg='#df40af', ctermfg=163, bold=true },
  NotchTbd = { fg='#ff5faf', ctermfg=169, bold=true },
  NotchUnq = { fg='#dfdfdf', ctermfg=188, bold=true },
}
local ns_id = 0  -- FAIL: vim.api.nvim_create_namespace('notches')
local nvim_set_hl = vim.api.nvim_set_hl
for hlgrp, attrs in pairs(highlights) do
  nvim_set_hl(ns_id, hlgrp, attrs)
end

local patterns = {
  NotchAdd = '%(GREN|ADD|ALSO|E\\.G|e\\.g|NEED|FIND|BET|BETTER|ADVICE)',
  NotchAlt = '%(YELW|ALT|OR|CASE|THINK|IDEA|CHG|RENAME|CALL|CMP|I\\.E|i\\.e|EXAM|EXAMINE|OPT|OPTL|OPTIONAL)',
  NotchCom = '%(EXPL|EXPLAIN|COS|BECAUSE|AGAIN)',
  NotchDev = '%(BLUE|DEV|DEVELOP|CFG|ENH|ENHANCE|HACK|NICE|RFC|SEP|SEPARATE|SPL|SPLIT|DECI|DECIDE)',
  NotchDid = '%(GREY|DONE|FIXED|WKRND|TEMP|UNUSED|OBSOL|DEPR|DSBLD|DISABLED|TL;DR|FMT|FORMAT)',
  NotchErr = '%(RED|Qs|RQ|RQs|REQUIRE|ERR|ERRs|ERROR|BUG|BUGs|REGR|XXX|WTF|BAD|FAIL|FAILED|FAILURE|CRIT|CRITICAL)',
  NotchFix = '%(ORNG|BUT|DONT|TBD|WiP|WIP|FIX|FIXME|FIXUP|WARN|WARNING|ATT|ATTN|ATTENTION|REM|REMOVE|OPTS|OPTIONS|BLK|BLOCK|BLOCKED|BlockedBy)',
  NotchHdr = '%(OFF|OFFL|OFCL|OFFICIAL|DRAW|WF|WFs|WORKFLOW|PRIA|PRIOR_ART|FUT|FUTURE|RE|REV\\-ENG|REVL|REVEAL|XLR|EXPLORE|XP|EXPT)',
  NotchInf = '%(CYAN|INF|INFO|SRC|VAR|VARs|VIZ|ALG|ALGO|SEQ|HYP|HYPO|CONT|CONTR|IMPL|ARCH|PERF|TALK|SECU|SECURE|RELI|RELY|MMAP)',
  NotchMsg = '%(PURP|NB|NOTE|N\\.B\\.|USE|USAGE|DEMO|DFL|DEFAULT|STD|SUM|SUMMARY|DBG|DEBUG|I\\.A|i\\.a|DEP|DEPs|DEPS|DEPENDS)',
  NotchRef = '%(SEE|READ|REF|REFERENCE|TUT|TUTORIAL|BLOG|BOOK|LIOR|OV|OVERVIEW)',
  NotchRul = '%(RUL|RULE|RULEs|LORE)',
  NotchSem = '%(ex:|EXAMPLE|SEIZE|BUMP|EVO|EVOL|EVOLVE)',
  NotchTbd = '%(PINK|TODO|CHECK|TRY|MOVE|NOT|REQ|REQUEST|MAYBE|WAIT|WAITING)',
  NotchUnq = '%(THEO)',
}
local matchadd = vim.fn.matchadd
-- local rpfx = '\\v%(^|.*!|\\A@1<=)'
-- local rsfx = '%(!.*|[:?*.=~]+|\\A@=|$)'
local rpfx = '\\v<'
local rsfx = '%(>|[:?=])'

local function notches_register()
  vim.fn.clearmatches()
  for hlgrp, vrgx in pairs(patterns) do
    matchadd(hlgrp, rpfx.. vrgx ..rsfx, -1)
  end
end

-- , 'Syntax', 'ColorScheme'
vim.api.nvim_create_autocmd({'WinEnter'}, {
  desc = "(flower) register notches everywhere",
  group = vim.api.nvim_create_augroup('Notches', { clear = true }),
  callback = notches_register
})

notches_register()
