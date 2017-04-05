
if !exists('my_job_id')
  let my_job_id = jobstart(['nvim', '--embed'], {'rpc': v:true})
endif

" echo my_job_id

let my_async = rpcasync(my_job_id, 'nvim_eval', ['1 + 1'], { id, data, event -> execute('let g:my_result = ' . string(a:data))})

" call rpcwait(my_async)

let result_checker = {
      \ 'result': my_async,
      \ 'callback': get(g:, 'my_result', v:false)
      \ }

echo result_checker
