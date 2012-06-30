"▶1 Header
scriptencoding utf-8
execute frawor#Setup('0.0', {}, 1)
"▶1 Define messages
if v:lang=~?'ru'
    let s:_messages={
                \    'ridnstr': 'Ошибка создания ресурса дополнения %s: '.
                \               'имя ресурса не является строкой',
                \   'ridempty': 'Ошибка создания ресурса дополнения %s: '.
                \               'имя ресурсо пусто',
                \   'ridslash': 'Ошибка создания ресурса дополнения %s: '.
                \               'использование косой черты в имени '.
                \               'ресурса запрещено',
                \  'ridexists': 'Ошибка создания ресурса %s дополнения %s: '.
                \               'данный ресурс уже создан',
                \  'invrcpfun': 'Ошибка создания ресурса %s дополнения %s: '.
                \               'дополнительный аргумент неверен',
            \}
else
    let s:_messages={
                \    'ridnstr': 'Error while posting resource for plugin %s: '.
                \               'resource name is not a String',
                \   'ridempty': 'Error while posting resource for plugin %s: '.
                \               'resource name is empty',
                \   'ridslash': 'Error while posting resource for plugin %s: '.
                \               'slashes are not allowed in resource name',
                \  'ridexists': 'Error while posting resource %s '.
                \               'for plugin %s: resource was already defined',
                \  'invrcpfun': 'Error while posting resource %s '.
                \               'for plugin %s: invalid copy function',
            \}
endif
"▶1 id
function s:F.id(val)
    return a:val
endfunction
"▶1 resource feature
"▶2 postresource :: {f}, rid, resource[, cpf] → + s:plugresources
let s:plugresources={}
function s:F.postresource(plugdict, fdict, rid, resource, ...)
    "▶3 Check arguments
    if type(a:rid)!=type('')
        call s:_f.throw('ridnstr', a:plugdict.id)
    elseif empty(a:rid)
        call s:_f.throw('ridempty', a:plugdict.id)
    elseif has_key(a:fdict, a:rid)
        call s:_f.throw('ridexists', a:plugdict.id, a:rid)
    elseif a:0 && a:1 isnot 1 && a:1 isnot 0 && !exists('*a:1')
        call s:_f.throw('invrcpfun')
    endif
    "▶3 Add fdict to plugresources
    if !has_key(s:plugresources, a:plugdict.id)
        let s:plugresources[a:plugdict.id]=a:fdict
    endif
    "▲3
    let r={'name': a:rid,}
    if a:0 && a:1 isnot 0
        if a:1 is 1
            let r.resource=a:resource
            let r.copyfunc=s:F.id
        else
            let r.resource=deepcopy(a:resource)
            let r.copyfunc=a:1
        endif
    else
        let r.resource=deepcopy(a:resource)
        let r.copyfunc=function('deepcopy')
    endif
    let a:fdict[a:rid]=r
endfunction
"▶2 delresources :: {f} → + s:plugresources
function s:F.delresources(plugdict, fdict)
    if has_key(s:plugresources, a:plugdict.id)
        unlet s:plugresources[a:plugdict.id]
    endif
endfunction
"▶2 Register feature
call s:_f.newfeature('postresource', {'cons': s:F.postresource,
            \                       'unload': s:F.delresources,})
"▶1 addresource feature
let s:addresource={'ignoredeps': 1}
function s:addresource.load(plugdict, fdict)
    let r={}
    call map(map(filter(keys(a:plugdict.dependencies),
                \'has_key(s:plugresources, v:val)'),
                \'s:plugresources[v:val]'),
                \'map(values(v:val), '.
                \    '"extend(r, '.
                \            '{v:val.name : v:val.copyfunc(v:val.resource)})")')
    let a:plugdict.g._r=r
endfunction
function s:addresource.depadd(plugdict, fdict, dplid)
    if !has_key(a:plugdict.g, '_r') || type(a:plugdict.g._r)!=type({})
        return
    endif
    let r=a:plugdict.g._r
    if has_key(s:plugresources, a:dplid)
        call map(values(s:plugresources[a:dplid]),
                    \'extend(r, {v:val.name : v:val.copyfunc(v:val.resource)})')
    endif
endfunction
call s:_f.newfeature('addresource', s:addresource)
"▶1
call frawor#Lockvar(s:, 'plugresources')
" vim: fmr=▶,▲ sw=4 ts=4 sts=4 et tw=80
