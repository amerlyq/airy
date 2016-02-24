-- vim: ts=2:sw=2:sts=2
module Main (main) where

---- Std
import Data.List    (isPrefixOf)
import System.IO
import System.Exit

---- Core
import XMonad
import XMonad.Config.Desktop
import XMonad.Util.EZConfig         (mkKeymap)

---- Actions
import XMonad.Actions.CycleWS       (moveTo, shiftTo, toggleWS, Direction1D(Prev, Next), WSType(NonEmptyWS, EmptyWS))
import qualified XMonad.Actions.GroupNavigation as GN

---- Hooks
import XMonad.Hooks.DynamicLog      (statusBar, xmobarPP, xmobarColor, PP(..))
import XMonad.Hooks.EwmhDesktops    (ewmh, fullscreenEventHook)
import XMonad.Hooks.ManageDocks     (manageDocks, avoidStruts, docksEventHook, SetStruts(..), ToggleStruts(..))
import XMonad.Hooks.ManageHelpers   (isFullscreen, doFullFloat, isDialog)
import XMonad.Hooks.InsertPosition  (insertPosition, Position(Below), Focus(Newer))

---- Layouts
import qualified XMonad.StackSet as W
-- basis
import XMonad.Layout.Tabbed         (simpleTabbed)
import XMonad.Layout.Grid           (Grid(..))
import XMonad.Layout.Circle         (Circle(..))
import XMonad.Layout.SimplestFloat  (simplestFloat)
-- modifiers
import XMonad.Layout.ResizableTile  (ResizableTall(ResizableTall), MirrorResize(MirrorShrink, MirrorExpand))
import XMonad.Layout.PerWorkspace   (onWorkspace)
import XMonad.Layout.MultiToggle    (mkToggle, Toggle(..), single, (??), EOT(..))
import XMonad.Layout.MultiToggle.Instances(StdTransformers(FULL, MIRROR, NOBORDERS))
-- decorators
import XMonad.Layout.LayoutHints    (layoutHintsToCenter, hintsEventHook)  -- honor size hints
import XMonad.Layout.NoBorders      (smartBorders)  -- no borders on fullscreen


myKeys cfg = mkKeymap cfg $
  ---- focus
  [ ("M-h"        , windows W.focusMaster)
  , ("M-j"        , windows W.focusDown)
  , ("M-k"        , windows W.focusUp)
  , ("M-l"        , GN.nextMatch GN.History (return True))
  , ("M-'"        , GN.nextMatchWithThis GN.Backward className)
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
  , ("M-;"        , sendMessage . IncMasterN $  1)
  , ("M-S-;"      , sendMessage . IncMasterN $ -1)
  ---- float
  -- , ("M-w"        , withFocused $ windows . W.sink)
  , ("M-C-w"      , withFocused $ windows . W.sink)
  -- , ("M-S-w"      , withFocused $ windows . W.float)
  -- Layouts
  , ("M-n"        , sendMessage NextLayout)
  , ("M-S-n"      , sendMessage FirstLayout)  -- ALT: setLayout $ XMonad.layoutHook cfg
  , ("M-f"        , sendMessage $ Toggle FULL)
  , ("M-/"        , sendMessage $ Toggle MIRROR)
  ] ++
  -- Cycle through workspaces
  let focusNextNE = moveTo  Next NonEmptyWS
      focusPrevNE = moveTo  Prev NonEmptyWS
      shiftNextNE = shiftTo Next NonEmptyWS
      shiftPrevNE = shiftTo Prev NonEmptyWS
      -- moveToE   = moveTo  Next EmptyWS
      -- shiftToE  = shiftTo Next EmptyWS
  in [ ("M-a"        , toggleWS)
     --FIXME: , ("M-S-a"      , shiftToPrev >> toggleWS)
     , ("M-S-a"      , windows (W.shift "0") >> windows (W.view "0"))
     , ("M-<Tab>"    , focusNextNE)
     , ("M-S-<Tab>"  , focusPrevNE)
     , ("M-C-<Tab>"  , shiftNextNE >> focusNextNE)
     , ("M-C-S-<Tab>", shiftPrevNE >> focusPrevNE)
     -- , ("M-C-<Tab>"  , moveToE)
     -- , ("M-C-S-<Tab>", shiftToE >> moveToE)
     ]
  ++
  ---- Workspaces
  [ (m ++ i, f i) | i <- workspaces cfg, (m, f) <-
    [ ("M-"  , windows . W.view)
    , ("M-C-", windows . W.shift)
    , ("M-S-", \w -> windows (W.shift w) >> windows (W.view w))
    --THINK:ALT:, ("M-S-", windows . W.shift >> windows . W.view)
    ]
  ] ++
  ---- Shortcuts
  spawnAll
    [ ("M-u" , terminal cfg)
    --FIXME: , ("M-S-u"      , spawn "r.t" >> windows W.swapMaster)
    , ("M-C-u"        , "~/.i3/ctl/run-cwd")
    , ("M-<Return>"   , "r.t -e zsh -ic r.ranger")
    , ("M-C-<Return>" , "r.tf")
    , ("M-S-<Return>" , "r.tf -e r.ranger")
    , ("M-A-<Return>" , "r.tf -e r.python")
    , ("M-d"          , "r.dmenu")
    , ("M-S-d"        , "r.dmenu -n")
    , ("M-C-d"        , "j4-dmenu-desktop")
    , ("M-<Print>"    , "~/.i3/ext/screenshot")
    , ("M-y"          , "r.dict --vim")
    ] ++
  spawnAll (feedCmd "~/.i3/ext/volume"
    [ ("M-<Home>"     , "20%")
    , ("M-<Page_Up>"  , "2%+")
    , ("M-<Page_Down>", "2%-")
    , ("M-<End>"      , "")
    , ("<XF86AudioRaiseVolume>", "2%+")
    , ("<XF86AudioLowerVolume>", "2%-")
    , ("<XF86AudioMute>"       , "")
    ]) ++
  spawnAll (feedCmd "mpc"
    [ ("M-S-<Home>"      , "toggle")
    , ("M-S-<Page_Up>"   , "prev")
    , ("M-S-<Page_Down>" , "next")
    , ("M-S-<End>"       , "seek +5 >/dev/null")
    , ("<XF86AudioPlay>" , "toggle")
    , ("<XF86AudioNext>" , "next")
    , ("<XF86AudioPrev>" , "prev")
    , ("<XF86AudioStop>" , "stop")
    , ("<XF86AudioPause>", "pause")
    ]) ++
  spawnAll  -- misc
    [ ("<XF86Tools>"     , "r.tf ncmpcpp")
    , ("<XF86Mail>"      , "r.tf -e mutt")
    , ("<XF86Search>"    , "r.vimb -p")
    , ("<XF86Calculator>", "r.tf -e ipython")
    , ("<XF86Sleep>"     , "xset -d :0 dpms force off")
    ] ++
  ---- System
  [ ("M-\\"     , kill)
  , ("M-S-q"    , kill)
  , ("M-C-S-\\" , spawn "~/.i3/ctl/wnd_active_kill")
  , ("M-S-z"          , spawn "~/.i3/ext/i3exit lock")
  , ("M-S-<Backspace>", restart "xmonad" True)
  ] ++
  ---- Submenus
  --ATTENTION: "M-<Esc>" must be unused -- I use <Esc> to drop xkb latching
  inGroup "M-S-<Esc>"  -- xmonad
    [ ("o", io exitSuccess)
    , ("n", refresh)  -- workspace normalizing (resize)
    , ("r", spawn "sudo reboot")
    , ("t", spawn "sudo poweroff")
    ] ++
  spawnMenu "M-S-<Esc>" (feedCmd "xbacklight -set"
    [ (i, i ++ "0") | i <- map show [0..9]
    ]) ++
  spawnMenu "M-o"
    [ ("b", "r.vimb")
    , ("f", "firefox")
    , ("h", "r.tf -e htop")
    , ("n", "r.tf -e ncmpcpp")
    , ("p", "pidgin")
    , ("s", "skype")
    , ("k", "~/.i3/ctl/run-focus k")
    -- r.tf -e gksudo powertop
    -- r.tf -e gksudo tlp start
    -- nemo --no-desktop
    -- /usr/lib/cinnamon-settings/cinnamon-settings.py sound
    ] ++
  spawnMenu "M-p"
    [ ("b", "r.vimb -h")
    , ("g", "r.vimb -g")
    , ("d", "r.dict --vim")
    , ("m", "~/.mpd/move_current")
    ] ++
  spawnMenu "M-z" (feedCmd "copyq"
    [ ("e", "edit")
    , ("o", "toggle")
    , ("m", "menu")
    , ("a", "enable")
    , ("d", "disable")
    ]) ++
  spawnMenu "M-z" (feedCmd "r.copyq"
    [ (m ++ i, k ++ i) | i <- map show [0..9], (m, k) <-
      [("", ""), ("S-", "+"), ("C-", "-")]
    ])
  ---- wacom M-<Insert>
  -- o ~/aura/airy/cfg/wacom/ctl/change-output ,$def
  -- $mod+m ~/aura/airy/cfg/wacom/ctl/change-mode -q && $upd wnd ,$def
  -- $mod+s ~/aura/airy/cfg/wacom/ctl/change-curve  ,$def
  where
    inGroup prf = map $ \(k, f) -> (prf ++ " " ++ k, f)
    feedCmd cmd  = map $ \(k, o) -> (k, cmd ++ " " ++ o)
    spawnAll    = map $ \(k, s) -> (k, spawn $ s)
    spawnMenu prf = (inGroup prf) . spawnAll
    --DEV:(copyq) keySeqFor cmd prf = map (prf ++ " " ++)
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
  , manageHook  = insertPosition Below Newer <+> myManageHook <+> manageDocks <+> manageHook defaultConfig
  -- layoutHook defaultConfig
  -- layoutHintsToCenter
  , layoutHook = smartBorders . avoidStruts $ myLayout
  , logHook = GN.historyHook
  , handleEventHook = myHandleEventHook
  -- Style
  , borderWidth        = 2
  , normalBorderColor  = "#000000"
  , focusedBorderColor = "#c050f0"
  }


myLayout = smartBorders
    . onWorkspace (workspaces myCfg !! 4) Full
    . mkToggle (NOBORDERS ?? FULL ?? EOT)
    . mkToggle (single MIRROR)
    $ tiled ||| simpleTabbed ||| simplestFloat ||| Grid ||| Circle
  where
    tiled   = ResizableTall nmaster delta ratio []
    nmaster = 1     -- number of windows in master pane
    ratio   = toRational (1.9 / (1 + sqrt 5.0)) -- phi
    delta   = 2/100 -- step of increasing


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
  , ppLayout  = \nm -> case nm of                             -- short 'titles' for layouts
      "ResizableTall" -> "[|]"
      "Mirror ResizableTall" -> "[-]"
      "Tabbed Simplest" -> "=--"
      "Full" -> "[ ]"
      "Grid" -> "[#]"
      "SimplestFloat" -> "( )"
      "Circle" -> "(O)"
      _ -> nm
  }


main :: IO ()
main = xmonad =<< statusBar myCmdStatus myPP toggleStrutsKey myCfg
  where
    myCmdStatus = "xmobar ~/.xmonad/xmobarrc"
    toggleStrutsKey XConfig { XMonad.modMask = modMask } = (modMask, xK_b)  -- xK_Escape
