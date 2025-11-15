local M = {}

---Refresh picker and clear cache
---@param picker snacks.Picker
---@param item snacks.picker.Item
---@param action snacks.picker.Action
---@diagnostic disable-next-line: unused-local
function M.action_jira_refresh_cache(picker, item, action)
  require("jira.cache").clear()
  picker:refresh()
end

return M
