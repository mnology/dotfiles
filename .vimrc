" Bundles
set nocompatible
filetype off
set rtp+=~/.vim/bundle/Vundle.vim/
call vundle#begin()

Plugin 'bash-support.vim'
Plugin 'groovy.vim'
Plugin 'minibufexplorerpp'
Plugin 'perl-support.vim'
Plugin 'taglist-plus'
Plugin 'vcscommand.vim'
Plugin 'epmatsw/ag.vim'
Plugin 'pearofducks/ansible-vim'
Plugin 'chriskempson/base16-vim'
Plugin 'nyarly/cadre'
Plugin 'nanotech/jellybeans.vim'
Plugin 'wookiehangover/jshint.vim'
Plugin 'tomasr/molokai'
Plugin 'scrooloose/nerdtree'
Plugin 'taiansu/nerdtree-ag'
Plugin 'klen/python-mode'
Plugin 'hhff/SpacegrayEighties.vim'
Plugin 'ajh17/Spacegray.vim'
Plugin 'juneedahamed/svnj.vim'
Plugin 'scrooloose/syntastic'
Plugin 'bling/vim-airline'
Plugin 'Chiel92/vim-autoformat'
Plugin 'dougireton/vim-chef'
Plugin 'tpope/vim-fugitive'
Plugin 'tfnico/vim-gradle'
Plugin 'pangloss/vim-javascript'
Plugin 'lepture/vim-jinja'
Plugin 'maksimr/vim-jsbeautify'
Plugin 'xolox/vim-misc'
Plugin 'vim-perl/vim-perl'
Plugin 'robbles/logstash.vim'
Plugin 'stephpy/vim-php-cs-fixer'
Plugin 'ngmy/vim-rubocop'
Plugin 'vim-ruby/vim-ruby'
Plugin 'xolox/vim-session'
Plugin 'hashivim/vim-terraform'
Plugin 'chriskempson/vim-tomorrow-theme'
Plugin 'markcornick/vim-vagrant'
Plugin 'VundleVim/Vundle.vim'
Plugin 'Valloric/YouCompleteMe'

call vundle#end()

filetype plugin indent on

autocmd filetype css setlocal equalprg=csstidy\ -\ --silent=true\ \--template=low

colorscheme Tomorrow-Night-Eighties
syntax on

set  antialias
set  autoindent
set  autoread
set  autowrite
set  backspace=indent,eol,start
set  bg=dark
set  colorcolumn=+1
set  expandtab
set  foldmethod=syntax
set  foldcolumn=3
set  foldlevelstart=2
set  helplang=En
set  hlsearch
set  incsearch
set  matchpairs=(:),{:},[:],<:>
set  mouse=a
set  nu
set  nowrap
set  showcmd
set  ruler
set  shiftround
set  shiftwidth=2
set  showmatch
set  smartindent
set  tabstop=2
set  textwidth=80
set  listchars=tab:>.,eol:\$
set  visualbell
set  wildignore=*.bak,*.o,*.e,*~
set  wildmenu
set  guifont=Source\ Code\ Pro\ for\ Powerline\ 10 
set  anti enc=utf-8

let  g:airline_powerline_fonts=1

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
let g:php_cs_fixer_config="default"

set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

" Autoformat
let g:formatdef_present_java = '"astyle --mode=java --style=java -pcHs4"'
let g:formatters_java = [ 'present_java' ]

" chef syntax highlighting
let g:ruby_path = system('echo $HOME/.rbenv/shims')
autocmd FileType ruby,eruby set filetype=ruby.eruby.chef

" ruby / chef syntax checking
let g:syntastic_ruby_checkers = [ 'rubocop', 'mri' ]

" python / pymode
let g:pymode = 1
let g:pymode_trim_whitespaces = 1
let g:pymode_options = 1
let g:pymode_indent = 1
let g:pymode_lint = 1
let g:pymode_lint_on_write = 1
let g:pymode_lint_checkers = ['pep8', 'flake8']

" NERDTree
let NERDTreeShowHidden=1

" Terraform
let g:terraform_align = 1
let g:terraform_fmt_on_save = 1
