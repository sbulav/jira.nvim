local M = {}

-- Highlight groups for issue types
local TYPE_HIGHLIGHTS = {
  Bug = "DiagnosticError",
  Story = "DiagnosticInfo",
  Task = "DiagnosticWarn",
  Enhancement = "DiagnosticHint",
  Epic = "Special",
}

-- Highlight groups for statuses
local STATUS_HIGHLIGHTS = {
  ["To Do"] = "Comment",
  ["In Progress"] = "DiagnosticWarn",
  ["In Review"] = "DiagnosticInfo",
  ["Done"] = "DiagnosticOk",
  ["Blocked"] = "DiagnosticError",
}

---Format issue item for display
---@param item snacks.picker.Item
---@param picker snacks.Picker
---@return snacks.picker.Highlight[]
function M.jira_issues(item, picker)
  local ret = {}

  -- Type badge with icon
  local type_icon = {
    Bug = "󰃤 ",
    Story = " ",
    Task = " ",
    Enhancement = " ",
    Epic = " ",
  }
  local icon = type_icon[item.type] or " "
  local type_hl = TYPE_HIGHLIGHTS[item.type] or "Comment"

  ret[#ret + 1] = { icon, type_hl }
  ret[#ret + 1] = { string.format("%-12s", item.type or "Unknown"), type_hl }
  ret[#ret + 1] = { " │ " }

  -- Issue key (bold)
  ret[#ret + 1] = { string.format("%-12s", item.key or ""), "Special" }
  ret[#ret + 1] = { " │ " }

  -- Assignee
  local assignee = item.assignee or "Unassigned"
  if assignee == "" then
    assignee = "Unassigned"
  end
  ret[#ret + 1] = { string.format("%-20s", assignee), "Identifier" }
  ret[#ret + 1] = { " │ " }

  -- Status badge
  local status = item.status or "Unknown"
  local status_hl = STATUS_HIGHLIGHTS[status] or "Comment"
  ret[#ret + 1] = { string.format("[%-12s]", status), status_hl }
  ret[#ret + 1] = { " │ " }

  -- Summary (main text)
  ret[#ret + 1] = { item.summary or "", "Normal" }

  -- Labels (if present)
  if item.labels and item.labels ~= "" then
    ret[#ret + 1] = { " " }
    local labels = vim.split(item.labels, ",")
    for i, label in ipairs(labels) do
      if i > 1 then
        ret[#ret + 1] = { ", ", "Comment" }
      end
      ret[#ret + 1] = { "", "Comment" }
      ret[#ret + 1] = { label, "Comment" }
    end
  end

  return ret
end

return M
