# SEE: /usr/lib/python3.10/site-packages/libqtile/backend/x11/xkeysyms.py
import os
import time
from typing import cast

from libqtile import bar, hook, layout, qtile, widget
from libqtile.backend.x11 import window
from libqtile.config import (Click, Drag, EzKey, Group, Key, KeyChord, Match,
                             Screen)
from libqtile.lazy import lazy
from libqtile.utils import guess_terminal
from psutil import Process

# pylint:disable=invalid-name


def K(keydef: str, *cmds: str, desc: str = None) -> EzKey:
    return EzKey(keydef, *cmds, desc=desc)  # type:ignore


prev_layout = 0  # lazy.current_group.current_layout
def toggle_maxlayout(qtile, laymax: int = 2) -> None:
    global prev_layout
    l = qtile.current_group.current_layout
    if l == laymax:
        l = prev_layout
    else:
        prev_layout = l
        l = laymax
    qtile.current_group.use_layout(l)


mod = "mod4"
terminal = ["env", "--chdir=/t", cast(str, guess_terminal())]
ranger = ["st", "-e", "ranger", "--choosedir=/run/user/1000/ranger/cwd", "--"]

keys = [
    # A list of available commands that can be bound to keys can be found
    # at https://docs.qtile.org/en/latest/manual/config/lazy.html
    K("M-a", lazy.screen.toggle_group(), desc="Back'n'forth"),
    # Switch between windows
    # K("M-h", lazy.layout.left(), desc="Move focus to left"),
    K("M-h", lazy.spawn(terminal), desc="Launch terminal"),
    K("M-<semicolon>", lazy.layout.right(), desc="Move focus to right"),
    K("M-j", lazy.layout.down(), desc="Move focus down"),
    K("M-k", lazy.layout.up(), desc="Move focus up"),
    K("M-S-<quoteright>", lazy.layout.previous(), desc="Move focus back"),
    K("M-<quoteright>", lazy.layout.next(), desc="Move window focus to other window"),
    # Move windows between left/right columns or move up/down in current stack.
    # Moving out of range in Columns layout will create new column.
    K("M-S-h", lazy.layout.shuffle_left(), desc="Move window to the left"),
    K("M-S-l", lazy.layout.shuffle_right(), desc="Move window to the right"),
    K("M-S-j", lazy.layout.shuffle_down(), desc="Move window down"),
    K("M-S-k", lazy.layout.shuffle_up(), desc="Move window up"),
    # Grow windows. If current window is on the edge of screen and direction
    # will be to screen edge - window would shrink.
    K("M-C-h", lazy.layout.grow_left(), desc="Grow window to the left"),
    K("M-C-l", lazy.layout.grow_right(), desc="Grow window to the right"),
    K("M-C-j", lazy.layout.grow_down(), desc="Grow window down"),
    K("M-C-k", lazy.layout.grow_up(), desc="Grow window up"),
    K("M-n", lazy.layout.normalize(), desc="Reset all window sizes"),
    K("M-m", lazy.layout.maximize(), desc="Zoom window in layout"),
    # K("M-S-m", lazy.layout.minimize(), desc="Zoom window in layout"),
    K("M-S-m", lazy.layout.grow(), desc="Zoom-in window"),
    K("M-S-n", lazy.layout.shrink(), desc="Zoom-out window"),
    K("M-C-w", lazy.window.toggle_floating(), desc="Toggle floating"),
    # EzKey('M-w', f.toggle_focus_floating(), f.warp_cursor_here()),
    # K("M-w", f.toggle_focus_floating(), desc="Focus floating"),
    K(
        "M-<Tab>",
        lazy.layout.toggle_split(),
        desc="Toggle between split and unsplit sides of stack"
        # * Split = all windows displayed
        # * Unsplit = 1 window displayed, like Max layout, but still with multiple stack panes
    ),
    K("M-<Return>", lazy.spawn(terminal), desc="Launch terminal"),
    K("M-<space>", lazy.spawn(ranger + ["/@/airy"]), desc="Launch fm"),
    K("M-S-<space>", lazy.spawn(ranger + ["/@/just"]), desc="Launch fm"),
    KeyChord(
        [mod],
        "o",
        [
            Key([], "f", lazy.spawn(["/@/airy/firefox/run"]), desc="Launch firefox"),
            Key([], "h", lazy.spawn(["st", "-e", "htop"]), desc="Launch htop"),
            Key([], "n", lazy.spawn(["st", "-e", "ncmpcpp"]), desc="Launch ncmpcpp"),
        ],
    ),  # , mode="Launch"
    K("M-u", lazy.spawn(["qutebrowser"]), desc="Launch browser"),
    # Toggle between different layouts as defined below
    K("M-<slash>", lazy.next_layout(), desc="Toggle between layouts"),
    # K("M-slash", lazy.next_layout(), desc="Toggle between layouts"),
    # K("M-question", lazy.previous_layout(), desc="Toggle between layouts"),
    # K("M-S-slash", lazy.prev_layout(), desc="Toggle between layouts"),
    # K("M-f", lazy.window.toggle_fullscreen(), desc="Toggle fullscreen"),
    # K("M-f", lazy.next_layout(), desc="Toggle fullscreen"),
    # K("M-f", lazy.to_layout_index(2), desc="Fullscreen"),
    K("M-f", lazy.function(toggle_maxlayout), desc="Fullscreen"),
    # K("M-S-x", lazy.hide_show_bar("top")),
    # K("M-x", lazy.hide_show_bar("bottom")),
    K("M-S-f", lazy.hide_show_bar("bottom")),
    K("M-<backslash>", lazy.window.kill(), desc="Kill focused window"),
    K("M-C-r", lazy.reload_config(), desc="Reload the config"),
    K("M-C-q", lazy.shutdown(), desc="Shutdown Qtile"),
    K("M-e", lazy.spawncmd(), desc="Spawn a command using a prompt widget"),
    K("M-<minus>", lazy.spawn("xset dpms force off".split()), desc="Screen off"),
    ## FAIL: unknown keysym
    # Key([], "XF86AudioRaiseVolume", lazy.spawn("amixer -c 0 -q set Master 1dB+")),
    # Key([], "XF86AudioLowerVolume", lazy.spawn("amixer -c 0 -q set Master 1dB-")),
    # Key([], "XF86AudioMute", lazy.spawn("amixer -c 0 -q set Master toggle")),
    K("M-<Page_Up>", lazy.spawn("amixer -c 0 -q set Master 1dB+"), desc="Volume up"),
    K(
        "M-<Page_Down>",
        lazy.spawn("amixer -c 0 -q set Master 1dB-"),
        desc="Volume down",
    ),
    # K("M-x", lazy.spawn(["env", "--chdir=/d/research/clipboard/infinitecopy", "--",
    #                         "poetry", "run", "infinitecopy"]), desc="Clipboard"),
    K("M-x", lazy.spawn(["copyq", "toggle"]), desc="Clipboard toggle"),
    K("M-C-x", lazy.spawn(["copyq", "edit -1"]), desc="Clipboard edit"),
    K("M-c", lazy.spawn(["copyq", "previous"]), desc="Clipboard prev"),
    K("M-v", lazy.spawn(["copyq", "next"]), desc="Clipboard next"),
]

groups = [Group(i) for i in "123456789"]

for i in groups:
    keys.extend(
        [
            # mod1 + letter of group = switch to group
            Key(
                [mod],
                i.name,
                lazy.group[i.name].toscreen(),
                desc="Switch to group {}".format(i.name),
            ),
            # mod1 + shift + letter of group = switch to & move focused window to group
            Key(
                [mod, "shift"],
                i.name,
                lazy.window.togroup(i.name, switch_group=True),
                desc="Switch to & move focused window to group {}".format(i.name),
            ),
            # Or, use below if you prefer not to switch to that group.
            # # mod1 + shift + letter of group = move focused window to group
            # Key([mod, "shift"], i.name, lazy.window.togroup(i.name),
            #     desc="move focused window to group {}".format(i.name)),
        ]
    )

layouts = [
    # layout.Columns(border_focus_stack=["#d75f5f", "#8f3d3d"], border_width=4),
    # Try more layouts by unleashing below layouts.
    # layout.Stack(num_stacks=2),
    # layout.Bsp(),
    # layout.Matrix(),
    layout.VerticalTile(
        ratio=0.6, border_focus="#00af00", border_normal="#000000", border_width=2
    ),
    layout.MonadTall(ratio=0.587),
    layout.Max(),
    # layout.MonadWide(),
    # layout.RatioTile(),
    # layout.Tile(),
    # layout.TreeTab(),
    # layout.Zoomy(),
]

widget_defaults = dict(
    font="monospace",
    fontsize=36,
    padding=3,
)
extension_defaults = widget_defaults.copy()

screens = [
    Screen(
        bottom=bar.Bar(
            [
                widget.CurrentLayoutIcon(),
                # widget.AGroupBox(),
                widget.GroupBox(highlight_method="block", inactive="242424"),
                widget.Sep(),
                widget.TextBox(" "),
                widget.Prompt(),
                widget.WindowName(),
                widget.Chord(
                    chords_colors={
                        "launch": ("#ff0000", "#ffffff"),
                    },
                    name_transform=lambda name: name.upper(),
                ),
                # widget.TextBox("default config", name="default"),
                # widget.TextBox("Press &lt;M-r&gt; to spawn", foreground="#d75f5f"),
                widget.Systray(),
                # widget.Clock(format="%Y-%m-%d %a %I:%M %p"),
                widget.NetGraph(),
                widget.MemoryGraph(fill_color="#00aa00"),
                widget.HDDBusyGraph(device="nvme0n1", graph_color="#ad570f"),
                widget.CPUGraph(),
                widget.Battery(
                    format="{char}{percent:2.0%} {hour:d}h{min:02d}m {watt:.2f}W",
                    foreground="#00971f",
                ),
                widget.PulseVolume(),
                widget.QuickExit(default_text="[X]", countdown_format="[{}]"),
                widget.Clock(
                    format="%Y-%m-%d-%a-W%V", update_interval=60, foreground="#fd971f"
                ),
                widget.Clock(format=" %H:%M", update_interval=5),
            ],
            40,
            # border_width=[2, 0, 2, 0],  # Draw top and bottom borders
            # border_color=["ff00ff", "000000", "ff00ff", "000000"]  # Borders are magenta
        ),
    ),
]

# Drag floating layouts.
mouse = [
    Drag(
        [mod],
        "Button1",
        lazy.window.set_position_floating(),
        start=lazy.window.get_position(),
    ),
    Drag(
        [mod], "Button3", lazy.window.set_size_floating(), start=lazy.window.get_size()
    ),
    Click([mod], "Button2", lazy.window.bring_to_front()),
]

dgroups_key_binder = None
dgroups_app_rules = []  # type: list
follow_mouse_focus = True
bring_front_click = False
cursor_warp = False
floating_layout = layout.Floating(
    float_rules=[
        # Run the utility of `xprop` to see the wm class and name of an X client.
        *layout.Floating.default_float_rules,
        Match(wm_class="confirmreset"),  # gitk
        Match(wm_class="makebranch"),  # gitk
        Match(wm_class="maketag"),  # gitk
        Match(wm_class="ssh-askpass"),  # ssh-askpass
        Match(title="branchdialog"),  # gitk
        Match(title="pinentry"),  # GPG key password entry
        Match(wm_class="pinentry-qt"),  # GPG key password entry
        Match(
            wm_class="copyq"
        ),  # doRectFloat (W.RationalRect (1/6) (1/5) (4/10) (4/10))
    ]
)
auto_fullscreen = True
focus_on_window_activation = "smart"
reconfigure_screens = True

# If things like steam games want to auto-minimize themselves when losing
# focus, should we respect this or not?
auto_minimize = True

# When using the Wayland backend, this can be used to configure input devices.
wl_input_rules = None

# XXX: Gasp! We're lying here. In fact, nobody really uses or cares about this
# string besides java UI toolkits; you can see several discussions on the
# mailing lists, GitHub issues, and other WM documentation that suggest setting
# this string if your java app doesn't work correctly. We may as well just lie
# and say that we're a working one by default.
#
# We choose LG3D to maximize irony: it is a 3D non-reparenting WM written in
# java that happens to be on java's whitelist.
wmname = "LG3D"


# Mpv player in floating mode · Issue #2651 · qtile/qtile ⌇⡢⢼⡸⣣
#   https://github.com/qtile/qtile/issues/2651
@hook.subscribe.client_new
def disable_floating(window):
    rules = [Match(wm_class="mpv"), Match(wm_instance_class="mpv")]

    if any(window.match(rule) for rule in rules):
        window.togroup(qtile.current_group.name)
        window.cmd_disable_floating()


prev_focus = None
prev_cbsel = None


def audit_log(text: str, grp: str) -> None:
    ts = time.time()
    sfx = time.strftime("%Y/%Y-%m-%d", time.localtime(ts))
    dst = f"/d/audit/{os.uname().nodename}/{grp}/{sfx}"

    # TODO:PERF: write in batch/second inof each ctxswitch
    with open(dst, "a", encoding="utf-8") as f:
        # ALSO: state :: w.maximized w.minimized w.floating:
        line = f"{int(ts)} {text}\n"
        # TODO: ensure file ends with \n before append
        f.write(line)


@hook.subscribe.client_focus
def audit_focus(w: window.Window) -> None:
    global prev_focus
    # w = qtile.current_screen.group.current_window
    if not w or w.wid == prev_focus:
        return
    prev_focus = w.wid

    nm = "?"
    if wikls := w.get_wm_class():
        inst, kls = wikls
        nm = inst if inst == kls else inst + " " + kls

    # PERF: cache mapping pid->name
    # TODO: app path/pid which have this window
    ps = Process(w.get_pid())
    with ps.oneshot():
        pid = ps.pid
        app = ps.name()  # ps.exe(), ps.cmdline(), ps.create_time()

    audit_log(f"{app} {pid} {nm} {w.wid}\t{w.name}", "wm")


@hook.subscribe.selection_change
def audit_cb(name, selection) -> None:
    global prev_cbsel
    oid = selection["owner"]
    sel = selection["selection"]
    if name != "CLIPBOARD" or (oid, sel) == prev_cbsel:
        return
    prev_cbsel = (oid, sel)

    ## FAIL: !copyq and !qtile always re-own selections
    # if oid in qtile.windows_map:
    #     owner = qtile.windows_map[oid].window
    # else:
    #     # owner = xcbq.window.XWindow(qtile.core.conn, oid)
    #     owner = window.Window(window.XWindow(qtile.core.conn, oid), qtile)

    ## FUT:ADD: black-listing
    # if owner_class := owner.get_wm_class():
    #     if any(x in owner_class for x in blacklist):
    #         return

    sel = sel.rstrip().replace("\r", "").replace("\n", "\r")
    cnt = len(sel)
    nl = sel.count("\n") + 1
    maxlen = 1024
    if cnt > maxlen:
        sel = sel[:maxlen] + "..."

    audit_log(f"{oid} {nl}/{cnt}\t{sel}", "cb")


# def toggle_focus_floating():
#     """Toggle focus between floating window and other windows in group"""
#
#     @lazy.function
#     def _toggle_focus_floating(qtile):
#         group = qtile.current_group
#         switch = "non-float" if qtile.current_window.floating else "float"
#         logger.debug(
#             f"toggle_focus_floating: switch = {switch}\t current_window: {qtile.current_window}"
#         )
#         logger.debug(f"focus_history: {group.focus_history}")
#
#         for win in reversed(group.focus_history):
#             logger.debug(f"{win}: {win.floating}")
#             if switch == "float" and win.floating:
#                 # win.focus(warp=False)
#                 group.focus(win)
#                 return
#             if switch == "non-float" and not win.floating:
#                 # win.focus(warp=False)
#                 group.focus(win)
#                 return
#
#     return _toggle_focus_floating
