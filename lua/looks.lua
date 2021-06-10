require('gitsigns').setup()

local M = {}

function M:lualine_light() 
	require('lualine').setup{
		options = {
			theme = 'solarized'
		}
	}
end

function M:lualine_dark() 
	require('lualine').setup{
		options = {
			theme = 'tokyonight'
		}
	}
end

return M
