local M = {}

M.list = {}

function M.is_buffer_valid(buf_id, buf_name)
    return 1 == vim.fn.buflisted(buf_id) and buf_name ~= ""
end

local function get_buf_basename(list)
    for i, buf_info in ipairs(list) do
        if not buf_info.basename then
            buf_info.basename = vim.fs.basename(buf_info.name)
        end

        -- check duplicate buf
        local is_duplicate = false
        for j, other in ipairs(list) do

            if not other.basename then
                other.basename = vim.fs.basename(other.name)
            end

            if i ~= j and buf_info.basename == other.basename then
                is_duplicate = true
                local parent = vim.fs.basename(vim.fs.dirname(other.name))
                other.basename = vim.fs.joinpath(parent, other.basename)
            end
        end

        if is_duplicate then
            local parent = vim.fs.basename(vim.fs.dirname(buf_info.name))
            buf_info.basename = vim.fs.joinpath(parent, buf_info.basename)
        end
    end

    return list
end

function M.update_bufferlist()

    M.list = {}

    local buffer_ids = vim.api.nvim_list_bufs()

    for _, buf_id in ipairs(buffer_ids) do
        local buf_name = vim.api.nvim_buf_get_name(buf_id)
        if (M.is_buffer_valid(buf_id, buf_name)) then
            local buf_info = {id = buf_id, name = buf_name}
            table.insert(M.list, buf_info)
        end
    end

    M.list = get_buf_basename(M.list)
end

return M
