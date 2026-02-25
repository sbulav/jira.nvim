local M = {}

---Main action: Create a new JIRA issue via scratch buffer
---@param picker snacks.Picker
---@param item snacks.picker.Item
---@param action snacks.picker.Action
---@diagnostic disable-next-line: unused-local
function M.action_jira_create_issue_scratch(picker, item, action)
  if picker then
    picker:close()
  end
  require("jira.create").open()
end

return M
