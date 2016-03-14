-- vim: ts=2:sw=2:sts=2
module XMonad.Config.Amer.EventHook (myHandleEventHook) where

import Data.Default                 (def)
import XMonad                       (handleEventHook)
import XMonad.Layout.LayoutHints    (hintsEventHook)
import XMonad.Hooks.ManageDocks     (docksEventHook)
import XMonad.Hooks.EwmhDesktops    (fullscreenEventHook)

myHandleEventHook = mconcat
  [ handleEventHook def
  , docksEventHook
  , hintsEventHook
  , fullscreenEventHook
  ]
