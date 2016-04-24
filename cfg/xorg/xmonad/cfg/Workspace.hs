-- vim: ts=2:sw=2:sts=2
module XMonad.Config.Amer.Workspace (
   all, keys, actions,
   primary, secondary, immediate,
   named, skipped
) where

import Prelude hiding (all)
import Data.List                    (zipWith)
import XMonad                       (windows)
import XMonad.StackSet              (view, shift)
import XMonad.Actions.CopyWindow    (copy)
import XMonad.Actions.SwapWorkspaces(swapWithCurrent)
-- import XMonad.Layout.IndependentScreens (onCurrentScreen, workspaces')

import XMonad.Config.Amer.Common    (bring)

all = concat
  [ primary
  , secondary
  , immediate
  , named
  ]

primary   = words "` 1 2 3 4 5 6 7 8 9 0 - ="
secondary = words "~ ! @ # $ % ^ & * ( ) _ +"
immediate = map (:[]) ['a' .. 'z']

-- TODO: show those workspaces names in different color/style (like blue + italic?)
named = ["FF", "PI", "SK", "MM", "MON"]
skipped = ["NSP", "MON"]


keys = [ (m ++ k, windows $ f i) | (i, k) <- aliases, (m, f) <- actions]
-- keys = [ (m ++ k, windows $ onCurrentScreen f i) | (i, k) <- aliases, (m, f) <- actions]

leader = ("s " ++)  -- ([s]econdary) ALT: g, <Backspace>, <Tab>
aliases = concat
  [ map (\i -> (i, i)) primary
  , map (\i -> (i, leader i)) immediate
  , zipWith (\i k -> (i, leader k)) secondary primary
  ]

actions =
  [ ("M-"     , view)
  , ("M-C-"   , shift)
  , ("M-S-"   , bring)
  , ("M-C-S-" , copy)
  -- THINK: maybe use it only for 'M-a', and bind smth else for wksp?
  , ("M-M1-"  , swapWithCurrent)
  ]
