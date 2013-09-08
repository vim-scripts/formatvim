"▶1 Header
scriptencoding utf-8
execute frawor#Setup('0.0', {'@/os': '0.0',
            \         '@/resources': '0.0',})
let s:F.sign={}
let s:signs={}
let s:lastsgid=0
"▶1 Define messages
if v:lang=~?'ru'
    let s:_messages={
                \  'sgidnstr': 'Ошибка создания знака для дополнения %s: '.
                \              'имя команды не является строкой',
                \   'invsgid': 'Ошибка создания знака для дополнения %s: '.
                \              'строка «%s» не может являться именем знака',
                \ 'dsgidnstr': 'Ошибка удаления знака для дополнения %s: '.
                \              'имя команды не является строкой',
                \  'dinvsgid': 'Ошибка удаления знака для дополнения %s: '.
                \              'строка «%s» не может являться именем знака',
                \  'nthisdef': 'Ошибка удаления знака %s для дополнения %s: '.
                \              'знак не был определён данным дополнением',
                \ 'psgidnstr': 'Ошибка показа знака для дополнения %s: '.
                \              'имя команды не является строкой',
                \  'pinvsgid': 'Ошибка показа знака для дополнения %s: '.
                \              'строка «%s» не может являться именем знака',
            \}
    call extend(s:_messages, map({
                \   'sgiddef': 'знак уже определён дополнением %s',
                \'sgoptsndct': 'второй аргумент не является словарём',
                \  'sgoempty': 'второй аргумент не содержит информации, '.
                \              'достаточной для определения знака',
                \'sgokeynstr': 'значение ключа %s не является строкой',
                \    'hlndef': 'неизвестная группа подсветки: %s',
                \  'iconread': 'файл с иконкой (%s) нечитаем',
                \   'invtext': '«%s» не может использовать в качестве '.
                \              'текста знака',
            \}, '"Ошибка создания знака %s для дополнения %s: ".v:val'))
    call extend(s:_messages, map({
                \ 'sgidundef': 'знак не определён',
                \     'bnnum': 'второй аргумент не является числом',
                \      'bnex': 'буфер с номером %i не существует',
                \     'lnnum': 'третий аргумент не является числом',
                \   'linvnum': 'номер строки должен быть положительным',
                \    'sgndep': 'знак определён не данным дополнением и '.
                \              'не одной из его зависимостей',
            \}, '"Ошибка показа знака %s для дополнения %s: ".v:val'))
else
    let s:_messages={
                \  'sgidnstr': 'Error while creating sign for plugin %s: '.
                \              'command name is not a String',
                \   'invsgid': 'Error while creating sign for plugin %s: '.
                \              '`%s'' is not a valid sign name',
                \ 'dsgidnstr': 'Error while deleting sign for plugin %s: '.
                \              'command name is not a String',
                \  'dinvsgid': 'Error while deleting sign for plugin %s: '.
                \              '`%s'' is not a valid sign name',
                \  'nthisdef': 'Error while deleting sign %s for plugin %s: '.
                \              'sign was not defined by this plugin',
                \ 'psgidnstr': 'Error while placing sign for plugin %s: '.
                \              'command name is not a String',
                \  'pinvsgid': 'Error while placing sign for plugin %s: '.
                \              '`%s'' is not a valid sign name',
            \}
    call extend(s:_messages, map({
                \   'sgiddef': 'sign was already defined by plugin %s',
                \'sgoptsndct': 'second argument is not a Dictionary',
                \  'sgoempty': 'second argument is missing information '.
                \              'required to define a sign',
                \'sgokeynstr': 'value of %s key is not a String',
                \    'hlndef': 'unknown higlight group: %s',
                \  'iconread': 'icon file (%s) is not readable',
                \   'invtext': '`%s'' is not a valid sign text',
            \}, '"Error while creating sign %s for plugin %s: ".v:val'))
    call extend(s:_messages, map({
                \ 'sgidundef': 'undefined sign',
                \     'bnnum': 'second argument is not a Number',
                \      'bnex': 'there is no buffer #%i',
                \     'lnnum': 'third argument is not a Number',
                \   'linvnum': 'line number must be positive',
                \    'sgndep': 'sign was defined neither by this plugin '.
                \              'nor by one of its dependencies',
            \}, '"Error while placing sign %s for plugin %s: ".v:val'))
endif
"▶1 signexists  :: sgid + :sign → Bool
function s:F.signexists(sgid)
    try
        silent execute 'sign list '.a:sgid
        return 1
    catch /Vim(sign):E155:/
        return 0
    endtry
endfunction
"▶1 getsigns    :: buf + :sign → [(line, id, name)]
function s:F.getsigns(buf)
    redir => placedstr
        silent execute 'sign place buffer='.a:buf
    redir END
    return map(map(filter(split(placedstr, "\n"),
                \         'v:val[:3] is# "    "'),
                \  'map(split(v:val[4:]), "v:val[stridx(v:val, ''='')+1:]")'),
                \'[+v:val[1], +v:val[0], v:val[2]]')
endfunction
"▶1 delsign     :: sgid → + :sign
function s:F.delsign(sgid)
    for buf in filter(range(1, bufnr('$')), 'bufexists(v:val)')
        for psign in filter(s:F.getsigns(buf), 'v:val[2] is# a:sgid')
            execute 'sign unplace '.psign[0].' buffer='.buf
        endfor
    endfor
    execute 'sign undefine '.a:sgid
endfunction
"▶1 getsigndef  :: sgid + :sign → sgopts
function s:F.getsigndef(sgid)
    redir => defstr
        silent execute 'sign list' a:sgid
    redir END
    let defstr=defstr[(6+len(a:sgid)):]
    let r={}
    " TODO check icons with spaces
    for prop in split(defstr)
        let eqidx=stridx(prop, '=')
        let r[prop[:(eqidx-1)]]=prop[(eqidx+1):]
    endfor
    return r
endfunction
"▶1 Post resource
call s:_f.postresource('sign', {'exists': s:F.signexists,
            \                   'delete': s:F.delsign,
            \                   'getbuf': s:F.getsigns,
            \                   'getdef': s:F.getsigndef,})
"▶1 add_signs   :: {f} → + p:_signs
function s:F.add_signs(plugdict, fdict)
    if !has_key(a:plugdict.g, '_signs') || type(a:plugdict.g._signs)!=type([])
        let a:plugdict.g._signs=[]
    endif
endfunction
"▶1 delsigns    :: {f} + p:_signs → + :delcommand, p:_signs
function s:F.delsigns(plugdict, fdict)
    if !has_key(a:plugdict.g, '_signs') || type(a:plugdict.g._signs)!=type([])
        return
    endif
    call map(filter(copy(a:plugdict.g._signs),
                \   'type(v:val)=='.type('').' && v:val=~#''\v%(\d+|\h\w*)$'' '.
                \   '&& s:F.signexists(v:val)'),
                \'s:F.delsign(v:val)')
endfunction
call s:_f.newfeature('delsigns', {'unloadpre': s:F.delsigns,
            \                      'register': s:F.add_signs,})
"▶1 sign.delete :: {f}[, sgid] → + :sign, s:signs
function s:F.sign.delete(plugdict, fdict, ...)
    if a:0
        "▶2 Check argument
        if type(a:1)!=type('')
            call s:_f.throw('dsgidnstr', a:plugdict.id)
        elseif a:1!~#'\v^%(\d+|\h\w*)$'
            call s:_f.throw('dinvsgid', a:plugdict.id, a:1)
        elseif !has_key(a:fdict, a:1)
            call s:_f.throw('nthisdef', a:1, a:plugdict.id)
        endif
        "▲2
        call s:F.delsign(a:1)
        unlet s:signs[a:1]
        unlet a:fdict[a:1]
    else
        for sgid in keys(a:fdict)
            call s:F.delsign(sgid)
            unlet s:signs[sgid]
            unlet a:fdict[sgid]
        endfor
    endif
endfunction
"▶1 sign.new    :: {f}, sgid, sgopts → + :sign, s:signs
let s:sgokeys=['linehl', 'text', 'texthl']
if has('gui_running')
    call add(s:sgokeys, 'icon')
endif
function s:F.sign.new(plugdict, fdict, sgid, sgopts)
    "▶2 Check first argument
    if a:sgid isnot 0
        if type(a:sgid)!=type('')
            call s:_f.throw('sgidnstr', a:plugdict.id)
        elseif a:sgid!~#'\v^%(\d+|\h\w*)$'
            call s:_f.throw('invsgid', a:plugdict.id, a:sgid)
        elseif has_key(s:signs, a:sgid)
            call s:_f.throw('sgiddef', a:sgid, a:plugdict.id,
                        \              s:signs[a:sgid].plid)
        endif
    endif
    "▶2 Get sign id
    if a:sgid is 0
        let sgid=printf('frawor%x', s:lastsgid)
        let s:lastsgid+=1
        while s:F.signexists(sgid)
            let sgid=printf('frawor%x', s:lastsgid)
            let s:lastsgid+=1
        endwhile
    else
        let sgid=a:sgid
    endif
    "▶2 Check second argument
    if type(a:sgopts)!=type({})
        call s:_f.throw('sgoptsndct', sgid, a:plugdict.id)
    endif
    "▲2
    let sgokeys=filter(copy(s:sgokeys), 'has_key(a:sgopts, v:val)')
    "▶2 Check sgokeys
    if empty(sgokeys)
        call s:_f.throw('sgoempty', sgid, a:plugdict.id)
    endif
    "▲2
    let sign={'id': sgid, 'places': [], 'plid': a:plugdict.id}
    "▶2 Process options
    let d={}
    for key in sgokeys
        let d.value=a:sgopts[key]
        if type(d.value)!=type('')
            call s:_f.throw('sgokeynstr', sgid, a:plugdict.id, key)
        endif
        if key[-2:] is# 'hl'
            if !hlexists(d.value)
                call s:_f.throw('hlndef', sgid, a:plugdict.id, d.value)
            endif
        elseif key is# 'icon'
            if !filereadable(d.value)
                call s:_f.throw('iconread', sgid, a:plugdict.id, d.value)
            endif
            let sign.ifile=s:_r.os.path.abspath(s:_r.os.path.normpath(d.value))
            let d.value=fnameescape(sign.ifile)
        elseif key is# 'text'
            if d.value!~#'\v^\p?\p$'
                call s:_f.throw('invtext', sgid, a:plugdict.id, d.value)
            endif
        endif
        let sign[key]=d.value
    endfor
    "▲2
    let sign.cmd='sign define '.sign.id.' '.
                \join(map(copy(sgokeys), 'v:val."=".sign[v:val]'))
    execute sign.cmd
    let a:fdict[sign.id]=sign
    let s:signs[sign.id]=sign
    return sign.id
endfunction
"▶1 sign.place  :: {f}, sgid, buf, line → + :sign, s:signs
function s:F.sign.place(plugdict, fdict, sgid, buf, line)
    "▶2 Check arguments
    if type(a:sgid)!=type('')
        call s:_f.throw('psgidnstr', a:plugdict.id)
    elseif a:sgid!~#'\v^%(\d+|\h\w*)$'
        call s:_f.throw('pinvsgid', a:plugdict.id, a:sgid)
    elseif !s:F.signexists(a:sgid)
        call s:_f.throw('sgidundef', a:sgid, a:plugdict.id)
    elseif type(a:buf)!=type(0)
        call s:_f.throw('bnnum', a:sgid, a:plugdict.id)
    elseif a:buf isnot 0 && !bufexists(a:buf)
        call s:_f.throw('bnex', a:sgid, a:plugdict.id, a:buf)
    elseif type(a:line)!=type(0)
        call s:_f.throw('lnnum', a:sgid, a:plugdict.id)
    elseif a:line<=0
        call s:_f.throw('linvnum', a:sgid, a:plugdict.id)
    endif
    "▶2 Sign was defined by this module
    if has_key(s:signs, a:sgid)
        let sign=s:signs[a:sgid]
        if !(has_key(a:fdict, a:sgid) ||
                    \has_key(a:plugdict.dependencies, sign.plid))
            call s:_f.throw('sgndep', a:sgid, a:plugdict.id)
        endif
    endif
    "▶2 Define buf
    let buf=a:buf
    if buf is 0
        let buf=bufnr('%')
    endif
    "▲2
    let id=max(map(s:F.getsigns(buf), 'v:val[0]'))+1
    execute 'sign place '.id.' line='.a:line.' name='.a:sgid.' buffer='.buf
    "▶2 Add tuple to sign.places
    if exists('sign')
        call add(sign.places, [id, buf, a:line])
    endif
    "▲2
    return id
endfunction
"▶1 Register feature
call s:_f.newfeature('sign', {'cons': s:F.sign,
            \               'unload': s:F.sign.delete,})
"▶1
call frawor#Lockvar(s:, 'signs,lastsgid')
" vim: fmr=▶,▲ sw=4 ts=4 sts=4 et tw=80
