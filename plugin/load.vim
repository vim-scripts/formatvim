"{{{1 Начало
"{{{2
scriptencoding utf-8
if (exists("s:g.pluginloaded") && s:g.pluginloaded) ||
            \exists("g:loadOptions.DoNotLoad")
    finish
endif
"{{{2 Объявление переменных
"{{{3 Словари с функциями
" Функции для внутреннего использования
let s:F={
            \"plug": {},
            \"cons": {},
            \"stuf": {},
            \"main": {},
            \ "mng": {},
            \ "reg": {},
            \"comm": {},
            \"comp": {},
            \"maps": {},
            \ "int": {},
            \  "au": {},
            \ "ses": {},
        \}
lockvar 1 s:F
"{{{3 Глобальная переменная
let s:g={}
let s:g.c={}
let s:g.load={}
let s:g.pluginloaded=1
let s:g.load.scriptfile=expand("<sfile>")
"{{{4 sid
function s:SID()
    return matchstr(expand('<sfile>'), '\d\+\ze_SID$')
endfunction
let s:g.scriptid=s:SID()
delfunction s:SID
"{{{4 Настройки по умолчанию
let s:g.c.options={
            \"DisableLoadChecks": ["bool", ""],
        \}
let s:g.defaultOptions={
            \"DisableLoadChecks": 1,
        \}
lockvar! s:g.defaultOptions
"{{{3 Команды и функции
" Определяет команды. Для значений ключей словаря см. :h :command. Если 
" некоторому ключу «key» соответствует непустая строка «str», то в аргументы 
" :command передаётся -key=str, иначе передаётся -key. Помимо ключей 
" :command, в качестве ключа словаря также используется строка «func». Ключ 
" «func» является обязательным и содержит функцию, которая будет вызвана при 
" запуске команды (без префикса s:F.).
let s:g.load.commands={
            \"Command": {
            \      "nargs": '+',
            \       "func": "mng.main",
            \   "complete": "customlist,s:_complete",
            \},
        \}
" Список видимых извне функции
let s:g.load.functions=[["Funcdict", "comm.rdict", {}]]
"{{{2 Выводимые сообщения
let s:g.p={
            \"emsg": {
            \    "1dct": "First argument to this function must be a dictionary",
            \    "2str": "Second argument to this function must be ".
            \            'a non-empty string',
            \    "bool": "Value must equal either to 0 or to 1",
            \   "procd": "While processing option %s for plugin %s ".
            \            "from dictionary %s found an error",
            \    "proc": "While processing option %s for plugin %s ".
            \            "found an error",
            \     "str": "Option must have type String",
            \   "fpref": "Function prefix must start either with g: or with a ".
            \            "capital latin letter and contain latin letters and ".
            \            "numbers",
            \   "cpref": "Command prefix must start with a capital latin ".
            \            "letter and contain latin letters and numbers",
            \    "preg": "Plugin “%s” was already registered",
            \   "nplug": "Failed to find plugin %s",
            \   "nfunc": "Failed to find function %s",
            \    "ireg": "Invalid registration dictionary",
            \    "iopt": "Invalid option",
            \    "uopt": "Failed to find option %s",
            \   "cexst": "Failed to create command “%s” for plugin “%s”: ".
            \            "command already exists",
            \   "fexst": "Failed to create function “%s” for plugin “%s”: ".
            \            "function already exists",
            \   "imdef": "Invalid “s:g.defaultOptions._maps”",
            \   "ukmap": "Failed to find options for mapping named “%s” ".
            \            "defined in plugin “%s”",
            \   "ebmap": "Buffer mapping “%s” already defined by plugin %s",
            \   "egmap": "Global mapping “%s” already defined by plugin %s",
            \   "majap": "Major api version mismatch (%s required by %s): ".
            \            "%u≠%u",
            \   "minap": "Minor api version mismatch (%s required by %s): ".
            \            "%u<%u",
            \    "nreq": "Failed to load dependencies for plugin %s",
            \   "sesdw": "Unable to write to directory %s that contains ".
            \            "session file",
            \   "sesfx": "Unable to overwrite %s file",
            \   "sesnf": "Failed to create session file",
            \   "yamlf": "Failed to load yaml plugin",
            \    "sesr": "While restoring a session, failed to load plugin %s",
            \    "wext": "Wrong vim script extension: “%s” (should be “vim”)",
            \},
            \"etype": {
            \    "value": "InvalidValue",
            \   "syntax": "SyntaxError",
            \   "option": "InvalidOption",
            \     "perm": "PermissionDenied",
            \     "nfnd": "NotFound",
            \    "ofail": "OperationFailed",
            \      "req": "RequirementsUnsatisfied",
            \},
            \"th": ["Type", "Name", "File", "Status"],
            \"nfnd": "Not found",
        \}
lockvar! s:g.p
"{{{2 s:g.c.reg
let s:g.c.reg={}
let s:g.c.reg.func='^g:[[:alnum:]_]\+\|\u[[:alnum:]_]*$'
let s:g.c.reg.cmd='^\u[[:alnum:]_]*$'
let s:g.c.reg.tf='^[[:alnum:]_]\+$'
let s:g.c.reg.rf='^\([[:alnum:]_]\+.\)*[[:alnum:]_]\+$'
lockvar! s:g.c.reg
"{{{2 s:g.maps
let s:g.maps={}
let s:g.maps.created_buffer={}
let s:g.maps.created_global={}
let s:g.maps.bufmaps=[]
let s:g.maps.mapcommands={
            \" ": "noremap",
            \"!": "noremap!",
        \}
call map(["n", "v", "x", "s", "o", "i", "l", "c"],
            \'extend(s:g.maps.mapcommands, {(v:val): (v:val."noremap")})')
lockvar 1 s:g.maps
"{{{1 Функции
"{{{2 cons: eerror, option
"{{{3 cons.eerror
function s:F.cons.eerror(plugin, from, type, ...)
    let etype=((type(a:type)==type("") &&
                \   exists("a:plugin.g.p.etype") &&
                \   type(a:plugin.g.p.etype)==type({}) &&
                \   has_key(a:plugin.g.p.etype, a:type))?
                \(a:plugin.g.p.etype[a:type]):
                \(s:F.stuf.string(a:type)))
    let emsg=((exists("a:plugin.g.p.emsg") &&
                \   type(a:plugin.g.p.emsg)==type({}))?
                \(a:plugin.g.p.emsg):
                \({}))
    let dothrow=0
    let outmsgs=[]
    let args=a:000
    if len(args) && type(args[0])==type(0)
        let dothrow=!!args[0]
        let args=args[1:]
    endif
    for e in args
        if type(e)==type([])
            if e!=[] && type(e[0])==type("") && has_key(emsg, e[0])
                if len(e)>1
                    call add(outmsgs, call("printf",
                                \[s:F.stuf.string(emsg[e[0]])]+e[1:]))
                else
                    call add(outmsgs, emsg[e[0]])
                endif
            else
                call add(outmsgs, s:F.stuf.string(e))
            endif
        elseif type(e)==type("")
            call add(outmsgs, e)
        else
            call add(outmsgs, s:F.stuf.string(e))
        endif
        unlet e
    endfor
    let comm="(".join(outmsgs, ': ').")"
    let msg=(a:plugin.type.'/'.a:plugin.name)."/".
                \s:F.stuf.string(a:from).":".(etype).(comm)
    echohl ErrorMsg
    echo msg
    echohl None
    if dothrow
        throw msg
    endif
    return 0
endfunction
"{{{3 cons.option
"{{{4 s:g.c.maps
let s:g.c.maps=["dict", [[["any", ""], ["type", type("")]]]]
"}}}4
function s:F.cons.option(plugin, option)
    let selfname="cons.option"
    "{{{4 Объявление переменных
    if type(a:option)!=type("")
        return s:F.cons.eerror(a:plugin, selfname, "value", 1, s:g.p.emsg.str,
                    \s:F.stuf.string(a:option))
    endif
    let oname=(a:plugin.optionprefix)."Options"
    let defaults=((exists("a:plugin.g.defaultOptions") &&
                \   type(a:plugin.g.defaultOptions)==type({}))?
                \(a:plugin.g.defaultOptions):
                \({}))
    "{{{4 Настройка _maps
    if a:option==#"_maps"
        let r=[{}, {}, {}]
        if has_key(a:plugin, "mappings")
            if !s:F.plug.chk.checkargument(s:g.c.intmaps, a:plugin.mappings)
                return s:F.cons.eerror(a:plugin, selfname, "value", 1,
                            \          printf(s:g.p.emsg.proc, a:option,
                            \                 a:plugin.name),
                            \          s:g.p.emsg.imdef)
            endif
            let r[2]=a:plugin.mappings
        else
            return r
        endif
        if exists("b:".oname) && has_key(b:{oname}, "_maps")
            if !s:F.plug.chk.checkargument(s:g.c.maps, b:{oname}._maps)
                return s:F.cons.eerror(a:plugin, selfname, "value", 1,
                            \          printf(s:g.p.emsg.procd, a:option,
                            \                 a:plugin.name, 'b:'.oname),
                            \          s:g.p.emsg.iopt)
            endif
            let r[0]=b:{oname}._maps
        endif
        if exists("g:".oname) && has_key(g:{oname}, "_maps")
            if !s:F.plug.chk.checkargument(s:g.c.maps, g:{oname}._maps)
                return s:F.cons.eerror(a:plugin, selfname, "value", 1,
                            \          printf(s:g.p.emsg.procd, a:option,
                            \                 a:plugin.name, 'g:'.oname),
                            \          s:g.p.emsg.iopt)
            endif
            let r[1]=g:{oname}._maps
        endif
        return r
    "{{{4 Настройка _leader
    elseif a:option==#"_leader"
        if exists("g:".oname) && has_key(g:{oname}, "_leader")
            if type(g:{oname}._leader)==type("")
                return g:{oname}._leader
            else
                return s:F.cons.eerror(a:plugin, selfname, "value", 1,
                            \          printf(s:g.p.emsg.procd, a:option,
                            \                 a:plugin.name, 'g:'.oname),
                            \          s:g.p.emsg.iopt)
            endif
        elseif has_key(a:plugin, "leader")
            return a:plugin.leader
        endif
        return ""
    "{{{4 Настройка _disablemaps
    elseif a:option==#"_disablemaps"
        let r=0
        if exists("g:".oname) && has_key(g:{oname}, "_disablemaps")
            let r=!!(g:{oname}._disablemaps)
        elseif has_key(defaults, a:option)
            let r=!!(defaults[a:option])
        endif
        if index([0, 1], r)==-1
            return s:F.main.eerror(selfname, 'option', 1,
                        \          ["procd", a:option, a:plugin.name,
                        \                    'g:'.oname],
                        \          ["bool"])
        endif
        return r
    "{{{4 Настройки _cprefix и _fprefix
    elseif a:option==#"_cprefix" || a:option==#"_fprefix"
        let pref=a:plugin[a:option[1:]]
        if exists("g:".oname) && has_key(g:{oname}, a:option)
            let pref=g:{oname}[a:option]
        endif
        if type(pref)!=type("")
            return s:F.main.eerror(selfname, 'option', 1,
                        \          ["procd", a:option, a:plugin.name,
                        \           'g:'.oname],
                        \          ["str"], s:F.stuf.string(pref))
        elseif a:option[1]==#"c" && pref!~#s:g.c.reg.cmd
            return s:F.main.eerror(selfname, 'option', 1,
                        \          ["procd", a:option, a:plugin.name,
                        \           'g:'.oname],
                        \          ["fpref"], pref)
        elseif a:option[1]==#"f" && pref!~#s:g.c.reg.func
            return s:F.main.eerror(selfname, 'option', 1,
                        \          ["procd", a:option, a:plugin.name,
                        \           'g:'.oname],
                        \          ["cpref"], pref)
        endif
        return pref
    endif
    "{{{4 Настройка _disable_option_checks
    let noCheck=0
    let noCheckSrc=''
    if exists('g:'.oname) && has_key(g:{oname}, '_disable_option_checks')
        let noCheck=g:{oname}._disable_option_checks
        let noCheckSrc='g:'.oname.'._disable_option_checks'
    elseif exists('g:loadOptions') &&
                \has_key(g:loadOptions, 'DisableOptionChecks')
        let noCheck=g:loadOptions.DisableOptionChecks
        let noCheckSrc='g:loadOptions.DisableOptionChecks'
    endif
    if index([0, 1], noCheck)==-1
        return s:F.main.eerror(selfname, 'option', 1,
                    \          ["procd", '_disable_option_checks',
                    \                    a:plugin.name, noCheckSrc],
                    \          ["bool"])
    endif
    if a:option==#'_disable_option_checks'
        return noCheck
    endif
    "{{{4 chk
    let chk=((!noCheck && exists("a:plugin.g.c.options") &&
                \   type(a:plugin.g.c.options)==type({}) &&
                \   has_key(a:plugin.g.c.options, a:option))?
                \(a:plugin.g.c.options[a:option]):
                \(0))
    "{{{4 Получить настройку
    if exists("b:".oname) && has_key(b:{oname}, a:option)
        let src='b'
        let retopt=b:{oname}[a:option]
    elseif exists("g:".oname) && has_key(g:{oname}, a:option)
        let src='g'
        let retopt=g:{oname}[a:option]
    else
        if has_key(defaults, a:option)
            return defaults[a:option]
        else
            return s:F.cons.eerror(a:plugin, selfname, "value", 1,
                        \          printf(s:g.p.emsg.uopt, a:option))
        endif
    endif
    "{{{4 Проверить правильность
    let optstr=a:option."/".src
    if type(chk)!=type(0) && !s:F.plug.chk.checkargument(chk, retopt)
        return s:F.cons.eerror(a:plugin, selfname, "value", 1,
                    \          printf(s:g.p.emsg.procd, a:option, a:plugin.name,
                    \                 src.':'.oname),
                    \          s:g.p.emsg.iopt)
    endif
    "}}}4
    return retopt
endfunction
"{{{2 stuf: findnr, findpath, printtable, fdictstr, string, ...
"{{{3 s:Eval: доступ к внутренним переменным
" Внутренние переменные, в том числе s:F, недоступны в привязках
function s:Eval(var)
    return eval(a:var)
endfunction
let s:F.int["s:Eval"]=function("s:Eval")
"{{{3 stuf.squote
function s:F.stuf.squote(str)
    return "'".substitute(substitute(a:str, "'", '&&', 'g'),
                \         '\n', '''."\\n".''', 'g')."'"
endfunction
"{{{3 stuf.mapprepare
function s:F.stuf.mapprepare(str)
    return escape(substitute(
                \  substitute(
                \   substitute(
                \    substitute(a:str, '<', '<LT>', 'g'),
                \   ' ', '<SPACE>', 'g'),
                \  '\t', '<Tab>', 'g'),
                \ '\n', '<CR>', 'g') , '|')
endfunction
"{{{3 stuf.string
function s:F.stuf.string(obj)
    if type(a:obj)==type("")
        return a:obj
    endif
    try
        let r=string(a:obj)
    catch
        redir => r
        silent echo a:obj
        redir END
        let r=r[1:]
    endtry
    return r
endfunction
"{{{3 stuf.findf: Найти функцию по номеру
function s:F.stuf.findf(nr, pos, d, depth)
    if a:depth > &maxfuncdepth-10
        return 0
    endif
    if type(a:d)==2 && string(a:d)=~#"'".a:nr."'"
        return a:pos
    elseif type(a:d)==type({})
        for [key, Value] in items(a:d)
            let pos=s:F.stuf.findf(a:nr, a:pos."/".key, Value, a:depth+1)
            unlet Value
            if type(pos)==type("")
                return pos
            endif
        endfor
    endif
    return 0
endfunction
"{{{3 stuf.findr: Найти функцию по номеру
function s:F.stuf.findnr(nr)
    for plugtype in keys(s:g.reg.registered)
        for [plugname, plugdict] in items(s:g.reg.registered[plugtype])
            let pos=s:F.stuf.findf(a:nr, "/".plugdict.plid, plugdict.F, 0)
            if type(pos)==type("")
                return pos
            endif
        endfor
    endfor
    if has_key(s:g.reg.unnamedfunctions, a:nr)
        return s:g.reg.unnamedfunctions[a:nr]
    endif
    return 0
endfunction
"{{{3 stuf.findpath: Найти номер функции
function s:F.stuf.findpath(path)
    let selfname="stuf.findpath"
    let s=split(a:path, '/')
    if s==[]
        return 0
    endif
    if has_key(s:g.reg.plugtypes, s[0])
        let plugtype=remove(s, 0)
    else
        let plugtype='plugin'
    endif
    let [plugname; path]=s
    if !has_key(s:g.reg.registered[plugtype], plugname)
        return s:F.main.eerror(selfname, "nfnd",
                    \["nplug", plugtype.'/'.plugname])
    endif
    let Fdict=s:g.reg.registered[plugtype][plugname].F
    for component in path
        if type(Fdict)!=type({}) || !has_key(Fdict, component)
            return 0
        endif
        let Tmp=Fdict[component]
        unlet Fdict
        let Fdict=Tmp
        unlet Tmp
    endfor
    return Fdict
endfunction
"{{{3 stuf.strlen: получение длины строки
function s:F.stuf.strlen(stuf)
    return len(split(a:stuf, '\zs'))
endfunction
"{{{3 stuf.printl: printf{'%-*s', ...}
" Напечатать {stuf}, шириной {len}, выровненное по левому краю, оставшееся 
" пространство заполнив пробелами (вместо printf('%-*s', len, stuf)).
function s:F.stuf.printl(len, stuf)
    return a:stuf . repeat(" ", a:len-s:F.stuf.strlen(a:stuf))
endfunction
"{{{3 stuf.printtline: печать строки таблицы
" Напечатать одну линию таблицы
"   {line} — список строк таблицы,
" {lenlst} — список длин
function s:F.stuf.printtline(line, lenlst)
    let result=""
    let i=0
    while i<len(a:line)
        let result.=s:F.stuf.printl(a:lenlst[i], a:line[i])
        let i+=1
        if i<len(a:line)
            let result.="  "
        endif
    endwhile
    return result
endfunction
"{{{3 stuf.printtable: напечатать таблицу
" Напечатать таблицу с заголовками рядов {headers} и линиями {lines}.
" {headers}: список строк
"   {lines}: список списков строк
function s:F.stuf.printtable(header, lines)
    let lineswh=a:lines+[a:header]
    let columns=max(map(copy(lineswh), 'len(v:val)'))
    let lenlst=[]
    let i=0
    while i<columns
        call add(lenlst, max(map(copy(lineswh),
                    \'(i<len(v:val))?s:F.stuf.strlen(v:val[i]):0')))
        let i+=1
    endwhile
    if a:header!=[]
        echohl PreProc
        echo s:F.stuf.printtline(a:header, lenlst)
        echohl None
    endif
    echo join(map(copy(a:lines), 's:F.stuf.printtline(v:val, lenlst)'), "\n")
    return 1
endfunction
"{{{3 stuf.fdictstr
function s:F.stuf.fdictstr(dict, indent)
    if a:indent > &maxfuncdepth-10
        return []
    endif
    let result=[]
    for [key, Value] in items(a:dict)
        if type(Value)==type({})
            let list=s:F.stuf.fdictstr(Value, a:indent+1)
            if list!=[]
                let result+=[[a:indent, key, ""]]+list
            endif
        elseif type(Value)==2
            call add(result, [a:indent, key, Value])
        endif
        unlet Value
    endfor
    return result
endfunction
"{{{2 main: eerror, destruct, session
"{{{3 main.destruct: Выгрузить дополнение
function s:F.main.destruct()
    for aug in ["LoadRegisterLoad", "LoadNewBuffer", "LoadDeleteBufferMappings"]
        execute 'augroup '.aug
            autocmd!
        augroup END
    endfor
    for f in keys(s:F.int)
        execute "delfunction ".f
    endfor
    if has_key(s:F.comp, "__complete")
        call s:F.plug.comp.delcomp(s:g.comp._cname)
    endif
    unlet s:F
    unlet s:g
    return 1
endfunction
"{{{3 main.session
function s:F.main.session(...)
    if empty(a:000)
        let r={}
        for [plugtype, plugins] in items(s:g.reg.registered)
            for [plugname, plugdict] in items(s:g.reg.registered[plugtype])
                let r[plugdict.plid]={
                            \"status": plugdict.status,
                            \  "type": plugdict.type,
                        \}
            endfor
        endfor
        return r
    else
        let rdict=get(a:000, 0, {})
        if type(rdict)!=type({})
            return
        endif
        for plugtype in keys(s:g.reg.registered)
            for plugname in keys(s:g.reg.registered[plugtype])
                if !has_key(rdict, plugtype.'/'.plugname)
                    call s:F.comm.unload(plugname, plugtype)
                endif
            endfor
        endfor
        for [plugname, l:Plugopts] in items(rdict)
            if type(l:Plugopts)!=type({}) || !has_key(l:Plugopts, "status") ||
                        \!has_key(l:Plugopts, "type") ||
                        \!has_key(s:g.reg.plugtypes, l:Plugopts.type)
                unlet l:Plugopts
                continue
            endif
            let plugdict=s:F.comm.getpldict(plugname, l:Plugopts.type)
            let curstatus=plugdict.status
            let status=l:Plugopts.status
            if curstatus!=#"loaded" && status==#"loaded"
                call s:F.comm.load(plugname, l:Plugopts.type)
            elseif curstatus==#""
                call s:F.main.eerror(selfname, "ofail",
                            \["sesr", l:Plugopts.type.'/'.plugname])
            endif
            unlet l:Plugopts
        endfor
    endif
endfunction
"{{{2 reg: register, unreg
"{{{3 s:g.reg
let s:g.reg={}
let s:g.reg.lazyload={}
let s:g.reg.unnamedfunctions={}
let s:g.reg.required={}
let s:g.reg.preloaded={}
let s:g.reg.mapdict=["cprefix", "fprefix", "leader", "functions",
            \        "dictfunctions", "mappings", "commands"]
let s:g.reg.plugtypes={
            \"colors": 0,
            \"plugin": 0,
            \"syntax": '&l:filetype',
            \"indent": '&l:filetype',
            \"keymap": '&l:keymap',
            \"autoload": 0,
            \"ftplugin": '&l:filetype',
            \"compiler": '((exists("b:current_compiler"))?'.
            \               '(b:current_compiler):'.
            \               '(""))',
            \"ftdetect": 0,
            \"/unknown": 0,
        \}
let s:g.reg.registered=map(copy(s:g.reg.plugtypes), '{}')
lockvar!  s:g.reg.plugtypes
lockvar!  s:g.reg.mapdict
lockvar 1 s:g.reg.registered
lockvar 1 s:g.reg
"{{{3 reg.regsource: Добавить запись о том, что плагин загружен
"{{{4 aug LoadRegisterLoad
augroup LoadRegisterLoad
    autocmd!
    autocmd SourcePre * call s:F.reg.regsource(expand('<afile>:p'))
augroup END
"}}}4
function s:F.reg.regsource(scriptname)
    silent let [plugname, plugtype, plugaddinfo, plugactinfo]=
                \s:F.reg.parsepf(a:scriptname)
    let s:g.reg.preloaded[plugtype.'/'.plugname]=1
    if has_key(s:g.reg.registered, plugtype) &&
                \has_key(s:g.reg.registered[plugtype], plugname) &&
                \s:g.reg.registered[plugtype][plugname].file==#a:scriptname &&
                \s:g.reg.registered[plugtype][plugname].status==#"registered"
        let s:g.reg.registered[plugtype][plugname].status="sourced"
    endif
endfunction
"{{{3 reg.parsepf:   Получить информацию о типе и имени дополнения
"                    из имени его файла
function s:F.reg.parsepf(filename)
    let selfname="reg.parsepf"
    let filename  = fnamemodify(a:filename, ':p:h')
    let plugname  = fnamemodify(a:filename, ':t:r')
    let extension = fnamemodify(a:filename, ':t:e')
    if extension!=#"vim"
        call s:F.main.eerror(selfname, 'value', ['wext', extension],
                    \        a:filename)
    endif
    let fragments = [plugname]
    let oldfilename=""
    let curfragment=""
    let plugtype="/unknown"
    let plugaddinfo=0
    while 1
        let curfragment = fnamemodify(filename, ':t')
        let oldfilename = filename
        let filename    = fnamemodify(filename, ':h')
        if filename==#oldfilename
            break
        elseif has_key(s:g.reg.plugtypes, curfragment)
            let plugtype=curfragment
            let plugaddinfo=s:g.reg.plugtypes[curfragment]
            break
        else
            call insert(fragments, curfragment)
        endif
    endwhile
    if plugtype[0]!=#'/'
        let plugname=join(fragments, "/")
    endif
    let plugactinfo=0
    if type(plugaddinfo)!=type(0)
        let plugactinfo=fragments[0]
    endif
    return [plugname, plugtype, plugaddinfo, plugactinfo]
endfunction
"{{{3 reg.register:  Зарегистрировать плагин
function s:F.reg.register(regdict)
    let selfname="reg.register"
    "{{{4 Проверка аргументов
    let [plugname, plugtype, plugaddinfo, plugactinfo]=
                \s:F.reg.parsepf(a:regdict.scriptfile)
    let plid=plugtype.'/'.plugname
    let regdict=s:g.reg.registered[plugtype]
    "{{{5 Если проверяющее дополнение не загружено
    if !has_key(s:g.reg.registered.plugin, "chk") &&
                \!(plugtype==#'plugin' && (plugname==#"load" ||
                \                          plugname==#"chk"))
        runtime plugin/chk.vim
    endif
    "}}}5
    if !(plugtype==#'plugin' && (plugname==#"chk" || plugname==#"load"))
        if !has_key(s:F.plug, "chk")
            let s:F.plug.chk=s:F.comm.getfunctions("chk", "plugin",
                        \                          "dictfunctions")
        endif
        if !s:F.main.option("DisableLoadChecks") &&
                    \!s:F.plug.chk.checkargument(s:g.c.register, a:regdict)
            return s:F.main.eerror(selfname, "value", 1, ["ireg"])
        endif
    endif
    if has_key(regdict, plugname)
        return s:F.main.eerror(selfname, "perm", ["preg", plid])
    endif
    "{{{4 au RegisterPluginPre, LoadPluginPre
    call s:F.au.doevent("RegisterPluginPre", plid)
    let oneload=get(a:regdict, "oneload", 0)
    if oneload
        call s:F.au.doevent("LoadPluginPre", plid)
    endif
    "{{{4 Построение записи
    let entry={
                \        "status": ((oneload)?("loaded"):("registered")),
                \       "oneload": oneload,
                \             "F": a:regdict.funcdict,
                \             "g": a:regdict.globdict,
                \      "scriptid": a:regdict.sid,
                \          "file": fnamemodify(a:regdict.scriptfile, ':p'),
                \  "extfunctions": [],
                \   "extcommands": [],
                \  "optionprefix": a:regdict.oprefix,
                \          "name": plugname,
                \    "quotedname": s:F.stuf.squote(plugname),
                \          "type": plugtype,
                \          "plid": plid,
                \       "addinfo": plugaddinfo,
                \       "actinfo": plugactinfo,
                \    "apiversion": map(split(matchstr(a:regdict.apiversion,
                \                                     '^\d\+\.\d\+'), '\.'),
                \                      'v:val+0'),
                \       "preload": [],
                \"globalmappings": {},
                \"buffermappings": {},
                \      "requires": {},
                \"requnsatisfied": {},
                \    "requiredby": {},
            \}
    if exists('*fnameescape')
        let entry.srccmd="source ".fnameescape(entry.file)
    else
        let entry.srccmd="source ".escape(entry.file, " \t\n*$`?[{\\%#'\"|!<")
    endif
    let entry.loadcmd="call s:F.comm.load(".entry.quotedname.", ".
                \                        "'".entry.type."')"
    if has_key(s:g.reg.required, plid)
        let entry.requiredby=s:g.reg.required[plid]
        unlet s:g.reg.required[plid]
    endif
    for regdictkey in s:g.reg.mapdict
        if has_key(a:regdict, regdictkey)
            let entry[regdictkey]=a:regdict[regdictkey]
        endif
    endfor
    if has_key(a:regdict, "requires")
        for req in a:regdict.requires
            let rplugname=get(req, 2, "plugin").'/'.req[0]
            let rplugversion=req[1]
            let entry.requires[rplugname]=map(
                        \                 split(
                        \                  matchstr(rplugversion,
                        \                           '^\d\+\(\.\d\+\)\='),
                        \                       '\.'), 'v:val+0')
            let entry.requnsatisfied[rplugname]=1
        endfor
    endif
    if !(entry.plid==#"plugin/load" || has_key(entry.requires, "plugin/load"))
        let entry.requires["plugin/load"]=
                    \s:g.reg.registered.plugin.load.apiversion
        let entry.requnsatisfied["plugin/load"]=1
    endif
    if has_key(a:regdict, "preload")
        call extend(entry.preload, map(copy(a:regdict.preload),
                    \'get(v:val, 1, "plugin")."/".v:val[0]'))
    endif
    let entry.intprefix='s:g.reg.registered["'.entry.type.'"]'.
                \                         '['.entry.quotedname.']'
    let locks={}
    call map(["F", "g"], 'extend(locks, {(v:val): islocked("entry.".v:val)})')
    lockvar 1 entry
    for  v  in  ["status", "extfunctions", "extcommands", "g", "F",
                \"globalmappings", "buffermappings", "requiredby"]
        if !(has_key(locks, v) && locks[v])
            unlockvar entry[v]
        endif
    endfor
    let regdict[plugname]=entry
    "{{{4 Создание функций
    let F={}
    for fname in keys(s:F.cons)
        execute      "function F.".fname."(...)\n".
                    \"    return call(s:F.cons.".fname.", ".
                    \"             [".entry.intprefix."]+".
                    \"             a:000, {})\n".
                    \"endfunction"
        let fnr=matchstr(string(F[fname]), '\d\+')
        let s:g.reg.unnamedfunctions[fnr]="cons:/".plid."/".fname
    endfor
    "{{{4 Создание привязок
    if has_key(entry, "mappings")
        call s:F.maps.create(entry)
    endif
    "}}}4
    call s:F.comm.cf(entry)
    "{{{4 au RegisterPluginPost
    call s:F.au.doevent("RegisterPluginPost", plid)
    "}}}4
    return      {     "name": plugname,
                \     "type": plugtype,
                \"functions": F}
endfunction
"{{{4 Проверки аргументов
"{{{5 Проверка для command
let s:g.c.comdict=[[["equal", "nargs" ],   ["or", [["in", ['*',
            \                                                '?',
            \                                                '+',
            \                                                '0']],
            \                                        ["regex",
            \                                          '^[1-9][0-9]*$']]]],
            \        [["equal", "range" ],   ["or", [["in", ['', '%']],
            \                                        ["regex",
            \                                          '^[1-9][0-9]*$']]]],
            \        [["equal", "count" ],   ["regex",
            \                                      '^\([1-9][0-9]*\)\=$']],
            \        [["equal", "bang"  ],   ["equal", ""]],
            \        [["equal", "reg"   ],   ["equal", ""]],
            \        [["equal", "bar"   ],   ["equal", ""]],
            \        [["equal", "complete"], ["or", [["in", ["augroup",
            \                                                "buffer",
            \                                                "command",
            \                                                "dir",
            \                                                "enviroment",
            \                                                "event",
            \                                                "expression",
            \                                                "file",
            \                                                "shellcmd",
            \                                                "function",
            \                                                "help",
            \                                                "highlight",
            \                                                "mapping",
            \                                                "menu",
            \                                                "option",
            \                                                "tag",
            \                                                "tag_listfiles",
            \                                                "var"]],
            \                                        ["regex",
            \                                 '^custom\(list\)\=,s:.*']]]],
            \        [["equal", "func"], ["regex", s:g.c.reg.rf]]]
"{{{5 s:g.c.register
let s:g.c.intmaps=["dict", [[["regex", '^\(+\)\@!'],
            \                  ["and", [["hkey", "function"],
            \                           ["dict", [[["equal", "function"],
            \                                      ["regex", s:g.c.reg.rf]],
            \                                     [["equal", "default"],
            \                                      ["type", type("")]],
            \                                     [["equal", "silent"],
            \                                      ["bool", ""]],
            \                                     [["equal", "leader"],
            \                                      ["bool", ""]],
            \                                     [["equal", "type"],
            \                                      ["keyof",
            \                                       s:g.maps.mapcommands]]]]]
            \                  ]]]]
let s:g.c.plugtype=["keyof", s:g.reg.plugtypes]
let s:g.c.funclist=["alllst",
            \       ["optlst", [[["regex", s:g.c.reg.tf],
            \                    ["regex", s:g.c.reg.rf]],
            \                   [["type", type({})],
            \                    ["alllst",
            \                     ["or", [["chklst",
            \                              [["var", 'option,buffer,window,'.
            \                                       'tabpage,global'],
            \                               ["any", ""]]],
            \                             ["chklst",
            \                              [["regex", '%\.'],
            \                               ["regex", '%\.'],
            \                               ["regex", '%\.']]]]]]]]]]
let s:g.c.dfunclist=deepcopy(s:g.c.funclist)
let s:g.c.dfunclist[1][1][0][0]=["type", type("")]
let s:g.c.register=["and", [
            \["map", ["hkey", ["oprefix",
            \                  "funcdict",
            \                  "globdict",
            \                  "sid",
            \                  "scriptfile",
            \                  "apiversion",]]],
            \["allorno", [["hkey", "fprefix"],
            \             ["hkey", "functions"]]],
            \["allorno", [["hkey", "cprefix"],
            \             ["hkey", "commands"]]],
            \["dict", [
            \   [["equal", "dictfunctions"], s:g.c.dfunclist],
            \   [["equal", "fprefix"],  ["regex", s:g.c.reg.func]],
            \   [["equal", "cprefix"],  ["regex", s:g.c.reg.cmd]],
            \   [["equal", "oprefix"],  ["regex", s:g.c.reg.tf]],
            \   [["equal", "funcdict"], [ "type", type({})]],
            \   [["equal", "globdict"], [ "type", type({})]],
            \   [["equal", "commands"], [ "dict", [[["type", type("")],
            \                                       ["dict", s:g.c.comdict]]]]],
            \   [["equal", "functions"],  s:g.c.funclist],
            \   [["equal", "mappings"],   s:g.c.intmaps],
            \   [["equal", "oneload"],    ["bool", ""]],
            \   [["equal", "sid"],        ["regex", '^[1-9][0-9]*$']],
            \   [["equal", "scriptfile"], ["and", [["file", "r"],
            \                                      ["regex", '\.vim$']]]],
            \   [["equal", "apiversion"], ["regex", '^\d\+\.\d\+']],
            \   [["equal", "requires"],   ["alllst", ["optlst",
            \                                         [[["type", type("")],
            \                                           ["regex",
            \                                            '^\d\+']],
            \                                          [s:g.c.plugtype]]]]
            \   ],
            \   [["equal", "preload"], ["alllst", ["optlst",
            \                                      [["type", type("")]],
            \                                      [s:g.c.plugtype]]]],
            \   [["equal", "leader"],     ["type", type("")]],
            \   [["any", ''], ["any", '']],
            \ ]
            \],
        \]]
"{{{3 reg.unreg:     Удалить команды и функции
function s:F.reg.unreg(plugname, plugtype)
    let plugdict=s:F.comm.getpldict(a:plugname, a:plugtype)
    for f in plugdict.extfunctions
        execute "delfunction ".f
    endfor
    for c in plugdict.extcommands
        execute "delcommand ".c
    endfor
    unlet s:g.reg.registered[a:plugtype][a:plugname]
    unlet plugdict
endfunction
"{{{2 maps: create, delmappings
"{{{3 autocommands
augroup LoadDeleteBufferMappings
    autocmd!
    autocmd BufWipeout * call s:F.maps.delmappings(expand("<abuf>"))
augroup END
augroup LoadNewBuffer
    autocmd!
    autocmd BufAdd * call s:F.maps.newbuffer(expand("<abuf>"))
augroup END
"{{{3 maps.map
function s:F.maps.map(plugdict, mapname, options, mapstring, buffer)
    let selfname="maps.map"
    "{{{4 Пустая строка
    if a:mapstring==#""
        return 1
    endif
    "{{{4 mapoptions
    if !has_key(a:options, a:mapname)
        return s:F.main.eerror(selfname, "option", ["ukmap", a:mapname,
                    \                               a:plugdict.name])
    endif
    let mapoptions=a:options[a:mapname]
    "{{{4 Тип привязки: определение команды
    let type=" "
    if has_key(mapoptions, "type")
        let type=mapoptions.type
    endif
    "{{{4 Проверка существования привязки
    if a:buffer
        let curbuffer=bufnr("%")
        if           has_key(s:g.maps.created_buffer,curbuffer) &&
                    \has_key(s:g.maps.created_buffer[curbuffer],type) &&
                    \has_key(s:g.maps.created_buffer[curbuffer][type],
                    \        a:mapstring) &&
                    \
                    \s:g.maps.created_buffer[curbuffer][type][a:mapstring][1].
                    \'/'.
                    \s:g.maps.created_buffer[curbuffer][type][a:mapstring][0]
                    \!=#a:plugdict.plid
            return s:F.main.eerror(selfname, "perm", ["ebmap", a:mapstring,
                        \s:g.maps.created_buffer[curbuffer][type][a:mapstring]
                        \[1].'/'.
                        \s:g.maps.created_buffer[curbuffer][type][a:mapstring]
                        \[0]])
        endif
    else
        if           has_key(s:g.maps.created_global,type) &&
                    \has_key(s:g.maps.created_global[type], a:mapstring) &&
                    \
                    \s:g.maps.created_global[type][a:mapstring][1].'/'.
                    \s:g.maps.created_global[type][a:mapstring][0]
                    \!=#a:plugdict.plid
            return s:F.main.eerror(selfname, "perm", ["egmap", a:mapstring,
                        \s:g.maps.created_global[type][a:mapstring][1].'/'.
                        \s:g.maps.created_global[type][a:mapstring][0]])
        endif
    endif
    let cmd=s:g.maps.mapcommands[type]
    let mapcommand=cmd." <special> <expr> "
    "{{{4 <buffer>
    if a:buffer
        let mapcommand.="<buffer> "
    endif
    "{{{4 <silent>
    if has_key(mapoptions, "silent") && mapoptions.silent
        let mapcommand.="<silent> "
    endif
    "{{{4 Основная часть команды
    let mapcommand.=s:F.stuf.mapprepare(a:mapstring)." "
    let mapcommand.='call(<SID>Eval("s:F.maps.run"), ['.
                \"'".type."', ".
                \s:F.stuf.mapprepare(s:F.stuf.squote(a:mapstring)).", ".
                \((a:buffer)?(bufnr("%")):(-1)).
                \'], {})'
    "{{{4 Создание привязки, обработка ошибок
    try
        execute mapcommand
        "{{{5 Создание записи о созданной привязке
        if a:buffer
            let curbuffer=bufnr("%")
            if !has_key(s:g.maps.created_buffer, curbuffer)
                let s:g.maps.created_buffer[curbuffer]={}
            endif
            let created=s:g.maps.created_buffer[curbuffer]
            if !has_key(a:plugdict.buffermappings, curbuffer)
                let a:plugdict.buffermappings[curbuffer]={}
            endif
            let created_plugin=a:plugdict.buffermappings[curbuffer]
        else
            let created=s:g.maps.created_global
            let created_plugin=a:plugdict.globalmappings
        endif
        if !has_key(created, type)
            let created[type]={}
        endif
        if !has_key(created_plugin, type)
            let created_plugin[type]={}
        endif
        let centry = [a:plugdict.name, a:plugdict.type, a:mapname,
                    \ copy(mapoptions)]
        let created[type][a:mapstring]=centry
        let created_plugin[type][a:mapstring]=centry
        "}}}5
        return 1
    catch
        return s:F.main.eerror(selfname, "ofail", v:exception)
    endtry
    "}}}4
endfunction
"{{{3 maps.create
function s:F.maps.create(plugdict)
    "{{{4 Объявление переменных
    let selfname="maps.create"
    let [bmaps, gmaps, options]=s:F.cons.option(a:plugdict, "_maps")
    if options=={} || s:F.cons.option(a:plugdict, "_disablemaps")
        return 0
    endif
    let leader=s:F.cons.option(a:plugdict, "_leader")
    "{{{4 Добавление локальных привязок
    for [mapname, mapstring] in items(bmaps)
        let mapname=substitute(mapname, '^{-.\{-}-}', '', '')
        if mapname[0]==#'+'
            let mapname=mapname[1:]
            let mapstring=leader.mapstring
        endif
        call s:F.maps.map(a:plugdict, mapname, options, mapstring, 1)
    endfor
    "{{{4 Добавление глобальных привязок
    for [mapname, mapstring] in items(gmaps)
        let mapname=substitute(mapname, '^{-.\{-}-}', '', '')
        if mapname[0]==#'+'
            let mapname=mapname[1:]
            let mapstring=leader.mapstring
        endif
        call s:F.maps.map(a:plugdict, mapname, options, mapstring, 0)
    endfor
    for [mapname, mapoptions] in items(options)
        if !has_key(gmaps, mapname) && has_key(mapoptions, "default")
            let mapstring=mapoptions.default
            if has_key(mapoptions, "leader") && mapoptions.leader
                let mapstring=leader.mapstring
            endif
            call s:F.maps.map(a:plugdict, mapname, options, mapstring, 0)
        endif
    endfor
    "}}}4
    return 1
endfunction
"{{{3 maps.run
function s:F.maps.run(type, mapstring, buffer)
    if a:buffer==-1
        let [plugname, plugtype, mapname, mapoptions]=
                    \             s:g.maps.created_global[a:type][a:mapstring]
    else
        let [plugname, plugtype, mapname, mapoptions]=
                    \   s:g.maps.created_buffer[a:buffer][a:type][a:mapstring]
    endif
    let plugdict=s:F.comm.getpldict(plugname, plugtype)
    if plugdict.status!=#"loaded"
        call s:F.comm.load(plugname, plugtype)
    endif
    return call(eval("plugdict.F.".(mapoptions.function)),
                \[a:type, mapname, a:mapstring, a:buffer], {})
endfunction
"{{{3 maps.unmap
function s:F.maps.unmap(plugname, plugtype, mapname, mapoptions, mapstring,
            \           buffer)
    let selfname='maps.unmap'
    let type=" "
    if has_key(a:mapoptions, "type")
        let type=a:mapoptions.type
    endif
    let unmapcommand=substitute(s:g.maps.mapcommands[type], 'nore', 'un', '').
                \" <special> ".((a:buffer!=-1)?("<buffer> "):("")).
                \s:F.stuf.mapprepare(a:mapstring)
    try
        execute unmapcommand
        if a:buffer==-1
            unlet s:g.reg.registered[a:plugtype][a:plugname].globalmappings
                        \[type][a:mapstring]
            unlet s:g.maps.created_global[type][a:mapstring]
        else
            unlet s:g.reg.registered[a:plugtype][a:plugname].buffermappings
                        \[a:buffer][type][a:mapstring]
            unlet s:g.maps.created_buffer[a:buffer][type][a:mapstring]
        endif
        return 1
    catch
        return s:F.main.eerror(selfname, "ofail", v:exception)
    endtry
endfunction
"{{{3 maps.delmappings
function s:F.maps.delmappings(what)
    "{{{4 Удаление привязок, связанных с текущим буфером
    if type(a:what)==type(0) && has_key(s:g.maps.created_buffer, a:what)
        for [type, mappings] in items(s:g.maps.created_buffer[a:what])
            for [mapstring, centry] in items(mappings)
                call call(s:F.maps.unmap, centry+[mapstring, a:what], {})
            endfor
            unlet s:g.maps.created_buffer[a:what][type]
        endfor
        unlet s:g.maps.created_buffer[a:what]
    "{{{4 Удаление привязок указанного дополнения
    elseif type(a:what)==type({})
        "{{{5 Удаление локальных привязок
        if has_key(a:what, "buffermappings")
            let savedbufnr=bufnr("%")
            let savedhidden=&hidden
            let savedbufhidden={}
            set hidden
            for [buffer, m] in items(a:what.buffermappings)
                let sbh=getbufvar(buffer, '&bufhidden')
                if index(["", "hide"], sbh)==-1
                    let savedbufhidden[buffer]=sbh
                    setlocal bufhidden=
                endif
                execute "buffer ".buffer
                for [type, mappings] in items(m)
                    for [mapstring, centry] in items(mappings)
                        call call(s:F.maps.unmap, centry+[mapstring, buffer],
                                    \{})
                    endfor
                endfor
            endfor
            execute "buffer ".savedbufnr
            call map(savedbufhidden, 'setbufvar(v:key, v:val)')
            let &hidden=savedhidden
        endif
        "{{{5 Удаление глобальных привязок
        if has_key(a:what, "globalmappings")
            for [type, mappings] in items(a:what.globalmappings)
                for [mapstring, centry] in items(mappings)
                    call call(s:F.maps.unmap, centry+[mapstring, -1], {})
                endfor
            endfor
        endif
        "}}}5
    "{{{4 Удаление привязок, связанных с удаляемым буфером
    elseif type(a:what)==type("")
        if has_key(s:g.maps.created_buffer, a:what)
            unlet s:g.maps.created_buffer[a:what]
        endif
    endif
    "}}}4
    return 1
endfunction
"{{{3 maps.newbuffer
function s:F.maps.newbuffer(buffer)
    for plugtype in keys(s:g.reg.registered)
        for plugdict in values(s:g.reg.registered[plugtype])
            let [bmaps, gmaps, options]=s:F.cons.option(plugdict, "_maps")
            if options=={}
                continue
            endif
            let leader=s:F.cons.option(plugdict, "_leader")
            for [mapname, mapstring] in items(bmaps)
                let mapname=substitute(mapname, '^{-.\{-}-}', '', '')
                if mapname[0]==#'+'
                    let mapname=mapname[1:]
                    let mapstring=leader.mapstring
                endif
                call s:F.maps.map(plugdict, mapname, options, mapstring, 1)
            endfor
        endfor
    endfor
    return 1
endfunction
"{{{2 comm: load, cf, getfunctions, lazyload, unload
"{{{3 s:g.comm
let s:g.comm={}
"{{{3 comm.parseplid
function s:F.comm.parseplid(plid)
    let plugtype=matchstr(a:plid, '/\=[^/]*')
    if !has_key(s:g.reg.registered, plugtype)
        let plugtype="plugin"
        let plugname=a:plid
    else
        let plugname=a:plid[(len(plugtype)+1):]
    endif
    return [plugname, plugtype]
endfunction
"{{{3 comm.cmdadd:       Создать команду
function s:F.comm.cmdadd(key, value, cmdargs, plugdict, command)
    "{{{4 Объявление переменных
    let result='-'.a:key
    let append=""
    "{{{4 Автодополнение
    if a:key==#"complete" && a:value=~'^custom'
        "{{{5 Объявление переменных
        " -complete=custom,func или -complete=customlist,func
        let funcname=matchstr(a:value, 'custom\(list\)\=,\zss:.*')
        " удаляем s:
        let intfunc=funcname[2:]
        let quotedintfunc="'".substitute(intfunc, "'", "''", "g")."'"
        " имя функции внутри дополнения (s:F.comp.funcname)
        let intfuncname=(a:plugdict.intprefix).'.F.comp['.quotedintfunc.']'
        " чтобы функции к разным командам не пересекались добавим имя команды 
        " к имени функции
        let realname=funcname.(a:command)
        let append=a:command
        " шаблон для автокоманды
        " // Vim 7.2: starts with P<scriptid>
        " // Vim 7.3: starts with R<scriptid> => removed P, not adding R
        let fpattern="*".(s:g.scriptid)."_".realname[2:]
        "{{{5 Если дополнение загружено
        if a:plugdict.status==#"loaded"
            "{{{6 Создание функции
            if !exists("*".realname)
                execute      "function ".realname."(...)\n".
                            \"    silent! return call(".intfuncname.", ".
                            \                        "a:000, {})\n".
                            \"endfunction"
            endif
            call add(a:plugdict.extfunctions, realname)
            "{{{6 Удаление автокоманды
            augroup LoadBeforeLoadComp
                execute "autocmd! FuncUndefined ".fpattern
            augroup END
        "{{{5 Если нет
        else
            augroup LoadBeforeLoadComp
                execute "autocmd! FuncUndefined ".fpattern
                execute "autocmd FuncUndefined ".fpattern." ".a:plugdict.loadcmd
            augroup END
        endif
        "}}}5
    endif
    "}}}4
    if a:value!=""
        let result.='='.a:value.append
    endif
    call add(a:cmdargs, result)
    return result
endfunction
"{{{3 comm.mkcmd:        Создать команду
function s:F.comm.mkcmd(cmd, plugdict)
    let selfname="comm.mkcmd"
    "{{{4 Объявление переменных
    let cmdargs=[]
    let fargs=[]
    let intfuncprefix=a:plugdict.intprefix.'.F'
    let cmddescr=a:plugdict.commands[a:cmd]
    let cmd=s:F.cons.option(a:plugdict, '_cprefix').a:cmd
    "{{{4 Получение ключей для :command
    for key in keys(cmddescr)
        if has_key(s:g.comm.cmdfargs, key)
            call s:F.comm.cmdadd(key, cmddescr[key], cmdargs, a:plugdict, cmd)
            if s:g.comm.cmdfargs[key]!=""
                call add(fargs, s:g.comm.cmdfargs[key])
            endif
        endif
    endfor
    "{{{4 Удаление старой команды
    if exists(':'.cmd)
        if index(a:plugdict.extcommands, cmd)!=-1
            execute "delcommand ".cmd
        else
            return s:F.main.eerror(selfname, "perm", ["cexst", a:plugdict.name,
                        \                             cmd])
        endif
    endif
    "{{{4 Создание команды
    execute "command ".join(cmdargs, " ")." ".cmd." ".
                \((a:plugdict.status==#"loaded")?
                \   (""):
                \   (a:plugdict.loadcmd." | ")).
                \"call ".(intfuncprefix.".".(cmddescr.func)).
                \"(".join(sort(fargs), ", ").")"
    "{{{4 Регистрация команды
    if a:plugdict.status==#"registered" ||
                \(a:plugdict.oneload && a:plugdict.status==#"loaded")
        call add(a:plugdict.extcommands, cmd)
    endif
    return 1
    "}}}4
endfunction
"{{{4 Аргументы для command
" Порядок аргументов будет (благодаря сортировке по алфавиту):
"   "'<bang>'", "'<reg>'", "<LINE1>, <LINE2>", "<count>", "<f-args>"
let s:g.comm.cmdfargs={
            \   "nargs": "<f-args>",
            \   "range": "<LINE1>, <LINE2>",
            \   "count": "<count>",
            \    "bang": "'<bang>'",
            \     "reg": "'<reg>'",
            \  "buffer": "",
            \"complete": ""
        \}
lockvar! s:g.comm.cmdfargs
"{{{3 comm.getcheck:     Создать строки проверки для аргументов функции
function s:F.comm.getcheck(check, checkstr, plugdict)
    if !empty(a:check)
        return "    let args=s:F.plug.chk.checkarguments(".a:checkstr.", ".
                    \                                   "a:000)\n".
                    \"    if type(args)!=type([])\n".
                    \"        throw 'CheckFailed(".a:plugdict.type."/'.".
                    \                              a:plugdict.quotedname.'.'.
                    \                          "')'\n".
                    \"    endif\n"
    endif
    return "let args=a:000\n"
endfunction
"{{{3 comm.getwith:      Создать строки, реализующие аналог with
function s:F.comm.getwith(withlst, plugdict)
    if !empty(a:withlst)
        let before=""
        let  after="    finally\n"
        let i=0
        for wspec in a:withlst
            let varname="l:Saved".i
            if exists(wspec[0])
                let before.=    "    let ".varname. "=".wspec[0]."\n".
                            \   "    let ".wspec[0]."=".wspec[1]."\n"
                let  after.="        let ".wspec[0]."=".varname."\n"
            else
                let before.=    "    ".substitute(wspec[0], '%\.',
                            \                     varname, 'g')."\n".
                            \   "    ".substitute(wspec[1], '%\.',
                            \                     varname, 'g')."\n"
                let  after.="        ".substitute(wspec[2], '%\.',
                            \                     varname, 'g')."\n"
            endif
            let i+=1
            unlet wspec
        endfor
        let before.= "\n    try\n"
        let  after.="    endtry\n"
        return [before, after]
    endif
    return ["", ""]
endfunction
"{{{3 comm.getfbody
function s:F.comm.getfbody(fspec, fsource, fidx, plugdict)
    let intname=a:fspec[1]
    let  acheck=get(a:fspec, 2, {})
    let    with=get(a:fspec, 3, [])
    let intfuncprefix=a:plugdict.intprefix.'.F'
    let checkstr=a:plugdict.intprefix.'.'.a:fsource.'['.a:fidx.'][2]'
    let check=s:F.comm.getcheck(acheck, checkstr, a:plugdict)
    let [before, after]=s:F.comm.getwith(with, a:plugdict)
    return            (check).
                \     (before).
                \"        return call(".intfuncprefix.".".intname.", ".
                \                    "args, s:F)\n".
                \     (after)
endfunction
"{{{3 comm.mkfuncs
" Создать функции или события FuncUndefined. Событие создаётся, если 
" plugdict.status!="loaded"
function s:F.comm.mkfuncs(plugdict)
    let selfname='comm.mkfuncs'
    if !has_key(a:plugdict, "functions")
        return 0
    endif
    let i=0
    for fspec in a:plugdict.functions
        let extname=s:F.cons.option(a:plugdict, '_fprefix').(fspec[0])
        if exists('*'.extname)
            call s:F.main.eerror(selfname, "perm", ["fexst", a:plugdict.name,
                        \                           extname])
            continue
        endif
        if a:plugdict.status==#"loaded"
            execute "function ".extname."(...)\n".
                        \s:F.comm.getfbody(fspec, "functions", i, a:plugdict)
                        \"endfunction"
            call add(a:plugdict.extfunctions, extname)
        else
            augroup LoadBeforeLoad
                execute "autocmd! FuncUndefined ".extname
                execute "autocmd FuncUndefined ".extname." ".a:plugdict.loadcmd
            augroup END
        endif
        let i+=1
    endfor
    return 1
endfunction
"{{{3 comm.cdict:        Создать словарь с функциями
function s:F.comm.cdict(plugdict, from)
    if !has_key(a:plugdict, a:from)
        return {}
    endif
    let intfuncprefix=a:plugdict.intprefix.'.F'
    let r={}
    let i=0
    for fspec in a:plugdict[a:from]
        let dictname=fspec[0]
        let  intname=fspec[1]
        execute "function r.".dictname."(...)\n".
                    \s:F.comm.getfbody(fspec, a:from, i, a:plugdict)
                    \"endfunction"
        let fnr=matchstr(string(r[dictname]), '\d\+')
        let s:g.reg.unnamedfunctions[fnr]="dict:/".(a:plugdict.name)."/".
                    \dictname." -> /".(a:plugdict.name)."/".
                    \tr(intname, '.', '/')
        let i+=1
    endfor
    return r
endfunction
"{{{3 comm.cf:           Создать команды и функции
function s:F.comm.cf(plugdict)
    for [rplid, rplugversion] in items(a:plugdict.requires)
        let [rplugname, rplugtype]=s:F.comm.parseplid(rplid)
        call s:F.comm.loadreq(a:plugdict, rplugname, rplugtype, rplugversion)
    endfor
    for rplid in a:plugdict.preload
        if !has_key(s:g.reg.preloaded, rplid)
            if a:plugdict.status==#"loaded"
                execute 'runtime! '.fnameescape(rplid)
            endif
        endif
    endfor
    if has_key(a:plugdict, "commands")
        call map(keys(a:plugdict.commands),
                    \'s:F.comm.mkcmd(v:val, a:plugdict)')
    endif
    call s:F.comm.mkfuncs(a:plugdict)
endfunction
"{{{3 comm.loadreq:      Загрузить требуемое дополнение
function s:F.comm.loadreq(plugdict, rplugname, rplugtype, rplugversion)
    let selfname='comm.loadreq'
    let rplugdict={}
    let rplid=a:rplugtype.'/'.a:rplugname
    if !has_key(s:g.reg.registered[a:rplugtype], a:rplugname)
        if !has_key(s:g.reg.required, rplid)
            let s:g.reg.required[rplid]={}
        endif
        let s:g.reg.required[rplid][a:plugdict.plid]=1
        if a:plugdict.status==#"loaded"
            let rplugdict=s:F.comm.getpldict(a:rplugname, a:rplugtype, 0)
        endif
    else
        let rplugdict=s:g.reg.registered[a:rplugtype][a:rplugname]
    endif
    if !empty(rplugdict)
        if rplugdict.apiversion[0]!=a:rplugversion[0]
            return s:F.main.eerror(selfname, "req", 1, ["majap",
                        \          rplid, a:plugdict.name,
                        \          rplugdict.apiversion[0],
                        \          a:rplugversion[0]])
        elseif len(a:rplugversion)>1 &&
                    \rplugdict.apiversion[1]<a:rplugversion[1]
            return s:F.main.eerror(selfname, "req", 1, ["minap",
                        \          rplid, a:plugdict.name,
                        \          rplugdict.apiversion[1],
                        \          a:rplugversion[1]])
        elseif !has_key(rplugdict.requiredby, a:plugdict.plid)
            let rplugdict.requiredby[a:plugdict.plid]=1
        endif
        if a:plugdict.status==#"loaded"
            if rplugdict.status!=#"loaded"
                call s:F.comm.load(a:rplugname, a:rplugtype)
            endif
            if rplugdict.status==#"loaded" && has_key(a:plugdict.requnsatisfied,
                        \                             rplid)
                unlet a:plugdict.requnsatisfied[rplid]
            endif
        endif
    elseif a:plugdict.status==#"loaded"
        return s:F.main.eerror(selfname, "req", 0, ["nplug", rplid])
    endif
endfunction
"{{{3 comm.getpldict:    Получить словарь, связанный с плагином
function s:F.comm.getpldict(plugname, plugtype, ...)
    let selfname="comm.getpldict"
    if !has_key(s:g.reg.registered[a:plugtype], a:plugname) &&
                \has_key(s:g.reg.plugtypes, a:plugtype)
        execute "runtime ".fnameescape(a:plugtype."/".a:plugname.".vim")
    endif
    if !has_key(s:g.reg.registered[a:plugtype], a:plugname)
        return s:F.main.eerror(selfname, "value", empty(a:000),
                    \          ["nplug", a:plugtype.'/'.a:plugname])
    endif
    return s:g.reg.registered[a:plugtype][a:plugname]
endfunction
"{{{3 comm.load:         Загрузить плагин
function s:F.comm.load(plugname, plugtype)
    let selfname='comm.load'
    let plid=a:plugtype.'/'.a:plugname
    call s:F.au.doevent("LoadPluginPre", plid)
    let plugdict=s:F.comm.getpldict(a:plugname, a:plugtype)
    if plugdict.status==#"loaded"
        return 1
    elseif plugdict.status!=#"sourced"
        execute plugdict.srccmd
    endif
    let plugdict.status="loaded"
    call s:F.comm.cf(plugdict)
    if !empty(plugdict.requnsatisfied)
        return s:F.main.eerror(selfname, "req",
                    \          ["nreq", plid],
                    \          join(keys(plugdict.requnsatisfied)))
    endif
    "{{{4 Ленивая загрузка
    if has_key(s:g.reg.lazyload, plid)
        while !empty(s:g.reg.lazyload[plid])
            unlockvar! s:g.reg.lazyload[plid][-1]
            let from=get(s:g.reg.lazyload[plid][-1], '_from', 'dictfunctions')
            unlet s:g.reg.lazyload[plid][-1]._plid
            unlet s:g.reg.lazyload[plid][-1]._position
            unlet s:g.reg.lazyload[plid][-1]._from
            call extend(s:g.reg.lazyload[plid][-1],
                        \s:F.comm.cdict(plugdict, from))
            unlet s:g.reg.lazyload[plid][-1]
        endwhile
    endif
    "}}}4
    call s:F.au.doevent("LoadPluginPost", plid)
    return 1
endfunction
"{{{3 comm.getfunctions: Получить функции плагина
let s:g.comm.funccache={
            \"functions": {},
            \"dictfunctions": {},
        \}
function s:F.comm.getfunctions(plugname, plugtype, from)
    let selfname="comm.getfunctions"
    let plugdict=s:F.comm.getpldict(a:plugname, a:plugtype)
    if plugdict.status!=#"loaded"
        call s:F.comm.load(a:plugname, a:plugtype)
    endif
    if has_key(s:g.comm.funccache[a:from], plugdict.plid)
        return deepcopy(s:g.comm.funccache[a:from][plugdict.plid])
    else
        let r=s:F.comm.cdict(plugdict, a:from)
        let s:g.comm.funccache[a:from][plugdict.plid]=deepcopy(r)
        return r
    endif
endfunction
"{{{3 comm.lazyload:
function s:F.comm.lazyload(plugname, plugtype, from)
    let selfname="comm.lazyload"
    let plid=a:plugtype.'/'.a:plugname
    if !has_key(s:g.reg.registered[a:plugtype], a:plugname) ||
                \s:g.reg.registered[a:plugtype][a:plugname].status!=#"loaded"
        if !has_key(s:g.reg.lazyload, plid)
            let s:g.reg.lazyload[plid]=[]
        endif
        let result={ "_plid": plid,
                    \"_largs": [a:plugname, a:plugtype],
                    \"_position": len(s:g.reg.lazyload[plid]),
                    \"_from": a:from}
        lockvar! result
        call add(s:g.reg.lazyload[plid], result)
        return result
    else
        return s:F.comm.cdict(s:g.reg.registered[a:plugtype][a:plugname],
                    \         a:from)
    endif
endfunction
"{{{3 comm.run:          Запустить функцию из «лениво» созданного словаря
function s:F.comm.run(lazydict, funcname, ...)
    let selfname="comm.run"
    if type(a:lazydict)!=type({})
        return s:F.main.eerror(selfname, "syntax", ["1dict"])
    elseif type(a:funcname)!=type("")
        return s:F.main.eerror(selfname, "syntax", ["2str"])
    endif
    if has_key(a:lazydict, "_plid") &&
                \type(a:lazydict._plid)==type("") &&
                \has_key(s:g.reg.lazyload, a:lazydict._plid) &&
                \has_key(a:lazydict, "_position") &&
                \type(a:lazydict._position)==type(0) &&
                \s:g.reg.lazyload[a:lazydict._plid][a:lazydict._position] is
                \                                                     a:lazydict
        if !call(s:F.comm.load, a:lazydict._largs, {})
            return s:F.main.eerror(selfname, "nfnd", 1,
                        \          ["nplug", a:lazydict._plid])
        endif
    endif
    if has_key(a:lazydict, a:funcname)
        return call(a:lazydict[a:funcname], a:000, a:lazydict)
    else
        return s:F.main.eerror(selfname, "nfnd", 1, ["nfunc", a:funcname])
    endif
endfunction
"{{{3 comm.rdict:        Вернуть словарь с функциями данного плагина
function s:F.comm.rdict()
    return s:F.comm.cdict(s:g.reg.registered.plugin.load, 'dictfunctions')
endfunction
let s:g.c.tstr={
            \"model": "optional",
            \"required": [["type", type("")]],
            \"optional": [[["keyof", s:g.reg.registered], {}, "plugin"]],
        \}
let s:g.c.gfchk=deepcopy(s:g.c.tstr)
call add(s:g.c.gfchk.optional,
            \[["in", ["dictfunctions", "functions"]], {}, "dictfunctions"])
lockvar! s:g.c.tstr
let s:g.comm.f=[
            \["registerplugin",   "reg.register", {}],
            \["unregister",       "reg.unreg",         s:g.c.tstr ],
            \["getfunctions",     "comm.getfunctions", s:g.c.gfchk],
            \["lazygetfunctions", "comm.lazyload",     s:g.c.gfchk],
            \["run",              "comm.run",          {}],
            \["restoresession", "ses.restore", {"model": "simple",
            \                                "required": [["file", 'r']]}],
        \]
lockvar! s:g.comm
unlockvar! s:g.comm.funccache
lockvar 1 s:g.comm.funccache
unlockvar! s:g.reg.registered
"{{{3 comm.getdep:       Получить список зависимостей (для удаления)
function s:F.comm.getdep(plugdict, hasdep)
    let r=[a:plugdict]
    for plid in keys(a:plugdict.requiredby)
        let [plugname, plugtype]=s:F.comm.parseplid(plid)
        if !has_key(a:hasdep, plid)
            let a:hasdep[plid]=1
            call extend(r, s:F.comm.getdep(s:F.comm.getpldict(plugname,
                        \                                     plugtype),
                        \                  a:hasdep))
        endif
    endfor
    return r
endfunction
"{{{3 comm.depcomp:      Сравнить количество зависимых плагинов
function s:DepComp(plugdict1, plugdict2)
    let depnum1=len(keys(a:plugdict1.requiredby))
    let depnum2=len(keys(a:plugdict2.requiredby))
    return ((depnum1>depnum2)?
                \(1):
                \((depnum1<depnum2)?
                \   (-1):
                \   (0)))
endfunction
let s:F.int["s:DepComp"]=function("s:DepComp")
let s:F.comm.depcomp=function("s:DepComp")
"{{{3 comm.unload:       Удалить плагин
function s:F.comm.unload(plugname, plugtype)
    let plugdict=s:g.reg.registered[a:plugtype][a:plugname]
    call s:F.au.doevent("UnloadPluginPre", plugdict.plid)
    let srccmd=""
    let hasdep={}
    let depends=sort(s:F.comm.getdep(plugdict, hasdep), s:F.comm.depcomp)
    let plugins=filter(copy(depends), 'empty(v:val.requiredby)')
    let plids=map(copy(plugins), 'v:val.plid')
    call filter(depends, '!empty(v:val.requiredby)')
    while depends!=[]
        let removedsmth=0
        let i=0
        while i<len(depends)
            if filter(keys(depends[i].requiredby),
                        \'index(plids, v:val)==-1')==[]
                call add(plugins, depends[i])
                call add(plids, depends[i].plid)
                call remove(depends, i)
                let removedsmth=1
            else
                let i+=1
            endif
        endwhile
        if !removedsmth && depends!=[]
            call add(plugins, depends[0])
            call add(plids, depends[0].plid)
            call remove(depends, 0)
            continue
        endif
    endwhile
    for plugdict in plugins
        if plugdict.status!=#'loaded'
            call s:F.comm.load(plugdict.name, plugdict.type)
        endif
    endfor
    let srccmd=join(map(reverse(copy(plugins)), 'v:val.srccmd'), "\n")
    for plugdict in plugins
        if has_key(plugdict, "mappings")
            call s:F.maps.delmappings(plugdict)
        endif
        call s:F.reg.unreg(plugdict.name, plugdict.type)
        if has_key(plugdict, "F") && has_key(plugdict, "g")
            if has_key(plugdict.F, "main") &&
                        \has_key(plugdict.F.main, "destruct")
                call plugdict.F.main.destruct()
            endif
            unlockvar plugdict.g
            unlockvar plugdict.F
            for key in keys(plugdict.g)
                unlet plugdict.g[key]
            endfor
            for key in keys(plugdict.F)
                unlet plugdict.F[key]
            endfor
            unlet plugdict.g
            unlet plugdict.F
        endif
    endfor
    if exists('s:F')
        call s:F.au.doevent("UnloadPluginPost", a:plugtype.'/'.a:plugname)
    endif
    return srccmd
endfunction
"{{{2 au: regevent, delevent, doau
"{{{3 s:g.au
let s:g.au={}
let s:g.au.events={}
let s:g.au.events.RegisterPluginPre={}
let s:g.au.events.LoadPluginPre={}
let s:g.au.events.UnloadPluginPre={}
let s:g.au.events.RegisterPluginPost={}
let s:g.au.events.LoadPluginPost={}
let s:g.au.events.UnloadPluginPost={}
lockvar 1 s:g.au
lockvar 1 s:g.au.events
"{{{3 au.doau
function s:F.au.doau(Command, event, plugin)
    if type(a:Command)==type("")
        execute a:Command
    else
        call call(a:Command, [a:event, a:plugin], {})
    endif
endfunction
"{{{3 au.doevent
function s:F.au.doevent(event, plugin)
    for l:Cmd in get(s:g.au.events[a:event], a:plugin, [])
        call s:F.au.doau(l:Cmd, a:event, a:plugin)
    endfor
endfunction
"{{{3 au.regevent
function s:F.au.regevent(event, plugin, Command)
    if !has_key(s:g.au.events[a:event], a:plugin)
        let s:g.au.events[a:event][a:plugin]=[]
    endif
    call add(s:g.au.events[a:event][a:plugin], a:Command)
endfunction
"{{{3 au.delevent
function s:F.au.delevent(event, plugin, Command)
    if type(a:Command)!=type(0)
        if !has_key(s:g.au.events[a:event], a:plugin)
            return
        endif
        call filter(s:g.au.events[a:event][a:plugin],
                    \'!(type(v:val)==type(a:Command) && v:val==#a:Command)')
    elseif type(a:plugin)==type("")
        call filter(s:g.au.events[a:event], 'v:key!=#a:plugin')
        if !empty(s:g.au.events[a:event])
            call remove(s:g.au.events[a:event], 0, -1)
        endif
    else
        for key in keys(s:g.au.events[a:event])
            unlet s:g.au.events[a:event][key]
        endfor
    endif
endfunction
"{{{3 s:g.comm.f
unlockvar 1 s:g.comm.f
call add(s:g.comm.f,
            \["autocmd", 'au.regevent', {"model": "simple",
            \                         "required": [["keyof", s:g.au.events],
            \                                      ["type", type("")],
            \                                      ["type", type("")]]}])
call add(s:g.comm.f,
            \["delautocmd", 'au.delevent',
            \           {"model": "optional",
            \         "required": [["keyof", s:g.au.events]],
            \         "optional": [[["type", type("")], {}, ""],
            \                      [["type", type("")], {}, ""]]}])
lockvar 2 s:g.comm.f
"{{{2 ses: mksession, loadsession
"{{{3 ses.mksession
function s:F.ses.mksession(sfile)
    let selfname='ses.mksession'
    try
        execute "mksession! ".fnameescape(a:sfile)
    catch
        return s:F.main.eerror(selfname, "ofail", 1, ["sesnf"], v:exception)
    endtry
    let xfile=fnamemodify(a:sfile, ':p:r').'x.vim'
    if filewritable(fnamemodify(a:sfile, ':p:h'))==2
        if filereadable(xfile)
            if !filewritable(xfile)
                return s:F.main.eerror(selfname, "ofail", 1, ["sesfx", xfile])
            endif
            " let sescontent=readfile(xfile, 'b')
            let sescontent=[]
        else
            let sescontent=[]
        endif
        let sescontent+=[
                    \'call load#LoadFuncdict("load").'.
                    \           'restoresession(expand("<sfile>"))',
                    \'finish',
                    \'### YAML document starts here ###',
                    \]
        let plses={}
        for plugtype in keys(s:g.reg.registered)
            for plugdict in values(s:g.reg.registered[plugtype])
                if has_key(plugdict.F, "main") && has_key(plugdict.F.main,
                            \                            "session")
                    let plses[plugdict.plid]=plugdict.F.main.session()
                endif
            endfor
        endfor
        if !(has_key(s:g.reg.registered.plugin, "yaml") &&
                    \s:g.reg.registered.plugin.yaml.status==#"loaded")
            call s:F.comm.load("yaml", "plugin")
        endif
        if !(has_key(s:g.reg.registered.plugin, "yaml") &&
                    \s:g.reg.registered.plugin.yaml.status==#"loaded")
            return s:F.main.eerror(selfname, "ofail", 1, ["yamlf"])
        endif
        call extend(sescontent, s:F.plug.yaml.dumps(plses, 0))
        call add(sescontent, "")
        call writefile(sescontent, xfile, 'b')
    else
        return s:F.main.eerror(selfname, "ofail", 1, ["sesdw",
                    \                             fnamemodify(a:sfile, ':p:h')])
    endif
endfunction
"{{{3 ses.restore
function s:F.ses.restore(sfile)
    let selfname='ses.restore'
    let sescontent=readfile(a:sfile, 'b')
    while sescontent[0]!=#'### YAML document starts here ###'
        call remove(sescontent, 0)
    endwhile
    if !(has_key(s:g.reg.registered.plugin, "yaml") &&
                \s:g.reg.registered.plugin.yaml.status==#"loaded")
        call s:F.comm.load("yaml", "plugin")
    endif
    if !(has_key(s:g.reg.registered.plugin, "yaml") &&
                \s:g.reg.registered.plugin.yaml.status==#"loaded")
        return s:F.main.eerror(selfname, "ofail", 1, ["yamlf"])
    endif
    let plses=s:F.plug.yaml.loads(join(sescontent, "\n"))
    for [plid, arg] in items(plses)
        let plugdict=call(s:F.comm.getpldict, s:F.comm.parseplid(plid), {})
        if has_key(plugdict.F, "main") && has_key(plugdict.F.main,
                    \                            "session")
            call plugdict.F.main.session(arg)
        endif
        unlet arg
    endfor
endfunction
"{{{2 mng: main
"{{{3 mng.main
"{{{4 s:g.c.cmd
let s:g.c.nothing={"model": "optional"}
let s:g.c.cmd={
            \"model": "actions",
            \"actions": {}
        \}
let s:g.c.cmd.actions.unload={
            \   "model": "simple",
            \"required": [["type", type("")]]
        \}
let s:g.c.cmd.actions.reload=s:g.c.cmd.actions.unload
let s:g.c.cmd.actions.show=s:g.c.nothing
let s:g.c.cmd.actions.findnr={"model": "simple",
            \                "required": [["type", type("")]]}
let s:g.c.cmd.actions.nrof={"model": "simple",
            \              "required": [{"check": ["regex", '^/']}]}
let s:g.c.cmd.actions.autocmd={"model": "optional",
            \               "required": [["keyof", s:g.au.events],
            \                            ["type", type("")],
            \                            ["type", type("")]],
            \                   "next": ["type", type("")]}
let s:g.c.cmd.actions["autocmd!"]={"model": "optional",
            \                   "required": [["keyof", s:g.au.events]],
            \                   "optional": [[["type", type("")], {}, 0]],
            \                       "next": ["type", type("")]}
let s:g.c.cmd.actions.mksession={"model": "simple",
            \                 "required": [["file", "w"]]}
lockvar! s:g.c
unlockvar! s:g.reg.registered
for s:key in keys(s:g.au.events)
    execute "unlockvar! s:g.au.events.".s:key
endfor
unlet s:key
"}}}4
function s:F.mng.main(action, ...)
    "{{{4 Объявление переменных
    let selfname="mng.main"
    let action=tolower(a:action)
    "{{{4 Проверка ввода
    let args=s:F.plug.chk.checkarguments(s:g.c.cmd, [action]+a:000)
    if type(args)!=type([])
        return 0
    endif
    "{{{4 Действия
    "{{{5 Выгрузить дополнение
    if action==#"unload"
        return !empty(call(s:F.comm.unload, s:F.comm.parseplid(args[1]), {}))
    "{{{5 Перезагрузить дополнение
    elseif action==#"reload"
        execute call(s:F.comm.unload, s:F.comm.parseplid(args[1]), {})
        return 1
    "{{{5 Показать список загруженных дополнений
    elseif action==#"show"
        let lines=[]
        for plugtype in keys(s:g.reg.registered)
            for [plugname, plugdict] in items(s:g.reg.registered[plugtype])
                call add(lines, [plugtype, plugname, plugdict.file,
                            \    plugdict.status])
            endfor
        endfor
        return s:F.stuf.printtable(s:g.p.th, lines)
    "{{{5 Найти функцию, соответствующую номеру
    elseif action==#"findnr"
        let results=map(split(args[1], '\D\+'),
                    \'[v:val, s:F.stuf.findnr(v:val)]')
        call map(results,
                    \'[v:val[0], '.
                    \'((type(v:val[1])==type(""))?(v:val[1]):(s:g.p.nfnd))]')
        if len(results)==1
            echo results[0][1]
        else
            echo join(map(results, 'join(v:val, ": ")'), "\n")
        endif
        return 1
    "{{{5 Найти номер, соответствующий функции
    elseif action==#"nrof"
        let Result=s:F.stuf.findpath(args[1])
        if type(Result)==2
            echo Result
            return 1
        elseif type(Result)==type({})
            let list=s:F.stuf.fdictstr(Result, 0)
            call map(list, '[repeat(" ", v:val[0]).v:val[1], '.
                        \"substitute(s:F.stuf.string(v:val[2]), ".
                        \                   "'^.*''\\([^'']*\\)''.*$', ".
                        \                   "'\\1', '')]")
            return s:F.stuf.printtable([], list)
        else
            echo s:g.p.nfnd
        endif
    "{{{5 autocmd
    elseif action==#"autocmd"
        call s:F.au.regevent(args[1], args[2], join(args[3:]))
    "{{{5 autocmd!
    elseif action==#"autocmd!"
        call s:F.au.delevent(args[1], args[2],
                    \((len(args)>2)?
                    \   (join(args[3:])):
                    \   (0)))
    "{{{5 mksession
    elseif action==#"mksession"
        call s:F.ses.mksession(args[1])
    endif
    "}}}4
endfunction
"{{{2 comp: автодополнение
"{{{3 comp.nrof
function s:F.comp.nrof(arglead)
    let s=split(a:arglead, '/')
    if len(s)<=1 && a:arglead[-1:]!=#'/'
        return map(keys(s:g.reg.registered), '"/".v:val."/"')
    elseif len(s)==2 && a:arglead[-1:]!=#'/' &&
                \has_key(s:g.reg.registered, s[0])
        return map(keys(s:g.reg.registered[s[0]]), '"/'.s[0].'/".v:val."/"')
    else
        let path='/'.join(s, '/')
        let P=s:F.stuf.findpath(path)
        if type(P)==type({})
            return map(keys(P), 'path."/".v:val')
        elseif type(P)!=2
            unlet P
            let path='/'.join(s[:(-2)], '/')
            let P=s:F.stuf.findpath('/'.join(s[:(-2)], '/'))
            if type(P)==type({})
                return map(keys(P), 'path."/".v:val')
            endif
        endif
    endif
    return []
endfunction
"{{{3 comp.plug
function s:F.comp.plug(arglead)
    let plugtype=matchstr(a:arglead, '/\=[^/]*')
    if !has_key(s:g.reg.registered, plugtype)
        let plugtype='plugin'
    endif
    return map(keys(s:g.reg.registered[plugtype]), '"'.plugtype.'/".v:val')
endfunction
"{{{3 comp._complete
function s:F.comp._complete(...)
    if !has_key(s:F.comp, "__complete")
        let s:F.comp.__complete=
                    \s:F.comm.run(s:F.plug.comp, "ccomp",
                    \             s:g.comp._cname, s:g.comp.a)
    endif
    return call(s:F.comp.__complete, a:000, {})
endfunction
"{{{3 s:g.comp
let s:g.comp={}
let s:g.comp.plug=["func", s:F.comp.plug]
let s:g.comp.event=["keyof", s:g.au.events]
let s:g.comp.a={"model": "actions"}
let s:g.comp.a.actions={}
let s:g.comp.a.actions.unload={"model": "simple",
            \              "arguments": [s:g.comp.plug]}
let s:g.comp.a.actions.reload={"model": "simple",
            \              "arguments": [s:g.comp.plug]}
let s:g.comp.a.actions.show={"model": "simple"}
let s:g.comp.a.actions.findnr={"model": "simple"}
let s:g.comp.a.actions.nrof={"model": "simple",
            \              "arguments": [["func", s:F.comp.nrof]]}
let s:g.comp.a.actions.autocmd={"model": "simple",
            \               "arguments": [s:g.comp.event, s:g.comp.plug]}
let s:g.comp.a.actions["autocmd!"]={"model": "simple",
            \                   "arguments": [s:g.comp.event, s:g.comp.plug]}
let s:g.comp.a.actions.mksession={"model": "simple",
            \                 "arguments": [["file", '.vim']]}
let s:g.comp._cname="load"
"{{{1
let s:g.reginfo=s:F.reg.register({
            \     "funcdict": s:F,
            \     "globdict": s:g,
            \      "fprefix": "Load",
            \      "cprefix": "Load",
            \      "oprefix": "load",
            \     "commands": s:g.load.commands,
            \    "functions": s:g.load.functions,
            \          "sid": s:g.scriptid,
            \   "scriptfile": s:g.load.scriptfile,
            \      "oneload": 1,
            \"dictfunctions": s:g.comm.f,
            \   "apiversion": "0.7",
        \})
lockvar! s:g.reginfo
let s:F.main.eerror=s:g.reginfo.functions.eerror
let s:F.main.option=s:g.reginfo.functions.option
unlet s:g.load
" let s:F.plug.comp=s:F.comm.getfunctions("comp")
let s:F.plug.comp=s:F.comm.lazyload("comp", "plugin", "dictfunctions")
let s:F.plug.stuf=s:F.comm.lazyload("stuf", "plugin", "dictfunctions")
let s:F.plug.yaml=s:F.comm.lazyload("yaml", "plugin", "dictfunctions")
lockvar! s:F
unlockvar s:F.plug
unlockvar s:F.comp
lockvar s:g
" vim: ft=vim:ts=8:fdm=marker:fenc=utf-8

