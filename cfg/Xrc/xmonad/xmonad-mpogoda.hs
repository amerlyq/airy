import Data.List            (isPrefixOf)
import Control.Applicative  ((<$>))
-- for exiting xmonad
import System.Exit          (exitWith, ExitCode(..))

import XMonad
-- for statusbar
import XMonad.Hooks.DynamicLog      (statusBar, xmobarPP, xmobarColor, PP(..), wrap)
import XMonad.Hooks.EwmhDesktops    (ewmh, fullscreenEventHook)
import XMonad.Hooks.ManageDocks     (docksEventHook, ToggleStruts(..), SetStruts(..))
-- honor size hints
import XMonad.Layout.LayoutHints    (layoutHintsToCenter, hintsEventHook)
-- for auto-toggling fullscreen on fullscreen windows (like flash)
import XMonad.Hooks.ManageHelpers   (isFullscreen, doFullFloat, isDialog)
-- urgency stuff
import XMonad.Hooks.UrgencyHook     (withUrgencyHook, NoUrgencyHook(..))
-- auto-borders
import XMonad.Layout.NoBorders      (smartBorders)
-- enable resizing for non-master windows
import XMonad.Layout.ResizableTile  (ResizableTall(..), MirrorResize(..))
-- hiding & showing some windows
import XMonad.Util.NamedScratchpad  (namedScratchpadAction, namedScratchpadManageHook, NamedScratchpad(..), nonFloating, customFloating)
-- easy way to specify shortcuts (including emacs-like submaps)
import XMonad.Util.EZConfig         (mkKeymap)

import qualified XMonad.StackSet as W
import qualified Data.Map        as M

main :: IO ()
main = do
  xmonad =<< statusBar "xmobar" myPP toggleStrutsKey defaults
  where
    defaults = ewmh $ withUrgencyHook NoUrgencyHook $ defaultConfig
              { terminal           = myTerminal
              , borderWidth        = 3
              , modMask            = mod4Mask
              , workspaces         = myWorkspaces
              , normalBorderColor  = "#1b1d1e"
              , focusedBorderColor = "#a0a0a0"
              , layoutHook         = layoutHintsToCenter . smartBorders $ myLayout
              , manageHook         = myManageHook <+> namedScratchpadManageHook scratchpads
              }

-- How we should manage windows
myManageHook :: ManageHook
myManageHook = composeAll
            (
            [ myIgnores    --> doIgnore     -- Don't manage
            , myFloats     --> doFloat      -- Make floating
            , isFullscreen --> doFullFloat  -- Auto-fullscreen
            ]
            ++
            [ x --> doShift w | (x, w) <- myShifts ] -- Perform shifts
            )
  where
    -- list of conditions when we have make window floating
    myFloats = foldr1 (<||>)
      [ ("Figure" `isPrefixOf`) <$> title
      , className =? "feh"
      , className =? "mplayer2"
      , className =? "Steam"
      , isDialog
      ]
    -- list of conditions when we have to ignore window (don't manage it)
    myIgnores = foldr1 (<||>)
      [ resource  =? "panel"
      , className =? "stalonetray"
      ]
    -- when condition from first part of tuple succeed, move that window to #2
    myShifts = map (\(x, y) -> (className =? x, y)) clsShifts
    -- [ ( className, workspace) ]
    clsShifts = [ ("Chromium-browser", "r")
                , ("Google-chrome-unstable", "r")
                , ("Firefox", "r")
                , ("Leechcraft", "a")
                ] :: [(String,  String)]

-- Keys
myKeys = \conf -> mkKeymap conf $
         [ ("M-u",          spawn       $ myTerminal )
         , ("M-<Return>",   spawn       $ myTerminal ++ " -e r.ranger")
         , ("M-S-<Return>", spawn       $ myTerminal ++ " -e tmux")
         , ("M-C-<Esc>",    spawn       $ "xkill")
         , ("M-d",          spawn       $ "r.dmenu")
         -- cycle through all possible layouts
         , ("M-<Space>",    sendMessage $ NextLayout)
         -- restore default layout
         , ("M-S-<Space>",  setLayout   $ XMonad.layoutHook conf)
         , ("M-n",          refresh)
         -- cycle through all windows
         , ("M-j",          windows     $ W.focusDown)
         , ("M-k",          windows     $ W.focusUp)
         -- jump to master pane
         , ("M-m",          windows     $ W.focusMaster)
         -- moving stuff
         , ("M-S-j",        windows     $ W.swapDown)
         , ("M-S-k",        windows     $ W.swapUp)
         , ("M-S-m",        windows     $ W.swapMaster)
         -- enlarging|shrinking stuff
         , ("M-h",          sendMessage $ Shrink)
         , ("M-l",          sendMessage $ Expand)
         , ("M-o",          sendMessage $ MirrorShrink)
         , ("M-i",          sendMessage $ MirrorExpand)
         -- make floating windows non-floating
         , ("M-w",          withFocused $ windows . W.sink)
         -- increase/decrease number of windows in master pane
         , ("M-,",          sendMessage $ IncMasterN 1)
         , ("M-.",          sendMessage $ IncMasterN (-1))
         -- statusbar stuff
         , ("M-b",          sendMessage $ ToggleStruts)

         , ("M-S-q",        io          $ exitWith ExitSuccess)
         , ("M-q",          restart "xmonad" True)

         -- close current window
         , (prefix "c", kill)
         -- shortcuts
         , (prefix "b", spawn $ "firefox")
         , (prefix "e", spawn $ "gvim")
         , (prefix "r", namedScratchpadAction scratchpads "term")
         , (prefix "d", namedScratchpadAction scratchpads "dashboard")
         ]
         ++
         -- M-[asdfgzxcv]   : switch to corresponding workspace
         -- M-S-[asdfgzxcv] : move window to " " " " " " "
         [ ( m ++ i, windows $ f i)
            | i <- myWorkspaces
            , (m, f) <- [("M-", W.view), ("M-S-", W.shift)]
         ]
  where
    -- prefix that is used in my emacs-like keybidings
    prefix  = (++) "M-<Tab> " :: String -> String

scratchpads :: [NamedScratchpad]
scratchpads = [ NS "dashboard" (myTerminal ++ " -c dashboard -e /bin/sh /home/tmux.sh")
                  (className =? "dashboard") nonFloating
              , NS "term" (myTerminal ++ " -c term -e tmux") (className =? "term")
                  ( customFloating $ W.RationalRect 0 (2/3) 1 (1/3))
              ]
