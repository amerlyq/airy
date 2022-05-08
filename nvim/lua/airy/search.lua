local o, g = vim.opt, vim.g

--PERF: search
o.grepprg = "rg --vimgrep --smart-case --sortr path --no-follow --hidden --glob '!.git'"
