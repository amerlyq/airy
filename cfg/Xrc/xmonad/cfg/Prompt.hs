-- vim: ts=2:sw=2:sts=2
module XMonad.Config.Amer.Prompt (myPromptTheme) where

import Data.Default                 (def)
import XMonad.Prompt

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
