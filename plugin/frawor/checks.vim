"▶1 Header
scriptencoding utf-8
execute frawor#Setup('0.0', {'@/fwc': '0.0',
            \         '@/decorators': '0.0'}, 1)
"▶1 _messages
if v:lang=~?'ru'
    let s:_messages={
                \'uchecker': 'Ошибка создания проверки для дополнения %s: '.
                \            'аргумент, описывающий проверку, '.
                \            'не принадлежит ни к одному из известных типов',
                \'chkncall': 'Ошибка создания проверки для дополнения %s: '.
                \            'проверочная функция не может быть вызвана '.
                \            '(возможно вы использовали ссылку на внутренную '.
                \            'функцию дополнения без раскрытия «s:» '.
                \            'в «<SNR>_{SID}»?)',
                \ 'ufilter': 'Ошибка создания фильтра для дополнения %s: '.
                \            'аргумент, описывающий фильтр, '.
                \            'не принадлежит ни к одному из известных типов',
                \'filncall': 'Ошибка создания фильтра для дополнения %s: '.
                \            'проверочная функция не может быть вызвана '.
                \            '(возможно вы использовали ссылку на внутренную '.
                \            'функцию дополнения без раскрытия «s:» '.
                \            'в «<SNR>_{SID}»?)',
                \'idnotstr': 'Ошибка при обработке запроса на удаление от '.
                \            'дополнения %s: идентификатор не является строкой',
            \}
else
    let s:_messages={
                \'uchecker': 'Error while creating checker for plugin %s: '.
                \            'unknown check description type',
                \'chkncall': 'Error while creating checker for plugin %s: '.
                \            '(perhaps you tried to use a reference to '.
                \            'a script-local function without replacing `s:'' '.
                \            'with `<SNR>_{SID}'')',
                \ 'ufilter': 'Error while creating filter for plugin %s: '.
                \            'unknown filter description type',
                \'filncall': 'Error while creating filter for plugin %s: '.
                \            '(perhaps you tried to use a reference to '.
                \            'a script-local function without replacing `s:'' '.
                \            'with `<SNR>_{SID}'')',
                \'idnotstr': 'Error while processing delete request from '.
                \            'plugin %s: ID is not a string',
            \}
endif
"▶1 freeres      :: {f}
function s:F.freeres(plugdict, fdict)
    call map(a:fdict.FWCids, 's:_f.fwc.del(v:val)')
endfunction
"▶1 conschecker feature
"▶2 conschecker  :: {f}, checker[, gdict] → chkfunc + ?
function s:F.conschecker(plugdict, fdict, Chk, ...)
    if type(a:Chk)==2
        if !exists('*a:Chk')
            call s:_f.throw('chkncall', a:plugdict.id)
        endif
        return a:Chk
    elseif type(a:Chk)==type('')
        let d={}
        let [d.F, id]=s:_f.fwc.compile(a:Chk, 'check',
                    \                  get(a:000, 0, a:plugdict.g))
        call add(a:fdict.FWCids, id)
        return d.F
    else
        call s:_f.throw('uchecker', a:plugdict.id)
    endif
endfunction
"▶2 Register feature
call s:_f.newfeature('conschecker', {'cons': s:F.conschecker,
            \                      'unload': s:F.freeres,
            \                        'init': {'FWCids': []}})
"▶1 consfilter feature
"▶2 consfilter  :: {f}, filter[, gdict] → filfunc + ?
function s:F.consfilter(plugdict, fdict, Fil, ...)
    if type(a:Fil)==2
        if !exists('*a:Fil')
            call s:_f.throw('filncall', a:plugdict.id)
        endif
        return a:Fil
    elseif type(a:Fil)==type('')
        let d={}
        let [d.F, id]=s:_f.fwc.compile(a:Fil, 'filter',
                    \                  get(a:000, 0, a:plugdict.g))
        call add(a:fdict.FWCids, id)
        return d.F
    else
        call s:_f.throw('ufilter', a:plugdict.id)
    endif
endfunction
"▶2 Register feature
call s:_f.newfeature('consfilter', {'cons': s:F.consfilter,
            \                     'unload': s:F.freeres,
            \                       'init': {'FWCids': []}})
"▶1 Decorators: checker and filter
let s:F.de={}
"▶2 checker
function s:F.de.checker(plugdict, fname, Arg)
    let throwargs="'".a:fname."', ".
                \substitute(string(a:plugdict.id), "\n", '''."\\n".''', 'g')
    return [128, '@@@', a:plugdict.g._f.conschecker(a:Arg),
                \['if !@%@(@@@)',
                \     'call s:_f.throw("checkfailed", '.throwargs.')',
                \ 'endif',], [], 0]
endfunction
call s:_f.adddecorator('checker', s:F.de.checker)
"▶2 filter
function s:F.de.filter(plugdict, fname, Arg)
    let throwargs="'".a:fname."', ".
                \substitute(string(a:plugdict.id), "\n", '''."\\n".''', 'g')
    return [64, 'args', a:plugdict.g._f.consfilter(a:Arg),
                \['let args=@%@(@@@)',
                \ 'if type(args)!='.type([]),
                \ '    call s:_f.throw("filterfailed", '.throwargs.')',
                \ 'endif',], [], 0]
endfunction
call s:_f.adddecorator('filter', s:F.de.filter)
"▲2
unlet s:F.de
"▶1
call frawor#Lockvar(s:, 'checkers,filters')
" vim: fmr=▶,▲ sw=4 ts=4 sts=4 et tw=80
