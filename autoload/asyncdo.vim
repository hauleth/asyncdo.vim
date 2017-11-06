func! s:finalize(scope, file, prefix, cmd, nojump, setlist) abort
    unlet! a:scope['asyncdo_job']
    try
        if a:nojump
            exe a:prefix.'getfile '.a:file
        else
            exe a:prefix.'file '.a:file
        endif
    finally
        call a:setlist([], 'a', {'title': a:cmd})
        call delete(a:file)
    endtry
endfunc

func! s:build(scope, setlist, prefix) abort
    function! Run(nojump, ...) abort closure
        if get(a:scope, 'asyncdo_job')
            echoerr 'There is currently running job, just wait'
            return
        endif

        call a:setlist([], 'r')
        let l:tmp = tempname()
        let l:cmd = join(a:000)
        let l:spec = [&shell, &shellcmdflag, printf(l:cmd.&shellredir, l:tmp)]

        if has('nvim')
            let a:scope['asyncdo_job'] = jobstart(l:spec, {
                        \ 'on_exit': {-> s:finalize(a:scope, l:tmp, a:prefix, l:cmd, a:nojump, a:setlist)}
                        \ })
        else
            let a:scope['asyncdo_job'] = job_start(l:spec, {
                        \ 'in_io': 'null','out_io': 'null','err_io': 'null',
                        \ 'exit_cb': {-> s:finalize(a:scope, l:tmp, a:prefix, l:cmd, a:nojump, a:setlist)}
                        \ })
        endif
    endfunc

    func! Stop() abort closure
        let l:job = get(a:scope, 'asyncdo_job')
        if l:job
            if has('nvim')
                call jobstop(l:job)
            else
                call job_stop(l:job)
            endif

            unlet a:scope['asyncdo_job']
        endif
    endfunc

    return { 'run': funcref('Run'), 'stop': funcref('Stop') }
endfunc

let s:qf = s:build(g:, function('setqflist'), 'c')
let s:ll = s:build(w:, function('setloclist'), 'l')

func! asyncdo#run(...) abort
    call call(s:qf.run, a:000)
endfunc
func! asyncdo#stop(...) abort
    call call(s:qf.stop, a:000)
endfunc
func! asyncdo#lrun(...) abort
    call call(s:ll.run, a:000)
endfunc
func! asyncdo#lstop(...) abort
    call call(s:ll.run, a:000)
endfunc
