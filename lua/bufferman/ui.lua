local devicons = require("nvim-web-devicons")

local bm = require("bufferman")
local bl = require("bufferman.bufferlist")

local M = {}
local config = bm.config

function M.create_float_window(opts)
    M.ns = vim.api.nvim_create_namespace("BufferManIndicator")
    local buf = vim.api.nvim_create_buf(false, true)
    local screen_h = vim.o.lines
    local screen_w = vim.o.columns
    local width = config.width or 0.6
    local height = config.height or 0.6
    local w, h
    if (width > 1) then
        w = width
    else
        w = math.floor(screen_w * width)
    end
    if (height > 1) then
        h = height
    else
        h = math.floor(screen_h * height)
    end
    local x = math.floor((screen_w - w) / 2)
    local y = math.floor((screen_h - h) / 2)
    local border = config.border
    if (opts == nil) then
        opts = {
            title = "buffer",
            title_pos = "center",
            relative = 'editor',
            width = w,
            height = h,
            col = x,
            row = y,
            anchor = 'NW',
            -- style = 'minimal',
            border = border,
            zindex = 50,
        }
    end
    local win = vim.api.nvim_open_win(buf, true, opts)

    vim.api.nvim_set_option_value("relativenumber", true, {win = win})

    vim.keymap.set("n", "<CR>", function()
        local line = vim.api.nvim_get_current_line()
        local buf_id = string.match(line, "^%[([0-9]+)%]")
        buf_id = tonumber(buf_id)
        M.close_float_window()
        if vim.api.nvim_buf_is_valid(buf_id) then
            vim.api.nvim_set_current_buf(buf_id)
        end
    end, {buffer = buf})

    vim.keymap.set("n", "q", function()
        M.close_float_window()
    end, {buffer = buf})

    M.buf = buf
    M.win = win
end

function M.close_float_window()
    local lines = vim.api.nvim_buf_get_lines(M.buf, 0, -1, true)
    vim.api.nvim_win_close(M.win, true)
    M.buf = nil
    M.win = nil
    M.check_buffers(lines)
end

function M.get_file_icon(buf_name)
    return devicons.get_icon(buf_name, nil, { default = true })
end

local function get_diagnostic(buf_id)
    local diagnostics = vim.diagnostic.get(buf_id, {})
    local diagnostic_info = {
        info = 0,
        warn = 0,
        error = 0
    }
    for _, diagnostic in ipairs(diagnostics) do
        if diagnostic.severity == vim.diagnostic.severity.INFO then
            diagnostic_info.info = diagnostic_info.info + 1
        elseif diagnostic.severity == vim.diagnostic.severity.WARN then
            diagnostic_info.warn = diagnostic_info.warn + 1
        elseif diagnostic.severity == vim.diagnostic.severity.ERROR then
            diagnostic_info.error = diagnostic_info.error + 1
        end
    end

    return diagnostic_info
end

function M.fill_buffers()
    bl.update_bufferlist()
    local id_len = 0
    local basename_len = 0
    for _, buf_info in ipairs(bl.list) do
        id_len = math.max(id_len, #tostring(buf_info.id))
        basename_len = math.max(basename_len, #buf_info.basename)
    end
    for i, buf_info in ipairs(bl.list) do
        local icon, hl = M.get_file_icon(buf_info.name)
        local format_str = '[%0' .. id_len .. 'd] %s %-' .. basename_len .. 's'
        local line = string.format(format_str, buf_info.id, icon, buf_info.basename)
        local diagnostic_info = get_diagnostic(buf_info.id)
        local virt_text = {}
        vim.api.nvim_buf_set_lines(M.buf, i - 1, -1, false, {line})
        -- set icon color 
        vim.api.nvim_buf_set_extmark(M.buf, M.ns, i - 1, id_len + 3, {hl_group = hl, end_col = id_len + 4})
        -- set diagnostic
        -- virt_text[1] = {'E' .. diagnostic_info.error .. " ", "DiagnosticFloatingError"}
        -- virt_text[2] = {'W' .. diagnostic_info.warn .. " ",  "DiagnosticFloatingWarn"}
        -- virt_text[3] = {'I' .. diagnostic_info.info,  "DiagnosticFloatingInfo"}
        -- vim.api.nvim_buf_set_extmark(M.buf, M.ns, i - 1, -1, {virt_text = virt_text})
    end
end

function M.check_buffers(lines)
    local buf_ids = {}
    for _, line in ipairs(lines) do
        local buf_id = string.match(line, "^%[([0-9]+)%]")
        buf_id = tonumber(buf_id)
        table.insert(buf_ids, buf_id)
    end
    for _, buf_info in ipairs(bl.list) do
        local deleted = true
        for _, buf_id in ipairs(buf_ids) do
            if buf_info.id == buf_id then
                deleted = false
            end
        end

        if deleted then
            vim.api.nvim_buf_clear_namespace(buf_info.id, -1, 1, -1)
            vim.api.nvim_buf_delete(buf_info.id, {})
        end
    end
end

function M.bufferlist_toggle()
    local current_win_conf = vim.api.nvim_win_get_config(0)
    if (M.buf ~= nil and M.win ~= nil) then
        M.close_float_window()
    else
        M.create_float_window()
        M.fill_buffers()
    end
end

return M
