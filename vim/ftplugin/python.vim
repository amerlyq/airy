" Indent settings.
" make Python follow PEP8 ( http://www.python.org/dev/peps/pep-0008/ )
setlocal textwidth=88
setlocal nowrap
setlocal smarttab
setlocal expandtab
setlocal tabstop=4
setlocal shiftwidth=4
setlocal softtabstop=4
setlocal nosmartindent

iabbrev  _i(  __import__("").

"⌇⡡⣓⠊⢁ USAGE: :echo
python3 << EOF
from pathlib import Path
def inferjupyterpkg(fpath):
    x = d = Path(fpath).absolute().parent
    while x.joinpath('__init__.py').exists(): x=x.parent
    return '__package__ = "' + '.'.join(d.relative_to(x).parts) + '"'
EOF
fun! InferJupyterPkg()
  return py3eval("inferjupyterpkg(r'".expand("%:p")."')")
endfun
