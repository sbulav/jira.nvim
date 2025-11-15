local ui = require("jira.picker.ui")
local cli = require("jira.cli")

---Submit comment from scratch buffer
---@param issue_key string
---@param win snacks.win
local function submit_comment(issue_key, win)
  local comment = win:text()

  if not comment or comment:match("^%s*$") then
    vim.notify("Comment cannot be empty", vim.log.levels.WARN)
    return
  end

  cli.comment_issue(issue_key, comment, {
    success_msg = string.format("Added comment to %s", issue_key),
    error_msg = string.format("Failed to comment on %s", issue_key),
    on_success = function()
      local cache = require("jira.cache")
      cache.clear(cache.keys.ISSUE_VIEW, { key = issue_key })
      win:close()
    end,
  })
end

local M = {}

---Add comment to issue
---@param picker snacks.Picker
---@param item snacks.picker.Item
---@param action snacks.picker.Action
---@diagnostic disable-next-line: unused-local
function M.action_jira_add_comment(picker, item, action)
  ui.open_markdown_editor({
    title = string.format("Add Comment to %s", item.key),
    height = 15,
    ---@diagnostic disable-next-line: unused-local
    on_submit = function(text, win)
      submit_comment(item.key, win)
    end,
    submit_desc = "Submit comment",
  })
end

return M
