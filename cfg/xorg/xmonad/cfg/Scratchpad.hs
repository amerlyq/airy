-- vim: ts=2:sw=2:sts=2
module XMonad.Config.Amer.Scratchpad (myScratchpads) where

import XMonad
import XMonad.StackSet              (RationalRect(..))
import XMonad.Util.NamedScratchpad  (NamedScratchpad(NS), nonFloating, defaultFloating, customFloating)

term s c = NS s ("r.t -n " ++ s ++ " -e " ++ c) (appName =? s)
vim s a = term s ("$EDITOR " ++ a)

myScratchpads :: [NamedScratchpad]
myScratchpads =
  [ term s s m | (s, m) <-
    [ ("htop"   , defaultFloating), ("mutt"   , nonFloating)
    , ("ncmpcpp", defaultFloating), ("ipython", bottom_r34b3)
    ]
  ] ++
  [ vim "lyrics" "~/aura/lyfa/lists/music.otl" nonFloating
  , vim "help" "~/aura/airy/cfg/xorg/xmonad/doc/LIOR.otl" defaultFloating
  , term "j8" "j8 -c" bottom_l14b3
  ]
  where
    bottom_r34b3 = customFloating $ RationalRect (1/4) (2/3) 1 (1/3)
    bottom_l14b3 = customFloating $ RationalRect 0 (2/3) (1/4) (1/3)
