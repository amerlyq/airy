-- vim: ts=2:sw=2:sts=2
module XMonad.Config.Amer.Scratchpad (myScratchpads) where

import XMonad
import XMonad.StackSet              (RationalRect(..))
import XMonad.Util.NamedScratchpad  (NamedScratchpad(NS), nonFloating, defaultFloating, customFloating)

myScratchpads :: [NamedScratchpad]
myScratchpads =
  [ NS nm ("r.t -n " ++ nm ++ " -e " ++ nm) (appName =? nm) mng | (nm, mng) <-
    [ ("htop"   , defaultFloating), ("mutt"   , nonFloating)
    , ("ncmpcpp", defaultFloating), ("ipython", bottom_r34b3)
    ]
  ] ++
  [ NS "lyrics" "cd ~/aura/lyfa/lists && r.t -n lyrics -e $EDITOR ./music.otl" (appName =? "lyrics") nonFloating
  , NS "j8"  "r.t -n j8 -e j8 -c"  (appName =? "j8" ) bottom_l14b3
  ]
  where
    bottom_r34b3 = customFloating $ RationalRect (1/4) (2/3) 1 (1/3)
    bottom_l14b3 = customFloating $ RationalRect 0 (2/3) (1/4) (1/3)
