"▶1 Header
scriptencoding utf-8
execute frawor#Setup('0.4', {'@/fwc/compiler': '0.0',
            \                '@/decorators'  : '0.0'}, 1)
"▶1 Define messages
if v:lang=~?'ru'
    let s:_messages=map({
                \     'onstr': 'первый аргумент не является строкой',
                \     'tnstr': 'второй аргумент не является строкой',
                \  'tinvtype': '«%s» не является верным типом функции. '.
                \              'Возможные типы: «check», «filter» и «complete»',
                \    '3ndict': 'третий аргумент не является словарём',
                \}, '"Ошибка создания функции для дополнения %s: ".v:val')
    call extend(s:_messages, map({
                \    'donstr': 'первый аргумент не является строкой',
                \    'dundef': 'неизвестная функция %s',
                \   'dnowner': 'функция %s принадлежит дополнению %s',
                \}, '"Ошибка удаления ресурсов для дополнения %s: ".v:val'))
    call extend(s:_messages, map({
                \'decargnlst': 'настройки декоратора не являются списком',
                \    'largn2': 'в списке должно быть два элемента, а не %u',
                \     '1nstr': 'первый элемент списка не является строкой',
                \   'invtype': 'второй элемент списка должен быть равен '.
                \              '«check» или «filter», а не «%s»',
                \}, '"Ошибка создания функции %s для дополнения %s: ".v:val'))
else
    let s:_messages=map({
                \     'onstr': 'first argument is not a String',
                \     'tnstr': 'second argument is not a String',
                \  'tinvtype': 'expected second argument to be one of '.
                \              '"check", "filter" or "complete", but got "%s"',
                \    '3ndict': 'third argument is not a Dictionary',
                \}, '"Error while compiling function for plugin %s: ".v:val')
    call extend(s:_messages, map({
                \    'donstr': 'first argument is not a String',
                \    'dundef': 'unknown function %s',
                \   'dnowner': 'function %s was compiled for plugin %s',
                \}, '"Error while deleting function resources '.
                \    'for plugin %s: ".v:val'))
    call extend(s:_messages, map({
                \'decargnlst': 'decorator argument is not a List',
                \    'largn2': 'expected two elements in list, but got %u',
                \     '1nstr': 'first element in list is not a String',
                \   'invtype': 'expected second element to be '.
                \              'either "check" or "filter", but got "%s"',
                \}, '"Error while creating function %s for plugin %s: ".v:val'))
endif
"▶1 createvars      :: gdict → id + s:lastid, s:FWCs
function s:F.createvars(gdict)
    return {
                \ 'p': a:gdict,
            \}
endfunction
"▶1 fwc feature
let s:F.fwc={}
"▶2 fwc.compile     :: {f}, FWCstring, type[, gdict] → FWCid, Fref + s:FWCs
let s:lastid=0
let s:FWCs={}
let s:types=['check', 'filter', 'complete']
function s:F.fwc.compile(plugdict, fdict, string, type, ...)
    "▶3 Check arguments
    if type(a:string)!=type('')
        call s:_f.throw('onstr', a:plugdict.id)
    elseif type(a:type)!=type('')
        call s:_f.throw('tnstr', a:plugdict.id)
    elseif index(s:types, a:type)==-1
        call s:_f.throw('tinvtype', a:plugdict.id, a:type)
    elseif a:0 && type(a:1)!=type({})
        call s:_f.throw('3ndict', a:plugdict.id)
    endif
    "▲3
    let d={}
    let id=printf('%s%X', a:type, s:lastid)
    let FWC  =    {'id': id,
                \'plid': a:plugdict.id,
                \'vars': s:F.createvars(get(a:000, 0, a:plugdict.g)),}
    let s:lastid+=1
    call add(a:fdict.ids, id)
    let [opts, lines]=s:_r.fwc_compile(FWC.vars, a:string, a:type, 1)
    if opts.only
        call insert(lines, 'let d={"arg": a:args}')
    elseif has_key(opts, 'requiresd')
        call insert(lines, 'let d={}')
    endif
    execute "function FWC.f(args)\n    ".
                \substitute(substitute(substitute(substitute(
                \join(lines, "\n    "),
                \'@@@', ((opts.only)?('d.arg'):
                \                    ('a:args')), 'g'),
                \'@%@', 's:FWCs.'.id.'.vars',     'g'),
                \'@-@', 'variants',               'g'),
                \'@$@', '',                       'g')."\n".
            \'endfunction'
    let s:FWCs[id]=FWC
    return [FWC.f, id]
endfunction
"▶2 fwc.del         :: {f}, FWCid
function s:F.fwc.del(plugdict, fdict, FWCid)
    "▶3 Check arguments
    if type(a:FWCid)!=type('')
        call s:_f.throw('donstr', a:plugdict.id)
    elseif !has_key(s:FWCs, a:FWCid)
        call s:_f.throw('dundef', a:plugdict.id, a:FWCid)
    elseif s:FWCs[a:FWCid].plid isnot a:plugdict.id
        call s:_f.throw('dnowner', a:plugdict.id, a:FWCid, s:FWCs[a:FWCid].plid)
    endif
    "▲3
    call filter(a:fdict.ids, 'v:val isnot a:FWCid')
    unlet s:FWCs[a:FWCid]
endfunction
"▶2 delids          :: {f}
function s:F.delids(plugdict, fdict)
    call map(a:fdict.ids, 'remove(s:FWCs, v:val)')
endfunction
"▶2 Register feature
call s:_f.newfeature('fwc', {'cons': s:F.fwc,
            \              'unload': s:F.delids,
            \                'init': {'ids': []}})
"▶1 makedec         :: plugdict, fname, arg
function s:F.makedec(plugdict, fname, arg)
    "▶2 Check arguments
    if type(a:arg)!=type([])
        call s:_f.throw('decargnstr', a:fname, a:plugdict.id)
    elseif len(a:arg)!=2
        call s:_f.throw('largn2', a:fname, a:plugdict.id, len(a:arg))
    elseif type(a:arg[0])!=type('')
        call s:_f.throw('1nstr', a:fname, a:plugdict.id)
    elseif index(['check', 'filter'], a:arg[1])==-1
        call s:_f.throw('invtype', a:fname, a:plugdict.id, string(a:arg[1]))
    endif
    "▲2
    let vars=s:F.createvars(a:plugdict.g)
    let a=['FWCfail', a:fname, a:plugdict.id]
    let [opts, lines]=s:_r.fwc_compile(vars, a:arg[0], a:arg[1], a)
    let rearg=(opts.only || a:arg[1] is# 'filter')
    if rearg
        call map(lines, 'substitute(v:val, "@@@", "@$@d.args", "g")')
        call insert(lines, 'let @$@d={"args": copy(@@@)}')
    elseif has_key(opts, 'requiresd')
        call insert(lines, 'let @$@d={}')
    endif
    return [128, ((rearg)?('@$@d.args'):('@@@')), vars, lines, [], 0]
endfunction
"▶1 Register decorator
call s:_f.adddecorator('FWC', s:F.makedec)
"▶1
call frawor#Lockvar(s:, 'lastid,FWCs')
" vim: fmr=▶,▲ sw=4 ts=4 sts=4 et tw=80
