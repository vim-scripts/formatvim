"▶1 Header
scriptencoding utf-8
execute frawor#Setup('0.0', {'plugin/frawor/checks': '0.0'}, 1)
"▶1 Define messages
if v:lang=~?'ru'
    let s:_messages=map({
                \  'optnotstr': 'название настройки не является строкой',
                \'oprefnotstr': 'префикс не является строкой',
                \ 'invoprefix': 'строка «%s» не может являться '.
                \               'префиксом переменной',
            \}, '"Ошибка получения настройки для дополнения %s: ".v:val')
    call extend(s:_messages, map({
                \  'nooptions': 'глобальная переменная не содержит '.
                \               'описания настроек (_options)',
                \'_optnotdict': 'значение ключа _messages не является словарём',
                \   'nooption': 'отсутствует описание настройки',
                \ 'optnotdict': 'описание настройки не является словарём',
                \ 'scopesnstr': 'ключ «scopes» описания настройки должен '.
                \               'быть строкой',
                \  'invscopes': 'строка «%s» не является правильным '.
                \               'описанием локальности настройки',
                \'scopesanstr': 'второй аргумент должен быть строкой',
                \ 'invscopesa': 'строка «%s» не является правильным '.
                \               'описанием локальности настройки',
                \    'chkfail': 'проверка настройки провалилась '.
                \               '(настройка была получена из переменной %s)',
                \    'filfail': 'фильтрация настройки провалилась '.
                \               '(настройка была получена из переменной %s)',
                \    'onotdef': 'настройка нигде не определена',
                \ 'typenmatch': 'тип настройки, полеченной из переменной %s, '.
                \               'не совпадает с типом настройки, '.
                \               'полученной ранее',
                \  'mergefref': 'невозможно слить две ссылки на функции',
                \    'umerger': 'неверное значение ключа «merger»',
            \}, '"Ошибка получения настройки %s для дополнения %s: ".v:val'))
else
    let s:_messages=map({
                \  'optnotstr': 'option name is not a String',
                \'oprefnotstr': 'prefix is not a String',
                \ 'invoprefix': 'string `%s'' is not a valid option prefix',
            \}, '"Error while obtaining option for plugin %s: ".v:val')
    call extend(s:_messages, map({
                \  'nooptions': 'global variable does not contain _options',
                \'_optnotdict': '_messages key value is not a Dictionary',
                \   'nooption': 'option description is missing',
                \ 'optnotdict': 'option description is not a Dictionary',
                \ 'scopesnstr': '`scopes'' key must have a String value',
                \  'invscopes': "string `%s' is not a valid scopes description",
                \'scopesanstr': 'second argument is not a String',
                \ 'invscopesa': "string `%s' is not a valid scopes description",
                \    'chkfail': 'option failed to pass a check '.
                \               '(option was obtained from %s variable)',
                \    'filfail': 'option filtering failed'.
                \               '(option was obtained from %s variable)',
                \    'onotdef': 'option was not defined anywhere',
                \ 'typenmatch': 'type of the option obtained from %s variable '.
                \               'does not match type of the option obtained '.
                \               'earlier',
                \  'mergefref': 'unable to merge function references',
                \    'umerger': '`merger'' key value is not valid',
            \}, '"Error while obtaining option %s for plugin %s: ".v:val'))
endif
"▶1 getovalue  :: oshadow ovalue, oid, plid, ovar → ovalue
function s:F.getovalue(oshadow, ovalue, oid, plid, ovar)
    let d={}
    let d.ovalue=a:ovalue
    "▶2 Process checker
    if has_key(a:oshadow, 'checker')
        if !a:oshadow.checker([d.ovalue])
            call s:_f.throw('chkfail', a:oid, a:plid, a:ovar)
        endif
    endif
    "▶2 Process filter
    if has_key(a:oshadow, 'filter')
        let d.ovalue=deepcopy(d.ovalue)
        let d.newval=a:oshadow.filter([d.ovalue])
        if type(d.newval)!=type([]) || len(d.newval)!=1
            call s:_f.throw('filfail', a:oid, a:plid, a:ovar)
        endif
        let d.ovalue=d.newval[0]
    endif
    "▲2
    return d.ovalue
endfunction
"▶1 extendopts :: ovalue, ovalue, oid, plid, ovar → ovalue
let s:merges=[
            \'a:a+a:b',
            \'a:a.a:b', 0,
            \'a:a+a:b',
            \'extend(a:a, a:b, "keep")',
            \'a:a+a:b',
        \]
function s:F.extendopts(a, b, oid, plid, ovar)
    let ta=type(a:a)
    if ta!=type(a:b)
        call s:_f.throw('typenmatch', a:oid, a:plid, a:ovar)
    elseif ta==2
        call s:_f.throw('mergefref', a:oid, a:plid)
    endif
    return eval(s:merges[type(a:a)])
endfunction
"▶1 getoption  :: {f}, oid[, scopes] + p:_options, p:_oprefix → ovalue
let s:dochecks=1
function s:F.getoption(plugdict, fdict, oid, ...)
    "▶2 Check arguments
    if s:dochecks
        if type(a:oid)!=type('')
            call s:_f.throw('optnotstr', a:plugdict.id)
        elseif !has_key(a:plugdict.g, '_options')
            call s:_f.throw('nooptions', a:oid, a:plugdict.id)
        elseif type(a:plugdict.g._options)!=type({})
            call s:_f.throw('_optnotdict', a:oid, a:plugdict.id)
        elseif !has_key(a:plugdict.g._options, a:oid)
            call s:_f.throw('nooption', a:oid, a:plugdict.id)
        endif
    endif
    "▲2
    let option=a:plugdict.g._options[a:oid]
    "▶2 Check option
    if s:dochecks
        if type(option)!=type({})
            call s:_f.throw('optnotdict', a:oid, a:plugdict.id)
        endif
    endif
    "▶2 oshadow
    if !has_key(a:fdict.oshadow, a:oid)
        let oshadow={}
        "▶3 `scopes' key
        if has_key(option, 'scopes')
            if type(option.scopes)!=type('')
                call s:_f.throw('scopesnstr', a:oid, a:plugdict.id)
            elseif option.scopes!~#'^[wtbg]\+$'
                call s:_f.throw('invscopes', a:oid,a:plugdict.id,option.scopes)
            endif
            let oshadow.scopes=option.scopes
        else
            let oshadow.scopes='bg'
        endif
        "▶3 `merger' key
        if has_key(option, 'merger')
            if type(option.merger)==2 && exists('*option.merger')
                let oshadow.merger=option.merger
            elseif option.merger is# 'extend'
                let oshadow.merger=s:F.extendopts
            else
                call s:_f.throw('umerger', a:oid, a:plugdict.id)
            endif
        endif
        "▶3 `checker' and `filter' keys
        for key in ['checker', 'filter']
            if has_key(option, key)
                let oshadow[key]=s:_f['cons'.key](option[key], a:plugdict.g)
            endif
        endfor
        "▲3
        let a:fdict.oshadow[a:oid]=oshadow
    else
        let oshadow=a:fdict.oshadow[a:oid]
    endif
    "▶2 oprefix
    if !has_key(a:fdict, 'oprefix')
        if has_key(a:plugdict.g, '_oprefix')
            let oprefix=a:plugdict.g._oprefix
            if type(oprefix)!=type('')
                call s:_f.throw('oprefnotstr', a:plugdict.id)
            endif
        else
            let oprefix=split(a:plugdict.id, '/')[1]
        endif
        if oprefix!~#'^\h\w*$'
            call s:_f.throw('invoprefix', a:plugdict.id, oprefix)
        endif
        let a:fdict.oprefix=oprefix
    else
        let oprefix=a:fdict.oprefix
    endif
    "▶2 Process scopes
    "▶3 `merge' variable
    let d={}
    let merge=0
    if has_key(oshadow, 'merger')
        let merge=1
    endif
    "▶3 Get scopes
    if a:0
        if type(a:1)!=type('')
            call s:_f.throw('scopesanstr', a:oid, a:plugdict.id)
        elseif a:1!~#'^[wtbg]\+$'
            call s:_f.throw('invscopesa', a:oid, a:plugdict.id, a:1)
        endif
        let scopes=a:1
    else
        let scopes=oshadow.scopes
    endif
    "▲3
    for scope in split(scopes, '.\@=')
        "▶3 Options dictionary
        let ovar=scope.':'.oprefix.'Options'
        if exists(ovar)
            let soptions=eval(ovar)
            if type(soptions)==type({}) && has_key(soptions, a:oid)
                if merge
                    let d.newval=s:F.getovalue(oshadow, soptions[a:oid], a:oid,
                                \              a:plugdict.id, ovar)
                    if exists('d.ovalue')
                        let d.tmp=d.ovalue
                        let d.ovalue=oshadow.merger(d.tmp, d.newval, a:oid,
                                    \               a:plugdict.id, ovar)
                        unlet d.tmp
                    else
                        let d.ovalue=deepcopy(d.newval)
                    endif
                    unlet d.newval
                else
                    return s:F.getovalue(oshadow, soptions[a:oid], a:oid,
                                \        a:plugdict.id, ovar)
                endif
            endif
            unlet soptions
        endif
        "▶3 _option variable
        if a:oid=~#'^\w\+$'
            let ovar=scope.':'.oprefix.'_'.a:oid
            if exists(ovar)
                if merge
                    let d.newval=s:F.getovalue(oshadow, eval(ovar), a:oid,
                                \              a:plugdict.id, ovar)
                    if exists('d.ovalue')
                        let d.tmp=d.ovalue
                        let d.ovalue=oshadow.merger(d.tmp, d.newval, a:oid,
                                    \               a:plugdict.id, ovar)
                        unlet d.tmp
                    else
                        let d.ovalue=deepcopy(d.newval)
                    endif
                    unlet d.newval
                else
                    return s:F.getovalue(oshadow, eval(ovar), a:oid, 
                                \        a:plugdict.id, ovar)
                endif
            endif
        endif
        "▲3
    endfor
    "▶2 `default' key
    if has_key(option, 'default')
        if merge
            let d.newval=option.default
            if exists('d.ovalue')
                let d.tmp=d.ovalue
                let d.ovalue=oshadow.merger(d.tmp, d.newval, a:oid,
                            \               a:plugdict.id, 'default')
            else
                let d.ovalue=deepcopy(d.newval)
            endif
            return d.ovalue
        else
            return option.default
        endif
    endif
    "▲2
    if exists('d.ovalue')
        return d.ovalue
    else
        call s:_f.throw('onotdef', a:oid, a:plugdict.id)
    endif
endfunction
call s:_f.newfeature('getoption', {'cons': s:F.getoption,
            \                      'init': {'oshadow': {}}})
"▶1
call frawor#Lockvar(s:, '')
" vim: fmr=▶,▲ sw=4 ts=4 sts=4 et tw=80
