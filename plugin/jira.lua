-- User commands
vim.api.nvim_create_user_command("JiraIssues", function()
  require("jira").issues()
end, {
  desc = "Open JIRA issues picker for current sprint",
})
