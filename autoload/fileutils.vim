"{{{1 protector
if exists('s:loaded_plugin')
    finish
endif
let s:loaded_plugin=1
"{{{1 GetDirContents :: (path) -> [filenames]
function fileutils#GetDirContents(directory)
    if type(a:directory)!=type("") || !isdirectory(a:directory)
        return -1
    endif
    " fnamemodify adds trailing path separator when expanding with :p
    let fullpath=fnamemodify(a:directory, ':p')[:-2]
    return s:GetDirContents(fullpath)
endfunction
if has('python')
    try
        python import vim
        python import os
        function s:GetDirContents(directory)
            python import os, vim
            python vim.command('return ['+','.join(['"'+(x.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n'))+'"' for x in os.listdir(vim.eval('a:directory'))])+']')
        endfunction
    catch
    endtry
elseif has('python3')
    try
        py3 import vim
        py3 import os
        function s:GetDirContents(directory)
            py3 import os, vim
            py3 vim.command('return ['+','.join(['"'+(x.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n'))+'"' for x in os.listdir(vim.eval('a:directory'))])+']')
        endfunction
    catch
    endtry
endif
if !exists('*s:GetDirContents')
    if os#OS=~#'unix'
        function s:GetDirContents(directory)
            let dirlist = split(glob(a:directory.'/*'),  "\n", 1)+
                        \ split(glob(a:directory.'/.*'), "\n", 1)
            let r=[]
            for directory in dirlist
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
    elseif os#OS=~#'win'
        function s:GetDirContents(directory)
            return map(split(glob(a:directory.'\\*'), "\n"), 'fnamemodify(v:val, ":t")')
        endfunction
    else
        let s:escapedPathSeparator=escape(os#pathSeparator, '`*[]\')
        function s:GetDirContents(directory)
            return map(split(glob(a:directory.
                        \s:escapedPathSeparator.'*'), "\n"), 'fnamemodify(v:val, ":t")')
        endfunction
    endif
endif

" vim: ft=vim:fenc=utf-8:tw=80:ts=4:expandtab
