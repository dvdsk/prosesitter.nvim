local state = require("prosesitter/state")
local log = require("prosesitter/log")

local severity_as_int = {
	error = 4,
	warning = 3,
	suggestion = 2,
}

local function other(linter)
	if linter == "vale" then
		return "langtool"
	else
		return "vale"
	end
end

Issue = {}
Issue.__index = Issue
function Issue.new()
	local self = setmetatable({}, Issue)
	return self
end

function Issue:suggestion_text()
	if #self.replacements > 0 then
		return "replace with: " .. self.replacements[1].value
	end
end

function Issue:suggestion_lists()
	if #self.replacements == 0 then
		return nil
	end

	local list = {}
	for _, repl in ipairs(self.replacements) do
		list[#list + 1] = repl.value
	end
	return list
end

IssueList = {}
IssueList.__index = IssueList
function IssueList.new()
	local self = setmetatable({}, IssueList)
	return self
end

function IssueList:severity()
	local max = 0
	local res = "should never be unset"
	for _, issue in ipairs(self) do
		local curr = severity_as_int[issue.severity]
		if curr > max then
			max = curr
			res = issue.severity
		end
	end
	return res
end

function IssueList:hl_group()
	local sev = self:severity()
	return state.cfg.severity_to_hl[sev]
end

-- meta is a dict containing all kind of properties
-- m = buffer/linter/id/meta
-- then issues is a list of:
--
-- msg, severity, type, full_source, action
--
IssueIndex = { m = {} }
function IssueIndex:attach(buf)
	self.m[buf] = { vale = {}, langtool = {} }
end

function IssueIndex:remove(linter, buf, id)
	log.debug("removing issue list for id,linter,buf:",id,linter,buf)
	local old = self.m[buf][linter][id]
	if old ~= nil then
		self.m[buf][linter][id] = nil
	end
	return old
end

-- can only be called if you are sure other issue exists
function IssueIndex:linked_issue(linter, buf, id)
	log.debug("retrieving issue list for id,linter,buf:",id,other(linter),buf)
	return self.m[buf][other(linter)][id]
end

-- adds the list of issues under id for linter on buffer buf
function IssueIndex:set(buf, linter, id, issue_list)
	log.debug("adding issue list for id,linter,buf:",id,linter,buf)
	self.m[buf][linter][id] = issue_list
end

function IssueIndex:for_id(id)
	local buf = vim.api.nvim_get_current_buf()
	return self:for_buf_id(buf, id)
end

-- returns a list of issues given a mark id
function IssueIndex:for_buf_id(buf, id)
	local list = {}
	for _, by_linter in pairs(self.m[buf]) do
		local issues_list = by_linter[id]
		if issues_list ~= nil then
			for _, issue in pairs(issues_list) do
				list[#list + 1] = issue
			end
		end
	end
	return list
end

local M = {}
M.Issue = Issue
M.IssueList = IssueList
M.IssueIndex = IssueIndex
return M
