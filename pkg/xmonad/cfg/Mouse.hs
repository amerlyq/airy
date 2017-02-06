-- vim: ts=2:sw=2:sts=2
module XMonad.Config.Amer.Mouse (myMouseBindings) where

import XMonad
import qualified Data.Map.Strict as M
import qualified XMonad.StackSet as W
import qualified XMonad.Actions.FlexibleManipulate as Flex


myMouseBindings :: XConfig Layout -> M.Map (KeyMask, Button) (Window -> X ())
myMouseBindings XConfig {XMonad.modMask = modMask} = M.fromList
  -- mod-button1 %! Set the window to floating mode and move by dragging
  -- [ ((modMask, button1), \w -> focus w >> mouseMoveWindow w >> windows W.shiftMaster)
  -- mod-button2 %! Raise the window to the top of the stack
  [ ((modMask, button2), windows . (W.shiftMaster .) . W.focusWindow)
  -- mod-button3 %! Set the window to floating mode and resize by dragging
  -- , ((modMask, button3), \w -> focus w >> mouseResizeWindow w >> windows W.shiftMaster)
  -- optional. but nicer than normal mouse move and size
  -- , ((mod4Mask, button3), \w -> focus w >> Flex.mouseWindow Flex.discrete w)
  , ((mod4Mask, button3), Flex.mouseWindow Flex.discrete)
  -- scroll wheel window focusing
  , ((mod4Mask, button4), const $ windows W.swapDown)
  , ((mod4Mask, button5), const $ windows W.swapUp)
  ]
