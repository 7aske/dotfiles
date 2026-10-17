-- Hostname-based AI completion:
--   mariner  -> local Minuet + Ollama FIM (qwen2.5-coder:7b)
--   voyager  -> GitHub Copilot (LazyVim extra)
--
-- On mariner: completions work when Ollama is up; silent no-op when it is not.

local host = (vim.uv or vim.loop).os_gethostname():gsub("%..*$", ""):lower()
local use_minuet = host == "mariner"
local use_copilot = host == "voyager"

local ollama_base = "http://127.0.0.1:11434"

return {
  -- LazyVim Copilot extra (only on voyager)
  {
    import = "lazyvim.plugins.extras.ai.copilot",
    enabled = use_copilot,
  },

  -- Keep Copilot disabled on mariner even if leftovers are installed
  { "zbirenbaum/copilot.lua", enabled = use_copilot },
  { "zbirenbaum/copilot-cmp", enabled = use_copilot },
  { "fang2hou/blink-copilot", enabled = use_copilot },

  {
    "milanglacier/minuet-ai.nvim",
    enabled = use_minuet,
    event = "InsertEnter",
    opts = {
      provider = "openai_fim_compatible",
      n_completions = 1,
      context_window = 1024,
      throttle = 800,
      debounce = 400,
      request_timeout = 2,
      -- false = no vim.notify at all (including Ollama down / curl errors)
      notify = false,
      curl_extra_args = { "--connect-timeout", "1", "--max-time", "3" },
      provider_options = {
        openai_fim_compatible = {
          api_key = "TERM",
          name = "Ollama",
          end_point = ollama_base .. "/v1/completions",
          -- 7b is much snappier for Tab; swap to :14b if you prefer quality over latency
          model = "qwen2.5-coder:7b",
          optional = {
            max_tokens = 64,
            top_p = 0.9,
          },
        },
      },
      virtualtext = {
        auto_trigger_ft = { "*" },
        auto_trigger_ignore_ft = {
          "snacks_picker_input",
          "TelescopePrompt",
          "DressingInput",
          "oil",
          "neo-tree-popup",
        },
        keymap = {
          -- Tab is handled by LazyVim.cmp.actions.ai_accept below
          accept = nil,
          accept_line = "<A-l>",
          next = "<M-]>",
          prev = "<M-[>",
          dismiss = "<A-e>",
        },
        show_on_completion_menu = false,
      },
    },
    config = function(_, opts)
      require("minuet").setup(opts)

      local ignore = opts.virtualtext.auto_trigger_ignore_ft or {}
      local ollama_up = false
      local last_check = 0
      local checking = false

      local function set_auto_trigger(buf, enabled)
        buf = buf or vim.api.nvim_get_current_buf()
        if not vim.api.nvim_buf_is_valid(buf) then
          return
        end
        local ft = vim.bo[buf].filetype
        if enabled and ft ~= "" and not vim.tbl_contains(ignore, ft) then
          vim.b[buf].minuet_virtual_text_auto_trigger = true
        else
          vim.b[buf].minuet_virtual_text_auto_trigger = false
        end
      end

      local function refresh_ollama()
        local now = vim.uv.now()
        if checking or (now - last_check) < 15000 then
          set_auto_trigger(nil, ollama_up)
          return
        end
        checking = true
        last_check = now
        vim.system(
          { "curl", "-sf", "--connect-timeout", "1", "--max-time", "1", ollama_base .. "/api/tags" },
          {},
          function(obj)
            vim.schedule(function()
              checking = false
              ollama_up = obj.code == 0
              set_auto_trigger(nil, ollama_up)
            end)
          end
        )
      end

      -- Minuet only arms auto-trigger on FileType; re-arm when Ollama is up.
      refresh_ollama()
      vim.api.nvim_create_autocmd({ "BufEnter", "FileType", "InsertEnter" }, {
        group = vim.api.nvim_create_augroup("minuet_auto_trigger_arm", { clear = true }),
        callback = function(ev)
          refresh_ollama()
          set_auto_trigger(ev.buf, ollama_up)
        end,
      })

      LazyVim.cmp.actions.ai_accept = function()
        local vt = require("minuet.virtualtext")
        if vt.action.is_visible() then
          LazyVim.create_undo()
          vt.action.accept()
          return true
        end
      end
    end,
  },
}
