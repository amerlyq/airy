from enum import Enum, auto

import ranger.gui.context as ctx
import ranger.gui.widgets.browsercolumn as B


class CustomKeys(Enum):
    ext_nou = auto()
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


def new_hook_before_drawing(fsobj, color_list):
    nm = fsobj.basename
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
