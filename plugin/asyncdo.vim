" asyncdo.vim - minimal async runner for Vim 8 and NeoVim
" Maintainer: Łukasz Niemier <lukasz@niemier.pl>

scriptencoding utf-8

if exists('g:loaded_asyncdo_vim') || !(has('job') || has('nvim')) || &cp
    finish
endif
let g:loaded_asyncdo_vim = 1
let s:save_cpo = &cpo
set cpo&vim

command! -bang -nargs=+ AsyncDo   call asyncdo#run(<bang>0, <f-args>)
command!       -nargs=0 AsyncStop call asyncdo#stop()

let &cpo = s:save_cpo
unlet s:save_cpo
