"{{{1 protector
if exists('s:loaded_plugin')
    finish
endif
let s:loaded_plugin=1
"{{{1 Os :: os
let os#OS="unknown"
for s:os in ["unix", "win16", "win32", "win64", "win32unix", "win95",
            \"mac", "macunix", "amiga", "os2", "qnx", "beos", "vms"]
    if has(s:os)
        let os#OS=s:os
        break
    endif
endfor
unlet s:os
lockvar os#OS
"{{{2 os :: pathSeparator
let os#pathSeparator=fnamemodify(expand('<sfile>:h'), ':p')[-1:]
let s:ps=os#pathSeparator
lockvar os#pathSeparator s:ps
"{{{1 Exec :: ([{command}, {arguments}][, {cwd}]) -> retstatus
function os#Exec(cmd, ...)
    if type(a:cmd)!=type([])
                \|| empty(filter(a:cmd, 'type(v:val)=='.type("")))
                \|| (!empty(a:000)
                \    && (type(a:000[0])!=type("")
                \        || !isdirectory(a:000[0])))
        return -1
    endif
    return s:Exec(a:cmd, get(a:000, 0, 0))
endfunction
if has("python") || has("python/dyn")
    try
        python import subprocess
        python import vim
        function s:Exec(cmd, cwd)
            python import subprocess
            python import vim
            if type(a:cwd)==type(0)
                python vim.command("return "+str(subprocess.Popen(vim.eval("a:cmd"), stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE).wait()))
            else
                python vim.command("return "+str(subprocess.Popen(vim.eval("a:cmd"), cwd=vim.eval("a:cwd"), stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE).wait()))
            endif
        endfunction
    endtry
elseif has("python3") || has("python3/dyn")
    try
        py3 import subprocess
        py3 import vim
        function s:Exec(cmd, cwd)
            py3 import subprocess
            py3 import vim
            if type(a:cwd)==type(0)
                py3 vim.command("return "+str(subprocess.Popen(vim.eval("a:cmd"), stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE).wait()))
            else
                py3 vim.command("return "+str(subprocess.Popen(vim.eval("a:cmd"), cwd=vim.eval("a:cwd"), stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE).wait()))
            endif
        endfunction
    endtry
endif
if !exists("*s:Exec")
    if os#OS=~#'^win' && os#OS!~#'unix'
        function s:Exec(cmd, cwd)
            let cmd=a:cmd[0]
            call escape(cmd, '\ ')
            let savedeventignore=&eventignore
            if type(a:cwd)!=type(0)
                set eventignore=all
                new
                execute "lcd ".fnameescape(a:cwd)
            endif
            call system(cmd.' '.join(map(a:cmd[1:], 'shellescape(v:val, 1)')))
            if type(a:cwd)!=type(0)
                bwipeout
                let &eventignore=savedeventignore
            endif
            redraw
            return v:shell_error
        endfunction
    else
        function s:Exec(cmd, cwd)
            let savedeventignore=&eventignore
            if type(a:cwd)!=type(0)
                set eventignore=all
                new
                execute "lcd ".fnameescape(a:cwd)
            endif
            call system(join(map(a:cmd, 'shellescape(v:val, 1)')))
            if type(a:cwd)!=type(0)
                bwipeout
                let &eventignore=savedeventignore
            endif
            redraw
            return v:shell_error
        endfunction
    endif
endif
"{{{1 JoinPath :: filename, filename, ... -> filename
let s:eps=escape(s:ps, '^$*~[].\')
function os#JoinPath(...)
    let components=filter(copy(a:000), 'type(v:val)=='.type(""))
    if len(components)<2
        return -1
    endif
    let r=substitute(s:JoinPath(components), s:eps.'\{2,}', '\=s:ps', 'g')
    if r[-1:]==#s:ps
        return r[:-2]
    endif
    return r
endfunction
if os#OS=~#'^win' && os#OS!~'unix'
    if exists('+shellslash')
        function s:JoinPath(components)
            let r=join(a:components, s:ps)
            if &shellslash
                return substitute(r, '\\', '/', 'g')
            else
                return substitute(r, '/', '\\', 'g')
            endif
        endfunction
    else
        function s:JoinPath(components)
            return substitute(join(a:components, s:ps), '/', '\\', 'g')
        endfunction
    endif
else
    function s:JoinPath(components)
        return join(a:components, s:ps)
    endfunction
endif

" vim: ft=vim:fenc=utf-8:tw=80:ts=4:expandtab
