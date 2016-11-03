-- vim: ts=2:sw=2:sts=2
module XMonad.Config.Amer.Navigation (
    keys, doScreen, nextEmpty, nextNonEmpty
) where

import Data.Default                 (def)
import XMonad                       (gets, spawn, windows, windowset, screenWorkspace, broadcastMessage, float, withFocused, rescreen)
import XMonad.StackSet              (view, shift, currentTag, shiftWin)
import XMonad.Actions.CycleWS       (findWorkspace, screenBy, Direction1D(Prev, Next), WSType(EmptyWS, NonEmptyWS))
import XMonad.Util.WorkspaceCompare (getSortByIndex)

import XMonad.Layout.TwoPane        (TwoPane(..))
import XMonad.Layout.LayoutScreens  (layoutScreens)
import XMonad.Actions.TagWindows    (setTags, addTag, shiftHere, tagPrompt, tagDelPrompt, focusUpTaggedGlobal, withTaggedGlobal, withTaggedGlobalP, withTaggedP)

import XMonad.Config.Amer.Common    (inGroup, actions, backNforth)
import XMonad.Config.Amer.Workspace (skipped, immediate)


-- Cycle through workspaces
-- BUG: them counts unused wksp from current one, NEED any from the start! -- USE another sorting function
-- ALT: choose empty only from secondary wksp? -- Like on M-g <Space> instead <Backspace>
nextEmpty    f = findWorkspace getSortByIndex Next EmptyWS 1    >>= windows . f
nextNonEmpty f = findWorkspace getSortByIndex Next NonEmptyWS 1 >>= windows . f

-- Cycle through screens
-- ALT (screenWorkspace 0 >>= flip whenJust (windows . view))
-- THINK: Jumping between visible/not wksp. Maybe unnecessary (we have doScreen)
--   SEE: https://mail.haskell.org/pipermail/xmonad/2012-August/012880.html
doScreen d f = do
  s <- screenBy d
  mws <- screenWorkspace s
  case mws of
    Nothing -> return ()
    Just ws -> windows (f ws)


keys = screens ++ panels ++ markNgo

screens = [ (m ++ k, b f) | (k, b) <- groups, (m, f) <- actions]
groups =
  [ ("a", backNforth skipped)
  , ("<Backspace>", nextEmpty)
  , ("<Tab>", nextNonEmpty)
  , ("[", doScreen (-1))
  , ("]", doScreen 1)
  ]

panels =
  [ ("M-S-p"    , layoutScreens 2 (TwoPane 0.15 0.85) >> windows (view "MON"))
  , ("M-p"      , rescreen)  -- TODO: toggle show/hide second screen
  ]

-- NEED:DEV: back_and_forth -- to return window on their previous screen
-- -- if on currentFocused -- shiftHere was pressed again
-- FIXME: don't show 'Marked' message on empty WS (skip marking completely)
--  TODO: post current window title in marking message
-- BAD: for 'ext/ctl' need to def all cmds explicitly -- no args possible ?
tagMark t = withFocused (setTags [t]) >> spawn ("r.n Marked " ++ t)
tagFocus = focusUpTaggedGlobal
tagShift t = withTaggedGlobalP t shiftHere
tagActions = [ ("M-S-", tagMark), ("M-", tagFocus), ("M-C-", tagShift) ]
leader = ("s " ++)  -- M-s -- [s]eek tag. EXPL: the least pain to press
quote = ("_" ++)

markNgo =
  [ (m ++ "<" ++ k ++ ">", f . quote $ k)
  | k <- map (\n -> "F" ++ show n) [1..12], (m, f) <- tagActions
  ] ++
  [ (m ++ leader k, f . quote $ k)
  | k <- immediate, (m, f) <- tagActions
  ] ++
  [ ("M-S-t", tagPrompt def focusUpTaggedGlobal)
  , ("M-C-t", tagPrompt def (`withTaggedGlobalP` shiftHere))
  , ("M-S-C-t", tagPrompt def (\s -> withTaggedP s (shiftWin "2")))
  ] ++
  inGroup "M-t"  -- tags
    [ ("a", tagPrompt def (withFocused . addTag))
    , ("x", tagDelPrompt def)
    , ("w", tagPrompt def (`withTaggedGlobal` float))
    ]
