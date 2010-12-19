"▶1 Начало
scriptencoding utf-8
if (exists("s:g.pluginloaded") && s:g.pluginloaded) ||
            \exists("g:compOptions.DoNotLoad")
    finish
"▶1 Первая загрузка
elseif !exists("s:g.pluginloaded")
    "▶2 Объявление переменных
    "▶3 Словари с функциями
    " Функции для внутреннего использования
    let s:F={
                \"plug": {},
                \"main": {},
                \ "mod": {},
                \"comp": {},
                \ "out": {},
                \"stuf": {},
            \}
    lockvar 1 s:F
    "▶3 Глобальная переменная
    let s:g={}
    let s:g.pluginloaded=0
    let s:g.load={}
    let s:g.out={}
    let s:g.chk={}
    let s:g.chk.id=["type", type("")]
    let s:g.chk.id_comp=["and", [s:g.chk.id,
                \                ["not", ["keyof", s:g.out]]]]
    let s:g.load.scriptfile=expand("<sfile>")
    let s:g.srccmd="source ".(s:g.load.scriptfile)
    let s:g.chk.f=[
                \["ccomp",     "out.constructcompletion",
                \       {   "model": "simple",
                \        "required": [s:g.chk.id_comp,
                \                     ["type", type({})]]}],
                \["delcomp", "out.delcompletion",
                \       {   "model": "simple",
                \        "required": [["keyof", s:g.out]]}],
            \]
    let s:g.plugname=fnamemodify(s:g.load.scriptfile, ":t:r")
    "▶3 sid
    function s:SID()
        return matchstr(expand('<sfile>'), '\d\+\ze_SID$')
    endfun
    let s:g.scriptid=s:SID()
    delfunction s:SID
    "▲2
    let s:F.plug.load=load#LoadFuncdict()
    let s:g.reginfo=s:F.plug.load.registerplugin({
                \     "funcdict": s:F,
                \     "globdict": s:g,
                \      "oprefix": "comp",
                \          "sid": s:g.scriptid,
                \   "scriptfile": s:g.load.scriptfile,
                \"dictfunctions": s:g.chk.f,
                \   "apiversion": "0.6",
                \     "requires": [["load", '0.7'],
                \                  ["chk",  '0.3'],
                \                  ["stuf", '0.0']],
                \      "preload": [["fileutils", "autoload"],
                \                  ["os",        "autoload"]],
            \})
    let s:F.main.eerror=s:g.reginfo.functions.eerror
    let s:F.main.option=s:g.reginfo.functions.option
    finish
endif
"▶1 Вторая загрузка
let s:g.pluginloaded=1
"▶2 Чистка
unlet s:g.load
"▶2 Выводимые сообщения
let s:g.p={
            \"emsg": {
            \   "idexists": "This completion ID already exists",
            \       "umod": "Unknown model",
            \   "filefail": "Failed to load file %s ".
            \               "which is part of vim-fileutils plugin",
            \},
            \"etype": {
            \   "imp": "ImportError",
            \},
        \}
call add(s:g.chk.f[0][2].required[0][1][1], s:g.p.emsg.idexists)
"▶1 Вторая загрузка — функции
"▶2 Внешние дополнения
let s:F.plug.stuf=s:F.plug.load.getfunctions("stuf")
let s:F.plug.chk=s:F.plug.load.getfunctions("chk")
"▶3 plug.file
let s:F.plug.file={}
let s:F.plug.file.getDirContents=function('fileutils#GetDirContents')
"▶4 s:g.plug.file
let s:g.plug={"file": {}}
let s:g.plug.file.pathseparator=os#pathSeparator
let s:g.plug.file.os=os#OS
let s:g.plug.file.eps=s:F.plug.stuf.regescape(s:g.plug.file.pathseparator)
"▶2 main: eerror, option, destruct
"▶3 s:g.defaultOptions, s:g.c.options
let s:g.defaultOptions={
            \"TrailingSeparator": 1,
        \}
let s:g.c={}
let s:g.c.options={
            \"TrailingSeparator": ["bool", ""],
        \}
"▶3 main.destruct: выгрузить плагин
function s:F.main.destruct()
    unlet s:g
    unlet s:F
    return 1
endfunction
"▶2 stuf
"▶3 stuf.gettrun
function s:F.stuf.gettrun(trun, fulls)
    if type(a:fulls)==type({})
        let fulls=keys(a:fulls)
    else
        let fulls=copy(a:fulls)
    endif
    if index(fulls, a:trun)!=-1
        return a:trun
    endif
    let ltrun=len(a:trun)-1
    for full in fulls
        if full[:ltrun]==?a:trun
            return full
        endif
    endfor
    return a:trun
endfunction
"▶2 mod
"▶3 mod.actions
function s:F.mod.actions(comp, s)
    if empty(a:s.arguments)
        return get(a:comp, "actions", [])
    endif
    if has_key(a:comp, "actions")
        let action=tolower(a:s.arguments[0])
        if len(a:s.arguments)==1 && !has_key(a:comp.actions, action)
            return s:F.comp.toarglead(a:s.arguments[-1], keys(a:comp.actions))
        endif
        if get(a:comp, 'allowtrun', 1)
            let action=s:F.stuf.gettrun(action, a:comp.actions)
        endif
        if !has_key(a:comp.actions, action)
            return []
        endif
        let comp=a:comp.actions[action]
        let a:s.arguments=a:s.arguments[1:]
        return s:F.mod[comp.model](comp, a:s)
    endif
    return []
endfunction
"▶3 mod.simple
function s:F.mod.simple(comp, s)
    if has_key(a:comp, "arguments")
        let lsarg=len(a:s.arguments)
        if lsarg && lsarg<=len(a:comp.arguments)
            return s:F.comp.getlist(a:comp.arguments[lsarg-1],
                        \           a:s.arguments[-1])
        endif
    endif
    return []
endfunction
"▶3 mod.pref
function s:F.mod.pref(comp, s)
    let larg=len(a:s.arguments)
    if has_key(a:comp, "arguments")
        let lcarg=len(a:comp.arguments)
        if larg<=lcarg
            return s:F.mod.simple(a:comp, a:s)
        else
            let a:s.arguments=a:s.arguments[(lcarg):]
        endif
    endif
    let larg=len(a:s.arguments)
    if has_key(a:comp, "prefix") || has_key(a:comp, "altpref")
        let preflist=get(a:comp, 'preflist', [])
        let allowtrun=get(a:comp, 'allowtrun', 1) && empty(preflist)
        let omitpresent=get(a:comp, 'omitpresent', 1)
        let altpref=get(a:comp, 'altpref', [])
        let prefdict=get(a:comp, 'prefix', {})
        let hasaltpref=!empty(altpref)
        let chk=keys(prefdict)+altpref
        let prefomit={}
        let args=a:s.arguments
        let largs=len(args)
        let prevprefidx=-1
        let lastprefidx=0
        let inlistprefix=0
        let isaltpref=0
        while lastprefidx<largs
            let prevprefidx=lastprefidx
            let pref=args[lastprefidx]
            if allowtrun
                let fullpref=s:F.stuf.gettrun(pref, chk)
                if empty(fullpref) && hasaltpref && pref[:1]==#'no'
                    let fullpref=s:F.stuf.gettrun(pref[2:], altpref)
                    if !empty(fullpref)
                        let isaltpref=2
                    else
                        let isaltpref=0
                    endif
                else
                    let isaltpref=0
                endif
                let pref=fullpref
            elseif index(chk, pref)==-1 && pref[:1]==#'no' &&
                        \index(altpref, pref[2:])
                let pref=pref[2:]
                let isaltpref=2
            else
                let isaltpref=0
            endif
            if omitpresent && lastprefidx!=largs-1 && !empty(pref)
                let prefomit[pref]=1
            endif
            if !isaltpref
                let isaltpref=(index(altpref, pref)!=-1)
                if !has_key(prefdict, pref)
                    let lastprefidx+=1
                    let inlistprefix=0
                elseif index(preflist, pref)==-1
                    let lastprefidx+=2
                    let inlistprefix=0
                else
                    let lastprefidx+=1
                    let inlistprefix=1
                    let arg=get(args, lastprefidx)
                    while lastprefidx<largs &&
                                \(!has_key(prefdict, arg) ||
                                \ (hasaltpref && arg[:1]==#'no' &&
                                \  index(altpref, arg[2:])==-1))
                        let lastprefidx+=1
                        unlet arg
                        let arg=get(args, lastprefidx)
                    endwhile
                    unlet arg
                endif
            else
                let lastprefidx+=1
                let inlistprefix=0
            endif
        endwhile
        let prefixes=keys(prefdict)+
                    \filter(copy(altpref), '!has_key(prefdict, v:val)')
        call filter(prefixes, '!has_key(prefomit, v:val)')
        let pref=args[prevprefidx]
        if allowtrun
            let fullpref=s:F.stuf.gettrun(pref, prefdict)
            if empty(fullpref) && hasaltpref && pref[:1]==#'no'
                let fullpref=s:F.stuf.gettrun(pref[2:], altpref)
            endif
            let pref=fullpref
        endif
        let result=[]
        if inlistprefix || isaltpref || prevprefidx==largs-1
            let tofilter=copy(prefixes)
            if hasaltpref
                let tofilter+=map(filter(copy(prefixes),
                            \          'index(altpref, v:val)!=-1'),
                            \   '"no".v:val')
            endif
            let result+=s:F.comp.toarglead(a:s.arguments[-1], tofilter)
        endif
        if has_key(prefdict, pref)
            let result+=s:F.comp.getlist(prefdict[pref], a:s.arguments[-1])
        endif
        return result
    endif
    return []
endfunction
"▶3 mod.words
function s:F.mod.words(comp, s)
    if has_key(a:comp, "words")
        return s:F.comp.getlist(a:comp.words, a:s.arguments[-1])
    endif
    return []
endfunction
"▶2 comp
let s:g.comp={}
"▶3 comp.getlist
function s:F.comp.getlist(descr, arglead)
    let [type, l:Arg]=a:descr
    let forcefilter=0
    if type[0]==#'='
        let type=type[1:]
        let forcefilter=1
    endif
    if type==#"merge"
        let result=[]
        for descr in l:Arg
            let result+=s:F.comp.getlist(descr, a:arglead)
        endfor
        return result
    elseif type==#"file"
        if type(l:Arg)==2
            return s:F.comp.getfiles(a:arglead,
                        \['call(a:filter[1], file, {})', l:Arg], forcefilter)
        elseif type(l:Arg)==type("")
            let filter=[]
            let regex=[]
            while !empty(l:Arg)
                let char=l:Arg[0]
                let l:Arg=l:Arg[1:]
                if char==#'d'
                    call add(filter, 'isdirectory(file)')
                elseif char==#'r'
                    call add(filter, 'filereadable(file)')
                elseif char==#'w'
                    call add(filter, 'filewritable(file)==1')
                elseif char==#'W'
                    call add(filter, 'filewriteable(file)')
                elseif char==#'.'
                    let ext=matchstr(l:Arg, '^\%(\\.\|[^\\/.]\)')
                    let l:Arg=l:Arg[len(ext):]
                    call add(regex, s:F.plug.stuf.regescape(
                                \'.'.substitute(ext, '\\\(.\)', '\1', 'g').'$'))
                elseif char==#'/'
                    let reg=matchstr(l:Arg, '^\%(\\.\|[^\\/]\)')
                    let l:Arg=l:Arg[len(ext):]
                    call add(regex, reg)
                endif
            endwhile
            return s:F.comp.getfiles(a:arglead,
                        \[(empty(filter)?
                        \   (''):
                        \   ('('.join(filter, ' || ').')')).
                        \ (empty(regex)?
                        \   (""):
                        \   (((empty(filter))?(''):(' && ')).
                        \    '(isdirectory(file)?'.
                        \       '(1):'.
                        \       '(file=~?'.string(join(regex, '\|')).'))'))],
                        \forcefilter)
        endif
    elseif type==#"file!"
        return s:F.comp.getfiles(a:arglead,
                    \['s:F.plug.chk.checkargument(a:filter[1], file)',
                    \ l:Arg], forcefilter)
    elseif type==#"first"
        for descr in l:Arg
            let result=s:F.comp.getlist(descr, a:arglead)
            if result!=[]
                return result
            endif
        endfor
        return []
    elseif type==#"func!"
        return eval(s:g.comp.list.func)
    endif
    return s:F.comp.toarglead(a:arglead, eval(s:g.comp.list[type]))
endfunction
"▶4 s:g.comp.list
let s:g.comp.list={
            \"func": "call(l:Arg, [a:arglead], {})",
            \"list": "l:Arg",
            \"keyof": "keys(l:Arg)",
        \}
"▶3 comp.getfiles
function s:F.comp.getfiles(arglead, filter, forcefilter)
    let fragments=split(a:arglead, s:g.plug.file.eps)
    let globstart=''
    if a:arglead[0]==#s:g.plug.file.pathseparator
        let globstart=s:g.plug.file.pathseparator
    endif
    if a:arglead[-1:]==#s:g.plug.file.pathseparator
        call add(fragments, "")
    endif
    while !empty(fragments) && (fragments[0]==#'.' || fragments[0]==#'..')
        let globstart.=remove(fragments, 0).s:g.plug.file.pathseparator
    endwhile
    if empty(fragments)
        call add(fragments, "")
    endif
    let files=s:F.comp.recdownglob(globstart, fragments,
                \                  len(fragments)-1)
    let r=files
    if !empty(a:filter[0])
        let newfiles=[]
        for f in files
            let file=fnamemodify(f, ':p')
            if isdirectory(file) || eval(a:filter[0])
                call add(newfiles, f)
            endif
        endfor
        if !empty(newfiles) || a:forcefilter
            let r=newfiles
        endif
    endif
    if s:F.main.option("TrailingSeparator")
        " isdirectory(fnamemodify(v:val, ':p')) is used instead of 
        " isdirectory(v:val) because isdirectory() cannot handle '~' as the 
        " first fragemnt
        call map(r, '((isdirectory(fnamemodify(v:val, ":p")))?'.
                    \   '(v:val.s:g.plug.file.pathseparator):'.
                    \   '(v:val))')
    endif
    return map(r, 'substitute(v:val, s:g.plug.file.eps."\\{2}", '.
                \   '"\\=s:g.plug.file.pathseparator", "g")')
endfunction
"▶3 comp.recdownglob
function s:F.comp.recdownglob(globstart, fragments, i)
    if a:i<0
        return []
    endif
    let dotfragment=(a:fragments[a:i]==#'.' || a:fragments[a:i]==#'..')
    let glist=[]
    if dotfragment
        let dir=join(a:fragments[:(a:i)], s:g.plug.file.pathseparator)
        " isdirectory(fnamemodify(dir, ':p')) is used instead of 
        " isdirectory(dir) because isdirectory() cannot handle '~' as the 
        " first fragemnt
        if isdirectory(fnamemodify(dir, ":p"))
            let glist=[dir]
        endif
    else
        let curdir=a:globstart.
                    \    ((a:i)?
                    \       (join(a:fragments[:(a:i-1)],
                    \             s:g.plug.file.pathseparator)):
                    \       (""))
        let fullcurdir=fnamemodify(curdir, ':p')
        if isdirectory(fullcurdir)
            let fcur=a:fragments[a:i]
            let dircontents=s:F.plug.file.getDirContents(fullcurdir)
            let glist=s:F.comp.toarglead(fcur, dircontents)
            if !empty(curdir)
                call map(glist, 'curdir.(s:g.plug.file.pathseparator).v:val')
            endif
        endif
    endif
    if empty(glist)
        return s:F.comp.recdownglob(a:globstart, a:fragments, a:i-1)
    endif
    if a:i==len(a:fragments)-1
        return glist
    endif
    " isdirectory(fnamemodify(v:val, ':p')) is used instead of 
    " isdirectory(v:val) because isdirectory() cannot handle '~' as the first 
    " fragemnt
    return s:F.comp.recupglob(filter(glist,
                \                    'isdirectory(fnamemodify(v:val, ":p"))'),
                \             a:fragments, a:i+1)
endfunction
"▶3 comp.recupglob
function s:F.comp.recupglob(files, fragments, i)
    let dotfragment=(a:fragments[a:i]==#'.' || a:fragments[a:i]==#'..')
    let glist=[]
    if dotfragment
        let glist=[join(a:fragments[:(a:i)], s:g.plug.file.pathseparator)]
    endif
    let fcur=a:fragments[a:i]
    let directories={}
    let reg=s:F.plug.stuf.regescape(fcur)
    let reg2=join(
                \map(
                \   split(fcur, s:g.comp.splitreg),
                \   's:F.plug.stuf.regescape(v:val)'),
                \'.*')
    for filter in s:g.comp.filters
        for file in a:files
            let curdir=file
            if has_key(directories, curdir)
                let dircontents=directories[curdir]
            else
                let dircontents=s:F.plug.file.getDirContents(curdir)
                let directories[curdir]=dircontents
            endif
            let tmpglist=filter(copy(dircontents), filter)
            if !empty(tmpglist)
                if !empty(curdir)
                    let tmpglist=map(tmpglist,
                                \    'curdir.(s:g.plug.file.pathseparator).'.
                                \            'v:val')
                endif
                let glist+=tmpglist
            endif
        endfor
        if !empty(glist)
            break
        endif
    endfor
    if a:i==len(a:fragments)-1 || empty(glist)
        return glist
    endif
    " isdirectory(fnamemodify(v:val, ':p')) is used instead of 
    " isdirectory(v:val) because isdirectory() cannot handle '~' as the first 
    " fragemnt
    return s:F.comp.recupglob(filter(glist,
                \                    'isdirectory(fnamemodify(v:val, ":p"))'),
                \             a:fragments, a:i+1)
endfunction
"▶4 s:g.comp.rg
let s:g.comp.rg={}
let s:g.comp.rg.pregex='[[:punct:]]\@<=\|[[:punct:]]\@='
"▶3 comp.toarglead
let s:g.comp.filters=[
            \'v:val=~#"^".reg',
            \'v:val=~?"^".reg',
            \'v:val=~#reg',
            \'v:val=~?reg',
            \'v:val=~#reg2',
            \'v:val=~?reg2',
        \]
let s:g.comp.splitreg='[[:punct:]]\@<=\|[[:punct:]]\@='
function s:F.comp.toarglead(arglead, list)
    if type(a:list)!=type([])
        return []
    endif
    let results=[[], [], [], [], [], [], a:list]
    let reg=s:F.plug.stuf.regescape(a:arglead)
    let reg2=join(
                \map(
                \   split(a:arglead, s:g.comp.splitreg),
                \   's:F.plug.stuf.regescape(v:val)'),
                \'.*')
    let list=filter(copy(a:list), 'type(v:val)=='.type(""))
    for f in s:g.comp.filters
        let r=filter(copy(list), f)
        if r!=[]
            return r
        endif
    endfor
    return []
endfunction
"▶3 comp.split
let s:g.comp.argsplitregex='\(\\\@<!\(\\.\)*\\\)\@<! '
function s:F.comp.split(comp, input, ...)
    let r={"origin": []}
    " arglead, cmdline, postion -> cmdline, arglead, position
    call add(r.origin, get(a:000, 1, ""))
    call add(r.origin, get(a:000, 0, ""))
    call add(r.origin, get(a:000, 2, 0))
    let splitreg=get(a:comp, 'argsplitregex', s:g.comp.argsplitregex)
    if a:input==0
        let r.cmd=r.origin[0][:(r.origin[2])]
        let r.range=matchstr(r.cmd, '^'.s:g.reg.range)
        let r.cmd=r.cmd[len(r.range):]
        let r.command=matchstr(r.cmd, '^\(\u[[:alnum:]_]*\)!\=')
        let r.cmd=r.cmd[len(r.command):]
    elseif a:input==1
        let r.cmd=r.origin[0]
        let r.range=""
        let curwordstart=matchstr(r.origin[0][:(r.origin[2]-1)],
                    \             '\(\\.\|[^ ]\)*$')
        let curwordend=matchstr(r.origin[0], '^\(\\.\|[^ ]\)*', r.origin[2])
        let curword=curwordstart.curwordend
        let start=r.origin[2]-len(curwordstart)
        let end=r.origin[2]+len(curwordend)-1
        let r.cmd=r.cmd[:(end)]
        if start
            let r.prefix=r.cmd[:(start-1)]
        else
            let r.prefix=""
        endif
    elseif a:input==2
        let r.origin[2]=col('.')-1
        let r.cmd=getline('.')[:(col('.')-2)]
        let r.range=""
        let r.start=s:F.comp.getstart(a:comp, r.cmd)
        if type(r.start)!=type(0) || r.start<=0
            return 0
        endif
        let curword=r.cmd[(r.start-1):]
        let r.arguments=split(r.cmd[:(r.start-2)], splitreg)+[curword]
        return r
    endif
    let r.arguments=split(r.cmd, splitreg)
    if (a:input && empty(curword)) || (!a:input && empty(r.origin[1]))
        call add(r.arguments, '')
    endif
    return r
endfunction
"▶4 s:g.reg
let s:g.reg={}
let s:g.reg.range='\(%\|'.
            \       '\('.
            \         '\(\d\+\|'.
            \           '[.$]\|'.
            \           '''.\|'.
            \           '\\[/?&]\|'.
            \           '/\([^\\/]\|\\.\)\+/\=\|'.
            \           '?\([^\\?]\|\\.\)\+?\='.
            \         '\)'.
            \         '\([+-]\d\+\)\='.
            \         '[;,]\='.
            \       '\)*'.
            \     '\)\='
"▶3 comp.getstart
"▶4 s:g.comp.start
let s:g.comp.start={
            \"regexs": {
            \   '_cword': '\%(\k*\|\%(\k\@!\S\)*\)$',
            \   '_cWORD': '\S*$',
            \   '_cfile': '\f*$',
            \}
        \}
"▲4
function s:F.comp.getstart(comp, line)
    let l:Start=get(a:comp, 'start', '_cword')
    if type(l:Start)==type('')
        if l:Start[0]=='_'
            let l:Start=get(s:g.comp.start.regexs, l:Start, l:Start)
        endif
        return matchstr(a:line, l:Start)+1
    else
        return call(l:Start, [a:line], {})
    endif
endfunction
"▶3 comp.main
function s:F.comp.main(comp, ...)
    let model=a:comp.model
    let input=0
    if model[:4]==#'input'
        let model=model[5:]
        let input=1
    elseif model[:5]==#'insert'
        let model=model[6:]
        let input=2
    endif
    let s=call(s:F.comp.split, [a:comp, input]+a:000, {})
    if empty(s)
        if input!=2
            return []
        else
            return ""
        endif
    endif
    let r=s:F.mod[model](a:comp, s)
    let escape=get(a:comp, "escape", ((input==0)?1:0))
    if escape==1
        call map(r, 'escape(v:val, "\\| \"\n")')
    elseif escape==2
        call map(r, 'fnameescape(v:val)')
    endif
    if input==1
        call map(r, 's.prefix . v:val')
    elseif input==2
        call complete(s.start, r)
        return ""
    endif
    return r
endfunction
"▶4 Проверки
let s:g.chk.alist=["alllst",]
let s:g.chk.list=["and", [["len", [2]],
            \             ["eval", 'type(a:Arg[0])==type("")'],
            \             ["or", [["chklst", [["equal", "merge"],
            \                                 s:g.chk.alist]],
            \                     ["chklst", [["equal", "func"],
            \                                 ["isfunc", 0]]],
            \                     ["chklst", [["equal", "func!"],
            \                                 ["isfunc", 0]]],
            \                     ["chklst", [["equal", "list"],
            \                                 ["alllst", ["type", type("")]]]],
            \                     ["chklst", [["regex", '^=\?file$'],
            \                                 ["type", type("")]]],
            \                     ["chklst", [["regex", '^=\?file!$'],
            \                                 ["type", type([])]]],
            \                     ["chklst", [["equal", "first"],
            \                                 s:g.chk.alist]],
            \                     ["chklst", [["equal", "keyof"],
            \                                 ["type", type({})]]]]]]]
call add(s:g.chk.alist, s:g.chk.list)
let s:g.chk.pref=["dict", [[["any", ""], s:g.chk.list]]]
let s:g.chk.model=["and",]
let s:g.chk.actions=["dict", [[["any", ""], s:g.chk.model]]]
let s:g.chk.modcheck=["in", keys(s:F.mod)+map(keys(s:F.mod), '"input".v:val')
            \                            +map(keys(s:F.mod), '"insert".v:val'),
            \         s:g.p.emsg.umod]
let s:g.chk.insertstart=["or", [["isfunc", 1],
            \                   ["keyof", s:g.comp.start.regexs],
            \                   ["isreg", '']]]
let s:g.chk.preflist=["alllst", ['type', type("")]]
call add(s:g.chk.model,  [["hkey", "model"],
            \             ["dict", [[["equal", "model"], s:g.chk.modcheck],
            \                       [["equal", "actions"], s:g.chk.actions],
            \                       [["equal", "arguments"], s:g.chk.alist],
            \                       [["equal", "prefix"], s:g.chk.pref],
            \                       [["equal", "words"], s:g.chk.list],
            \                       [["equal", "start"], s:g.chk.insertstart],
            \                       [["equal", "argsplitregex"], ["isreg", '']],
            \                       [["equal", "escape"], ["in", [0, 1, 2]]],
            \                       [["equal", "allowtrun"], ["bool", ""]],
            \                       [["equal", "preflist"], s:g.chk.preflist],
            \                       [["equal", "altpref"],  s:g.chk.preflist],
            \                       [["equal", "omitpresent"], ["bool", ""]],
            \                      ]]])
let s:g.chk.f[0][2].required[1]=s:g.chk.model
"▶2 out
"▶3 out.constructcompletion
function s:F.out.constructcompletion(id, comp)
    let s:g.out[a:id]=[a:comp]
    let id=s:F.plug.stuf.squote(a:id)
    let r={}
    execute      "function r._complete(...)\n".
                \"    return call(s:F.comp.main, s:g.out[".id."]+".
                \           "a:000, {})\n".
                \"endfunction"
    return r._complete
endfunction
"▶3 out.delcompletion
function s:F.out.delcompletion(id)
    unlet s:g.out[a:id]
endfunction
"▶1
lockvar! s:F
lockvar s:g
unlockvar! s:g.out
let t=s:F
" vim: ft=vim:ts=4:et:sts=4:fdm=marker:fmr=▶,▲:fenc=utf-8

