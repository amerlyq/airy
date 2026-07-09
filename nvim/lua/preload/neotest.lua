
--SRC: https://github.com/nvim-neotest/neotest
--SRC: https://github.com/nvim-neotest/neotest-python

--## USAGE
-- -- Run the nearest test
-- require("neotest").run.run()  -- <TRY
-- -- Run the current file
-- require("neotest").run.run(vim.fn.expand("%"))
-- -- Debug the nearest test (requires nvim-dap and adapter support)
-- require("neotest").run.run({strategy = "dap"})  -- <TRY
-- -- See :h neotest.run.run() for parameters.
-- -- Stop the nearest test, see :h neotest.run.stop()
-- require("neotest").run.stop()
-- -- Attach to the nearest test, see :h neotest.run.attach()
-- require("neotest").run.attach()  -- <TRY


require("neotest").setup({
  adapters = {
    require("neotest-python")({
        -- -- Extra arguments for nvim-dap configuration
        -- -- See https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings for values
        -- dap = { justMyCode = false },
        -- -- Command line arguments for runner
        -- -- Can also be a function to return dynamic values
        -- args = {"--log-level", "DEBUG"},
        -- -- Runner to use. Will use pytest if available by default.
        -- -- Can be a function to return dynamic value.
        -- runner = "pytest",
        -- -- Custom python path for the runner.
        -- -- Can be a string or a list of strings.
        -- -- Can also be a function to return dynamic value.
        -- -- If not provided, the path will be inferred by checking for
        -- -- virtual envs in the local directory and for Pipenev/Poetry configs
        -- python = ".venv/bin/python",
        -- -- Returns if a given file path is a test file.
        -- -- NB: This function is called a lot so don't perform any heavy tasks within it.
        -- is_test_file = function(file_path)
        --   ...
        -- end,
        -- -- !!EXPERIMENTAL!! Enable shelling out to `pytest` to discover test
        -- -- instances for files containing a parametrize mark (default: false)
        -- pytest_discover_instances = true,
    })
  }
})
