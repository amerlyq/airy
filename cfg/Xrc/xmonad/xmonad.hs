-- vim: ts=2:sw=2:sts=2
module Main (main) where

---- Std
-- import Control.Arrow (second)
import Control.Monad (when, liftM2)
import Data.List     (zipWith, isPrefixOf)
import Data.Maybe    (isNothing,fromMaybe)
import Data.Ratio    ((%))
import Data.Default  (def)
import qualified Data.Map as M
import System.IO
import System.Exit

---- Core
import XMonad                       -- (float, kill, spawn, refresh, restart, doFloat, workspaces, windows, withFocused, sendMessage, Resize(Shrink, Expand), IncMasterN)
import XMonad.Util.Run              (spawnPipe)
import XMonad.Util.EZConfig         (mkKeymap)
import XMonad.Util.WorkspaceCompare (getSortByIndex)
import XMonad.ManageHook            (liftX, className)

---- Interaction
import XMonad.Prompt.Shell          (shellPrompt)
import XMonad.Prompt.Input          (inputPrompt, inputPromptWithCompl, (?+))

---- Actions
import XMonad.Actions.CycleWS       (doTo, moveTo, shiftTo, toggleWS', Direction1D(Prev, Next), WSType(NonEmptyWS, EmptyWS))
import XMonad.Actions.TagWindows    (setTags, focusUpTaggedGlobal, withTaggedGlobalP, shiftHere)
import XMonad.Actions.CopyWindow    (copy, copyWindow, runOrCopy, killAllOtherCopies, kill1, wsContainingCopies)
import XMonad.Actions.FloatKeys     (keysMoveWindow, keysMoveWindowTo, keysResizeWindow, keysAbsResizeWindow)
import XMonad.Actions.SpawnOn       (manageSpawn, spawnHere, spawnAndDo)
import XMonad.Actions.WindowGo      (runOrRaise)
import qualified XMonad.Actions.GroupNavigation as GN

---- Hooks
import XMonad.Hooks.DynamicLog      (pad, wrap, shorten, dynamicLogString, xmobarColor, defaultPP, PP(..))
import XMonad.Hooks.EwmhDesktops    (ewmh, fullscreenEventHook)
import XMonad.Hooks.ManageDocks     (manageDocks, avoidStruts, docksEventHook, SetStruts(..), ToggleStruts(..))
import XMonad.Hooks.ManageHelpers   (composeOne, (-?>), transience, isFullscreen, doFullFloat, doCenterFloat, isDialog)
import XMonad.Hooks.InsertPosition  (insertPosition, Position(Master, Above, Below), Focus(Newer, Older))
import XMonad.Hooks.UrgencyHook     (withUrgencyHook, NoUrgencyHook(..), focusUrgent, clearUrgents)

---- Layouts
import qualified XMonad.StackSet as W
-- basis
import XMonad.Layout.Tabbed         (simpleTabbed)
import XMonad.Layout.Grid           (Grid(..))
import XMonad.Layout.Circle         (Circle(..))
import XMonad.Layout.SimplestFloat  (simplestFloat)
import XMonad.Layout.IM             (withIM, Property(ClassName, Title, And))
-- modifiers
import XMonad.Layout.Reflect        (REFLECTX(REFLECTX))
import XMonad.Layout.ResizableTile  (ResizableTall(ResizableTall), MirrorResize(MirrorShrink, MirrorExpand))
import XMonad.Layout.PerWorkspace   (onWorkspace)
import XMonad.Layout.MultiToggle    (mkToggle, Toggle(..), single, (??), EOT(..))
import XMonad.Layout.MultiToggle.Instances(StdTransformers(FULL, MIRROR, NOBORDERS))
-- decorators
import XMonad.Layout.LayoutHints    (layoutHintsToCenter, hintsEventHook)  -- honor size hints
import XMonad.Layout.NoBorders      (smartBorders)  -- no borders on fullscreen
import XMonad.Layout.Spacing        (smartSpacing)
-- extension
import XMonad.Util.NamedScratchpad  (namedScratchpadAction, namedScratchpadManageHook, NamedScratchpad(..), nonFloating, defaultFloating, customFloating)


import XMonad.Config.Amer.EventHook  (myHandleEventHook)
import XMonad.Config.Amer.Prompt     (myPromptTheme)
import XMonad.Config.Amer.Scratchpad (myScratchpads)

myKeys cfg = mkKeymap cfg $
  ---- focus
  [ ("M-h"        , windows W.focusMaster)
  , ("M-j"        , windows W.focusDown)
  , ("M-k"        , windows W.focusUp)
  , ("M-l"        , GN.nextMatchWithThis GN.History wkspName)
  , ("M-'"        , GN.nextMatchWithThis GN.Backward className)
  , ("M-z"        , focusUrgent)
  , ("M-C-z"      , clearUrgents)
  ---- swap
  , ("M-S-h"      , windows W.swapMaster)
  , ("M-S-l"      , windows W.shiftMaster)
  , ("M-S-j"      , windows W.swapDown)
  , ("M-S-k"      , windows W.swapUp)
  ---- edit
  , ("M-,"        , sendMessage Shrink)
  , ("M-."        , sendMessage Expand)
  , ("M-S-,"      , sendMessage MirrorShrink)
  , ("M-S-."      , sendMessage MirrorExpand)
  , ("M-<Left>"   , withFocused $ keysMoveWindow (-10,0))
  , ("M-<Right>"  , withFocused $ keysMoveWindow ( 10,0))
  , ("M-<Up>"     , withFocused $ keysMoveWindow (0,-10))
  , ("M-<Down>"   , withFocused $ keysMoveWindow (0, 10))
  , ("M-C-<Left>" , withFocused $ keysMoveWindowTo ( 10, 10) (0,0))
  , ("M-C-<Right>", withFocused $ keysMoveWindowTo (800,410) (0,0))
  , ("M-C-<Up>"   , withFocused $ keysMoveWindowTo (800, 10) (0,0))
  , ("M-C-<Down>" , withFocused $ keysMoveWindowTo ( 10,410) (0,0))
  -- BUG: cant grow width/height -- problems with sizeHints?
  , ("M-S-<Left>" , withFocused $ keysResizeWindow (-10,0) (1%2,1%2))
  , ("M-S-<Rigth>", withFocused $ keysResizeWindow (10,0) (1%2,1%2))
  , ("M-S-<Up>"   , withFocused $ keysResizeWindow (0,-10) (1%2,1%2))
  , ("M-S-<Down>" , withFocused $ keysResizeWindow (0,10) (1%2,1%2))
  -- , ("M-<Up>"     , withFocused $ keysAbsResizeWindow (-10,-10) (1024,752))
  -- , ("M-<Down>"   , withFocused $ keysAbsResizeWindow (10,10) (1024,752))
  -- , ("M-<>" , withFocused (keysMoveWindowTo (512,384) (1%2,1%2)))
  , ("M-;"        , sendMessage . IncMasterN $  1)
  , ("M-S-;"      , sendMessage . IncMasterN $ -1)
  ---- float
  -- THINK: jumps between last two float windows -- do combo M-w, M-l better then i3 model
  , ("M-w"        , GN.nextMatch GN.History isFloat)
  , ("M-C-w"      , withFocused $ windows . W.sink)
  , ("M-S-w"      , withFocused float)
  -- Layouts
  , ("M-n"        , sendMessage NextLayout)
  , ("M-S-n"      , sendMessage FirstLayout)  -- ALT: setLayout $ XMonad.layoutHook cfg
  , ("M-f"        , sendMessage (Toggle FULL) >> sendMessage ToggleStruts)
  , ("M-/"        , sendMessage $ Toggle MIRROR)
  , ("M-S-/"      , sendMessage $ Toggle REFLECTX)
  ] ++
  -- Cycle through workspaces
  let focusNextE  = moveTo  Next EmptyWS
      shiftNextE  = shiftTo Next EmptyWS
      bringNextE  = doTo    Next EmptyWS getSortByIndex (\w -> windows (W.shift w) >> windows (W.view w))
      -- focusNextNE = moveTo  Next NonEmptyWS
      -- focusPrevNE = moveTo  Prev NonEmptyWS
      -- shiftNextNE = shiftTo Next NonEmptyWS
      -- shiftPrevNE = shiftTo Prev NonEmptyWS
  in [ ("M-a"        , toggleWS' ["NSP"])
     --FIXME: , ("M-S-a"      , shiftToPrev >> toggleWS)
     --SEE: http://xmonad.org/xmonad-docs/xmonad-contrib/src/XMonad-Actions-CycleWS.html
     , ("M-S-a" , windows (W.shift "0") >> windows (W.view "0"))
     , ("M-<Backspace>"   , focusNextE)
     , ("M-C-<Backspace>" , shiftNextE)
     -- BUG: we focus one after that!
     , ("M-S-<Backspace>" , bringNextE)
     -- , ("M-<Tab>"    , focusNextNE)
     -- , ("M-S-<Tab>"  , focusPrevNE)
     -- , ("M-C-<Tab>"  , shiftNextNE >> focusNextNE)
     -- , ("M-C-S-<Tab>", shiftPrevNE >> focusPrevNE)
     ]
  ++
  ---- Workspaces
  [ (m ++ k, windows $ f nm) | (k, nm) <- myWorkspaces, (m, f) <-
    [ ("M-"  , W.view)
    , ("M-C-", W.shift)
    , ("M-S-", \w -> W.view w . W.shift w)
    , ("M-C-S-", copy)
    ]
  ] ++
  ---- Mark & Goto
  -- NEED:DEV: back_and_forth -- to return window on their previous screen
  -- -- if on currentFocused -- shiftHere was pressed again
  [ (m ++ "<F" ++ show n ++ ">", f n) | n <- [1..12], (m, f) <-
    [ ("M-"  , \n -> focusUpTaggedGlobal ("F" ++ show n))
    , ("M-C-", \n -> withFocused $ setTags ["F" ++ show n])
    , ("M-S-", \n -> withTaggedGlobalP ("F" ++ show n) shiftHere)
    ]
  ] ++
  ---- System
  [ ("M-\\"  , kill1)
  , ("M-C-\\", killAllOtherCopies)
  , ("M-S-q" , kill)
  ] ++
  --ATTENTION: "M-<Esc>" must be unused -- I use <Esc> to drop xkb latching
  inGroup "M-S-<Esc>"  -- xmonad
    [ ("o", io exitSuccess)
    , ("n", refresh)  -- workspace normalizing (resize)
    , ("r", spawn "sudo reboot")
    , ("t", spawn "sudo poweroff")
    , ("f", refresh)  -- Correct size of the viewed windows
    , ("x", restart "xmonad" True)
    , ("c", spawn "r.n xmonad recompile" >>
            spawn "xmonad --recompile && xmonad --restart && r.n OK")
    ] ++
  ---- Shortcuts
  -- main tools
  -- ALT:FIXME spawn "r.t" >> windows W.swapMaster
  -- BUG? M-C-<Space> don't work -- seems like it's hardware problem
  concat [
    [ ("M-"     ++ k , spawnHere t)
    , ("M-S-"   ++ k , spawnAndDo (insertPosition Master Newer) t)
    , ("M-C-"   ++ k , spawnAndDo doFloat t)
    , ("M-S-C-" ++ k , spawnAndDo doCenterFloat t)
    ]
    | (k, t) <-
    [ ("<Space>", "r.t -e r.tmux")  -- OR "r.tf"
    , ("M1-<Space>", "~/.i3/ctl/run-cwd")
    , ("<Return>", "r.t -e r.ranger")  -- OR -e zsh -ic
    ]
  ] ++
  ---- Interactions
  inGroup "M-u"
    [ ("t", inputPrompt def "Fire" ?+ \p -> spawn ("r.tf -e " ++ p))
    , ("s", shellPrompt myPromptTheme)
    ] ++
  ---- Scratchpads
  (inGroup "M-o" . concat) [
    [ ("M-o", windows $ W.view "NSP")
    , ("M-S-o", windows $ W.shift "NSP")
    ],
    -- Open new or focus the already existing one
    [ ([head nm], namedScratchpadAction myScratchpads nm)
    | nm <- ["ncmpcpp", "mutt", "ipython", "htop", "pidgin", "skype", "lyrics"]
    ],
    -- Open new window always
    [ ("S-" ++ [head nm], spawnHere $ "r.tf -e " ++ nm)
    | nm <- ["ncmpcpp", "mutt", "ipython"]
    ],
    [ ("f" , runOrRaise "firefox" $ className =? "Firefox")
    , ("b" , spawnHere "r.b")
    , ("v" , spawnHere "r.tf -e $EDITOR")
    , ("S-<Space>", spawnHere "r.t")
    , ("<Space>"  , spawnHere "r.tf")
    , ("<Return>" , spawnHere "r.tf -e ranger")
    -- , ("k", "~/.i3/ctl/run-focus k")
    -- r.tf -e gksudo powertop
    -- r.tf -e gksudo tlp start
    -- nemo --no-desktop
    -- /usr/lib/cinnamon-settings/cinnamon-settings.py sound
    ]
  ] ++
  (spawnAll . concat) [
    [ ("M-d"       , "r.dmenu")
    , ("M-S-d"     , "r.dmenu -n")
    , ("M-C-d"     , "j4-dmenu-desktop")
    , ("M-<Print>" , "~/.i3/ext/screenshot")
    , ("M-C-S-\\"  , "~/.i3/ctl/wnd_active_kill")
    , ("M-S-z"     , "~/.i3/ext/i3exit lock")
    ],
    feedCmd "~/.i3/ext/volume"
    [ ("M-<Home>"     , "20%")
    , ("M-<Page_Up>"  , "2%+")
    , ("M-<Page_Down>", "2%-")
    , ("M-<End>"      , "")
    , ("<XF86AudioRaiseVolume>", "2%+")
    , ("<XF86AudioLowerVolume>", "2%-")
    , ("<XF86AudioMute>"       , "")
    ],
    feedCmd "mpc"
    [ ("M-S-<Home>"      , "toggle")
    , ("M-S-<Page_Up>"   , "prev")
    , ("M-S-<Page_Down>" , "next")
    , ("M-S-<End>"       , "seek +5 >/dev/null")
    , ("<XF86AudioPlay>" , "toggle")
    , ("<XF86AudioNext>" , "next")
    , ("<XF86AudioPrev>" , "prev")
    , ("<XF86AudioStop>" , "stop")
    , ("<XF86AudioPause>", "pause")
    ],
    -- NEED: spawnHere
    -- misc
    [ ("<XF86Tools>"     , "r.tf ncmpcpp")
    , ("<XF86Mail>"      , "r.tf -e mutt")
    , ("<XF86Search>"    , "r.b -p")
    , ("<XF86Calculator>", "r.tf -e ipython")
    , ("<XF86Sleep>"     , "xset -d :0 dpms force off")
    ],
    ---- Submenus
    inGroup "M-S-<Esc>" $ feedCmd "xbacklight -set"
    [ (i, i ++ "0") | i <- map show [0..9]
    ],
    inGroup "M-u"
    [ ("b", "r.b -h")
    , ("g", "r.b -g")
    , ("e", "r.dict --en --vim")
    , ("r", "r.dict --ru --vim")
    , ("m", "~/.mpd/move_current")
    ],
    inGroup "M-y"
    [ ("b", "r.b -p")
    ],
    (feedCmd "copyq" . concat) [
      [ ("M-x", "toggle")
      , ("M-S-x", "edit -1")
      ],
      inGroup "M-C-x"
      [ ("a", "edit")  -- add new entry
      , ("t", "eval 'copy(clipboard());paste()'") -- as plain text
      , ("M-x", "toggle")
      , ("x",   "toggle")
      , ("m", "menu")
      , ("n", "next")
      , ("p", "previous")
      , ("<Return>", "enable")
      , ("<Backspace>", "disable")
      ]
    ],
    inGroup "M-z" $ feedCmd "r.copyq"
    [ (m ++ i, k ++ i) | i <- map show [0..9], (m, k) <-
      [("", ""), ("S-", "+"), ("C-", "-")]
    ]
    ---- wacom M-<Insert>
    -- o ~/aura/airy/cfg/wacom/ctl/change-output ,$def
    -- $mod+m ~/aura/airy/cfg/wacom/ctl/change-mode -q && $upd wnd ,$def
    -- $mod+s ~/aura/airy/cfg/wacom/ctl/change-curve  ,$def
  ]
  where
    inGroup prf = map $ \(k, f) -> (prf ++ " " ++ k, f)
    feedCmd cmd  = map $ \(k, o) -> (k, cmd ++ " " ++ o)
    spawnAll    = map $ \(k, s) -> (k, spawn s)  -- TODO:USE: spawnHere
    --DEV:(copyq) keySeqFor cmd prf = map (prf ++ " " ++)
    hidTags w = map W.tag $ W.hidden w ++ [W.workspace . W.current $ w]
    visTags w = map (W.tag . W.workspace) $ W.visible w ++ [W.current w]
    -- | Get params from current window
    -- TRY? we could use simply W.tag on w? See src of toggleWS'
    wkspName = ask >>= (\w -> liftX $ withWindowSet $ \ws -> return $ fromMaybe "" $ W.findTag w ws) :: Query String
    isFloat  = ask >>= (\w -> liftX $ withWindowSet $ \ws -> return $ M.member w $ W.floating ws) :: Query Bool


myWorkspaces = concat
  [ map (\k -> (k, k)) mainRow
  , map (\k -> (leader [k], [k])) ['a' .. 'z']
  , zipWith (\k nm -> (leader k, nm)) mainRow (words "~ ! @ # $ % ^ & * ( ) _ +")
  ]
  where
    mainRow = words "` 1 2 3 4 5 6 7 8 9 0 - ="
    leader = ("g " ++)  -- ALT: s, <Backspace>, <Tab>


myStartupHook = do
  curr <- gets (W.currentTag . windowset)
  -- FIXME: dirty fix to not jump to 1st wksp on each restart beside startup
  when (curr == head wsl) (windows . W.view $ wsl !! 1)
  where
    wsl = workspaces myCfg
-- EXPL: to be able to use 'wmctrl' to get current wksp from scripts
-- import XMonad.Hooks.SetWMName
-- import XMonad.Hooks.EwmhDesktops
-- import XMonad.Util.Cursor
-- startupHook = setDefaultCursor xC_left_ptr <+>  ewmhDesktopsStartup >> setWMName "Xmonad"


myCfg = ewmh $ withUrgencyHook NoUrgencyHook $ def
  { modMask = mod4Mask
  -- Options
  , terminal    = "r.t"
  , workspaces  = [ nm | (k, nm) <- myWorkspaces]
  , keys        = myKeys
  -- Hooks
  -- , startupHook = broadcastMessage $ SetStruts [] [minBound..maxBound]
  -- , startupHook = windows . W.view . (!!1) . workspaces $ myCfg
  , startupHook = myStartupHook
  , manageHook  = myManageHook <+> manageHook def
  -- layoutHook def
  -- layoutHintsToCenter
  , layoutHook = avoidStruts . smartBorders $ myLayout
  , handleEventHook = myHandleEventHook
  -- Style
  , borderWidth        = 2
  , normalBorderColor  = "#000000"
  , focusedBorderColor = "#c050f0"
  }


myLayout = smartBorders
    -- . smartSpacing 3  -- I'm not sure yet if it nice or not
    -- . onWorkspace (workspaces myCfg !! 4) Full
    . onWorkspace (head $ workspaces myCfg) imLayer
    . mkToggle (NOBORDERS ?? FULL ?? EOT)
    . mkToggle (single MIRROR)
    . mkToggle (single REFLECTX)
    $ tiled ||| simpleTabbed ||| simplestFloat ||| Grid ||| Circle
  where
    imLayer = withIM (1%7) (Title "Buddy List") Grid
    tiled   = ResizableTall nmaster delta ratio []
    nmaster = 1     -- number of windows in master pane
    ratio   = toRational (1.9 / (1 + sqrt 5.0)) -- phi
    delta   = 2/100 -- step of increasing


-- RFC: mconcat . concat $ [ [
myManageHook :: ManageHook
myManageHook = manageSpawn <+>
  mconcat
  [ isFullscreen --> topmost doFullFloat
  , isDialog --> topmost doCenterFloat
  ] <+>
  composeFloat
  [ ("Figure" `isPrefixOf`) <$> title
  , ("Float" `isPrefixOf`) <$> appName
  , let lst = "buddy_list Preferences"
    in wmhas (stringProperty "WM_WINDOW_ROLE") lst
  , let lst = "copyq feh Steam Gimp Pidgin Skype piony.py Transmission-gtk"
    in wmhas className lst
  , let lst = "PlayOnLinux"
    in wmhas appName lst
  , className =? "Firefox" <&&> appName =? "Download"
  ] <+>
  -- for_window [title="^ElonaPlus"] fullscreen
  mconcat
  [ wmhas className "stalonetray" --> doIgnore
  , wmhas appName "panel desktop_window kdesktop trayer" --> doIgnore
  ]
  <+> insertPosition Below Newer <+>
  composeShift
  [ ("4", "Firefox")
  , ("5", "Krita")
  , ("8", "t-engine64")
  , ("9", "Steam")
  ]
  <+> namedScratchpadManageHook myScratchpads
  <+> manageDocks
  where
    wmhas t l = foldr1 (<||>) [ t =? x | x <- words l ]
    topmost =  (<+> insertPosition Master Newer)
    composeFloat = mconcat . map (--> topmost doFloat)
    -- ALT: doF (W.shift "doc")
    composeShift = mconcat . map (\(w, x) -> (className =? x --> doShift w))


-- SEE how to combine CopyWindow and DynamicLog in more modular way
--  https://bbs.archlinux.org/viewtopic.php?id=194863
myLogHook h = do
  GN.historyHook

  copies <- wsContainingCopies
  let check ws | ws `elem` copies = xmobarColor "#8888ff" "green" ws
               | otherwise = ws  -- pad ws
      predefined ws | ws `elem` workspaces myCfg = ws
                    | otherwise = ""

  -- xmobar pretty printing source
  io . hPutStrLn h =<< dynamicLogString defaultPP
    { ppCurrent = xmobarColor "#fd971f" ""
    -- , ppVisible = wrap "(" ")"
    , ppHidden  = check . predefined
    -- , ppHiddenNoWindows = const ""
    , ppUrgent  = xmobarColor "red" "yellow"
    -- , ppTitle   = xmobarColor "green"  "" . shorten 40
    -- , ppWsSep   = " "
    , ppSep     = xmobarColor "#fd971f" "" " \xe0b1 "           -- separator between elements
    , ppOrder   = \(ws:l:_) -> [l, ws]                          -- elems order (title ignored)
    -- , ppSort    = getSortByIndex
    -- , ppExtras  = []
    , ppLayout  = \nm -> case nm of
        "ResizableTall" -> "[|]"
        "Mirror ResizableTall" -> "[-]"
        "Tabbed Simplest" -> "=--"
        "Full" -> "[ ]"
        "Grid" -> "[#]"
        "IM Grid" -> "|##"
        "SimplestFloat" -> "( )"
        "Circle" -> "(O)"
        _ -> nm
    }

main :: IO ()
main = do
  h <- spawnPipe "xmobar ~/.xmonad/xmobarrc"
  xmonad myCfg { logHook = myLogHook h }
