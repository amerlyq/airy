-- vim: ts=2:sw=2:sts=2
module XMonad.Config.Amer.Navigation (
    keys, doScreen, nextEmpty, nextNonEmpty
) where

import XMonad                       (gets, windows, windowset, screenWorkspace)
import XMonad.StackSet              (view, shift, currentTag)
import XMonad.Actions.CycleWS       (findWorkspace, screenBy, toggleOrDoSkip, Direction1D(Prev, Next), WSType(EmptyWS, NonEmptyWS))
import XMonad.Util.WorkspaceCompare (getSortByIndex)

import XMonad.Config.Amer.Workspace (skipped, actions)


-- Cycle through workspaces
-- BUG: them counts unused wksp from current one, NEED any from the start! -- USE another sorting function
-- ALT: choose empty only from secondary wksp? -- Like on M-g <Space> instead <Backspace>
nextEmpty    f = findWorkspace getSortByIndex Next EmptyWS 1    >>= windows . f
nextNonEmpty f = findWorkspace getSortByIndex Next NonEmptyWS 1 >>= windows . f
backNforth   f = gets (currentTag . windowset) >>= toggleOrDoSkip skipped f

-- Cycle through screens
-- ALT (screenWorkspace 0 >>= flip whenJust (windows . W.view))
-- THINK: Jumping between visible/not wksp. Maybe unnecessary (we have doScreen)
--   SEE: https://mail.haskell.org/pipermail/xmonad/2012-August/012880.html
doScreen d f = do
  s <- screenBy d
  mws <- screenWorkspace s
  case mws of
    Nothing -> return ()
    Just ws -> windows (f ws)


keys = [ (m ++ k, b f) | (k, b) <- groups, (m, f) <- actions]

-- TRY:THINK:DEV: swap workspaces backNforth -- so I could completely move primary wksp into secondary
groups =
  [ ("a", backNforth)
  , ("<Backspace>", nextEmpty)
  , ("<Tab>", nextNonEmpty)
  , ("[", doScreen (-1))
  , ("]", doScreen 1)
  ]
