"{{{1 Начало
scriptencoding utf-8
if (exists("s:g.pluginloaded") && s:g.pluginloaded) ||
            \exists("g:stufOptions.DoNotLoad")
    finish
"{{{1 Первая загрузка
elseif !exists("s:g.pluginloaded")
    "{{{2 Объявление переменных
    "{{{3 Словари с функциями
    " Функции для внутреннего использования
    let s:F={
                \"stuf": {},
                \"plug": {},
                \ "cmd": {},
                \"file": {},
                \ "str": {},
                \ "lst": {},
                \ "num": {},
                \ "dct": {},
                \"main": {},
            \}
    lockvar 1 s:F
    "{{{3 Глобальная переменная
    let s:g={}
    let s:g.load={}
    let s:g.pluginloaded=0
    let s:g.load.scriptfile=expand("<sfile>")
    let s:g.srccmd="source ".(s:g.load.scriptfile)
    let s:g.reg={}
    let s:g.reg.oprefix='^[[:alnum:]_]\+$'
    let s:g.reg.intname='^\([[:alnum:]_]\+.\)*[[:alnum:]_]\+$'
    "{{{4 s:g.cmd
    let s:g.cmd={}
    let s:g.cmd.inputs={}
    let s:g.cmd.oldhist={}
    "{{{4 Функции
    let s:g.c={}
    let s:g.c.inameregex='^[a-z][a-z_]*$'
    let s:g.c.sid=["nums", [1]]
    " XXX cinput - 18
    let s:g.c.functions=[
                \["let", "lst.let", {}],
                \["or", "num.or",
                \       {   "model": "simple",
                \        "required": [["num", [0]],
                \                     ["num", [0]]]}],
                \["and", "num.and",
                \       {   "model": "simple",
                \        "required": [["num", [0]],
                \                     ["num", [0]]]}],
                \["recursivefilter", "dct.recursivefilter",
                \       {   "model": "simple",
                \        "required": [["type", type({})]]}],
                \["base64decode",   "str.base64decode",
                \       {   "model": "optional",
                \        "required": [["type", type("")]],
                \        "optional": [[["bool", ""], {}, 0]]}],
                \["base64encode",   "str.base64encode",
                \       {   "model": "simple",
                \        "required": [["or", [["type", type("")],
                \                             ["alllst", ["type",type(0)]]]]]}],
                \["regescape",   "str.escapefor.regex",
                \       {   "model": "simple",
                \        "required": [["type", type("")]]}],
                \["globescape",   "str.escapefor.glob",
                \       {   "model": "simple",
                \        "required": [["type", type("")]]}],
                \["mapprepare",  "str.escapefor.map",
                \       {   "model": "simple",
                \        "required": [["type", type("")]]}],
                \["squote",      "str.escapefor.quote",
                \       {   "model": "simple",
                \        "required": [["type", type("")]]}],
                \["iscombining", "str.iscombining",
                \       {   "model": "simple",
                \        "required": [["type", type("")]]}],
                \["strlen",      "str.strlen",
                \       {   "model": "simple",
                \        "required": [["type", type("")]]}],
                \["nextchar",    "str.nextchar",
                \       {   "model": "simple",
                \        "required": [["type", type("")]]}],
                \["nextchar_nr", "str.nextchar_nr",
                \       {   "model": "simple",
                \        "required": [["type", type("")]]}],
                \["printl",      "str.printl",
                \       {   "model": "simple",
                \        "required": [["type", type(0)],
                \                     ["type", type("")]]}],
                \["printtable",  "str.printtable",
                \       {   "model": "simple",
                \        "required": [["alllst", ["type", type("")]],
                \                     ["alllst", ["alllst", ["type", type("")]]]
                \                    ]}],
                \["string",      "str.string", {}],
                \["readfile",    "file.readfile",
                \       {   "model": "simple",
                \        "required": [["file", "r"]]}],
                \["cinput", "cmd.geninput",
                \       {   "model": "optional",
                \        "required": [["and", [["regex", s:g.c.inameregex],
                \                              ["not",
                \                               ["keyof", s:g.cmd.inputs]]]]],
                \        "optional": [[["type", type("")], {}, ""],
                \                     [["or", [["isfunc", 0],
                \                              ["in", ['augroup', 'buffer',
                \                                      'command', 'dir',
                \                                      'environment', 'event',
                \                                      'expression', 'file',
                \                                      'filetype', 'function',
                \                                      'help', 'highlight',
                \                                      'mapping', 'menu',
                \                                      'option', 'shellcmd',
                \                                      'syntax', 'tag', '',
                \                                      'tag_listfiles', 'var']],
                \                              ["regex",
                \                               '^custom,\([sS]:\)\@!']]],
                \                      {}, ""]]}],
            \]
    "{{{4 sid
    function s:SID()
        return matchstr(expand('<sfile>'), '\d\+\ze_SID$')
    endfun
    let s:g.scriptid=s:SID()
    delfunction s:SID
    "{{{2 Регистрация плагина
    let s:F.plug.load=load#LoadFuncdict()
    let s:g.reginfo=s:F.plug.load.registerplugin({
                \     "funcdict": s:F,
                \     "globdict": s:g,
                \      "oprefix": "stuf",
                \          "sid": s:g.scriptid,
                \   "scriptfile": s:g.load.scriptfile,
                \"dictfunctions": s:g.c.functions,
                \   "apiversion": "0.5",
                \     "requires": [["load", '0.0']],
            \})
    let s:F.main.eerror=s:g.reginfo.functions.eerror
    "}}}2
    finish
endif
"{{{1 Вторая загрузка
let s:g.pluginloaded=1
"{{{2 Чистка
unlet s:g.load
"{{{2 Выводимые сообщения
let s:g.p={
            \"emsg": {
            \   "iexists": "Input with such name already exists",
            \}
        \}
call add(s:g.c.functions[18][2].required[0][1][1], s:g.p.emsg.iexists)
"{{{1 Вторая загрузка — функции
"{{{2 stuf
"{{{3 stuf.writevar: записать в переменную
", возможно, являющуюся частью несуществующего словаря, или имеющую другой тип 
"по сравнению с тем, что мы собираемся туда записать
function s:F.stuf.writevar(varname, what)
    let selfname="stuf.writevar"
    if a:varname=~#'\.'
        if !exists(a:varname)
            let dct=matchstr(a:varname, '^.*\.\@=')
            if !exists(dct) || type(eval(dct))!=type({})
                let lastret=s:F.stuf.writevar(dct, {})
                if !lastret
                    return 0
                endif
            endif
        endif
    elseif exists(a:varname) && !islocked(a:varname)
        execute "unlet ".a:varname
    endif
    if exists(a:varname) && islocked(a:varname)
        return s:F.main.eerror(selfname, "perm", ["vlock"], a:varname)
    endif
    execute "let ".a:varname."=a:what"
    return 1
endfunction
"{{{2 str
let s:g.str={}
"{{{3 str.escapefor
let s:F.str.escapefor={}
let s:g.str.escapefor={
            \"regex": 'escape(a:str, ''^$*~[].\'')',
            \"map": 'escape('.
            \        'substitute('.
            \         'substitute('.
            \          'substitute('.
            \           'substitute(a:str, "<", "<LT>", "g"), '.
            \          '" ", "<SPACE>", "g"), '.
            \         '''\t'', "<Tab>", "g"), '.
            \        '''\n'', "<CR>", "g"), "|")',
            \"quote": "\"'\".substitute(".
            \                "substitute(a:str, \"'\", '&&', 'g'), ".
            \               '''\n'', ''''''."\\n".'''''', "g")."''"',
            \"glob": 'escape(a:str, ''[]*?`\'')',
        \}
for s:key in keys(s:g.str.escapefor)
    execute      "function s:F.str.escapefor.".s:key."(str)\n".
                \"    return ".s:g.str.escapefor[s:key]."\n".
                \"endfunction"
endfor
unlet s:key
"{{{3 str.string: failsafe string() replacement
function s:F.str.string(obj)
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
"{{{3 str.strlen: получение длины строки
function s:F.str.strlen(str)
    return len(split(a:str, '\zs'))
endfunction
"{{{3 str.iscombining: проверить, является ли символ диакритикой
" Если да, то вернуть его длину в байтах
" Unicode: combining diacritical marks: определение
" Wikipedia: http://en.wikipedia.org/wiki/Combining_character:
"   Combining Diacritical Marks (0300–036F)
"   Combining Diacritical Marks Supplement (1DC0–1DFF)
"   Combining Diacritical Marks for Symbols (20D0–20FF)
"   Combining Half Marks (FE20–FE2F)
function s:F.str.iscombining(char)
    let chnr=char2nr(a:char)
    if           (0x0300<=chnr && chnr<=0x036F) ||
                \(0x1DC0<=chnr && chnr<=0x1DFF) ||
                \(0x20D0<=chnr && chnr<=0x20FF) ||
                \(0xFE20<=chnr && chnr<=0xFE2F)
        return len(nr2char(chnr))
    endif
    return 0
endfunction
"{{{3 str.nextchar: получить следующий символ (reg('.'))
" Получить следующий символ. Если дан второй аргумент, то получить следующий за 
" позицией, данной во втором аргументе, символ.
function s:F.str.nextchar(str, ...)
    return matchstr(a:str, '.', ((len(a:000))?(a:000[0]):(0)))
endfunction
"{{{3 str.nextchar_nr получить следующий символ (nr2char(char2nr))
" То же, что и предыдущая функция, но получение следующего символа выполняется 
" с помощью nr2char(char2nr)
function s:F.str.nextchar_nr(str, ...)
    return nr2char(char2nr(a:str[((len(a:000))?(a:000[0]):(0)):]))
endfunction
"{{{3 str.printl: printf{'%-*s', ...}
" Напечатать {str}, шириной {len}, выровненное по левому краю, оставшееся 
" пространство заполнив пробелами (вместо printf('%-*s', len, str)).
function s:F.str.printl(len, str)
    return a:str . repeat(" ", a:len-s:F.str.strlen(a:str))
endfunction
"{{{3 str.printtline: печать строки таблицы
" Напечатать одну линию таблицы
"   {line} — список строк таблицы,
" {lenlst} — список длин
function s:F.str.printtline(line, lenlst)
    let result=""
    let i=0
    while i<len(a:line)
        let result.=s:F.str.printl(a:lenlst[i], a:line[i])
        let i+=1
        if i<len(a:line)
            let result.="  "
        endif
    endwhile
    return result
endfunction
"{{{3 str.printtable: напечатать таблицу
" Напечатать таблицу с заголовками рядов {headers} и линиями {lines}.
" {headers}: список строк
"   {lines}: список списков строк
function s:F.str.printtable(header, lines)
    let lineswh=a:lines+[a:header]
    let columns=max(map(copy(lineswh), 'len(v:val)'))
    let lenlst=[]
    let i=0
    while i<columns
        call add(lenlst, max(map(copy(lineswh),
                    \'(i<len(v:val))?s:F.str.strlen(v:val[i]):0')))
        let i+=1
    endwhile
    if !empty(a:header)
        echohl PreProc
        echo s:F.str.printtline(a:header, lenlst)
        echohl None
    endif
    echo join(map(copy(a:lines), 's:F.str.printtline(v:val, lenlst)'), "\n")
    return 1
endfunction
"{{{3 str.base64decode
let s:g.str.cd64=map(split("|$$$}rstuvwxyz{$$$$$$$>?@ABCDEFGHIJKLMNOPQRSTUVW$$$$$$XYZ[\\]^_`abcdefghijklmnopq",
            \              '\zs'),
            \        'char2nr(v:val)')
function s:F.str.base64decode(str, bytearray)
    let str=map(split(substitute(a:str, '[^a-zA-Z0-9+/]', '', 'g'), '\zs'),
                \'char2nr(v:val)')+[-1]
    let in=repeat([0], 4)
    let v=0
    let len=0
    let i=0
    if a:bytearray
        let r=[]
    else
        let r=""
    endif
    while !empty(str)
        let i=0
        let len=0
        while i<4 && !empty(str)
            let v=0
            while !empty(str) && v==0
                let v=remove(str, 0)
                let v=(((v<43)||(v>122))?(0):(s:g.str.cd64[v-43]))
                if v
                    let v=((v==36)?(0):(v-61))
                endif
            endwhile
            if !empty(str)
                let len+=1
                if v
                    let in[i]=v-1
                endif
            else
                let in[i]=0
            endif
            let i+=1
        endwhile
        if len
            let out=[    s:F.num.or(            in[0]*4,         in[1]/16),
                        \s:F.num.or(            in[1]*16,        in[2]/4),
                        \s:F.num.or(s:F.num.and(in[2]*64, 0xC0), in[3])]
            call map(out, 's:F.num.and(v:val, 0xFF)')
            if a:bytearray
                let r+=out[:(len-2)]
            else
                let r.=join(map(out[:(len-2)],
                            \   'eval(printf(''"\x%02x"'', v:val))'),
                            \"")
            endif
        endif
    endwhile
    return r
endfunction
"{{{3 str.base64encode
let s:g.str.eqsigncode=char2nr('=')
let s:g.str.cb64=map(split("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/",
            \              '\zs'), 'char2nr(v:val)')
function s:F.str.base64encode(str)
    let r=""
    let bytearray=(type(a:str)==type([]))
    let in=repeat([0], 3)
    let idx=0
    let slen=len(a:str)
    let cb64=s:g.str.cb64
    while idx<slen
        let len=0
        let i=0
        while i<3
            if idx<slen
                let cur=a:str[idx]
                if !bytearray
                    let cur=char2nr(cur)
                endif
                let in[i]=cur
                let len+=1
                let idx+=1
            else
                let in[i]=0
            endif
            let i+=1
        endwhile
        if len
            let out=[    cb64[in[0]/4],
                        \cb64[s:F.num.or(((s:F.num.and(in[0], 0x03))*16),
                        \                ((s:F.num.and(in[1], 0xF0))/16))],
                        \((len>1)?
                        \   (cb64[s:F.num.or(s:F.num.and(in[1], 0x0F)*4,
                        \                    s:F.num.and(in[2], 0xC0)/64)]):
                        \   (s:g.str.eqsigncode)),
                        \((len>2)?
                        \   (cb64[s:F.num.and(in[2], 0x3F)]):
                        \   (s:g.str.eqsigncode))]
            let r.=join(map(copy(out), 'eval(printf(''"\x%02x"'', v:val))'), "")
        endif
    endwhile
    return r
endfunction
"{{{2 num
"{{{3 num.and
function s:F.num.and(v1, v2)
    let [v1, v2]=[a:v1, a:v2]
    let list=[]
    while v1 || v2
        let [nv1, nv2]=[v1/2, v2/2]
        call add(list, ((nv1*2!=v1)&&(nv2*2!=v2)))
        let [v1, v2]=[nv1, nv2]
    endwhile
    let r=0
    while !empty(list)
        let r=(r*2) + remove(list, -1)
    endwhile
    return r
endfunction
"{{{3 num.or
function s:F.num.or(v1, v2)
    let [v1, v2]=[a:v1, a:v2]
    let list=[]
    while v1 || v2
        let [nv1, nv2]=[v1/2, v2/2]
        call add(list, ((nv1*2!=v1)||(nv2*2!=v2)))
        let [v1, v2]=[nv1, nv2]
    endwhile
    let r=0
    while !empty(list)
        let r=(r*2) + remove(list, -1)
    endwhile
    return r
endfunction
"{{{2 file
"{{{3 file.readfile: прочитать файл
" vim-7.0 не имеет функции shellescape
if executable("cat") && exists('*shellescape')
    function s:F.file.readfile(fname)
        " Как ни странно, такой вариант работает быстрее, чем все придуманные 
        " мною альтернативы на чистом Vim
        let result=""
        let result=system("cat ".shellescape(a:fname))
        if v:shell_error
            let result=join(readfile(a:fname, 'b'), "\n")
        endif
        return result
        " Если в аргументах readfile не указывать 'b', то файл, не содержащий 
        " переводов строки, прочитается как будто он пустой.
        " return join(readfile(fname, 'b'), "\n")
        " Есть ещё варианты через открытие буфера, но они всё равно медленнее 
        " данного. Тем не менее, даже они могут быть быстрее join(readfile).
    endfunction
else
    function s:F.file.readfile(fname)
        return join(readfile(a:fname, 'b'), "\n")
    endfunction
endif
"{{{2 lst
"{{{3 lst.let
function s:F.lst.let(list, index, element, ...)
    if type(a:list)==type([]) && type(a:index)==type(0)
        let ll=len(a:list)
        if a:index<ll
            let a:list[a:index]=a:element
        elseif a:index==ll
            call add(a:list, a:element)
        elseif !empty(a:000)
            call extend(a:list, repeat([a:000[0]], a:index-ll)+[a:element])
        endif
    elseif type(a:list)==type({}) && type(a:index)==type("")
        let a:list[a:index]=a:element
    endif
    return a:list
endfunction
"{{{2 dct
"{{{3 dct.recursivefilter
function s:F.dct.recursivefilter(dict, expr)
    let r={}
    for [l:Key, l:Val] in items(a:dict)
        if type(l:Val)==type({})
            let r[l:Key]=s:F.dct.recursivefilter(l:Val, a:expr)
        elseif eval(a:expr)
            let r[l:Key]=l:Val
        endif
        unlet l:Val
    endfor
    return r
endfunction
"{{{2 cmd
"{{{3 cmd.savehist
" Patch 30 for vim 7.3 adds support for storing lists and dictionaries in 
" viminfo file, so we do not need to join string anymore
if (v:version==703 && has("patch30")) || v:version>703
    function s:F.cmd.savehist(...)
        if &viminfo=~'!' || !empty(a:000)
            for [key, value] in items(s:g.cmd.inputs)
                let g:STUF_HISTORY_{toupper(key)}=value.history
            endfor
        endif
    endfunction
else
    function s:F.cmd.savehist(...)
        if &viminfo=~'!' || !empty(a:000)
            for [key, value] in items(s:g.cmd.inputs)
                let g:STUF_HISTORY_{toupper(key)}=join(value.history, "\n")
            endfor
        endif
    endfunction
endif
augroup StufStoreHistory
    autocmd!
    autocmd VimLeavePre * call s:F.cmd.savehist()
augroup END
"{{{3 cmd.histget
function s:F.cmd.histget(history)
    let r=[]
    while 1
        let histentry=histget(a:history, -1)
        if histdel(a:history, -1)
            call insert(r, histentry)
        else
            return r
        endif
    endwhile
endfunction
"{{{3 cmd.histextend
function s:F.cmd.histextend(history, histlst)
    while !empty(a:histlst)
        call histadd(a:history, remove(a:histlst, 0))
    endwhile
    return a:histlst
endfunction
"{{{3 cmd.input
function s:F.cmd.input(inputdict, ...)
    let prompt=get(a:000, 0, a:inputdict.prompt)
    if type(prompt)!=type("")
        let prompt=a:inputdict.prompt
    endif
    let text=get(a:000, 1, "")
    let completion=get(a:000, 2, a:inputdict.completion)
    let histlock=islocked('a:inputdict.history')
    if !histlock
        call extend(a:inputdict.inputhistory, s:F.cmd.histget("input"))
        call s:F.cmd.histextend("input", a:inputdict.history)
        lockvar a:inputdict.history
    endif
    call inputsave()
    try
        let r=call("input", [prompt, text]+
                    \((empty(completion))?([]):([completion])))
        return r
    catch /^Vim:Interrupt/
        throw "Interrupted"
    catch
        throw "Input failed: ".v:exception
    finally
        call inputrestore()
        if !histlock
            unlockvar a:inputdict.history
            call extend(a:inputdict.history, s:F.cmd.histget("input"))
            call s:F.cmd.histextend("input", a:inputdict.inputhistory)
        endif
    endtry
endfunction
"{{{3 cmd.geninput
function s:F.cmd.geninput(name, prompt, Completion)
    let entry={
                \"name": a:name,
                \"prompt": a:prompt,
                \"history": [],
                \"inputhistory": [],
            \}
    let upname=toupper(a:name)
    if has_key(s:g.cmd.oldhist, a:name)
        call extend(entry.history, s:g.cmd.oldhist[a:name])
        unlet s:g.cmd.oldhist[a:name]
    elseif exists('g:STUF_HISTORY_'.upname)
        let tsh=type(g:STUF_HISTORY_{upname})
        if tsh==type("")
            call extend(entry.history, split(g:STUF_HISTORY_{upname}, "\n"))
        elseif tsh==type([])
            let entry.history=filter(g:STUF_HISTORY_{upname},
                        \            'type(v:val)=='.type(""))
        endif
        unlet g:STUF_HISTORY_{upname}
    endif
    let s:g.cmd.inputs[a:name]=entry
    if type(a:Completion)==2
        let entry.compfunc='g:__complete_input_'.a:name
        execute      "function ".(entry.compfunc)."(...)\n".
                    \"    return call(s:g.cmd.inputs.".a:name.".compF, ".
                    \                "a:000, {})\n".
                    \"endfunction"
        let entry.completion="customlist,".(entry.compfunc)
        let entry.compF=a:Completion
    else
        let entry.completion=a:Completion
    endif
    let r={}
    execute      "function r.f(...)\n".
                \"    return call(s:F.cmd.input, ".
                \           "[s:g.cmd.inputs.".a:name."]+a:000, {})\n".
                \"endfunction"
    execute      "function r.d()\n".
                \"    return s:F.cmd.delinput(".string(a:name).")\n".
                \"endfunction"
    return [r.f, r.d]
endfunction
"{{{3 cmd.delinput
function s:F.cmd.delinput(name)
    if has_key(s:g.cmd.inputs[a:name], 'compfunc')
        execute "delfunction ".s:g.cmd.inputs[a:name].compfunc
    endif
    unlet s:g.cmd.inputs[a:name]
    return 1
endfunction
"{{{2 main: destruct, session
"{{{3 main.destruct: выгрузить плагин
function s:F.main.destruct()
    augroup StufStoreHistory
        autocmd!
    augroup END
    call s:F.cmd.savehist(1)
    unlet s:g
    unlet s:F
    return 1
endfunction
"{{{3 main.session: Сохранить сессию
function s:F.main.session(...)
    if empty(a:000)
        let r={'inputhistory': {}}
        for [key, value] in items(s:g.cmd.inputs)
            let r.inputhistory[key]=value.history
        endfor
        return r
    else
        let s=a:000[0]
        if type(s)==type({}) && has_key(s, 'inputhistory')
            for [key, l:Value] in items(s.inputhistory)
                if type(l:Value)!=type([]) || key!~#s:g.c.inameregex
                    unlet l:Value
                    continue
                endif
                call filter(l:Value, 'type(v:val)=='.type(""))
                if has_key(s:g.cmd.inputs, key)
                    let s:g.cmd.inputs[key]=copy(l:Value)
                else
                    let s:g.cmd.oldhist[key]=copy(l:Value)
                endif
                unlet l:Value
            endfor
        endif
    endif
endfunction
"{{{1
lockvar! s:g
unlockvar! s:g.cmd.inputs
unlockvar! s:g.cmd.oldhist
lockvar! s:F
" vim: ft=vim:ts=8:fdm=marker:fenc=utf-8

