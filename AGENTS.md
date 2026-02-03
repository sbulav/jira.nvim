# AGENTS.md for jira.nvim

## Project Overview
jira.nvim is a Neovim plugin for browsing and managing JIRA issues using a fuzzy-finding interface powered by snacks.nvim. It integrates with the jira-cli tool for API interactions and provides features like issue searching, creation, editing, transitions, and caching via SQLite. The codebase is written in Lua, organized under `lua/jira/` with submodules for util, git, cli, cache, etc. Tests are in `tests/` using Busted framework (via plenary.nvim patterns). No JavaScript/TypeScript components; purely Lua-based. Repository structure includes `lua/`, `tests/`, `plugin/`, and config files like `stylua.toml`. No build step required—install via plugin managers like lazy.nvim.

Key dependencies:
- Neovim >= 0.11.0
- snacks.nvim (core UI/picker)
- jira-cli (external binary for JIRA API)
- Optional: render-markdown.nvim for previews

No AGENTS.md exists currently. This document summarizes development practices inferred from codebase analysis, README.md, and tools. Aim: Standardize contributions for consistency, especially for AI-assisted coding (e.g., Cursor, Copilot).

## Repository Structure
- `lua/jira/`: Core plugin logic
  - `init.lua`: Main entrypoint, setup, commands
  - `config.lua`: Default options table
  - `cli.lua`: Wrapper for jira-cli execution
  - `cache.lua`: SQLite-based data caching
  - `git.lua`: Git branch utilities
  - `util.lua`: Helpers (e.g., validation, notification)
  - `fetchers.lua`: Data fetching from CLI
  - `picker/`: UI components (sources, actions, previewers, formatters)
  - `actions/`: Individual actions (e.g., transition.lua, create_issue.lua)
  - `buf.lua`: Buffer handling for issue views
  - `health.lua`: :checkhealth implementation
  - `markdown.lua`: Markdown processing
  - `types.lua`: Type definitions (tables)
- `tests/`: Busted specs
  - `*_spec.lua`: Unit tests for modules (e.g., git_spec.lua, cli_spec.lua)
- `plugin/jira.lua`: Autoload script
- `stylua.toml`: Formatter config
- `README.md`: User docs (features, setup, keymaps)
- No `.luacheckrc`, no CI workflows found (.github/workflows empty)

## Build and Installation
No compilation or build process—pure Lua plugin.
- Install via lazy.nvim (see README.md example).
- Development setup:
  1. Clone repo: `git clone https://github.com/l-lin/jira.nvim ~/.local/share/nvim/lazy/jira.nvim`
  2. Add to lazy.nvim spec with `dev = true` for local path.
  3. Ensure jira-cli installed: `go install github.com/ankitpokhrel/jira-cli@latest` and `jira init`.
  4. Test in Neovim: `:Lazy sync` then `:JiraIssues`.
- No Makefile or package.json; no npm/yarn build.
- Cache dir: `~/.local/share/nvim/jira/` (SQLite file auto-created).

For releases: Tag and push; lazy.nvim handles lazy-loading.

## Testing
Uses Busted testing framework (integrated via plenary.nvim patterns in specs). Tests are unit-focused, mocking vim APIs (e.g., vim.system, vim.notify).

### Running Tests
- Full suite: From repo root, run Neovim in headless mode with plenary's busted runner:
  ```
  nvim --headless -c 'PlenaryBustedDirectory tests/ { minimal_init = "init.lua" }' -c 'qall!'
  ```
  - `init.lua` should minimally load plenary: `vim.opt.rtp:prepend(vim.fn.expand("$HOME") .. "/.local/share/nvim/lazy/plenary.nvim")` (adjust path).
- Verbose output: Add `{ verbose = true }`.
- No integration/e2e tests found; all unit (e.g., git sanitization, CLI execution mocks).

### Running a Single Test
- Specific file: `nvim --headless -c "PlenaryBustedFile tests/git_spec.lua { minimal_init = 'init.lua' } " -c 'qall!'`
- Specific describe/it block: Use Busted's filtering:
  ```
  nvim --headless -c 'PlenaryBustedDirectory tests/ { minimal_init = "init.lua", filter = "sanitize_for_branch" }' -c 'qall!'
  ```
  - Filter by describe/it name (e.g., "Git Utilities" or "should replace spaces").
- Mock setup in specs: Overrides vim.notify, vim.system, vim.schedule for isolation.
- Assertions: Standard Lua (e.g., `assert.equals(expected, actual)`).
- Coverage: No tools configured; run manually or add `luacov` via plenary.

Tips: Ensure plenary.nvim in runtimepath. Tests mock external deps (jira-cli via vim.system stubs). Fix failing tests by running individually.

## Linting and Formatting
No `.luacheckrc` found—use manual luacheck or none enforced.
- **Linting**: Run `luacheck lua/ tests/` manually. Common issues: unused locals, globals. Enforce via pre-commit hook if adding CI.
- **Formatting**: Stylua configured in `stylua.toml`.
  - Run: `stylua lua/ tests/`
  - Config:
    - Indent: Spaces, width 2
    - Line length: 120 columns
    - Sort requires: Enabled (alphabetical local requires)
  - Pre-commit: Add `stylua --check lua/ tests/` to hooks.
- No ESLint/Prettier (no JS). For Lua types: Manual via `types.lua`; consider lua-language-server for IDE linting.

## Code Style Guidelines
Inferred from codebase patterns (e.g., grep for require/local/function/error). Follow Lua LSP best practices; aim for readability in Neovim context.

### Imports/Requires
- Use `local` for all requires (no global pollution).
- Alphabetical sorting: Enabled by stylua.toml—`local a = require("a") \n local b = require("b")`.
- Relative paths: `local git = require("jira.git")` (modular under jira namespace).
- Avoid `require` in loops/hot paths; prefer lazy-loading where possible (e.g., actions).
- No dynamic requires; static for tree-shaking.

Example:
```lua
local config = require("jira.config")
local cli = require("jira.cli")
local util = require("jira.util")
```

### Functions and Structure
- Descriptive names: snake_case (e.g., `sanitize_for_branch`, `generate_branch_name`).
- Short functions: <50 lines; single responsibility (e.g., actions in separate files).
- Modules return tables: e.g., `return { sanitize_for_branch = ..., ... }`.
- Describe/it in tests: Clear, focused (e.g., "should replace spaces with underscores").
- Avoid side-effects: Pure functions where possible; mock externalities in tests.

### Types and Validation
- Use `types.lua` for table shapes (e.g., issue keys, configs).
- Validate inputs: `util.validate(spec)` with error on mismatch (type, nil checks).
- Typed tables: Comment shapes, e.g., `{ key = "string", summary = "string?" }`.
- Optional params: Use `or` defaults, e.g., `local summary = summary or ""`.
- No strict typing (Lua); document with `-- @param issue_key string`.

Example validation:
```lua
local function validate(spec)
  for name, def in pairs(spec) do
    local value = ... -- extract
    if not optional and value == nil then
      error(string.format("%s: expected %s, got nil", name, expected_type))
    end
  end
end
```

### Naming Conventions
- Variables/functions: snake_case (e.g., `issue_key`, `open_jira_issues`).
- Modules/files: kebab or underscore (e.g., `start_work.lua`).
- Constants: UPPER_SNAKE_CASE (rare; e.g., cache paths).
- Locals: Descriptive, avoid single-letter except loops (`for i, v in ipairs(items) do`).
- Avoid Hungarian notation; Lua is dynamic.

### Error Handling
- Use `pcall` for risky ops (e.g., CLI execution, SQLite).
- Notify user: `vim.notify(msg, vim.log.levels.ERROR)` for failures.
- Graceful degradation: Return nil/empty on errors, log via notify.
- No raw `error()` in hot paths; wrap in notify + return.
- CLI errors: Capture stdout/stderr from vim.system, parse for user-friendly msgs.
- Cache misses: Fallback to fetch + cache.

Example:
```lua
local ok, result = pcall(cli.execute, cmd)
if not ok then
  vim.notify("CLI failed: " .. result, vim.log.levels.ERROR)
  return {}
end
```

### Formatting and Whitespace
- Follow stylua.toml: 2-space indents, 120-col lines.
- Trailing commas: Optional, but consistent in tables.
- Comments: `--` for inline; `-- @section` for docs (e.g., in config.lua).
- No trailing whitespace; empty lines between sections.

### UI and Keymaps
- Keymaps: Configurable via `opts.keymaps`; defaults in picker (e.g., `<CR>` for actions).
- Icons/colors: Customizable; use `ui.icons` table.
- Buffers: Read-only for views (`jira://KEY`); autocmds for setup.

## AI/Copilot/Cursor Rules
No `.cursor/rules/`, `.cursorrules`, or `.github/copilot-instructions.md` found. Suggested rules for AI tools:

### General Rules
- Generate Lua code only; match snake_case, local requires.
- Always validate inputs with types from `types.lua`.
- Use vim.notify for all user feedback (INFO/WARN/ERROR).
- Mock vim APIs in tests (system, schedule, notify).
- Keep functions <30 lines; extract helpers.

### Cursor-Specific (.cursor/rules/)
If adding: Create `.cursor/rules/` with .mdc files.
- Rule: "Prefer modular requires under jira namespace."
- Rule: "Error handling: pcall + notify, no raw errors."
- Rule: "Tests: Use describe/it, mock externalities."

### Copilot Instructions (.github/copilot-instructions.md)
Suggested content:
```
# Copilot Guidelines for jira.nvim
- Namespace all exports under require("jira.module").
- Use 2-space indents; sort requires alphabetically.
- For actions: Return { execute = function(ctx) ... end }.
- CLI calls: Wrap in pcall, handle non-zero exits.
- Cache ops: Use sqlite3 module; invalidate on mutations.
- Avoid globals; all locals.
- Tests: before_each/after_each for mocks.
```

## Contribution Workflow
1. Fork/clone; branch: `feat/short-desc`.
2. Format: `stylua .`
3. Test: Run suite/single as above.
4. Lint: `luacheck lua/`
5. Commit: Conventional (e.g., "feat: add transition action").
6. PR: Describe changes, link issues; no force-push to main.
7. Health: Run `:checkhealth jira` post-changes.

## Potential Improvements
- Add .luacheckrc for globals (e.g., vim, require).
- CI: GitHub Actions for stylua check, busted run.
- Docs: Expand README with dev section (testing, style).
- Types: Integrate lua-types.nvim or full shapes.
- Single test: Add script (e.g., `run_test.sh`).

This AGENTS.md is ~150 lines; expand as needed. For questions, check README or code patterns.

(End of document)
