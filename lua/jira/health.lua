local M = {}

function M.check()
  vim.health.start("jira.nvim")

  local nvim_version = vim.version()
  local required_version = { 0, 11, 0 }
  local version_ok = nvim_version.major > required_version[1]
    or (nvim_version.major == required_version[1] and nvim_version.minor >= required_version[2])

  if version_ok then
    vim.health.ok(
      string.format("Neovim version %d.%d.%d >= 0.11.0", nvim_version.major, nvim_version.minor, nvim_version.patch)
    )
  else
    vim.health.error(
      string.format("Neovim version %d.%d.%d < 0.11.0", nvim_version.major, nvim_version.minor, nvim_version.patch),
      "Upgrade to Neovim 0.11.0 or later"
    )
  end

  -- Check snacks.nvim
  local has_snacks = pcall(require, "snacks")
  if has_snacks then
    vim.health.ok("snacks.nvim is installed")
  else
    vim.health.error("snacks.nvim is not installed", "Install snacks.nvim: https://github.com/folke/snacks.nvim")
  end

  -- Check jira CLI
  local util = require("jira.util")
  if util.has_jira_cli() then
    vim.health.ok("jira CLI is installed")
  else
    vim.health.error("jira CLI is not installed", "Install jira CLI: https://github.com/ankitpokhrel/jira-cli")
  end
end

return M
