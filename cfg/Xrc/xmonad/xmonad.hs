-- vim: ts=2:sw=2:sts=2
module Main (main) where

---- Std
import Control.Arrow (second)
import Control.Monad (when, liftM2)
import Data.List     (zipWith, isPrefixOf)
import Data.Maybe    (isNothing, isJust, fromMaybe)
import Data.Ratio    ((%))
import Data.Default  (def)
import Data.Char     (ord)
import Numeric       (showHex)
import qualified Data.Map.Strict as M
import System.IO
import System.Exit

---- Core
import XMonad                       -- (float, kill, spawn, refresh, restart, doFloat, workspaces, windows, withFocused, sendMessage, Resize(Shrink, Expand), IncMasterN)
import XMonad.Util.Run              (spawnPipe)
import XMonad.Util.EZConfig         (mkKeymap, checkKeymap)
import XMonad.ManageHook            (liftX, className)

---- Interaction
import XMonad.Prompt.Shell          (shellPrompt)
import XMonad.Prompt.Input          (inputPrompt, inputPromptWithCompl, (?+))

---- Actions
import XMonad.Actions.TagWindows    (setTags, focusUpTaggedGlobal, withTaggedGlobalP, shiftHere)
import XMonad.Actions.CopyWindow    (copy, copyWindow, runOrCopy, killAllOtherCopies, kill1, wsContainingCopies)
import XMonad.Actions.FloatKeys     (keysMoveWindow, keysMoveWindowTo, keysResizeWindow, keysAbsResizeWindow)
import XMonad.Actions.SpawnOn       (manageSpawn, spawnHere, spawnAndDo)
import XMonad.Actions.WindowGo      (runOrRaise)
import qualified XMonad.Actions.GroupNavigation as GN

---- Hooks
import XMonad.Hooks.SetWMName       (setWMName)
import XMonad.Hooks.EwmhDesktops    (ewmh, ewmhDesktopsStartup)
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
-- DEV:
import qualified XMonad.Layout.Monitor as MON
import XMonad.Layout.LayoutModifier (ModifiedLayout(..))  -- For Layout.Monitor
import XMonad.Layout.LayoutScreens  (layoutScreens)
import XMonad.Layout.TwoPane        (TwoPane(..))
-- import XMonad.Layout.IndependentScreens (withScreens)
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
import XMonad.Config.Amer.LogHook    (myLogHook)
import XMonad.Config.Amer.Prompt     (myPromptTheme)
import XMonad.Config.Amer.Scratchpad (myScratchpads)
import qualified XMonad.Config.Amer.Workspace as MyWksp
import qualified XMonad.Config.Amer.Navigation as MyNavi

myKeys = MyWksp.keys ++ MyNavi.keys ++
  ---- focus
  [ ("M-h"      , windows W.focusMaster)
  , ("M-j"      , windows W.focusDown)
  , ("M-k"      , windows W.focusUp)
  , ("M-l"      , GN.nextMatchWithThis GN.History wkspName)
  , ("M-;"      , GN.nextMatchWithThis GN.Forward className)
  , ("M-S-;"    , GN.nextMatchWithThis GN.Backward className)
  , ("M-z"      , focusUrgent)
  , ("M-C-z"    , clearUrgents)
  ---- swap
  , ("M-S-h"    , windows W.shiftMaster)
  , ("M-S-l"    , GN.nextMatchWithThis GN.History wkspName >> windows W.swapMaster)
  , ("M-S-j"    , windows W.swapDown)
  , ("M-S-k"    , windows W.swapUp)
  ---- edit
  , ("M-,"      , sendMessage Shrink)
  , ("M-."      , sendMessage Expand)
  , ("M-S-,"    , sendMessage MirrorShrink)
  , ("M-S-."    , sendMessage MirrorExpand)
  , ("M-<L>"    , withFocused $ keysMoveWindow (-10,0))
  , ("M-<R>"    , withFocused $ keysMoveWindow ( 10,0))
  , ("M-<U>"    , withFocused $ keysMoveWindow (0,-10))
  , ("M-<D>"    , withFocused $ keysMoveWindow (0, 10))
  , ("M-C-<L>"  , withFocused $ keysMoveWindowTo ( 10, 10) (0,0))
  , ("M-C-<R>"  , withFocused $ keysMoveWindowTo (800,410) (0,0))
  , ("M-C-<U>"  , withFocused $ keysMoveWindowTo (800, 10) (0,0))
  , ("M-C-<D>"  , withFocused $ keysMoveWindowTo ( 10,410) (0,0))
  , ("M-S-<L>"  , withFocused $ keysResizeWindow (-10,0) (1%2,1%2))
  , ("M-S-<R>"  , withFocused $ keysResizeWindow (10,0) (1%2,1%2))
  , ("M-S-<U>"  , withFocused $ keysResizeWindow (0,-10) (1%2,1%2))
  , ("M-S-<D>"  , withFocused $ keysResizeWindow (0,10) (1%2,1%2))
  -- , ("M-<U>"      , withFocused $ keysAbsResizeWindow (-10,-10) (1024,752))
  -- , ("M-<D>"      , withFocused $ keysAbsResizeWindow (10,10) (1024,752))
  -- , ("M-<?>"      , withFocused (keysMoveWindowTo (512,384) (1%2,1%2)))
  , ("M-'"      , sendMessage . IncMasterN $  1)
  , ("M-S-'"    , sendMessage . IncMasterN $ -1)
  ---- float
  -- THINK: jumps between last two float windows -- do combo M-w, M-l better then i3 model
  , ("M-w"      , GN.nextMatch GN.History isFloat)
  , ("M-C-w"    , withFocused $ windows . W.sink)
  , ("M-S-w"    , withFocused float)
  -- Layouts
  , ("M-n"      , sendMessage NextLayout)
  , ("M-S-n"    , sendMessage FirstLayout)  -- ALT: setLayout $ XMonad.layoutHook cfg
  , ("M-f"      , sendMessage (Toggle FULL) >> sendMessage ToggleStruts)
  , ("M-b"      , broadcastMessage MON.ToggleMonitor >> refresh)
  , ("M-S-p"    , layoutScreens 2 (TwoPane 0.15 0.85) >> windows (W.view "MON"))
  , ("M-p"      , rescreen)  -- TODO: toggle show/hide second screen
  , ("M-/"      , sendMessage $ Toggle MIRROR)
  , ("M-S-/"    , sendMessage $ Toggle REFLECTX)
  ] ++
  ---- Mark & Goto
  -- NEED:DEV: back_and_forth -- to return window on their previous screen
  -- -- if on currentFocused -- shiftHere was pressed again
  -- NOTE: F13..F24 -- remapped by xkb for xmonad exclusively
  -- -- original F1..12 are accessed in overlay
  -- THINK: is overlay convenient? I have vim/ranger/mutt which need F1..F12
  [ (m ++ "<F" ++ show n ++ ">", f n) | n <- [13..24], (m, f) <-
    [ ("M-", \n -> withFocused $ setTags ["F" ++ show n])
    , (""  , \n -> focusUpTaggedGlobal ("F" ++ show n))
    , ("C-", \n -> withTaggedGlobalP ("F" ++ show n) shiftHere)
    ]
  ] ++
  ---- System
  [ ("M-\\"    , kill1)
  , ("M-C-\\", killAllOtherCopies)
  , ("M-S-q"   , kill)
  ] ++
  --ATTENTION: "M-<Esc>" must be unused -- I use <Esc> to drop xkb latching
  inGroup "M-S-<Esc>"  -- xmonad
    [ ("o", whenWindowsClosed $ io exitSuccess)
    , ("r", whenWindowsClosed $ spawn "systemctl reboot")
    , ("t", whenWindowsClosed $ spawn "systemctl poweroff")
    , ("n", refresh)  -- Correct size of the viewed windows (workspace normalizing)
    , ("x", restart "xmonad" True)
    , ("j", spawn "r.n xmonad recompile && xmonad --recompile && xmonad --restart && r.n OK")
    ] ++
  ---- Shortcuts
  -- main tools
  -- TODO: insert into M-o / M-S-o menus to be able open on new wksp
  concat [
    [ ("M-"     ++ k , spawnHere t)
    , ("M-S-"   ++ k , spawnAndDo (insertPosition Master Newer) t)
    , ("M-C-"   ++ k , spawnAndDo doFloat t)  -- WARNING: if broken >> HW problem
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
  -- TODO:ADD: M-s <Space> (export sPrf -- secondary prefix) -- jump to nearest next/prev(S-<Space>) empty wksp instead of <Bksp>
  (concat . (`map` [
      inGroup "M-o",
      inGroup "M-S-o" . map (second (\f -> MyNavi.nextEmpty W.view >> f))
  ]) . flip ($) . concat) [
    [ ("M-o", windows $ W.view "NSP")
    , ("M-S-o", windows $ W.shift "NSP")
    , ("f" , runOrRaise "firefox" $ className =? "Firefox")
    ],
    -- Open new or focus the already existing one
    [ ([head nm], namedScratchpadAction myScratchpads nm)
    | nm <- ["ncmpcpp", "mutt", "ipython", "j8", "htop", "pidgin", "skype", "lyrics"]
    ],
    -- Open new window always
    [ ("S-" ++ [head nm], spawnHere $ "r.tf -e " ++ nm)
    | nm <- ["ncmpcpp", "mutt", "ipython"]
    ],
    [ ("b" , spawnHere "r.b")
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
  (map (second spawn) . concat) [  -- TODO:USE: spawnHere
    [ ("M-d"       , "r.dmenu")
    , ("M-S-d"     , "r.dmenu -n")
    , ("M-C-d"     , "j4-dmenu-desktop")
    , ("M-<Print>" , "r.capture-screen")
    , ("M-C-S-\\"  , "~/.i3/ctl/wnd_active_kill")
    , ("M-S-z"     , "r.lock")
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
    [ ("M-o ."           , "next")
    , ("M-o ,"           , "prev")
    , ("M-S-<Home>"      , "toggle")
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
    , ("m", "r.mpd-move")
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
      -- NOTE: paste() simply sends Shift-Insert -- therefore may be buggy in 'st'
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
    feedCmd cmd = map $ \(k, o) -> (k, cmd ++ " " ++ o)
    --DEV:(copyq) keySeqFor cmd prf = map (prf ++ " " ++)
    hidTags w = map W.tag $ W.hidden w ++ [W.workspace . W.current $ w]
    visTags w = map (W.tag . W.workspace) $ W.visible w ++ [W.current w]
    -- | Get params from current window
    -- TRY? we could use simply W.tag on w? See src of toggleWS'
    wkspName = ask >>= (\w -> liftX $ withWindowSet $ \ws -> return $ fromMaybe "" $ W.findTag w ws) :: Query String
    isFloat  = ask >>= (\w -> liftX $ withWindowSet $ \ws -> return $ M.member w $ W.floating ws) :: Query Bool
    whenWindowsClosed fX = withWindowSet $ \ws -> if null (W.allWindows ws)
        then fX else MyNavi.nextNonEmpty W.view >> spawn "r.n Non-empty" :: X()

myStartupHook = do
  ewmhDesktopsStartup  -- EXPL: to be able to use 'wmctrl'
  setWMName "LG3D"  -- Fixes problems with Java GUI programs
  -- FIXME: dirty fix to not jump to 1st wksp on each restart beside startup
  checkKeymap myCfg myKeys
  curr <- gets (W.currentTag . windowset)
  when (curr == head MyWksp.all) $
    windows . W.view $ MyWksp.primary !! 1


myCfg = withUrgencyHook NoUrgencyHook $ def
  { modMask = mod4Mask
  -- Options
  , terminal    = "r.t"
  , workspaces  = MyWksp.all
  -- , workspaces  = withScreens 2 MyWksp.all
  , keys        = (`mkKeymap` myKeys)
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


-- NOTE: you need to launch $ mpv --x11-name overlay -- /path/to/file to activate it
-- ALSO:CHECK: this window must be the unique one
-- BUG: can't focus/close it at all. Control only by mouse. BAD.
-- BETTER: sticking sliding workspace for column of windows on right
-- > NEED: toggleable sublayout, inherited for all windows
-- > BETTER: LayoutScreens
--    ? but how to toggle show/hide for second one?
--    ? maybe ability to have more then one column (like left+right ones) is even better?
--    * need ability to mirror screens to horizontal layout
--    * FIND: better navigation between screens (current one is too frustraiting)
--    * USE: one/several separate, named workspaces for that panel/screen
--    * TODO: show wksp for each screen in status as:  >1 2 > MON MPV  OR  >1 2 | MON MPV
--    ~ THINK: create spacing between those screens?
--    ~ IDEA: apply second screen as overlay with floating layout for main one
--      > to manage monitors separately from other windows
--      : then Layout.Monitor will be unnecessary
-- ~ MAYBE:ALT:(sublayout) DynamicWorkspaceGroups
--     http://mail.haskell.org/pipermail/xmonad/2015-July/014840.html
--     ADD workgroups -- to split my work_log/home_scripts screens
--     IDEA:(for this only) xmobar shows all wksp in current group and blue names for other groups
--       -- when focusing one of that groups -- its wksps replaces list in xmobar -- like fold/open tree structure
-- ALT:BETTER? http://xmonad.org/xmonad-docs/xmonad-contrib/XMonad-Layout-IndependentScreens.html
-- THINK: use named screens to skip screen panel when switching between actual monitors
--    http://hackage.haskell.org/package/xmonad-contrib-0.11.2/docs/XMonad-Actions-PhysicalScreens.html

myOverlay = MON.monitor
  { MON.prop = MON.ClassName "mpv" `MON.And` MON.Resource "overlay"
  , MON.rect = Rectangle (1920-320) 0 320 180  -- Lower right corner
  , MON.persistent = True  -- avoid flickering
  , MON.opacity = 1.0
  , MON.visible = True  -- show on start
  , MON.name = "mpv"  -- assign name to toggle independently
  }


myLayout = smartBorders
    . ModifiedLayout myOverlay
    -- . smartSpacing 3  -- I'm not sure yet if it nice or not
    -- . onWorkspace (workspaces myCfg !! 4) Full
    . onWorkspace (head MyWksp.primary) imLayer
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
  [ ("Float" `isPrefixOf`) <$> appName
  --XXX: ("Figure" `isPrefixOf`) <$> title
  --EXPL: pidgin is tiled by XMonad.Layout.IM
  -- , let lst = "buddy_list Preferences"
  --   in wmhas (stringProperty "WM_WINDOW_ROLE") lst
  , let lst = "copyq feh Steam Gimp piony.py Transmission-gtk"
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
  [ ("`", "Pidgin")
  , ("`", "Skype")
  , ("FF", "Firefox")
  -- , ("MM", "mutt") -- TODO: make whole wksp similar to firefox
  -- NOTE: strictly speaking, we don't need runOrRaise for mutt
  -- -- only stick it to MM wksp and keys to jump on it
  -- -- but with raise we get auto-launch and jumping even to moved for some reasons windows
  , ("5", "Krita")
  , ("8", "t-engine64")
  , ("9", "Steam")
  ]
  <+> MON.manageMonitor myOverlay
  <+> namedScratchpadManageHook myScratchpads
  <+> manageDocks
  where
    wmhas t l = foldr1 (<||>) [ t =? x | x <- words l ]
    topmost =  (<+> insertPosition Master Newer)
    composeFloat = mconcat . map (--> topmost doFloat)
    -- ALT: doF (W.shift "doc")
    composeShift = mconcat . map (\(w, x) -> (className =? x --> doShift w))


main :: IO ()
main = do
  h <- spawnPipe "xmobar ~/.xmonad/xmobarrc"
  xmonad $ ewmh myCfg { logHook = myLogHook h }
