"▶1 Header
scriptencoding utf-8
execute frawor#Setup('0.0', {'@/decorators': '0.0',
            \              '@/autocommands': '0.0',}, 1)
"▶1 _messages
if v:lang=~?'ru'
    let s:_messages={
                \    'fnotdict': 'аргумент, описывающий функции, '.
                \                'должен быть словарём',
                \    'invfname': 'строка «%s» не может являться именем функции',
                \        'uref': 'ключ «%s» описания фунцкции %s содержит '.
                \                'ссылку на неизвестную функцию',
            \}
    call map(s:_messages, '"Ошибка создания функций для дополнения %s: ".'.
                \           'v:val')
    call extend(s:_messages, map({
                \'foptsnotdict': 'описание функции не является словарём',
                \        'fdef': 'функция уже определена',
                \      'nofunc': 'описание функции не содержит '.
                \                'ключа «function»',
                \        'nref': 'ключ «%s» не является ссылкой на функцию',
                \   'invdecret': 'декоратор %s вернул неверное значение',
                \     'decndep': 'дополнение, определившее декоратор %s, '.
                \                'не находится в списке зависимостей',
            \},
            \'"Ошибка создания функции %s для дополнения %s: ".v:val'))
    call extend(s:_messages, {
                \ 'checkfailed': 'Аргументы функции %s дополнения %s '.
                \                'не прошли проверку',
                \'filterfailed': 'Фильтр функции %s дополнения %s вернул '.
                \                'значение, не являющееся списком',
                \    'invvcvar': 'Строка «%s» не может указывать на то, '.
                \                'какие переменные следует сохранить',
                \   'savexcept': 'Ошибка при запуске сохраняющей функции %s '.
                \                'для функции %s дополнения %s: %s',
                \   'setexcept': 'Ошибка при запуске восстанавливающей '.
                \                'функции %s для функции %s дополнения %s: %s',
                \  'set2except': 'Ошибка при восстановлении значения функцией '.
                \                '%s для функции %s дополнения %s: %s',
                \     'oexcept': 'Ошибка при установке настройки %s '.
                \                'для функции %s дополнения %s: %s',
                \    'deceqpri': 'Приоритет декораторов %s и %s совпадает',
            \})
else
    let s:_messages={
                \    'fnotdict': 'functions argument must be a dictionary',
                \    'invfname': '%s is not a valid function name',
                \        'uref': 'key `%s'' of %s function description '.
                \                'provides a reference to unknown function',
            \}
    call map(s:_messages, '"Error while creating functions for plugin %s: ".'.
                \           'v:val')
    call extend(s:_messages, map({
                \'foptsnotdict': 'function description must be a Dictionary',
                \        'fdef': 'function was already defined',
                \      'nofunc': 'function description lacks '.
                \                '`function'' key',
                \        'nref': 'key `%s'' is not a function reference',
                \   'invdecret': 'decorator %s returned invalid value',
                \     'decndep': 'plugin that defined decorator %s '.
                \                'is not in dependency list',
            \},
            \'"Error while creating function %s for plugin %s: ".v:val'))
    call extend(s:_messages, {
                \ 'checkfailed': 'Arguments of function %s of plugin %s '.
                \                'failed to pass check',
                \'filterfailed': 'Filter of function %s of plugin %s '.
                \                'returned value that is not a list',
                \    'invvcvar': 'String `%s'' does not describe which '.
                \                'variables should be saved',
                \   'savexcept': 'Error while running saver function %s '.
                \                'for function %s of a plugin %s: %s',
                \   'setexcept': 'Error while running setter function %s '.
                \                'for function %s of a plugin %s: %s',
                \  'set2except': 'Error while restoring value using setter '.
                \                'function %s for function %s of a plugin %s: '.
                \                '%s',
                \     'oexcept': 'Error while setting option %s '.
                \                'for function %s of a plugin %s: %s',
                \    'deceqpri': 'Decorators %s and %s have equal priority',
            \})
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
"▶1 refunction      :: sid, Funcref, throwargs → Funcref
function s:F.refunction(sid, Fref, ...)
    let fstr=s:F.rewritefname(a:sid, a:Fref)
    if string(+fstr) is# fstr
        return a:Fref
    else
        if !exists('*'.fstr)
            call call(s:_f.throw, a:000, {})
        endif
        return function(fstr)
    endif
endfunction
"▶1 delfunction     :: sid, Funcref → + :delfunction
function s:F.delfunction(sid, Fref)
    let fstr=s:F.rewritefname(a:sid, a:Fref)
    if string(+fstr) is# fstr || fstr=~#'^[a-z_]\+$'
        return 3
    elseif !exists('*'.fstr)
        return 2
    endif
    try
        execute 'delfunction '.fstr
    catch /^Vim(delfunction):E131:/
        " Normally you should catch this error for FraworUnload function, so 
        " it has bang
        return 0
    catch /^Vim(delfunction):E128:/
        return -1
    endtry
    return 1
endfunction
"▶1 delextfunctions :: {f} + p:_functions → + p:_functions, …
function s:F.delextfunctions(plugdict, fdict)
    if has_key(a:plugdict.g, '_functions') &&
                \type(a:plugdict.g._functions)==type([])
        let d={}
        unlockvar a:plugdict.g._functions
        for d.Function in a:plugdict.g._functions
            if type(d.Function)!=2 && type(d.Function)!=type('')
                continue
            endif
            call s:F.delfunction(a:plugdict.sid, d.Function)
        endfor
    endif
endfunction
"▶1 add_functions   :: {f} → + p:_functions
function s:F.add_functions(plugdict, fdict)
    if !has_key(a:plugdict.g, '_functions') ||
                \type(a:plugdict.g._functions)!=type([])
        let a:plugdict.g._functions=[]
    endif
endfunction
call s:_f.newfeature('delfunctions', {'unloadpre': s:F.delextfunctions,
            \                          'register': s:F.add_functions,
            \                        'ignoredeps': 1})
"▶1 decsort
function s:Decsort(a, b)
    let a=a:a[2]
    let b=a:b[2]
    if a==b
        call s:_f.warn('deceqpri', a:a[0], a:b[0])
        return ((a:a[0]>#a:b[0])?(-1):(1))
    endif
    return ((a>b)?(-1):(1))
endfunction
let s:_functions+=['s:Decsort']
"▶1 beatycode       :: function::[String] → function::[String]
let s:indents={
            \         'if': [ 0, 1],
            \     'elseif': [-1, 1],
            \       'else': [-1, 1],
            \      'endif': [-1, 0],
            \        'try': [ 0, 1],
            \      'catch': [-1, 1],
            \    'finally': [-1, 1],
            \     'endtry': [-1, 0],
            \   'function': [ 0, 1],
            \'endfunction': [-1, 0],
            \        'for': [ 0, 1],
            \     'endfor': [-1, 0],
            \      'while': [ 0, 1],
            \   'endwhile': [-1, 0],
        \}
function s:F.beatycode(func)
    let r=[]
    let indent=0
    for line in a:func
        let line=substitute(line, '^\s\+', '', '')
        let firstword=matchstr(line, '^\w\+')
        if has_key(s:indents, firstword)
            let indent+=s:indents[firstword][0]
            call add(r, repeat('    ', indent).line)
            let indent+=s:indents[firstword][1]
        else
            call add(r, repeat('    ', indent).line)
        endif
    endfor
    return r
endfunction
"▶1 wrapfunc        :: plugdict, funopts, fundictsname, fname → fundef + …
let s:subs =['"\\V@$@", pref,  "g"',
            \'"\\V@@@", args,  "g"',
            \'"\\V@%@", pvar,  "g"',
            \'"\\V@*@", fvar,  "g"',
            \'"\\V@=@", "_.r", "g"',
            \'"\\V@.@", "_.d", "g"',
            \]
let s:mapexpr=repeat('substitute(',len(s:subs))."v:val, ".join(s:subs,"), ").")"
let s:nargsexpr=substitute(s:mapexpr, 'v:val', 'newargs', '')
unlet s:subs
function s:F.wrapfunc(plugdict, funopts, fundictsname, fname)
    "▶2 Check a:funopts
    if !has_key(a:funopts, 'function')
        call s:_f.throw('nofunc', a:fname, a:plugdict.id)
    elseif type(a:funopts.function)!=2
        call s:_f.throw('nref', a:fname, a:plugdict.id, 'function')
    endif
    "▲2
    let fname=a:fname
    let fdicts=s:{a:fundictsname}
    let fundef =  {'id': printf('%x', fdicts.nextid),
                \'name':   fname,
                \'plid': a:plugdict.id,}
    let fdicts.nextid+=1
    let fdicts[fundef.id]=fundef
    "▶2 Add `function' key
    let fundef.function=s:F.refunction(a:plugdict.sid, a:funopts.function,
                \                      'uref', a:plugdict.id, 'function',
                \                              a:fname)
    "▶2 Define variables
    " Contains name of variable that holds arguments
    let args='a:000'
    "▲2
    let fpref='s:'.a:fundictsname.'.'.fundef.id
    let func=['function '.fname.'(...)',
                \'let _={"d": {}, "F": '.fpref.'.function}',
                \]
    let decs=map(filter(keys(a:funopts), 'v:val[0] is# "@"'),
                \'s:_r.getdecorator(v:val[1:])')
    let fblocks=[]
    let addedrval=0
    for decorator in decs
        "▶2 Check existance of decorator definer in dependencies
        if !has_key(a:plugdict.dependencies, decorator.plid)
            call s:_f.throw('decndep', a:fname, a:plugdict.id,
                        \              decorator.id)
        endif
        "▲2
        call add(fblocks, decorator.func(a:plugdict, fname,
                    \                    a:funopts['@'.decorator.id]))
        "▶2 Check decorator return value
        if type(fblocks[-1])!=type([])
                    \|| len(fblocks[-1])!=6
                    \|| type(fblocks[-1][0])!=type(0)
                    \|| type(fblocks[-1][1])!=type('')
                    \|| type(fblocks[-1][3])!=type([])
                    \|| type(fblocks[-1][4])!=type([])
                    \|| type(fblocks[-1][5])!=type(0)
            call s:_f.throw('invdecret', a:fname, a:plugdict.id,
                        \                decorator.id)
        endif
        "▲2
        if fblocks[-1][5] && !addedrval
            let addedrval=1
        endif
        call extend(fblocks[-1], [decorator.id, decorator.pref], 0)
    endfor
    call sort(fblocks, function('s:Decsort'))
    let end=[]
    let d={}
    let fvar='_.F'
    let pvarstart=fpref.'.decvars.'
    for [deid, pref, prior, newargs, d.privvar, preret, postret, rrv] in fblocks
        let pvar=pvarstart.deid
        let  preret=map(copy( preret), s:mapexpr)
        let postret=map(copy(postret), s:mapexpr)
        "▶2 Add private variable to fundef.decvars
        if d.privvar isnot 0
            if !has_key(fundef, 'decvars')
                let fundef.decvars={}
            endif
            let fundef.decvars[deid]=d.privvar
        endif
        unlet d.privvar
        "▲2
        let func+=preret
        call extend(end, postret, 0)
        let args=eval(s:nargsexpr)
    endfor
    if addedrval
        let func +=  ['let _.r=call('.fvar.', '.args.', _.d)']+end+
                    \['return _.r',
                    \ 'endfunction']
    else
        let func +=  ['return call('.fvar.', '.args.', _.d)']+end+
                    \['endfunction']
    endif
    execute join(s:F.beatycode(func), "\n")
    if fname isnot# 'fundef.cons'
        let fundef.cons=function(fname)
    endif
    return fundef
endfunction
"▶1 delfunctions    :: {f} → + s:{fundictsname}, fdict, …
function s:F.delfunctions(plugdict, fdict)
    for fundef in values(a:fdict.fundicts)
        if ((has_key(fundef, 'cons'))?
                    \(s:F.delfunction(a:plugdict.sid, fundef.cons)):
                    \(1))
            for key in ['checker', 'filter']
                if has_key(fundef, key)
                    call call(s:_f['del'.key], [fundef[key]], {})
                endif
            endfor
            unlet a:fdict.fundicts[fundef.id]
            unlet s:{a:fdict.fundictsname}[fundef.id]
        endif
    endfor
endfunction
"▶1 loadplugin      :: fdict → + fdict, …
function s:F.loadplugin(plid, fdict)
    call FraworLoad(a:plid)
    call s:_f.augroup.del(a:fdict.augname)
    for wfopts in a:fdict.delayed
        let fundef=call(s:F.wrapfunc, wfopts, {})
        let a:fdict.fundicts[fundef.id]=fundef
    endfor
    unlet a:fdict.augname a:fdict.delayed
endfunction
"▶1 addfunctions    :: {f}, functions::{fname: funopts} → + fdict, …
let s:extfunctions={'nextid': 0}
let s:lastdid=0
function s:F.addfunctions(plugdict, fdict, functions)
    "▶2 Check a:functions
    if type(a:functions)!=type({})
        call s:_f.throw('fnotdict', a:plugdict.id)
    endif
    "▲2
    let d={}
    for [fname, d.funopts] in items(a:functions)
        "▶2 Check d.funopts
        if type(d.funopts)!=type({})
            call s:_f.throw('foptsnotdict', fname, a:plugdict.id)
        endif
        "▶2 Replace s: prefix with <SNR>{SID}_
        let fstr=s:F.rewritefname(a:plugdict.sid, fname)
        "▶2 Check function name
        if fname!~#'\v^%((h:|\<SNR\>\d+_)\w+|[A-Z_]\w*)$'
            call s:_f.throw('invfname', fname, a:plugdict.id)
        "▶2 Throw an error or redefine existing function
        elseif exists('*'.fname)
            if !has_key(d.funopts, 'redefine')
                call s:_f.throw('fdef', fname, a:plugdict.id)
            else
                if !s:F.delfunction(a:plugdict.sid, function(fname))
                    call s:_f.throw('fdef', fname, a:plugdict.id)
                endif
            endif
        endif
        "▲2
        let wfopts=[a:plugdict, d.funopts, a:fdict.fundictsname, fname]
        if a:plugdict.status==2
            let fundef=call(s:F.wrapfunc, wfopts, {})
            let a:fdict.fundicts[fundef.id]=fundef
        else
            if !has_key(a:fdict, 'delayed')
                let a:fdict.delayed=[]
                let a:fdict.augname=printf('FraworFunctionLoad_%x', s:lastdid)
                let s:lastdid+=1
            endif
            let a:fdict.delayed+=[wfopts]
            let fpattern=substitute(fname, '\c\m^<SNR>', '*', '')
            call s:_f.augroup.add(a:fdict.augname,
                        \         [['FuncUndefined', fpattern, 0,
                        \           [s:F.loadplugin, a:plugdict.id, a:fdict]]])
        endif
    endfor
endfunction
call s:_f.newfeature('addextfunctions', {'cons': s:F.addfunctions,
            \                          'unload': s:F.delfunctions,
            \                            'init': {'fundicts': {},
            \                                 'fundictsname': 'extfunctions',}})
"▶1 wrapfunc_cons   :: {f}, funopts → Funcref + …
let s:wrappedfuncs={'nextid': 0}
function s:F.wrapfunc_cons(plugdict, fdict, funopts)
    if type(a:funopts)!=type({})
        call s:_f.throw('foptsnotdict', '.dictionary', a:plugdict.id)
    endif
    let fundef=s:F.wrapfunc(a:plugdict, a:funopts, a:fdict.fundictsname,
                \           'fundef.cons')
    let a:fdict.fundicts[fundef.id]=fundef
    return fundef.cons
endfunction
call s:_f.newfeature('wrapfunc', {'cons': s:F.wrapfunc_cons,
            \                   'unload': s:F.delfunctions,
            \                     'init': {'fundictsname': 'wrappedfuncs',
            \                                  'fundicts': {}}})
"▶1
call frawor#Lockvar(s:, 'extfunctions,wrappedfuncs,lastdid')
" vim: fmr=▶,▲ sw=4 ts=4 sts=4 et tw=80
