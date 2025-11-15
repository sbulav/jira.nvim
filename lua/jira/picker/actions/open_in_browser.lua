local cli = require("jira.cli")

local M = {}

---Open issue in browser
---@param picker snacks.Picker
---@param item snacks.picker.Item
---@param action snacks.picker.Action
---@diagnostic disable-next-line: unused-local
function M.action_jira_open_in_browser(picker, item, action)
  cli.open_issue(item.key, {
    success_msg = string.format("Opened %s in browser", item.key),
    error_msg = string.format("Failed to open %s", item.key),
  })
end

return M
