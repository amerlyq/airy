-- vim: ts=2:sw=2:sts=2
module XMonad.Config.Amer.Common (
    bring, inGroup, feedCmd
) where

import qualified XMonad.StackSet as W

-- ALT (\w -> windows (W.shift w) >> windows (W.view w))
bring i = W.view i . W.shift i

modsGrp key = zip $ (++ key) ["M-", "M-S-", "M-C-", "M-C-S-"]
inGroup prf = map $ \(k, f) -> (prf ++ " " ++ k, f)
feedCmd cmd = map $ \(k, o) -> (k, cmd ++ " " ++ o)

hidTags w = map W.tag $ W.hidden w ++ [W.workspace . W.current $ w]
visTags w = map (W.tag . W.workspace) $ W.visible w ++ [W.current w]
