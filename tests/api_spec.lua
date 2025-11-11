---@module 'luassert'

-- Mock vim global if not available
if not _G.vim then
  _G.vim = {
    list_extend = function(dst, src)
      for _, v in ipairs(src) do
        table.insert(dst, v)
      end
      return dst
    end,
    notify = function() end,
    log = {
      levels = {
        INFO = 1,
        WARN = 2,
        ERROR = 3,
      },
    },
  }
end

describe("api", function()
  local api
  local notify_called
  local notify_message

  before_each(function()
    -- Clear package cache
    package.loaded["jira.api"] = nil
    package.loaded["jira.util"] = nil
    package.loaded["jira.config"] = nil

    -- Reset notify tracking
    notify_called = false
    notify_message = nil

    -- Mock vim.notify to track calls
    vim.notify = function(msg, level)
      notify_called = true
      notify_message = msg
    end

    -- Mock jira.util
    package.loaded["jira.util"] = {
      has_jira_cli = function()
        return true
      end,
    }
  end)

  after_each(function()
    -- Clean up
    package.loaded["jira.api"] = nil
    package.loaded["jira.util"] = nil
    package.loaded["jira.config"] = nil
  end)

  describe("build_jira_args", function()
    it("should build basic args with default config", function()
      -- Mock config with defaults
      package.loaded["jira.config"] = {
        options = {
          cli = {
            cmd = "jira",
          },
          query = {
            filters = { "--assignee", "me" },
            order_by = "created",
            paginate = "100",
            columns = { "key", "summary", "status" },
          },
          debug = false,
        },
      }

      api = require("jira.api")
      local args = api.build_jira_args()

      local expected = {
        "sprint",
        "list",
        "--current",
        "--assignee",
        "me",
        "--order-by",
        "created",
        "--paginate",
        "100",
        "--csv",
        "--columns",
        "key,summary,status",
      }

      assert.are.same(expected, args)
    end)

    it("should handle custom filters", function()
      package.loaded["jira.config"] = {
        options = {
          cli = { cmd = "jira" },
          query = {
            filters = { "--status", "In Progress", "--priority", "High" },
            order_by = "updated",
            paginate = "50",
            columns = { "key", "summary" },
          },
          debug = false,
        },
      }

      api = require("jira.api")
      local args = api.build_jira_args()

      assert.are.equal("--status", args[4])
      assert.are.equal("In Progress", args[5])
      assert.are.equal("--priority", args[6])
      assert.are.equal("High", args[7])
    end)

    it("should handle custom order_by", function()
      package.loaded["jira.config"] = {
        options = {
          cli = { cmd = "jira" },
          query = {
            filters = {},
            order_by = "priority",
            paginate = "100",
            columns = { "key" },
          },
          debug = false,
        },
      }

      api = require("jira.api")
      local args = api.build_jira_args()

      local order_idx = nil
      for i, v in ipairs(args) do
        if v == "--order-by" then
          order_idx = i
          break
        end
      end

      assert.is_not_nil(order_idx)
      assert.are.equal("priority", args[order_idx + 1])
    end)

    it("should handle custom paginate", function()
      package.loaded["jira.config"] = {
        options = {
          cli = { cmd = "jira" },
          query = {
            filters = {},
            order_by = "created",
            paginate = "200",
            columns = { "key" },
          },
          debug = false,
        },
      }

      api = require("jira.api")
      local args = api.build_jira_args()

      local paginate_idx = nil
      for i, v in ipairs(args) do
        if v == "--paginate" then
          paginate_idx = i
          break
        end
      end

      assert.is_not_nil(paginate_idx)
      assert.are.equal("200", args[paginate_idx + 1])
    end)

    it("should handle custom columns", function()
      package.loaded["jira.config"] = {
        options = {
          cli = { cmd = "jira" },
          query = {
            filters = {},
            order_by = "created",
            paginate = "100",
            columns = { "key", "summary", "assignee", "priority" },
          },
          debug = false,
        },
      }

      api = require("jira.api")
      local args = api.build_jira_args()

      local columns_idx = nil
      for i, v in ipairs(args) do
        if v == "--columns" then
          columns_idx = i
          break
        end
      end

      assert.is_not_nil(columns_idx)
      assert.are.equal("key,summary,assignee,priority", args[columns_idx + 1])
    end)

    it("should call vim.notify when debug is enabled", function()
      package.loaded["jira.config"] = {
        options = {
          cli = { cmd = "jira" },
          query = {
            filters = {},
            order_by = "created",
            paginate = "100",
            columns = { "key" },
          },
          debug = true,
        },
      }

      api = require("jira.api")
      api.build_jira_args()

      assert.is_true(notify_called)
      assert.is_not_nil(notify_message)
      assert.is_true(notify_message:match("JIRA CLI Command") ~= nil)
    end)

    it("should not call vim.notify when debug is disabled", function()
      package.loaded["jira.config"] = {
        options = {
          cli = { cmd = "jira" },
          query = {
            filters = {},
            order_by = "created",
            paginate = "100",
            columns = { "key" },
          },
          debug = false,
        },
      }

      api = require("jira.api")
      api.build_jira_args()

      assert.is_false(notify_called)
    end)

    it("should handle empty filters", function()
      package.loaded["jira.config"] = {
        options = {
          cli = { cmd = "jira" },
          query = {
            filters = {},
            order_by = "created",
            paginate = "100",
            columns = { "key" },
          },
          debug = false,
        },
      }

      api = require("jira.api")
      local args = api.build_jira_args()

      assert.are.equal("sprint", args[1])
      assert.are.equal("list", args[2])
      assert.are.equal("--current", args[3])
      assert.are.equal("--order-by", args[4])
    end)

    it("should error when jira CLI is not available", function()
      -- Mock util to return false
      package.loaded["jira.util"] = {
        has_jira_cli = function()
          return false
        end,
      }

      package.loaded["jira.config"] = {
        options = {
          cli = { cmd = "jira" },
          query = {
            filters = {},
            order_by = "created",
            paginate = "100",
            columns = { "key" },
          },
          debug = false,
        },
      }

      api = require("jira.api")

      assert.has_error(function()
        api.build_jira_args()
      end, "JIRA CLI not found. Please install: https://github.com/ankitpokhrel/jira-cli")
    end)
  end)
end)
