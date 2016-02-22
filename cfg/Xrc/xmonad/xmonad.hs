-- vim: ts=2:sw=2:sts=2
module Main (main) where

import XMonad
import XMonad.Config.Desktop

import XMonad.Hooks.DynamicLog      (statusBar, xmobarPP, xmobarColor, PP(..))
import XMonad.Hooks.EwmhDesktops    (ewmh, fullscreenEventHook)
import XMonad.Hooks.ManageDocks     (manageDocks, avoidStruts, docksEventHook, SetStruts(..), ToggleStruts(..))
import XMonad.Hooks.ManageHelpers   (isFullscreen, doFullFloat, isDialog)
import XMonad.Layout.LayoutHints    (layoutHintsToCenter, hintsEventHook)  -- honor size hints
import XMonad.Layout.NoBorders      (smartBorders)  -- no borders on fullscreen
import XMonad.Layout.ResizableTile  (ResizableTall(..), MirrorResize(..))
import XMonad.Layout.SimplestFloat  (simplestFloat)
import XMonad.Layout.MultiToggle    (mkToggle, Toggle(..), single, (??), EOT(..))
import qualified XMonad.Layout.MultiToggle.Instances as MI

import XMonad.Util.EZConfig         (additionalKeys, mkKeymap)

import qualified XMonad.StackSet as W
import qualified XMonad.Actions.CycleWS as CC
import XMonad.Util.WorkspaceCompare (getSortByIndex)

import Data.List    (isPrefixOf)

import System.IO
import System.Exit


myKeys cfg = mkKeymap cfg $
  [ ("M-u"        , spawn $ terminal cfg)
  , ("M-C-u"      , spawn "~/.i3/ctl/run-cwd")
-- bindsym $mSd+u split vertical  , $exno r.t
-- bindsym $mCS+u split horizontal, $exno r.t
  , ("M-<Return>" , spawn "r.t -e zsh -ic r.ranger")
  , ("M-C-<Return>", spawn "r.tf")
  , ("M-S-<Return>", spawn "r.tf -e r.ranger")
  , ("M-A-<Return>", spawn "r.tf -e r.python")
  , ("M-d"        , spawn "r.dmenu")
  , ("M-S-d"      , spawn "r.dmenu -n")
  , ("M-C-d"      , spawn "j4-dmenu-desktop")
  , ("M-\\"       , kill)
  , ("M-S-q"      , kill)
  , ("M-C-S-\\"   , spawn "~/.i3/ctl/wnd_active_kill")
  ---- focus
  , ("M-h"        , windows W.focusMaster)
  , ("M-j"        , windows W.focusDown)
  , ("M-k"        , windows W.focusUp)
  ---- swap
  , ("M-S-h"      , windows W.swapMaster)
  , ("M-S-l"      , windows W.shiftMaster)
  , ("M-S-j"      , windows W.swapDown)
  , ("M-S-k"      , windows W.swapUp)
  ---- edit
  , ("M-,"        , sendMessage Shrink)
  , ("M-."        , sendMessage Expand)
  , ("M-S-,"      , sendMessage MirrorShrink)
  , ("M-S-."      , sendMessage MirrorExpand)
  -- Layouts
  , ("M-<Space>"  , sendMessage NextLayout)
  , ("M-f"        , sendMessage $ Toggle MI.FULL)
  , ("M-/"        , sendMessage $ Toggle MI.MIRROR)
  -- , ("M-w"        , withFocused $ windows . W.sink)
  , ("M-C-w"      , withFocused $ windows . W.sink)
  -- , ("M-S-w"      , withFocused $ windows . W.float)
  , ("M-S-<Space>", setLayout   $ XMonad.layoutHook cfg)
  ] ++
  -- Cycle through workspaces
  let moveToNE  = CC.moveTo  CC.Next CC.NonEmptyWS
      shiftToNE = CC.shiftTo CC.Next CC.NonEmptyWS
      moveToE   = CC.moveTo  CC.Next CC.EmptyWS
      shiftToE  = CC.shiftTo CC.Next CC.EmptyWS
  in [ ("M-a"        , CC.toggleWS)
     -- , ("M-S-a"      , CC.shiftToPrev >> CC.toggleWS)
     , ("M-S-a"      , windows (W.shift "0") >> windows (W.view "0"))
     , ("M-<Tab>"    , moveToNE)
     , ("M-S-<Tab>"  , shiftToNE >> moveToNE)
     , ("M-C-<Tab>"  , moveToE)
     , ("M-C-S-<Tab>", shiftToE >> moveToE)
     ] ++
  -- workspaces
  let lws = [ ("M-"  , windows . W.view)
            , ("M-C-", windows . W.shift)
            , ("M-S-", \w -> windows (W.shift w) >> windows (W.view w))
            ]
  in [ (m ++ i, f i) | i <- workspaces cfg, (m, f) <- lws] ++
  -- shortcuts
  -- media
  [ ("M-<Print>" , spawn "~/.i3/ext/screenshot")
  , ("M-y"       , spawn "r.dict --vim")
  ---- volume
  , ("M-<Home>"     , spawn "~/.i3/ext/volume 20%")
  , ("M-<Page_Up>"  , spawn "~/.i3/ext/volume 2%+")
  , ("M-<Page_Down>", spawn "~/.i3/ext/volume 2%-")
  , ("M-<End>"      , spawn "~/.i3/ext/volume")
  , ("<XF86AudioRaiseVolume>", spawn "~/.i3/ext/volume 2%+")
  , ("<XF86AudioLowerVolume>", spawn "~/.i3/ext/volume 2%-")
  , ("<XF86AudioMute>"       , spawn "~/.i3/ext/volume")
  ---- mpd
  , ("M-S-<Home>"      , spawn "mpc toggle")
  , ("M-S-<Page_Up>"   , spawn "mpc prev")
  , ("M-S-<Page_Down>" , spawn "mpc next")
  , ("M-S-<End>"       , spawn "mpc seek +5 >/dev/null")
  , ("<XF86Tools>"     , spawn "r.tf ncmpcpp")
  , ("<XF86AudioPlay>" , spawn "mpc toggle")
  , ("<XF86AudioNext>" , spawn "mpc next")
  , ("<XF86AudioPrev>" , spawn "mpc prev")
  , ("<XF86AudioStop>" , spawn "mpc stop")
  , ("<XF86AudioPause>", spawn "mpc pause")
  ---- misc
  , ("<XF86Mail>"      , spawn "r.tf -e mutt")
  , ("<XF86Search>"    , spawn "r.vimb -p")
  , ("<XF86Calculator>", spawn "r.tf -e ipython")
  , ("<XF86Sleep>"     , spawn "xset -d :0 dpms force off")
  ] ++
  -- Submenus
  ---- xmonad
  let mWM = ("M-S-<Esc> " ++)
  in [ (mWM "o" , io exitSuccess)
     , (mWM "r" , spawn "sudo reboot")
     , (mWM "t" , spawn "sudo poweroff")
     , ("M-S-z"          , spawn "~/.i3/ext/i3exit lock")
     , ("M-S-<Backspace>", restart "xmonad" True)
     ] ++
     [ (mWM i, spawn $ "xbacklight -set " ++ i ++ "0") | i <- map show [0..9]
  ] ++
  let mPrs = ("M-o " ++)
  in [ (mPrs "b", spawn "vimb")
     , (mPrs "f", spawn "firefox")
     , (mPrs "h", spawn "r.tf -e htop")
     , (mPrs "n", spawn "r.tf -e ncmpcpp")
     , (mPrs "p", spawn "pidgin")
     , (mPrs "k", spawn "~/.i3/ctl/run-focus k")
     -- r.tf -e gksudo powertop
     -- r.tf -e gksudo tlp start
     -- nemo --no-desktop
     -- /usr/lib/cinnamon-settings/cinnamon-settings.py sound
  ] ++
  let mPrompt = ("M-p " ++)
  in [ (mPrompt "b", spawn "r.vimb -h")
     , (mPrompt "g", spawn "r.vimb -g")
     , (mPrompt "d", spawn "r.dict --vim")
     , (mPrompt "m", spawn "~/.mpd/move_current")
  ] ++
  let mCopyq = ("M-z " ++)
  in [ (mCopyq "e", spawn "copyq edit")
     , (mCopyq "o", spawn "copyq toggle")
     , (mCopyq "m", spawn "copyq menu")
     , (mCopyq "a", spawn "copyq enable")
     , (mCopyq "d", spawn "copyq disable")
     ] ++ [ (mCopyq i, spawn $ "copyq select " ++ i) | i <- map show [0..9]
  ]
  ---- wacom M-<Insert>
  -- o ~/aura/airy/cfg/wacom/ctl/change-output ,$def
  -- $mod+m ~/aura/airy/cfg/wacom/ctl/change-mode -q && $upd wnd ,$def
  -- $mod+s ~/aura/airy/cfg/wacom/ctl/change-curve  ,$def
  where
    hidTags w = map W.tag $ W.hidden w ++ [W.workspace . W.current $ w]
    visTags w = map (W.tag . W.workspace) $ W.visible w ++ [W.current w]

myCfg = ewmh $ defaultConfig
  { modMask = mod4Mask
  -- Options
  , terminal    = "r.t"
  , workspaces  = words "` 1 2 3 4 5 6 7 8 9 0 - ="
  , keys        = myKeys
  -- Hooks
  -- , startupHook = broadcastMessage $ SetStruts [] [minBound..maxBound]
  , startupHook = windows . W.view . (!!1) . workspaces $ myCfg
  , manageHook = manageHook defaultConfig <+> myManageHook <+> manageDocks
  -- layoutHook defaultConfig
  -- layoutHintsToCenter
  , layoutHook = smartBorders . avoidStruts $ myLayout
  , handleEventHook = myHandleEventHook
  -- Style
  , borderWidth        = 2
  , normalBorderColor  = "#000000"
  , focusedBorderColor = "#c050f0"
  }


myLayout = smartBorders
     . mkToggle (MI.NOBORDERS ?? MI.FULL ?? EOT)
     . mkToggle (single MI.MIRROR)
     $ tiled ||| simplestFloat -- ||| Grid ||| Circle
  where
    tiled   = ResizableTall nmaster delta ratio []
    nmaster = 1     -- number of windows in master pane
    ratio   = toRational (2 / (1 + sqrt 5.0)) -- phi
    delta   = 3/100 -- step of increasing


myManageHook :: ManageHook
myManageHook = mconcat $
  [ myIgnores    --> doIgnore     -- Don't manage
  , myFloats     --> doFloat      -- Make floating
  , isFullscreen --> doFullFloat  -- Auto-fullscreen
  -- for_window [title="^ElonaPlus"] fullscreen
  ] ++
  [ x --> doShift w | (x, w) <- myShifts ]  -- ALT: doF (W.shift "doc")
  where
    wmhas t l = [ t =? x | x <- words l ]
    myIgnores = foldr1 (<||>) $
      wmhas className "stalonetray" ++
      wmhas appName "panel desktop_window kdesktop"
    myFloats = foldr1 (<||>) $
      [ ("Figure" `isPrefixOf`) <$> title, isDialog ] ++
      wmhas className "Float copyq feh Steam Gimp Pidgin Skype piony.py Transmission-gtk"
    myShifts = map (\(x, y) -> (className =? x, y)) $
      [ ("Firefox", "4")
      , ("Krita", "5")
      , ("t-engine64", "8")
      , ("Steam", "9")
      ]

myHandleEventHook = mconcat $
  [ handleEventHook defaultConfig
  , docksEventHook
  , hintsEventHook
  , fullscreenEventHook
  ]


myPP :: PP  -- xmobar pretty printing source
myPP = xmobarPP
  { ppCurrent = xmobarColor "#fd971f" ""
  , ppSep     = xmobarColor "#fd971f" "" " \xe0b1 "           -- separator between elements
  , ppOrder   = \(ws:l:_) -> [l, ws]                          -- elems order (title ignored)
  , ppHidden  = \w -> if elem w (workspaces myCfg) then w else ""  -- only predefined by me
  , ppLayout  = \n -> case n of                               -- short 'titles' for layouts
      "Full" -> "[ ]"
      "ResizableTall" -> "[|]"
      "Mirror ResizableTall" -> "[-]"
      _ -> n
  }


main :: IO ()
main = xmonad =<< statusBar "xmobar" myPP toggleStrutsKey myCfg
  where
    toggleStrutsKey XConfig { XMonad.modMask = modMask } = (modMask, xK_b)  -- xK_Escape
