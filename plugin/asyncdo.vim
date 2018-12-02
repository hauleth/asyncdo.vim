" asyncdo.vim - minimal async runner for Vim 8 and NeoVim
" Maintainer: Hauleth <lukasz@niemier.pl>

if exists('g:loaded_asyncdo_vim') | finish | endif
if !(has('job') || has('nvim')) || &cp
    echoerr "Here's a nickel, Kid. Buy a real editor."
    finish
endif

let g:loaded_asyncdo_vim = 1
let s:save_cpo = &cpo
set cpo&vim

command! -bang -nargs=+ -complete=file AsyncDo   call asyncdo#run(<bang>0, <f-args>)
command!       -nargs=0 -complete=file AsyncStop call asyncdo#stop()

command! -bang -nargs=+ -complete=file LAsyncDo   call asyncdo#lrun(<bang>0, <f-args>)
command!       -nargs=0 -complete=file LAsyncStop call asyncdo#lstop()

let &cpo = s:save_cpo
