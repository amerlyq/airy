-- vim: ts=2:sw=2:sts=2

-- >> https://ro-che.info/docs/xmonad/
-- https://wiki.haskell.org/Xmonad
-- http://xmonad.org/xmonad-docs/xmonad/XMonad-StackSet.html
-- http://prajitr.github.io/quick-haskell-syntax/
-- https://www.schoolofhaskell.com/school/to-infinity-and-beyond/pick-of-the-week/Simple%20examples
-- https://en.wikibooks.org/wiki/Haskell/Indentation

import XMonad
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks
import XMonad.Util.Run(spawnPipe)
import XMonad.Util.EZConfig(additionalKeys)
import System.IO

import XMonad.Config.Desktop

-- easy way to specify shortcuts (including emacs-like submaps)
import XMonad.Util.EZConfig         (mkKeymap)

import qualified XMonad.StackSet as W

baseConfig = desktopConfig

myTerminal = "r.t"
-- myWorkspaces :: [String]
myWorkspaces = words "` 1 2 3 4 5 6 7 8 9 0 - ="

myKeys = \conf -> mkKeymap conf $
  [ ("M-u",          spawn       $ myTerminal )
  , ("M-d",          spawn       $ "r.dmenu")
  -- cycle through all windows
  , ("M-j",          windows     $ W.focusDown)
  , ("M-k",          windows     $ W.focusUp)
  -- , ("M-S-q",        io          $ exitWith ExitSuccess)
  , ("M-q",          restart "xmonad" True)
  ]
  ++
  [ ( m ++ i, windows $ f i)
    | i <- myWorkspaces
    , (m, f) <- [("M-", W.view), ("M-S-", W.shift)]
  ]

cfg = defaultConfig
  { modMask = mod4Mask
  -- Options
  , terminal    = myTerminal
  , workspaces  = myWorkspaces
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
    xmonad $ cfg
    print $ cfg.terminal
