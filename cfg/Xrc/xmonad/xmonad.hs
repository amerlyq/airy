-- vim: ts=2:sw=2:sts=2

import XMonad
import XMonad.Config.Desktop

import XMonad.Hooks.DynamicLog      (statusBar, xmobarPP, xmobarColor, PP(..))
import XMonad.Hooks.ManageDocks
-- import XMonad.Hooks.SetWMName

import XMonad.Util.EZConfig         (additionalKeys, mkKeymap)

import qualified XMonad.StackSet as W
import XMonad.Actions.CycleRecentWS

import System.IO
import System.Exit


myKeys conf = mkKeymap conf $
  [ ("M-u"        , spawn $ terminal myCfg)
  , ("M-d"        , spawn "r.dmenu"       )
  -- workspaces
  -- -- Cycle recent (not visible) workspaces, tab is next, escape previous in history
  -- , let options w     = map (W.greedyView `flip` w)   (hiddenTags w)
  --   in ("M-<Tab>" , cycleWindowSets options [xK_Super_L] xK_Tab xK_Escape)
  -- -- Cycle through visible screens, a is next, s previous
  -- , let options w     = map (W.view `flip` w)         (visibleTags w)
  --   in ("M-a"     , cycleWindowSets options [xK_Super_L] xK_a xK_s)
  -- Swap visible workspaces on current screen, s is next, d previous
  -- , let options w     = map (W.greedyView `flip` w)   (visibleTags w)
  --   in ("M-s"     , cycleWindowSets options [xK_Super_L] xK_s xK_d)
  , ("M-<Tab>"    , myCycleRecentWS)  -- Toggle previously displayed workspaces
  -- cycle through all windows
  , ("M-j"        , windows W.focusDown)
  , ("M-k"        , windows W.focusUp)
  -- Xmonad
  , ("M-q"          , restart "xmonad" True)
  , ("M-S-<Escape>" , io exitSuccess)
  ]
  ++
  [ ( m ++ i, windows $ f i)
    | i <- (workspaces myCfg)
    , (m, f) <- [("M-", W.view), ("M-S-", W.shift)]
  ]
  where
    hiddenTags w    = map W.tag $ W.hidden w ++ [W.workspace . W.current $ w]
    visibleTags w   = map (W.tag . W.workspace) $ W.visible w ++ [W.current w]
    myCycleRecentWS = let options w = map (W.view `flip` w) (hiddenTags w)
                      in cycleWindowSets options [xK_Super_L] xK_Tab xK_q

myCfg = defaultConfig
  { modMask = mod4Mask
  -- Options
  , terminal    = "r.t"
  , workspaces  = words "` 1 2 3 4 5 6 7 8 9 0 - ="
  , keys        = myKeys
  -- Hooks
  -- , startupHook = setWMName "LG3D"
  , manageHook = manageDocks <+> manageHook defaultConfig
  , layoutHook = avoidStruts  $  layoutHook defaultConfig
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
