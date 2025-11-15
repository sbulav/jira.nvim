local cli = require("jira.cli")
local CLIPBOARD_REG = "+"
local DEFAULT_REG = '"'

local M = {}

---Copy issue URL to clipboard
---@param picker snacks.Picker
---@param item snacks.picker.Item
---@param action snacks.picker.Action
---@diagnostic disable-next-line: unused-local
function M.action_jira_copy_url(picker, item, action)
  local url = cli.get_issue_url(item.key)
  if not url then
    vim.notify("Failed to get server URL from config", vim.log.levels.ERROR)
    return
  end

  vim.fn.setreg(CLIPBOARD_REG, url)
  vim.fn.setreg(DEFAULT_REG, url)

  vim.notify(string.format("Copied %s to clipboard", url), vim.log.levels.INFO)
end

return M
