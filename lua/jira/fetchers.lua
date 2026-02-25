local cache = require("jira.cache")
local cli = require("jira.cli")

local M = {}

---Fetch epic information for the given issue key
---@param key string
---@param callback fun(epic: jira.Epic?)
function M.fetch_epic(key, callback)
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

---Fetch issue with epic information
---@param issue_key string
---@param callback fun(result: table, epic: jira.Epic?)
function M.fetch_issue(issue_key, callback)
  local config = require("jira.config").options

  local cached = cache.get(cache.keys.ISSUE_VIEW, { key = issue_key })
  if cached and cached.items then
    M.fetch_epic(issue_key, function(epic)
      callback(cached.items, epic)
    end)
    return
  end

  cli.view_issue(issue_key, config.preview.nb_comments, function(result)
    if result.code ~= 0 then
      vim.notify("Failed to load issue: " .. issue_key, vim.log.levels.ERROR)
      return
    end

    cache.set(cache.keys.ISSUE_VIEW, { key = issue_key }, result)

    M.fetch_epic(issue_key, function(epic)
      callback(result, epic)
    end)
  end)
end

---Fetch sprints
---@param callback fun(sprints: table)
function M.fetch_sprints(callback)
  local cached = cache.get(cache.keys.SPRINTS)
  if cached and cached.items then
    callback(cached.items)
    return
  end

  cli.get_sprints(function(sprints)
    cache.set(cache.keys.SPRINTS, nil, sprints)
    callback(sprints)
  end)
end

---Fetch transitions for an issue
---@param issue_key string
---@param callback fun(transitions: string[]?)
function M.fetch_transitions(issue_key, callback)
  local cached = cache.get(cache.keys.TRANSITIONS, { key = issue_key })
  if cached and cached.items then
    callback(cached.items)
    return
  end

  cli.get_transitions(issue_key, function(transitions)
    if transitions and #transitions > 0 then
      cache.set(cache.keys.TRANSITIONS, { key = issue_key }, transitions)
    end
    callback(transitions)
  end)
end

---Fetch issue types
---@param callback fun(issue_types: string[]?)
function M.fetch_issue_types(callback)
  local cached = cache.get(cache.keys.ISSUE_TYPES)
  if cached and cached.items then
    callback(cached.items)
    return
  end

  cli.get_issue_types(function(issue_types)
    if issue_types and #issue_types > 0 then
      cache.set(cache.keys.ISSUE_TYPES, nil, issue_types)
    end
    callback(issue_types)
  end)
end

local function parse_csv_line(line)
  local values = {}
  local current = ""
  local in_quotes = false
  local i = 1

  while i <= #line do
    local char = line:sub(i, i)
    if char == '"' then
      in_quotes = not in_quotes
    elseif char == "," and not in_quotes then
      table.insert(values, current)
      current = ""
    else
      current = current .. char
    end
    i = i + 1
  end
  table.insert(values, current)
  return values
end

---Fetch epics list for create scratch buffer
---@param callback fun(epics: {key: string, summary: string}[]?)
function M.fetch_epics_for_create(callback)
  local cached = cache.get(cache.keys.EPICS)
  if cached and cached.items then
    local epics = {}
    for _, item in ipairs(cached.items) do
      if item.key and item.summary then
        table.insert(epics, { key = item.key, summary = item.summary })
      end
    end
    callback(#epics > 0 and epics or nil)
    return
  end

  local config = require("jira.config").options
  local args = cli.get_epic_list_args()
  vim.list_extend(args, { "--csv", "--columns", "key,summary" })

  local cmd = { config.cli.cmd }
  vim.list_extend(cmd, args)

  vim.system(cmd, { text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        callback(nil)
        return
      end

      local epics = {}
      local first_line = true
      for line in result.stdout:gmatch("[^\r\n]+") do
        if first_line then
          first_line = false
        else
          local values = parse_csv_line(line)
          if #values >= 2 then
            local summary = values[2]:gsub("%[([^%]]+)%[%]", "[%1]")
            table.insert(epics, { key = values[1], summary = summary })
          end
        end
      end

      callback(#epics > 0 and epics or nil)
    end)
  end)
end

return M
