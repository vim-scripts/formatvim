"▶1 Header
scriptencoding utf-8
execute frawor#Setup('0.0', {'@/autocommands': '0.0',
            \                         '@/fwc': '0.0',}, 1)
"▶1 Define messages
if v:lang=~?'ru'
    let s:_messages={
                \   'cidnstr': 'Ошибка создания команды для дополнения %s: '.
                \              'имя команды не является строкой',
                \    'invcid': 'Ошибка создания команды для дополнения %s: '.
                \              'строка «%s» не может являться именем команды',
                \  'dcidnstr': 'Ошибка удаления команды для дополнения %s: '.
                \              'имя команды не является строкой',
                \   'nowncid': 'Ошибка удаления команды для дополнения %s: '.
                \              'команда «%s» не была определена этим '.
                \              'дополнением',
            \}
    call extend(s:_messages, map({
                \    'ciddef': 'команда уже определена дополнением %s',
                \   'cidedef': 'команда уже определена',
                \ 'coptsndct': 'второй аргумент не является словарём',
                \  'invrange': '«%s» не является правильным диапозоном',
                \  'hascount': 'нельзя использовать «range» и «count» вместе',
                \  'invcount': '«%s» не является числом',
                \    'invkey': 'ключ %s не принимает никаких аргументов',
                \  'invnargs': '%s не является правильным описанием числа '.
                \              'параметров',
                \   'invclen': 'неправильное количество аргументов',
                \     '1nstr': 'аргумент не является строкой на языке FWC',
                \     'ucomp': 'непонятное описание функции автодополнения',
                \   'invsreg': '«%s» не является правильным регулярным '.
                \              'выражением: %s',
                \     'invsp': 'неверное значение ключа «%ssplitfunc»',
                \'nowrapfunc': 'отсутствует функция _f.wrapfunc '.
                \              '(дополнение должно зависеть от '.
                \               'plugin/frawor/functions)',
                \     'urepl': 'непонятное описание команды',
            \}, '"Ошибка создания команды %s для дополнения %s: ".v:val'))
else
    let s:_messages={
                \   'cidnstr': 'Error while creating command for plugin %s: '.
                \              'command name is not a String',
                \    'invcid': 'Error while creating command for plugin %s: '.
                \              '`%s'' is not a valid command name',
                \  'dcidnstr': 'Error while deleting command for plugin %s: '.
                \              'command name is not a String',
                \   'nowncid': 'Error while deleting command for plugin %s: '.
                \              '`%s'' was not defined by this plugin',
            \}
    call extend(s:_messages, map({
                \    'ciddef': 'command was already defined by plugin %s',
                \   'cidedef': 'command was already defined',
                \ 'coptsndct': 'second argument is not a Dictionary',
                \  'invrange': '`%s'' is not a valid range',
                \  'hascount': 'cannot use both `range'' and `count'' '.
                \              'for one command',
                \  'invcount': '`%s'' is not a valid count',
                \    'invkey': 'key %s does not accept any arguments',
                \  'invnargs': '%s is not a valid parameter number description',
                \   'invclen': 'invalid number of arguments',
                \     '1nstr': 'expected FWC string here',
                \     'ucomp': 'invalid completion description',
                \   'invsreg': '`%s'' is not a valid regular expression: %s',
                \     'invsp': 'invalid value of `%ssplitfunc'' key',
                \'nowrapfunc': 'function _f.wrapfunc is absent (plugin '.
                \              'must depend on plugin/frawor/functions)',
                \     'urepl': 'invalid command description',
            \}, '"Error while creating command %s for plugin %s: ".v:val'))
endif
"▶1 rewritefname    :: sid, Funcref → funcname
function s:F.rewritefname(sid, Fref)
    if type(a:Fref)==2
        let fstr=string(a:Fref)[10:-3]
    else
        let fstr=a:Fref
    endif
    if fstr[:1] is# 's:'
        let fstr='<SNR>'.a:sid.'_'.fstr[2:]
    elseif fstr[:4] ==? '<SID>'
        let fstr='<SNR>'.a:sid.'_'.fstr[5:]
    endif
    return fstr
endfunction
"▶1 wrapfunc     :: cmd, fname, fdescr → + :function
function s:F.wrapfunc(cmd, fname, fdescr)
    if type(a:fdescr)==type({})
        let a:cmd.fs[a:fname[2:]]=call(a:cmd.wrapfunc, [a:fdescr], {})
        let args='a:000'
    else
        let lcomp=len(a:fdescr)
        if lcomp==1
            if type(a:fdescr[0])!=type('')
                call s:_f.throw('1nstr', a:cmd.id, a:cmd.plid)
            endif
            let compargs=['-onlystrings '.a:fdescr[0], 'complete']
        elseif lcomp==2
            let compargs=a:fdescr
        else
            call s:_f.throw('invclen', a:cmd.id, a:cmd.plid)
        endif
        let compargs+=[a:cmd.g]
        unlet a:cmd.g
        let [a:cmd.fs[a:fname[2:]], a:cmd.FWCid]=
                    \call(s:_f.fwc.compile, compargs, {})
        let args     = '[call(s:F.splitfunc, '.
                    \        'a:000'.
                    \        ((a:cmd.sp is 0)?
                    \           (', '):
                    \           ('+[s:commands.'.a:cmd.id.'.sp], ')).
                    \        '{}).curargs]'
    endif
    execute      'function '.a:fname."(...)\n"
                \'    return call(s:commands.'.a:cmd.id.'.fs.'.a:fname[2:].', '.
                \                 args.", {})\n".
                \'endfunction'
endfunction
"▶1 add_commands :: {f} → + p:_commands
function s:F.add_commands(plugdict, fdict)
    if !has_key(a:plugdict.g, '_commands') ||
                \type(a:plugdict.g._commands)!=type([])
        let a:plugdict.g._commands=[]
    endif
endfunction
"▶1 delcommands  :: {f} + p:_commands → + :delcommand, p:_commands
function s:F.delcommands(plugdict, fdict)
    if !has_key(a:plugdict.g, '_commands') ||
                \type(a:plugdict.g._commands)!=type([])
        return
    endif
    for cmd in filter(copy(a:plugdict.g._commands),
                \     'type(v:val)=='.type('').' && v:val=~#"\\v^\\u\\w+$" && '.
                \     'exists(":".v:val)')
        execute 'delcommand' cmd
    endfor
endfunction
call s:_f.newfeature('delcommands', {'unloadpre': s:F.delcommands,
            \                         'register': s:F.add_commands,
            \                       'ignoredeps': 1})
"▶1 splitfunc    :: arglead, cmdline, curpos[, cmdsplit] → cmddict
" cmdsplit :: Fref | Regex
"  cmddict :: {range: String, command: String, bang: Bool,
"              curargs: [String], args: [String],
"              arglead: String, position: UInt, cmdline: String}
let s:argsplitregex='\(\\\@<!\(\\.\)*\\\)\@<! '
let s:rangeregex='\m^\(%\|'.
            \         '\('.
            \           '\(\d\+\|'.
            \             '[.$]\|'.
            \             '''.\|'.
            \             '\\[/?&]\|'.
            \             '/\([^\\/]\|\\.\)\+/\=\|'.
            \             '?\([^\\?]\|\\.\)\+?\='.
            \           '\)'.
            \           '\([+-]\d\+\)\='.
            \           '[;,]\='.
            \         '\)*'.
            \       '\)\=\s*'
function s:F.splitfunc(arglead, cmdline, curpos, ...)
    let r={}
    let r.arglead=a:arglead
    let r.position=a:curpos
    let r.cmdline=a:cmdline
    let r.range=matchstr(a:cmdline, s:rangeregex)
    let r.command=matchstr(a:cmdline[len(r.range):], '\v^(\u[[:alnum:]_]*)!?')
    let d={}
    let d.split=get(a:000, 0, s:argsplitregex)
    if type(d.split)==type('')
        let r.args=split(a:cmdline[(len(r.range)+len(r.command)):], d.split)
        let r.curargs=split(a:cmdline[(len(r.range)+len(r.command)):(a:curpos)],
                    \       d.split)
        if empty(a:arglead)
            call add(r.curargs, '')
        endif
    else
        let r.args=d.split(a:cmdline[(len(r.range)+len(r.command)):])
        let r.curargs=d.split(a:cmdline[len(r.range)+len(r.command):(a:curpos)])
    endif
    let r.bang=(r.command[-1:] is# '!')
    return r
endfunction
"▶1 cmdsplit     :: cmdline[, cmdsplit] → [String]
function s:F.cmdsplit(cmdline, ...)
    let d={}
    let d.split=get(a:000, 0, s:argsplitregex)
    if type(d.split)==type('')
        return split(a:cmdline, d.split)
    else
        return d.split(a:cmdline)
    endif
endfunction
"▶1 command feature
let s:F.command={}
let s:commands={}
let s:bufcommands={}
let s:fts={}
"▶2 addfunc      :: cmd, fdescr → + cmd | :function
function s:F.addfunc(cmd, plstatus, fdescr)
    if a:plstatus!=2
        let fpattern='*'.(s:_sid).'_'.(a:cmd.compfname[2:])
        let augname=s:compaugprefix.(a:cmd.id)
        call s:_f.augroup.add(augname, [['FuncUndefined', fpattern, 0,
                    \                   [s:F.loadplugin, a:cmd]]])
        call add(a:cmd.augs, augname)
        call add(a:cmd.funs, [a:cmd.compfname, a:fdescr])
    else
        call s:F.wrapfunc(a:cmd, a:cmd.compfname, a:fdescr)
    endif
endfunction
"▶2 loadplugin   :: cmd → + FraworLoad(), :au!
function s:F.loadplugin(cmd)
    call FraworLoad(a:cmd.plid)
    if !empty(a:cmd.augs)
        call map(remove(a:cmd.augs, 0, -1), 's:_f.augroup.del(v:val)')
    endif
    if !empty(a:cmd.funs)
        call map(remove(a:cmd.funs, 0, -1),
                    \'s:F.wrapfunc(a:cmd, v:val[0], v:val[1])')
        if empty(a:cmd.fs)
            unlet a:cmd.fs
        endif
    endif
endfunction
"▶2 runcmd       :: cmd → + ?
function s:F.runcmd(cmd, args)
    if type(a:cmd.f)==type({})
        call s:F.loadplugin(a:cmd)
        let a:cmd.f=call(a:cmd.wrapfunc, [a:cmd.f], {})
        execute 'delcommand' a:cmd.id
        execute 'command' a:cmd.newcmdstring
        let a:cmd.cmdstring=a:cmd.newcmdstring
        unlet a:cmd.newcmdstring
    endif
    return call(a:cmd.f, a:args, {})
endfunction
"▶2 command.add  :: {f}, cid, cstr, copts → + :command, …
"▶3 getspfunc    :: plid, cid, copts, spref → Maybe sp
function s:F.getspfunc(plid, cid, copts, spref)
    let key=a:spref.'splitfunc'
    if !has_key(a:copts, key)
        return 0
    elseif type(a:copts[key])==type('')
        try
            call matchstr('', a:copts[key])
        catch
            call s:_f.throw('invsreg', a:cid, a:plid, a:copts[key], v:exception)
        endtry
    elseif !exists('*a:copts[key]') && a:copts[key] isnot 0
        call s:_f.throw('invsp', a:cid, a:plid, a:spref)
    endif
    return a:copts[key]
endfunction
"▲3
let s:cmddefaults={
            \   'nargs': '0',
            \'complete':  0,
            \   'range':  0,
            \   'count':  0,
            \    'bang':  0,
            \     'bar':  1,
            \'register':  0,
            \  'buffer':  0,
        \}
let s:compaugprefix='LoadCompFunc_'
function s:F.command.add(plugdict, fdict, cid, cstr, copts)
    "▶3 Checking arguments
    if type(a:cid)!=type('')
        call s:_f.throw('cidnstr', a:plugdict.id)
    elseif a:cid!~#'^\u\w*$'
        call s:_f.throw('invcid', a:plugdict.id, a:cid)
    elseif has_key(s:commands, a:cid)
        call s:_f.throw('ciddef', a:cid, a:plugdict.id, s:commands[a:cid].plid)
    elseif exists(':'.a:cid)
        call s:_f.throw('cidedef', a:cid, a:plugdict.id)
    elseif type(a:copts)!=type({})
        call s:_f.throw('coptsndct', a:cid, a:plugdict.id)
    endif
    "▲3
    let cmd   =   {'id': a:cid,
                \'plid': a:plugdict.id,
                \'augs': [],
                \'funs': [],
                \  'fs': {},
                \}
    if a:plugdict.type is# 'ftplugin'
        let cmd.filetype=matchstr(a:plugdict.id, '\v^[^/]*', 9)
    endif
    let cmdstring=''
    let addargs=[]
    "▶3 Process *splitfunc
    let cmd.sp=s:F.getspfunc(a:plugdict.id, a:cid, a:copts, '')
    let cmd.rsp=s:F.getspfunc(a:plugdict.id, a:cid, a:copts, 'r')
    "▶3 Create :command -options
    for [key, value] in sort(items(s:cmddefaults))
        if a:plugdict.type is# 'ftplugin' && key is# 'buffer'
            let value=1
        elseif has_key(a:copts, key)
            "▶4 Completion
            if key is# 'complete'
                let d={}
                let d.complete=a:copts.complete
                let tcomplete=type(d.complete)
                let cmd.compfname='s:Complete'.cmd.id
                "▶5 Use function
                if tcomplete==2
                    let fname=s:F.rewritefname(a:plugdict.sid, a:copts.complete)
                    if fname=~#'^\d'
                        let cmd.compfunc=d.complete
                        let intfname='s:commands.'.cmd.id.'.compfunc'
                        execute      "function ".cmd.compfname."(...)\n".
                                    \"    return call(".intfname.",a:000,{})\n".
                                    \"endfunction"
                    else
                        let cmd.compfname=fname
                    endif
                    let cmdstring.='-complete=customlist,'.(cmd.compfname).' '
                "▶5 Use function described by dictionary
                elseif tcomplete==type({})
                    if !exists('*a:plugdict.g._f.wrapfunc')
                        call s:_f.throw('nowrapfunc', a:cid, a:plugdict.id)
                    endif
                    let cmd.wrapfunc=a:plugdict.g._f.wrapfunc
                    call s:F.addfunc(cmd, a:plugdict.status, d.complete)
                    let cmdstring.='-complete=customlist,'.(cmd.compfname).' '
                "▶5 Use FWC string
                elseif tcomplete==type([])
                    let cmd.g=a:plugdict.g
                    call s:F.addfunc(cmd, a:plugdict.status, d.complete)
                    let cmdstring.='-complete=customlist,'.(cmd.compfname).' '
                "▶5 Use something else
                elseif tcomplete==type('')
                    let cmdstring.='-complete='.(d.complete).' '
                "▶5 Fail
                else
                    call s:_f.throw('ucomp', a:cid, a:plugdict.id)
                endif
            "▶4 Other options
            else
                unlet value
                let value=a:copts[key]
                if key is# 'range'
                    if index([0, 1, '%'], value)==-1
                        call s:_f.throw('invrange', a:cid, a:plugdict.id,
                                    \               string(value))
                    elseif has_key(a:copts, 'count')
                        call s:_f.throw('hascount', a:cid, a:plugdict.id)
                    elseif value isnot 0
                        let addargs+=['<line1>', '<line2>']
                    endif
                elseif key is# 'count'
                    if  !(value is 0 || value is 1 ||
                            \(type(value)==type('') && value=~#'^\d\+$'))
                        call s:_f.throw('invcount', a:cid, a:plugdict.id,
                                    \               string(value))
                    elseif value isnot 0
                        let addargs+=['<count>']
                    endif
                elseif (key is# 'bang' || key is# 'bar' || key is# 'register' ||
                            \key is# 'buffer')
                    if !(value is 0 || value is 1)
                        call s:_f.throw('invkey', a:cid, a:plugdict.id, key)
                    elseif key is# 'bang' && value
                        let addargs+=['<bang>0']
                    elseif key is# 'register' && value
                        let addargs+=['<q-reg>']
                    endif
                elseif key is# 'nargs' && index(['0', '1', '*', '?', '+'],
                            \                   value)==-1
                    call s:_f.throw('invnargs', a:cid, a:plugdict.id,
                                \               string(value))
                endif
            endif
            "▲4
        endif
        if key is# 'nargs' && cmd.rsp isnot 0
            let cmdstring.='-nargs=1 '
        elseif value is 1
            let cmdstring.='-'.key.' '
        elseif type(value)==type('')
            let cmdstring.='-'.key.'='.value.' '
        endif
        unlet value
    endfor
    "▲3
    let cmdstring.=cmd.id.' '
    "▶3 Process replacement
    if type(a:cstr)==type('')
        let cmdstring.=(a:cstr)
    else
        if type(a:cstr)==type({})
            if !exists('*a:plugdict.g._f.wrapfunc')
                call s:_f.throw('nowrapfunc', a:cid, a:plugdict.id)
            endif
            let cmd.wrapfunc=a:plugdict.g._f.wrapfunc
            let cmd.f=a:cstr
        elseif exists('*a:cstr')
            let cmd.f=a:cstr
        else
            call s:_f.throw('urepl', a:cid, a:plugdict.id)
        endif
        let args=''
        if !empty(addargs)
            let args='['.join(addargs, ', ').']+'
        endif
        if cmd.rsp is 0
            let args.='[<f-args>]'
        elseif type(cmd.rsp)==type('')
            let args.='s:F.cmdsplit(<q-args>, s:commands.'.a:cid.'.rsp)'
        else
            let args.='s:commands.'.a:cid.'.rsp(<q-args>)'
        endif
        if type(a:cstr)==type({})
            let cmd.newcmdstring=cmdstring.
                        \     'call call(s:commands.'.a:cid.'.f, '.args.', {})'
            let cmdstring.='call s:F.runcmd(s:commands.'.a:cid.', '.args.')'
        else
            let cmdstring.='call call(s:commands.'.a:cid.'.f, '.args.', {})'
        endif
    endif
    "▲3
    let cmd.cmdstring=cmdstring
    let a:fdict[cmd.id]=cmd
    "▶3 Add cmd to various global variables, execute :command
    let s:commands[cmd.id]=cmd
    if has_key(cmd, 'filetype')
        if !has_key(s:fts, cmd.filetype)
            let s:fts[cmd.filetype]={}
        endif
        let s:fts[cmd.filetype][cmd.id]=cmd
        let buf=bufnr('%')
        if !has_key(s:bufcommands, buf)
            let s:bufcommands[buf]={}
        endif
        if index(split(&filetype, '\.'), cmd.filetype)!=-1
            execute 'command' cmdstring
            let s:bufcommands[buf][cmd.id]=cmd
        endif
    else
        execute 'command' cmdstring
    endif
    "▲3
endfunction
"▶2 command.del  :: {f}[, cid] → + :delcommand, s:commands
function s:F.command.del(plugdict, fdict, ...)
    let todel=keys(a:fdict)
    if a:0
        "▶3 Проверка аргумента
        if type(a:1)!=type('')
            call s:_f.throw('dcidnstr', a:plugdict.id)
        elseif !has_key(a:fdict, a:1)
            call s:_f.throw('nowncid', a:plugdict.id, a:1)
        endif
        "▲3
        let todel=[a:1]
    endif
    for cid in todel
        if has_key(a:fdict[cid], 'FWCid')
            call s:_f.fwc.del(a:fdict[cid].FWCid)
        endif
        if has_key(a:fdict[cid], 'fs')
            for fname in keys(a:fdict[cid].fs)
                execute 'delfunction s:'.fname
            endfor
        endif
        unlet s:commands[cid]
        unlet a:fdict[cid]
        execute 'delcommand' cid
    endfor
endfunction
"▶2 Register feature
call s:_f.newfeature('command', {'cons': s:F.command,
            \                  'unload': s:F.command.del,})
"▶1 ftcommand     :: () → + :delcommand, :command, s:bufcommands
function s:F.ftcommand()
    let buf=expand('<abuf>')
    if has_key(s:bufcommands, buf)
        for cid in keys(s:bufcommands[buf])
            execute 'delcommand' cid
        endfor
    else
        let s:bufcommands[buf]={}
    endif
    for filetype in filter(split(&filetype, '\V.'), 'has_key(s:fts, v:val)')
        for cmd in values(s:fts[filetype])
            execute 'command' cmd.cmdstring
            let s:bufcommands[buf][cmd.id]=cmd
        endfor
    endfor
endfunction
"▶1 bufentered    :: () → s:F.ftcommand()
function s:F.bufentered()
    let buf=expand('<abuf>')
    if !has_key(s:bufcommands, buf)
        call s:F.ftcommand()
    endif
endfunction
"▶1 bufdeleted    :: () → + s:bufcommands
function s:F.bufdeleted()
    let buf=expand('<abuf>')
    if has_key(s:bufcommands, buf)
        unlet s:bufcommands[buf]
    endif
endfunction
"▶1 Create autocommands
call s:_f.augroup.add('Commands', [['BufEnter',  '*', 0, s:F.bufentered],
            \                      ['BufDelete', '*', 0, s:F.bufdeleted],
            \                      ['Filetype',  '*', 0, s:F.ftcommand ]])
"▶1
call frawor#Lockvar(s:, 'commands,fts,bufcommands')
" vim: fmr=▶,▲ sw=4 ts=4 sts=4 et tw=80
