-- vim: ts=2:sw=2:sts=2
module XMonad.Config.Amer.EventHook (myHandleEventHook) where

import Control.Arrow  (first)
import Data.Default   (def)
import XMonad                       (handleEventHook)
import XMonad.StackSet              (allWindows)
import XMonad.Layout.LayoutHints    (hintsEventHook)
import XMonad.Hooks.ManageDocks     (docksEventHook)
import XMonad.Hooks.EwmhDesktops    (fullscreenEventHook, ewmhDesktopsEventHook)
import XMonad.Hooks.ServerMode      (serverModeEventHookCmd')
import XMonad.Actions.Commands      (defaultCommands)

import XMonad.Config.Amer.Keys      (myKeys)

myHandleEventHook = mconcat
  [ handleEventHook def
  , docksEventHook
  , hintsEventHook
  , fullscreenEventHook
  , ewmhDesktopsEventHook
  , serverModeEventHookCmd' srvCmds
  -- , serverModeEventHookF "XMONAD_COMMAND" (`whenJust` evalExpression defaultEvalConfig)
  ]
  where
    escape ' ' = '_'
    escape c = c
    mapped = map (first (map escape)) myKeys
    srvCmds = do
      dfl <- defaultCommands
      -- isempty <- gets $ null . allWindows . windowset
      -- service = [("is-empty", if isempty then return 0)]
      return $ dfl ++ mapped
