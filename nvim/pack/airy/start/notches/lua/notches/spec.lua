--%GenBy: /data/aura/just/use/pkg/just/flower/notches/luagen.py
local M = {}

M.highlights = {
  NotchAdd = { fg = '#5faf00', bold = true, ctermfg = 76 },
  NotchAlt = { fg = '#dfaf00', bold = true, ctermfg = 178 },
  NotchCom = { fg = '#958e68', bold = true, ctermfg = 101 },
  NotchDev = { fg = '#0087ff', bold = true, ctermfg = 33 },
  NotchDid = { fg = '#767676', bold = true, ctermfg = 243 },
  NotchErr = { fg = '#ff2525', bold = true, ctermfg = 196 },
  NotchFix = { fg = '#ff5f00', bold = true, ctermfg = 202 },
  NotchHdr = { fg = '#004fff', bold = true, ctermfg = 27 },
  NotchInf = { fg = '#00afdf', bold = true, ctermfg = 38 },
  NotchMsg = { fg = '#5f5fdf', bold = true, ctermfg = 62 },
  NotchRef = { fg = '#00af00', bold = true, ctermfg = 28 },
  NotchRul = { fg = '#1f881f', bold = true, ctermfg = 22 },
  NotchSem = { fg = '#df40af', bold = true, ctermfg = 163 },
  NotchTbd = { fg = '#ff5faf', bold = true, ctermfg = 169 },
  NotchUnq = { fg = '#dfdfdf', bold = true, ctermfg = 188 },
}

M.patterns = {
  NotchAdd = 'GREN|ADD|ALSO|E\\.G|e\\.g|NEED|FIND|BET|BETTER|ADVICE',
  NotchAlt = 'YELW|ALT|OR|CASE|CASEs|THINK|IDEA|IDEAs|CHG|RENAME|CALL|CMP|I\\.E|i\\.e|EXAM|EXAMINE|OPT|OPTs|OPTL|OPTIONAL',
  NotchCom = 'EXPL|EXPLAIN|COS|BECAUSE|AGAIN|EQ',
  NotchDev = 'BLUE|DEV|DEVELOP|CFG|CFGs|ENH|ENHANCE|HACK|NICE|RFC|SEP|SEPARATE|SPL|SPLIT|DECI|DECIDE',
  NotchDid = 'GREY|DONE|FIXED|WKRND|TEMP|OLD|UNUSED|OBSOL|DEPR|DSBLD|DISABLED|TL;DR|FMT|FORMAT|RND|OBS',
  NotchErr = 'RED|Qs|RQ|RQs|REQUIRE|ERR|ERRs|ERROR|BUG|BUGs|REGR|XXX|WTF|BAD|FAIL|FAILED|FAILURE|CRIT|CRITICAL|RUSH',
  NotchFix = 'ORNG|BUT|DONT|TBD|WiP|WIP|FIX|FIXME|FIXUP|WARN|WARNING|ATT|ATTN|ATTENTION|REM|REMOVE|BLK|BLOCK|BLOCKED|BlockedBy',
  NotchHdr = 'OFF|OFFL|OFCL|OFFICIAL|DRAW|DIY|MAKE|WF|WFs|WORKFLOW|PRIA|PRIOR_ART|FUT|FUTURE|RE|REV\\-ENG|REVL|REVEAL|XLR|EXPLORE|XP|XPs|XPMT',
  NotchInf = 'CYAN|INF|INFO|SRC|VAR|VARs|VIZ|ALG|ALGO|SEQ|HYP|HYPO|CONT|CONTR|IMPL|ARCH|PERF|TALK|SECU|SECURE|RELI|RELY|MMAP',
  NotchMsg = 'PURP|NB|NOTE|N\\.B\\.|USE|USAGE|DEMO|DFL|DEFAULT|STD|SUM|SUMMARY|DBG|DEBUG|I\\.A|i\\.a|DEP|DEPs|DEPENDS|WHY',
  NotchRef = 'SEE|READ|REF|REFERENCE|TUT|TUTORIAL|BLOG|BOOK|LIOR|OV|OVERVIEW',
  NotchRul = 'RUL|RULE|RULEs|LORE|TRAIN|VREC',
  NotchSem = 'API|ex\\~|EXAMPLE|SEIZE|BUMP|EVO|EVOL|EVOLVE',
  NotchTbd = 'PINK|TODO|CHECK|TRY|MOVE|NOT|REQ|REQUEST|MAYBE|WAIT|WAITING',
  NotchUnq = 'THEO',
}

return M
