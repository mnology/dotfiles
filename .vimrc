" Bundles
scriptencoding utf-8
" set nocompatible
filetype off
set runtimepath+=~/.vim/bundle/Vundle.vim/
set runtimepath+=/usr/local/lib/python3.6/dist-packages/powerline/bindings/vim/
call vundle#begin()

" Plugin '42wim/vim-shfmt'
Plugin 'psf/black'
Plugin 'ajh17/Spacegray.vim'
Plugin 'bash-support.vim'
Plugin 'benmills/vimux'
Plugin 'bling/vim-airline'
Plugin 'bling/vim-bufferline'
Plugin 'Chiel92/vim-autoformat'
Plugin 'chriskempson/base16-vim'
Plugin 'chriskempson/vim-tomorrow-theme'
Plugin 'ctrlpvim/ctrlp.vim'
Plugin 'dougireton/vim-chef'
Plugin 'DoxygenToolkit.vim'
Plugin 'editorconfig/editorconfig-vim'
Plugin 'epmatsw/ag.vim'
Plugin 'euclio/vim-markdown-composer'
Plugin 'fatih/vim-go'
Plugin 'godlygeek/tabular'
Plugin 'groovy.vim'
Plugin 'hashivim/vim-terraform'
Plugin 'hhff/SpacegrayEighties.vim'
"Plugin 'iamcco/markdown-preview.nvim'
Plugin 'juliosueiras/vim-terraform-completion'
Plugin 'juneedahamed/svnj.vim'
Plugin 'lepture/vim-jinja'
Plugin 'majutsushi/tagbar'
Plugin 'maksimr/vim-jsbeautify'
Plugin 'markcornick/vim-vagrant'
Plugin 'mzlogin/vim-markdown-toc'
Plugin 'nanotech/jellybeans.vim'
Plugin 'ngmy/vim-rubocop'
Plugin 'nyarly/cadre'
Plugin 'pangloss/vim-javascript'
Plugin 'pearofducks/ansible-vim'
Plugin 'perl-support.vim'
Plugin 'preservim/nerdcommenter'
Plugin 'plasticboy/vim-markdown'
Plugin 'previm/previm'
Plugin 'pseewald/vim-anyfold'
Plugin 'python-mode/python-mode'
Plugin 'robbles/logstash.vim'
Plugin 'ruby-formatter/rufo-vim'
Plugin 'scrooloose/nerdtree'
Plugin 'scrooloose/syntastic'
Plugin 'sheerun/vim-polyglot'
Plugin 'shumphrey/fugitive-gitlab.vim'
Plugin 'stephpy/vim-php-cs-fixer'
Plugin 'stephpy/vim-yaml'
" Plugin 'taglist-plus'
Plugin 'taiansu/nerdtree-ag'
Plugin 'tell-k/vim-autopep8'
Plugin 'tfnico/vim-gradle'
Plugin 'tomasr/molokai'
Plugin 'tpope/vim-fugitive'
Plugin 'tyru/open-browser.vim'
Plugin 'universal-ctags/ctags'
Plugin 'Valloric/YouCompleteMe'
Plugin 'vcscommand.vim'
Plugin 'vim-perl/vim-perl'
Plugin 'vim-ruby/vim-ruby'
Plugin 'VundleVim/Vundle.vim'
Plugin 'w0rp/ale'
Plugin 'wookiehangover/jshint.vim'
Plugin 'xolox/vim-misc'
Plugin 'xolox/vim-session'
call vundle#end()

filetype plugin indent on

colorscheme base16-tomorrow-night-eighties
syntax on

set  antialias
set  autoindent
set  autoread
set  autowrite
set  backspace=indent,eol,start
set  background=dark
set  colorcolumn=+1
set  expandtab
set  foldmethod=syntax
set  foldcolumn=3
set  foldlevelstart=0
set  helplang=En
set  hlsearch
set  incsearch
set  laststatus=2
set  matchpairs=(:),{:},[:],<:>
set  mouse=a
set  number
set  nowrap
set  showcmd
set  ruler
set  shiftround
set  shiftwidth=2
set  showmatch
set  smartindent
set  t_CO=256
set  tabstop=2
set  textwidth=80
set  listchars=tab:>.,eol:\$
set  visualbell
set  wildignore=*.bak,*.o,*.e,*~
set  wildmenu
set  guifont=JuliaMono\ 10
set  antialias enc=utf-8

" airline
let g:airline_powerline_fonts=1
let g:airline#extensions#tabline#enabled = 1

let javaScript_fold=1
let perl_fold=1
let perl_fold_anonymous_subs=1
let php_folding=1
let ruby_fold=3
let sh_fold_enabled=1
let vimsyn_folding='af'
let xml_syntax_folding=1
let Tlist_Use_Right_Window = 1

map <c-f> :call JsBeautify()<cr>
imap <Tab> <C-P>

let g:Perl_GlobalTemplateFile=$HOME.'/.vim/bundle/perl-support.vim/perl-support/templates/Templates'
let g:Perl_LocalTemplateFile=$HOME.'/.vim/bundle/perl-support.vim/perl-support/templates/Templates'
let tlist_perl_settings='perl;c:constant;l:label;p:package;s:subroutine;a:attribute'

let g:php_cs_fixer_path=$HOME.'/bin/php-cs-fixer'
let g:php_cs_fixer_config='default'

set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

let g:syntastic_javascript_checkers = ['eslint']
let g:syntastic_javascript_eslint_exe = 'npm run lint --'

" Autoformat
let g:formatdef_present_java = '"astyle --mode=java --style=java -pcHs4"'
let g:formatters_java = [ 'present_java' ]

" chef syntax highlighting
let g:ruby_path = system('echo $HOME/.rbenv/shims')
augroup chef
  autocmd FileType ruby,eruby set filetype=ruby.eruby.chef
augroup END

" ruby / chef syntax checking
let g:syntastic_ruby_checkers = [ 'rubocop', 'mri' ]

" Enable rufo (RUby FOrmat)
" let g:rufo_auto_formatting = 1

" python / pymode
let g:pymode = 1
let g:pymode_python = 'python3'
let g:pymode_trim_whitespaces = 1
let g:pymode_options = 1
let g:pymode_indent = 1
let g:pymode_lint = 1
let g:pymode_lint_on_write = 1
let g:pymode_lint_checkers = ['pycodestyle', 'flake8']

" NERDTree
let NERDTreeShowHidden=1

" NERDComment
let g:NERDDefaultAlign = 'left'
let g:NERDSpaceDelims = 1

" Terraform
let g:terraform_align = 1
let g:terraform_fmt_on_save = 1
let g:terraform_fold_sections = 1

" Ansible
let g:ansible_unindent_after_newline = 1
let g:ansible_name_highlight = 'd'
let g:ansible_extra_keywords_highlight = 1

" AnyFold
augroup anyfold
  autocmd Filetype * AnyFoldActivate
augroup END

" Tagbar Makefiles
let g:tagbar_type_make = { 'kinds':[ 'm:macros', 't:targets' ] }

" Add support for markdown files in tagbar.
let g:tagbar_type_markdown = {
    \ 'ctagstype': 'markdown',
    \ 'ctagsbin' : '/usr/local/lib/python3.6/dist-packages/markdown2ctags.py',
    \ 'ctagsargs' : '-f - --sort=yes --sro=»',
    \ 'kinds' : [
        \ 's:sections',
        \ 'i:images'
    \ ],
    \ 'sro' : '»',
    \ 'kind2scope' : {
        \ 's' : 'section',
    \ },
    \ 'sort': 0,
\ }

" Ansible tagbar
let g:tagbar_type_ansible = {
    \ 'ctagstype' : 'ansible',
    \ 'kinds' : [
        \ 't:tasks'
    \],
    \ 'sort' : 0
\ }

" Gitlab fugitive
let g:fugitive_gitlab_domains = [
      \ 'https://git.sdo.jlrmotor.com',
      \ 'https://git-gdd.sdo.jlrmotor.com'
      \ ]

let g:gitlab_api_keys = {
      \ 'git.sdo.jlrmotor.com': '***REMOVED***',
      \ 'git-gdd.sdo.jlrmotor.com': '***REMOVED***'
      \ }

" Vim startup plugins
augroup startup
  autocmd VimEnter * NERDTree
  autocmd VimEnter * Tagbar
  autocmd VimEnter * wincmd p
augroup END

augroup css
  autocmd filetype css setlocal equalprg=csstidy\ -\ --silent=true\ \--template=low
augroup END
