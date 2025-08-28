local pickers = require 'telescope.pickers'
local finders = require 'telescope.finders'
local make_entry = require 'telescope.make_entry'
local conf = require('telescope.config').values
local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'
local M = {}

M.live_multigrep = function(opts)
  opts = opts or {}
  opts.cwd = opts.cwd or vim.uv.cwd()
  local finder = finders.new_async_job {
    command_generator = function(prompt)
      if not prompt or prompt == '' then
        return nil
      end

      local pieces = vim.split(prompt, '  ')
      local args = { 'rg' }
      if pieces[1] then
        table.insert(args, '-e')
        table.insert(args, pieces[1])
      end

      if pieces[2] then
        table.insert(args, '-g')
        table.insert(args, pieces[2])
      end
      ---@diagnostic disable-next-line: deprecated
      return vim.tbl_flatten {
        args,
        { '--color=never', '--no-heading', '--with-filename', '--line-number', '--column', '--smart-case' },
      }
    end,
    entry_maker = make_entry.gen_from_vimgrep(opts),
    cwd = opts.cwd,
  }

  pickers
    .new(opts, {
      debounce = 100,
      prompt_title = 'multi grep',
      finder = finder,
      previewer = conf.grep_previewer(opts),
      sorter = require('telescope.sorters').empty(),
    })
    :find()
end

local M = {}

function M.getChangedfiles(opts)
  opts = opts or {}

  local git_root = vim.fn.systemlist('git rev-parse --show-toplevel')[1]
  if not git_root or git_root == '' or string.find(git_root, 'fatal') then
    vim.notify('Not in a git repo', vim.log.levels.WARN)
    return
  end

  local dirty = vim.fn.systemlist 'git status --porcelain'
  local files = {}

  for _, line in ipairs(dirty) do
    local rel_path = string.sub(line, 4)
    table.insert(files, rel_path)
  end

  pickers
    .new(opts, {
      prompt_title = 'Git Working Files',
      finder = finders.new_table { results = files },
      sorter = conf.generic_sorter(opts),
      cwd = git_root,

      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection and selection.value then
            local full_path = git_root .. '/' .. selection.value
            vim.cmd('edit ' .. vim.fn.fnameescape(full_path))
          end
        end)
        return true
      end,
    })
    :find()
end

M.getChangedfiles()
return M
