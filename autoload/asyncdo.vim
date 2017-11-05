func! s:finalize(file, cmd, nojump) abort
    unlet! g:asyncdo_job
    try
        if a:nojump
            exe 'cgetfile '.a:file
        else
            exe 'cfile '.a:file
        endif
    finally
        call setqflist([], 'a', {'title': a:cmd})
        call delete(a:file)
    endtry
endfunc

func! asyncdo#run(nojump, ...) abort
    if exists('g:asyncdo_job')
        echoerr 'There is currently running job, just wait'
        return
    endif

    call setqflist([], 'r')
    let l:tmp = tempname()
    let l:cmd = join(a:000)
    let l:spec = [&shell, &shellcmdflag, printf(l:cmd.&shellredir, l:tmp)]
    let l:nojump = a:nojump

    let g:qf_quickfix_titles = []
    if has('nvim')
        let g:asyncdo_job = jobstart(l:spec, {
                    \ 'on_exit': {-> s:finalize(l:tmp, l:cmd, a:nojump)}
                    \ })
    else
        let g:asyncdo_job = job_start(l:spec, {
                    \ 'in_io': 'null','out_io': 'null','err_io': 'null',
                    \ 'exit_cb': {-> s:finalize(l:tmp, l:cmd, a:nojump)}
                    \ })
    endif
endfunc

func! asyncdo#stop() abort
    if exists('g:asyncdo_job')
        if has('nvim')
            call jobstop(g:asyncdo_job)
        else
            call job_stop(g:asyncdo_job)
        endif

        unlet g:asyncdo_job
    endif
endfunc
