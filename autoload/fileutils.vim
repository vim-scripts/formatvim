"{{{1 protector
if exists('s:loaded_plugin')
    finish
endif
let s:loaded_plugin=1
"{{{1 GetDirContents :: (path) -> [filenames]
function fileutils#GetDirContents(directory)
    if type(a:directory)!=type("")
        return -1
    endif
    " fnamemodify("", ":p") already gives the name of the current directory, but 
    " I am not sure whether I can rely on it
    " fnamemodify will expand ~ which isdirectory does not accept
    let fullpath=fnamemodify((empty(a:directory)?('.'):(a:directory)), ':p')
    if !isdirectory(fullpath)
        return -1
    endif
    " fnamemodify adds trailing path separator when expanding with :p, but this 
    " does not work if we are trying to get contents of the root directory using 
    " python's os.listdir: it will get empty. Added workaround into python 
    " function variants
    let fullpath=fullpath[:-2]
    return s:GetDirContents(fullpath)
endfunction
if has('python')
    try
        python import vim
        python import os
        function s:GetDirContents(directory)
            python import os, vim
            let directory=a:directory
            if empty(a:directory)
                let directory=g:os#pathSeparator
            endif
            python vim.command('return ['+','.join(['"'+(x.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n'))+'"' for x in os.listdir(vim.eval('directory'))])+']')
        endfunction
    catch
    endtry
elseif has('python3')
    try
        py3 import vim
        py3 import os
        function s:GetDirContents(directory)
            py3 import os, vim
            let directory=a:directory
            if empty(a:directory)
                let directory=g:os#pathSeparator
            endif
            py3 vim.command('return ['+','.join(['"'+(x.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n'))+'"' for x in os.listdir(vim.eval('directory'))])+']')
        endfunction
    catch
    endtry
endif
if !exists('*s:GetDirContents')
    function s:globdir(directory, ...)
        return split(glob(escape(a:directory.g:os#pathSeparator, '`*[]\').
                    \     get(a:000, 0, '*')),
                    \"\n", 1)
    endfunction
    if os#OS=~#'unix'
        function s:GetDirContents(directory)
            let dirlist = s:globdir(a:directory)+s:globdir(a:directory, '.*')
            let nlnum=len(split(a:directory, "\n", 1))-1
            let r=[]
            let i=0
            let addfragment=""
            for directory in dirlist
                if i<nlnum
                    let i+=1
                    let addfragment=directory."\n"
                    continue
                else
                    let directory=addfragment.directory
                    let i=0
                    let addfragment=""
                endif
                let tail=fnamemodify(directory, ':t')
                if tail==#'.' || tail==#'..'
                    continue
                endif
                if directory[0]!=#'/'
                    let r[-1].="\n".directory
                else
                    call add(r, tail)
                endif
            endfor
            return r
        endfunction
    else
        function s:GetDirContents(directory)
            return map(s:globdir(a:directory), 'fnamemodify(v:val, ":t")')
        endfunction
    endif
endif

" vim: ft=vim:fenc=utf-8:tw=80:ts=4:expandtab
