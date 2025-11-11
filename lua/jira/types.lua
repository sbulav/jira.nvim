---@class jira.CliConfig
---@field cmd string Path to jira CLI binary
---@field args string[] Default CLI arguments for sprint list

---@class jira.QueryConfig
---@field columns string[] Columns to display
---@field filters string[] Default filters for sprint list
---@field order_by string Sort order field

---@class jira.DisplayConfig
---@field type_icons table<string, string> Icons for issue types
---@field type_highlights table<string, string> Highlight groups for issue types
---@field status_highlights table<string, string> Highlight groups for statuses
---@field preview_comments number Number of comments to show in preview (default: 0)

---@class jira.KeymapsInput
---@field copy_key string Keymap to copy issue key in input mode
---@field transition string Keymap to transition issue in input mode

---@class jira.KeymapsList
---@field actions string Keymap to open actions dialog in list mode
---@field copy_key string Keymap to copy issue key in list mode
---@field transition string Keymap to transition issue in list mode

---@class jira.Keymaps
---@field input jira.KeymapsInput Keymaps for input focus mode
---@field list jira.KeymapsList Keymaps for list focus mode

---@class jira.Config
---@field cli jira.CliConfig CLI settings
---@field query jira.QueryConfig Query settings
---@field display jira.DisplayConfig Display settings
---@field keymaps jira.Keymaps Custom keymaps
---@field debug boolean Enable debug mode to print CLI commands
