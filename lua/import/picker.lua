local actions = require("telescope.actions")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local conf = require("telescope.config").values
local action_state = require("telescope.actions.state")
local utils = require("import.utils")
local default_languages = require("import.languages")
local find_imports = require("import.find_imports")
local insert_line = require("import.insert_line")
local update_path = require("import.update_path")

local function is_relative(import_path)
  -- Check if the import path is relative or absolute
  return import_path:match("^%.%./") or import_path:match("^%./") or import_path:match("^/")
end

local function picker(opts)
  local languages = utils.table_concat(default_languages, opts.custom_languages)

  local imports = find_imports(languages)

  if imports == nil then
    vim.notify("Filetype not supported", vim.log.levels.ERROR)
    return nil
  end

  if next(imports) == nil then
    vim.notify("No imports found", vim.log.levels.INFO)
    return nil
  end

  pickers
    .new(opts, {
      prompt_title = "Imports",
      sorter = conf.generic_sorter(opts),
      finder = finders.new_table({
        results = imports,
        entry_maker = function(import)
          return {
            value = import.value,
            display = import.value,
            ordinal = import.value,
            path = import.path,
          }
        end,
      }),
      attach_mappings = function(prompt_bufnr, _)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          local import_path = utils.extract_path(selection.value)

          if is_relative(import_path) then
            local current_path = vim.fn.expand("%:p")
            local sel_path = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
              .. "/"
              .. selection.path
            local updated_path = update_path(import_path, sel_path, current_path)
            import_path = utils.replace_in_quotes(selection.value, updated_path)
          end

          insert_line(import_path, opts.insert_at_top)
        end)
        return true
      end,
    })
    :find()
end

return picker
