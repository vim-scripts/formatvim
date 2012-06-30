"▶1 Header
scriptencoding utf-8
execute frawor#Setup('0.1', {'plugin/frawor/options': '0.0',
            \           'plugin/frawor/autocommands': '0.0',
            \              'plugin/frawor/resources': '0.0',}, 1)
"▶1 Define variables
let s:_oprefix='frawormap'
let s:_options={}
let s:ablhsreg='\v^%(\k+|%(\k@!.)+\k|\S*\k@!.)$'
"▶1 Define messages
if v:lang=~?'ru'
    let s:_messages={
                \ '_mgp_pref': 'Ошибка создания привязки %s '.
                \              'для группы %s, определённой в дополнении %s: ',
                \'mgidnotstr': 'Ошибка создания группы привязок '.
                \              'для дополнения %s: название группы '.
                \              'не является строкой',
                \   'invmgid': 'Ошибка создания группы привязок '.
                \              'для дополнения %s: строка «%s» не может '.
                \              'являться названием группы',
                \  'olhsnstr': 'Левая часть привязки не является строкой',
                \    'onolhs': 'Список левых частей привязки пуст',
                \  'loadfail': 'Ошибка при запуске привязки %s из группы %s: '.
                \              'не удалось загрузить дополнение %s',
                \   'strfail': 'Не удалось получить строку от пользователя',
                \'mmmgidnstr': 'Ошибка создания привязок группы '.
                \              'для дополнения %s: название группы '.
                \              'не является строкой',
                \'ummgidnstr': 'Ошибка удаления привязок группы '.
                \              'для дополнения %s: название группы '.
                \              'не является строкой',
                \'dmmgidnstr': 'Ошибка удаления группы дополнения %s: '.
                \              'название группы не является строкой',
            \}
    call extend(s:_messages, map({
                \   'mgiddef': 'группа уже определена дополнением %s',
                \  'mapsndct': 'описание привязок не является словарём',
                \ 'mapsempty': 'отсутствует описание привязок',
                \'mgoptsndct': 'настройки группы не являются словарём',
                \ 'mleadnstr': 'приставка группы привязок не является строкой',
                \'invmapname': 'строка «%s» не может являться именем привязки',
                \'mgmodenstr': 'режим по умолчанию не является строкой',
                \'mgtypenstr': 'тип по умолчанию не является строкой',
                \   'gdnbool': 'ключ «%s» не является нулём или единицей',
            \},
            \'"Ошибка создания группы привязок %s для дополнения %s: ".v:val'))
    call extend(s:_messages, map({
                \'mdescrndct': 'описание привязки не является словарём',
                \   'lhsnstr': 'левая часть привязки не является строкой',
                \ 'mtypenstr': 'тип привязки не является строкой',
                \  'invmtype': 'неизвестный тип привязки: %s',
                \'invabbrlhs': 'строка «%s» не может являться аббревиатурой',
                \   'mdnbool': 'ключ «%s» описания привязки не 0 или 1',
                \ 'mmodenstr': 'режим привязки не является строкой',
                \   'invmode': 'строка «%s» не может описывать режим привязки',
                \   'tipnstr': 'подсказка не является строкой',
                \    'nofunc': 'ключ «func» отсутствует или не содержит '.
                \              'ссылку на функцию',
                \'nowrapfunc': 'отсутствует функция _f.wrapfunc '.
                \              '(дополнение должно зависеть от '.
                \               'plugin/frawor/functions)',
                \   'invargs': 'значение ключа «args» должно быть списком',
                \    'invrhs': 'не удалось обработать правую часть привязки',
                \   'rhsndef': 'ключ «rhs» не определён',
                \    'middef': 'привязка с данным именем уже определена',
                \ 'strfncall': 'неизвестная функция в значении ключа «strfunc»',
                \    'fncall': 'неизвестная функция в значении ключа «func»',
                \     'ncall': 'неизвестная функция в значении ключа «func»',
                \    'mapcol': 'левая часть («%s») данной привязки совпадает '.
                \              'с левой частью привязки %s группы %s, '.
                \              'определённой в дополнении %s',
            \},
            \'s:_messages._mgp_pref.v:val'))
    call extend(s:_messages, map({
                \  'mmnomgid': 'группа не существует',
                \ 'mmnounrel': 'дополнение %s, определившее группу, не входит '.
                \              'в список зависимостей',
                \  'mminvbuf': 'дополнительный аргумент неверен',
            \},
            \'"Ошибка создания привязок группы %s для дополнения %s: ".v:val'))
    call extend(s:_messages, map({
                \  'umnomgid': 'группа не существует',
                \ 'umnounrel': 'дополнение %s, определившее группу, не входит '.
                \              'в список зависимостей',
                \  'uminvbuf': 'дополнительный аргумент неверен',
            \},
            \'"Ошибка удаления привязок группы %s для дополнения %s: ".v:val'))
    call extend(s:_messages, map({
                \  'dmnomgid': 'группа не существует',
                \   'dmnself': 'нельзя удалить группу, определённую '.
                \              'дополнением %s',
            \},
            \'"Ошибка удаления группы %s дополнения %s: ".v:val'))
    unlet s:_messages._mgp_pref
else
    let s:_messages={
                \ '_mgp_pref': 'Error while creating mapping %s in group %s '.
                \              'defined by plugin %s: ',
                \'mgidnotstr': 'Error while creating group of mappings '.
                \              'for plugin %s: group id is not a String',
                \   'invmgid': 'Error while creating group of mappings '.
                \              'for plugin %s: `%s'' is not a valid group id',
                \  'olhsnstr': '{lhs} of the mapping is not a String',
                \    'onolhs': 'No {lhs} specified in a list',
                \  'loadfail': 'Error while running mapping %s from group %s: '.
                \              'loading plugin %s failed',
                \   'strfail': 'Failed to get additional string from a user',
                \'mmmgidnstr': 'Error while mapping a mgroup '.
                \              'for plugin %s: group id is not a String',
                \'ummgidnstr': 'Error while unmapping a mgroup '.
                \              'for plugin %s: group id is not a String',
                \'dmmgidnstr': 'Error while deleting a mgroup '.
                \              'for plugin %s: group id is not a String',
            \}
    call extend(s:_messages, map({
                \   'mgiddef': 'group was already defined by plugin %s',
                \  'mapsndct': 'mappings description is not a dictionary',
                \ 'mapsempty': 'no mappings specified',
                \'mgoptsndct': 'mapping group options are not a dictionary',
                \ 'mleadnstr': 'mapping group leader is not a String',
                \'invmapname': 'string `%s'' is not a valid mapping name',
                \'mgmodenstr': 'group default mapping mode is not a String',
                \'mgtypenstr': 'group default mapping type is not a String',
                \   'gdnbool': '`%s'' group options key is neither 1 nor 0',
            \},
            \'"Error while creating mapping group %s for plugin %s: ".v:val'))
    call extend(s:_messages, map({
                \'mdescrndct': 'mapping description is not a Dictionary',
                \   'mdnbool': 'key `%s'' of mapping description is not a Bool',
                \   'lhsnstr': '{lhs} of the mapping is not a String',
                \ 'mtypenstr': 'mapping type is not a String',
                \  'invmtype': 'unknown mapping type: %s',
                \'invabbrlhs': 'string `%s'' cannot be an abbreviation',
                \ 'mmodenstr': 'mapping mode is not a String',
                \   'invmode': 'string `%s'' is not a valid mode description',
                \   'tipnstr': 'menu tip is not a String',
                \    'nofunc': 'key `func'' is either absent or does not hold '.
                \              'a callable function reference',
                \'nowrapfunc': 'function _f.wrapfunc is absent (plugin '.
                \              'must depend on plugin/frawor/functions)',
                \   'invargs': '`args'' key must be a List',
                \    'invrhs': 'unable to process given {rhs}',
                \   'rhsndef': '`rhs'' key is not defined',
                \    'middef': 'mapping with such name was already defined',
                \ 'strfncall': '`strfunc'' key contains unknown function',
                \    'fncall': '`func'' key contains unknown function',
                \     'ncall': '`func'' key contains unknown function',
                \    'mapcol': '{lhs} (`%s'') of the mapping is just the same '.
                \              'as {lhs} of mapping %s from group %s '.
                \              'defined by plugin %s',
            \},
            \'s:_messages._mgp_pref.v:val'))
    call extend(s:_messages, map({
                \  'mmnomgid': 'group does not exist',
                \ 'mmnounrel': 'plugin %s that defined this group is not '.
                \              'in dependency list',
                \  'mminvbuf': 'additional argument is invalid',
            \},
            \'"Error while mapping mgroup %s for plugin %s: ".v:val'))
    call extend(s:_messages, map({
                \  'umnomgid': 'group does not exist',
                \ 'umnounrel': 'plugin %s that defined this group is not '.
                \              'in dependency list',
                \  'uminvbuf': 'additional argument is invalid',
            \},
            \'"Error while unmapping mgroup %s for plugin %s: ".v:val'))
    call extend(s:_messages, map({
                \  'dmnomgid': 'group does not exist',
                \   'dmnself': 'cannot delete group defined by %s',
            \},
            \'"Error while deleting mgroup %s for plugin %s: ".v:val'))
    unlet s:_messages._mgp_pref
endif
"▶1 savemap       :: lhs, mode, abbr → Maybe mapdescr
"▶2 savemap for newer vim
if (v:version==703 && has('patch32')) || v:version>703
    function s:F.savemap(lhs, mode, abbr)
        let map=maparg(a:lhs, a:mode, a:abbr, 1)
        if !empty(map)
            let map.type=((a:abbr)?('abbr'):('map'))
            if map.buffer
                let map.buffer=bufnr('%')
            endif
            return map
        endif
        return 0 " Explicitely return 0 if mapping does not exist
    endfunction
"▶2 savemap for <vim-7.3.32
else
    " maparg(lhs, mode, abbr, dict) emulation for older vim. Limitations:
    " 1. Cannot differentiate between <expr> and other mappings
    " 2. Cannot differentiate between <CR> and <LT>CR>
    " 3. Cannot restore <silent> flag
    function s:F.savemap(lhs, mode, abbr)
        if a:mode is 0
            let mode=' '
        else
            let mode=a:mode
        endif
        let type=((a:abbr)?('abbr'):('map'))
        let modes=s:F.modrewrite(mode, type)
        let rhs=maparg(a:lhs, mode, a:abbr)
        if len(modes)>1
            let om=0
            for m in modes
                if maparg(a:lhs, m, a:abbr) is# rhs
                    if om is 0
                        let om=m
                    endif
                else
                    let mode=om
                    break
                endif
            endfor
        endif
        if empty(rhs)
            let rhs='<Nop>'
        endif
        let cmd=type
        redir => mapoutput
        silent! execute mode.cmd substitute(a:lhs, ' ', '<Space>', 'g')
        redir END
        let maplines=split(mapoutput, "\n")
        let noremap=0
        let buffer=0
        let lrhs=len(rhs)
        call filter(maplines, 'v:val[-'.lrhs.':] is# rhs')
        if empty(maplines)
            if rhs is# '<Nop>'
                return 0
            endif
        else
            let noremap=(maplines[0][(-lrhs-2):][0] is# '*')
            let buffer=(maplines[0][(-lrhs-1):][0] is# '@')
        endif
        if buffer
            let buffer=bufnr('%')
        endif
        return      {    'lhs': a:lhs,
                    \    'rhs': rhs,
                    \ 'silent': 0,
                    \'noremap': noremap,
                    \   'expr': 0,
                    \ 'buffer': buffer,
                    \   'mode': mode,
                    \    'sid': 0,
                    \   'type': type,}
    endfunction
endif
"▶1 hsescape      :: String, sid[, a:1::Bool] → String
function s:F.hsescape(str, sid, ...)
    if a:0 && a:1 is# 'menu'
        return a:str
    endif
    return substitute(substitute(substitute(substitute(substitute(a:str,
                \      ' ', '<Space>',         'g'),
                \      '|', '<Bar>',           'g'),
                \'\c<SID>', '<SNR>'.a:sid.'_', 'g'),
                \     "\n", '<CR>',            'g'),
                \'\c^<\%(buffer\|silent\|expr\|special\)\@=', '<LT>', '')
endfunction
"▶1 modrewrite    :: mode, type → [mode]
function s:F.modrewrite(mode, type)
    if a:type is# 'abbr'
        return split(substitute(a:mode, ' ', 'ci', ''), '\v.@=')
    else
        return split(substitute(substitute(substitute(a:mode,
                    \' ', 'nxso', ''),
                    \'!', 'ic',   ''),
                    \'v', 'xs',   ''),
                    \'\v.@=')
    endif
endfunction
"▶1 map           :: mapdescr → + :map
function s:F.map(mapdescr)
    let modes=s:F.modrewrite(a:mapdescr.mode, a:mapdescr.type)
    let lhs=s:F.hsescape(a:mapdescr.lhs, a:mapdescr.sid, a:mapdescr.type)
    for mode in modes
        if a:mapdescr.expr>1
            let rhs=printf(a:mapdescr.rhs, '"'.mode.'","'.escape(lhs, '"\').'"')
        else
            let rhs=s:F.hsescape(a:mapdescr.rhs, a:mapdescr.sid)
        endif
        execute mode.((a:mapdescr.noremap)?('nore'):('')).(a:mapdescr.type)
                    \ ((a:mapdescr.silent)?('<silent>'):(''))
                    \ '<special>'
                    \ ((a:mapdescr.buffer)?('<buffer>'):(''))
                    \ ((a:mapdescr.expr)?('<expr>'):(''))
                    \ lhs rhs
        if a:mapdescr.type is# 'menu' && has_key(a:mapdescr, 'tip')
            " Deletes text that appears on the right as it is not accepted by 
            " tmenu
            let lhs=substitute(lhs, '\v%(\\@<!\\%(\\\\)*)@<!\c\<Tab\>.*$','','')
            execute 'tmenu' lhs a:mapdescr.tip
        endif
    endfor
endfunction
"▶1 unmap         :: mapdescr → + :unmap
function s:F.unmap(mapdescr)
    let modes=s:F.modrewrite(a:mapdescr.mode, a:mapdescr.type)
    let lhs=s:F.hsescape(a:mapdescr.lhs, a:mapdescr.sid, a:mapdescr.type)
    let r=1
    for mode in modes
        try
            execute mode.'un'.(a:mapdescr.type)
                        \ '<special>'
                        \ ((a:mapdescr.buffer)?('<buffer>'):(''))
                        \ lhs
        catch /\v^Vim\(\l?un\w+\)\:E(24|31|329):/
            let r=0
        endtry
    endfor
    return r
endfunction
"▶1 lhsfilter     :: Either lhs [lhs] → [lhs]
function s:F.lhsfilter(llhs)
    if type(a:llhs[0])==type([])
        let lhss=a:llhs[0]
    else
        let lhss=[a:llhs[0]]
    endif
    if empty(lhss)
        call s:_f.warn('onolhs')
        return 0
    endif
    for lhs in lhss
        if lhs isnot 0 && type(lhs)!=type('')
            call s:_f.warn('olhsnstr')
            return 0
        endif
    endfor
    return [lhss]
endfunction
"▶1 leadchecker   :: leader → Bool
function s:F.leadchecker(leader)
    return (type(a:leader[0])==type('') || a:leader[0] is 0)
endfunction
"▶1 mapmgroup     :: mgroup, mlist, a:0::Bool → + s:mapped, s:bufmapped, :map
let s:mapped={}
let s:bufmapped={}
function s:F.mapmgroup(mgroup, mlist, ...)
    "▶2 Define buf and mdict
    if a:0
        let buf=bufnr('%')
        if !has_key(s:bufmapped, buf)
            let s:bufmapped[buf]={}
        endif
        let mdict=s:bufmapped[buf]
    else
        let buf=0
        let mdict=s:mapped
    endif
    "▶2 Define leader
    if a:mgroup.nouser
        let leader=a:mgroup.leader
    else
        let leader=s:_f.getoption(a:mgroup.id)
    endif
    "▲2
    if leader is 0
        return
    endif
    for mid in ((a:mlist is 0)?(keys(a:mgroup.maps)):(a:mlist))
        let map=a:mgroup.maps[mid]
        "▶2 Get {lhs}s
        if a:mgroup.nouser
            let lhss=[map.lhs]
        else
            let lhss=s:_f.getoption(a:mgroup.id.'_'.(map.id), (a:0? 'bg' : 'g'))
            if empty(lhss)
                let lhss=[map.lhs]
            endif
        endif
        "▲2
        if index(lhss, 0)!=-1
            continue
        endif
        call filter(map(lhss, 'leader.v:val'), '!empty(v:val)')
        "▶2 Check for invalid lhs suffixes in an abbreviations
        if (map.type) is# 'abbr'
            let invlhss=filter(copy(lhss), 'v:val!~#s:ablhsreg')
            if !empty(invlhss)
                call s:_f.throw('invabbrlhs', (map.id), a:mgroup.id,
                            \                 a:mgroup.plid, invlhss[0])
            endif
        endif
        "▲2
        for lhs in lhss
            for mode in s:F.modrewrite(map.mode, map.type)
                let didess=(map.type[0]).(mode).':'.lhs
                let mdid=(buf).didess
                if buf && has_key(map.mapped, '0'.didess)
                    continue
                elseif has_key(mdict, mdid)
                    " XXX it is workaround for the problem which occures if both 
                    " FileType and BufEnter events are called.
                    if mdict[mdid].mgid is# a:mgroup.id && mdict[mdid].id is# map.id
                        continue
                    endif
                    call s:_f.warn('mapcol', (map.id), a:mgroup.id,
                                \            a:mgroup.plid, lhs, mdict[mdid].id,
                                \            mdict[mdid].mgid,
                                \         s:mgroups[mdict[mdid].mgid].plid)
                    unlet s:mgroups[mdict[mdid].mgid]
                                \.maps[mdict[mdid].id]
                                \.mapped[mdid]
                    unlet mdict[mdid]
                endif
                let mapdescr=copy(map)
                let mapdescr.mode=mode
                let mapdescr.lhs=lhs
                let mapdescr.buffer=buf
                let mapdescr.mdid=mdid
                unlet mapdescr.mapped
                call s:F.map(mapdescr)
                let mdict[mdid]=mapdescr
                let map.mapped[mdid]=mapdescr
            endfor
        endfor
    endfor
endfunction
"▶1 unmapmgroup   :: mgroup, a:0::Bool → + s:[buf]mapped, :unmap
function s:F.unmapmgroup(mgroup, ...)
    let maps=values(a:mgroup.maps)
    if a:0
        let buf=bufnr('%')
        let mdict=s:bufmapped[buf]
    else
        call filter(maps, '!v:val.buffer')
        let mdict=s:mapped
    endif
    for map in maps
        for [mdid, mapdescr] in filter(items(map.mapped),
                    \                  ((a:0)?('v:val[1].buffer is '.buf):
                    \                         ('!v:val[1].buffer')))
            unlet mdict[mdid]
            unlet map.mapped[mdid]
            call s:F.unmap(mapdescr)
        endfor
    endfor
endfunction
"▶1 delmgroup     :: mgroup → + s:_options, s:mgroups
function s:F.delmgroup(mgroup)
    call s:F.unmapmgroup(a:mgroup)
    call s:F.unmapmgroup(a:mgroup, 1)
    for buf in filter(range(1, bufnr('$')), 'v:val!='.bufnr('%'))
        let s:deletedgroups[buf]=add(get(s:deletedgroups, buf, []), a:mgroup)
    endfor
    if !a:mgroup.nouser
        for map in values(a:mgroup.maps)
            unlet s:_options[(a:mgroup.id).'_'.(map.id)]
        endfor
        unlet s:_options[a:mgroup.id]
    endif
    unlet s:mgroups[a:mgroup.id]
    if has_key(a:mgroup, 'filetype')
        unlet s:fts[a:mgroup.filetype][a:mgroup.id]
    endif
endfunction
"▶1 strfunc       :: key → (-1|3, 0, 0)
function s:F.strfunc(key)
    if key is# "\<CR>" || key is# "\n"
        return [-1, 0, 0]
    endif
    return [3, 0, 0]
endfunction
"▶1 runfeed       :: + s:keystofeed → String + s:keystofeed
function s:F.runfeed()
    if exists('s:keystofeed')
        let r=s:keystofeed
        unlet s:keystofeed
        return r
    endif
    return ''
endfunction
"▶1 feedfunc      :: [key] → + s:keystofeed
function s:F.feedfunc(keys)
    let s:keystofeed=join(a:keys, '')
endfunction
"▶1 maprun        :: mgid, mapname, mode, lhs → <expr> + ?
let s:mapreplaces={'%lhs': 'a:lhs',
            \     '%mode': 'a:mode',
            \      '%str': 's:F.getstr(get(map, "strfunc", s:F.strfunc), '.
            \                         's:F.feedfunc)',
            \     '%mgid': 'a:mgid',
            \    '%mname': 'a:mapname',}
let s:replaceexpr='type(v:val)=='.type('').' && has_key(s:mapreplaces, v:val)?'.
            \           'eval(s:mapreplaces[v:val]):'.
            \           'v:val'
let s:modeopsuf={'i': "\<C-o>",
            \    'c': "\e",
            \    'o': "\e",
            \    'n': "",
            \    'x': "",
            \    's': "\<C-o>",
            \    'l': "\<C-o>",}
function s:F.maprun(mgid, mapname, mode, lhs, ...)
    let mgroup=s:mgroups[a:mgid]
    let map=mgroup.maps[a:mapname]
    if !a:0 && map.operator
        let &l:operatorfunc='<SNR>'.s:_sid.'_opfunc'
        let s:mrargs=[a:mgid, a:mapname, a:mode, a:lhs]
        return s:modeopsuf[a:mode].'g@'
    endif
    if !has_key(map, 'loaded')
        if !has_key(mgroup, 'plloaded')
            if !FraworLoad(mgroup.plid)
                call s:_f.throw('loadfail', a:mapname, a:mgid, mgroup.plid)
            endif
            if has_key(mgroup, 'func') && type(mgroup.func)==type({})
                let mgroup.func=call(mgroup.wrapfunc, [mgroup.func], {})
            endif
            let mgroup.plloaded=1
        endif
        for key in filter(['strfunc', 'func'], 'has_key(map, v:val) && '.
                    \                          'type(map[v:val])=='.type({}))
            let map[key]=call(mgroup.wrapfunc, [map[key]], {})
        endfor
        let map.loaded=1
    endif
    let d={'func': (has_key(map, 'func')?(map.func):(mgroup.func))}
    if (map.expr==2)
        return call(d.func, a:000+(has_key(map, 'strfunc')?
                    \                   [s:F.getstr(map.strfunc, s:F.feedfunc)]:
                    \                   []), {})
    elseif (map.expr==3)
        return call(d.func, a:000+map(copy(map.args), s:replaceexpr), {})
    endif
endfunction
"▶1 opfunc        :: mtype → <expr> + ?
function s:opfunc(mtype)
    let mrargs=s:mrargs
    unlet s:mrargs
    call add(mrargs, a:mtype)
    if mrargs[2] is# 'x' || mrargs[2] is# 's'
        call add(mrargs, getpos("'<"))
        call add(mrargs, getpos("'>"))
    else
        call add(mrargs, getpos("'["))
        call add(mrargs, getpos("']"))
    endif
    call call(s:F.maprun, mrargs, {})
endfunction
let s:_functions+=['s:opfunc']
"▶1 getchar       :: + {input} → String
function s:F.getchar()
    let r=getchar()
    return ((type(r)==type(0))?(nr2char(r)):(r))
endfunction
"▶1 getstr        :: strfunc[, feedfunc] → Either String (String, retvalue) + ?
function s:F.getstr(Strfunc, ...)
    "▶2 define variables
    "▶3 time and timeout
    if &timeout && has('float') && has('reltime')
        let timeout=&timeoutlen/1000.0
        let time=reltime()
    endif
    "▲3
    let chars=[]     " :: [char]
    let args=[]      " (char) or (char, addarg)
    let laststatus=1
    let r=[0, '', 0] " next character index, {gotstring}, {retvalue}
    "▲2
    while ((exists('timeout'))?((eval(reltimestr(reltime(time))))<timeout):(1))
        if getchar(1) || laststatus==1
            let char=s:F.getchar()
            call add(chars, char)
            call insert(args, char)
            let [laststatus, retvalue, addarg]=call(a:Strfunc, args, {})
            "▶2 Process addarg
            let args=[]
            if addarg isnot 0
                call add(args, addarg)
            endif
            unlet addarg
            "▲2
            if laststatus==2
                let r=[len(chars), join(chars, ''), retvalue]
            elseif laststatus==0
                break
            elseif laststatus==-1
                if r[0]==0
                    let r[-1]=retvalue
                endif
                break
            elseif laststatus==3
                let r=[len(chars), join(chars, ''), retvalue]
                break
            endif
            "▶2 Update `time' variable, unlet retvalue
            if exists('time')
                let time=reltime()
            endif
            unlet retvalue
            "▲2
        else
            sleep 50m
        endif
    endwhile
    "▶2 Throw `strfail'
    if laststatus==0 && r[0]==0
        call s:_f.throw('strfail')
    endif
    "▶2 feed additional keys back
    if len(chars)>r[0]
        if a:0
            call call(a:1, [chars[r[0]:]], {})
        else
            call feedkeys(join(chars[r[0]:], ''))
        endif
    endif
    "▲2
    return ((r[-1] is 0)?(r[1]):(r[1:]))
endfunction
"▶1 mapgroup feature
let s:F.mapgroup={}
"▶2 mapgroup.map   :: {f}, mgid[, bufnr] + s:mgroups → + … (unmapmgroup)
function s:F.mapgroup.map(plugdict, fdict, mgid, ...)
    "▶3 Check mgid
    if type(a:mgid)!=type('')
        call s:_f.throw('mmmgidnstr', a:plugdict.id)
    elseif !has_key(s:mgroups, a:mgid)
        call s:_f.throw('mmnomgid', a:mgid, a:plugdict.id)
    endif
    "▲3
    let mgroup=s:mgroups[a:mgid]
    "▶3 Check mgroup and a:1
    if !(a:plugdict.id is# mgroup.plid ||
                \has_key(a:plugdict.dependencies, mgroup.plid))
        call s:_f.throw('mmnounrel', a:mgid, a:plugdict.id, mgroup.plid)
    elseif a:0 && !(type(a:1)==type(0) && bufexists(a:1))
        call s:_f.throw('mminvbuf', a:mgid, a:plugdict.id)
    endif
    "▲3
    let buf=get(a:000, 0, 0)
    let curbuf=bufnr('%')
    if buf
        if buf!=curbuf
            let s:missinggroups[buf]=add(get(s:missinggroups,buf,[]),[mgroup,0])
            return
        endif
        return s:F.mapmgroup(mgroup, 0, 1)
    else
        return s:F.mapmgroup(mgroup, 0)
    endif
endfunction
"▶2 mapgroup.unmap :: {f}, mgid[, bufnr] + s:mgroups → + … (unmapmgroup)
function s:F.mapgroup.unmap(plugdict, fdict, mgid, ...)
    "▶3 Check mgid
    if type(a:mgid)!=type('')
        call s:_f.throw('ummgidnstr', a:plugdict.id)
    elseif !has_key(s:mgroups, a:mgid)
        call s:_f.throw('umnomgid', a:mgid, a:plugdict.id)
    endif
    "▲3
    let mgroup=s:mgroups[a:mgid]
    "▶3 Check mgroup and a:1
    if !(a:plugdict.id is# mgroup.plid ||
                \has_key(a:plugdict.dependencies, mgroup.plid))
        call s:_f.throw('umnounrel', a:mgid, a:plugdict.id, mgroup.plid)
    elseif a:0 && !(type(a:1)==type(0) && bufexists(a:1))
        call s:_f.throw('uminvbuf', a:mgid, a:plugdict.id)
    endif
    "▲3
    let buf=get(a:000, 0, 0)
    if buf
        if buf!=bufnr('%')
            let s:deletedgroups[buf]=add(get(s:deletedgroups, buf, []), mgroup)
            return
        endif
        return s:F.unmapmgroup(mgroup, 1)
    else
        return s:F.unmapmgroup(mgroup)
    endif
endfunction
"▶2 mapgroup.add   :: {f}, mgid, {mapid: mapdescr}[, mopts] → + s:mgroups, …
"▶3 getfkey :: mgroup, Val, mapname, plugdict, emsgid → Val | + throw
function s:F.getfkey(mgroup, Val, mapname, plugdict, emsgid)
    if type(a:Val)==type({})
        if !has_key(a:mgroup, 'wrapfunc')
            if !exists('a:plugdict.g._f.wrapfunc')
                call s:_f.throw('nowrapfunc', a:mapname, a:mgroup.id,
                            \                 a:plugdict.id)
            endif
            let a:mgroup.wrapfunc=a:plugdict.g._f.wrapfunc
        endif
    else
        if !exists('*a:Val')
            call s:_f.throw(a:emsgid, a:mapname, a:mgroup.id, a:plugdict.id)
        endif
    endif
    return a:Val
endfunction
"▲3
let s:mgroups={}
let s:mglastid=0
let s:mapdescrdef={'silent': 0,
            \     'noremap': 1,
            \        'expr': 0,
            \        'mode': ' ',
            \         'lhs': '',
            \    'operator': 0,
            \        'type': 'map',}
let s:maptypes={'map': 'nvxso!lci ',
            \  'abbr': 'ci ',
            \  'menu': 'anvxsoci ',}
let s:fts={}
function s:F.mapgroup.add(plugdict, fdict, mgid, mappings, ...)
    "▶3 Check arguments
    if type(a:mgid)!=type('')
        call s:_f.throw('mgidnotstr', a:plugdict.id)
    elseif type(a:mappings)!=type({})
        call s:_f.throw('mapsndct', a:mgid, a:plugdict.id)
    elseif empty(a:mappings)
        call s:_f.throw('mapsempty', a:mgid, a:plugdict.id)
    elseif a:0
        if type(a:1)!=type({})
            call s:_f.throw('mgoptsndct', a:mgid, a:plugdict.id)
        endif
    endif
    "▶3 mgid
    if empty(a:mgid)
        if empty(a:mgid) || !has_key(s:mgroups, a:mgid)
            let mgid=printf('_%x', s:mglastid)
            let s:mglastid+=1
        else
            let mgid=a:mgid
        endif
    elseif a:mgid!~#'^\u[A-Za-z0-9]*$'
        call s:_f.throw('invmgid', a:plugdict.id, a:mgid)
    else
        let mgid=a:mgid
    endif
    "▲3
    if has_key(s:mgroups, mgid)
        let mgroup=s:mgroups[mgid]
        if mgroup.plid isnot# a:plugdict.id
            call s:_f.throw('mgiddef', mgid, a:plugdict.id, mgroup.plid)
        endif
    else
        let mgroup= {     'id':   mgid,
                    \   'plid': a:plugdict.id,
                    \    'sid': a:plugdict.sid,
                    \   'maps': {},
                    \ 'leader': '',
                    \ 'buffer': (a:plugdict.type is# 'ftplugin'),
                    \ 'nouser': (mgid[0] is# '_'),
                    \'dontmap': 0,}
        "▶3 Add options: presence -> mgroup (nouser, dontmap, buffer)
        if a:0
            for key in ['nouser', 'dontmap', 'buffer']
                if has_key(a:1, key)
                    let mgroup[key]=1
                endif
            endfor
        endif
        "▲3
    endif
    let mapdescrdef=copy(s:mapdescrdef)
    "▶3 Add options
    if a:0
        if has_key(a:1, 'leader')
            "▶4 Check leader
            if type(a:1.leader)!=type('') && a:1.leader isnot 0
                call s:_f.throw('mleadnstr', mgid, a:plugdict.id)
            endif
            "▲4
            let mgroup.leader=a:1.leader
        endif
        if has_key(a:1, 'func')
            let mgroup.func=s:F.getfkey(mgroup, a:1.func, '', a:plugdict,
                        \               'ncall')
        endif
        "▶4 string -> mapdescrdef (mode, type)
        for key in ['mode', 'type']
            if has_key(a:1, key)
                if type(a:1[key])!=type('')
                    call s:_f.throw('mg'.key.'nstr', mgid, a:plugdict.id)
                endif
                let mapdescrdef[key]=a:1[key]
            endif
        endfor
        "▶4 bool -> mapdescrdef (silent, noremap, expr, operator)
        for key in ['silent', 'noremap', 'expr', 'operator']
            if has_key(a:1, key)
                if type(a:1[key])!=type(0)
                    call s:_f.throw('gdnbool', mgid, a:plugdict.id, key)
                endif
                let mapdescrdef[key]=(!!a:1[key])
            endif
        endfor
        "▲4
    endif
    "▶3 filetype
    if !mgroup.dontmap && a:plugdict.type is# 'ftplugin'
        let mgroup.filetype=matchstr(a:plugdict.id, '\v^[^/]*', 9)
        let mgroup.dontmap=1
    endif
    "▲3
    for [mapname, mapdescr] in items(a:mappings)
        "▶3 Check mapname and mapdescr
        if !(mgroup.nouser || mapname=~#'^\w\+$')
            call s:_f.throw('invmapname', mgid, a:plugdict.id, mapname)
        elseif type(mapdescr)!=type({})
            call s:_f.throw('mdescrndct', mapname, mgid, a:plugdict.id)
        elseif !has_key(mapdescr, 'rhs')
            call s:_f.throw('rhsndef', mapname, mgid, a:plugdict.id)
        elseif has_key(mgroup.maps, mapname)
            call s:_f.throw('middef', mapname, mgid, a:plugdict.id)
        endif
        "▲3
        let map={'id': mapname, 'mgid': mgroup.id, 'mapped': {}}
        "▶3 Populate map with provided or default values
        let map.sid=a:plugdict.sid
        let map.buffer=(mgroup.buffer!=0)
        let map.rhs=mapdescr.rhs
        for key in keys(mapdescrdef)
            if !has_key(mapdescr, key)
                let map[key]=mapdescrdef[key]
            else
                if type(mapdescrdef[key])==type('')
                    let map[key]=mapdescr[key]
                elseif type(mapdescr[key])!=type(0)
                    call s:_f.throw('mdnbool', mapname, mgid, a:plugdict.id,key)
                else
                    let map[key]=(!!mapdescr[key])
                endif
            endif
        endfor
        "▶3 Check map keys
        if map.lhs isnot 0 && type(map.lhs)!=type('')
            call s:_f.throw('lhsnstr', mapname, mgid, a:plugdict.id)
        elseif type(map.type)!=type('')
            call s:_f.throw('mtypenstr', mapname, mgid, a:plugdict.id)
        elseif !has_key(s:maptypes, map.type)
            call s:_f.throw('invmtype', mapname, mgid, a:plugdict.id, map.type)
        elseif (map.type is# 'abbr') && type(map.lhs)==type('') &&
                    \type(mgroup.leader)==type('') &&
                    \((mgroup.leader).(map.lhs)!~#s:ablhsreg)
            call s:_f.throw('invabbrlhs', mapname, mgid, a:plugdict.id,
                        \                 (mgroup.leader).(map.lhs))
        elseif type(map.mode)!=type('')
            call s:_f.throw('mmodenstr', mapname, mgid, a:plugdict.id)
        elseif (map.mode)!~#'^['.s:maptypes[(map.type)].']\+$'
            call s:_f.throw('invmode', mapname, mgid, a:plugdict.id, map.mode)
        endif
        "▶3 Reset keys that are irrelevant to menu, add `tip'
        if (map.type) is# 'menu'
            let map.expr=0
            let map.buffer=0
            if has_key(mapdescr, 'tip')
                if type(mapdescr.tip)!=type('')
                    call s:_f.throw('tipnstr', mapname, mgid, a:plugdict.id)
                endif
                let map.tip=mapdescr.tip
            endif
        endif
        "▶3 Add `strfunc' key
        if has_key(mapdescr, 'strfunc')
            let map.strfunc=s:F.getfkey(mgroup, mapdescr.strfunc, mapname,
                        \               a:plugdict, 'strfncall')
        endif
        "▶3 Add `func' key
        if has_key(mapdescr, 'func')
            let map.func=s:F.getfkey(mgroup, mapdescr.func, mapname, a:plugdict,
                        \            'fncall')
        endif
        "▲3
        let evalstr='<SNR>'.s:_sid.'_Eval'
        "▶3 map.rhs :: Funcref
        if type(map.rhs)==2 && exists('*map.rhs')
            let map.expr=2
            let map.func=map.rhs
            let map.rhs=evalstr.'("s:F").maprun("'.mgroup.id.'", '.
                        \                      '"'.(map.id).'", %s)'
        "▶3 map.rhs :: List
        elseif type(map.rhs)==type([])
            "▶4 Check `func' key existence
            if !has_key(map, 'func') && !has_key(mgroup, 'func')
                call s:_f.throw('nofunc', mapname, mgid, a:plugdict.id)
            endif
            "▲4
            let map.expr=3
            let map.args=map.rhs
            let map.rhs=evalstr.'("s:F").maprun("'.mgroup.id.'", '.
                        \                      '"'.(map.id).'", %s)'
        "▶3 map.rhs :: Dictionary
        elseif type(map.rhs)==type({})
            "▶4 Do some checks
            if has_key(mapdescr, 'args') && type(mapdescr.args)!=type([])
                call s:_f.throw('invargs',mapname, mgid, a:plugdict.id)
            endif
            "▲4
            let map.expr=3
            let map.func=s:F.getfkey(mgroup, map.rhs, mapname, a:plugdict, '')
            let map.args=get(mapdescr, 'args', [])
            let map.rhs=evalstr.'("s:F").maprun("'.mgroup.id.'", '.
                        \                      '"'.(map.id).'", %s)'
        "▶3 map.rhs :: String
        elseif type(map.rhs)==type('')
            if empty(map.rhs)
                let map.rhs='<Nop>'
            elseif has_key(map, 'strfunc')
                if type(map.strfunc)==type({})
                    let map.strfunc=call(mgroup.wrapfunc, [map.strfunc], {})
                endif
                let map.rhs=substitute((map.rhs), '%str',
                            \evalstr.'("s:F.getstr(s:mgroups.'.(mgroup.id).'.'.
                            \                       'maps.'.(map.id).'.strfunc'.
                            \                      ((map.expr)?
                            \                           (', s:F.feedfunc'):
                            \                           ('')).')")',
                            \'g')
            endif
        "▶3 unknown map.rhs
        else
            call s:_f.throw('invrhs', mapname, mgid, a:plugdict.id)
        endif
        "▲3
        if map.expr
            let map.rhs.='.('.evalstr.'("s:F.runfeed()"))'
        endif
        "▶3 mapping option
        if !mgroup.nouser
            let s:_options[(mgroup.id).'_'.(map.id)]={
                        \'default': [],
                        \ 'filter': s:F.lhsfilter,
                        \ 'merger': 'extend',
                    \}
        endif
        "▲3
        let mgroup.maps[map.id]=map
        unlet mapdescr
    endfor
    "▶3 Leader option
    if !mgroup.nouser
        let s:_options[mgroup.id]={
                    \'default': mgroup.leader,
                    \'checker': s:F.leadchecker,
                    \ 'scopes': 'g',
                \}
    endif
    "▲3
    let s:mgroups[mgroup.id]=mgroup
    let a:fdict[mgroup.id]=mgroup
    let maps=keys(a:mappings)
    if has_key(mgroup, 'filetype')
        if index(split(&filetype, '\.'),  mgroup.filetype)!=-1
            call s:F.mapmgroup(mgroup, keys(a:mappings), 1)
        endif
        if has_key(s:fts, mgroup.filetype)
            let s:fts[mgroup.filetype][mgroup.id]=mgroup
        else
            let s:fts[mgroup.filetype]={mgroup.id : mgroup}
            let s:missingft[mgroup.filetype]={}
        endif
        let mftd=s:missingft[mgroup.filetype]
        for buf in filter(range(1, bufnr('$')), 'v:val!='.bufnr('%'))
            let mftd[buf]=add(get(mftd, buf, []), [mgroup, maps])
        endfor
        return mgid
    elseif mgroup.dontmap
        if mgroup.buffer
            call s:F.mapmgroup(mgroup, maps, 1)
        endif
        return mgid
    elseif !mgroup.buffer
        call s:F.mapmgroup(mgroup, maps)
    endif
    call s:F.mapmgroup(mgroup, maps, 1)
    for buf in filter(range(1, bufnr('$')), 'v:val!='.bufnr('%'))
        let s:missinggroups[buf]=add(get(s:missinggroups,buf,[]),[mgroup,maps])
    endfor
    return mgid
endfunction
"▶2 mapgroup.del   :: {f}, mgid
function s:F.mapgroup.del(plugdict, fdict, mgid)
    "▶3 Check mgid
    if type(a:mgid)!=type('')
        call s:_f.throw('dmmgidnstr', a:plugdict.id)
    elseif !has_key(s:mgroups, a:mgid)
        call s:_f.throw('dmnomgid', a:mgid, a:plugdict.id)
    endif
    "▲3
    let mgroup=s:mgroups[a:mgid]
    "▶3 Check mgroup.plid
    if mgroup.plid!~#a:plugdict.id
        call s:_f.throw('dmnself', a:mgid, a:plugdict.id, mgroup.plid)
    endif
    "▲3
    call s:F.delmgroup(mgroup)
    unlet a:fdict[mgroup.id]
endfunction
"▶2 delmapgroups   :: {f} → + s:mgroups, …
function s:F.delmapgroups(plugdict, fdict)
    call map(values(a:fdict), 's:F.delmgroup(v:val)')
endfunction
"▶2 Register mapgroup feature
call s:_f.newfeature('mapgroup', {'cons': s:F.mapgroup,
            \                   'unload': s:F.delmapgroups})
"▶1 bufentered    :: () → + :map
let s:missinggroups={}
let s:deletedgroups={}
let s:missingft={}
function s:F.bufentered()
    let buf=expand('<abuf>')
    if has_key(s:bufmapped, buf)
        "▶2 unmap deleted groups
        if has_key(s:deletedgroups, buf)
            call map(s:deletedgroups[buf], 's:F.unmapmgroup(v:val, 1)')
            unlet s:deletedgroups[buf]
        endif
        "▶2 map created groups
        if has_key(s:missinggroups, buf)
            call map(s:missinggroups[buf], 's:F.mapmgroup(v:val[0],v:val[1],1)')
            unlet s:missinggroups[buf]
        endif
        "▶2 map created filetype groups
        let filetypes=filter(split(&filetype, '\.'),
                    \        'has_key(s:missingft, v:val) && '.
                    \        'has_key(s:missingft[v:val], '.buf.')')
        for filetype in filetypes
            for [mgroup, maps] in s:missingft[filetype][buf]
                call s:F.mapmgroup(mgroup, maps, 1)
            endfor
            unlet s:missingft[filetype][buf]
        endfor
        "▲2
        return
    endif
    for vname in ['missinggroups', 'deletedgroups']
        if has_key(s:{vname}, buf)
            unlet s:{vname}[buf]
        endif
    endfor
    let s:bufmapped[buf]={}
    for mgroup in filter(values(s:mgroups), '!v:val.dontmap')
        call s:F.mapmgroup(mgroup, 0, 1)
    endfor
endfunction
"▶1 ftmap         :: () → :map
function s:F.ftmap()
    let buf=expand('<abuf>')
    if has_key(s:bufmapped, buf)
        for mgroup in filter(values(s:mgroups), 'has_key(v:val, "filetype")')
            call s:F.unmapmgroup(mgroup, 1)
        endfor
    else
        call s:F.bufentered()
    endif
    let filetypes=split(expand('<amatch>'), '\V.')
    for filetype in filter(filetypes, 'has_key(s:fts, v:val)')
        for mgroup in values(s:fts[filetype])
            call s:F.mapmgroup(mgroup, 0, 1)
        endfor
    endfor
endfunction
"▶1 delbuffermaps :: () → + s:bufmapped, s:mgroups.*.maps.*.mapped
function s:F.delbuffermaps()
    let buf=expand('<abuf>')
    if has_key(s:bufmapped, buf)
        call map(values(s:bufmapped[buf]), 'remove(s:mgroups[v:val.mgid]'.
                    \                                '.maps[v:val.id].mapped, '.
                    \                             'v:val.mdid)')
        unlet s:bufmapped[buf]
    endif
endfunction
"▶1 Create autocommands
call s:_f.augroup.add('Mappings', [['BufEnter',  '*', 0, s:F.bufentered   ],
            \                      ['BufDelete', '*', 0, s:F.delbuffermaps],
            \                      ['Filetype',  '*', 0, s:F.ftmap        ]])
"▶1 map resource
call s:_f.postresource('map', {'maparg': s:F.savemap,
            \                     'map': s:F.map,
            \                   'unmap': s:F.unmap,})
"▶1
call frawor#Lockvar(s:, 'mapped,bufmapped,mgroups,_options,missinggroups,'.
            \           'deletedgroups,fts,missingft,mglastid')
" vim: fmr=▶,▲ sw=4 ts=4 sts=4 et tw=80
