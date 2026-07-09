--SRC: https://github.com/kevinhwang91/nvim-hlslens
--USAGE:
-- Hlslens also supports <C-g> and <C-t> to move to the next and previous match.
-- Start hlslens
--   Press / or ? to search text, /s and /e offsets are supported;
--   Invoke API require('hlslens').start();
-- Stop hlslens
--   Run ex command nohlsearch;
--   Map key to :nohlsearch;
--   Invoke API require('hlslens').stop();

local kopts = {noremap = true, silent = true}
vim.api.nvim_set_keymap('n', 'n',
    [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]],
    kopts)
vim.api.nvim_set_keymap('n', 'N',
    [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]],
    kopts)
vim.api.nvim_set_keymap('n', '*', [[*<Cmd>lua require('hlslens').start()<CR>]], kopts)
vim.api.nvim_set_keymap('n', '#', [[#<Cmd>lua require('hlslens').start()<CR>]], kopts)
vim.api.nvim_set_keymap('n', 'g*', [[g*<Cmd>lua require('hlslens').start()<CR>]], kopts)
vim.api.nvim_set_keymap('n', 'g#', [[g#<Cmd>lua require('hlslens').start()<CR>]], kopts)
-- vim.api.nvim_set_keymap('n', '<Leader>l', '<Cmd>noh<CR>', kopts)


-- run `:nohlsearch` and export results to quickfix
-- if Neovim is 0.8.0 before, remap yourself.
-- OR: <Leader>L
vim.keymap.set({'n', 'x'}, '<C-l>', function()
    vim.schedule(function()
        if require('hlslens').exportLastSearchToQuickfix() then
            vim.cmd('cw')
        end
    end)
    return ':noh<CR>'
end, {expr = true})


-- hi default link HlSearchNear CurSearch
-- hi default link HlSearchLens WildMenu
-- hi default link HlSearchLensNear CurSearch
-- vim.api.nvim_set_hl(0, 'HlSearchNear', { link = 'SpecialKey' })
vim.api.nvim_set_hl(0, 'HlSearchLens', { link = 'SpecialKey' })
vim.api.nvim_set_hl(0, 'HlSearchLensNear', { link = 'IncSearch' })

require('hlslens').setup {
    calm_down = true,
    -- nearest_only = true,
    -- nearest_float_when = 'always',

    override_lens = function(render, posList, nearest, idx, relIdx)
        local sfw = vim.v.searchforward == 1
        local indicator, text, chunks
        local absRelIdx = math.abs(relIdx)
        if absRelIdx > 1 then
            indicator = ('%d%s'):format(absRelIdx, sfw ~= (relIdx > 1) and '▲' or '▼')
        elseif absRelIdx == 1 then
            indicator = sfw ~= (relIdx == 1) and '▲' or '▼'
        else
            indicator = ''
        end

        local lnum, col = unpack(posList[idx])
        if nearest then
            local cnt = #posList
            if indicator ~= '' then
                text = ('[%s %d/%d]'):format(indicator, idx, cnt)
            else
                text = ('[%d/%d]'):format(idx, cnt)
            end
            chunks = {{' '}, {text, 'HlSearchLensNear'}}
        else
            text = ('[%s %d]'):format(indicator, idx)
            chunks = {{' '}, {text, 'HlSearchLens'}}
        end
        render.setVirt(0, lnum - 1, col - 1, chunks, nearest)
    end
}
