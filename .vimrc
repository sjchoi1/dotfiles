" Fast minimal vim config

" Performance settings
set nocompatible
set lazyredraw
set ttyfast
set synmaxcol=200
set updatetime=300

" Basic settings
set number hidden wildmenu noswapfile
set splitright splitbelow noequalalways
set laststatus=0 noruler
set clipboard=unnamedplus
set autoread

" True color
set termguicolors background=dark
let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"

" Colorschemes - F5 to cycle
let g:my_colors = ['desert', 'slate', 'torte', 'darkblue', 'evening', 'blue']
let g:my_color_idx = 0
let g:colorscheme_file = expand('~/.vim/colorscheme')

function! LoadSavedColorscheme()
    if filereadable(g:colorscheme_file)
        let l:idx = index(g:my_colors, readfile(g:colorscheme_file)[0])
        if l:idx >= 0 | let g:my_color_idx = l:idx | endif
    endif
    silent! execute 'colorscheme ' . g:my_colors[g:my_color_idx]
endfunction

function! CycleColors()
    let g:my_color_idx = (g:my_color_idx + 1) % len(g:my_colors)
    execute 'colorscheme ' . g:my_colors[g:my_color_idx]
    echo g:my_colors[g:my_color_idx]
endfunction

nnoremap <F5> :call CycleColors()<CR>

" Focused window cursorline
set cursorline
highlight CursorLine guibg=#303040
highlight WinSeparator guifg=#5080ff guibg=NONE

" Window navigation
nnoremap <Tab> <C-w>w
nnoremap <S-Tab> <C-w>W

" netrw settings
let g:netrw_banner = 0
let g:netrw_liststyle = 3
let g:netrw_winsize = 30
let g:netrw_altv = 1

" Close current file
function! CloseCurrentFile()
    let l:curbuf = bufnr('%')
    if !buflisted(l:curbuf) || &buftype != "" || bufname(l:curbuf) == "" | return | endif
    let l:bufs = filter(range(1, bufnr('$')), 'buflisted(v:val) && getbufvar(v:val, "&buftype") == "" && bufname(v:val) != "" && v:val != ' . l:curbuf)
    if !empty(l:bufs)
        execute 'buffer ' . l:bufs[0] | execute 'bdelete ' . l:curbuf
    else
        call ShowCheatsheet() | execute 'bdelete ' . l:curbuf
        call timer_start(10, {-> execute('1wincmd w')})
    endif
    call RefreshBufferList()
endfunction

" Handle quit commands
function! HandleQuit(save)
    let l:ft = &filetype
    let l:bufname = bufname('%')
    if a:save && &modified && l:ft != 'netrw' && l:ft != 'bufferlist' && l:bufname != '[Cheatsheet]'
        write
    endif
    if l:ft == 'netrw' || l:bufname == '[Cheatsheet]'
        qall
    elseif l:ft == 'bufferlist'
        let l:bufs = filter(range(1, bufnr('$')), 'buflisted(v:val) && getbufvar(v:val, "&buftype") == "" && bufname(v:val) != ""')
        if empty(l:bufs) | qall | else | call CloseAllFiles() | endif
    else
        call CloseCurrentFile()
    endif
endfunction

" Override quit commands
cnoreabbrev <expr> q getcmdtype() == ':' && getcmdline() == 'q' ? 'call HandleQuit(0)' : 'q'
cnoreabbrev <expr> quit getcmdtype() == ':' && getcmdline() == 'quit' ? 'call HandleQuit(0)' : 'quit'
cnoreabbrev <expr> wq getcmdtype() == ':' && getcmdline() == 'wq' ? 'call HandleQuit(1)' : 'wq'
cnoreabbrev <expr> x getcmdtype() == ':' && getcmdline() == 'x' ? 'call HandleQuit(1)' : 'x'
cnoreabbrev <expr> exit getcmdtype() == ':' && getcmdline() == 'exit' ? 'call HandleQuit(1)' : 'exit'
nnoremap ZZ :call HandleQuit(1)<CR>
nnoremap ZQ :call HandleQuit(0)<CR>

" Open buffer from list
function! OpenBuffer(idx)
    if exists('b:buffer_list') && a:idx >= 0 && a:idx < len(b:buffer_list)
        2wincmd w | execute 'buffer ' . b:buffer_list[a:idx]
    endif
endfunction

" Close all files
function! CloseAllFiles()
    let l:bufs = filter(range(1, bufnr('$')), 'buflisted(v:val) && getbufvar(v:val, "&buftype") == "" && bufname(v:val) != ""')
    2wincmd w | call ShowCheatsheet()
    for b in l:bufs | silent! execute 'bdelete ' . b | endfor
    call RefreshBufferList()
    call timer_start(10, {-> execute('1wincmd w')})
endfunction

" Refresh buffer list panel
function! RefreshBufferList()
    let l:cur = winnr()
    for i in range(1, winnr('$'))
        if getwinvar(i, '&filetype') == 'bufferlist'
            call setwinvar(i, '&modifiable', 1)
            let l:bufs = filter(range(1, bufnr('$')), 'buflisted(v:val) && getbufvar(v:val, "&buftype") == "" && bufname(v:val) != ""')
            let l:lines = empty(l:bufs) ? [' (no open files)'] : map(copy(l:bufs), {i, b -> ' ' . (i+1) . '. ' . fnamemodify(bufname(b), ':t') . (getbufvar(b, "&modified") ? ' +' : '')})
            call setbufline(winbufnr(i), 1, l:lines)
            silent! call deletebufline(winbufnr(i), len(l:lines)+1, '$')
            call setwinvar(i, '&modifiable', 0)
            call setbufvar(winbufnr(i), 'buffer_list', l:bufs)
            break
        endif
    endfor
endfunction

" Show cheatsheet
function! ShowCheatsheet()
    enew
    if filereadable(expand('~/.vim/cheatsheet.txt'))
        silent! read ~/.vim/cheatsheet.txt | 1delete _
    endif
    setlocal buftype=nofile bufhidden=wipe noswapfile readonly nomodifiable nobuflisted
    file [Cheatsheet]
endfunction

" Startup layout
function! StartupLayout()
    if argc() == 0
        call ShowCheatsheet()
        Vexplore | vertical resize 30 | setlocal winfixwidth
        vertical botright new | call SetupBufferListPanel()
        1wincmd w
    endif
endfunction

function! SetupBufferListPanel()
    setlocal buftype=nofile bufhidden=wipe noswapfile nowrap nonumber filetype=bufferlist
    file [Open\ Files]
    let b:buffer_list = []
    call RefreshBufferList()
    vertical resize 25 | setlocal winfixwidth
    nnoremap <buffer> <CR> :call OpenBuffer(line('.') - 1)<CR>
    nnoremap <buffer> <LeftRelease> :call OpenBuffer(line('.') - 1)<CR>
    for i in range(1, 9) | execute 'nnoremap <buffer> ' . i . ' :call OpenBuffer(' . (i-1) . ')<CR>' | endfor
endfunction

" Autocmds - grouped for efficiency
augroup vimrc
    autocmd!
    autocmd VimEnter * call LoadSavedColorscheme() | call StartupLayout()
    autocmd VimLeave * call writefile([g:my_colors[g:my_color_idx]], g:colorscheme_file)
    autocmd WinEnter * setlocal cursorline
    autocmd WinLeave * setlocal nocursorline
    autocmd FocusGained,BufEnter * silent! checktime
    autocmd BufAdd,BufDelete * call RefreshBufferList()
    autocmd FileType netrw setlocal winfixwidth | if winnr('$') >= 2 | let g:netrw_chgwin = 2 | endif
    autocmd FileType netrw nnoremap <buffer> q :qall<CR>
    autocmd FileType bufferlist nnoremap <buffer> q :call CloseAllFiles()<CR>
    autocmd BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
augroup END
