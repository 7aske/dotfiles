return {
  { "shaunsingh/nord.nvim" },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "nord",
    },
  },
  {
    "mfussenegger/nvim-jdtls",
    ft = "java",
    config = function()
      require("jdtls").start_or_attach({
        cmd = {
          "jdtls",
          "--jvm-arg=" .. string.format("-javaagent:%s", vim.fn.expand("$MASON/share/jdtls/lombok.jar")),
        },
        root_dir = require("jdtls.setup").find_root({ "gradle.build", "pom.xml" }),
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      autoformat = false,
    },
  },
}
