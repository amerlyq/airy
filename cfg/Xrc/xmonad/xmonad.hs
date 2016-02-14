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
-- import XMonad.Hooks.SetWMName

import XMonad.Util.EZConfig         (additionalKeys, mkKeymap)
import Graphics.X11.ExtraTypes.XorgDefault  -- xK_ISO_Left_Tab

import qualified XMonad.StackSet as W
import XMonad.Actions.CycleRecentWS (cycleWindowSets)

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
  -- cycle through all windows
  ---- focus
  , ("M-h"        , windows W.focusMaster)
  , ("M-j"        , windows W.focusDown)
  , ("M-k"        , windows W.focusUp)
  ---- swap
  , ("M-S-h"      , windows W.swapMaster)
  , ("M-S-j"      , windows W.swapDown)
  , ("M-S-k"      , windows W.swapUp)
  ---- edit
  , ("M-,"        , sendMessage Shrink)
  , ("M-."        , sendMessage Expand)
  , ("M-S-,"      , sendMessage MirrorShrink)
  , ("M-S-."      , sendMessage MirrorExpand)
  -- Layouts
  , ("M-<Space>"  , sendMessage NextLayout)
  -- , ("M-f"        , setLayout   $ avoidStruts Full)
  , ("M-w"        , withFocused $ windows . W.sink)  -- BUG
  , ("M-S-<Space>", setLayout   $ XMonad.layoutHook cfg)
  ] ++
  -- cycling
  let visWs w = map (W.greedyView `flip` w) (visTags w)
      hidWs w = map (W.greedyView `flip` w) (hidTags w)
      rctWs w = map (W.view `flip` w)       (map ($ hidTags w) [head, last])
  in [ ("M-<Tab>"  , cycleWindowSets visWs [xK_Super_L] xK_Tab xK_ISO_Left_Tab)
     , ("M-S-<Tab>", cycleWindowSets hidWs [xK_Super_L] xK_ISO_Left_Tab xK_Tab)
     , ("M-a"      , cycleWindowSets rctWs [xK_Super_L] xK_a xK_a)
  ] ++
  -- workspaces
  [ (m ++ i, windows $ f i) | i <- workspaces cfg
    , (m, f) <- [("M-", W.view), ("M-S-", W.shift)]
  ] ++
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
     , (mPrs "m", spawn "~/.mpd/move_current")
     , (mPrs "p", spawn "pidgin")
     , (mPrs "k", spawn "~/.i3/ctl/run-focus k")
     -- r.tf -e gksudo powertop
     -- r.tf -e gksudo tlp start
     -- nemo --no-desktop
     -- /usr/lib/cinnamon-settings/cinnamon-settings.py sound
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
  -- , startupHook = setWMName "LG3D"
  -- , startupHook = broadcastMessage $ SetStruts [] [minBound..maxBound]
  , manageHook = manageHook defaultConfig <+> manageDocks
  -- layoutHook defaultConfig
  -- layoutHintsToCenter
  , layoutHook = smartBorders . avoidStruts $ myLayout
  , handleEventHook = mconcat [ handleEventHook defaultConfig, docksEventHook,
                                hintsEventHook, fullscreenEventHook ]
  -- Style
  , borderWidth        = 2
  , normalBorderColor  = "#000000"
  , focusedBorderColor = "#c050f0"
  }

myLayout = tiled ||| Mirror tiled ||| Full
  where
    tiled   = ResizableTall nmaster delta ratio []
    nmaster = 1     -- number of windows in master pane
    ratio   = toRational (2 / (1 + sqrt 5.0)) -- phi
    delta   = 3/100 -- step of increasing

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
    toggleStrutsKey XConfig { XMonad.modMask = modMask } = (modMask, xK_Escape)
