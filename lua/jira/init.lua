--- Setup plugin with user configuration
---@param opts jira.Config?
local function setup(opts)
  require("jira.config").setup(opts)

  -- Register with snacks.picker if available
  if package.loaded["snacks"] then
    require("jira.picker").register()
  end
end

--- Open issues picker
---@param opts table? Picker options
local function open_jira_issues(opts)
  if not package.loaded["snacks"] then
    vim.notify("jira.nvim requires snacks.nvim", vim.log.levels.ERROR)
    return
  end

  if not package.loaded["jira.picker"] then
    require("jira.picker").register()
  end

  return require("snacks").picker("source_jira_issues", opts)
end

local M = {}
M.setup = setup
M.open_jira_issues = open_jira_issues
return M
