-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
    -- Packer can manage itself
    use 'wbthomason/packer.nvim'

    use {
        'nvim-telescope/telescope.nvim', tag = '0.1.6',
        requires = { 'nvim-lua/plenary.nvim' }
    }

    use {
        "rose-pine/neovim",
        as = "rose-pine",
        config = function()
            vim.cmd('colorscheme rose-pine')
        end
    }

    use { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' }
    use 'theprimeagen/harpoon'
    use 'mbbill/undotree'
    use 'tpope/vim-fugitive'
    use 'nvim-tree/nvim-web-devicons'

    use {
        'neovim/nvim-lspconfig',
        'williamboman/mason.nvim',
        'williamboman/mason-lspconfig.nvim',
    }

    use {
        'VonHeikemen/lsp-zero.nvim',
        requires = {
            'hrsh7th/nvim-cmp',
            'hrsh7th/cmp-buffer',
            'hrsh7th/cmp-path',
            'saadparwaiz1/cmp_luasnip',
            'hrsh7th/cmp-nvim-lsp',
            'L3MON4D3/LuaSnip',
            'rafamadriz/friendly-snippets'
        }
    }

    use {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        config = function()
            require("nvim-autopairs").setup {}
        end
    }

    use {
        "airblade/vim-gitgutter",
        config = function()
            vim.cmd('let g:gitgutter_enabled = 1')
        end
    }

    use {
        'akinsho/flutter-tools.nvim',
        requires = {
            'nvim-lua/plenary.nvim',
            'stevearc/dressing.nvim'
        },
        config = function()
            require("flutter-tools").setup {}
        end
    }

    use {
        "sindrets/diffview.nvim",
        config = function()
            require("diffview").setup {}
        end
    }

    use "keith/swift.vim"
end)

