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
-- import XMonad.Layout.IndependentScreens (onCurrentScreen, workspaces')
import Data.Maybe       (maybe, fromMaybe, listToMaybe)

import XMonad.Config.Amer.Common    (actions, backNforth)

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
named = ["FF", "MM", "PI", "SK", "MON"]
skipped = ["NSP", "MON"]


keys = [ (m ++ k, windows $ f i) | (i, k) <- aliases, (m, f) <- actions]
-- TODO: backNforth on repeated press
-- keys = [ (m ++ k, fromMaybe (backNforth [] f) (windows $ f i)) | (i, k) <- aliases, (m, f) <- actions]
-- TODO: backNforth on current monitor only
-- keys = [ (m ++ k, windows $ onCurrentScreen f i) | (i, k) <- aliases, (m, f) <- actions]

-- MAYBE: change to leader-mod-letter for more consistent navigation
-- (+) mod+leader -- additional functions/abilities/new wksps
-- (+) mod+leader-letter -- another functions, not wksp jumping
-- BUT:THINK: mods-leader-letter scheme have the less key presses for additional wksp
leader = ("d " ++)  -- M-d -- [d]esktop wksp. ALT: g, <Backspace>, <Tab>
aliases = concat
  [ map (\i -> (i, i)) primary
  , map (\i -> (i, leader i)) immediate
  , zipWith (\i k -> (i, leader k)) secondary primary
  ]
