from enum import Enum, auto

import ranger.gui.context as ctx
import ranger.gui.widgets.browsercolumn as B


class CustomKeys(Enum):
    ext_nou = auto()
    wf_log = auto()


for key in CustomKeys:
    ctx.CONTEXT_KEYS.append(key.name)
    # exec("ctx." + key + " = False")
    setattr(ctx.Context, key.name, False)


OLD_HOOK_BEFORE_DRAWING = B.hook_before_drawing


def new_hook_before_drawing(fsobj, color_list):
    if fsobj.is_file:
        if fsobj.basename.endswith(".nou"):
            color_list.append(CustomKeys.ext_nou.name)
    elif fsobj.is_directory:
        if fsobj.basename in ("arc", "log", "todo"):
            color_list.append(CustomKeys.wf_log.name)

    return OLD_HOOK_BEFORE_DRAWING(fsobj, color_list)


B.hook_before_drawing = new_hook_before_drawing
