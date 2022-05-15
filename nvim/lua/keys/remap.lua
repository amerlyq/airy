-- Move original keys to make space for my own more frequent actions
local K = require 'keys.bind'.K

-- Because 'ga' is used by me already
-- NICE: https://spin.atomicobject.com/2011/06/21/character-encoding-tricks-for-vim/
K('', 'g8', 'ga')
