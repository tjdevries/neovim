-- Implements the following default callbacks:
--  textDocument/publishDiagnostics
--  notification: textDocument/didOpen
--  notification: textDocument/willSave
--  TODO: textDocument/willSaveWaitUntil
--  notification: textDocument/didSave
--  notification: textDocument/didClose
--  IN PROGRESS: textDocument/completion
--  textDocument/hover
--  TODO: textDocument/signatureHelp
--  textDocument/references
--  TODO: textDocument/documentHighlight
--  TODO: textDocument/documentSymbol
--  TODO: textDocument/formatting
--  TODO: textDocument/rangeFormatting
--  TODO: textDocument/onTypeFormatting
--  textDocument/definition
--  TODO: textDocument/codeAction
--  TODO: textDocument/codeLens
--  TODO: textDocument/documentLink
--  TODO: textDocument/rename
--
--  TODO: completionItem/resolve
--
--  TODO: codeLens/resolve
--
--  TODO: documentLink/resolve

local log = require('lsp.log')
local util = require('neovim.util')
local lsp_util = require('lsp.util')

local protocol = require('lsp.protocol')
local handle_completion = require('lsp.handle.completion')

local error_callback = require('lsp.config.callbacks').error_callback

local cb = {}
cb.textDocument = {}

cb.textDocument.publishDiagnostics = { function(success, data)
  if not success then
    error_callback('textDocument/publishDiagnostics', data)
    return nil
  end

  local loclist = {}

  for _, diagnostic in ipairs(data.diagnostics) do
    local range = diagnostic.range
    local severity = diagnostic.severity or protocol.DiagnosticSeverity.Information

    local message_type
    if severity == protocol.DiagnosticSeverity.Error then
      message_type = 'E'
    elseif severity == protocol.DiagnosticSeverity.Warning then
      message_type = 'W'
    else
      message_type = 'I'
    end

    -- local code = diagnostic.code
    local source = diagnostic.source or 'lsp'
    local message = diagnostic.message

    table.insert(loclist, {
      lnum = range.start.line + 1,
      col = range.start.character + 1,
      text = '[' .. source .. ']' .. message,
      filename = lsp_util.get_filename(data.uri),
      ['type'] = message_type,
    })
  end

  local result = vim.api.nvim_call_function('setloclist', {0, loclist})

  -- if loclist ~= {} and not util.is_loclist_open() then
  --   vim.api.nvim_command('lopen')
  --   vim.api.nvim_command('wincmd p')
  -- end

  return result
end }

cb.textDocument.completion = { function(success, data)
  if not success then
    error_callback('textDocument/completion', data)
    return nil
  end

  if data == nil then
    return
  end

  return handle_completion.getLabels(data)
end }

cb.textDocument.references = { function(success, data)
  if not success then
    error_callback('textDocument/references', data)
    return nil
  end

  local locations = data
  local loclist = {}

  for _, loc in ipairs(locations) do
    -- TODO: URL parsing here?
    local path = util.handle_uri(loc["uri"])
    local start = loc.range.start
    local line = start.line + 1
    local character = start.character + 1

    local text = util.get_file_line(path, line)

    table.insert(loclist, {
        filename = path,
        lnum = line,
        col = character,
        text = text,
    })
  end

  local result = vim.api.nvim_call_function('setloclist', {0, loclist})

  if loclist ~= {} and not util.is_loclist_open() then
    vim.api.nvim_command('lopen')
  else
    vim.api.nvim_command('lclose')
  end

  return result
end }

cb.textDocument.hover = { function(success, data)
  log.trace('textDocument/hover', data)

  if not success then
    error_callback('textDocument/hover', data)
    return nil
  end

  if data.range ~= nil then
    -- Doesn't handle multi-line highlights
    local _ = vim.api.nvim_buf_add_highlight(0,
      -1,
      'Error',
      data.range.start.line,
      data.range.start.character,
      data.range['end'].character
    )
  end

  -- TODO: Use floating windows when they become available
  local long_string = ''
  if data.contents ~= nil then
    if util.is_array(data.contents) == true then
      for _, item in ipairs(data.contents) do
        local value
        if type(item) == 'table' then
          value = item.value
        elseif item == nil then
          value = ''
        else
          value = item
        end

        long_string = long_string .. value .. "\n"
      end

      log.debug('Hover: ', long_string)
      -- vim.api.nvim_out_write(long_string)
    elseif type(data.contents) == 'table' then
      long_string = long_string .. data.contents.value
    else
      long_string = data.contents
    end

    vim.api.nvim_command('echon "' .. long_string .. '"')
    return long_string
  end

end }

cb.textDocument.definition = { function(success, data)
  log.trace('callback:textDocument/definiton', data)

  if not success then
    error_callback('textDocument/definition', data)
    return nil
  end

  if data == nil or data == {} then
    log.info('No definition found')
    return nil
  end

  local current_file = vim.api.nvim_call_function('expand', {'%'})

  -- We can sometimes get a list of locations,
  -- so set the first value as the only value we want to handle
  if data[1] ~= nil then
    data = data[1]
  end

  if data.uri == nil then
    vim.api.nvim_err_writeln('[LSP] Could not find a valid definition')
    return
  end

  if type(data.uri) ~= 'string' then
    vim.api.nvim_err_writeln('Invalid uri')
    return
  end

  local data_file = lsp_util.get_filename(data.uri)

  if data_file ~= lsp_util.get_uri(current_file) then
    vim.api.nvim_command('silent edit ' .. data_file)
  end

  vim.api.nvim_command(
    string.format('normal! %sG%s|'
      , data.range.start.line + 1
      , data.range.start.character + 1
    )
  )

  return true
end }

local get_list_of_callbacks = function(method, callback_parameter) -- {{{
  local method_table
  if type(method) == 'string' then
    method_table = util.split(method, '/')
  elseif type(method) == 'table' then
    method_table = method
  else
    return nil
  end

  -- If they haven't passed a callback parameter, then fiull with a default
  if callback_parameter == nil then
    local callback_func = cb

    for _, key in ipairs(method_table) do
      callback_func = callback_func[key]

      if callback_func == nil then
        break
      end
    end

    if type(callback_func) ~= 'table' then
      return nil
    end

    return callback_func
  elseif type(callback_parameter) == 'table' then
    return callback_parameter
  elseif type(callback_parameter) == 'function' then
    return { callback_parameter }
  elseif type(callback_parameter) == 'string' then
    -- When we pass a string, that's a VimL function that we want to call
    -- so we create a callback function to run it.
    --
    --      See: |lsp#request()|
    return {
      function(success, data)
        return vim.api.nvim_call_function(callback_parameter, {success, data})
      end
    }
  end

  return nil
end -- }}}

local call_callbacks = function(callback_list, success, params)
  local results = {}
  for key, callback in pairs(callback_list) do
    results[key] = callback(success, params)
  end

  return results
end

return {
  callbacks = cb,
  get_list_of_callbacks = get_list_of_callbacks,
  call_callbacks = call_callbacks,
}
