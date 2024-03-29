-- vim: ts=2:sw=2:sts=2
{-# LANGUAGE ScopedTypeVariables #-}
module Main (main) where

---- Std
import Control.Monad (when, unless)
import Data.List     (isPrefixOf, isInfixOf)
import Data.Ratio    ((%))
import Data.Maybe    (maybe, fromMaybe, fromJust, isJust)
import Text.Read     (readMaybe)
import System.Directory     (doesFileExist)
import System.IO
import System.IO.Error      (IOError)
-- import System.IO.Unsafe     (unsafePerformIO)
import Control.Exception    (handle)
import System.Environment   (getArgs, getEnv, lookupEnv)
import System.Process       (readProcessWithExitCode)
import System.Posix.Types   (ProcessID)
import System.Posix.Process (getProcessID, getParentProcessID, getProcessGroupID)
import System.Posix.Signals (signalProcess, sigUSR1)
import System.Exit          (ExitCode(ExitSuccess))

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
import XMonad.Hooks.ManageHelpers   (composeOne, (-?>), transience, isFullscreen, doFullFloat, doCenterFloat, doRectFloat, doFloatAt, isDialog, isInProperty)
import XMonad.Hooks.InsertPosition  (insertPosition, Position(Master, Above, Below), Focus(Newer, Older))
import XMonad.Hooks.UrgencyHook     (withUrgencyHook, BorderUrgencyHook(..))
import XMonad.Hooks.DynamicProperty (dynamicPropertyChange, dynamicTitle)

---- Layouts
import qualified XMonad.StackSet as W
-- basis
import XMonad.Layout.Fullscreen     (fullscreenFocus, fullscreenManageHook)
import XMonad.Layout.TrackFloating  (trackFloating)
import qualified XMonad.Layout.Tabbed as T
import XMonad.Layout.TwoPane        (TwoPane(..))
import XMonad.Layout.Grid           (Grid(..))
import XMonad.Layout.Circle         (Circle(..))
import XMonad.Layout.SimplestFloat  (simplestFloat)
import XMonad.Layout.IM             (gridIM, Property(ClassName, Title, Role, And, Not))
-- DEV:
import XMonad.Layout.BoringWindows  (boringWindows)
import XMonad.Layout.Minimize       (minimize)
import XMonad.Layout.Maximize       (maximize)
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

------ User State
-- import qualified XMonad.Util.ExtensibleState as XS
---- Glob
-- newtype BoolWasRestarted = BoolWasRestarted Bool
-- instance ExtensionClass BoolWasRestarted where
--   initialValue = BoolWasRestarted False
---- Get (startupHook)
-- restarted <- XS.get :: X BoolWasRestarted
-- case restarted of
--   BoolWasRestarted b -> trace $ show "hi"
---- Put (main)
-- args <- getArgs
-- when ("--replace" `elem` args) $ XS.put (BoolWasRestarted True)
-- ALT: newIORef (BoolWasRestarted True)


-- notifySystemd = do
--   -- FIXME: skip on non-systemd MAYBE:BUG: one more notify on each --restart
--   -- NEED: one-time env vars https://www.freedesktop.org/software/systemd/man/sd_notify.html
--   -- MAYBE: NOTIFY_SOCKET is set automatically when Type=notify?
--   -- getProcessID >>= \p -> spawn $ "systemd-notify --ready --pid=" ++ show $ liftIO . p
--   pid  <- liftIO getProcessID
--   trace $ show pid
--   -- myHome = unsafePerformIO $ getEnv "HOME"
--   soc <- io $ getEnv "NOTIFY_SOCKET"
--   trace $ show soc
--   spawn $ "systemd-notify --ready --pid=" ++ show pid

notifySystemd :: X ()
notifySystemd = liftIO $ do
  sppid <- lookupEnv "NOTIFY_PPID"
  when (isJust sppid) $ do
    -- trace $ show $ fromJust sppid
    let ippid = readMaybe (fromJust sppid) :: Maybe ProcessID
    when (isJust ippid) $ do
      ppid <- getParentProcessID  -- getProcessGroupID
      -- trace $ show ppid
      when (fromJust ippid == ppid) $
        signalProcess sigUSR1 ppid

  -- (e, _, _) <- readProcessWithExitCode "/usr/bin/systemctl" ["--user", "is-active", "wm.target"] ""
  -- trace $ show e
  -- when (e == ExitSuccess) $ return ()

  -- BAD: default xmonad don't support additional args
  -- args <- getArgs
  -- trace $ show args
  -- unless (null args) $
  --   maybe (return()) (signalProcess sigUSR1) (readMaybe (head args) :: Maybe ProcessID)


-- ATTENTION: launched twice when /usr/bin/xmonad started
myStartupHook = do
  -- broadcastMessage $ SetStruts [] [minBound..maxBound]
  ewmhDesktopsStartup  -- EXPL: to be able to use 'wmctrl'
  setWMName "LG3D"  -- Fixes problems with Java GUI programs
  notifySystemd
  -- FIXME: dirty fix to not jump to 1st wksp on each restart beside startup
  -- BUG: stopped to work?
  curr <- gets (W.currentTag . windowset)
  when (curr == head MyWksp.all || curr == "PI") $
    windows . W.view $ MyWksp.primary !! 1
  -- NOTE: must be the last
  checkKeymap myCfg myKeys


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
  -- TRY: borderWidth based on window
  -- REF: http://haskell.1045720.n5.nabble.com/More-possibilities-for-border-width-customization-td5825298.html
  -- e.g. setBorder bw = ask >>= \w -> liftX (withDisplay $ \d -> io $ setWindowBorderWidth d w bw) >> idHook
  , borderWidth        = 2
  , normalBorderColor  = "#000000"
  , focusedBorderColor = "#00af00"
  }


myTabConfig = def
  { T.inactiveBorderColor = "#222222"
  , T.activeTextColor = "#22ff44"
  , T.fontName = "xft:monospace:pixelsize=15"
  -- , T.decoHeight =
  }


-- layoutHintsToCenter
myLayout = smartBorders
    . ModifiedLayout myOverlay
    -- . onWorkspace (workspaces myCfg !! 4) Full
    . fullscreenFocus
    . maximize
    . mkToggle (single STRUTS)
    . mkToggle (single FULL)
    . avoidStruts
    . mkToggle (single GAPS)
    . mkToggle (single MIRROR)
    . mkToggle (single REFLECTX)
    . boringWindows
    . minimize
    -- . onWorkspace "PI" piLayer
    -- . onWorkspace "SK" (reflectHoriz skLayer)
    . trackFloating
    $ tiled ||| TwoPane (1/100) (1/2) ||| Grid
    -- $ tiled ||| TwoPane (1/100) (1/2) ||| tabi ||| Grid ||| simplestFloat
  where
    piLayer = gridIM (1%7) (ClassName "Pidgin" `And` Role "buddy_list")
    skLayer = gridIM (1%6) (ClassName "Skype" `And` Not (Title "Options") `And` Not (Role "Chats") `And` Not (Role "CallWindowForm"))
    tiled   = ResizableTall nmaster delta ratio [ratio]
    -- tabi    = T.tabbedAlways T.shrinkText myTabConfig
    nmaster = 1     -- number of windows in master pane
    ratio   = toRational (1.9 / (1 + sqrt 5.0)) -- phi
    delta   = 1/100 -- step of increasing


-- RFC: mconcat . concat $ [ [
myManageHook :: ManageHook
myManageHook = manageSpawn <+> fullscreenManageHook <+>
  -- (dynamicTitle ((stringProperty "WM_NAME" =? "" && stringProperty "_NET_WM_NAME" =? "Emulator") --> doIgnore)) <+>
  mconcat
  [ isFullscreen --> doFullFloat
  , isDialog --> doFloat
  -- , isDialog --> doCenterFloat
  --   (ask >>= \w -> doF $ W.sink w) >> doShift "IM"
  -- FIXME: bring copyq into between windows stack -- check on first window of fullscreen wksp
  , className =? "copyq" --> doRectFloat (W.RationalRect (1/6) (1/5) (4/10) (4/10))
  , className =? "rdesktop" --> doFullFloat

  -- FAIL: don't work ("Android Emulator" `isPrefixOf`)
  -- WM_NAME(STRING) = "Android Emulator - 10.1_WXGA_Tablet_API_30:5554"
  , fmap ("Emulator" `isPrefixOf`) title --> doFloatAt (1/200) (1/100)

  -- TODO ignore completely
  -- WM_NAME(STRING) =
  -- _NET_WM_NAME(UTF8_STRING) = "Emulator"
  -- _NET_WM_WINDOW_TYPE(ATOM) = _NET_WM_WINDOW_TYPE_UTILITY, _KDE_NET_WM_WINDOW_TYPE_OVERRIDE, _NET_WM_WINDOW_TYPE_NORMAL
  --
  -- , stringProperty "_NET_WM_NAME" =? "Emulator" --> doIgnore
  -- WM_CLASS(STRING) = "-device", "Emulator"
  -- , fmap ("Android Emulator" `isPrefixOf`) className --> doFloat
  , className =? "Emulator" --> doFloat

  ] <+>
  composeFloat
  [ ("Float" `isPrefixOf`) <$> appName
  --EXPL: pidgin is tiled by XMonad.Layout.IM
  -- , let lst = "buddy_list Preferences"
  --   in wmhas (stringProperty "WM_WINDOW_ROLE") lst
  -- BAD: floating "Steam" will run away in diagonal bot-right if {borderWidth > 2}
  , let lst = "feh Gimp piony.py Transmission-gtk"  -- "jetbrains-studio"
    in wmhas className lst
  , let lst = "PlayOnLinux Dialog pinentry-qt"
    in wmhas appName lst
  , className =? "firefox" <&&> appName =? "Download"
  ] <+>
  -- for_window [title="^ElonaPlus"] fullscreen
  mconcat
  [ wmhas className "stalonetray Dunst" --> doIgnore
  , wmhas appName "panel desktop_window kdesktop trayer" --> doIgnore
  -- TODO:FIND: exclude pop-up windows for Dunst/copyq from stealing focus
  -- MAYBE: there bug in copyq WM_WINDOW_TYPE or it doesn't work with ATOM
  --   https://xmonad.haskell.narkive.com/mcO5HF2r/use-atomic-window-props-in-window-manage-hook
  -- CHECK:FIND: how to keep kbdd current layout on stealing
  -- THINK:USE: another notifier:
  -- -- http://nochair.net/posts/2010/10-25-freedesktop-notifications-xmobar.html
  -- -- https://wiki.archlinux.org/index.php/Desktop_notifications

  -- WARN: https://xmonad.haskell.narkive.com/mcO5HF2r/use-atomic-window-props-in-window-manage-hook
  , foldr1 (<||>) [ isInProperty "_NET_WM_WINDOW_TYPE" x | x <-
    [ "_NET_WM_WINDOW_TYPE_TOOLTIP"
    , "_NET_WM_WINDOW_TYPE_UTILITY"  -- Emulator toolbar REF: https://specifications.freedesktop.org/wm-spec/1.3/ar01s05.html
    , "_NET_WM_WINDOW_TYPE_NOTIFICATION"
    , "_KDE_NET_WM_WINDOW_TYPE_OVERRIDE"  -- OR: (WM_NAME = "" && _NET_WM_NAME = "zoom")
    -- _NET_WM_WINDOW_TYPE_DIALOG
    ] ] --> doIgnore
  -- FAIL: skype pop-up window during call still tiled instead of floating/ignored
  -- TRY: isPreview = isInProperty "_NET_WM_STATE" "_NET_WM_STATE_ABOVE"
  , foldr1 (<||>) [ isInProperty "_NET_WM_STATE" x | x <-
    [ -- "WM_COLORMAP_WINDOWS"
    -- , "_NET_WM_STATE_ABOVE"
    "_NET_WM_STATE_SKIP_TASKBAR"  -- "Android/IDEa/jetbrains-studio"
    -- , _GTK_HIDE_TITLEBAR_WHEN_MAXIMIZED(CARDINAL) = 1
    -- , _NET_WM_STATE(ATOM) = WM_COLORMAP_WINDOWS, _NET_WM_STATE_ABOVE
    ] ] --> doIgnore
  -- WTF: it seems "stringProperty" is wrong
  --   -- we need _NET_WM_WINDOW_TYPE(ATOM) and atom constants to compare
  , foldr1 (<||>) [ stringProperty "WM_NAME" =? x | x <-
    [ "Microsoft Teams Notification" ] ] --> doIgnore
  ] <+>
  -- insertPosition Below Newer <+>
  mconcat
  -- EXPL: for IM 'shift' is more comfortable
  [ className =? "Pidgin" --> doF (W.shift "PI")
  , className =? "Skype" --> doF (W.shift "SK")
  -- , className =? "Skype Preview" --> doF (W.shift "SK")

  -- WM_WINDOW_ROLE(STRING) = "browser"
  -- WM_CLASS(STRING) = "Navigator", "firefox"
  , className =? "firefox" --> doF (bring "b")  -- "FF"

  -- , className =? "xmind-2020" --> (\w -> doF (W.sink w)
  -- , ("5", "Krita")
  -- , ("8", "t-engine64")
  -- , ("9", "Steam")
  , className =? "Steam" --> doF (bring "g")
  , appName =? "daily" --> doF (bring "5")
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
    -- topmost =  (<+> insertPosition Master Newer)
    composeFloat = mconcat . map (--> doFloat)


-- ALT: acquire dpi directly from xmonad
-- SEE: https://git.joko.gr/joko/dotfiles/commit/9a918ac37297ecfee511d541b9d5caa8f795f7c4?style=split
-- BUG:FIXME: unsafe io operation, catch error/exception instead of Xorg fail.
catchStdout c f = fmap read (runProcessWithInput c [f] "")

main :: IO ()
main = do
  -- USE: Maybe Exception
  -- handle (\(e :: IOException) -> print e >> return Nothing) $ do
  --     h <- openFile "/some/path" ReadMode
  --     return (Just h)

  -- TODO:MOVE: into 'withStatusBar' function (like exists for xmobar)
  xdg <- lookupEnv "XDG_RUNTIME_DIR"
  -- ALT:(old): xdg <- handle (\(e :: IOError) -> return "/run/user/1000") $ getEnv "XDG_RUNTIME_DIR"
  let fifoName = fromMaybe "/run/user/1000" xdg ++ "/xmobar/wm"
  barExists <- doesFileExist fifoName
  h <- if barExists
    then openBinaryFile fifoName WriteMode
    else spawnPipe "xmobar ~/.xmonad/xmobarrc"
  hSetBuffering h LineBuffering

  -- TODO:CHG: query value from Xft.dpi by xmonad means instead!
  -- BUT:TEMP: impossible as xprofile can be run only after xmonad
  -- BUG: not found r.xorg
  -- -- dpi <- print (fromMaybe 96 (catchStdout "r.xorg" "-d"))
  -- -- (err, stdout, _) <- readProcessWithExitCode "r.xorg" ["-d"] ""
  -- -- dpi <- fmap read stdout
  -- dpi <- catchStdout "r.xorg" "-d"

  xmonad $ ewmh myCfg { logHook = myLogHook h
  -- , borderWidth = fromIntegral $ round (dpi / 60)
  -- -- , borderWidth = fromIntegral $ round (fromMaybe 96 (catchStdout "r.xorg" "-d") / 60)
  }

  -- CHECK: is really necessary?
  hClose h
