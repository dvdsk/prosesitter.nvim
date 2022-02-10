-- local langtool = require("prosesitter/backend/langtool")
-- local vale = require("prosesitter/backend/vale")
-- local util = require("prosesitter/util")

-- -- Attempt at an install test, however this takes far too long
-- describe("Checking if install succeeds", function()
-- 	it("installing", function()
-- 		local langtool_ok = langtool.setup_binairy()
-- 		langtool.setup_cfg()
-- 		local vale_ok = vale.setup_binairy_and_styles()
-- 		vale.setup_cfg()

-- 		local function check()
-- 			return langtool_ok ~= nil and vale_ok ~= nil
-- 		end
-- 		local _, _ = vim.wait(49000, check, 500, false)
-- 		assert.truthy(langtool_ok)
-- 		assert.truthy(vale_ok)

-- 		local path = util:resolve_path(nil, "vale")
-- 		assert.is_not_nil(path)

-- 		path = util:resolve_path(nil, "langtool/languagetool-server.jar")
-- 		assert.is_not_nil(path)
-- 	end)
-- end)
