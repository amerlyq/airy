-- vim: ts=2:sw=2:sts=2
module XMonad.Config.Amer.EventHook (myHandleEventHook) where

import Control.Arrow  (first)
import Data.Default   (def)
import XMonad                       (handleEventHook)
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
    srvCmds = do
      dfl <- defaultCommands
      return $ dfl ++ map (first (map escape)) myKeys
