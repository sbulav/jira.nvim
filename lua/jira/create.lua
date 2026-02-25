local cache = require("jira.cache")
local cli = require("jira.cli")
local config = require("jira.config")

local M = {}

---Parse markdown frontmatter to extract fields and content
---@param body string Buffer content
---@return table<string, string> fields Extracted frontmatter fields
---@return string content Rest of the body (description)
function M.parse(body)
  local fields = {}
  local content = body

  -- Parse markdown frontmatter for fields
  content = content:gsub("^(%-%-%-\n.-\n%-%-%-\n%s*)", function(fm)
    fm = fm:gsub("^%-%-%-\n", ""):gsub("\n%-%-%-\n%s*$", "")
    local lines = vim.split(fm, "\n")
    for _, line in ipairs(lines) do
      local field, value = line:match("^(%w+):%s*(.-)%s*$")
      if field then
        fields[field] = value
      end
    end
    return ""
  end)

  -- Extract summary and clean up
  local summary = ""
  content = content:gsub("\n?Summary:%s*(.-)\n\n", function(s)
    summary = s
    return "\n\n"
  end)

  -- Clean up empty lines at start/end
  content = content:gsub("^%s+", ""):gsub("%s+$", "")

  fields["Summary"] = summary
  return fields, content
end

---Submit the scratch buffer to create the issue
---@param win snacks.win
function M.submit(win)
  local body = win:text()
  local fields, description = M.parse(body)

  if not fields["Summary"] or fields["Summary"] == "" then
    vim.notify("Summary is required", vim.log.levels.ERROR)
    return
  end

  if not fields["Type"] or fields["Type"] == "" then
    vim.notify("Type is required in frontmatter", vim.log.levels.ERROR)
    return
  end

  if (not fields["Project"] or fields["Project"] == "") and (not fields["Epic"] or fields["Epic"] == "") then
    vim.notify("No Project or Epic specified; using jira-cli defaults", vim.log.levels.WARN)
  end

  local args = { "issue", "create", "-t", fields["Type"], "-s", fields["Summary"], "--no-input" }

  if fields["Project"] and fields["Project"] ~= "" then
    table.insert(args, "-p")
    table.insert(args, fields["Project"])
  end

  if fields["Assignee"] and fields["Assignee"] ~= "" then
    table.insert(args, "-a")
    table.insert(args, fields["Assignee"])
  end

  if fields["Epic"] and fields["Epic"] ~= "" then
    -- Extract just the key from "KEY: Summary" format
    local epic_key = fields["Epic"]:match("^([A-Z0-9]+-[0-9]+)")
    if epic_key then
      table.insert(args, "-P")
      table.insert(args, epic_key)
    end
  end

  -- Handle multiple labels
  if fields["Labels"] and fields["Labels"] ~= "" then
    for label in string.gmatch(fields["Labels"], "[^,]+") do
      label = vim.trim(label)
      if label ~= "" then
        table.insert(args, "-l")
        table.insert(args, label)
      end
    end
  end

  -- Handle multiple components
  if fields["Components"] and fields["Components"] ~= "" then
    for comp in string.gmatch(fields["Components"], "[^,]+") do
      comp = vim.trim(comp)
      if comp ~= "" then
        table.insert(args, "-C")
        table.insert(args, comp)
      end
    end
  end

  -- Handle custom fields in format key=value[,key=value]
  if fields["Custom"] and fields["Custom"] ~= "" then
    for pair in string.gmatch(fields["Custom"], "[^,]+") do
      local key, value = pair:match("^%s*([^=]+)%s*=%s*(.-)%s*$")
      if key and value and key ~= "" and value ~= "" then
        table.insert(args, "--custom")
        table.insert(args, string.format("%s=%s", key, value))
      end
    end
  end

  if description and description ~= "" then
    table.insert(args, "-b")
    table.insert(args, description)
  end

  local spinner = require("snacks.picker.util.spinner").loading()

  -- Use direct vim.system or cli.execute. We will use a wrapped version or cli.execute
  cli.execute(args, {
    success_msg = false,
    error_msg = "Failed to create issue",
    on_success = function(result)
      vim.schedule(function()
        spinner:stop()

        -- Parse issue key from output
        local issue_key = result.stdout:match("([A-Z0-9]+-[0-9]+)")
        if issue_key then
          vim.notify(string.format("✓ Created issue: %s", issue_key), vim.log.levels.INFO)

          -- Close scratch buffer
          if win and win:valid() then
            local buf = win.buf
            local fname = vim.api.nvim_buf_get_name(buf)
            win:on("WinClosed", function()
              vim.schedule(function()
                pcall(vim.api.nvim_buf_delete, buf, { force = true })
                os.remove(fname)
                os.remove(fname .. ".meta")
              end)
            end, { buf = true })
            win:close()
          end

          -- Open the new issue in buffer
          vim.defer_fn(function()
            require("jira.buf").open(issue_key)
            cache.clear(cache.keys.ISSUES)
            cache.clear(cache.keys.EPIC_ISSUES)
          end, config.options.cli.timeout.issue_open_delay)
        else
          vim.notify("Failed to parse created issue key", vim.log.levels.ERROR)
        end
      end)
    end,
    on_error = function()
      vim.schedule(function()
        spinner:stop()
      end)
    end,
  })
end

---Find line number for a field in frontmatter
---@param buf number Buffer handle
---@param field string Field name to find
---@return number? line Line number (1-indexed) or nil if not found
local function find_field_line(buf, field)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  for i, line in ipairs(lines) do
    if line:match("^" .. field .. ":") then
      return i
    end
  end
  return nil
end

---Update a field value in the frontmatter
---@param buf number Buffer handle
---@param field string Field name
---@param value string New value
local function update_field(buf, field, value)
  local line_nr = find_field_line(buf, field)
  if line_nr then
    vim.api.nvim_buf_set_lines(buf, line_nr - 1, line_nr, false, { string.format("%s: %s", field, value) })
  end
end

---Open epic picker for selection
---@param win snacks.win
local function pick_epic(win)
  if not win or not win:valid() then
    return
  end

  require("snacks").picker("source_jira_epics", {
    confirm = function(picker, item)
      picker:close()
      if item and item.key then
        local display = item.key
        if item.summary and item.summary ~= "" then
          display = string.format("%s: %s", item.key, item.summary)
        end
        update_field(win.buf, "Epic", display)
      end
    end,
  })
end

---Open components picker for selection (multi-select)
---@param win snacks.win
local function pick_components(win)
  if not win or not win:valid() then
    return
  end

  local opts = config.options.action.create or {}
  local components = opts.available_components or {}

  if #components == 0 then
    vim.notify("No components configured. Add them to config.action.create.available_components", vim.log.levels.WARN)
    return
  end

  local buf = win.buf
  local current_line = find_field_line(buf, "Components")
  local current_value = ""
  if current_line then
    local lines = vim.api.nvim_buf_get_lines(buf, current_line - 1, current_line, false)
    current_value = lines[1]:gsub("^Components:%s*", "")
  end
  local current_components = {}
  for comp in current_value:gmatch("[^,]+") do
    comp = vim.trim(comp)
    if comp ~= "" then
      current_components[comp] = true
    end
  end

  local items = {}
  for i, comp in ipairs(components) do
    local icon = current_components[comp] and "✓ " or "  "
    table.insert(items, {
      text = icon .. comp,
      comp = comp,
      selected = current_components[comp] or false,
      idx = i,
    })
  end

  require("snacks").picker({
    title = "Select Components",
    layout = { preset = "select" },
    main = { current = true },
    items = items,
    format = "text",
    confirm = function(picker, item)
      picker:close()
      if not item then
        return
      end

      current_components[item.comp] = not current_components[item.comp]

      local selected = {}
      for comp, sel in pairs(current_components) do
        if sel then
          table.insert(selected, comp)
        end
      end

      update_field(buf, "Components", table.concat(selected, ", "))
    end,
  })
end

---Open scratch buffer to create a new Jira issue
function M.open()
  local opts = config.options.action.create or { default_fields = {}, template = "" }
  local default_fields = opts.default_fields or {}

  local field_order = { "Project", "Epic", "Type", "Components", "Labels", "Assignee", "Custom" }

  local fm = { "---" }
  for _, field in ipairs(field_order) do
    local v = default_fields[field]
    if v then
      local val = type(v) == "function" and v() or v
      fm[#fm + 1] = string.format("%s: %s", field, val)
    end
  end
  fm[#fm + 1] = "---\n"
  fm[#fm + 1] = "Summary: "

  local template = table.concat(fm, "\n") .. "\n\n" .. (opts.template or "")

  require("snacks").scratch({
    ft = "markdown",
    name = "Create Jira Issue",
    template = template,
    filekey = {
      cwd = true,
      branch = true,
      count = false,
      id = "jira_create",
    },
    win = {
      relative = "editor",
      width = config.options.ui.scratch.width,
      height = config.options.ui.scratch.height,
      border = "rounded",
      title = " Create Jira Issue ",
      title_pos = "center",
      keys = {
        submit = {
          "<c-s>",
          function(w)
            M.submit(w)
          end,
          desc = "Submit and create issue",
          mode = { "n", "i" },
        },
        epic_picker = {
          "<c-e>",
          function(w)
            pick_epic(w)
          end,
          desc = "Select epic",
          mode = { "n", "i" },
        },
        components_picker = {
          "<c-o>",
          function(w)
            pick_components(w)
          end,
          desc = "Select components",
          mode = { "n", "i" },
        },
      },
      on_win = function(win)
        -- Position cursor at the end of "Summary: " line
        vim.schedule(function()
          if not win or not win:valid() then
            return
          end
          local lines = vim.api.nvim_buf_get_lines(win.buf, 0, -1, false)
          for i, line in ipairs(lines) do
            if line:match("^Summary:") then
              vim.api.nvim_win_set_cursor(win.win, { i, #line })
              vim.cmd.startinsert({ bang = true })
              break
            end
          end
        end)
      end,
    },
  })
end

return M
