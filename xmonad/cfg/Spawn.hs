-- vim: ts=2:sw=2:sts=2
module XMonad.Config.Amer.Spawn (
    keys
) where

import Control.Arrow (second)
import XMonad                       (spawn, windows, doShift, doFloat, withWindowSet, (=?))
import XMonad.StackSet              (view, shift, currentTag)
import XMonad.Actions.SpawnOn       (spawnHere, spawnAndDo)
import XMonad.Actions.WindowGo      (runOrRaise, raiseMaybe)
import XMonad.ManageHook            (className, appName, title, stringProperty, (<&&>), (<+>))
import XMonad.Hooks.ManageHelpers   (doCenterFloat, (/=?))
import XMonad.Hooks.InsertPosition  (insertPosition, Position(Master, Above, Below), Focus(Newer, Older))
import XMonad.Util.NamedScratchpad  (namedScratchpadAction)

import XMonad.Config.Amer.Common     (inGroup, feedCmd)
import XMonad.Config.Amer.Scratchpad (myScratchpads)
import XMonad.Config.Amer.Navigation (nextEmpty)

keys = main ++ scratchpad ++ media

-- TODO: insert into M-o / M-S-o menus to be able open on new wksp
main = concat
  [ [ ("M-"     ++ k , spawnHereAt Below  t)
    , ("M-S-"   ++ k , spawnHereAt Master t)
    ] -- NOTE: We have M-o <Space> for floating terminal instead of (spawnAndDo doCenterFloat t).
    | (k, t) <-
    [ ("<Space>", "r.t")
    , ("<Return>", "r.t r.ranger")
    , ("C-<Space>", "r.t -M")  -- WARNING: if broken >> HW problem
    , ("C-<Return>", "r.t -M r.ranger")
    , ("M1-<Space>", "r.wm-run-xcwd r.t")
    , ("u" , "r.b")
    -- "r.b" open on new empty wksp
    -- "r.b" focus already opened one (like M-w works)
    -- THINK: is "r.b" link suitable, if I use "u" anyway (url)
    -- THINK:ENH: make M-g * to go to already opened instead of using mods
    ]
  ]
  where
    spawnHereAt pos cmd = withWindowSet $ \ws -> spawnAndDo (doShift (currentTag ws) <+> insertPosition pos Newer) cmd

---- Scratchpads
-- TODO:ADD: M-s <Space> (export sPrf -- secondary prefix) -- jump to nearest next/prev(S-<Space>) empty wksp instead of <Bksp>
scratchpad = (concat . (`map` [
      inGroup "M-o",
      inGroup "M-S-o" . map (second (\f -> nextEmpty view >> f))
  ]) . flip ($) . concat) [
    [ ("M-o", windows $ view "NSP")
    , ("M-S-o", windows $ shift "NSP")
    , ("f" , runOrRaise "firefox" $ className =? "Firefox")
    , ("p" , runOrRaise "r.pidgin" $ className =? "Pidgin" <&&> stringProperty "WM_WINDOW_ROLE" =? "buddy_list")
    , ("s" , runOrRaise "skypeforlinux" $ className =? "Skype Preview")
    -- , ("S" , runOrRaise "skype" $ className =? "Skype" <&&> title /=? "Options" <&&> stringProperty "WM_WINDOW_ROLE" /=? "Chats" <&&> stringProperty "WM_WINDOW_ROLE" /=? "CallWindowForm")
    -- FIXME: broken opening on new wksp?
    , ("m" , raiseMaybe (spawn "r.t -n mutt -e mutt") (appName =? "mutt"))
    , ("M" , raiseMaybe (spawn "r.t -n muttR -e mutt -R") (appName =? "muttR"))
    , ("<F1>", namedScratchpadAction myScratchpads "help")
    ],
    -- Open new or focus the already existing one
    [ ([head nm], namedScratchpadAction myScratchpads nm)
    | nm <- ["agenda", "htop", "ipython", "j8", "lyrics", "ncmpcpp", "todo"]
    ],
    -- Open new window always
    [ ("S-" ++ [head nm], spawnHere $ "r.tf -e " ++ nm)
    | nm <- ["ncmpcpp", "mutt", "ipython"]
    ],
    [ ("v" , spawnHere "r.tf -e $EDITOR") -- THINK: also open in [tmux]?
    -- , ("S-<Space>", spawnHere "r.tf")
    , ("<Space>"  , spawnAndDo doCenterFloat "r.t")
    , ("<Return>" , spawnAndDo doCenterFloat "r.tf r.ranger")
    , ("C-<Space>"  , spawnAndDo doCenterFloat "r.t -M")
    , ("C-<Return>" , spawnAndDo doCenterFloat "r.t -M r.ranger")
    -- , ("k", "~/.i3/ctl/run-focus k")
    -- r.tf -e gksudo powertop
    -- r.tf -e gksudo tlp start
    -- nemo --no-desktop
    -- /usr/lib/cinnamon-settings/cinnamon-settings.py sound
    ]
  ]

media = (map (second spawn) . concat) [  -- TODO:USE: spawnHere
    -- [e]xecute cmd/name
    [ ("M-e"       , "r.dmenu -c")
    , ("M-S-e"     , "r.dmenu -n")
    , ("M-C-e"     , "j4-dmenu-desktop")
    , ("M-<Print>" , "r.capture-screen")
    , ("M-t t"     , "r.touchpad-tgl")
    ],
    -- ADD: prompt to set volume
    feedCmd "r.audio"
    [ ("M-<Home>"     , "")
    , ("M-<Page_Up>"  , "2%+")
    , ("M-<Page_Down>", "2%-")
    , ("M-<End>"      , "20% unmute")
    , ("<XF86AudioRaiseVolume>", "2%+")
    , ("<XF86AudioLowerVolume>", "2%-")
    , ("<XF86AudioMute>"       , "")
    ],
    feedCmd "mpc"
    [ ("M-o ."           , "next")
    , ("M-o ,"           , "prev")
    , ("M-o <Delete>"    , "del 0")
    , ("M-S-<Home>"      , "toggle")
    , ("M-S-<Page_Up>"   , "prev")
    , ("M-S-<Page_Down>" , "next")
    , ("M-S-<End>"       , "seek +5 >/dev/null")
    , ("<XF86AudioPlay>" , "toggle")
    , ("<XF86AudioNext>" , "next")
    , ("<XF86AudioPrev>" , "prev")
    , ("<XF86AudioStop>" , "stop")
    , ("<XF86AudioPause>", "pause")
    ],
    -- NEED: spawnHere
    -- misc
    [ ("<XF86Tools>"     , "r.tf -e ncmpcpp")
    , ("<XF86Mail>"      , "r.tf -e mutt")
    , ("<XF86Search>"    , "r.b -p")
    , ("<XF86Calculator>", "r.tf -e ipython")
    , ("<XF86Sleep>"     , "xset -d :0 dpms force off")
    ],
    ---- Submenus
    inGroup "M-i"
    [ ("u", "r.b -h")
    , ("g", "r.playonlinux -p")
    , ("e", "r.dict --en --dmenu")
    , ("r", "r.dict --ru --dmenu")
    , ("m", "r.t -e r.mutt-acc")
    ],
    inGroup "M-y"
    [ ("u", "r.b -p")
    , ("w", "r.notify-winclass")
    , ("l", "echo wmctrl -l | r.notify-sh")
    ],
    --DEV:(copyq) keySeqFor cmd prf = map (prf ++ " " ++)
    feedCmd "copyq"
    [ ("M-x", "toggle")
    , ("M-C-x", "edit -1")
    , ("M-c", "previous")
    , ("M-v", "next")
    ],
    (inGroup "M-S-x" . concat)
    [ feedCmd "copyq"
      [ ("a", "edit")  -- add new entry
      , ("e", "edit -1")  -- edit latest entry
      , ("t", "eval 'copy(clipboard());paste()'") -- as plain text
      -- NOTE: paste() simply sends Shift-Insert -- therefore may be buggy in 'st'
      , ("M-x", "toggle")
      , ("x",   "toggle")
      , ("m", "menu")
      , ("n", "next")
      , ("p", "previous")
      , ("<Return>", "enable")
      , ("<Backspace>", "disable")
      ]
    , feedCmd "r.copyq"
      [ (m ++ i, k ++ i) | i <- map show [0..9], (m, k) <-
        [("", ""), ("S-", "+"), ("C-", "-")]
      ]
    ],
    ---- Wacom
    inGroup "M-<Insert>"
    [ ("o", "r.wacom change-output")
    , ("m", "r.wacom change-mode -q")  -- && $upd wnd
    , ("s", "r.wacom change-curve")
    , ("c", "r.wacom show-curves")
    ]
  ]
