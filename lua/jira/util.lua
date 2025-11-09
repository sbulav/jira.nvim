local M = {}

---Check if jira CLI is available
---@return boolean
function M.has_jira_cli()
  local config = require("jira.config").options
  return vim.fn.executable(config.jira_cmd) == 1
end

---Validate configuration
---@param config jira.Config
---@return boolean ok
---@return string? error
function M.validate_config(config)
  if not M.has_jira_cli() then
    return false, "jira CLI not found in PATH: " .. config.jira_cmd
  end
  return true
end

---Get JIRA instance base URL from config or environment
---@return string url
function M.get_jira_base_url()
  local config = require("jira.config").options

  -- Check config first
  if config.jira_base_url then
    return config.jira_base_url
  end

  -- Check environment variable
  local env_url = vim.env.JIRA_BASE_URL or vim.env.JIRA_URL
  if env_url then
    return env_url
  end

  -- Try to extract from jira CLI config
  local result = vim.system({ config.jira_cmd, "config", "get", "server" }, { text = true }):wait()
  if result.code == 0 and result.stdout then
    return vim.trim(result.stdout)
  end

  -- Fallback
  return "https://your-jira-instance.atlassian.net"
end

return M
