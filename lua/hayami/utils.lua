local c = require("hayami.config")
local devicons = require("nvim-web-devicons")
local M = {}

function M.get_valid_buffers()
	local result = {}

	local current_buf = vim.api.nvim_get_current_buf()
	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(bufnr) and vim.api.nvim_buf_get_option(bufnr, "buflisted") then
			local filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")

			if not vim.tbl_contains(c.opts.excluded_filetypes, filetype) then
				local name = vim.api.nvim_buf_get_name(bufnr)
				local extension = vim.fn.fnamemodify(name, ":e")

				local icon, _ = devicons.get_icon(name, extension, { default = true })
				name = name ~= "" and vim.fn.fnamemodify(name, ":~:.") or "[No Name]"

				local modified = vim.api.nvim_buf_get_option(bufnr, "modified")

				local buf = {
					bufnr = bufnr,
					name = name,
					modified = modified,
					icon = icon or "",
					current_buf = bufnr == current_buf,
				}

				table.insert(result, buf)
			end
		end
	end

	return result
end

return M
