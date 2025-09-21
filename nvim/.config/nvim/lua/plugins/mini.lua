return {
  "nvim-mini/mini.nvim",
  version = "*",
  config = function()
    require("mini.pairs").setup()
    require("mini.icons").setup()
    require("mini.statusline").setup()
    require("mini.files").setup()
    vim.keymap.set("n", "-", "<cmd>lua MiniFiles.open()<CR>")
  end,
}
