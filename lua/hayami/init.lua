local c = require("hayami.config")
local M = {}

local state = {
	buf = nil,
	win = nil,
	buffers = {},
	selected_idx = 1,
	timer = nil,
}

local function get_valid_buffers()
	local result = {}

	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(bufnr) and vim.api.nvim_buf_get_option(bufnr, "buflisted") then
			local filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")

			if not vim.tbl_contains(c.opts.excluded_filetypes, filetype) then
				local name = vim.api.nvim_buf_get_name(bufnr)
				name = name ~= "" and vim.fn.fnamemodify(name, ":~:.") or "[No Name]"

				local modified = vim.api.nvim_buf_get_option(bufnr, "modified")
				if modified then
					name = name .. " [+]"
				end

				table.insert(result, {
					bufnr = bufnr,
					name = name,
					modified = modified,
				})
			end
		end
	end

	local current_buf = vim.api.nvim_get_current_buf()
	table.sort(result, function(a, b)
		if a.bufnr == current_buf then
			return true
		end
		if b.bufnr == current_buf then
			return false
		end
		return a.bufnr > b.bufnr
	end)

	return result
end

local function create_window()
	local buffers = state.buffers
	local width = c.opts.width
	local height = math.min(#buffers, c.opts.height)

	local ui = vim.api.nvim_list_uis()[1]
	local row = math.floor((ui.height - height) / 2 - 1)
	local col = math.floor((ui.width - width) / 2)

	local buf = vim.api.nvim_create_buf(false, true)
	state.buf = buf

	vim.api.nvim_buf_set_option(buf, "modifiable", false)
	vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")

	local opts = {
		style = "minimal",
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		border = c.opts.border,
	}

	state.win = vim.api.nvim_open_win(buf, true, opts)

	vim.api.nvim_win_set_option(state.win, "winhl", "Normal:" .. c.opts.highlight.background)
	vim.api.nvim_win_set_option(state.win, "cursorline", true)

	return buf
end

local function update_buffer_contents()
	local buffers = state.buffers
	local lines = {}
	local padding = string.rep(" ", c.opts.padding)

	for i, buf in ipairs(buffers) do
		local prefix = state.selected_idx == i and "▶ " or "  "
		local line = prefix .. padding .. buf.name
		table.insert(lines, line)
	end

	local buf = state.buf
	vim.api.nvim_buf_set_option(buf, "modifiable", true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(buf, "modifiable", false)

	vim.api.nvim_win_set_cursor(state.win, { state.selected_idx, 0 })
end

local function setup_keymaps()
	local buf = state.buf

	vim.api.nvim_buf_set_keymap(buf, "n", c.opts.mappings.close, "", {
		callback = M.close,
		noremap = true,
		silent = true,
	})

	vim.api.nvim_buf_set_keymap(buf, "n", c.opts.mappings.select, "", {
		callback = function()
			M.select_buffer()
		end,
		noremap = true,
		silent = true,
	})

	vim.api.nvim_buf_set_keymap(buf, "n", c.opts.mappings.next, "", {
		callback = function()
			M.select_next()
		end,
		noremap = true,
		silent = true,
	})

	vim.api.nvim_buf_set_keymap(buf, "n", c.opts.mappings.prev, "", {
		callback = function()
			M.select_prev()
		end,
		noremap = true,
		silent = true,
	})
end

local function reset_timer()
	if state.timer then
		state.timer:stop()
		state.timer:close()
		state.timer = nil
	end

	if c.opts.auto_close_delay then
		state.timer = vim.loop.new_timer()
		state.timer:start(
			c.opts.auto_close_delay,
			0,
			vim.schedule_wrap(function()
				if state.win and vim.api.nvim_win_is_valid(state.win) then
					M.close()
				end
			end)
		)
	end
end

function M.open()
	if state.win and vim.api.nvim_win_is_valid(state.win) then
		state.selected_idx = 1
		state.buffers = get_valid_buffers()
		update_buffer_contents()
		reset_timer()
		return
	end

	state.buffers = get_valid_buffers()

	if #state.buffers == 0 then
		vim.notify("No buffers to switch to", vim.log.levels.INFO)
		return
	end

	create_window()
	setup_keymaps()
	update_buffer_contents()
	reset_timer()
end

function M.close()
	if state.timer then
		state.timer:stop()
		state.timer:close()
		state.timer = nil
	end

	if state.win and vim.api.nvim_win_is_valid(state.win) then
		vim.api.nvim_win_close(state.win, true)
		state.win = nil
	end

	if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
		vim.api.nvim_buf_delete(state.buf, { force = true })
		state.buf = nil
	end
end

function M.select_buffer()
	local selected = state.buffers[state.selected_idx]
	if selected then
		M.close()
		vim.api.nvim_set_current_buf(selected.bufnr)
	end
end

function M.select_next()
	local count = #state.buffers
	if count > 0 then
		state.selected_idx = (state.selected_idx % count) + 1
		update_buffer_contents()
		reset_timer()
	end
end

function M.select_prev()
	local count = #state.buffers
	if count > 0 then
		state.selected_idx = ((state.selected_idx - 2) % count) + 1
		update_buffer_contents()
		reset_timer()
	end
end

function M.setup(conf)
	vim.validate({ user_config = { conf, "table", true } })
	c.load(conf)

	vim.api.nvim_create_user_command("BufferSwitcher", function()
		M.open()
	end, {})

	vim.api.nvim_set_keymap("n", "J", "", {
		callback = M.open,
		noremap = true,
		silent = true,
		desc = "Open buffer switcher",
	})

	vim.api.nvim_set_keymap("n", "K", "", {
		callback = M.open,
		noremap = true,
		silent = true,
		desc = "Open buffer switcher",
	})
end

return M
