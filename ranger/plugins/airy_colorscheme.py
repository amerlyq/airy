import ranger.gui.context as ctx
import ranger.gui.widgets.browsercolumn as B

for key in ["ext_nou"]:
    ctx.CONTEXT_KEYS.append(key)
    # exec("ctx." + key + " = False")
    setattr(ctx.Context, key, False)


OLD_HOOK_BEFORE_DRAWING = B.hook_before_drawing


def new_hook_before_drawing(fsobj, color_list):
    if fsobj.is_file and fsobj.basename.endswith(".nou"):
        color_list.append("ext_nou")

    return OLD_HOOK_BEFORE_DRAWING(fsobj, color_list)


B.hook_before_drawing = new_hook_before_drawing
