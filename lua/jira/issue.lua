local cache = require("jira.cache")
local cli = require("jira.cli")
local epic = require("jira.epic")

local M = {}

---Load issue with epic information
---@param issue_key string
---@param callback fun(result: table, epic: jira.Epic?)
function M.fetch(issue_key, callback)
  local config = require("jira.config").options

  local cached = cache.get(cache.keys.ISSUE_VIEW, { key = issue_key })
  if cached and cached.items then
    epic.fetch(issue_key, function(epic_info)
        callback(cached.items, epic_info)
    end)
    return
  end

  cli.view_issue(issue_key, config.preview.nb_comments, function(result)
    if result.code ~= 0 then
      vim.notify("Failed to load issue: " .. issue_key, vim.log.levels.ERROR)
      return
    end

    cache.set(cache.keys.ISSUE_VIEW, { key = issue_key }, result)

    epic.fetch(issue_key, function(epic_info)
      callback(result, epic_info)
    end)
  end)
end

return M
