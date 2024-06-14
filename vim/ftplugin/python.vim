" Indent settings.
" make Python follow PEP8 ( http://www.python.org/dev/peps/pep-0008/ )
setlocal textwidth=112
setlocal nowrap
setlocal smarttab
setlocal expandtab
setlocal tabstop=4
setlocal shiftwidth=4
setlocal softtabstop=4
setlocal nosmartindent

" iabbrev  _i(  __import__("").

"⌇⡡⣓⠊⢁ USAGE: :echo
fun! InferJupyterPkg()
python3 << EOF
from pathlib import Path
def inferjupyterpkg(fpath):
    x = d = Path(fpath).absolute().parent
    while x.joinpath('__init__.py').exists(): x=x.parent
    return '__package__ = "' + '.'.join(d.relative_to(x).parts) + '"'
EOF
  return py3eval("inferjupyterpkg(r'".expand("%:p")."')")
endfun


"" FAIL:BET: use snippets plugin
" inoreab <buffer> <expr> cl (match(getline('.'), "^cl\\s*$") < 0 ? "cl" : "class A:\n    def __init__(self):\n        self.a = 1")
" inoreab <buffer> <expr> s. (match(getline('.'), "^\\s\\+s\\.\\s*$") < 0 ? "s." : "self.")
