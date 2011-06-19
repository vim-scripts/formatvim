"▶1 Header
scriptencoding utf-8
execute frawor#Setup('0.0', {'@/resources': '0.0'}, 1)
"▶1 os resource
let s:os={}
"▶2 os.fullname
for s:os.fullname in ['unix', 'win16', 'win32', 'win64', 'win32unix', 'win95',
            \         'mac', 'macunix', 'amiga', 'os2', 'qnx', 'beos', 'vms']
    if has(s:os.fullname)
        break
    endif
    let s:os.fullname='unknown'
endfor
"▶2 os.name
if s:os.fullname[-3:] is# 'nix' || s:os.fullname[:2] is# 'mac' ||
            \s:os.fullname is# 'qnx' || s:os.fullname is# 'vms'
    let s:os.name='posix'
elseif s:os.fullname[:2] is# 'win'
    let s:os.name='nt'
elseif s:os.fullname is# 'os2'
    let s:os.name='os2'
else
    let s:os.name='other'
endif
"▲2
let s:os.sep=fnamemodify(expand('<sfile>:h'), ':p')[-1:]
"▶2 os.linesep
if s:os.name is# 'nt'
    let s:os.linesep="\r\n"
elseif s:os.fullname[:2] is# 'mac'
    let s:os.linesep="\r"
else
    let s:os.linesep="\n"
endif
"▶2 os.pathsep
if s:os.name is# 'nt' || s:os.name is# 'os2'
    let s:os.pathsep=';'
else
    let s:os.pathsep=':'
endif
"▶2 os.path
let s:os.path={}
"▶3 os.path.abspath   :: path + FS → path
function s:os.path.abspath(path)
    let path=fnamemodify(a:path, ':p')
    " Purge trailing path separator
    return ((isdirectory(path) && len(path)>1)?(path[:-2]):(path))
endfunction
"▶3 os.path.realpath  :: path + FS → path
function s:os.path.realpath(path)
    return resolve(s:os.path.abspath(a:path))
endfunction
"▶3 os.path.basename  :: path → component
function s:os.path.basename(path)
    return fnamemodify(a:path, ':t')
endfunction
"▶3 os.path.dirname   :: path → path
function s:os.path.dirname(path)
    return fnamemodify(a:path, ':h')
endfunction
"▶3 os.path.join      :: path[, path[, ...]] | [path] → path
"▶4 s:eps
if s:os.name is# 'nt'
    let s:eps='[/\\]'
else
    let s:eps='\V'.escape(s:os.sep, '\')
endif
"▲4
function s:os.path.join(...)
    let components=copy((a:0 && type(a:1)==type([]))?
                \           (a:1):
                \           (a:000))
    call filter(components, 'type(v:val)=='.type(""))
    return substitute(join(components, s:os.sep), s:eps.'\+',
                \     escape(s:os.sep, '\&~'), 'g')
endfunction
"▶3 os.path.split     :: path → [component]
" Note: unlike python's one, this splits into a list of components
function s:os.path.split(path)
    let r=[]
    let path=a:path
    let oldpath=''
    while oldpath isnot# path
        call insert(r, s:os.path.basename(path))
        let oldpath=path
        let path=s:os.path.dirname(path)
    endwhile
    if !empty(r) && empty(r[0])
        let r[0]=path
    endif
    return r
endfunction
"▶3 os.path.normpath  :: path → path
function s:os.path.normpath(path)
    return s:os.path.join(s:os.path.split(a:path))
endfunction
"▶3 os.path.samefile  :: path, path + FS → Bool
function s:os.path.samefile(path1, path2)
    return (s:os.path.normpath(s:os.path.realpath(a:path1))==
                \s:os.path.normpath(s:os.path.realpath(a:path2)))
endfunction
"▶3 os.path.exists    :: path + FS → Bool
function s:os.path.exists(path)
    return !empty(glob(fnameescape(a:path)))
endfunction
"▶3 os.path.isdir     :: path + FS → Bool
function s:os.path.isdir(path)
    return isdirectory(s:os.path.abspath(a:path))
endfunction
"▶3 os.path.isfile    :: path + FS → Bool
function s:os.path.isfile(path)
    return s:os.path.exists(a:path) && !s:os.path.isdir(a:path)
endfunction
"▶3 os.path.walk      :: path, F[, arg] + FS
function s:os.path.walk(path, Func, ...)
    let arg=get(a:000, 0, 0)
    let path=s:os.path.abspath(a:path)
    let files=s:os.listdir(path)
    call call(a:Func, [arg, path, files], {})
    call map(filter(map(files, 's:os.path.join(path, v:val)'),
                \   's:os.path.isdir(v:val)'),
                \'s:os.path.walk(v:val, a:Func, arg)')
endfunction
"▶2 os.listdir        :: path[, keepdirname] + FS → [component]
"▶3 s:F.globdir
function s:F.globdir(directory, ...)
    let r=split(glob(fnameescape(a:directory.s:os.sep).
               \     get(a:000, 0, '*')),
               \"\n", 1)
    return ((len(r)==1 && empty(r[0]))?([]):(r))
endfunction
"▲3
function s:os.listdir(path, ...)
    let path=s:os.path.abspath(a:path)
    let filelist=s:F.globdir(path)
    if s:os.name is# 'posix'
        let filelist+=s:F.globdir(path, '.*')
    else
        call filter(filelist, '!empty(v:val)')
        return ((a:0)?(filelist):(map(filelist, 'fnamemodify(v:val, ":t")')))
    endif
    let nlnum=len(substitute(path, '[^\x0A]', '', 'g'))
    let r=[]
    let i=0
    let addfragment=''
    for file in filelist
        if i==0 && file[:0] isnot# '/'
            let r[-1].="\n".file
            continue
        elseif i<nlnum
            let i+=1
            let addfragment.=file."\n"
            continue
        else
            let file=addfragment.file
            let i=0
            let addfragment=''
        endif
        let tail=fnamemodify(file, ':t')
        if tail is# '.' || tail is# '..'
            continue
        endif
        call add(r, ((a:0)?(file):(tail)))
    endfor
    return r
endfunction
"▶2 os.chdir          :: path[, Bool] → Bool + WD
function s:os.chdir(path, ...)
    if s:os.path.isdir(a:path)
        try
            execute ((a:0 && a:1)?('lcd'):('cd')) fnameescape(a:path)
            return 1
        catch
            return 0
        endtry
    endif
    return 0
endfunction
"▶2 os.run            :: command[, cwd::path] → String + sh
let s:opts={
            \ 'eventignore': 'all',
            \   'autowrite':   0,
            \'autowriteall':   0,
            \  'lazyredraw':   1,
        \}
function s:os.run(command, ...)
    let hasnewlines=!empty(filter(copy(a:command), 'stridx(v:val, "\n")>0'))
    if s:os.name is# 'nt'
        let cmd=escape(a:command[0], '\ %')
        if len(a:command)>1
            let cmd.=' '.join(map(a:command[1:],
                        \'((v:val=~#"^[[:alnum:]/\\-]\\+$")?'.
                        \   '(v:val):'.
                        \   '(shellescape(v:val, hasnewlines)))'))
        endif
    else
        let cmd=join(map(copy(a:command), 'shellescape(v:val, hasnewlines)'))
    endif
    try
        if a:0
            let savedopts={}
            for [opt, val] in items(s:opts)
                let savedopts[opt]=eval('&g:'.opt)
                execute 'let &g:'.opt.'='.val
            endfor
            new
            if !s:os.chdir(a:1, 1)
                bwipeout
                return -1
            endif
        endif
        if hasnewlines
            execute 'silent! !'.cmd
        else
            call system(cmd)
        endif
        redraw!
        return v:shell_error
    finally
        if exists('savedopts')
            for [opt, val] in items(savedopts)
                execute 'let &g:'.opt.'='.val
            endfor
        endif
    endtry
endfunction
"▶2 mkdir, makedirs
if exists('*mkdir')
    "▶3 os.makedirs       :: path[, mode] → Bool + FS
    function s:os.makedirs(path, ...)
        let mode=get(a:000, 0, 0755)
        let tocreate=[]
        let path=a:path
        while !s:os.path.isdir(path)
            call insert(tocreate, path)
            let path=s:os.path.dirname(path)
        endwhile
        try
            call map(tocreate, 'mkdir(v:val, "", '.mode.')')
            return 1
        catch
            return 0
        endtry
    endfunction
    "▶3 os.mkdir          :: path[, mode] → Bool + FS
    function s:os.mkdir(path, ...)
        let mode=get(a:000, 0, 0755)
        if !s:os.path.isdir(s:os.path.dirname(a:path))
            return 0
        endif
        try
            call mkdir(a:path, '', mode)
            return 1
        catch
            return 0
        endtry
    endfunction
    "▲3
endif
"▶2 os.unlink         :: path + FS → Bool + FS
function s:os.unlink(path)
    return delete(a:path) is# 0
endfunction
let s:os.remove=s:os.unlink
"▶2 os.rmdir          :: path → Bool + FS
function s:os.rmdir(path)
    let path=s:os.path.normpath(s:os.path.realpath(a:path))
    if !(s:os.path.isdir(path) && empty(s:os.listdir(path)))
        return 0
    endif
    if s:os.name is# 'posix'
        if executable('rmdir')
            return !s:os.run(['rmdir', path])
        elseif executable('rm') && empty(s:os.listdir(path))
            return !s:os.run(['rm', '-r', path])
        endif
    elseif s:os.name is# 'nt'
        " For some reason |executable()| function does not work
        return ((!s:os.run(['rmdir', path])) || (!s:os.run(['deltree', path])))
    endif
    return 0
endfunction
"▶2 os.removedirs     :: path → UInt + FS
function s:os.removedirs(path)
    let path=s:os.path.normpath(a:path)
    let prevpath=''
    let i=0
    while path isnot# '.' && path isnot# prevpath && s:os.rmdir(path)
        let prevpath=path
        let path=s:os.path.dirname(path)
        let i+=1
    endwhile
    return i
endfunction
"▶2 os.removetree     :: path → Bool + FS
function s:os.removetree(path)
    if s:os.path.isdir(a:path)
        let path=s:os.path.normpath(s:os.path.realpath(a:path))
        let toremove=[path]
        let files=s:os.listdir(path, 1)
        while !empty(files)
            let file=remove(files, 0)
            " Trying to unlink file before testing whether it is a directory 
            " prevents occasinal recursion into symbolic links
            if !s:os.unlink(file)
                if s:os.path.isdir(file)
                    let files+=s:os.listdir(file, 1)
                    call insert(toremove, file)
                else
                    return 0
                endif
            endif
        endwhile
        for directory in toremove
            if !s:os.rmdir(directory)
                return 0
            endif
        endfor
    else
        return s:os.unlink(a:path)
    endif
endfunction
"▶2 os.walk           :: path + FS → [(path, [ component ], [ component ])]
function s:os.walk(path)
    let r=[]
    let dirs=[s:os.path.normpath(a:path)]
    let processed=[]
    while !empty(dirs)
        let dir=remove(dirs, 0)
        "▶3 Check whether directory was already processed
        let realdir=s:os.path.realpath(dir)
        if index(processed, realdir)!=-1
            continue
        endif
        call add(processed, realdir)
        "▲3
        let cur=[dir, [], []]
        call add(r, cur)
        let files=s:os.listdir(dir)
        for file in files
            let fullname=s:os.path.join(dir, file)
            if s:os.path.isdir(fullname)
                call add(dirs, fullname)
                call add(cur[1], file)
            else
                call add(cur[2], file)
            endif
        endfor
    endwhile
    return r
endfunction
"▶2 post resource
call s:_f.postresource('os', s:os)
"▶1
call frawor#Lockvar(s:, '')
" vim: fmr=▶,▲ sw=4 ts=4 sts=4 et tw=80
