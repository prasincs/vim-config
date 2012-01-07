:let mapleader=","
syntax on

:map <M-Esc>[62~ <MouseDown> 
:map! <M-Esc>[62~ <MouseDown> 
:map <M-Esc>[63~ <MouseUp> 
:map! <M-Esc>[63~ <MouseUp> 
:map <M-Esc>[64~ <S-MouseDown> 
:map! <M-Esc>[64~ <S-MouseDown> 
:map <M-Esc>[65~ <S-MouseUp> 
:map! <M-Esc>[65~ <S-MouseUp>
filetype plugin on

"set tags=~/.vim/stdtags,tags,.tags,../tags

autocmd InsertLeave * if pumvisible() == 0|pclose|endif
set ai sw=4
" enable mouse wherever
set mouse=a
" " OPTIONAL: This enables automatic indentation as you type.
filetype indent on
" It's VIM, not VI
set nocompatible

" A tab produces a 2-space indentation
set softtabstop=2
set shiftwidth=2
set expandtab


" Enable filetype detection
filetype on

" Add and delete spaces in increments of `shiftwidth' for tabs
set smarttab

" Highlight syntax in programming languages
syntax on

" In Makefiles, don't expand tabs to spaces, since we need the actual tabs
autocmd FileType make set noexpandtab

" Useful macros for cleaning up code to conform to LLVM coding guidelines

" Delete trailing whitespace and tabs at the end of each line
command! DeleteTrailingWs :%s/\s\+$//

" Convert all tab characters to two spaces
command! Untab :%s/\t/  /g


function! ConditionalPairMap(open, close)
  let line = getline('.')
  let col = col('.')
  if col < col('$') || stridx(line, a:close, col + 1) != -1
    return a:open
  else
    return a:open . a:close . repeat("\<left>", len(a:close))
  endif
endf

" Automatically adds the pairs
inoremap <expr> ( ConditionalPairMap('(', ')')
inoremap <expr> { ConditionalPairMap('{', '}')
inoremap <expr> [ ConditionalPairMap('[', ']')


" Additional vim features to optionally uncomment.
set showcmd
set showmatch
set showmode
set incsearch
set ruler

"Allow copy-pasting
map <C-c> "+y

" Enable pathogen
"call pathogen#infect()
call pathogen#runtime_append_all_bundles()
call pathogen#helptags()
"Solarized color scheme
syntax enable
set background=dark
colorscheme solarized

" NERDTree
map <F2> :NERDTreeToggle<CR>
"Enable Ctrl+P to paste
map <C-p> :set paste<CR>

" Folds
set foldmethod=indent
set foldlevel=99

" Moving around windows

map <c-j> <c-w>j
map <c-k> <c-w>k
map <c-l> <c-w>l
map <c-h> <c-w>h

" SuperTab plugin

au FileType python set omnifunc=pythoncomplete#Complete
let g:SuperTabDefaultCompletionType = "context"

set completeopt=menuone,longest,preview

syntax on

:map <M-Esc>[62~ <MouseDown> 
:map! <M-Esc>[62~ <MouseDown> 
:map <M-Esc>[63~ <MouseUp> 
:map! <M-Esc>[63~ <MouseUp> 
:map <M-Esc>[64~ <S-MouseDown> 
:map! <M-Esc>[64~ <S-MouseDown> 
:map <M-Esc>[65~ <S-MouseUp> 
:map! <M-Esc>[65~ <S-MouseUp>
filetype plugin on

"set tags=~/.vim/stdtags,tags,.tags,../tags

autocmd InsertLeave * if pumvisible() == 0|pclose|endif
set ai sw=4
" enable mouse wherever
set mouse=a
" " OPTIONAL: This enables automatic indentation as you type.
filetype indent on
" It's VIM, not VI
set nocompatible

" A tab produces a 2-space indentation
set softtabstop=2
set shiftwidth=2
set expandtab


" Enable filetype detection
filetype on

" Add and delete spaces in increments of `shiftwidth' for tabs
set smarttab

" Highlight syntax in programming languages
syntax on

" In Makefiles, don't expand tabs to spaces, since we need the actual tabs
autocmd FileType make set noexpandtab

" Useful macros for cleaning up code to conform to LLVM coding guidelines

" Delete trailing whitespace and tabs at the end of each line
command! DeleteTrailingWs :%s/\s\+$//

" Convert all tab characters to two spaces
command! Untab :%s/\t/  /g


function! ConditionalPairMap(open, close)
  let line = getline('.')
  let col = col('.')
  if col < col('$') || stridx(line, a:close, col + 1) != -1
    return a:open
  else
    return a:open . a:close . repeat("\<left>", len(a:close))
  endif
endf

" Automatically adds the pairs
inoremap <expr> ( ConditionalPairMap('(', ')')
inoremap <expr> { ConditionalPairMap('{', '}')
inoremap <expr> [ ConditionalPairMap('[', ']')


" Additional vim features to optionally uncomment.
set showcmd
set showmatch
set showmode
set incsearch
set ruler

"Allow copy-pasting
map <C-c> "+y

" Enable pathogen
"call pathogen#infect()
call pathogen#runtime_append_all_bundles()
call pathogen#helptags()
"Solarized color scheme
syntax enable
set background=dark
colorscheme solarized

" NERDTree
map <F2> :NERDTreeToggle<CR>
"Enable Ctrl+P to paste
map <C-p> :set paste<CR>

" Folds
set foldmethod=indent
set foldlevel=99

" Moving around windows

map <c-j> <c-w>j
map <c-k> <c-w>k
map <c-l> <c-w>l
map <c-h> <c-w>h

" SuperTab plugin

au FileType python set omnifunc=pythoncomplete#Complete
let g:SuperTabDefaultCompletionType = "context"

set completeopt=menuone,longest,preview

