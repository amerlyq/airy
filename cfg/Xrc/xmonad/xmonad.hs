-- vim: ts=2:sw=2:sts=2
module Main (main) where

---- Std
import Control.Monad (when)
import Data.List     (isPrefixOf)
import Data.Ratio    ((%))
import Data.Default  (def)
import System.IO
import System.Process (readProcess)

---- Core
import XMonad                       -- (float, kill, spawn, refresh, restart, doFloat, workspaces, windows, withFocused, sendMessage, Resize(Shrink, Expand), IncMasterN)
import XMonad.Util.Run              (spawnPipe)
import XMonad.Util.EZConfig         (mkKeymap, checkKeymap)
import XMonad.ManageHook            (className)

---- Actions
import XMonad.Actions.SpawnOn       (manageSpawn)

---- Hooks
import XMonad.Hooks.SetWMName       (setWMName)
import XMonad.Hooks.EwmhDesktops    (ewmh, ewmhDesktopsStartup)
import XMonad.Hooks.ManageDocks     (manageDocks, avoidStruts)
import XMonad.Hooks.ManageHelpers   (composeOne, (-?>), transience, isFullscreen, doFullFloat, doCenterFloat, isDialog)
import XMonad.Hooks.InsertPosition  (insertPosition, Position(Master, Above, Below), Focus(Newer, Older))
import XMonad.Hooks.UrgencyHook     (withUrgencyHook, NoUrgencyHook(..))

---- Layouts
import qualified XMonad.StackSet as W
-- basis
import XMonad.Layout.Tabbed         (simpleTabbed)
import XMonad.Layout.Grid           (Grid(..))
import XMonad.Layout.Circle         (Circle(..))
import XMonad.Layout.SimplestFloat  (simplestFloat)
import XMonad.Layout.IM             (withIM, Property(ClassName, Title, And))
-- DEV:
import qualified XMonad.Layout.Monitor as MON
import XMonad.Layout.LayoutModifier (ModifiedLayout(..))  -- For Layout.Monitor
-- import XMonad.Layout.IndependentScreens (withScreens)
-- modifiers
import XMonad.Layout.Reflect        (REFLECTX(REFLECTX))
import XMonad.Layout.ResizableTile  (ResizableTall(ResizableTall), MirrorResize(MirrorShrink, MirrorExpand))
import XMonad.Layout.PerWorkspace   (onWorkspace)
import XMonad.Layout.MultiToggle    (mkToggle, Toggle(..), single, (??), EOT(..))
import XMonad.Layout.MultiToggle.Instances(StdTransformers(FULL, MIRROR))
-- decorators
import XMonad.Layout.LayoutHints    (layoutHintsToCenter, hintsEventHook)  -- honor size hints
import XMonad.Layout.NoBorders      (smartBorders)  -- no borders on fullscreen
-- extension
import XMonad.Util.NamedScratchpad  (namedScratchpadManageHook)


import XMonad.Config.Amer.Common     (bring)
import XMonad.Config.Amer.Layout     (MyTransformers(STRUTS, GAPS))
import XMonad.Config.Amer.EventHook  (myHandleEventHook)
import XMonad.Config.Amer.LogHook    (myLogHook)
import XMonad.Config.Amer.Scratchpad (myScratchpads)
import XMonad.Config.Amer.Keys       (myKeys, myOverlay)
import qualified XMonad.Config.Amer.Workspace as MyWksp


myStartupHook = do
  ewmhDesktopsStartup  -- EXPL: to be able to use 'wmctrl'
  setWMName "LG3D"  -- Fixes problems with Java GUI programs
  -- FIXME: dirty fix to not jump to 1st wksp on each restart beside startup
  checkKeymap myCfg myKeys
  curr <- gets (W.currentTag . windowset)
  when (curr == head MyWksp.all) $
    windows . W.view $ MyWksp.primary !! 1


myCfg = withUrgencyHook NoUrgencyHook $ def
  { modMask = mod4Mask
  -- Options
  , terminal    = "r.t"
  , workspaces  = MyWksp.all
  -- , workspaces  = withScreens 2 MyWksp.all
  , keys        = (`mkKeymap` myKeys)
  -- Hooks
  -- , startupHook = broadcastMessage $ SetStruts [] [minBound..maxBound]
  -- , startupHook = windows . W.view . (!!1) . workspaces $ myCfg
  , startupHook = myStartupHook
  , manageHook  = myManageHook <+> manageHook def
  -- layoutHook def
  -- layoutHintsToCenter
  , layoutHook = myLayout
  , handleEventHook = myHandleEventHook
  -- Style
  , borderWidth        = 2
  , normalBorderColor  = "#000000"
  , focusedBorderColor = "#c050f0"
  }


myLayout = smartBorders
    . ModifiedLayout myOverlay
    -- . onWorkspace (workspaces myCfg !! 4) Full
    . mkToggle (single STRUTS)
    . mkToggle (single FULL)
    . avoidStruts
    . mkToggle (single GAPS)
    . mkToggle (single MIRROR)
    . mkToggle (single REFLECTX)
    . onWorkspace "IM" imLayer
    $ tiled ||| simpleTabbed ||| simplestFloat ||| Grid ||| Circle
  where
    imLayer = withIM (1%7) (ClassName "Pidgin" `And` Title "Buddy List") Grid
    tiled   = ResizableTall nmaster delta ratio []
    nmaster = 1     -- number of windows in master pane
    ratio   = toRational (1.9 / (1 + sqrt 5.0)) -- phi
    delta   = 2/100 -- step of increasing


-- RFC: mconcat . concat $ [ [
myManageHook :: ManageHook
myManageHook = manageSpawn <+>
  mconcat
  [ isFullscreen --> topmost doFullFloat
  , isDialog --> topmost doCenterFloat
  -- , stringProperty "WM_WINDOW_ROLE" =? "buddy_list" -->
  --   (ask >>= \w -> doF $ W.sink w) >> doShift "IM"
  ] <+>
  composeFloat
  [ ("Float" `isPrefixOf`) <$> appName
  --EXPL: pidgin is tiled by XMonad.Layout.IM
  -- , let lst = "buddy_list Preferences"
  --   in wmhas (stringProperty "WM_WINDOW_ROLE") lst
  , let lst = "copyq feh Steam Gimp piony.py Transmission-gtk Xmessage"
    in wmhas className lst
  , let lst = "PlayOnLinux Dialog"
    in wmhas appName lst
  , className =? "Firefox" <&&> appName =? "Download"
  ] <+>
  -- for_window [title="^ElonaPlus"] fullscreen
  mconcat
  [ wmhas className "stalonetray Dunst" --> doIgnore
  , wmhas appName "panel desktop_window kdesktop trayer" --> doIgnore
  -- TODO:FIND: exclude pop-up windows for Dunst/copyq from stealing focus
  -- MAYBE: there bug in copyq WM_WINDOW_TYPE
  -- CHECK:FIND: how to keep kbdd current layout on stealing
  -- THINK:USE: another notifier:
  -- -- http://nochair.net/posts/2010/10-25-freedesktop-notifications-xmobar.html
  -- -- https://wiki.archlinux.org/index.php/Desktop_notifications
  , foldr1 (<||>) [ stringProperty "WM_WINDOW_TYPE" =? x | x <-
    [ "_NET_WM_WINDOW_TYPE_TOOLTIP"
    , "_NET_WM_WINDOW_TYPE_NOTIFICATION"
    ] ] --> doIgnore
  ]
  <+> insertPosition Below Newer <+>
  composeBring
  [ ("IM", "Pidgin")
  , ("IM", "Skype")
  , ("FF", "Firefox")
  -- , ("MM", "mutt") -- TODO: make whole wksp similar to firefox (but I can have >1 mutt)
  -- NOTE: strictly speaking, we don't need runOrRaise for mutt
  -- -- only stick it to MM wksp and keys to jump on it
  -- -- but with raise we get auto-launch and jumping even to moved for some reasons windows
  , ("5", "Krita")
  , ("8", "t-engine64")
  , ("9", "Steam")
  ]
  <+> MON.manageMonitor myOverlay
  <+> namedScratchpadManageHook myScratchpads
  <+> manageDocks
  where
    wmhas t l = foldr1 (<||>) [ t =? x | x <- words l ]
    topmost =  (<+> insertPosition Master Newer)
    composeFloat = mconcat . map (--> topmost doFloat)
    -- ALT: doF (W.shift "doc")
    composeBring = mconcat . map (\(i, x) -> (className =? x --> doF (bring i)))


main :: IO ()
main = do
  -- BUG: crash X
  -- dpi <- readProcess "r.Xrc" ["-d"] ""
  h <- spawnPipe "xmobar ~/.xmonad/xmobarrc"
  xmonad $ ewmh myCfg { logHook = myLogHook h
  , borderWidth = fromIntegral $ round (read "102" / 50)
  }
