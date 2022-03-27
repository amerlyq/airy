-- vim: ts=2:sw=2:sts=2
module XMonad.Config.Amer.Scratchpad (myScratchpads) where

import XMonad.ManageHook            (appName, (=?))
import XMonad.StackSet              (RationalRect(..))
import XMonad.Util.NamedScratchpad  (NamedScratchpad(NS), nonFloating, defaultFloating, customFloating)

term s c = NS s ("env --chdir=/t r.t -n " ++ s ++ " -e " ++ c) (appName =? s)
vim s a = term s ("$EDITOR " ++ a)
ranger s a = term s ("r.ranger -L " ++ a)

myScratchpads :: [NamedScratchpad]
myScratchpads =
  [ term s s m | (s, m) <-
    [ ("htop"   , defaultFloating)
    , ("gotop"  , nonFloating)
    , ("ncmpcpp", defaultFloating)
    , ("ipython", customFloating $ RationalRect (1/4) (2/3) 1 (1/3))
    ]
  ] ++
  [ term s c m | (s, c, m) <-
    [ ("agenda", "r.gcalcli-agenda", nonFloating)
    , ("todo", "r.airy-todo", nonFloating)
    , ("j8", "j8 -c", bottom_l14b3)
    ]
  ] ++
  [ vim "lyrics" "/@/lyfa/lists/music/anime.nou" nonFloating
  , vim "help" "/@/airy/xmonad/doc/LIOR.nou" defaultFloating
  -- import System.Directory             (canonicalizePath)
  -- , canonicalizePath "/@/todo/log/!today" >>= \f -> vim "daily" f nonFloating
  , ranger "daily" "/@/todo/log/!today" nonFloating
  ]
  where
    bottom_l14b3 = customFloating $ RationalRect 0 (2/3) (1/4) (1/3)
