" Simple vim config

" Basic settings
set nocompatible
set number hidden wildmenu noswapfile
set splitright splitbelow
set clipboard=unnamedplus autoread
set laststatus=2

" True color
set termguicolors background=dark
colorscheme desert

" netrw file tree
let g:netrw_banner = 0
let g:netrw_liststyle = 3

" Window navigation
nnoremap <Tab> <C-w>w
nnoremap <S-Tab> <C-w>W

" Open file tree when starting vim without a file
autocmd VimEnter * if argc() == 0 | Explore | endif
