-- vim: ts=2:sw=2:sts=2

{- SEE:
  >> https://ro-che.info/docs/xmonad/
  >> http://learnyouahaskell.com/making-our-own-types-and-typeclasses
  https://wiki.haskell.org/Xmonad
  http://xmonad.org/xmonad-docs/xmonad/XMonad-StackSet.html
  Intro:
    > http://echo.rsmw.net/n00bfaq.html
    http://prajitr.github.io/quick-haskell-syntax/
    https://www.schoolofhaskell.com/school/to-infinity-and-beyond/pick-of-the-week/Simple%20examples
  https://en.wikibooks.org/wiki/Haskell/Indentation
  >> http://www.stephendiehl.com/posts/vim_haskell.html
  -- https://github.com/mcmaniac/xmonad/blob/master/xmonad.hs
-}

import XMonad
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks
import XMonad.Util.Run(spawnPipe)
-- easy way to specify shortcuts (including emacs-like submaps)
import XMonad.Util.EZConfig(additionalKeys, mkKeymap)
import System.IO

import XMonad.Config.Desktop

import qualified XMonad.StackSet as W
import XMonad.Actions.CycleRecentWS

-- baseConfig = desktopConfig

myKeys conf = mkKeymap conf $
  [ ("M-u",          spawn       $ (terminal myCfg))
  , ("M-d",          spawn       $ "r.dmenu")
  -- workspaces
  -- -- Cycle recent (not visible) workspaces, tab is next, escape previous in history
  -- , let options w     = map (W.greedyView `flip` w)   (hiddenTags w)
  --   in ("M-<Tab>" , cycleWindowSets options [xK_Super_L] xK_Tab xK_Escape)
  -- -- Cycle through visible screens, a is next, s previous
  -- , let options w     = map (W.view `flip` w)         (visibleTags w)
  --   in ("M-a"     , cycleWindowSets options [xK_Super_L] xK_a xK_s)
  -- Swap visible workspaces on current screen, s is next, d previous
  , let options w     = map (W.greedyView `flip` w)   (visibleTags w)
    in ("M-s"     , cycleWindowSets options [xK_Super_L] xK_s xK_d)
  -- cycle through all windows
  , ("M-j",          windows     $ W.focusDown)
  , ("M-k",          windows     $ W.focusUp)
  -- , ("M-S-q",        io          $ exitWith ExitSuccess)
  , ("M-q",          restart "xmonad" True)
  ]
  ++
  [ ( m ++ i, windows $ f i)
    | i <- (workspaces myCfg)
    , (m, f) <- [("M-", W.view), ("M-S-", W.shift)]
  ]
  where
    hiddenTags  w = map (W.tag $ W.hidden w) ++ [W.workspace . W.current $ w]
    visibleTags w = map (W.tag . W.workspace) $ W.visible w ++ [W.current w]

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
  , borderWidth        = 3
  , normalBorderColor  = "#000000"
  , focusedBorderColor = "#c050f0"
  }

main = do
    xmproc <- spawnPipe "xmobar" -- ~/.xmobarrc
    xmonad $ myCfg
