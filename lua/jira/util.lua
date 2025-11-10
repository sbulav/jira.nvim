local M = {}

---Check if jira CLI is available
---@return boolean
function M.has_jira_cli()
  local config = require("jira.config").options
  return vim.fn.executable(config.cli.cmd) == 1
end

---Validate configuration
---@param config jira.Config
---@return boolean ok
---@return string? error
function M.validate_config(config)
  if not M.has_jira_cli() then
    return false, "jira CLI not found in PATH: " .. config.cli.cmd
  end
  return true
end

return M
