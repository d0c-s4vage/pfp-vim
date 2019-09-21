" # PFP - Python Format Parser (vim plugin)
" @d0c_s4vage

" https://github.com/ycm-core/YouCompleteMe/blob/master/autoload/youcompleteme.vim
" When both versions are available, we prefer Python 3 over Python 2:
"  - faster startup (no monkey-patching from python-future);
"  - better Windows support (e.g. temporary paths are not returned in all
"    lowercase);
"  - Python 2 support will eventually be dropped.
function! s:UsingPython3()
    if has('python3')
        return 1
    endif
    return 0
endfunction

let s:using_python3 = s:UsingPython3()
let s:python_until_eof = s:using_python3 ? "python3 << EOF" : "python << EOF"
let s:python_command = s:using_python3 ? "py3 " : "py "
let s:python_import = s:using_python3 ? "py3file" : "pyfile"

let s:script_path = fnamemodify(resolve(expand('<sfile>:p')), ':h:h') . '/pfp_plugin.py'

function! DefinePfp()
    exec s:python_import s:script_path
endfunction

call DefinePfp()

function! PfpHandleCursorMoved()
    if &ft ==# 'pfp_dom'
        if b:pfp_dom_last_line != line('.')
            exec s:python_command "pfp_dom_cursor_moved()"
            let b:pfp_dom_last_line = line('.')
        endif
    elseif &ft ==# 'pfp_hex'
        echo "hex"
    endif
endfunction

function! DefinePfpAutoCommands()
    augroup Pfp!
        autocmd!
        autocmd CursorMoved * call PfpHandleCursorMoved()
    augroup END
endfunction

call DefinePfpAutoCommands()

highlight pfp_hex_selection ctermfg=red ctermbg=black guifg=red guibg=black

" -------------------
" -------------------

" load/init ~/.pfp
command! -nargs=0 PfpInit exec s:python_command "pfp_init(True)"

" parse the current file
command! -nargs=0 PfpParse exec s:python_command "pfp_parse()"
