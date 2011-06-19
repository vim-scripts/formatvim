"▶1 Header
scriptencoding utf-8
execute frawor#Setup('0.0', {'@/decorators': '0.0',
            \                    '@/checks': '0.0',
            \      '@/decorators/altervars': '0.0'}, 1)
"▶1 Define messages
if v:lang=~?'ru'
    let s:_messages={
                \    'idnotstr': 'Ошибка создания сохраняющей и '.
                \                'восстанавливающей функций для '.
                \                'дополнения %s: их название '.
                \                'не является строкой',
                \       'invid': 'Ошибка создания сохраняющей и '.
                \                'восстанавливающей функций для '.
                \                'дополнения %s: строка «%s» '.
                \                'не может являться названием',
            \}
    call extend(s:_messages, map({
                \     'altnlst': 'ключ «altervars» не является списком',
                \   'altelnlst': 'элемент %u значения ключа «altervars» '.
                \                'описания функции не является списком',
                \ 'altelinvlen': 'элемент %u значения ключа «altervars» '.
                \                'описания функции имеет неверную длину %u '.
                \                '(список должен содержать один или '.
                \                 'два элемента)',
                \   'altelnstr': 'первый элемент элемента %u значения ключа '.
                \                '«altervars» описания функции '.
                \                'не является строкой',
                \    'invvnlen': 'неверен первый элемент элемента %u '.
                \                'значения ключа «altervars»: длина строки '.
                \                'не может быть меньше двух символов',
                \    'invvname': 'неверен первый элемент элемента %u '.
                \                'значения ключа «altervars»: строка «%s» '.
                \                'не может являться именем переменной',
                \    'noocpref': 'неверен первый элемент элемента %u '.
                \                'значения ключа «altervars»: в имени '.
                \                'настройки «%s» отсутстувет префикс '.
                \                '(g: или l:)',
                \    'invoname': 'неверен первый элемент элемента %u '.
                \                'значения ключа «altervars»: строка «%s» '.
                \                'не может являться именем настройки',
                \     'invoval': 'неверен второй элемент элемента %u '.
                \                'значения ключа «altervars»: '.
                \                'тип элемента не совпадает с типом настройки',
                \     'noclose': 'неверен первый элемент элемента %u '.
                \                'значения ключа «altervars»: '.
                \                'отсутствует закрывающая скобка',
                \     'spnoarg': 'неверен первый элемент элемента %u '.
                \                'значения ключа «altervars»: '.
                \                'сохраняющая функция %s не принимает '.
                \                'дополнительных аргументов',
                \'acheckfailed': 'неверен первый элемент элемента %u '.
                \                'значения ключа «altervars»: '.
                \                'аргумент сохраняющей функции %s не прошёл '.
                \                'проверку',
                \      'usaver': 'неверен первый элемент элемента %u '.
                \                'значения ключа «altervars»: '.
                \                'неизвестна сохраняющая функция %s',
                \    'spmisarg': 'неверен первый элемент элемента %u '.
                \                'значения ключа «altervars»: '.
                \                'сохраняющая функция %s требует наличия '.
                \                'дополнительного аргумента',
                \      'notdep': 'неверен первый элемент элемента %u '.
                \                'значения ключа «altervars»: '.
                \                'дополнение %s, определившее сохраняющую '.
                \                'функцию %s, не указано в списке зависимостей',
                \        'ualt': 'неверен первый элемент элемента %u '.
                \                'значения ключа «altervars»: '.
                \                'способ обработки «%s» неизвестен',
            \}, '"Ошибка создания функции %s для дополнения %s: ".v:val'))
    call extend(s:_messages, map({
                \     'ssiddef': 'функции уже определены дополнением %s',
                \  'savnotfunc': 'второй аргумент не является '.
                \                'ссылкой на функцию',
                \  'setnotfunc': 'третий аргумент не является '.
                \                'ссылкой на функцию',
                \  'ssmanyargs': 'слишком большое количество аргументов',
                \  'ssoptsndct': 'дополнительный аргумент не является словарём',
                \   'sssavuref': 'сохраняющая функция является ссылкой '.
                \                'на неизвестную функцию',
                \   'ssseturef': 'восстанавливающая функция является ссылкой '.
                \                'на неизвестную функцию',
            \},
            \'"Ошибка создания сохраняющей и восстанавливающей функций '.
            \ '%s для дополнения %s: ".v:val'))
else
    let s:_messages={
                \    'idnotstr': 'Error while creating saver and setter '.
                \                'functions for plugin %s: id is not a String',
                \       'invid': 'Error while creating saver and setter '.
                \                'functions for plugin %s: string `%s'' '.
                \                'is not a valid identifier',
            \}
    call extend(s:_messages, map({
                \     'altnlst': 'key `altervars'' is not a list',
                \   'altelnlst': 'element %u of `altervars'' value '.
                \                'of the function description is not a list',
                \ 'altelinvlen': 'element %u of `altervars'' value '.
                \                'of the function description has invalid '.
                \                'length %u while expected 1 or 2',
                \   'altelnstr': 'first element of element %u of `altervars'' '.
                \                'value of the function description is '.
                \                'not a string',
                \    'invvnlen': 'first element of element %u of `altervars'' '.
                \                'value is not valid: string must be at least '.
                \                'two characters long',
                \    'invvname': 'first element of element %u of `altervars'' '.
                \                'value is not valid: string `%s'' '.
                \                'is not a variable name',
                \    'noocpref': 'first element of element %u of `altervars'' '.
                \                'value is not valid: there should be '.
                \                'g: or l: prefix before option name in '.
                \                'the string `%s''',
                \    'invoname': 'first element of element %u of `altervars'' '.
                \                'value is not valid: string `%s'' '.
                \                'is not an option name',
                \     'invoval': 'second element of element %u '.
                \                'of `altervars'' value is not valid: '.
                \                'type of the element does not match type of '.
                \                'the option',
                \     'noclose': 'first element of element %u of `altervars'' '.
                \                'value is not valid: closing bracket '.
                \                'not found',
                \     'spnoarg': 'first element of element %u of `altervars'' '.
                \                'value is not valid: saver %s does '.
                \                'not accept additional arguments',
                \'acheckfailed': 'first element of element %u of `altervars'' '.
                \                'value is not valid: argument of saver %s '.
                \                'failed to pass check',
                \      'usaver': 'first element of element %u of `altervars'' '.
                \                'value is not valid: saver %s is not known',
                \    'spmisarg': 'first element of element %u of `altervars'' '.
                \                'value is not valid: saver %s requires '.
                \                'additional argument',
                \      'notdep': 'first element of element %u of `altervars'' '.
                \                'value is not valid: plugin %s that defined '.
                \                'saver %s is not in dependencies list',
                \        'ualt': 'first element of element %u of `altervars'' '.
                \                'value is not valid: unable to determine '.
                \                'how to process %s',
            \}, '"Error while creating function %s for plugin %s: ".v:val'))
    call extend(s:_messages, map({
                \     'ssiddef': 'they were already defined by plugin %s',
                \  'savnotfunc': 'saver is not a function reference',
                \  'setnotfunc': 'setter is not a function reference',
                \  'ssmanyargs': 'too many arguments',
                \  'ssoptsndct': 'options argument is not a Dictionary',
                \   'sssavuref': 'saver is a reference to unknown function',
                \   'ssseturef': 'setter is a reference to unknown function',
            \},
            \'"Error while creating saver and setter functions with id %s '.
            \ 'for plugin %s: ".v:val'))
endif
"▶1 rewritefname    :: sid, Funcref → funcname
function s:F.rewritefname(sid, Fref)
    let fstr=string(a:Fref)[10:-3]
    if fstr[:1] is# 's:'
        let fstr='<SNR>'.a:sid.'_'.fstr[2:]
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
"▶1 Decorator
let s:altervars={'lastid': 0}
let s:ss={}
let s:altdict={'altervars': s:altervars,
            \         'ss': s:ss}
function s:F.altervars(plugdict, fname, arg)
    "▶2 Check a:arg
    if type(a:arg)!=type([])
        call s:_f.throw('altnlst', a:fname, a:plugdict.id)
    endif
    "▶2 Define variables
    let preret=['let @$@={}',
                \     'try',]
    let postret=['finally']
    let laltvars=len(a:arg)
    let plid=a:plugdict.id
    let i=0
    let id=printf('%x', s:altervars.lastid)
    let fpref='@%@.altervars.'.id
    let altcopy=map(copy(a:arg), 'copy(v:val)')
    let s:altervars[id]=altcopy
    let s:altervars.lastid+=1
    "▲2
    while i<laltvars
        "▶2 Check current element
        if type(a:arg[i])!=type([])
            call s:_f.throw('altelnlst', a:fname, plid, i)
        elseif empty(a:arg[i]) || len(a:arg[i])>2
            call s:_f.throw('altelinvlen', a:fname, plid, i, len(a:arg[i]))
        elseif type(a:arg[i][0])!=type('')
            call s:_f.throw('altelnstr', a:fname, plid, i)
        endif
        "▲2
        let element=altcopy[i]
        let varname=element[0]
        let vnlen=len(varname)
        let hasvar=(len(element)>1)
        let warnargs="'".varname."', '".a:fname."', ".
                    \substitute(string(plid), "\n",
                    \           '''."\\n".''', 'g').', v:exception'
        "▶2 Check varname length
        if vnlen<2
            call s:_f.throw('invvnlen', a:fname, plid, i)
        "▶2 Process variables
        elseif varname[1] is# ':' && index(['g','b','t','w'], varname[0])!=-1
            "▶3 Check variable name
            if varname[2:]!~#'^\h\w*$'
                call s:_f.throw('invvname', a:fname, plid, i, varname[2:])
            endif
            "▲3
            let preret+=['if exists("'.varname.'")',
                        \          'let @$@.'.i.'='.varname]
            if hasvar
                " Unlet variable to be sure that it won't cause E706 
                " (variable type mismatch) error
                let preret+=['unlet '.varname,
                            \   'endif',
                            \   'let '.varname.'=']
                if type(element[1])==type(0) ||
                            \(has('float') && type(element[1])==type(0.0) &&
                            \ string(element[1])!~'\w')
                    let preret[-1].=string(element[1])
                else
                    let preret[-1].=fpref.'['.i.'][1]'
                endif
            else
                call add(preret, 'endif')
            endif
            " Restore the previous status: variable will be left undefined if it 
            " was not defined before function was run
            let postret+=['if exists("'.varname.'")',
                        \         'unlet '.varname,
                        \     'endif',
                        \     'if has_key(@$@, '.i.')',
                        \         'let '.varname.'=@$@.'.i,
                        \     'endif',]
        "▶2 Process options
        elseif varname[0] is# '&' && vnlen>3
            "▶3 Check option name
            if varname[2] isnot# ':' || !(varname[1] is# 'g' || varname[1] is# 'l')
                call s:_f.throw('noocpref', a:fname, plid, i, varname)
            elseif varname[3:]!~#'^\l\+$'
                call s:_f.throw('invoname', a:fname, plid, i, varname[3:])
            endif
            "▲3
            if exists('+'.varname[1:])
                let ovarname='@$@'.varname[1].'_'.varname[3:]
                call add(preret, 'let '.ovarname.'='.varname)
                if hasvar
                    "▶3 Check value type
                    if type(element[1])!=type(eval(varname))
                        call s:_f.throw('invoval', a:fname, plid, i)
                    endif
                    "▲3
                    call add(preret, 'let '.varname.'='.
                                \substitute(string(element[1]), '\n',
                                \                  '''."\\n".''', 'g'))
                endif
                let postret+=['let '.varname.'='.ovarname]
            endif
        "▶2 Process special
        elseif varname[0] is# '+'
            "▶3 *args, varname
            let saveargs=''
            let setargs=fpref.'['.i.'][1]'
            let set2args='@$@.'.i
            let varname=varname[1:]
            "▲3
            let bidx=stridx(varname, '(')
            "▶3 If argument is supplied
            if bidx!=-1
                "▶4 Altering varname, element and *args variables
                let noclose=(varname[-1:] isnot# ')')
                if !hasvar
                    call add(element, 0)
                endif
                call add(element, varname[(bidx+1):-2])
                let varname=varname[:(bidx-1)]
                let element[0]='+'.varname
                let saveargs=fpref.'['.i.'][2]'
                let setargs.=', '.saveargs
                let set2args.=', '.saveargs
                "▶4 Check existance of special
                if !has_key(s:ss, varname)
                    call s:_f.throw('usaver', a:fname, plid, i, varname)
                endif
                let ssdef=s:ss[varname]
                "▶4 Checking () expr
                if noclose
                    call s:_f.throw('noclose', a:fname, plid, i)
                elseif !ssdef.hasarg
                    call s:_f.throw('spnoarg', a:fname, plid, i, varname)
                elseif has_key(ssdef, 'checker') && !ssdef.checker([element[2]])
                    call s:_f.throw('acheckfailed', a:fname, plid, i, varname)
                endif
            "▶3 Else just check existance of special
            else
                if !has_key(s:ss, varname)
                    call s:_f.throw('usaver', a:fname, plid, i, varname)
                endif
            endif
            "▲3
            let ssdef=s:ss[varname]
            "▶3 Check special name and existance of all arguments
            if ssdef.hasarg==2 && bidx==-1
                call s:_f.throw('spmisarg', a:fname, plid, i, varname)
            elseif !has_key(a:plugdict.dependencies, ssdef.plid)
                call s:_f.throw('notdep', a:fname, plid, i, ssdef.plid, varname)
            endif
            "▲3
            let preret+=['try',
                        \          'let @$@.'.i.'=@%@.ss.'.varname.'.saver'.
                        \                                      '('.saveargs.')',
                        \      'catch',
                        \          'call s:_f.warn("savexcept", '.warnargs.')',
                        \      'endtry',]
            if hasvar
                let preret+=['try',
                            \          'call @%@.ss.'.varname.'.setter'.
                            \                                   '('.setargs.')',
                            \      'catch',
                            \          'call s:_f.warn("setexcept", '.
                            \                                 warnargs.')',
                            \      'endtry',]
            endif
            let postret+=['try',
                        \         'call @%@.ss.'.varname.'.setter'.
                        \                                      '('.set2args.')',
                        \     'catch',
                        \         'call s:_f.warn("set2except", '.warnargs.')',
                        \     'endtry',]
        "▶2 Process unknown
        else
            call s:_f.throw('ualt', a:fname, plid, i, varname)
        endif
        "▶2 Finish cycle (increment+unlet)
        let i+=1
        unlet element
        "▲2
    endwhile
    call add(postret, 'endtry')
    return [192, '@@@', s:altdict, preret, postret, 0]
endfunction
call s:_f.adddecorator('altervars', s:F.altervars)
"▶1 addaltspecial feature
"▶2 delaltspecials  :: {f} → s:ss, fdict
function s:F.delaltspecials(plugdict, fdict)
    for ssdef in values(a:fdict)
        unlet s:ss[ssdef.id]
        unlet a:fdict[ssdef.id]
    endfor
endfunction
"▶2 addaltspecial   :: {f}, ssid, Saver::Funcref, Setter::Funcref[, ssopts] → +…
function s:F.addaltspecial(plugdict, fdict, ssid, Saver, Setter, ...)
    "▶3 Check arguments
    if type(a:ssid)!=type('')
        call s:_f.throw('idnotstr', a:plugdict.id)
    elseif a:ssid!~#'^\h\w*$'
        call s:_f.throw('invid', a:plugdict.id, a:ssid)
    elseif has_key(s:ss, a:ssid)
        call s:_f.throw('ssiddef', a:ssid, a:plugdict.id,
                    \              s:ss[a:ssid].plid)
    elseif type(a:Saver)!=2
        call s:_f.throw('savnotfunc', a:ssid, a:plugdict.id)
    elseif type(a:Setter)!=2
        call s:_f.throw('setnotfunc', a:ssid, a:plugdict.id)
    elseif a:0>1
        call s:_f.throw('ssmanyargs', a:ssid, a:plugdict.id)
    elseif a:0
        if type(a:1)!=type({})
            call s:_f.throw('ssoptsndct', a:ssid, a:plugdict.id)
        endif
    endif
    "▲3
    let ssdef={
                \    'id': a:ssid,
                \  'plid': a:plugdict.id,
                \ 'saver': s:F.refunction(a:plugdict.sid, a:Saver,
                \                         'sssavuref', a:ssid, a:plugdict.id),
                \'setter': s:F.refunction(a:plugdict.sid, a:Setter,
                \                         'ssseturef', a:ssid, a:plugdict.id),
                \'hasarg': 0,
            \}
    if a:0
        if has_key(a:1, 'requiresarg')
            let ssdef.hasarg=2
        elseif has_key(a:1, 'acceptsarg')
            let ssdef.hasarg=1
        endif
        if has_key(a:1, 'checker')
            let ssdef.checker=s:_f.conschecker(a:1.checker)
        endif
    endif
    let s:ss[ssdef.id]=ssdef
    let a:fdict[ssdef.id]=ssdef
endfunction
"▶2 Register feature
call s:_f.newfeature('addaltspecial', {'cons': s:F.addaltspecial,
            \                        'unload': s:F.delaltspecials,})
"▶1 Savers/setters
"▶2 Define dictionaries
let s:F.saver={}
let s:F.setter={}
let s:F.sschk={}
"▶2 window
function s:F.saver.window()
    return [tabpagenr(), winnr()]
endfunction
function s:F.setter.window(twnr)
    if type(a:twnr)==type([]) && len(a:twnr)==2
                \&& type(a:twnr[0])==type(0) && a:twnr[0]<=tabpagenr('$')
                \&& type(a:twnr[1])==type(0) && a:twnr[1]<=winnr('$')
        try
            if tabpagenr()!=a:twnr[0]
                execute 'tabnext' a:twnr[0]
            endif
            if winnr()!=a:twnr[1]
                execute a:twnr[1].'wincmd w'
            endif
        catch
            echohl ErrorMsg
            echomsg v:exception
            echohl None
        endtry
    endif
endfunction
call s:_f.addaltspecial('window', s:F.saver.window, s:F.setter.window)
"▶2 winview
call s:_f.addaltspecial('winview', function('winsaveview'),
            \                      function('winrestview'))
"▶2 buffer
function s:F.saver.buffer()
    return bufnr('%')
endfunction
function s:F.setter.buffer(bufnr)
    if type(a:bufnr)==type(0) && a:bufnr!=bufnr('%') && bufexists(a:bufnr)
        try
            execute 'buffer' a:bufnr
        catch
            " Setter must not throw anything: it may break things
            echohl ErrorMsg
            echomsg v:exception
            echohl None
        endtry
    endif
endfunction
call s:_f.addaltspecial('buffer', s:F.saver.buffer, s:F.setter.buffer)
"▶2 variables
"▶3 check
function s:F.sschk.variables(arg)
    if a:arg[0]!~#'^[gtbw]$'
        call s:_f.throw('invvcvar', a:arg[0])
    endif
    return 1
endfunction
"▶3 save
function s:F.saver.variables(...)
    let dname=get(a:000, 0, 'g').':'
    return copy(eval(dname))
endfunction
"▶3 set
function s:F.setter.variables(oldv, ...)
    if type(a:oldv)!=type({})
        return
    endif
    let dname=get(a:000, 0, 'g').':'
    let v=eval(dname)
    for name in filter(keys(v), '!has_key(a:oldv, v:val)')
        unlet v[name]
    endfor
    call extend(v, filter(a:oldv, 'v:key=~#"^\\h\\w*$"'), 'force')
endfunction
"▲3
call s:_f.addaltspecial('variables', s:F.saver.variables, s:F.setter.variables,
            \                               {'checker': s:F.sschk.variables,
            \                             'acceptsarg': 1,})
"▶2 matches
call s:_f.addaltspecial('matches',function('getmatches'),function('setmatches'))
"▶2 qflist
function s:F.setqflist(list)
    return setqflist(a:list, 'r')
endfunction
call s:_f.addaltspecial('qflist', function('getqflist'), s:F.setqflist)
"▲2
unlet s:F.saver s:F.setter s:F.sschk
"▶1
call frawor#Lockvar(s:, 'altervars,ss,altdict')
lockvar 1 s:altdict
" vim: fmr=▶,▲ sw=4 ts=4 sts=4 et tw=80
