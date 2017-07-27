-- vim: ts=2:sw=2:sts=2
module XMonad.Config.Amer.Control (
    keys
) where

import Control.Arrow    (second)
import Data.Default     (def)
import Data.Ratio       ((%))
import Data.Map.Strict  (member)
import Data.Maybe       (maybe, fromMaybe, listToMaybe)
import System.Exit      (exitSuccess)
import XMonad hiding    (keys)
import XMonad.ManageHook            (liftX, className)
import XMonad.Hooks.ManageDocks     (ToggleStruts(..))
import XMonad.Hooks.UrgencyHook     (withUrgents, clearUrgents)
import XMonad.Actions.CycleWS       (toggleOrDoSkip)

import XMonad.Actions.CopyWindow    (killAllOtherCopies, kill1)
import XMonad.Actions.FloatKeys     (keysMoveWindow, keysMoveWindowTo, keysResizeWindow, keysAbsResizeWindow)
import qualified XMonad.Actions.GroupNavigation as GN
import qualified XMonad.StackSet as W
-- BAD: boring windows disallow focusing other windows in fullscreen
--  TRY: sep layout instead of toggle https://github.com/0/.../blob/master/xmonad/xmonad.hs
--  TRY: Simplest from Tips of http://xmonad.org/xmonad-docs/xmonad-contrib/XMonad-Layout-BoringWindows.html
import qualified XMonad.Layout.BoringWindows as B
import XMonad.Layout.Minimize       (minimizeWindow, MinimizeMsg(..))
import XMonad.Layout.Maximize       (maximizeRestore)
import XMonad.Layout.MultiToggle    (Toggle(..))
import XMonad.Layout.MultiToggle.Instances(StdTransformers(FULL, MIRROR, NOBORDERS))
import XMonad.Layout.Reflect        (REFLECTX(REFLECTX))
import XMonad.Layout.ResizableTile  (MirrorResize(MirrorShrink, MirrorExpand))

import XMonad.Config.Amer.Common     (inGroup, feedCmd, backNforth)
import XMonad.Config.Amer.Layout     (MyTransformers(STRUTS, GAPS))
import XMonad.Config.Amer.Navigation (nextNonEmpty)

-- | Get params from current window
-- TRY? we could use simply W.tag on w? See src of toggleWS'
wkspName = ask >>= (\w -> liftX $ withWindowSet $ \ws -> return $ fromMaybe "" $ W.findTag w ws) :: Query String
isFloat  = ask >>= (\w -> liftX $ withWindowSet $ \ws -> return $ member w $ W.floating ws) :: Query Bool

-- DEPRECATED:(by focusNonEmpty)
-- whenWindowsClosed fX = withWindowSet $ \ws -> if null (W.allWindows ws)
--     then fX else nextNonEmpty W.view >> spawn "r.n 'Shutdown warning:' 'Close all windows'" :: X()

-- FIXME: jump to urgent and back ALT: save last urgent and always jump to it even after urgentstate cleared
-- urgentNback w = withUrgents $ maybe (backNforth [] $ W.view w) (windows . W.focusWindow) . listToMaybe $ w
urgentNback = withUrgents $ maybe (return ()) (windows . W.focusWindow) . listToMaybe
-- ENH: urgent_pullNback
-- TRY: UrgencyHook::FocusHook -- to store wksp tag of urgent window
pullUrgents = withUrgents $ maybe (return ()) (windows . \a ws -> W.shiftWin (W.currentTag ws) a ws) . listToMaybe

keys = focusing ++ swap ++ edit ++ movef ++ layouts ++ system

focusing =
  [ ("M-h"      , windows W.focusMaster)
  , ("M-j"      , windows W.focusDown)
  , ("M-k"      , windows W.focusUp)
  , ("M-l"      , GN.nextMatchWithThis GN.History wkspName)
  , ("M-;"      , GN.nextMatchWithThis GN.Forward className)
  , ("M-S-;"    , GN.nextMatchWithThis GN.Backward className)
  , ("M-q"      , urgentNback)
  , ("M-S-q"    , pullUrgents)
  , ("M-C-q"    , clearUrgents)
  ]

swap =
  [ ("M-S-h"    , windows W.shiftMaster)
  , ("M-S-l"    , GN.nextMatchWithThis GN.History wkspName >> windows W.swapMaster)
  , ("M-S-j"    , windows W.swapDown)
  , ("M-S-k"    , windows W.swapUp)
  ]

edit =
  [ ("M-,"      , sendMessage Shrink)
  , ("M-."      , sendMessage Expand)
  , ("M-S-,"    , sendMessage MirrorShrink)
  , ("M-S-."    , sendMessage MirrorExpand)
  -- , ("M-m"      , Tall 1 0 0.5)  -- FIND:(how?)
  , ("M-'"      , sendMessage . IncMasterN $  1)
  , ("M-S-'"    , sendMessage . IncMasterN $ -1)
  ---- float
  -- THINK: jumps between last two float windows -- do combo M-w, M-l better then i3 model
  , ("M-w"      , GN.nextMatch GN.History isFloat)
  , ("M-C-w"    , withFocused $ windows . W.sink)
  , ("M-S-w"    , withFocused float)
  ]

movef =
  [ ("M-<L>"    , withFocused $ keysMoveWindow (-10,0))
  , ("M-<R>"    , withFocused $ keysMoveWindow ( 10,0))
  , ("M-<U>"    , withFocused $ keysMoveWindow (0,-10))
  , ("M-<D>"    , withFocused $ keysMoveWindow (0, 10))
  , ("M-C-<L>"  , withFocused $ keysMoveWindowTo ( 10, 10) (0,0))
  , ("M-C-<R>"  , withFocused $ keysMoveWindowTo (800,410) (0,0))
  , ("M-C-<U>"  , withFocused $ keysMoveWindowTo (800, 10) (0,0))
  , ("M-C-<D>"  , withFocused $ keysMoveWindowTo ( 10,410) (0,0))
  , ("M-S-<L>"  , withFocused $ keysResizeWindow (-10,0) (1%2,1%2))
  , ("M-S-<R>"  , withFocused $ keysResizeWindow (10,0) (1%2,1%2))
  , ("M-S-<U>"  , withFocused $ keysResizeWindow (0,-10) (1%2,1%2))
  , ("M-S-<D>"  , withFocused $ keysResizeWindow (0,10) (1%2,1%2))
  -- , ("M-<U>"      , withFocused $ keysAbsResizeWindow (-10,-10) (1024,752))
  -- , ("M-<D>"      , withFocused $ keysAbsResizeWindow (10,10) (1024,752))
  -- , ("M-<?>"      , withFocused (keysMoveWindowTo (512,384) (1%2,1%2)))
  ]

layouts =
  [ ("M-/"      , sendMessage $ Toggle MIRROR)
  , ("M-S-/"    , sendMessage $ Toggle REFLECTX)
  , ("M-C-/"    , withFocused $ sendMessage . maximizeRestore)
  , ("M-n"      , sendMessage NextLayout)
  , ("M-S-n"    , sendMessage FirstLayout)  -- ALT: setLayout $ XMonad.layoutHook cfg
  , ("M-f"      , sendMessage $ Toggle FULL)  -- sendMessage (SetStruts [] [D]) >>
  , ("M-S-f"    , sendMessage ToggleStruts)
  , ("M-C-f"    , sendMessage $ Toggle STRUTS)
  , ("M-S-C-f"  , sendMessage $ Toggle GAPS)
  , ("M-b"      , withFocused minimizeWindow)
  , ("M-S-b"    , sendMessage RestoreNextMinimizedWin)
  , ("M-C-b"    , B.clearBoring)
  , ("M-S-C-b"  , B.markBoring)
  ]

system =
  -- TODO: kill recursively all nested terminal programs
  [ ("M-\\"     , kill1)
  , ("M-C-\\"   , killAllOtherCopies)
  -- TODO: kill even if window is frozen
  , ("M-C-S-\\" , kill)
  , ("M-S-z"    , spawn "r.lock")
  -- , ("M-C-S-\\" , spawn "~/.i3/ctl/wnd_active_kill") -- FIXME
  ] ++
  --ATTENTION: "M-<Esc>" must be unused -- I use <Esc> to drop xkb latching

  inGroup "M-g"
  [ ("1", screenWorkspace 0 >>= flip whenJust (windows . W.view))
  , ("2", screenWorkspace 1 >>= flip whenJust (windows . W.view))
  ] ++
  (inGroup "M-S-<Esc>" . concat)
  [ [ ("o", spawn "r.core logout")
    , ("r", spawn "r.core reboot")
    , ("t", spawn "r.core shutdown")
    , ("l", spawn "r.core lock")
    , ("n", refresh)  -- Correct size of the viewed windows (workspace normalizing)
    , ("x", restart "xmonad" True)
    , ("j", spawn "r.xmonad-rebuild")
    , ("-", spawn "r.monitor-off")
    ],
    map (second spawn) $ feedCmd "xbacklight -set" $ mconcat
    [ [ (i, i ++ "0")   | i <- map show [1..9] ]
    , [ (" 0 " ++ i, i) | i <- map show [1..9] ]
    ]
  ]
