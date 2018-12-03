local util = require('nvim.util')

local lsp_util = {}

lsp_util.get_filetype = function(filetype)
  if not filetype then
    filetype = vim.api.nvim_buf_get_option(0, 'filetype')
  end

  return filetype
end

lsp_util.get_uri = function(filename)
  local volume_start, volume_end
  if vim.api.nvim_call_function('has', {'win32'}) == 1 then
    filename = '/' .. string.gsub(filename, '\\', '/')
    volume_start, volume_end = string.find(filename, '^/[a-zA-Z]:')
  end
  volume_start = volume_start or 0
  volume_end = volume_end or 0
  return 'file://' .. string.sub(filename, volume_start, volume_end) ..
    string.gsub(string.sub(filename, volume_end + 1), '([^a-zA-Z0-9_.~/-])',
      function(c) return string.format("%%%X", string.byte(c)) end)
end

lsp_util.get_filename = function(uri)
  -- TODO: Can't remember if this is the best way
  if vim.api.nvim_call_function('has', {'win32'}) == 1 then
    uri = string.gsub(uri, 'file:///', '')
  else
    uri = string.gsub(uri, 'file://', '')
  end
  return string.gsub(uri, '%%(%x%x)',
    function(c) return string.char(tonumber('0x' .. c)) end)
end

lsp_util.get_buffer_lines = function(bufnr)
  return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
end

lsp_util.get_buffer_text = function(bufnr)
  return table.concat(lsp_util.get_buffer_lines(bufnr), '\n')
end

lsp_util.get_line_from_path = function(path, line_number)
  local buf_number = vim.api.nvim_call_function('bufnr', { path })

  local text = ''
  if buf_number == -1 then
    text = util.get_file_line(path, line_number)
  else
    text = vim.api.nvim_buf_get_lines(buf_number, line_number - 1, line_number, false)[1]
  end

  if text == nil then
    text = ''
  end

  return text
end


return lsp_util
