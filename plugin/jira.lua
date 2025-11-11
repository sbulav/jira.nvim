vim.api.nvim_create_user_command(
  "JiraIssues",
  require("jira").open_jira_issues,
  { desc = "Open JIRA issues picker for current sprint" }
)
