" Auto-install vim-plug if not present
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" Plugins
call plug#begin('~/.vim/plugged')
Plug 'tpope/vim-sensible'           " Sensible defaults
Plug 'tpope/vim-fugitive'           " Git integration
Plug 'preservim/nerdtree'           " File explorer
Plug 'airblade/vim-gitgutter'       " Git diff in gutter
Plug 'vim-airline/vim-airline'      " Status line
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'             " Fuzzy finder
call plug#end()

" General settings
set number                          " Show line numbers
set relativenumber                  " Relative line numbers
set cursorline                      " Highlight current line
set showmatch                       " Highlight matching brackets
set incsearch                       " Incremental search
set hlsearch                        " Highlight search results
set ignorecase                      " Case insensitive search
set smartcase                       " Unless uppercase is used

" Indentation
set expandtab                       " Use spaces instead of tabs
set tabstop=4                       " Tab width
set shiftwidth=4                    " Indent width
set autoindent                      " Auto indent
set smartindent                     " Smart indent

" UI
set laststatus=2                    " Always show status line
set wildmenu                        " Command line completion
set scrolloff=8                     " Keep 8 lines above/below cursor
set signcolumn=yes                  " Always show sign column

" Key mappings
let mapleader = " "                 " Space as leader key
nnoremap <leader>n :NERDTreeToggle<CR>
nnoremap <leader>f :Files<CR>
nnoremap <leader>g :Rg<CR>
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Clear search highlight with Escape
nnoremap <Esc> :nohlsearch<CR>
