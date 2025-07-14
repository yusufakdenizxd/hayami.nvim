local util = require("hayami.utils")
local M = {}

local sidebar_bufnr = nil
local sidebar_winid = nil
local buffers = {}

function M.get_valid_buffer_lines()
	buffers = util.get_valid_buffers()
	local lines = {}

	for _, buf in ipairs(buffers) do
		local line = string.format("%s %s", buf.icon, buf.name)

		if buf.modified then
			line = line .. " "
		end

		table.insert(lines, line)
	end
	return lines
end

function M.open_sidebar()
	if sidebar_winid and vim.api.nvim_win_is_valid(sidebar_winid) then
		vim.api.nvim_set_current_win(sidebar_winid)
		return
	end

	sidebar_bufnr = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(sidebar_bufnr, "bufhidden", "wipe")

	local lines = M.get_valid_buffer_lines()
	vim.api.nvim_buf_set_lines(sidebar_bufnr, 0, -1, false, lines)

	local columns = vim.o.columns
	local lines_count = vim.o.lines - vim.o.cmdheight

	sidebar_winid = vim.api.nvim_open_win(sidebar_bufnr, true, {
		relative = "editor",
		width = math.floor(columns * 0.2),
		height = lines_count,
		row = 0,
		col = columns - math.floor(columns * 0.2),
		style = "minimal",
		border = "none",
	})
end

local function get_current_buffer_index()
	local current_bufnr = vim.api.nvim_get_current_buf()
	for i, buf in ipairs(buffers) do
		if buf.bufnr == current_bufnr then
			return i
		end
	end
	return nil
end

function M.goto_next_buffer()
	local index = get_current_buffer_index()
	if not index or #buffers == 0 then
		return
	end

	local next_index = (index % #buffers) + 1
	local next_bufnr = buffers[next_index].bufnr

	if vim.api.nvim_buf_is_valid(next_bufnr) then
		vim.api.nvim_set_current_buf(next_bufnr)
	else
		vim.notify("Buffer " .. next_bufnr .. " is not valid", vim.log.levels.WARN)
	end
end

function M.goto_prev_buffer()
	local index = get_current_buffer_index()
	if not index or #buffers == 0 then
		return
	end

	local prev_index = (index - 2 + #buffers) % #buffers + 1
	local prev_bufnr = buffers[prev_index].bufnr

	if vim.api.nvim_buf_is_valid(prev_bufnr) then
		vim.api.nvim_set_current_buf(prev_bufnr)
	else
		vim.notify("Buffer " .. prev_bufnr .. " is not valid", vim.log.levels.WARN)
	end
end

function M.render_sidebar()
	if not (sidebar_bufnr and vim.api.nvim_buf_is_valid(sidebar_bufnr)) then
		return
	end

	local lines = M.get_valid_buffer_lines()
	vim.api.nvim_buf_set_lines(sidebar_bufnr, 0, -1, false, lines)

	vim.api.nvim_buf_clear_namespace(sidebar_bufnr, -1, 0, -1)

	for i, buf in ipairs(buffers) do
		local hl_group = nil
		if buf.current_buf then
			hl_group = "SidebarLineCurrent"
		else
			hl_group = "SidebarLineVisible"
		end

		vim.api.nvim_buf_add_highlight(sidebar_bufnr, -1, hl_group, i - 1, 0, -1)
	end
end

function M.sidebar_listener()
	vim.api.nvim_create_augroup("BufferSidebarAutoRender", { clear = true })

	vim.api.nvim_create_autocmd(
		{ "BufAdd", "BufDelete", "BufUnload", "BufReadPost", "BufEnter", "BufFilePost", "BufModifiedSet" },
		{
			group = "BufferSidebarAutoRender",
			callback = function()
				vim.schedule(function()
					M.render_sidebar()
				end)
			end,
		}
	)
end

function M.toggle_sidebar()
	if sidebar_winid and vim.api.nvim_win_is_valid(sidebar_winid) then
		vim.api.nvim_win_close(sidebar_winid, true)
		sidebar_winid = nil
	else
		M.open_sidebar()
	end
end

return M
