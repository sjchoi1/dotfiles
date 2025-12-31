" Fast minimal vim config

" Performance settings
set nocompatible lazyredraw ttyfast
set synmaxcol=200 updatetime=300

" Basic settings
set number hidden wildmenu noswapfile
set splitright splitbelow noequalalways
set laststatus=0 noruler
set clipboard=unnamedplus autoread

" True color
set termguicolors background=dark
let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"

" Colorschemes - F5 to cycle
let g:my_colors = ['desert', 'slate', 'torte', 'darkblue', 'evening', 'blue']
let g:my_color_idx = 0
let g:colorscheme_file = expand('~/.vim/colorscheme')
let g:layout_ready = 0

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

" Helper: Find window by filetype
function! FindWinByFiletype(ft)
    for i in range(1, winnr('$'))
        if getwinvar(i, '&filetype') == a:ft
            return i
        endif
    endfor
    return 0
endfunction

" Helper: Find middle pane (not netrw, not bufferlist)
function! FindMiddleWin()
    for i in range(1, winnr('$'))
        let l:ft = getwinvar(i, '&filetype')
        if l:ft != 'netrw' && l:ft != 'bufferlist'
            return i
        endif
    endfor
    return 0
endfunction

" Helper: Go to window safely
function! GotoWin(win)
    if a:win > 0 && a:win <= winnr('$')
        execute a:win . 'wincmd w'
        return 1
    endif
    return 0
endfunction

" Close current file
function! CloseCurrentFile()
    let l:curbuf = bufnr('%')
    " Only close if it's a real listed file
    if !buflisted(l:curbuf) || &buftype != "" || bufname(l:curbuf) == ""
        return
    endif
    " Find another file buffer to switch to
    let l:bufs = filter(range(1, bufnr('$')), 'buflisted(v:val) && getbufvar(v:val, "&buftype") == "" && bufname(v:val) != "" && v:val != ' . l:curbuf)
    if !empty(l:bufs)
        execute 'buffer ' . l:bufs[0]
        silent! execute 'bdelete ' . l:curbuf
    else
        call ShowCheatsheet()
        silent! execute 'bdelete ' . l:curbuf
        " Go to netrw if exists
        let l:netrw = FindWinByFiletype('netrw')
        if l:netrw > 0
            call timer_start(10, {-> GotoWin(l:netrw)})
        endif
    endif
    call RefreshBufferList()
endfunction

" Handle quit commands
function! HandleQuit(save)
    let l:ft = &filetype
    let l:bufname = bufname('%')
    " Save if requested and buffer is a real file
    if a:save && &modified && l:ft != 'netrw' && l:ft != 'bufferlist' && l:bufname !~ '^\['
        silent! write
    endif
    " Quit from side panels or cheatsheet = exit vim
    if l:ft == 'netrw' || l:bufname =~ '^\[Cheatsheet\]'
        qall
    elseif l:ft == 'bufferlist'
        let l:bufs = filter(range(1, bufnr('$')), 'buflisted(v:val) && getbufvar(v:val, "&buftype") == "" && bufname(v:val) != ""')
        if empty(l:bufs)
            qall
        else
            call CloseAllFiles()
        endif
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

" Open buffer from list (stay=1 keeps focus in buffer list)
function! OpenBuffer(idx, ...)
    if !exists('b:buffer_list') || a:idx < 0 || a:idx >= len(b:buffer_list)
        return
    endif
    let l:stay = get(a:, 1, 0)
    let l:cur = winnr()
    let l:bufnr = b:buffer_list[a:idx]
    let l:mid = FindMiddleWin()
    if l:mid > 0
        call GotoWin(l:mid)
        execute 'buffer ' . l:bufnr
        if l:stay
            call GotoWin(l:cur)
        endif
    endif
endfunction

" Close all files
function! CloseAllFiles()
    let l:bufs = filter(range(1, bufnr('$')), 'buflisted(v:val) && getbufvar(v:val, "&buftype") == "" && bufname(v:val) != ""')
    let l:mid = FindMiddleWin()
    if l:mid > 0
        call GotoWin(l:mid)
        call ShowCheatsheet()
    endif
    for b in l:bufs
        silent! execute 'bdelete ' . b
    endfor
    call RefreshBufferList()
    let l:netrw = FindWinByFiletype('netrw')
    if l:netrw > 0
        call timer_start(10, {-> GotoWin(l:netrw)})
    endif
endfunction

" Refresh buffer list panel
function! RefreshBufferList()
    if !g:layout_ready | return | endif
    let l:win = FindWinByFiletype('bufferlist')
    if l:win == 0 | return | endif
    let l:bufnr = winbufnr(l:win)
    if l:bufnr == -1 | return | endif

    call setbufvar(l:bufnr, '&modifiable', 1)
    let l:bufs = filter(range(1, bufnr('$')), 'buflisted(v:val) && getbufvar(v:val, "&buftype") == "" && bufname(v:val) != ""')
    let l:lines = empty(l:bufs) ? [' (no open files)'] : map(copy(l:bufs), {i, b -> ' ' . (i+1) . '. ' . fnamemodify(bufname(b), ':t') . (getbufvar(b, "&modified") ? ' +' : '')})
    silent! call deletebufline(l:bufnr, 1, '$')
    call setbufline(l:bufnr, 1, l:lines)
    call setbufvar(l:bufnr, '&modifiable', 0)
    call setbufvar(l:bufnr, 'buffer_list', l:bufs)
endfunction

" Show cheatsheet
function! ShowCheatsheet()
    enew
    setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted
    if filereadable(expand('~/.vim/cheatsheet.txt'))
        silent! read ~/.vim/cheatsheet.txt
        silent! 1delete _
    else
        call setline(1, ['', '  Welcome to Vim', '', '  Tab: switch windows', '  F5: change colorscheme', '  :q: close file/quit'])
    endif
    setlocal readonly nomodifiable
    file [Cheatsheet]
endfunction

" Setup buffer list panel
function! SetupBufferListPanel()
    setlocal buftype=nofile bufhidden=wipe noswapfile nowrap nonumber filetype=bufferlist
    file [Open\ Files]
    let b:buffer_list = []
    vertical resize 25
    setlocal winfixwidth
    nnoremap <buffer> <CR> :call OpenBuffer(line('.') - 1, 0)<CR>
    nnoremap <buffer> <LeftRelease> :call OpenBuffer(line('.') - 1, 0)<CR>
    nnoremap <buffer> j j:call OpenBuffer(line('.') - 1, 1)<CR>
    nnoremap <buffer> k k:call OpenBuffer(line('.') - 1, 1)<CR>
    for i in range(1, 9)
        execute 'nnoremap <buffer> ' . i . ' :call OpenBuffer(' . (i-1) . ')<CR>'
    endfor
endfunction

" Startup layout
function! StartupLayout()
    if argc() > 0 | return | endif
    " Create middle pane with cheatsheet
    call ShowCheatsheet()
    " Create left pane with netrw
    Vexplore
    vertical resize 30
    setlocal winfixwidth
    let g:netrw_chgwin = FindMiddleWin()
    " Create right pane with buffer list
    vertical botright new
    call SetupBufferListPanel()
    " Mark layout as ready
    let g:layout_ready = 1
    call RefreshBufferList()
    " Focus netrw
    let l:netrw = FindWinByFiletype('netrw')
    if l:netrw > 0
        call GotoWin(l:netrw)
    endif
endfunction

" Autocmds
augroup vimrc
    autocmd!
    autocmd VimEnter * call LoadSavedColorscheme() | call StartupLayout()
    autocmd VimLeave * call writefile([g:my_colors[g:my_color_idx]], g:colorscheme_file)
    autocmd WinEnter * setlocal cursorline
    autocmd WinLeave * setlocal nocursorline
    autocmd FocusGained,BufEnter * silent! checktime
    autocmd BufAdd,BufDelete * call RefreshBufferList()
    autocmd FileType netrw setlocal winfixwidth | let g:netrw_chgwin = FindMiddleWin()
    autocmd FileType netrw nnoremap <buffer> q :qall<CR>
    autocmd FileType bufferlist nnoremap <buffer> q :call CloseAllFiles()<CR>
    autocmd BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
augroup END
