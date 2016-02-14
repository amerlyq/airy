-- vim: ts=2:sw=2:sts=2
module Main (main) where

import XMonad
import XMonad.Config.Desktop

import XMonad.Hooks.DynamicLog      (statusBar, xmobarPP, xmobarColor, PP(..))
import XMonad.Hooks.ManageDocks     (manageDocks, avoidStruts, docksEventHook)
import XMonad.Layout.LayoutHints    (hintsEventHook)  -- honor size hints
-- import XMonad.Hooks.SetWMName

import XMonad.Util.EZConfig         (additionalKeys, mkKeymap)
import Graphics.X11.ExtraTypes.XorgDefault  -- xK_ISO_Left_Tab

import qualified XMonad.StackSet as W
import XMonad.Actions.CycleRecentWS (cycleWindowSets)

import System.IO
import System.Exit


myKeys conf = mkKeymap conf $
  [ ("M-u"        , spawn $ terminal myCfg)
  , ("M-d"        , spawn "r.dmenu"       )
  -- cycle through all windows
  , ("M-j"        , windows W.focusDown)
  , ("M-k"        , windows W.focusUp)
  -- Xmonad
  , ("M-q"          , restart "xmonad" True)
  , ("M-S-<Escape>" , io exitSuccess)
  ] ++
  -- cycling
  let visWs w = map (W.greedyView `flip` w) (visTags w)
      hidWs w = map (W.greedyView `flip` w) (hidTags w)
      rctWs w = map (W.view `flip` w)       (map ($ hidTags w) [head, last])
  in [ ("M-<Tab>"  , cycleWindowSets visWs [xK_Super_L] xK_Tab xK_ISO_Left_Tab)
     , ("M-S-<Tab>", cycleWindowSets hidWs [xK_Super_L] xK_ISO_Left_Tab xK_Tab)
     , ("M-a"      , cycleWindowSets rctWs [xK_Super_L] xK_a xK_a)
  ] ++
  -- workspaces
  [ (m ++ i, windows $ f i) | i <- workspaces myCfg
    , (m, f) <- [("M-", W.view), ("M-S-", W.shift)]
  ]
  where
    hidTags w = map W.tag $ W.hidden w ++ [W.workspace . W.current $ w]
    visTags w = map (W.tag . W.workspace) $ W.visible w ++ [W.current w]

myCfg = defaultConfig
  { modMask = mod4Mask
  -- Options
  , terminal    = "r.t"
  , workspaces  = words "` 1 2 3 4 5 6 7 8 9 0 - ="
  , keys        = myKeys
  -- Hooks
  -- , startupHook = setWMName "LG3D"
  , manageHook = manageHook defaultConfig <+> manageDocks
  , layoutHook = avoidStruts  $  layoutHook defaultConfig
  , handleEventHook = handleEventHook defaultConfig <+> mconcat
      [ docksEventHook, hintsEventHook ]
  -- Style
  , borderWidth        = 2
  , normalBorderColor  = "#000000"
  , focusedBorderColor = "#c050f0"
  }


myPP :: PP  -- xmobar pretty printing source
myPP = xmobarPP
  { ppCurrent = xmobarColor "#fd971f" ""
  , ppSep     = xmobarColor "#fd971f" "" " \xe0b1 "           -- separator between elements
  , ppOrder   = \(ws:l:_) -> [l, ws]                          -- elems order (title ignored)
  , ppHidden  = \w -> if elem w (workspaces myCfg) then w else ""  -- only predefined by me
  , ppLayout  = \n -> case n of                               -- short 'titles' for layouts
      "Full" -> "[ ]"
      "ResizableTall" -> "[|]"
      "Mirror ResizableTall" -> "[-]"
      _ -> n
  }


main :: IO ()
main = xmonad =<< statusBar "xmobar" myPP toggleStrutsKey myCfg
  where
    toggleStrutsKey XConfig { XMonad.modMask = modMask } = (modMask, xK_b)
