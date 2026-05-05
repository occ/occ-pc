{
  programs.nvchad = {
    chadrcConfig = ''
      local M = {}

      M.base46 = {
        theme = "catppuccin",
        transparency = true,
      }

      return M
    '';

    extraConfig = ''
      local lspconfig = require "lspconfig"
      local nvlsp = require "nvchad.configs.lspconfig"
      local util = require "lspconfig/util"

      lspconfig.rust_analyzer.setup{
        on_attach = nvlsp.on_attach,
        on_init = nvlsp.on_init,
        capabilities = nvlsp.capabilities,
        filetypes = {"rust"},
        root_dir = util.root_pattern("Cargo.toml"),
        settings = {
          ['rust-analyzer'] = {
            diagnostics = {
              enable = true,
            },
            cargo = {
              allFeatures = true,
            },
          },
        },
      }

      vim.opt.numberwidth = 3
      vim.opt.relativenumber = true
      vim.opt.signcolumn = "yes:1"
      vim.opt.statuscolumn = "%l%s"
    '';
  };
}
