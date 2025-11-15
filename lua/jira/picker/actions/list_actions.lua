local M = {}

---Action to show action dialog
---@param picker? snacks.Picker
---@param item snacks.picker.Item
---@param action? snacks.picker.Action
---@diagnostic disable-next-line: unused-local
function M.action_jira_list_actions(picker, item, action)
  require("snacks").picker("source_jira_actions", {
    item = item,
    confirm = function(action_picker, action_item, selected_action)
      if not action_item then
        return
      end

      -- Focus parent picker
      if picker then
        picker:focus()
      end

      -- Execute the action
      if action_item.action and action_item.action.action then
        action_item.action.action(picker, item, selected_action)
      end

      -- Close action dialog
      action_picker:close()
    end,
  })
end

return M
