-- vim: ts=2:sw=2:sts=2
module XMonad.Config.Amer.Workspace (
   all, keys,
   primary, secondary, immediate,
   named, skipped
) where

import Prelude hiding (all)
import Data.List                    (zipWith)
import XMonad                       (windows)
import XMonad.StackSet              (view, shift)
import XMonad.Actions.CopyWindow    (copy)


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
named = ["FF", "MM"]
skipped = ["NSP"]


keys = [ (m ++ k, windows $ f i) | (i, k) <- aliases, (m, f) <- actions]

leader = ("g " ++)  -- ALT: s, <Backspace>, <Tab>
aliases = concat
  [ map (\i -> (i, i)) primary
  , zipWith (\i k -> (i, leader k)) secondary primary
  , map (\i -> (i, leader i)) immediate
  ]

actions =
  [ ("M-"     , view)
  , ("M-C-"   , shift)
  , ("M-S-"   , \i -> view i . shift i)
  , ("M-C-S-" , copy)
  ]
