local cache = require("jira.cache")
local cli = require("jira.cli")

local M = {}

---Fetch epic information for the given issue key
---@param key string
---@param callback fun(epic: jira.Epic?)
function M.fetch(key, callback)
  local cached = cache.get(cache.keys.ISSUE_EPIC, { key = key })
  if cached and cached.items then
    -- Issues without epic have vim.NIL in the cache.
    if cached.items == vim.NIL then
      callback(nil)
    else
      callback(cached.items)
    end
    return
  end

  cli.get_issue_epic(key, function(epic)
    cache.set(cache.keys.ISSUE_EPIC, { key = key }, epic or vim.NIL)
    callback(epic)
  end)
end

return M
