-- vim: ts=2:sw=2:sts=2
module XMonad.Config.Amer.Prompt (
    keys, myPromptTheme
) where

import XMonad                       (spawn, windows)
import XMonad.Prompt
import XMonad.Prompt.Input          (inputPrompt, inputPromptWithCompl, (?+))
import XMonad.Prompt.Shell          (shellPrompt)
import XMonad.Prompt.Window         (windowPrompt, WindowPrompt(..), allWindows)
import XMonad.Prompt.Workspace      (workspacePrompt)
import XMonad.Prompt.XMonad         (xmonadPrompt)

import XMonad.Actions.SpawnOn       (spawnHere)
import XMonad.StackSet              (shift)

import XMonad.Config.Amer.Common    (inGroup, actions)

myPromptTheme = def
  -- { font = "-bitstream-bitstream vera sans-medium-r-*-*-14-*-*-*-*-*-*-*"
  { font = "xft:monospace-9.6,Symbola-9"
  , bgColor = "#ffffff"
  , fgColor = "#000000"
  , fgHLight = "#ff0000"
  , bgHLight = "#1b87cb"
  , borderColor = "#ffffff"
  , position = Top
  , defaultText = " "
  , autoComplete = Just 1
  }

pWksps = inGroup "M-i" [ (drop 2 m ++ "w", workspacePrompt def (windows . f)) | (m, f) <- actions]

keys = inGroup "M-i"
  [ ("t", inputPrompt def "Fire" ?+ \p -> spawnHere ("r.tf -e " ++ p))
  , ("s", shellPrompt myPromptTheme)
  , ("o", xmonadPrompt def)
  -- TODO: combine as set of "actions" with regular prefixes
  , ("f", windowPrompt def Goto allWindows)
  , ("d", windowPrompt def Bring allWindows)
  , ("c", windowPrompt def BringCopy allWindows)
  ] ++ pWksps ++
  [ ("M-C-z" , inputPrompt def "LockMsg" ?+ \p -> spawn ("r.lock " ++ p))
  ]
