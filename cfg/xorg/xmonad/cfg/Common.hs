-- vim: ts=2:sw=2:sts=2
module XMonad.Config.Amer.Common (
    bring, backNforth, actions, actionMons,
    inGroup, feedCmd
) where

import XMonad                         (gets, windowset)
import XMonad.Actions.CopyWindow      (copy)
import XMonad.Actions.CycleWS         (toggleOrDoSkip)
import XMonad.Actions.SwapWorkspaces  (swapWithCurrent)
import qualified XMonad.StackSet as W


withMods k = zip $ (++ k) ["M-", "M-S-", "M-C-", "M-C-S-", "M-M1-"]

-- ALT (\w -> windows (W.shift w) >> windows (W.view w))
bring i = W.view i . W.shift i

-- TRY:THINK:DEV: swap workspaces backNforth -- so I could completely move primary wksp into secondary
-- DEV: backNforth -- return to last non empty (useful only rarely -- after closing all windows on wksp)
-- DEV: backNforth -- move through whole history instead toggling only two last
-- -- import XMonad.Actions.GroupNavigation(nextMatch, Direction(History))
-- -- backHistory  f = nextMatch History (return True) -- BUG: only toggles between two recent
-- -- SEE: http://xmonad.org/xmonad-docs/xmonad-contrib/XMonad-Actions-TopicSpace.html
-- -- has history navigation between last workspaces
backNforth l f = gets (W.currentTag . windowset) >>= toggleOrDoSkip l f

-- EXPL: don't focus to secondary screen at all
isVisible w ws = any ((w ==) . W.tag . W.workspace) (W.visible ws)
lazyView w ws = if isVisible w ws then ws else W.view w ws

-- THINK: maybe use swapWithCurrent only for 'M-a', and bind smth else for wksp?
actions :: (Eq s, Eq i, Ord a) => [(String, i -> W.StackSet i l a s sd -> W.StackSet i l a s sd)]
actions = withMods [""] [lazyView, bring, W.shift, copy, swapWithCurrent]
actionMons :: (Eq s, Eq i, Ord a) => [(String, i -> W.StackSet i l a s sd -> W.StackSet i l a s sd)]
actionMons = withMods [""] [W.view, bring, W.shift, copy, W.greedyView]

inGroup prf = map $ \(k, f) -> (prf ++ " " ++ k, f)
feedCmd cmd = map $ \(k, o) -> (k, cmd ++ " " ++ o)

-- hidTags w = map W.tag $ W.hidden w ++ [W.workspace . W.current $ w]
-- visTags w = map (W.tag . W.workspace) $ W.visible w ++ [W.current w]
