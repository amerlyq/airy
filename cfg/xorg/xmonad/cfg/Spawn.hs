-- vim: ts=2:sw=2:sts=2
module XMonad.Config.Amer.Spawn (
    keys
) where

import Control.Arrow (second)
import XMonad                       (spawn, windows, doFloat, (=?))
import XMonad.StackSet              (view, shift)
import XMonad.Actions.SpawnOn       (spawnHere, spawnAndDo)
import XMonad.Actions.WindowGo      (runOrRaise, raiseMaybe)
import XMonad.ManageHook            (className, appName, title, stringProperty, (<&&>))
import XMonad.Hooks.ManageHelpers   (doCenterFloat, (/=?))
import XMonad.Hooks.InsertPosition  (insertPosition, Position(Master, Above, Below), Focus(Newer, Older))
import XMonad.Util.NamedScratchpad  (namedScratchpadAction)

import XMonad.Config.Amer.Common     (inGroup, feedCmd)
import XMonad.Config.Amer.Scratchpad (myScratchpads)
import XMonad.Config.Amer.Navigation (nextEmpty)

keys = main ++ scratchpad ++ media

-- TODO: insert into M-o / M-S-o menus to be able open on new wksp
main = concat [
    [ ("M-"     ++ k , spawnHere t)
    , ("M-S-"   ++ k , spawnAndDo (insertPosition Master Newer) t)
    , ("M-C-"   ++ k , spawnAndDo doFloat t)  -- WARNING: if broken >> HW problem
    , ("M-S-C-" ++ k , spawnAndDo doCenterFloat t)
    ]
    | (k, t) <-
    [ ("<Space>", "r.t -e r.tmux")  -- OR "r.tf"
    , ("M1-<Space>", "~/.i3/ctl/run-cwd") -- FIXME
    , ("<Return>", "r.t -e r.ranger")  -- OR -e zsh -ic
    ]
  ]

---- Scratchpads
-- TODO:ADD: M-s <Space> (export sPrf -- secondary prefix) -- jump to nearest next/prev(S-<Space>) empty wksp instead of <Bksp>
scratchpad = (concat . (`map` [
      inGroup "M-o",
      inGroup "M-S-o" . map (second (\f -> nextEmpty view >> f))
  ]) . flip ($) . concat) [
    [ ("M-o", windows $ view "NSP")
    , ("M-S-o", windows $ shift "NSP")
    , ("f" , runOrRaise "firefox" $ className =? "Firefox")
    , ("p" , runOrRaise "pidgin" $ className =? "Pidgin" <&&> stringProperty "WM_WINDOW_ROLE" =? "buddy_list")
    , ("s" , runOrRaise "skype" $ className =? "Skype" <&&> title /=? "Options" <&&> stringProperty "WM_WINDOW_ROLE" /=? "Chats" <&&> stringProperty "WM_WINDOW_ROLE" /=? "CallWindowForm")
    -- FIXME: broken opening on new wksp?
    , ("m" , raiseMaybe (spawn "r.t -n mutt -e mutt") (appName =? "mutt"))
    , ("<F1>", namedScratchpadAction myScratchpads "help")
    ],
    -- Open new or focus the already existing one
    [ ([head nm], namedScratchpadAction myScratchpads nm)
    | nm <- ["ncmpcpp", "ipython", "j8", "htop", "lyrics"]
    ],
    -- Open new window always
    [ ("S-" ++ [head nm], spawnHere $ "r.tf -e " ++ nm)
    | nm <- ["ncmpcpp", "mutt", "ipython"]
    ],
    [ ("b" , spawnHere "r.b")
    , ("v" , spawnHere "r.tf -e $EDITOR")
    , ("S-<Space>", spawnHere "r.t")
    , ("<Space>"  , spawnHere "r.tf")
    , ("<Return>" , spawnHere "r.tf -e ranger")
    -- , ("k", "~/.i3/ctl/run-focus k")
    -- r.tf -e gksudo powertop
    -- r.tf -e gksudo tlp start
    -- nemo --no-desktop
    -- /usr/lib/cinnamon-settings/cinnamon-settings.py sound
    ]
  ]

media = (map (second spawn) . concat) [  -- TODO:USE: spawnHere
    [ ("M-d"       , "r.dmenu -c")
    , ("M-S-d"     , "r.dmenu -n")
    , ("M-C-d"     , "j4-dmenu-desktop")
    , ("M-<Print>" , "r.capture-screen")
    , ("M-o t"     , "r.touchpad-tgl")
    ],
    -- ADD: prompt to set volume
    feedCmd "r.audio"
    [ ("M-<Home>"     , "20% unmute")
    , ("M-<Page_Up>"  , "2%+")
    , ("M-<Page_Down>", "2%-")
    , ("M-<End>"      , "")
    , ("<XF86AudioRaiseVolume>", "2%+")
    , ("<XF86AudioLowerVolume>", "2%-")
    , ("<XF86AudioMute>"       , "")
    ],
    feedCmd "mpc"
    [ ("M-o ."           , "next")
    , ("M-o ,"           , "prev")
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
    [ ("<XF86Tools>"     , "r.tf ncmpcpp")
    , ("<XF86Mail>"      , "r.tf -e mutt")
    , ("<XF86Search>"    , "r.b -p")
    , ("<XF86Calculator>", "r.tf -e ipython")
    , ("<XF86Sleep>"     , "xset -d :0 dpms force off")
    ],
    ---- Submenus
    inGroup "M-S-<Esc>" $ feedCmd "xbacklight -set" $ mconcat
    [ [ (i, i ++ "0")   | i <- map show [1..9] ]
    , [ (" 0 " ++ i, i) | i <- map show [1..9] ]
    ],
    inGroup "M-u"
    [ ("b", "r.b -h")
    , ("g", "r.game -p")
    , ("e", "r.dict --en --vim")
    , ("r", "r.dict --ru --vim")
    , ("m", "r.mpd-move")
    ],
    inGroup "M-y"
    [ ("b", "r.b -p")
    , ("w", "r.notify-winclass")
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
    ]
    ---- wacom M-<Insert>
    -- o ~/aura/airy/cfg/wacom/ctl/change-output ,$def
    -- $mod+m ~/aura/airy/cfg/wacom/ctl/change-mode -q && $upd wnd ,$def
    -- $mod+s ~/aura/airy/cfg/wacom/ctl/change-curve  ,$def
  ]
