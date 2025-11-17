local cli = require("jira.cli")
local cache = require("jira.cache")

local M = {}

---Remove issue from epic
---@param picker snacks.Picker
---@param item snacks.picker.Item
---@param action snacks.picker.Action
---@diagnostic disable-next-line: unused-local
function M.action_jira_remove_from_epic(picker, item, action)
  cli.remove_issue_from_epic(item.key, {
    success_msg = string.format("Removed %s from epic", item.key),
    error_msg = string.format("Failed to remove %s from epic", item.key),
    on_success = function()
      cache.clear_issue_caches(item.key)
      picker:refresh()
    end,
  })
end

return M
