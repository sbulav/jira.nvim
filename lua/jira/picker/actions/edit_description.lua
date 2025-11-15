local cli = require("jira.cli")
local ui = require("jira.picker.ui")

local M = {}

---Submit description from scratch buffer
---@param issue_key string
---@param win snacks.win
---@param picker snacks.Picker
local function submit_description(issue_key, win, picker)
  local description = win:text()

  cli.edit_issue_description(issue_key, description, {
    success_msg = string.format("Updated description for %s", issue_key),
    error_msg = string.format("Failed to update description for %s", issue_key),
    on_success = function()
      local cache = require("jira.cache")
      cache.clear(cache.keys.ISSUE_VIEW, { key = issue_key })
      win:close()
      picker:refresh()
    end,
  })
end

---Edit issue description
---@param picker snacks.Picker
---@param item snacks.picker.Item
---@param action snacks.picker.Action
---@diagnostic disable-next-line: unused-local
function M.action_jira_edit_description(picker, item, action)
  cli.get_issue_description(item.key, function(description)
    if not description then
      vim.notify(string.format("Failed to fetch description for %s", item.key), vim.log.levels.ERROR)
      return
    end

    ui.open_markdown_editor({
      title = string.format("Edit Description for %s", item.key),
      template = description,
      ---@diagnostic disable-next-line: unused-local
      on_submit = function(text, win)
        submit_description(item.key, win, picker)
      end,
      submit_desc = "Submit description",
    })
  end)
end

return M
