local cli = require("jira.cli")
local cache = require("jira.cache")

local M = {}

---Assign issue to current user
---@param picker snacks.Picker
---@param item snacks.picker.Item
---@param action snacks.picker.Action
---@diagnostic disable-next-line: unused-local
function M.action_jira_assign_me(picker, item, action)
  cli.get_current_user({
    error_msg = "Failed to get current user",
    on_success = function(result)
      local me = vim.trim(result.stdout or "")
      cli.assign_issue(item.key, me, {
        success_msg = string.format("Assigned %s to you", item.key),
        error_msg = string.format("Failed to assign %s", item.key),
        on_success = function()
          cache.clear_issue_caches(item.key)
          picker:refresh()
        end,
      })
    end,
  })
end

return M
