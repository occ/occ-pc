{
  programs.nvchad = {
    extraPlugins = ''
      return {
        {
          "github/copilot.vim", version = "*",
        },
        {
          "nvim-telescope/telescope.nvim", version = "*", 
          dependencies = { 'nvim-lua/plenary.nvim' }
        },
        { 'echasnovski/mini.nvim', version = '*' },
        {
          "folke/which-key.nvim",
          event = "VeryLazy",
          opts = {
            -- your configuration comes here
            -- or leave it empty to use the default settings
            -- refer to the configuration section below
          },
          keys = {
            {
              "<leader>?",
              function()
                require("which-key").show({ global = true })
              end,
              desc = "Buffer Local Keymaps (which-key)",
            },
          },
        },
        {
          "rust-lang/rust.vim",
          ft = "rust",
          init = function()
            vim.g.rustfmt_autosave = 1
          end
        },
        {
          "saecki/crates.nvim",
          ft = {"rust", "toml"},
          config = function(_, opts)
            local crates = require('crates')
            crates.setup(opts)
            crates.show()
          end
        },
        {
          "smoka7/hop.nvim",
          version = "*",
          opts = {
              keys = 'etovxqpdygfblzhckisuran',
              multi_windows = true,
              uppercase_labels = false
          },
          keys = {
            { "<leader>fj", function () require("hop").hint_words() end },
            mode = { "n", "o", "x" },
          },
        },
      }
    '';
  };
}
