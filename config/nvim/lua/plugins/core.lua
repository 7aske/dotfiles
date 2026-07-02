return {
  {
    "kylechui/nvim-surround",
    version = "^3.0.0",
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup({})
    end,
  },
  {
    "f-person/git-blame.nvim",
    event = "VeryLazy",
    opts = {
      enabled = true,
      message_template = "   <author> • <date> • <<sha>> • <summary>",
      date_format = "%r",
      message_when_not_committed = "",
      virtual_text_column = 1,
      delay = 0,
    },
  },
  {
    "folke/snacks.nvim",
    opts = {
      scroll = { enabled = false },
    },
  },
  {
    "norcalli/nvim-colorizer.lua",
    opts = {
      filetypes = { "css", "html", "yaml", "toml", "json", "jsonc" },
    },
  },
  { "godlygeek/tabular" },
  { "shaunsingh/nord.nvim" },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "nord",
    },
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "bash-language-server",
        "shellcheck",
        "actionlint",
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        bashls = {},
      },
    },
  },
  {
    "NMAC427/guess-indent.nvim",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      on_tab_options = {
        expandtab = false,
        tabstop = 4,
        shiftwidth = 4,
        softtabstop = 4,
      },
    },
  },
}
