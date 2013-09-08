"▶1 Header
scriptencoding utf-8
execute frawor#Setup('0.0', {'@/resources': '0.0'})
"▶1 Define messages
if v:lang=~?'ru'
    let s:_messages={
                \       'nodec': 'Обвязка «%s» не существует',
                \    'deidnstr': 'Имя обвязки, создаваемой для дополнения %s, '.
                \                'не является строкой',
                \     'invdeid': 'Ошибка создания обвязки для дополнения %s: '.
                \                'строка «%s» не может являться именем обвязки',
            \}
    call extend(s:_messages, map({
                \     'deiddef': 'обвязка уже определена дополнением %s',
                \     'decnfun': 'обвязка является не является ссылкой '.
                \                'на функцию',
                \      'deuref': 'обвязка является ссылкой '.
                \                'на неизвестную функцию',
            \},
            \'"Ошибка создания обвязки %s для дополнения %s: ".v:val'))
else
    let s:_messages={
                \       'nodec': 'Decorator `%s'' does not exist',
                \    'deidnstr': 'Error while creating decorator '.
                \                'for plugin %s: its identifier is not '.
                \                'a String',
                \     'invdeid': 'Error while creating decorator '.
                \                'for plugin %s: String `%s'' is not a valid '.
                \                'decorator identifier',
            \}
    call extend(s:_messages, map({
                \     'deiddef': 'decorator already defined by plugin %s',
                \     'decnfun': 'decorator is not a function reference',
                \      'deuref': 'decorator is a reference to unknown function',
            \},
            \'"Error while creating decorator %s for plugin %s: ".v:val'))
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
"▶1 adddecorator feature
"▶2 adddecorator    :: {f}, deid, Decorator::Funcref → + fdict, s:decorators
let s:decorators={}
let s:lastdeid=0
function s:F.adddecorator(plugdict, fdict, deid, Decorator)
    "▶3 Check arguments
    if type(a:deid)!=type('')
        call s:_f.throw('deidnstr', a:plugdict.id)
    elseif a:deid!~#'^\w\+$' && a:deid isnot# '_'
        call s:_f.throw('invdeid', a:plugdict.id, a:deid)
    elseif has_key(s:decorators, a:deid)
        call s:_f.throw('deiddef', a:deid, a:plugdict.id,
                    \              s:decorators[a:deid].plid)
    elseif type(a:Decorator)!=2
        call s:_f.throw('decnfun', a:deid, a:plugdict.id)
    endif
    "▲3
    let d={}
    let decorator={'id': a:deid,
                \'plid': a:plugdict.id,
                \'pref': printf('v%x_%s', s:lastdeid, a:deid),
                \'func': s:F.refunction(a:plugdict.sid, a:Decorator,
                \                       'deuref', a:deid, a:plugdict.id),}
    let s:lastdeid+=1
    let a:fdict[decorator.id]=decorator
    let s:decorators[decorator.id]=decorator
endfunction
"▶2 deldecorators
function s:F.deldecorators(plugdict, fdict)
    for decorator in values(a:fdict)
        unlet s:decorators[decorator.id]
        unlet a:fdict[decorator.id]
    endfor
endfunction
"▶2 Register feature
call s:_f.newfeature('adddecorator', {'cons': s:F.adddecorator,
            \                       'unload': s:F.deldecorators,})
"▶1 getdecorator
function s:F.getdecorator(id)
    if !has_key(s:decorators, a:id)
        call s:_f.throw('nodec', a:id)
    endif
    return s:decorators[a:id]
endfunction
call s:_f.postresource('getdecorator', s:F.getdecorator)
"▶1
call frawor#Lockvar(s:, 'decorators,lastdeid')
" vim: fmr=▶,▲ sw=4 ts=4 sts=4 et tw=80
