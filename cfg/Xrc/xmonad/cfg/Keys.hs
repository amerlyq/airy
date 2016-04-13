-- vim: ts=2:sw=2:sts=2
module XMonad.Config.Amer.Keys (
    myKeys, myOverlay
) where

import Control.Monad  (when)
import XMonad         (asks, broadcastMessage, refresh, theRoot, X(..), withFocused, Rectangle(..))
import qualified XMonad.Layout.Monitor as MON

import qualified XMonad.Config.Amer.Workspace as MyWksp
import qualified XMonad.Config.Amer.Navigation as MyNavi
import qualified XMonad.Config.Amer.Control as MyCtrl
import qualified XMonad.Config.Amer.Prompt as MyPrompt
import qualified XMonad.Config.Amer.Spawn as MySpawn


-- CHECK: maybe I could incrementally add keys to global var in each module?
myKeys = MyWksp.keys ++ MyNavi.keys ++ MyCtrl.keys ++ MyPrompt.keys ++ MySpawn.keys ++
  [ ("M-b"      , broadcastMessage MON.ToggleMonitor >> refresh)
  ]  -- ++ rootKeys
  where
    -- Additional keymap on empty workspace
    whenRoot fX = asks theRoot >>= \rw -> withFocused $ \cw -> when (cw == rw) fX :: X()
    -- rootKeys = asks theRoot >>= \rw -> withFocused $ \cw -> [ ("<Return>" , spawn "r.t") | cw == rw]
    -- rootKeys = [ ("<Return>" , whenRoot $ spawn "r.t") ]

-- NOTE: you need to launch $ mpv --x11-name overlay -- /path/to/file to activate it
-- ALSO:CHECK: this window must be the unique one
-- BUG: can't focus/close it at all. Control only by mouse. BAD.
-- BETTER: sticking sliding workspace for column of windows on right
-- > NEED: toggleable sublayout, inherited for all windows
-- > BETTER: LayoutScreens
--    ? but how to toggle show/hide for second one?
--    ? maybe ability to have more then one column (like left+right ones) is even better?
--    * need ability to mirror screens to horizontal layout
--    * FIND: better navigation between screens (current one is too frustraiting)
--    * USE: one/several separate, named workspaces for that panel/screen
--    * TODO: show wksp for each screen in status as:  >1 2 > MON MPV  OR  >1 2 | MON MPV
--    ~ THINK: create spacing between those screens?
--    ~ IDEA: apply second screen as overlay with floating layout for main one
--      > to manage monitors separately from other windows
--      : then Layout.Monitor will be unnecessary
-- ~ MAYBE:ALT:(sublayout) DynamicWorkspaceGroups
--     http://mail.haskell.org/pipermail/xmonad/2015-July/014840.html
--     ADD workgroups -- to split my work_log/home_scripts screens
--     IDEA:(for this only) xmobar shows all wksp in current group and blue names for other groups
--       -- when focusing one of that groups -- its wksps replaces list in xmobar -- like fold/open tree structure
-- ALT:BETTER? http://xmonad.org/xmonad-docs/xmonad-contrib/XMonad-Layout-IndependentScreens.html
-- THINK: use named screens to skip screen panel when switching between actual monitors
--    http://hackage.haskell.org/package/xmonad-contrib-0.11.2/docs/XMonad-Actions-PhysicalScreens.html

myOverlay = MON.monitor
  { MON.prop = MON.ClassName "mpv" `MON.And` MON.Resource "overlay"
  , MON.rect = Rectangle (1920-320) 0 320 180  -- Lower right corner
  , MON.persistent = True  -- avoid flickering
  , MON.opacity = 1.0
  , MON.visible = True  -- show on start
  , MON.name = "mpv"  -- assign name to toggle independently
  }
