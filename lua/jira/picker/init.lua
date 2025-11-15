local M = {}

function M.register()
  local snacks = require("snacks")

  -- Register formatters
  local formatters = require("jira.picker.formatters")
  for name, formatter in pairs(formatters) do
    if name:match("^format_") then
      snacks.picker.format[name] = formatter
    end
  end

  -- Register previewers
  local previewers = require("jira.picker.previewers")
  for name, previewer in pairs(previewers) do
    if name:match("^preview_") then
      snacks.picker.preview[name] = previewer
    end
  end

  -- Register actions
  local actions = require("jira.picker.actions")
  for name, action in pairs(actions) do
    if name:match("^action_") then
      snacks.picker.actions[name] = action
    end
  end

  -- Register sources
  local sources = require("jira.picker.sources")
  for name, source in pairs(sources) do
    if name:match("^source_") then
      snacks.picker.sources[name] = source
    end
  end
end

return M
