-- vim: ts=2:sw=2:sts=2
{-# LANGUAGE FlexibleInstances, MultiParamTypeClasses, DeriveDataTypeable, TypeSynonymInstances #-}
module XMonad.Config.Amer.Layout (
    MyTransformers(..)
) where

import XMonad                       (Typeable, Window)
import XMonad.Layout                (Full(..))
import XMonad.Layout.NoBorders      (noBorders)
import XMonad.Layout.Spacing        (smartSpacing)

import XMonad.Hooks.ManageDocks     (avoidStruts)
import XMonad.Layout.LayoutModifier (ModifiedLayout(..))
import XMonad.Layout.MultiToggle    (Transformer(..))


data MyTransformers = STRUTS
                    | GAPS
  deriving (Read, Show, Eq, Typeable)

instance Transformer MyTransformers Window where -- (const x)
    transform STRUTS   x k = k (avoidStruts x)    (\(ModifiedLayout _ x') -> x')
    -- TODO: inherit value from global conf? How to extend myCfg in-place on the fly?
    transform GAPS     x k = k (smartSpacing 8 x) (\(ModifiedLayout _ x') -> x')
