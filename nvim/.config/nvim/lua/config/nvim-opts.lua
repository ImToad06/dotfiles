-- Set leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Enable nerd font
vim.g.have_nerd_font = true

-- Use spaces instead of tab
vim.o.expandtab = true
vim.o.shiftwidth = 4

-- Line numbers
vim.o.number = true
vim.o.relativenumber = true

-- Enable mouse mode
vim.o.mouse = "a"

-- Don't show the mode
vim.o.showmode = false

-- Sync clipboard between OS and Neovim.
vim.schedule(function()
  vim.o.clipboard = "unnamedplus"
end)

-- Enable break indent
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.o.signcolumn = "yes"

-- Draw vertical column
vim.opt.colorcolumn = "80"

-- Decrease update time
vim.o.updatetime = 250

-- Decrease mapped sequence wait time
vim.o.timeoutlen = 300

-- Configure how new splits should be opened
vim.o.splitright = true
vim.o.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
vim.o.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Preview substitutions live, as you type!
vim.o.inccommand = "split"

-- Minimal number of screen lines to keep above and below the cursor.
vim.o.scrolloff = 10

-- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
-- instead raise a dialog asking if you wish to save the current file(s)
vim.o.confirm = true

-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Code runner
local function run_code_in_tmux()
  local filetype = vim.bo.filetype
  local file = vim.fn.expand("%:p")
  local cmd = nil

  -- Define commands based on filetype
  if filetype == "python" then
    cmd = "python3 " .. vim.fn.shellescape(file)
  elseif filetype == "javascript" then
    cmd = "node " .. vim.fn.shellescape(file)
  elseif filetype == "c" then
    local output = vim.fn.shellescape(vim.fn.fnamemodify(file, ":r"))
    cmd = "gcc " .. vim.fn.shellescape(file) .. " -o " .. output .. " && " .. output
  elseif filetype == "cpp" then
    local output = vim.fn.shellescape(vim.fn.fnamemodify(file, ":r"))
    cmd = "g++ " .. vim.fn.shellescape(file) .. " -o " .. output .. " && " .. output
  elseif filetype == "java" then
    local class = vim.fn.fnamemodify(file, ":t:r")
    cmd = "javac " .. vim.fn.shellescape(file) .. " && java " .. class
  elseif filetype == "sh" then
    cmd = "bash " .. vim.fn.shellescape(file)
  elseif filetype == "go" then
    cmd = "go run " .. vim.fn.shellescape(file)
  else
    vim.notify("No run command defined for filetype: " .. filetype, vim.log.levels.WARN)
    return
  end

  -- Append '; exec $SHELL' to keep the pane open with an interactive shell
  local full_cmd = cmd .. "; exec $SHELL"
  local tmux_cmd = "tmux split-window -v " .. vim.fn.shellescape(full_cmd)

  -- Execute the tmux command silently
  vim.cmd("silent !" .. tmux_cmd)
end

-- Map <leader>cc to run the function
vim.keymap.set("n", "<leader>cc", run_code_in_tmux, { noremap = true, silent = true, desc = "Run code in tmux split" })
