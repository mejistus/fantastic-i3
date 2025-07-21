vim.g.python3_host_prog = vim.fn.expand("$HOME") .. "/.virtualenvs/neovim/bin/python3"

vim.g.base46_cache = vim.fn.stdpath "data" .. "/nvchad/base46/"
-- vim.g.mapleader = " "
--
os.execute("export SSL_CERT_DIR=/etc/ssl/certs")

-- bootstrap lazy and all plugins
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
    local repo = "https://github.com/folke/lazy.nvim.git"
    vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
end

vim.opt.rtp:prepend(lazypath)
local lazy_config = require "configs.lazy"
local lazy = require "lazy"
-- load plugins
lazy.setup({
    {
        "NvChad/NvChad",
        lazy = false,
        branch = "v2.5",
        import = "nvchad.plugins",
        config = function() require "options" end
    },
    {
        "vhyrro/luarocks.nvim",
        priority = 1001, -- 该插件需要在其他插件之前加载
        opts = {
            rocks = { "magick" },
        },
    },

    { import = "plugins" }
}, lazy_config)

local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
    opts = opts or {}
    opts.border = opts.border or "rounded"
    opts.max_width = opts.max_width or 80
    opts.max_height = opts.max_height or 20
    opts.winhighlight = opts.winhighlight or "NormalFloat:NormalFloat,FloatBorder:FloatBorder"
    return orig_util_open_floating_preview(contents, syntax, opts, ...)
end

dofile(vim.g.base46_cache .. "defaults")
-- Code Bold
------------------------------------------------
local bold_groups = {
    '@keyword', '@keyword.operator',
    '@conditional', '@repeat', '@exception', '@type.builtin',
    '@storageclass', '@structure', '@constructor',
    '@constant.builtin', '@variable.builtin', '@tag',

    '@keyword.def', '@keyword.class', '@keyword.import', '@keyword.import_from',
    '@keyword.require', '@keyword.from', '@keyword.as', '@keyword.as_from',
    '@keyword.return', '@keyword.function',


    '@function.call', '@function.method.call',

    '@field', '@property', '@attribute',
    '@variable.builtin',
}
local italic_groups = {
    '@variable.parameter','@comment','@string.documentation'
}
local function set_bold_only(group)
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
    if ok and hl then
        -- 取消 link
        vim.api.nvim_set_hl(0, group, {})
        -- 显式设置 bold + 继承原属性（fg/bg/italic 等）
        vim.api.nvim_set_hl(0, group, vim.tbl_extend("force", hl, { bold = true }))
    else
        vim.api.nvim_set_hl(0, group, { bold = true })
    end
end
local function set_italic_only(group)
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
    if ok and hl then
        -- 取消 link
        vim.api.nvim_set_hl(0, group, {})
        -- 显式设置 bold + 继承原属性（fg/bg/italic 等）
        vim.api.nvim_set_hl(0, group, vim.tbl_extend("force", hl, { italic = true }))
    else
        vim.api.nvim_set_hl(0, group, { italic = true })
    end
end


local function enhance_syntax_highlighting()
    for _, group in ipairs(bold_groups) do
        set_bold_only(group)
    end
    for _, group in ipairs(italic_groups) do
        set_italic_only(group)
    end
end

-- 主题更换时重新执行
vim.api.nvim_create_autocmd("ColorScheme", {
    pattern = "*",
    callback = function()
        vim.defer_fn(enhance_syntax_highlighting, 50)
    end,
})

-----------------------------------------------------------
dofile(vim.g.base46_cache .. "statusline")
-- 立即执行一次
require "nvchad.autocmds"

local cmp = require("cmp")

cmp.setup({

    completion = {
        autocomplete = { require('cmp.types').cmp.TriggerEvent.TextChanged },
        keyword_length = 1, -- 输入几个字符后才开始补全
        debounce = 750,     -- 触发补全的最小间隔，单位为毫秒
    },

    mapping = {
        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        -- ["<C-Space>"] = cmp.mapping.complete(),
        ["<CR>"] = cmp.mapping.confirm({ select = true }), -- 确认选择
        ["<Up>"] = cmp.mapping.select_prev_item(),         -- 上箭头选择上一个
        ["<Down>"] = cmp.mapping.select_next_item(),       -- 下箭头选择下一个
        ["<Tab>"] = nil,                                   -- 禁用 Tab 键导航（可选）
        ["<S-Tab>"] = nil,                                 -- 禁用 Shift-Tab 键导航（可选）
    },
})
vim.schedule(function() require "mappings" end)

vim.api.nvim_set_keymap('v', '<S-C>', '"+y', { noremap = true })
vim.api.nvim_set_keymap('n', '<sc-v>', 'l"+P', { noremap = true })
vim.api.nvim_set_keymap('v', '<sc-v>', '"+P', { noremap = true })
vim.api.nvim_set_keymap('c', '<sc-v>', '<C-o>l<C-o>"+<C-o>P<C-o>l', { noremap = true })
vim.api.nvim_set_keymap('i', '<sc-v>', '<ESC>l"+Pli', { noremap = true })
vim.api.nvim_set_keymap('t', '<sc-v>', '<C-\\><C-n>"+Pi', { noremap = true })

-- VimTeX
vim.g.tex_flavor = 'latex'
vim.g.vimtex_quickfix_mode = 0
vim.g.vimtex_compiler_method = 'latexmk'
vim.g.vimtex_toc_config = {
    name = 'TOC',
    layers = { 'content', 'todo', 'include' },
    split_width = 25,
    todo_sorted = 0,
    show_help = 1,
    show_numbers = 1
}
vim.opt.conceallevel = 1
vim.g.tex_conceal = 'abdmg'

-- Set custom arguments for TexCount
vim.g.vimtex_texcount_custom_arg = ' -ch -total'
-- Map <leader>lw to VimtexCountWords in normal mode
vim.api.nvim_create_autocmd("FileType", {
    pattern = "tex",
    callback = function()
        vim.api.nvim_buf_set_keymap(0, 'n', '<leader>lw', ':VimtexCountWords!<CR>', { noremap = true, silent = true })
    end
})

-- vim.g.Tex_ViewRule_pdf
-- Set LaTeX compiler engines
vim.g.vimtex_compiler_latexmk_engines = {
    ['_'] = '-xelatex',
    ['context (pdftex)'] = '-pdf -pdflatex=texexec',
    ['context (luatex)'] = '-pdf -pdflatex=context',
    ['context (xetex)'] = '-pdf -pdflatex=\'texexec --xtx\''
}

-- Set additional options for latexmk
vim.g.vimtex_compiler_latexmk = {
    build_dir = 'build',
    callback = 1,
    continuous = 1,
    executable = 'latexmk',
    hooks = {},
    options = {
        '-verbose', '-file-line-error', '-shell-escape', '-synctex=1', '-interaction=nonstopmode',
        -- '-aux-directory=build' -- 仅中间文件输出到 build 目录
    },
}

-- PDF viewer options including forward and inverse search
vim.g.vimtex_view_general_options =
'--synctex-forward @line:@col:@pdf --synctex-editor-command "nvim --headless -c \\"VimtexInverseSearch {input} {line}\\""'
vim.g.vimtex_view_method = 'skim'
-- vim.g.vimtex_view_general_viewer = 'zathura'
-- Ignore warnings during compilation
vim.g.vimtex_quickfix_open_on_warning = 0

-- dap
local dap, dapui = require("dap"), require("dapui")
dapui.setup()
dap.listeners.before.attach.dapui_config = function() dapui.open() end
dap.listeners.before.launch.dapui_config = function() dapui.open() end
dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
dap.listeners.before.event_exited.dapui_config = function() dapui.close() end

require("nvim-dap-virtual-text").setup {
    enabled = true,                     -- enable this plugin (the default)
    enabled_commands = false,           -- create commands DapVirtualTextEnable, DapVirtualTextDisable, DapVirtualTextToggle, (DapVirtualTextForceRefresh for refreshing when debug adapter did not notify its termination)
    highlight_changed_variables = true, -- highlight changed values with NvimDapVirtualTextChanged, else always NvimDapVirtualText
    highlight_new_as_changed = false,   -- highlight new variables in the same way as changed variables (if highlight_changed_variables)
    show_stop_reason = true,            -- show stop reason when stopped for exceptions
    commented = false,                  -- prefix virtual text with comment string
    only_first_definition = true,       -- only show virtual text at first definition (if there are multiple)
    all_references = true,              -- show virtual text on all all references of the variable (not only definitions)
    clear_on_continue = false,          -- clear virtual text on "continue" (might cause flickering when stepping)
    --- A callback that determines how a variable is displayed or whether it should be omitted
    --- @param variable Variable https://microsoft.github.io/debug-adapter-protocol/specification#Types_Variable
    --- @param buf number
    --- @param stackframe dap.StackFrame https://microsoft.github.io/debug-adapter-protocol/specification#Types_StackFrame
    --- @param node userdata tree-sitter node identified as variable definition of reference (see `:h tsnode`)
    --- @param options nvim_dap_virtual_text_options Current options for nvim-dap-virtual-text
    --- @return string|nil A text how the virtual text should be displayed or nil, if this variable shouldn't be displayed
    display_callback = function(variable, buf, stackframe, node, options)
        -- by default, strip out new line characters
        if options.virt_text_pos == 'inline' then
            return ' = ' .. variable.value:gsub("%s+", " ")
        else
            return variable.name .. ' = ' .. variable.value:gsub("%s+", " ")
        end
    end,
    -- position of virtual text, see `:h nvim_buf_set_extmark()`, default tries to inline the virtual text. Use 'eol' to set to end of line
    virt_text_pos = vim.fn.has 'nvim-0.10' == 1 and 'inline' or 'eol',

    -- experimental features:
    all_frames = false,     -- show virtual text for all stack frames not only current. Only works for debugpy on my machine.
    virt_lines = true,      -- show virtual lines instead of virtual text (will flicker!)
    virt_text_win_col = nil -- position the virtual text at a fixed window column (starting from the first text column) ,
    -- e.g. 80 to position at column 80, see `:h nvim_buf_set_extmark()`
}

dap.adapters.python = { type = 'executable', command = 'python', args = { '-m', 'debugpy.adapter' } }
dap.configurations.python = {
    {
        type = 'python',
        request = 'launch',
        name = "Launch file",
        program = "${file}",
        pythonPath = function() return os.getenv('HOME') .. '/.virtualenvs/neovim/bin/python' end
    }
}
local lldb = os.getenv('HOME') .. '/.local/share/nvim/mason/bin/codelldb'

dap.adapters.codelldb = function(on_adapter)
    -- This asks the system for a free port
    local tcp = vim.loop.new_tcp()
    tcp:bind('127.0.0.1', 0)
    local port = tcp:getsockname().port
    tcp:shutdown()
    tcp:close()

    -- Start codelldb with the port
    local stdout = vim.loop.new_pipe(false)
    local stderr = vim.loop.new_pipe(false)
    local opts = { stdio = { nil, stdout, stderr }, args = { '--port', tostring(port) } }
    local handle
    local pid_or_err
    handle, pid_or_err = vim.loop.spawn(lldb, opts, function(code)
        stdout:close()
        stderr:close()
        handle:close()
        if code ~= 0 then print("codelldb exited with code", code) end
    end)
    if not handle then
        vim.notify("Error running codelldb: " .. tostring(pid_or_err), vim.log.levels.ERROR)
        stdout:close()
        stderr:close()
        return
    end
    vim.notify('codelldb started. pid=' .. pid_or_err)
    stderr:read_start(function(err, chunk)
        assert(not err, err)
        if chunk then vim.schedule(function() require("dap.repl").append(chunk) end) end
    end)
    local adapter = { type = 'server', host = '127.0.0.1', port = port }
    -- 💀
    -- Wait for codelldb to get ready and start listening before telling nvim-dap to connect
    -- If you get connect errors, try to increase 500 to a higher value, or check the stderr (Open the REPL)
    vim.defer_fn(function() on_adapter(adapter) end, 500)
end

dap.configurations.cpp = {
    {
        name = "runit",
        type = "codelldb",
        request = "launch",
        program = function() return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file") end,
        args = { "--log_level=all" },
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
        terminal = 'integrated',

        pid = function()
            local handle = io.popen('pgrep hw$')
            local result = handle:read()
            handle:close()
            return result
        end
    }
}

dap.configurations.c = dap.configurations.cpp
dap.configurations.rust = dap.configurations.cpp
local ftMap = {
    vim = 'indent',
    python = { 'indent' },
    git = ''
}
vim.keymap.set('n', 'zR', require('ufo').openAllFolds)
vim.keymap.set('n', 'zM', require('ufo').closeAllFolds)
vim.keymap.set('n', 'zr', require('ufo').openFoldsExceptKinds)
vim.keymap.set('n', 'zm', require('ufo').closeFoldsWith) -- closeAllFolds == closeFoldsWith(0)
vim.keymap.set('n', 'F', function()
    local winid = require('ufo').peekFoldedLinesUnderCursor()
    if not winid then
        -- choose one of coc.nvim and nvim lsp
        -- vim.fn.CocActionAsync('definitionHover') -- coc.nvim
        vim.lsp.buf.hover()
    end
end)

local handler = function(virtText, lnum, endLnum, width, truncate)
    local newVirtText = {}
    local suffix = (' 󰁂 %d '):format(endLnum - lnum)
    local sufWidth = vim.fn.strdisplaywidth(suffix)
    local targetWidth = width - sufWidth
    local curWidth = 0
    for _, chunk in ipairs(virtText) do
        local chunkText = chunk[1]
        local chunkWidth = vim.fn.strdisplaywidth(chunkText)
        if targetWidth > curWidth + chunkWidth then
            table.insert(newVirtText, chunk)
        else
            chunkText = truncate(chunkText, targetWidth - curWidth)
            local hlGroup = chunk[2]
            table.insert(newVirtText, { chunkText, hlGroup })
            chunkWidth = vim.fn.strdisplaywidth(chunkText)
            -- str width returned from truncate() may less than 2nd argument, need padding
            if curWidth + chunkWidth < targetWidth then
                suffix = suffix .. (' '):rep(targetWidth - curWidth - chunkWidth)
            end
            break
        end
        curWidth = curWidth + chunkWidth
    end
    table.insert(newVirtText, { suffix, 'MoreMsg' })
    return newVirtText
end

-- global handler
-- `handler` is the 2nd parameter of `setFoldVirtTextHandler`,
-- check out `./lua/ufo.lua` and search `setFoldVirtTextHandler` for detail.
require('ufo').setup({
    open_fold_hl_timeout = 150,
    close_fold_kinds_for_ft = {
        default = { 'imports', 'comment' },
        json = { 'array' },
        c = { 'comment', 'region' },
        python = { 'comment', 'region', 'code' }
    },
    fold_virt_text_handler = handler,
    preview = {
        win_config = {
            border = { '', '─', '', '', '', '─', '', '' },
            winhighlight = 'Normal:Folded',
            winblend = 0
        },
        mappings = {
            scrollU = '<C-u>',
            scrollD = '<C-d>',
            jumpTop = '[',
            jumpBot = ']'
        }
    },
    provider_selector = function(bufnr, filetype, buftype)
        -- if you prefer treesitter provider rather than lsp,
        -- return ftMap[filetype] or {'treesitter', 'indent'}
        return ftMap[filetype]
        -- refer to ./doc/example.lua for detail
    end
})
-- buffer scope handler
-- will override global handler if it is existed
local bufnr = vim.api.nvim_get_current_buf()
require('ufo').setFoldVirtTextHandler(bufnr, handler)
require("codeium").setup({
    enable_cmp_source = false,
    virtual_text = {
        enabled = true,
        manual = false,
        filetypes = { 'python', 'tex', 'markdown' },
        default_filetype_enabled = true,
        idle_delay = 500,
        virtual_text_priority = 65535,
        map_keys = true,

        -- The key to press when hitting the accept keybinding but no completion is showing.
        -- Defaults to \t normally or <c-n> when a popup is showing.
        accept_fallback = "<leader><Tab>",
        key_bindings = {
            accept = "<leader><Tab>",
            accept_word = false,
            accept_line = false,
            clear = false,
            next = "<leader>]",
            prev = "<leader>[",
        }
    },
    workspace_root = {
        use_lsp = true,
        find_root = nil,
        paths = {
            ".bzr",
            ".git",
            ".hg",
            ".svn",
            "_FOSSIL_",
            "package.json",
        }
    }
})

vim.notify = function(msg, log_level, opts)
    if msg:match("Codeium") then
        return
    end
    -- 否则照常通知
    vim.api.nvim_echo({ { msg } }, true, {})
end

require("nvim-treesitter.configs").setup({
    -- ... other ts config
    textobjects = {
        move = {
            enable = true,
            set_jumps = false, -- you can change this if you want.
            goto_next_start = {
                --- ... other keymaps
                ["]b"] = { query = "@code_cell.inner", desc = "next code block" },
            },
            goto_previous_start = {
                --- ... other keymaps
                ["[b"] = { query = "@code_cell.inner", desc = "previous code block" },
            },
        },
        select = {
            enable = true,
            lookahead = true, -- you can change this if you want
            keymaps = {
                --- ... other keymaps
                ["ib"] = { query = "@code_cell.inner", desc = "in block" },
                ["ab"] = { query = "@code_cell.outer", desc = "around block" },
            },
        },
        swap = { -- Swap only works with code blocks that are under the same
            -- markdown header
            enable = true,
            swap_next = {
                --- ... other keymap
                ["<leader>sbl"] = "@code_cell.outer",
            },
            swap_previous = {
                --- ... other keymap
                ["<leader>sbh"] = "@code_cell.outer",
            },
        },
    }
})

require('twilight').setup()


require('nvim-window').setup({
    chars = {
        'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o',
        'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'
    },
    normal_hl = 'Normal',
    hint_hl = 'Bold',
    border = 'single'
})

require('im_select').setup({
    default_im_select       = "com.apple.keylayout.ABC",
    default_command         = "macism",
    set_default_events      = { "VimEnter", "FocusGained", "InsertLeave", "CmdlineLeave" },
    set_previous_events     = { "InsertEnter" },
    keep_quiet_on_no_binary = true,
    async_switch_im         = true
})


-- 覆盖 preview 动作（必须在 setup() 之前做）
local oil = require("oil")
local util = require("oil.util")

local function is_image(path)
    local ext = path:match("^.+(%..+)$")
    local image_exts = {
        [".png"] = true,
        [".jpg"] = true,
        [".jpeg"] = true,
        [".webp"] = true,
        [".bmp"] = true,
        [".gif"] = true,
    }
    return ext and image_exts[ext:lower()]
end

local function open_image_preview(path, entry, opts)
    local split = opts.split or "botright"
    local cmd = (opts.vertical and split .. " vsplit")
        or (opts.horizontal and split .. " split")
        or (split .. " vsplit")

    -- 在当前窗口右侧创建分屏（不抢焦点）
    vim.cmd(cmd)
    local preview_win = vim.api.nvim_get_current_win()

    -- 切回 oil 窗口（保持文件管理器处于活动窗口）
    vim.cmd("wincmd p")

    -- 创建 buffer + 绑定
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(preview_win, buf)
    vim.fn.termopen({ "chafa", path })

    -- 配置 buffer
    vim.bo[buf].buftype = "terminal"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].swapfile = false
    vim.api.nvim_buf_set_name(buf, "preview://" .. entry.name)
    vim.w[preview_win].oil_preview = true
    vim.w[preview_win].oil_entry_id = entry.id
    vim.w.oil_preview = true
    vim.w.oil_entry_id = entry.id
end

require("oil.actions").preview = {
    desc = "Use chafa to preview images; fallback to default preview for others",
    parameters = {
        vertical = { type = "boolean", desc = "Open in vertical split" },
        horizontal = { type = "boolean", desc = "Open in horizontal split" },
        split = {
            type = '"aboveleft"|"belowright"|"topleft"|"botright"',
            desc = "Split modifier",
        },
    },
    callback = function(opts)
        opts = opts or {}
        local entry = oil.get_cursor_entry()
        if not entry then
            vim.notify("No entry under cursor", vim.log.levels.ERROR)
            return
        end

        local util = require("oil.util")
        local winid = util.get_preview_win()
        if winid and vim.w[winid].oil_entry_id == entry.id then
            vim.api.nvim_win_close(winid, true)
            return
        end

        local path = oil.get_current_dir() .. "/" .. entry.name
        local ext = path:match("^.+(%..+)$")
        local image_exts = {
            [".png"] = true,
            [".jpg"] = true,
            [".jpeg"] = true,
            [".webp"] = true,
            [".bmp"] = true,
            [".gif"] = true,
        }

        if entry.type == "file" and ext and image_exts[ext:lower()] then
            -- 正确打开并保持焦点在 oil buffer
            local split = opts.split or "botright"
            local cmd = (opts.vertical and split .. " vsplit")
                or (opts.horizontal and split .. " split")
                or (split .. " vsplit")

            vim.cmd(cmd)
            local preview_win = vim.api.nvim_get_current_win()
            vim.cmd("wincmd p") -- ← 回到 oil buffer 保持焦点

            local buf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_win_set_buf(preview_win, buf)
            vim.fn.termopen({ "chafa", path })

            vim.bo[buf].buftype = "terminal"
            vim.bo[buf].buftype = "terminal"
            vim.bo[buf].bufhidden = "wipe"
            vim.bo[buf].swapfile = false
            vim.api.nvim_buf_set_name(buf, "preview://" .. entry.name)
            vim.w[preview_win].oil_preview = true
            vim.w[preview_win].oil_entry_id = entry.id
        else
            oil.open_preview(opts)
        end
    end

}

require("oil").setup({
    -- Oil will take over directory buffers (e.g. `vim .` or `:e src/`)
    -- Set to false if you want some other plugin (e.g. netrw) to open when you edit directories.
    default_file_explorer = true,
    restore_win_options = true,
    -- Id is automatically added at the beginning, and name at the end
    -- See :help oil-columns
    columns = {
        "icon",
        -- "permissions",
        "size",
        -- "mtime",
    },
    -- Buffer-local options to use for oil buffers
    buf_options = {
        buflisted = false,
        bufhidden = "hide",
    },
    -- Window-local options to use for oil buffers
    win_options = {
        wrap = true,
        signcolumn = "no",
        cursorcolumn = false,
        foldcolumn = "0",
        spell = false,
        list = true,
        conceallevel = 3,
        concealcursor = "nvic",
    },
    -- Send deleted files to the trash instead of permanently deleting them (:help oil-trash)
    delete_to_trash = true,
    -- Skip the confirmation popup for simple operations (:help oil.skip_confirm_for_simple_edits)
    skip_confirm_for_simple_edits = true,
    -- Selecting a new/moved/renamed file or directory will prompt you to save changes first
    -- (:help prompt_save_on_select_new_entry)
    prompt_save_on_select_new_entry = true,
    -- Oil will automatically delete hidden buffers after this delay
    -- You can set the delay to false to disable cleanup entirely
    -- Note that the cleanup process only starts when none of the oil buffers are currently displayed
    cleanup_delay_ms = 2000,
    lsp_file_methods = {
        -- Enable or disable LSP file operations
        enabled = true,
        -- Time to wait for LSP file operations to complete before skipping
        timeout_ms = 1000,
        -- Set to true to autosave buffers that are updated with LSP willRenameFiles
        -- Set to "unmodified" to only save unmodified buffers
        autosave_changes = false,
    },
    -- Constrain the cursor to the editable parts of the oil buffer
    -- Set to `false` to disable, or "name" to keep it on the file names
    constrain_cursor = "editable",
    -- Set to true to watch the filesystem for changes and reload oil
    watch_for_changes = false,
    -- Keymaps in oil buffer. Can be any value that `vim.keymap.set` accepts OR a table of keymap
    -- options with a `callback` (e.g. { callback = function() ... end, desc = "", mode = "n" })
    -- Additionally, if it is a string that matches "actions.<name>",
    -- it will use the mapping at require("oil.actions").<name>
    -- Set to `false` to remove a keymap
    -- See :help oil-actions for a list of all available actions
    keymaps = {
        ["g?"] = { "actions.show_help", mode = "n" },
        ["<CR>"] = "actions.select",
        ["l"] = "actions.select",
        ["<C-s>"] = { "actions.select", opts = { vertical = true } },
        ["<C-h>"] = { "actions.select", opts = { horizontal = true } },
        ["<C-t>"] = { "actions.select", opts = { tab = true } },
        ["<C-p>"] = "actions.preview",
        ["<C-l>"] = "actions.refresh",
        ["h"] = { "actions.parent", mode = "n" },
        ["_"] = { "actions.open_cwd", mode = "n" },
        ["`"] = { "actions.cd", mode = "n" },
        ["~"] = { "actions.cd", opts = { scope = "tab" }, mode = "n" },
        ["gs"] = { "actions.change_sort", mode = "n" },
        ["gx"] = "actions.open_external",
        ["g."] = { "actions.toggle_hidden", mode = "n" },
        ["g\\"] = { "actions.toggle_trash", mode = "n" },
    },
    -- Set to false to disable all of the above keymaps
    use_default_keymaps = true,
    view_options = {
        -- Show files and directories that start with "."
        show_hidden = false,
        -- This function defines what is considered a "hidden" file
        is_hidden_file = function(name, bufnr)
            local m = name:match("^%.")
            return m ~= nil
        end,
        -- This function defines what will never be shown, even when `show_hidden` is set
        is_always_hidden = function(name, bufnr)
            return false
        end,
        -- Sort file names with numbers in a more intuitive order for humans.
        -- Can be "fast", true, or false. "fast" will turn it off for large directories.
        natural_order = "fast",
        -- Sort file and directory names case insensitive
        case_insensitive = true,
        sort = {
            -- sort order can be "asc" or "desc"
            -- see :help oil-columns to see which columns are sortable
            { "type", "asc" },
            { "name", "asc" },
        },
        -- Customize the highlight group for the file name
        highlight_filename = function(entry, is_hidden, is_link_target, is_link_orphan)
            return nil
        end,
    },
    -- Extra arguments to pass to SCP when moving/copying files over SSH
    extra_scp_args = {},
    -- EXPERIMENTAL support for performing file operations with git
    git = {
        -- Return true to automatically git add/mv/rm files
        add = function(path)
            return false
        end,
        mv = function(src_path, dest_path)
            return false
        end,
        rm = function(path)
            return false
        end,
    },
    -- Configuration for the floating window in oil.open_float
    float = {
        -- Padding around the floating window
        padding = 2,
        -- max_width and max_height can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
        max_width = 0,
        max_height = 0,
        border = "rounded",
        win_options = {
            winblend = 0,
        },
        -- optionally override the oil buffers window title with custom function: fun(winid: integer): string
        get_win_title = nil,
        -- preview_split: Split direction: "auto", "left", "right", "above", "below".
        preview_split = "auto",
        -- This is the config that will be passed to nvim_open_win.
        -- Change values here to customize the layout
        override = function(conf)
            return conf
        end,
    },
    -- Configuration for the file preview window
    preview_win = {
        -- Whether the preview window is automatically updated when the cursor is moved
        update_on_cursor_moved = true,
        -- How to open the preview window "load"|"scratch"|"fast_scratch"
        preview_method = "fast_scratch",
        -- A function that returns true to disable preview on a file e.g. to avoid lag
        disable_preview = function(filename)
            return false
        end,
        -- Window-local options to use for preview window buffers
        win_options = {},
    },
    -- Configuration for the floating action confirmation window
    confirmation = {
        -- Width dimensions can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
        -- min_width and max_width can be a single value or a list of mixed integer/float types.
        -- max_width = {100, 0.8} means "the lesser of 100 columns or 80% of total"
        max_width = 0.9,
        -- min_width = {40, 0.4} means "the greater of 40 columns or 40% of total"
        min_width = { 40, 0.4 },
        -- optionally define an integer/float for the exact width of the preview window
        width = nil,
        -- Height dimensions can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
        -- min_height and max_height can be a single value or a list of mixed integer/float types.
        -- max_height = {80, 0.9} means "the lesser of 80 columns or 90% of total"
        max_height = 0.9,
        -- min_height = {5, 0.1} means "the greater of 5 columns or 10% of total"
        min_height = { 5, 0.1 },
        -- optionally define an integer/float for the exact height of the preview window
        height = nil,
        border = "rounded",
        win_options = {
            winblend = 0,
        },
    },
    -- Configuration for the floating progress window
    progress = {
        max_width = 0.9,
        min_width = { 40, 0.4 },
        width = nil,
        max_height = { 10, 0.9 },
        min_height = { 5, 0.1 },
        height = nil,
        border = "rounded",
        minimized_border = "none",
        win_options = {
            winblend = 0,
        },
    },
    -- Configuration for the floating SSH window
    ssh = {
        border = "rounded",
    },
    -- Configuration for the floating keymaps help window
    keymaps_help = {
        border = "rounded",
    },
})


-- lua, default settings
require("better_escape").setup {
    timeout = 200,           -- after `timeout` passes, you can press the escape key and the plugin will ignore it
    default_mappings = true, -- setting this to false removes all the default mappings
    mappings = {
        -- i for insert
        i = {
            j = {
                k = "<Esc>",
            },
            [";"] = {
                [";"] = "<Esc>",
            },
            [' '] = {
                [' '] =
                    function()
                        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>:", true, false, true), "n", false)
                    end,
            }
        },
        t = {
            j = {
                k = "<C-\\><C-n>",
            },
        },
        v = {
            j = {
                k = "<Esc>",
            },
            [";"] = {
                [";"] = "<Esc>",
            },
        },
        s = {
            j = {
                k = "<Esc>",
            },
            [";"] = {
                [";"] = "<Esc>",
            },
        },
    },
}
require('neoscroll').setup({
    mappings = { -- Keys to be mapped to their corresponding default scrolling animation
        '<C-b>', '<C-f>',
        '<C-y>', '<C-e>',
        'zt', 'zz', 'zb',
    },
    hide_cursor = true,          -- Hide cursor while scrolling
    stop_eof = true,             -- Stop at <EOF> when scrolling downwards
    respect_scrolloff = false,   -- Stop scrolling when the cursor reaches the scrolloff margin of the file
    cursor_scrolls_alone = true, -- The cursor will keep on scrolling even if the window cannot scroll further
    duration_multiplier = 0.5,   -- Global duration multiplier
    easing = 'linear',           -- Default easing function
    pre_hook = nil,              -- Function to run before the scrolling animation starts
    post_hook = nil,             -- Function to run after the scrolling animation ends
    performance_mode = false,    -- Disable "Performance Mode" on all buffers.
    ignored_events = {           -- Events ignored while scrolling
        'WinScrolled', 'CursorMoved'
    },
})

vim.keymap.set("n", "<S-k>", "<C-u>", { desc = "scroll up half page" })
vim.keymap.set("v", "<S-k>", "<C-u>", { desc = "scroll up half page" })
vim.keymap.set("n", "<S-j>", "<C-d>", { desc = "scroll down half page" })
vim.keymap.set("v", "<S-j>", "<C-d>", { desc = "scroll down half page" })

require('fine-cmdline').setup({
    cmdline = {
        enable_keymaps = true,
        smart_history = true,
        prompt = '> '
    },
    popup = {
        position = {
            row = '50%',
            col = '50%',
        },
        size = {
            width = '60%',
        },
        border = {
            style = 'rounded',
        },
        win_options = {
            winhighlight = 'Normal:Normal,FloatBorder:FloatBorder',
        },
    },
    hooks = {
        before_mount = function(input)
            -- code
        end,
        after_mount = function(input)
        end,
        set_keymaps = function(imap, feedkeys)
            -- code
        end
    }
})

enhance_syntax_highlighting()
