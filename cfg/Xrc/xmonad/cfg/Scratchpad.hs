-- vim: ts=2:sw=2:sts=2
module XMonad.Config.Amer.Scratchpad (myScratchpads) where

import XMonad
import XMonad.StackSet              (RationalRect(..))
import XMonad.Util.NamedScratchpad  (NamedScratchpad(NS), nonFloating, defaultFloating, customFloating)

myScratchpads :: [NamedScratchpad]
myScratchpads =
  [ NS nm ("r.t -n " ++ nm ++ " -e " ++ nm) (appName =? nm) mng | (nm, mng) <-
    [ ("htop"   , defaultFloating), ("mutt"   , nonFloating)
    , ("ncmpcpp", defaultFloating), ("ipython", bottomThirdFloating)
    ]
  ] ++
  [ NS "pidgin" "pidgin" (className =? "Pidgin" <&&> title =? "Buddy List") defaultFloating
  , NS "skype"  "skype"  (className =? "Skype"  <&&> appName =? "skype" ) defaultFloating
  , NS "lyrics" "cd ~/aura/lyfa/lists && r.t -n lyrics -e $EDITOR ./music.otl" (appName =? "lyrics") nonFloating
  ]
  where
    bottomThirdFloating = customFloating $ RationalRect 0 (2/3) 1 (1/3)
