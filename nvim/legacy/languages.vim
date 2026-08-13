let javaScript_fold=1
let perl_fold=1
let perl_fold_anonymous_subs=1
let php_folding=1
let ruby_fold=3
let sh_fold_enabled=1
let vimsyn_folding='af'
let xml_syntax_folding=1

let Tlist_Use_Right_Window = 1

let NERDTreeShowHidden=1
let g:NERDDefaultAlign = 'left'
let g:NERDSpaceDelims = 1

let g:Perl_GlobalTemplateFile=$HOME.'/.vim/bundle/perl-support.vim/perl-support/templates/Templates'
let g:Perl_LocalTemplateFile=$HOME.'/.vim/bundle/perl-support.vim/perl-support/templates/Templates'
let tlist_perl_settings='perl;c:constant;l:label;p:package;s:subroutine;a:attribute'

let g:php_cs_fixer_path=$HOME.'/bin/php-cs-fixer'
let g:php_cs_fixer_config='default'

let g:pymode = 1
let g:pymode_python = 'python3'
let g:pymode_trim_whitespaces = 1
let g:pymode_options = 1
let g:pymode_indent = 1
let g:pymode_lint = 1
let g:pymode_lint_on_write = 1
let g:pymode_lint_checkers = ['pycodestyle', 'flake8']

let g:ruby_path = system('echo $HOME/.rbenv/shims')

let g:terraform_align = 1
let g:terraform_fmt_on_save = 1
let g:terraform_fold_sections = 1

let g:ansible_unindent_after_newline = 1
let g:ansible_name_highlight = 'd'
let g:ansible_extra_keywords_highlight = 1

let g:tagbar_type_make = { 'kinds':['m:macros', 't:targets'] }

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
