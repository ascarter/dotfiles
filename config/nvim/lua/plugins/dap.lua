return {
  -- DAP UI
  {
    "rcarriga/nvim-dap-ui",
    dependencies = {
      "mfussenegger/nvim-dap",
      "nvim-neotest/nvim-nio",
    },
    keys = {
      { "<leader>du", function() require("dapui").toggle() end, desc = "Toggle UI" },
      { "<leader>de", function() require("dapui").eval() end,   mode = { "n", "v" }, desc = "Evaluate" },
    },
    config = function()
      local dapui = require("dapui")
      dapui.setup()

      local dap                                          = require("dap")
      dap.listeners.before.launch.dapui_config           = function() dapui.open() end
      dap.listeners.before.attach.dapui_config           = function() dapui.open() end
      dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
      dap.listeners.before.event_exited.dapui_config     = function() dapui.close() end
    end,
  },

  -- Debug Adapter Protocol client
  {
    "mfussenegger/nvim-dap",
    keys = {
      { "<leader>db", function() require("dap").toggle_breakpoint() end,                         desc = "Toggle breakpoint" },
      { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input("Condition: ")) end, desc = "Conditional breakpoint" },
      { "<leader>dc", function() require("dap").continue() end,                                  desc = "Continue" },
      { "<leader>dC", function() require("dap").run_to_cursor() end,                             desc = "Run to cursor" },
      { "<leader>di", function() require("dap").step_into() end,                                 desc = "Step into" },
      { "<leader>do", function() require("dap").step_over() end,                                 desc = "Step over" },
      { "<leader>dO", function() require("dap").step_out() end,                                  desc = "Step out" },
      { "<leader>dp", function() require("dap").pause() end,                                     desc = "Pause" },
      { "<leader>dr", function() require("dap").restart() end,                                   desc = "Restart" },
      { "<leader>dt", function() require("dap").terminate() end,                                 desc = "Terminate" },
      { "<leader>dl", function() require("dap").run_last() end,                                  desc = "Run last" },
      { "<leader>dR", function() require("dap").repl.open() end,                                 desc = "Open REPL" },
      -- F-key aliases (VS Code / Zed muscle memory)
      { "<F5>",       function() require("dap").continue() end,                                  desc = "DAP continue" },
      { "<F9>",       function() require("dap").toggle_breakpoint() end,                         desc = "DAP toggle breakpoint" },
      { "<F10>",      function() require("dap").step_over() end,                                 desc = "DAP step over" },
      { "<F11>",      function() require("dap").step_into() end,                                 desc = "DAP step into" },
      { "<F12>",      function() require("dap").step_out() end,                                  desc = "DAP step out" },
    },
    config = function()
      local dap = require("dap")

      -- Signs
      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DapBreakpoint" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DapBreakpoint" })
      vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DapStopped", linehl = "DapStopped" })

      -- ── Adapters ──────────────────────────────────────────────────────────────
      -- Adapters connect nvim-dap to the debug binary. Launch configurations
      -- are defined per-project in .vscode/launch.json (read automatically).
      --
      -- Debug binaries installed via Mason ensure_installed in mason.lua

      -- Rust / C / C++ — codelldb
      -- Resolve path directly from Mason's known package layout rather than
      -- using mason-registry API (avoids registry-index loading timing issues
      -- and API changes in mason-org v2).
      local codelldb = vim.fn.stdpath("data") .. "/mason/packages/codelldb/extension/adapter/codelldb"
      if vim.fn.filereadable(codelldb) == 1 then
        dap.adapters.codelldb = {
          type = "server",
          port = "${port}",
          executable = {
            command = codelldb,
            args    = { "--port", "${port}" },
          },
        }
      end

      -- Go — delve
      -- dlv is on PATH via Mason's bin shim (~/.local/share/nvim/mason/bin)
      dap.adapters.delve = {
        type = "server",
        port = "${port}",
        executable = {
          command  = "dlv",
          args     = { "dap", "-l", "127.0.0.1:${port}" },
          detached = vim.fn.has("win32") == 0,
        },
      }
    end,
  },
}
