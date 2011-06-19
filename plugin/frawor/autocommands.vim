"▶1 Header
scriptencoding utf-8
execute frawor#Setup('0.0', {}, 1)
"▶1 Define messages
if v:lang=~?'ru'
    let s:_messages={
                \   'agidnstr': 'Ошибка создания группы событий '.
                \               'для дополнения %s: название группы '.
                \               'не является строкой',
                \    'invagid': 'Ошибка создания группы событий '.
                \               'для дополнения %s: строка «%s» не может '.
                \               'являться названием группы',
                \   'loadfail': 'Не удалось загрузить дополнение %s',
                \  'dagidnstr': 'Ошибка удаления группы событий '.
                \               'для дополнения %s: название группы '.
                \               'не является строкой',
                \    'uknagid': 'Группа событий «%s» не определена или '.
                \               'определена не дополнением %s',
            \}
    call extend(s:_messages, map({
                \    'agiddef': 'группа уже определена дополнением %s',
                \    'agenlst': 'список событий не является списком',
                \   'noevents': 'отсутствуют события в списке',
                \      'enlst': 'одно из событий не является списком',
                \     'en3lst': 'одно из событий содержит не три элемента',
            \},'"Ошибка создания группы событий %s для дополнения %s: ".v:val'))
    call extend(s:_messages, map({
                \ 'etypenslst': 'тип события не является строкой или списком',
                \  'invetypes': 'часть типов событий не верна',
                \    'ptrnstr': 'шаблон не является строкой',
                \  'nestnbool': 'третий элемент не является единицей или нулём',
                \   'emptycmd': 'список аргументов пуст',
                \ 'nowrapfunc': 'отсутствует функция _f.wrapfunc '.
                \               '(дополнение должно зависеть от '.
                \                'plugin/frawor/functions)',
                \     'ukncmd': 'не удалось обработать команду',
            \},'"Ошибка создания события №%u группы событий %s '.
            \   'для дополнения %s: ".v:val'))
else
    let s:_messages={
                \   'agidnstr': 'Error while creating augroup for plugin %s: '.
                \               'group ID is not a String',
                \    'invagid': 'Error while creating augroup for plugin %s: '.
                \               'string `%s'' is not a valid group ID',
                \   'loadfail': 'Failed to load plugin %s',
                \  'dagidnstr': 'Error while deleting augroup for plugin %s: '.
                \               'group ID is not a String',
                \    'uknagid': 'Augroup `%s'' is either undefined or '.
                \               'defined not by plugin %s',
            \}
    call extend(s:_messages, map({
                \    'agiddef': 'group was already defined by plugin %s',
                \    'agenlst': 'event list is not a List',
                \   'noevents': 'no events in list',
                \      'enlst': 'one of events is not a List',
                \     'en3lst': 'one of events contains not 3 elements',
            \}, '"Error while creating augroup %s for plugin %s: ".v:val'))
    call extend(s:_messages, map({
                \ 'etypenslst': 'event type is neither String nor List',
                \  'invetypes': 'some event types are not valid',
                \    'ptrnstr': 'event pattern is not a String',
                \  'nestnbool': 'third list element is neither 0 nor 1',
                \   'emptycmd': 'arguments list is empty',
                \ 'nowrapfunc': 'function _f.wrapfunc is absent '.
                \               '(plugin must depend on '.
                \                'plugin/frawor/functions)',
                \     'ukncmd': 'failed to process command',
            \}, '"Error while processing event #%u for augroup %s '.
            \    'defined by plugin %s: ".v:val'))
endif
"▶1 wipeau       :: agname → + :autocmd
function s:F.wipeau(agname)
    execute 'augroup' a:agname
        autocmd!
    augroup END
    execute 'augroup!' a:agname
endfunction
"▶1 add_augroups :: {f} → + p:_augroups
function s:F.add_augroups(plugdict, fdict)
    if !has_key(a:plugdict.g, '_augroups') ||
                \type(a:plugdict.g._augroups)!=type([])
        let a:plugdict.g._augroups=[]
    endif
endfunction
"▶1 delaugroups  :: {f} + p:_augroups → + :autocmd, p:_augroups
function s:F.delaugroups(plugdict, fdict)
    if !has_key(a:plugdict.g, '_augroups') ||
                \type(a:plugdict.g._augroups)!=type([])
        return
    endif
    let d={}
    while !empty(a:plugdict.g._augroups)
        let d.agname=remove(a:plugdict.g._augroups, 0)
        if type(d.agname)==type('') && stridx(d.agname, '#')==-1 &&
                    \exists('#'.d.agname)
            call s:F.wipeau(d.agname)
        endif
    endwhile
endfunction
call s:_f.newfeature('delaugroups', {'unloadpre': s:F.delaugroups,
            \                         'register': s:F.add_augroups,
            \                       'ignoredeps': 1})
"▶1 augroup feature
let s:F.augroup={}
let s:augroups={}
"▶2 aurun        :: agid, eidx → + ?
function s:F.aurun(agid, eidx)
    let augroup=s:augroups[a:agid]
    let args=get(augroup.args, a:eidx, [])
    if type(augroup.funcs[a:eidx])==type({})
        if !FraworLoad(augroup.plid)
            call s:_f.throw('loadfail', augroup.plid)
        endif
        let augroup.funcs[a:eidx]=augroup.wrapfunc(augroup.funcs[a:eidx])
    endif
    return call(augroup.funcs[a:eidx], args, {})
endfunction
"▶2 createau     :: augroup → + :autocmd
function s:F.createau(augroup)
    execute 'augroup' a:augroup.agname
        autocmd!
        for auargs in a:augroup.events
            execute 'autocmd' auargs
        endfor
    augroup END
endfunction
"▶2 augroup.del  :: {f}[, agid] → + :autocmd
function s:F.augroup.del(plugdict, fdict, ...)
    if a:0
        if type(a:1)!=type('')
            call s:_f.throw('dagidnstr', a:plugdict.id)
        elseif !has_key(a:fdict, a:1)
            call s:_f.throw('uknagid', a:1, a:plugdict.id)
        endif
        call s:F.wipeau(a:fdict[a:1].agname)
        unlet a:fdict[a:1]
        unlet s:augroups[a:1]
    else
        call map(values(a:fdict), 's:F.wipeau(v:val.agname)')
        call map(keys(a:fdict), 'remove(s:augroups, v:val)')
    endif
endfunction
"▶2 augroup.add  :: {f}, agid, [event] → + :autocmd, s:augroups
function s:F.augroup.add(plugdict, fdict, agid, events)
    "▶3 Check arguments
    if type(a:agid)!=type('')
        call s:_f.throw('agidnstr', a:plugdict.id)
    elseif a:agid!~#'^\w\+$'
        call s:_f.throw('invagid', a:plugdict.id, a:agid)
    elseif has_key(s:augroups,a:agid) && s:augroups[a:agid].plid isnot# a:plugdict.id
        call s:_f.throw('agiddef', a:agid,a:plugdict.id,s:augroups[a:agid].plid)
    elseif type(a:events)!=type([])
        call s:_f.throw('agenlst', a:agid, a:plugdict.id)
    elseif empty(a:events)
        call s:_f.throw('noevents', a:agid, a:plugdict.id)
    elseif !empty(filter(copy(a:events), 'type(v:val)!='.type([])))
        call s:_f.throw('enlst', a:agid, a:plugdict.id)
    elseif !empty(filter(copy(a:events), 'len(v:val)!=4'))
        call s:_f.throw('en3lst', a:agid, a:plugdict.id)
    endif
    "▲3
    if has_key(s:augroups, a:agid)
        let augroup=s:augroups[a:agid]
    else
        let augroup   =   {'id': a:agid,
                    \    'plid': a:plugdict.id,
                    \  'agname': 'FraworAugroup_'.a:agid,
                    \  'events': [],
                    \   'funcs': {},
                    \    'args': {}}
    endif
    let i=len(augroup.events)
    let d={}
    for [d.event, d.pattern, d.nested, d.command] in a:events
        let epc=[]
        if type(d.event)==type('')
            call add(epc, split(d.event, ','))
        elseif type(d.event)==type([])
            call add(epc, d.event)
        "▶3 Invalid event types
        else
            call s:_f.throw('etypenslst', i, a:agid, a:plugdict.id)
        endif
        if !empty(filter(copy(epc[0]), 'type(v:val)!='.type('').' || '.
                    \                  'v:val=~#"\\_[^a-zA-Z]" || '.
                    \                  '!exists("##".v:val)'))
            call s:_f.throw('invetypes', i, a:agid, a:plugdict.id)
        endif
        "▲3
        let epc[0]=join(epc[0], ',')
        "▶3 Check pattern
        if type(d.pattern)!=type('')
            call s:_f.throw('ptrnstr', i, a:agid, a:plugdict.id)
        endif
        "▲3
        call add(epc, escape(d.pattern, ' '))
        "▶3 Check nested
        if d.nested isnot 0 && d.nested isnot 1
            call s:_f.throw('nestnbool', i, a:agid, a:plugidct.id)
        endif
        "▲3
        if d.nested
            call add(epc, 'nested')
        endif
        if type(d.command)==type([])
            "▶3 Check d.command
            if empty(d.command)
                call s:_f.throw('emptycmd', i, a:agid, a:plugdict.id)
            endif
            "▲3
            let [d.command; augroup.args[i]]=d.command
        endif
        if exists('*d.command')
            let augroup.funcs[i]=d.command
            if has_key(augroup.args, i) && !empty(augroup.args[i])
                let epc+=['call call(s:augroups.'.a:agid.'.funcs.'.i.', '.
                            \       's:augroups.'.a:agid.'.args.'.i.', {})']
            else
                let epc+=['call s:augroups.'.a:agid.'.funcs.'.i.'()']
            endif
        elseif type(d.command)==type({})
            "▶3 Check for wrapfunc
            if !exists('*a:plugdict.g._f.wrapfunc')
                call s:_f.throw('nowrapfunc', i, a:agid, a:plugdict.id)
            endif
            "▲3
            let augroup.wrapfunc=a:plugdict.g._f.wrapfunc
            let augroup.funcs[i]=d.command
            let epc+=['call s:F.aurun('.string(a:agid).', '.i.')']
        elseif !has_key(augroup.args, i) && type(d.command)==type('')
            call add(epc, substitute(d.command, '<SID>',
                        \            '<SNR>'.a:plugdict.sid.'_', 'g'))
        "▶3 Unknown d.command
        else
            call s:_f.throw('ukncmd', i, a:agid, a:plugdict.id)
        endif
        "▲3
        call add(augroup.events, join(epc))
        let i+=1
        unlet d.event d.pattern d.command
    endfor
    let s:augroups[augroup.id]=augroup
    let a:fdict[augroup.id]=augroup
    call s:F.createau(augroup)
endfunction
"▶2 Define feature
call s:_f.newfeature('augroup', {'cons': s:F.augroup,
            \                  'unload': s:F.augroup.del,})
"▶1
call frawor#Lockvar(s:, 'augroups')
" vim: fmr=▶,▲ sw=4 ts=4 sts=4 et tw=80
