

""
" Omni completion with LSP
function! lsp#completion#omni(findstart, base) abort
  " If we haven't started, then don't return anything useful
  if !luaeval("require('lsp.plugin').client.has_started()")
    return a:findstart ? -1 : []
  endif

  if a:findstart
    let line_to_cursor = strpart(getline('.'), 0, col('.') - 1)
    let [string_result, start_position, end_position] = matchstrpos(line_to_cursor, '\k\+$')
    let length = end_position - start_position

    return len(line_to_cursor) - length
  else
    let results = lsp#request('textDocument/completion')

    let g:__lsp_completion = results
    return results
  endif

endfunction
