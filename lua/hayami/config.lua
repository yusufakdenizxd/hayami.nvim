---@class HayamiConfig
local config = {}

--- @class HayamiOptions
local default_config = {
	width = 60,
	height = 10,
	border = "rounded",
	padding = 1,
	auto_close_delay = 500,
	mappings = {
		close = "<Esc>",
		select = "<CR>",
		next = "J",
		prev = "K",
	},
	highlight = {
		border = "FloatBorder",
		background = "NormalFloat",
		selected = "CursorLine",
	},

	excluded_filetypes = {
		"qf",
		"help",
		"NvimTree",
		"fugitive",
		"toggleterm",
	},
}

--- @type HayamiOptions
config.opts = {}

config.load = function(user_config)
	config.opts = vim.tbl_deep_extend("force", default_config, user_config or {})
end

return config
