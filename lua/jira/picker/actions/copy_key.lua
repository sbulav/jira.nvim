local CLIPBOARD_REG = "+"
local DEFAULT_REG = '"'

local M = {}
---Copy issue key to clipboard
---@param picker snacks.Picker
---@param item snacks.picker.Item
---@param action snacks.picker.Action
---@diagnostic disable-next-line: unused-local
function M.action_jira_copy_key(picker, item, action)
  vim.fn.setreg(CLIPBOARD_REG, item.key)
  vim.fn.setreg(DEFAULT_REG, item.key)

  vim.notify(string.format("Copied %s to clipboard", item.key), vim.log.levels.INFO)
end

return M
