let s:client_string = "require('lsp.plugin').client"

let s:autocmds_initialized = get(s:, 'autocmds_initialized ', v:false)

" TODO(tjdevries): Make these autocmds filetype / pattern matching specific
function! s:initialize_autocmds() abort
  if s:autocmds_initialized
    return
  endif

  let s:autocmds_initialized = v:true

  augroup LanguageServerProtocol
    autocmd!
    lua require("lsp.autocmds").export_autocmds()
  augroup END

endfunction

function! lsp#start(...) abort
  call s:initialize_autocmds()

  let start_filetype = get(a:000, 0, &filetype)
  let force = get(a:000, 1, v:false)

  if force || !luaeval(s:client_string . '.has_started(_A)', start_filetype)
    call luaeval(s:client_string . '.start(nil, _A).name', start_filetype)

    " Open the document in the lsp.
    " Only do this if we just started the server, to make sure that this
    " document has been opened. Afterwards, autocmds will handle this.
    if &filetype == start_filetype
      silent call lsp#request_async('textDocument/didOpen')
    endif
  else
    echom '[LSP] Client for ' . start_filetype . ' has already started'
  end
endfunction

" TODO(tjdevries): Make sure this works correctly
" TODO(tjdevries): Figure out how to call a passed callback
function! lsp#request(request, ...) abort
  let arguments = get(a:000, 0, {})
  let optional_callback = get(a:000, 1, v:null)
  let filetype = get(a:000, 2, v:null)

  let request_id = luaeval(s:client_string . '.request(_A.request, _A.arguments, _A.callback, _A.filetype)', {
          \ 'request': a:request,
          \ 'arguments': arguments,
          \ 'callback': optional_callback,
          \ 'filetype': filetype,
        \ })

  return request_id
endfunction

""
" Async request to the lsp server.
"
" Do not wait until completion
function! lsp#request_async(request, ...) abort
  let arguments = get(a:000, 0, {})
  let optional_callback = get(a:000, 1, v:null)
  let filetype = get(a:000, 2, v:null)

  let result = luaeval(s:client_string . '.request_async(_A.request, _A.arguments, _A.callback, _A.filetype)', {
          \ 'request': a:request,
          \ 'arguments': arguments,
          \ 'callback': optional_callback,
          \ 'filetype': filetype,
        \ })

  return result
endfunction

""
" Give access to the default client callbacks to perform
" LSP type actions, without a server
function! lsp#handle(request, data, ...) abort abort
  let file_type = get(a:000, 0, &filetype)
  let default_only = get(a:000, 1, v:true)

  " Gets the default callback,
  " and then calls it with the provided data
  return luaeval(s:client_string . '.handle(_A.filetype, _A.method, _A.data, _A.default_only)', {
        \ 'filetype': file_type,
        \ 'name': a:request,
        \ 'data': a:data,
        \ 'default_only': default_only,
        \ })
endfunction
