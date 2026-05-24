return {
  "nvim-treesitter/nvim-treesitter",
  branch = "master",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter.configs").setup({
      modules = {},
      sync_install = false,
      ignore_install = {},
      ensure_installed = {
        "c",
        "css",
        "go",
        "html",
        "javascript",
        "lua",
        -- temporarily disabled because of Neovim 0.12.x crash:
        -- "markdown",
        -- "markdown_inline",
        "php",
        "python",
        "query",
        "rust",
        "typescript",
        "vim",
        "vimdoc",
      },
      auto_install = false,

      indent = {
        enable = true,
        disable = { "markdown", "markdown_inline" },
      },

      highlight = {
        enable = true,
        disable = function(lang, buf)
          -- Neovim 0.12.x + nvim-treesitter master Markdown crash workaround
          if lang == "markdown" or lang == "markdown_inline" then
            return true
          end

          local max_filesize = 100 * 1024 -- 100 KB
          local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
          if ok and stats and stats.size > max_filesize then
            return true
          end

          return false
        end,
        additional_vim_regex_highlighting = false,
      },
    })

    -- Extra safety: stop core Treesitter if Markdown still starts automatically
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "markdown", "markdown_inline" },
      callback = function(args)
        pcall(vim.treesitter.stop, args.buf)
      end,
    })
  end,
}
