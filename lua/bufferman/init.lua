local M = {}

function M.setup(config)
    if (config == nil) then
        M.config = {
            width = 0.6,
            height = 0.6,
            border = { "╭", "─" ,"╮", "│", "╯", "─", "╰", "│" }
        }
    else
        M.config = config
    end
end

M.setup()

return M
