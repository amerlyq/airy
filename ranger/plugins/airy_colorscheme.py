import os
import re
from enum import Enum, auto

import ranger.gui.context as ctx
import ranger.gui.widgets.browsercolumn as B
from ranger.container.fsobject import FileSystemObject

try:
    from plugins import vdconf
except ImportError:
    import vdconf


class CustomKeys(Enum):
    annexed = auto()
    link_link = auto()
    link_annex = auto()
    ext_nou = auto()
    clip_suffix = auto()
    clip_v32 = auto()
    wf_log = auto()
    wf_todo = auto()
    wf_ref = auto()
    wf_gen = auto()
    wf_misc = auto()


for key in CustomKeys:
    ctx.CONTEXT_KEYS.append(key.name)
    # exec("ctx." + key + " = False")
    setattr(ctx.Context, key.name, False)


OLD_HOOK_BEFORE_DRAWING = B.hook_before_drawing
_CLIP_SUFFIX_RE = re.compile(r"_(?:" + vdconf.CLIP_SUFFIX + r")$")
_V32_RE = re.compile(r"(?:^|_)v32(?:_|$)")


def new_hook_before_drawing(
    fsobj: FileSystemObject, color_list: list[str]
) -> list[str]:
    nm = fsobj.basename
    if fsobj.is_file and fsobj.video:
        stem = os.path.splitext(nm)[0]
        if _CLIP_SUFFIX_RE.search(stem):
            color_list.append(
                CustomKeys.clip_v32.name
                if _V32_RE.search(stem)
                else CustomKeys.clip_suffix.name
            )
    if fsobj.is_link:
        try:
            dst = os.readlink(fsobj.path)
        except FileNotFoundError:
            pass
        else:
            if not dst.startswith("/") and ".git/annex/objects/" in dst:
                color_list.append(CustomKeys.annexed.name)
            elif os.path.islink(dst):
                if ".git/annex/objects/" in os.readlink(dst):
                    color_list.append(CustomKeys.link_annex.name)
                else:
                    color_list.append(CustomKeys.link_link.name)
    if fsobj.is_file:
        if nm.endswith(".nou"):
            color_list.append(CustomKeys.ext_nou.name)
    elif fsobj.is_directory:
        if nm in ("arc", "log"):
            color_list.append(CustomKeys.wf_log.name)
        elif nm in ("todo", "seize"):
            color_list.append(CustomKeys.wf_todo.name)
        elif nm.startswith("&"):
            color_list.append(CustomKeys.wf_ref.name)
        elif nm.startswith("_") or nm in ("build", "out"):
            color_list.append(CustomKeys.wf_gen.name)
        elif nm.startswith("#"):
            color_list.append(CustomKeys.wf_misc.name)

    return OLD_HOOK_BEFORE_DRAWING(fsobj, color_list)


B.hook_before_drawing = new_hook_before_drawing
