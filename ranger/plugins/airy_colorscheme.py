import ranger.gui.context as ctx
import ranger.gui.widgets.browsercolumn as B

for key in ["ext_nou"]:
    ctx.CONTEXT_KEYS.append(key)
    # exec("ctx." + key + " = False")
    setattr(ctx.Context, key, False)


OLD_HOOK_BEFORE_DRAWING = B.hook_before_drawing


def new_hook_before_drawing(fsobject, color_list):
    if fsobject.basename.endswith(".nou"):
        color_list.append("ext_nou")

    return OLD_HOOK_BEFORE_DRAWING(fsobject, color_list)


B.hook_before_drawing = new_hook_before_drawing
