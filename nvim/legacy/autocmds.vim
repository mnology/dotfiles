augroup chef
  autocmd!
  autocmd FileType ruby,eruby set filetype=ruby.eruby.chef
augroup END

augroup anyfold
  autocmd!
  autocmd Filetype * AnyFoldActivate
augroup END

augroup startup
  autocmd!
  autocmd VimEnter * NERDTree
  autocmd VimEnter * Tagbar
  autocmd VimEnter * wincmd p
augroup END

augroup css
  autocmd!
  autocmd filetype css setlocal equalprg=csstidy\ -\ --silent=true\ --template=low
augroup END
