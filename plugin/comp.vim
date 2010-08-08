"{{{1 Начало
scriptencoding utf-8
if (exists("s:g.pluginloaded") && s:g.pluginloaded) ||
            \exists("g:compOptions.DoNotLoad")
    finish
"{{{1 Первая загрузка
elseif !exists("s:g.pluginloaded")
    "{{{2 Объявление переменных
    "{{{3 Словари с функциями
    " Функции для внутреннего использования
    let s:F={
                \"plug": {},
                \"main": {},
                \ "mod": {},
                \"comp": {},
                \ "out": {},
            \}
    lockvar 1 s:F
    "{{{3 Глобальная переменная
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
    "{{{3 sid
    function s:SID()
        return matchstr(expand('<sfile>'), '\d\+\ze_SID$')
    endfun
    let s:g.scriptid=s:SID()
    delfunction s:SID
    "}}}2
    let s:F.plug.load=load#LoadFuncdict()
    let s:g.reginfo=s:F.plug.load.registerplugin({
                \     "funcdict": s:F,
                \     "globdict": s:g,
                \      "oprefix": "comp",
                \          "sid": s:g.scriptid,
                \   "scriptfile": s:g.load.scriptfile,
                \"dictfunctions": s:g.chk.f,
                \   "apiversion": "0.1",
                \     "requires": [["load", '0.0'],
                \                  ["chk",  '0.0'],
                \                  ["stuf", '0.0']],
            \})
    let s:F.main.eerror=s:g.reginfo.functions.eerror
    finish
endif
"{{{1 Вторая загрузка
let s:g.pluginloaded=1
"{{{2 Чистка
unlet s:g.load
"{{{2 Выводимые сообщения
let s:g.p={
            \"emsg": {
            \   "idexists": "This completion ID already exists",
            \       "umod": "Unknown model",
            \},
            \"etype": {},
        \}
call add(s:g.chk.f[0][2].required[0][1][1], s:g.p.emsg.idexists)
"{{{1 Вторая загрузка — функции
"{{{2 Внешние дополнения
let s:F.plug.stuf=s:F.plug.load.getfunctions("stuf")
let s:F.plug.chk=s:F.plug.load.getfunctions("chk")
"{{{2 main: eerror, destruct
"{{{3 main.destruct: выгрузить плагин
function s:F.main.destruct()
    unlet s:g
    unlet s:F
    return 1
endfunction
"{{{2 mod
"{{{3 mod.actions
function s:F.mod.actions(comp, s)
    if a:s.arguments==[]
        return ((has_key(a:comp, "actions"))?(keys(a:comp.actions)):([]))
    endif
    if has_key(a:comp, "actions")
        let action=tolower(a:s.arguments[0])
        if len(a:s.arguments)==1 && !has_key(a:comp.actions, action)
            return s:F.comp.toarglead(a:s.arguments[-1], keys(a:comp.actions))
        endif
        if has_key(a:comp.actions, action)
            let comp=a:comp.actions[action]
            let a:s.arguments=a:s.arguments[1:]
            return s:F.mod[comp.model](comp, a:s)
        endif
    endif
    return []
endfunction
"{{{3 mod.simple
function s:F.mod.simple(comp, s)
    if has_key(a:comp, "arguments")
        let lsarg=len(a:s.arguments)
        if lsarg<=len(a:comp.arguments)
            return s:F.comp.getlist(a:comp.arguments[lsarg-1],
                        \           a:s.arguments[-1])
        endif
    endif
    return []
endfunction
"{{{3 mod.pref
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
    if has_key(a:comp, "prefix")
        if !(larg%2)
            let pref=a:s.arguments[-2]
            if has_key(a:comp.prefix, pref)
                return s:F.comp.getlist(a:comp.prefix[pref],
                            \           a:s.arguments[-1])
            endif
        else
            return s:F.comp.toarglead(a:s.arguments[-1], keys(a:comp.prefix))
        endif
    endif
    return []
endfunction
"{{{2 comp
"{{{3 comp.getlist
function s:F.comp.getlist(descr, arglead)
    let [type, Arg]=a:descr
    if type==#"merge"
        let result=[]
        for descr in Arg
            let result+=s:F.comp.getlist(descr, a:arglead)
        endfor
        return result
    elseif type==#"file"
        return s:F.comp.getfiles(a:arglead,
                    \["v:val=~?a:filter[1]",
                    \ s:F.plug.stuf.regescape(Arg).'$'])
    elseif type==#"file!"
        return s:F.comp.getfiles(a:arglead,
                    \['s:F.plug.chk.checkargument(a:filter[1], v:val)',
                    \ Arg])
    elseif type==#"first"
        for descr in Arg
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
"{{{4 s:g.comp.list
let s:g.comp={}
let s:g.comp.list={
            \"func": "call(Arg, [a:arglead], {})",
            \"list": "Arg",
            \"keyof": "keys(Arg)",
        \}
"{{{3 comp.getfiles
function s:F.comp.getfiles(arglead, filter)
    let fragments=split(a:arglead, '/')
    let globstart=''
    if a:arglead[0]==#'/'
        let globstart='/'
    endif
    if a:arglead[-1:]==#'/'
        call add(fragments, "")
    endif
    while fragments[0]==#'.' || fragments[0]==#'..'
        let globstart.=remove(fragments, 0).'/'
    endwhile
    let escapedfragments=map(copy(fragments), 's:F.plug.stuf.globescape(v:val)')
    let files=s:F.comp.recdownglob(globstart, fragments,
                \len(fragments)-1, escapedfragments)
    let newfiles=filter(copy(files), a:filter[0])
    let r=((newfiles==[])?(files):(newfiles))
    return map(r, 'substitute(v:val, "//", "/", "g")')
endfunction
"{{{3 comp.recdownglob
function s:F.comp.recdownglob(globstart, fragments, i, escapedfragments)
    if a:i<0
        return []
    endif
    let dotfragment=(a:fragments[a:i]==#'.' || a:fragments[a:i]==#'..')
    let glist=[]
    if dotfragment
        let dir=join(a:fragments[:(a:i)], '/')
        if isdirectory(dir)
            let glist=[dir]
        endif
    else
        let fstart=a:globstart.
                    \((a:i)?
                    \   (join(a:escapedfragments[:(a:i-1)],
                    \         '/')):
                    \   (""))
        if fstart!=#""
            let fstart.="/"
        endif
        for gexpr in s:g.comp.rg.glistexpr
            let glist=split(glob(eval(gexpr)), "\n")
            if glist!=[]
                break
            endif
        endfor
    endif
    if glist==[]
        return s:F.comp.recdownglob(a:globstart, a:fragments, a:i-1,
                    \               a:escapedfragments)
    endif
    if a:i==len(a:fragments)-1
        return glist
    endif
    return s:F.comp.recupglob(filter(glist, 'isdirectory(v:val)'), a:fragments,
                \             a:i+1, a:escapedfragments)
endfunction
"{{{3 comp.recupglob
function s:F.comp.recupglob(files, fragments, i, escapedfragments)
    let dotfragment=(a:fragments[a:i]==#'.' || a:fragments[a:i]==#'..')
    let glist=[]
    if dotfragment
        let glist=[join(a:fragments[:(a:i)], '/')]
    endif
    let fcur=a:escapedfragments[a:i]
    for gexpr in s:g.comp.rg.glistexpr
        let curglist=[]
        for file in a:files
            let fstart=s:F.plug.stuf.globescape(file)."/"
            let curglist+=split(glob(eval(gexpr)), "\n")
        endfor
        if curglist!=[]
            let glist=curglist
            break
        endif
    endfor
    if a:i==len(a:fragments)-1 || glist==[]
        return glist
    endif
    return s:F.comp.recupglob(filter(glist, 'isdirectory(v:val)'), a:fragments,
                \             a:i+1, a:escapedfragments)
endfunction
"{{{4 s:g.comp.rg
let s:g.comp.rg={}
let s:g.comp.rg.pregex='[[:punct:]]\@<=\|[[:punct:]]\@='
let s:g.comp.rg.glistexpr=[
            \'fstart.fcur."*"',
            \'fstart."*".fcur."*"',
            \'fstart."*".join(map(split(a:fragments[a:i], s:g.comp.rg.pregex),'.
            \                    '"s:F.plug.stuf.globescape(v:val)"), "*")."*"'
        \]
"{{{3 comp.toarglead
let s:g.comp.filters=[
            \'v:val=~#"^".reg',
            \'v:val=~?"^".reg',
            \'v:val=~#reg',
            \'v:val=~?reg',
            \'v:val=~#reg2',
            \'v:val=~?reg2',
        \]
function s:F.comp.toarglead(arglead, list)
    if type(a:list)!=type([])
        return []
    endif
    let results=[[], [], [], [], [], [], a:list]
    let reg=s:F.plug.stuf.regescape(a:arglead)
    let reg2=join(
                \map(
                \   split(a:arglead, '[[:punct:]]\@<=\|[[:punct:]]\@='),
                \   's:F.plug.stuf.regescape(v:val)'),
                \'.*')
    let list=filter(a:list, 'type(v:val)=='.type(""))
    for f in s:g.comp.filters
        let r=filter(copy(list), f)
        if r!=[]
            return r
        endif
    endfor
    return []
endfunction
"{{{3 comp.split
function s:F.comp.split(arglead, cmdline, position)
    let r={"origin": [a:cmdline, a:arglead, a:position]}
    let r.cmd=a:cmdline[:(a:position)]
    let r.range=matchstr(r.cmd, '^'.s:g.reg.range)
    let r.cmd=r.cmd[len(r.range):]
    let r.command=matchstr(r.cmd, '^\(\u[[:alnum:]_]*\)!\=')
    let r.cmd=r.cmd[len(r.command):]
    let r.arguments=split(r.cmd)
    if a:arglead==#""
        call add(r.arguments, '')
    endif
    return r
endfunction
"{{{4 s:g.reg
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
"{{{3 comp.main
function s:F.comp.main(comp, arglead, cmdline, position)
    let s=s:F.comp.split(a:arglead, a:cmdline, a:position)
    return s:F.mod[a:comp.model](a:comp, s)
endfunction
"{{{4 Проверки
let s:g.chk.alist=["alllst",]
let s:g.chk.list=["and", [["len", [2]],
            \             ["eval", 'type(a:Arg[0])==type("")'],
            \             ["or", [["chklst", [["equal", "merge"],
            \                                 s:g.chk.alist]],
            \                     ["chklst", [["equal", "func"],
            \                                 ["type", 2]]],
            \                     ["chklst", [["equal", "func!"],
            \                                 ["type", 2]]],
            \                     ["chklst", [["equal", "list"],
            \                                 ["alllst", ["type", type("")]]]],
            \                     ["chklst", [["equal", "file"],
            \                                 ["type", type("")]]],
            \                     ["chklst", [["equal", "file!"],
            \                                 ["type", type([])]]],
            \                     ["chklst", [["equal", "first"],
            \                                 s:g.chk.alist]],
            \                     ["chklst", [["equal", "keyof"],
            \                                 ["type", type({})]]]]]]]
call add(s:g.chk.alist, s:g.chk.list)
let s:g.chk.pref=["dict", [[["any", ""], s:g.chk.list]]]
let s:g.chk.model=["and",]
let s:g.chk.actions=["dict", [[["any", ""], s:g.chk.model]]]
call add(s:g.chk.model,  [["hkey", "model"],
            \             ["dict", [[["equal", "model"], ["keyof", s:F.mod]],
            \                       [["equal", "actions"], s:g.chk.actions],
            \                       [["equal", "arguments"], s:g.chk.alist],
            \                       [["equal", "prefix"], s:g.chk.pref]]]])
let s:g.chk.f[0][2].required[1]=s:g.chk.model
"{{{2 out
"{{{3 out.constructcompletion
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
"{{{3 out.delcompletion
function s:F.out.delcompletion(id)
    unlet s:g.out[a:id]
endfunction
"{{{1
lockvar! s:F
lockvar s:g
unlockvar! s:g.out
let t=s:F
" vim: ft=vim:ts=8:fdm=marker:fenc=utf-8

