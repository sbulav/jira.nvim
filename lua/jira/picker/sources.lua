local M = {}

---Builds the configuration for the JIRA issues picker.
---@param issues_opts table|nil Custom issues opts
---@return snacks.picker.source The configuration for the JIRA issues picker
local function source_jira_issues(issues_opts)
  local global_config = require("jira.config").options
  local keymaps = global_config.keymaps
  local merged_issues = vim.tbl_deep_extend("force", global_config.cli.issues, issues_opts or {})

  return {
    title = issues_opts and "JIRA Issues (Custom)" or "JIRA Issues",
    layout = global_config.layout.issues,
    finder = function(picker_opts, ctx)
      return require("jira.picker.finders").get_jira_issues(picker_opts, ctx, merged_issues)
    end,
    format = "format_jira_issues",
    preview = "preview_jira_issue",
    confirm = "action_jira_list_actions",
    pattern = merged_issues.prefill_search,

    win = {
      input = {
        title = "JIRA Issues (Current Sprint)",
        keys = keymaps.input,
      },
      list = {
        keys = keymaps.list,
      },
      preview = {
        keys = keymaps.preview,
      },
    },
  }
end

---Builds the configuration for the JIRA epics picker.
---@return snacks.picker.source The configuration for the JIRA epics picker
local function source_jira_epics()
  local config = require("jira.config").options
  local finders = require("jira.picker.finders")

  return {
    layout = config.layout.epics,
    title = "JIRA Epics",
    main = { current = true },
    finder = finders.get_jira_epics,
    format = "format_jira_epics",
    pattern = config.cli.epics.prefill_search,
    confirm = function(picker, item)
      picker:close()
      if item and item.key then
        vim.schedule(function()
          require("snacks").picker(M.jira_epic_issues(item.key))
        end)
      end
    end,
  }
end

---Builds the configuration for the JIRA actions picker.
---@return snacks.picker.source The configuration for the JIRA actions picker
local function source_jira_actions()
  local config = require("jira.config").options
  local finders = require("jira.picker.finders")

  return {
    layout = config.layout.actions,
    title = "Actions",
    main = { current = true },
    finder = finders.get_actions,
    format = "format_jira_action",
  }
end

---Builds the configuration for the JIRA sprints picker.
---@return snacks.picker.source The configuration for the JIRA sprints picker
local function source_jira_sprints()
  local config = require("jira.config").options
  local finders = require("jira.picker.finders")

  return {
    layout = config.layout.sprints,
    title = "Select Sprint",
    main = { current = true },
    finder = finders.get_sprints,
    format = "format_jira_sprint",
  }
end

---Builds the configuration for the JIRA epic issues picker.
---@param epic_key string? the epic key
---@return snacks.picker.source The configuration for the JIRA epic issues picker
function M.jira_epic_issues(epic_key)
  local config = require("jira.config").options
  local keymaps = config.keymaps

  return {
    title = "JIRA Epic Issues",
    layout = config.layout.epic_issues,
    finder = function(opts, ctx)
      return require("jira.picker.finders").get_jira_epic_issues(epic_key, opts, ctx)
    end,
    format = "format_jira_issues",
    preview = "preview_jira_issue",
    confirm = "action_jira_list_actions",
    pattern = config.cli.epic_issues.prefill_search,

    win = {
      input = {
        title = string.format("JIRA Epic Issues (%s)", epic_key or ""),
        keys = keymaps.input,
      },
      list = {
        keys = keymaps.list,
      },
      preview = {
        keys = keymaps.preview,
      },
    },
  }
end

function M.get_source_jira_issues(issues_opts)
  return source_jira_issues(issues_opts)
end

M.source_jira_issues = source_jira_issues()
M.source_jira_actions = source_jira_actions()
M.source_jira_epics = source_jira_epics()
M.source_jira_sprints = source_jira_sprints()

return M
