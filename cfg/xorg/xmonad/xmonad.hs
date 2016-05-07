-- vim: ts=2:sw=2:sts=2
module Main (main) where

---- Std
import Control.Monad (when)
import Data.List     (isPrefixOf)
import Data.Ratio    ((%))
import Data.Default  (def)
import System.IO
import System.Environment   (getEnv)
import System.Posix.Process (getProcessID)

---- Core
import XMonad                       -- (float, kill, spawn, refresh, restart, doFloat, workspaces, windows, withFocused, sendMessage, Resize(Shrink, Expand), IncMasterN)
import XMonad.Util.Run              (spawnPipe, runProcessWithInput)
import XMonad.Util.EZConfig         (mkKeymap, checkKeymap)
import XMonad.ManageHook            (className)

---- Actions
import XMonad.Actions.SpawnOn       (manageSpawn)

---- Hooks
import XMonad.Hooks.SetWMName       (setWMName)
import XMonad.Hooks.EwmhDesktops    (ewmh, ewmhDesktopsStartup)
import XMonad.Hooks.ManageDocks     (manageDocks, avoidStruts)
import XMonad.Hooks.ManageHelpers   (composeOne, (-?>), transience, isFullscreen, doFullFloat, doCenterFloat, doRectFloat, isDialog)
import XMonad.Hooks.InsertPosition  (insertPosition, Position(Master, Above, Below), Focus(Newer, Older))
import XMonad.Hooks.UrgencyHook     (withUrgencyHook, BorderUrgencyHook(..))

---- Layouts
import qualified XMonad.StackSet as W
-- basis
import XMonad.Layout.Tabbed         (simpleTabbed)
import XMonad.Layout.Grid           (Grid(..))
import XMonad.Layout.Circle         (Circle(..))
import XMonad.Layout.SimplestFloat  (simplestFloat)
import XMonad.Layout.IM             (gridIM, Property(ClassName, Title, Role, And, Not))
-- DEV:
import qualified XMonad.Layout.Monitor as MON
import XMonad.Layout.LayoutModifier (ModifiedLayout(..))  -- For Layout.Monitor
-- import XMonad.Layout.IndependentScreens (withScreens)
-- modifiers
import XMonad.Layout.Reflect        (reflectHoriz, REFLECTX(REFLECTX))
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
import XMonad.Config.Amer.Mouse      (myMouseBindings)
import qualified XMonad.Config.Amer.Workspace as MyWksp


-- myStartupHook = broadcastMessage $ SetStruts [] [minBound..maxBound]
-- myStartupHook = windows . W.view . (!!1) . workspaces $ myCfg
myStartupHook = do
  ewmhDesktopsStartup  -- EXPL: to be able to use 'wmctrl'
  setWMName "LG3D"  -- Fixes problems with Java GUI programs
  -- FIXME: skip on non-systemd MAYBE:BUG: one more notify on each --restart
  -- NEED: one-time env vars https://www.freedesktop.org/software/systemd/man/sd_notify.html
  -- MAYBE: NOTIFY_SOCKET is set automatically when Type=notify?
  -- getProcessID >>= \p -> spawn $ "systemd-notify --ready --pid=" ++ show $ liftIO . p
  pid <- liftIO getProcessID
  trace $ show pid
  -- import System.IO.Unsafe
  -- myHome = unsafePerformIO $ getEnv "HOME"
  soc <- io $ getEnv "NOTIFY_SOCKET"
  trace $ show soc
  spawn $ "systemd-notify --ready --pid=" ++ show pid
  -- FIXME: dirty fix to not jump to 1st wksp on each restart beside startup
  checkKeymap myCfg myKeys
  curr <- gets (W.currentTag . windowset)
  when (curr == head MyWksp.all) $
    windows . W.view $ MyWksp.primary !! 1


-- TRY:CHG:(make more clean) def -> XConfig
myCfg = withUrgencyHook BorderUrgencyHook { urgencyBorderColor="#ff0000" } $ def
  { modMask = mod4Mask
  -- Options
  , terminal    = "r.t"
  , workspaces  = MyWksp.all
  -- , workspaces  = withScreens 2 MyWksp.all
  , keys        = (`mkKeymap` myKeys)
  -- Hooks
  , startupHook = myStartupHook
  , manageHook  = myManageHook <+> manageHook def
  , layoutHook = myLayout
  , handleEventHook = myHandleEventHook
  -- Mouse
  , mouseBindings      = myMouseBindings
  , focusFollowsMouse = False
  , clickJustFocuses = True
  -- Style
  , borderWidth        = 2
  , normalBorderColor  = "#000000"
  , focusedBorderColor = "#c050f0"
  }


-- layoutHintsToCenter
myLayout = smartBorders
    . ModifiedLayout myOverlay
    -- . onWorkspace (workspaces myCfg !! 4) Full
    . mkToggle (single STRUTS)
    . mkToggle (single FULL)
    . avoidStruts
    . mkToggle (single GAPS)
    . mkToggle (single MIRROR)
    . mkToggle (single REFLECTX)
    . onWorkspace "PI" piLayer
    . onWorkspace "SK" (reflectHoriz skLayer)
    $ tiled ||| simpleTabbed ||| simplestFloat ||| Grid ||| Circle
  where
    piLayer = gridIM (1%7) (ClassName "Pidgin" `And` Role "buddy_list")
    skLayer = gridIM (1%7) (ClassName "Skype" `And` Not (Title "Options") `And` Not (Role "Chats") `And` Not (Role "CallWindowForm"))
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
  --   (ask >>= \w -> doF $ W.sink w) >> doShift "IM"
  -- FIXME: bring copyq into between windows stack -- check on first window of fullscreen wksp
  , className =? "copyq" --> doRectFloat (W.RationalRect (1/6) (1/5) (3/10) (3/10))
  ] <+>
  composeFloat
  [ ("Float" `isPrefixOf`) <$> appName
  --EXPL: pidgin is tiled by XMonad.Layout.IM
  -- , let lst = "buddy_list Preferences"
  --   in wmhas (stringProperty "WM_WINDOW_ROLE") lst
  , let lst = "feh Steam Gimp piony.py Transmission-gtk"
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
  mconcat
  -- EXPL: for IM 'shift' is more comfortable
  [ className =? "Pidgin" --> doF (W.shift "PI")
  , className =? "Skype" --> doF (W.shift "SK")
  , className =? "Firefox" --> doF (bring "FF")
  -- , ("5", "Krita")
  -- , ("8", "t-engine64")
  -- , ("9", "Steam")
  , appName =? "mutt" --> doF (bring "MM")  -- (but I can have >1 mutt)
  -- NOTE: strictly speaking, we don't need runOrRaise for mutt
  -- -- only stick it to MM wksp and keys to jump on it
  -- -- but with raise we get auto-launch and jumping even to moved for some reasons windows
  ]
  <+> MON.manageMonitor myOverlay
  <+> namedScratchpadManageHook myScratchpads
  <+> manageDocks
  where
    wmhas t l = foldr1 (<||>) [ t =? x | x <- words l ]
    topmost =  (<+> insertPosition Master Newer)
    composeFloat = mconcat . map (--> topmost doFloat)


-- BUG:FIXME: unsafe io operation, catch error/exception instead of Xorg fail.
catchStdout c f = fmap read (runProcessWithInput c [f] "")
getXorg = catchStdout "r.xorg"

main :: IO ()
main = do
  dpi <- getXorg "-d"
  h <- spawnPipe "xmobar ~/.xmonad/xmobarrc"
  xmonad $ ewmh myCfg { logHook = myLogHook h
  , borderWidth = fromIntegral $ round (dpi / 60)
  }
