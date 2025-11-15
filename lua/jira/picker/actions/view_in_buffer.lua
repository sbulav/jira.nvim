local M = {}

---View issue in buffer
---@param picker snacks.Picker
---@param item snacks.picker.Item
---@param action snacks.picker.Action
---@diagnostic disable-next-line: unused-local
function M.action_jira_view_in_buffer(picker, item, action)
  require("jira.buf").open(item.key)

  if picker then
    picker:close()
  end
end

return M
