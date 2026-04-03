local dap = require("dap")

-- Signs
vim.fn.sign_define("DapBreakpoint",          { text = "●", texthl = "DapBreakpoint" })
vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DapBreakpoint" })
vim.fn.sign_define("DapStopped",             { text = "▶", texthl = "DapStopped", linehl = "DapStopped" })

-- ── Adapters ──────────────────────────────────────────────────────────────────
-- Adapters connect nvim-dap to the debug binary. Launch configurations
-- are defined per-project in .vscode/launch.json (read automatically).
--
-- Debug binaries installed via Mason ensure_installed in lsp.lua

-- Rust / C / C++ — codelldb
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
dap.adapters.delve = {
  type = "server",
  port = "${port}",
  executable = {
    command  = "dlv",
    args     = { "dap", "-l", "127.0.0.1:${port}" },
    detached = vim.fn.has("win32") == 0,
  },
}

-- ── DAP UI ────────────────────────────────────────────────────────────────────
local dapui = require("dapui")
dapui.setup()

dap.listeners.before.launch.dapui_config           = function() dapui.open() end
dap.listeners.before.attach.dapui_config           = function() dapui.open() end
dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
dap.listeners.before.event_exited.dapui_config     = function() dapui.close() end

-- ── Keymaps ───────────────────────────────────────────────────────────────────
local map = function(lhs, rhs, desc)
  vim.keymap.set("n", lhs, rhs, { silent = true, desc = desc })
end

map("<leader>db", dap.toggle_breakpoint, "Toggle breakpoint")
map("<leader>dB", function() dap.set_breakpoint(vim.fn.input("Condition: ")) end, "Conditional breakpoint")
map("<leader>dc", dap.continue,      "Continue")
map("<leader>dC", dap.run_to_cursor, "Run to cursor")
map("<leader>di", dap.step_into,     "Step into")
map("<leader>do", dap.step_over,     "Step over")
map("<leader>dO", dap.step_out,      "Step out")
map("<leader>dp", dap.pause,         "Pause")
map("<leader>dr", dap.restart,       "Restart")
map("<leader>dt", dap.terminate,     "Terminate")
map("<leader>dl", dap.run_last,      "Run last")
map("<leader>dR", function() dap.repl.open() end, "Open REPL")
map("<leader>du", dapui.toggle,      "Toggle UI")
vim.keymap.set({ "n", "v" }, "<leader>de", dapui.eval, { silent = true, desc = "Evaluate" })

-- F-key aliases (VS Code / Zed muscle memory)
map("<F5>",  dap.continue,          "DAP continue")
map("<F9>",  dap.toggle_breakpoint, "DAP toggle breakpoint")
map("<F10>", dap.step_over,         "DAP step over")
map("<F11>", dap.step_into,         "DAP step into")
map("<F12>", dap.step_out,          "DAP step out")
