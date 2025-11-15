local cli = require("jira.cli")
local cache = require("jira.cache")

local M = {}

---Unassign issue
---@param picker snacks.Picker
---@param item snacks.picker.Item
---@param action snacks.picker.Action
---@diagnostic disable-next-line: unused-local
function M.action_jira_unassign(picker, item, action)
  cli.unassign_issue(item.key, {
    success_msg = string.format("Unassigned %s", item.key),
    error_msg = string.format("Failed to unassign %s", item.key),
    on_success = function()
      cache.clear_issue_caches(item.key)
      picker:refresh()
    end,
  })
end

return M
