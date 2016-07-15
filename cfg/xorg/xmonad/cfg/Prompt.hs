-- vim: ts=2:sw=2:sts=2
module XMonad.Config.Amer.Prompt (
    keys, myPromptTheme
) where

import Data.Default                 (def)
import XMonad                       (spawn)
import XMonad.Prompt
import XMonad.Prompt.Shell          (shellPrompt)
import XMonad.Prompt.Input          (inputPrompt, inputPromptWithCompl, (?+))
import XMonad.Actions.SpawnOn       (spawnHere)

import XMonad.Config.Amer.Common    (inGroup)

myPromptTheme = def
  { font = "-bitstream-bitstream vera sans-medium-r-*-*-14-*-*-*-*-*-*-*"
  , bgColor = "#ffffff"
  , fgColor = "#000000"
  , fgHLight = "#ff0000"
  , bgHLight = "#1b87cb"
  , borderColor = "#ffffff"
  , position = Top
  , defaultText = " "
  , autoComplete = Just 1
  }

keys = inGroup "M-i"
  [ ("t", inputPrompt def "Fire" ?+ \p -> spawnHere ("r.tf -e " ++ p))
  , ("s", shellPrompt myPromptTheme)
  ] ++
  [ ("M-C-z" , inputPrompt def "LockMsg" ?+ \p -> spawn ("r.lock " ++ p))
  ]
