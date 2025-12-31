" Minimal vim config with file navigation + command reference

" Basic settings
set nocompatible
set number
set laststatus=0
set noruler
set hidden
set wildmenu
set splitright
set splitbelow
set noswapfile
set clipboard=unnamedplus
set autoread

" Auto-reload files changed outside vim
autocmd FocusGained,BufEnter,CursorHold * checktime

" Window navigation with Tab
nnoremap <Tab> <C-w>w
nnoremap <S-Tab> <C-w>W

" netrw file explorer settings (left panel)
let g:netrw_banner = 0
let g:netrw_liststyle = 3
let g:netrw_winsize = 30
let g:netrw_altv = 1

" Make netrw open files in window 2 (middle)
function! SetNetrwTarget()
    if winnr('$') >= 2
        let g:netrw_chgwin = 2
    endif
endfunction

autocmd FileType netrw setlocal winfixwidth
autocmd FileType netrw call SetNetrwTarget()
" Close current file in middle pane
function! CloseCurrentFile()
    let l:curbuf = bufnr('%')
    let l:is_file = buflisted(l:curbuf) && getbufvar(l:curbuf, "&buftype") == "" && bufname(l:curbuf) != ""
    if !l:is_file
        return
    endif
    " Find another file buffer to switch to
    let l:bufs = filter(range(1, bufnr('$')), 'buflisted(v:val) && getbufvar(v:val, "&buftype") == "" && bufname(v:val) != "" && v:val != ' . l:curbuf)
    if !empty(l:bufs)
        " Switch to another file
        execute 'buffer ' . l:bufs[0]
        execute 'bdelete ' . l:curbuf
        call RefreshBufferList()
    else
        " No other files, show cheatsheet and go to file explorer
        call ShowCheatsheet()
        execute 'bdelete ' . l:curbuf
        call RefreshBufferList()
        call timer_start(10, {-> execute('1wincmd w')})
    endif
endfunction

" Handle :q based on which pane we're in
function! HandleQuit()
    let l:ft = &filetype
    let l:bufname = bufname('%')
    if l:ft == 'netrw'
        qall
    elseif l:ft == 'bufferlist'
        " Check if there are open files
        let l:bufs = filter(range(1, bufnr('$')), 'buflisted(v:val) && getbufvar(v:val, "&buftype") == "" && bufname(v:val) != ""')
        if empty(l:bufs)
            qall
        else
            call CloseAllFiles()
        endif
    elseif l:bufname == '[Cheatsheet]'
        " On cheatsheet, exit vim
        qall
    else
        call CloseCurrentFile()
    endif
endfunction

" Override :q and :quit commands
cnoreabbrev <expr> q getcmdtype() == ':' && getcmdline() == 'q' ? 'call HandleQuit()' : 'q'
cnoreabbrev <expr> quit getcmdtype() == ':' && getcmdline() == 'quit' ? 'call HandleQuit()' : 'quit'

" Map 'q' key in side panels
autocmd FileType netrw nnoremap <buffer> q :qall<CR>
autocmd FileType bufferlist nnoremap <buffer> q :call CloseAllFiles()<CR>

" Remember cursor position in files
autocmd BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

" Open buffer from list
function! OpenBuffer(idx)
    if !exists('b:buffer_list') || a:idx < 0 || a:idx >= len(b:buffer_list)
        return
    endif
    let l:bufnr = b:buffer_list[a:idx]
    2wincmd w
    execute 'buffer ' . l:bufnr
endfunction

" Close all open files (keep layout, show cheatsheet)
function! CloseAllFiles()
    " Get list of file buffers to close
    let l:bufs = filter(range(1, bufnr('$')), 'buflisted(v:val) && getbufvar(v:val, "&buftype") == "" && bufname(v:val) != ""')
    " Go to middle window first
    2wincmd w
    " Show cheatsheet (creates new buffer)
    call ShowCheatsheet()
    " Now delete old buffers
    for b in l:bufs
        try
            silent! execute 'bdelete ' . b
        catch
        endtry
    endfor
    " Refresh and go to file explorer after a short delay
    call RefreshBufferList()
    call timer_start(10, {-> execute('1wincmd w')})
endfunction

" Refresh the open files panel
function! RefreshBufferList()
    let l:cur_win = winnr()
    " Find buffer list window
    for i in range(1, winnr('$'))
        execute i . 'wincmd w'
        if &filetype == 'bufferlist'
            call UpdateBufferListContent()
            break
        endif
    endfor
    " Return to original window
    execute l:cur_win . 'wincmd w'
endfunction

" Show cheatsheet as background in middle pane
function! ShowCheatsheet()
    enew
    if filereadable(expand('~/.vim/cheatsheet.txt'))
        silent! read ~/.vim/cheatsheet.txt
        1delete _
    endif
    setlocal buftype=nofile
    setlocal bufhidden=wipe
    setlocal noswapfile
    setlocal readonly
    setlocal nomodifiable
    setlocal nobuflisted
    file [Cheatsheet]
endfunction

" Refresh the open files panel
function! RefreshBufferList()
    let l:cur_win = winnr()
    " Find buffer list window
    for i in range(1, winnr('$'))
        execute i . 'wincmd w'
        if &filetype == 'bufferlist'
            call UpdateBufferListContent()
            break
        endif
    endfor
    execute l:cur_win . 'wincmd w'
endfunction

function! UpdateBufferListContent()
    setlocal modifiable
    " Get list of open file buffers
    let l:bufs = filter(range(1, bufnr('$')), 'buflisted(v:val) && getbufvar(v:val, "&buftype") == "" && bufname(v:val) != ""')
    let l:lines = []
    let b:buffer_list = l:bufs
    let l:num = 1
    for b in l:bufs
        let l:name = fnamemodify(bufname(b), ':t')
        let l:mod = getbufvar(b, '&modified') ? ' +' : ''
        call add(l:lines, ' ' . l:num . '. ' . l:name . l:mod)
        let l:num += 1
    endfor
    if empty(l:lines)
        call add(l:lines, ' (no open files)')
    endif
    silent! %delete _
    call setline(1, l:lines)
    setlocal nomodifiable
endfunction

" Open layout: file explorer left, cheatsheet middle, open files right
function! StartupLayout()
    if argc() == 0
        " Start with cheatsheet in middle
        call ShowCheatsheet()
        " File explorer on left
        Vexplore
        vertical resize 30
        setlocal winfixwidth
        " Open files panel on far right
        vertical botright new
        call SetupBufferListPanel()
        " Focus file explorer (window 1)
        1wincmd w
    endif
endfunction

" Prevent window resizing
set noequalalways

function! SetupBufferListPanel()
    setlocal buftype=nofile
    setlocal bufhidden=wipe
    setlocal noswapfile
    setlocal nowrap
    setlocal nonumber
    setlocal filetype=bufferlist
    file [Open\ Files]
    call UpdateBufferListContent()
    vertical resize 25
    setlocal winfixwidth
    nnoremap <buffer> <CR> :call OpenBuffer(line('.') - 1)<CR>
    for i in range(1, 9)
        execute 'nnoremap <buffer> ' . i . ' :call OpenBuffer(' . (i-1) . ')<CR>'
    endfor
endfunction

" Auto-refresh buffer list when buffers change
autocmd BufAdd,BufDelete,BufWipeout * call RefreshBufferList()

autocmd VimEnter * call StartupLayout()
