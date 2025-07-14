local c = require("hayami.config")
local side = require("hayami.sidebar")
local M = {}

local function setup_keymaps()
	vim.keymap.set("n", "J", side.goto_next_buffer)
	vim.keymap.set("n", "K", side.goto_prev_buffer)
end

local function setup_highlights()
	vim.api.nvim_set_hl(0, "SidebarLineCurrent", {
		fg = "#e1a345",
		bold = true,
	})

	vim.api.nvim_set_hl(0, "SidebarLineVisible", {
		fg = "#a89984",
	})
end

function M.setup(conf)
	vim.validate({ user_config = { conf, "table", true } })
	c.load(conf)

	vim.api.nvim_create_user_command("SidebarOpen", function()
		side.open_sidebar()
	end, {})

	vim.api.nvim_create_user_command("GotoNext", function()
		side.goto_next_buffer()
	end, {})

	vim.api.nvim_create_autocmd("VimEnter", {
		callback = function()
			local current_win = vim.api.nvim_get_current_win()
			side.open_sidebar()
			side.sidebar_listener()
			vim.schedule(function()
				if vim.api.nvim_win_is_valid(current_win) then
					vim.api.nvim_set_current_win(current_win)
				end
			end)
		end,
	})

	setup_highlights()
	setup_keymaps()

	vim.api.nvim_create_autocmd("ColorScheme", {
		pattern = "*",
		callback = function()
			setup_highlights()
		end,
	})
end

return M
