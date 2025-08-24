local ls = require 'luasnip'
local s = ls.snippet
local sn = ls.snippet_node
local isn = ls.indent_snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local r = ls.restore_node
local events = require 'luasnip.util.events'
local ai = require 'luasnip.nodes.absolute_indexer'
local extras = require 'luasnip.extras'
local l = extras.lambda
local rep = extras.rep
local p = extras.partial
local m = extras.match
local n = extras.nonempty
local dl = extras.dynamic_lambda
local fmt = require('luasnip.extras.fmt').fmt
local fmta = require('luasnip.extras.fmt').fmta
local conds = require 'luasnip.extras.expand_conditions'
local postfix = require('luasnip.extras.postfix').postfix
local types = require 'luasnip.util.types'
local parse = require('luasnip.util.parser').parse_snippet
local ms = ls.multi_snippet
local k = require('luasnip.nodes.key_indexer').new_key
require('luasnip.session.snippet_collection').clear_snippets 'all'

-- local function surround(_, snip)
--   local res, env = {}, snip.env
--   for _, ele in ipairs(env.LS_SELECT_RAW) do
--     table.insert(res, '\\textbf{' .. ele .. '}')
--   end
--   return res
-- end

local printArgs = function(args, snip)
  local snipEnv = snip.env.SELECT_RAW
  local valueOfArgs = args
  local valueOfSnip = snip
  return 'text to print'
end
local functionNode = f(printArgs, {})
local key = 'run'
local snippet = s(key, functionNode)
local filetype = 'all'

ls.add_snippets(filetype, { snippet })

local func_template = [[
-- {}{}
function {}({})
	{}
end
]]

local function fn(
  args, -- text from i(2) in this example i.e. { { "456" } }
  parent, -- parent snippet or parent node
  user_args -- user_args from opts.user_args
)
  return '[' .. args[1][1] .. user_args .. ']'
end

ls.add_snippets('all', {
  -- important! fmt does not return a snippet, it returns a table of nodes.
  -- see where it has the value iNode1. and how we later set a key value pair
  -- to INode1. which then is equal to a insert node. the overall structure for
  -- the plugin seems to be a basic text and then a table of nodes. how this
  -- workes behind the secenes i have no clue about
  s(
    'example1',
    fmt('just an {iNode1}', {
      iNode1 = i(1, 'example'),
    })
  ),
  -- here we can see how they have not set certain values for
  -- the nodes. instead they are atutomatically numbered by
  -- the order that they came in
  s(
    'example2',
    fmt(
      [[
      if {} then
        {}
      end
      ]],
      {
        -- i(1) is at nodes[1], i(2) at nodes[2].
        i(1, 'not now'),
        i(2, 'when'),
      }
    )
  ),
  -- here is the same example as above but now we instead use the delimter <> compared to {}
  s(
    'example3',
    fmt(
      [[
      if <> then
        <>
      end
      ]],
      {
        -- i(1) is at nodes[1], i(2) at nodes[2].
        i(1, 'not now'),
        i(2, 'when'),
      },
      { -- notice how we are manually setting the delimeters in the ops argument here.
        -- also never really understood where i can find out what i can pass as opts.
        -- at least i know i can pass delimiter now. managed to find a list of the
        -- opts arguments in the documention inside neovim. was not to hard to find with search
        delimiters = '<>',
      }
    )
  ), -- with the value repeat duplicates both a will now be fileld with the same value.
  s(
    'example4',
    fmt(
      [[
      repeat {a} with the same key {a}
      ]],
      {
        a = i(1, 'this will be repeat'),
      },
      {
        repeat_duplicates = true,
      }
    )
  ), -- no clue what indent_string does. guessing it replaces the white space characters?

  s(
    'example5',
    fmt(
      [[
        line1: no indent
    
          line3: 2 space -> 1 indent ('\t')
            line4: 4 space -> 2 indent ('\t\t')
      ]],
      {},
      {
        indent_string = ' ',
      }
    )
  ),
  -- NOTE: [[\t]] means '\\t'
  s(
    'example6',
    fmt(
      [[
        line1: no indent
    
        \tline3: '\\t' -> 1 indent ('\t')
        \t\tline4: '\\t\\t' -> 2 indent ('\t\t')
      ]],
      {},
      {
        indent_string = [[\t]],
      }
    )
  ), -- if you indent the first line then run the command, the indentation stays for
  -- the first line. but the second line will be at the start with no indentation.
  s('isn', {
    isn(1, {
      t { 'This is indented as deep as the trigger', 'and this is at the beginning of the next line' },
    }, ''),
  }),
  -- seems like you can nest sinppet nodes. when this is usefull i have no clue
  -- for now it seems better to just use the fmt or fmta since its 10 times easier to read.
  s('trigger', {
    i(1, 'First jump'),
    t ' :: ',
    sn(2, {
      i(1, 'Second jump'),
      t ' : ',
      i(2, 'Third jump'),
    }),
  }),
  -- first node <-i(1) [text inside the function user_args_value] i(2)->text inside the function <-i(2) i(0)->end
  -- triggering this snippet below lets you first input the value to the left. then you get to input i(2) which is
  -- inside the arrows pointing to it. in my case i wrote "text inside the function". the function itself that is
  -- used is made at the top of this file. if you have an lsp use go to definition to find it. in that function
  -- a insteresting thing to not is that the argument are 2 dimensional arrays. where the first is the node itself
  -- and the second is the text it contains.
  s('trig', {
    i(1),
    t '<-i(1) ',
    f(
      fn, -- callback (args, parent, user_args) -> string
      { 2 }, -- node indice(s) whose text is passed to fn, i.e. i(2)
      { user_args = { 'user_args_value' } } -- opts
    ),
    t ' i(2)->',
    i(2),
    t '<-i(2) i(0)->',
    i(0),
  }),
  -- here do note that insert node 2 covers 2 lines, so when we type in something both lines dissepear.
  -- still very unsure what exactly the function is doing at this point.
  s('trig2', {
    i(1, 'text_of_first'),
    i(2, { 'first_line_of_second', 'second_line_of_second' }),
    f(function(args, snip)
      --here
      -- order is 2,1, not 1,2!!
    end, { 2, 1 }),
  }), -- this simply lets us toggle between 1st 2nd or 3rd.
  s(
    'cnode',
    c(1, {
      t '1st',
      t '2nd',
      t '3rd',
    })
  ), -- here is a very good example of how a simple function node works. here we return the current date.
  -- which then gets printed.
  s(
    'ii',
    f(function()
      return os.date '%y-%m-%d'
    end)
  ),
  -- here we have a better use case for function nodes. in this function we get the last name of
  -- what we are requiring and putting it as the variable name. i am also assuming that the first value
  -- which is the function gets mapped to jump node 1 automatically. meaning the part after local.
  s(
    'require',
    fmt('local {} = require("{}")', {
      f(function(values)
        local value = values[1][1]
        local path = vim.split(value, '%.')
        return path[#path]
      end, { 1 }),
      i(1),
    })
  ),
  s(
    'func',
    fmt(func_template, {
      i(1, 'this does some function'),
      f(function(values)
        vim.print(values)
        local param_str = values[1][1]
        if param_str == '' then
          return ''
        end
        param_str = param_str:gsub(' ', '')
        local params = vim.split(param_str, ',')
        local doc_comments = { '' }
        for _, param in ipairs(params) do
          table.insert(doc_comments, string.format('-- @param %s any <some description>', param))
        end
        vim.print(params)
        return doc_comments
      end, { 3 }),
      i(2, 'name'),
      i(3),
      i(4),
    })
  ),
})
