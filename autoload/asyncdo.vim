func! s:finalize(scope, prefix, settitle) abort
    let l:job = get(a:scope, 'asyncdo')
    if type(l:job) isnot v:t_dict | return | endif
    try
        let l:tmp = &errorformat
        if has_key(l:job, 'errorformat')
            let &errorformat = l:job.errorformat
        endif
        exe a:prefix.(l:job.jump ? '' : 'get').'file '.l:job.file
        call a:settitle(has_key(l:job, 'title') ? l:job.title : l:job.cmd, l:job.nr)
    finally
        let &errorformat = l:tmp
        unlet! a:scope.asyncdo
        call delete(l:job.file)
    endtry
endfunc

" Regexes shamely stolen from vim-dispatch
" https://github.com/tpope/vim-dispatch/blob/d4b8940fd1cd77fc6d300f003b18745a584295b2/autoload/dispatch.vim#L60
let s:var = '\%(<\%(cword\|cWORD\|cexpr\|cfile\|sfile\|slnum\|afile\|abuf\|amatch' . (has('clientserver') ? '\|client' : '') . '\)>\|%\|#<\=\d\+\|##\=\)'
let s:flags = '<\=\%(:[p8~.htre]\|:g\=s\(.\).\{-\}\1.\{-\}\1\)*\%(:S\)\='
let s:expandable = '\\*\%(`[+-]\==[^`]*`\|' . s:var . s:flags . '\)'
func! s:escape(...) abort
  " if there are two args, s:escape is called from map(). use 2nd arg
  let str = a:0 == 2 ? a:2 : a:1
  return shellescape(substitute(str, s:expandable, {a->expand(a[0])}, 'g'))
endfunc

func! s:build(scope, prefix, settitle) abort
    function! Run(nojump, cmd, ...) abort closure
        if type(get(a:scope, 'asyncdo')) == v:t_dict
            echoerr 'There is currently running job, just wait' | return
        endif

        if type(a:cmd) == v:t_dict
            let l:job = deepcopy(a:cmd)
            let l:cmd = a:cmd.job
        else
            let l:job = {}
            let l:cmd = a:cmd
        endif

        call extend(l:job, {'nr': win_getid(), 'file': tempname(), 'jump': !a:nojump})
        let l:args = copy(a:000)
        if l:cmd =~# '\$\*'
            let l:job.cmd = substitute(l:cmd, '\$\*', join(l:args), 'g')
        else
            let l:job.cmd = join([l:cmd] + l:args)
        endif
        let l:job.cmd = s:escape(l:job.cmd)
        echom l:job.cmd
        let l:spec = [&shell, &shellcmdflag, l:job.cmd . printf(&shellredir, l:job.file)]
        let l:Cb = {-> s:finalize(a:scope, a:prefix, a:settitle)}
        if !has_key(l:job, 'errorformat')
          let l:job.errorformat = &errorformat
        endif

        if has('nvim')
            let l:job.id = jobstart(l:spec, {'on_exit': l:Cb})
        else
            let l:job.id = job_start(l:spec, {
                        \   'in_io': 'null','out_io': 'null','err_io': 'null',
                        \   'exit_cb': l:Cb
                        \ })
        endif
        let a:scope['asyncdo'] = l:job
    endfunc

    func! Stop() abort closure
        let l:job = get(a:scope, 'asyncdo')
        if type(l:job) is v:t_dict
            has('nvim')
                call jobstop(l:job.id)
            else
                call job_stop(l:job.id)
            endif
            unlet! a:scope['asyncdo']
        endif
    endfunc

    return { 'run': funcref('Run'), 'stop': funcref('Stop') }
endfunc

let s:qf = s:build(g:, 'c', {title, nr -> setqflist([], 'a', {'title': title})})
let s:ll = s:build(w:, 'l', {title, nr -> setloclist(nr, [], 'a', {'title': title})})

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
    call call(s:ll.stop, a:000)
endfunc
