"▶1 Header
scriptencoding utf-8
if exists('s:_pluginloaded') || exists('g:fraworOptions._donotload') ||
            \exists('g:frawor__donotload')
    finish
endif
"▶1 Variable initialization
let s:F={}
let s:_functions=[]
"▶2 s:
let s:deplen={}
let s:pls={} " Plugin dictionaries
let s:loading={}
let s:features={}
let s:plfeatures={}
let s:shadow={}
let s:featfunckeys=['cons', 'load', 'unload', 'unloadpre', 'register', 'depadd']
let s:featordered={'all': []}
let s:dependents={}
"▶2 Messages
if v:lang=~?'ru'
    let s:_messages={
                \ '_plstatuses': ['выгружен', 'зарегестрирован', 'загружен'],
                \'plregistered': 'Дополнение %s уже зарегистрировано '.
                \                'в каталоге %s',
                \   'doublereg': 'Попытка повторной регистрации %s '.
                \                'заблокирована',
                \  'filenotstr': 'Третий аргумент функции FraworRegister '.
                \                'должен быть строкой',
                \   'fileempty': 'Третий аргумент функции FraworRegister пуст',
                \  'vernotlist': 'Версия дополнения %s должна быть списком',
                \    'vershort': 'Версия дополнения %s должна содержать '.
                \                'не менее двух компонент',
                \   'vernotnum': 'Все компоненты версии дополнения %s должны '.
                \                'быть неотрицательными целыми',
                \  'depnotdict': 'Список зависимостей дополнения %s должен '.
                \                'являться словарём',
                \'d_vernotlist': 'Версия зависимости %s дополнения %s должна '.
                \                'быть списком',
                \  'd_vershort': 'Версия зависимости %s дополнения %s должна '.
                \                'содержать не менее одной компоненты',
                \ 'd_vernotnum': 'Все комопоненты версии зависимости %s '.
                \                'дополнения %s должны быть '.
                \                'неотрицательными целыми',
                \ 'majmismatch': 'Несовпадение основного номера версии '.
                \                'зависимости %s дополнения %s: '.
                \                'требовалась версия %u, но была загружена %u',
                \  'oldversion': 'Слишком старая версия зависимости %s '.
                \                'дополнения %s: требовалась версия %s, '.
                \                'но была загружена %s',
                \   'reqfailed': 'Не удалось загрузить зависимость %s '.
                \                'дополнения %s',
                \      'recdep': 'Дополнения %s и %s рецурсивно зависят '.
                \                'друг от друга',
                \    'gnotdict': 'Ошибка регистрации %s: '.
                \                'предпоследний аргумент FraworRegister '.
                \                'не является словарём',
                \    'Fnotdict': 'Ошибка регистрации %s: '.
                \                'последний аргумент FraworRegister '.
                \                'не является словарём',
                \   'sidnotnum': 'Ошибка регистрации %s: второй аргумент '.
                \                'FraworRegister не является числом',
                \   'sidnonpos': 'Ошибка регистрации %s: второй аргумент '.
                \                'FraworRegister должен быть '.
                \                'либо положителен, либо '.
                \                '(если первый аргумент равен нулю) нулём',
                \  'nomessages': 'Глобальная переменная дополнения %s '.
                \                'не содержит сообщений (_messages)',
                \   'mesnotdct': 'Ключ _messages глобальной переменной '.
                \                'дополнения %s не является словарём',
                \   'mesnotstr': 'Сообщение дополнения %s не является строкой',
                \   'nomessage': 'Список сообщений дополнения %s '.
                \                'не содержит сообщения %s',
                \   'fidnotstr': 'Ошибка регистрации возможности '.
                \                'дополнения %s: название возможности '.
                \                'не является строкой',
                \   'fidinvstr': 'Ошибка регистрации возможности '.
                \                'дополнения %s: строка «%s» '.
                \                'не может являться названием возможности',
                \     'featreg': 'Ошибка регистрации возможности %s '.
                \                'дополнения %s: возможность с таким именем '.
                \                'уже зарегестрирована данным дополнением',
                \ 'foptsnotdct': 'Ошибка регистрации возможности %s '.
                \                'дополнения %s: описание возможности '.
                \                'не является словарём',
                \    'initndct': 'Ошибка регистрации возможности %s '.
                \                'дополнения %s: значение ключа «init» '.
                \                'не является словарём',
                \  'nofeatkeys': 'Ошибка регистрации возможности %s '.
                \                'дополнения %s: описание возможности '.
                \                'не содержит ни одного из ключей '.
                \                '«'.join(s:featfunckeys, '», «').'»',
                \       'nfref': 'Ошибка регистрации возможности %s '.
                \                'дополнения %s: значение ключа «%s» '.
                \                'не является ссылкой на функцию',
                \       'ncall': 'Ошибка регистрации возможности %s '.
                \                'дополнения %s: значение ключа «%s» '.
                \                'не может быть вызвано (возможно '.
                \                'вы использовали ссылку на внутренную '.
                \                'функцию дополнения без раскрытия «s:» в '.
                \                '«<SNR>_{SID}»?)',
                \      'invkey': 'Ошибка регистрации возможности %s '.
                \                'дополнения %s: «%s» не является '.
                \                'правильным путём к функции',
                \  'unotloaded': 'Невозможно выгрузить незагруженное '.
                \                'дополнение %s',
                \   'plidempty': 'Имя дополнения не может быть пустой строкой',
                \ 'invplugdict': 'Неправильный словарь с описанием дополнения',
                \  'invloadarg': 'Неверный тип аргумента FraworLoad',
                \   'notloaded': 'Дополнение %s не загружено',
                \'invunloadarg': 'Неверный тип аргумента FraworUnload',
                \       'npref': 'Использование приставки «%s» здесь '.
                \                'не разрешено',
                \    'plidnstr': 'Ошибка добавления зависимости '.
                \                'дополнения %s: имя дополнения '.
                \                'должно являться непустой строкой',
                \'invplversion': 'Ошибка добавления зависимости %s '.
                \                'дополнения %s: версия дополнения должна '.
                \                'быть непустым списком '.
                \                'целых неотрицательных чисел',
                \  'thrownbool': 'Ошибка добавления зависимости %s '.
                \                'дополнения %s: последний обязательный '.
                \                'аргумент должен быть нулём или единицей',
                \  'plidrnbool': 'Ошибка добавления зависимости %s '.
                \                'дополнения %s: необязательный аргумент '.
                \                'должен быть нулём или единицей',
            \}
else
    let s:_messages={
                \ '_plstatuses': ['unloaded', 'registered', 'loaded'],
                \'plregistered': 'Plugin %s was already registered '.
                \                'in directory %s',
                \   'doublereg': 'Refusing to register %s for the second time',
                \  'filenotstr': 'Third argument to FraworRegister '.
                \                'must be a String',
                \   'fileempty': 'Third argument to FraworRegister is empty',
                \  'vernotlist': 'Version argument of plugin %s is not a List',
                \    'vershort': 'Version argument of plugin %s must have '.
                \                'at least two components',
                \   'vernotnum': 'All components of %s version must be '.
                \                'nonnegative integers',
                \  'depnotdict': 'List of %s dependencies must be a Dictionary',
                \'d_vernotlist': 'Version must be a list in a dependency %s '.
                \                'of a plugin %s',
                \  'd_vershort': 'Version must contain at least one component '.
                \                'in a dependency %s of a plugin %s',
                \ 'd_vernotnum': 'All components of version must be '.
                \                'nonnegative integers in a dependency %s '.
                \                'of a plugin %s',
                \ 'majmismatch': 'Major version mismatch for dependency %s '.
                \                'of a plugin %s: expected %u, but got %u',
                \  'oldversion': 'Detected too old dependency %s '.
                \                'of a plugin %s: expected %s, but got %s',
                \   'reqfailed': 'Failed to load dependency %s of a plugin %s',
                \      'recdep': 'Plugins %s and %s are recursively dependent',
                \    'gnotdict': 'Error while registering %s: '.
                \                'last but one argument to FraworRegister '.
                \                'must be a Dictionary',
                \    'Fnotdict': 'Error while registering %s: '.
                \                'last argument to FraworRegister '.
                \                'must be a Dictionary',
                \   'sidnotnum': 'Error while registering %s: second argument '.
                \                'to FraworRegister must be a number',
                \   'sidnonpos': 'Error while registering %s: second argument '.
                \                'to FraworRegister must either be positive '.
                \                'or equal to 0 (if first argument '.
                \                'is equal to 0 too)',
                \  'nomessages': '%s global variable does not contain '.
                \                '_messages',
                \   'mesnotdct': 'Key _messages of a %s global variable '.
                \                'is not a dictionary',
                \   'mesnotstr': '%s message is not a String',
                \   'nomessage': '%s messages does not contain message id %s',
                \   'fidnotstr': 'Error while registering feature '.
                \                'of a plugin %s: feature ID is not a String',
                \   'fidinvstr': 'Error while registering feature '.
                \                'of a plugin %s: string `%s'' '.
                \                'is not a valid feature ID',
                \     'featreg': 'Error while registering feature %s '.
                \                'of a plugin %s: feature with such ID was '.
                \                'already registered by this plugin',
                \ 'foptsnotdct': 'Error while registering feature %s '.
                \                'of a plugin %s: description argument '.
                \                'is not a Dictionary',
                \    'initndct': 'Failed to construct feature %s '.
                \                'for plugin %s: `init'' key value '.
                \                'is not a dictionary',
                \  'nofeatkeys': 'Error while registering feature %s '.
                \                'of a plugin %s: description argument '.
                \                'contains none of the keys '.
                \                '`'.join(s:featfunckeys, "', `")."'",
                \       'nfref': 'Error while registering feature %s '.
                \                'of a plugin %s: `%s'' fopts key is not '.
                \                'a function reference',
                \       'ncall': 'Error while registering feature %s '.
                \                'of a plugin %s: `%s'' fopts key is not '.
                \                'callable (perhaps you tried to use '.
                \                'a reference to a script-local function '.
                \                'without replacing `s:'' '.
                \                'with `<SNR>_{SID})'')',
                \      'invkey': 'Error while registering feature %s '.
                \                'of a plugin %s: `%s'' is not a valid path '.
                \                'to function',
                \  'unotloaded': 'Unable to unload plugin %s that '.
                \                'is not loaded',
                \   'plidempty': 'Expected plugin ID, but got empty string',
                \ 'invplugdict': 'Plugin description dictionary is not valid',
                \  'invloadarg': 'Wrong type of FraworLoad argument',
                \   'notloaded': 'Plugin %s is not loaded',
                \'invunloadarg': 'Wrong type of FraworUnload argument',
                \       'npref': 'Prefix `%s'' is not allowed here',
                \    'plidnstr': 'Error while adding dependency to plugin %s: '.
                \                'plugin name should be a non-empty string',
                \'invplversion': 'Error while adding dependency %s '.
                \                'to plugin %s: plugin version should be '.
                \                'a non-empty list of non-negative integers',
                \  'thrownbool': 'Error while adding dependency %s '.
                \                'to plugin %s: last required argument '.
                \                'should be either 0 or 1',
                \  'plidrnbool': 'Error while adding dependency %s '.
                \                'to plugin %s: optional argument should be '.
                \                'either 0 or 1',
            \}
endif
"▶1 s:Eval
function s:Eval(expr)
    return eval(a:expr)
endfunction
let s:_functions+=['s:Eval']
"▶1 expandplid      :: String → plid
let s:prefixes={
            \'@/': 'autoload/frawor/',
            \'@:': 'ftplugin/',
            \'@%': 'autoload/',
            \'@' : 'plugin/',
            \'@@': '@',
        \}
function s:F.expandplid(str, ...)
    let prefix=matchstr(a:str, '\v^\@[/:%@\^.]?')
    if empty(prefix)
        return a:str
    elseif has_key(s:prefixes, prefix)
        return s:prefixes[prefix].a:str[len(prefix):]
    elseif !a:0
        call s:_f.throw('npref', prefix)
    elseif prefix is# '@^'
        return matchstr(a:1, '\m.*/').a:str[2:]
    elseif prefix is# '@.'
        return a:1.a:str[2:]
    else
        return s:prefixes[prefix].a:str[len(prefix):]
    endif
endfunction
"▶1 compareversions :: version, version → -1|0|1
function s:F.compareversions(a, b)
    let len=max([len(a:a), len(a:b)])
    for i in range(0, len-1)
        let a=get(a:a, i, 0)
        let b=get(a:b, i, 0)
        if a>b
            return 1
        elseif a<b
            return -1
        endif
    endfor
    return 0
endfunction
"▶1 normpath        :: path + FS → path
let s:sep=fnamemodify(expand('<sfile>:h'), ':p')[-1:]
let s:sesep=escape(s:sep, '\&~')
let s:resep='\V'.escape(s:sep, '\').'\+'
function s:F.normpath(path)
    return substitute(expand(fnameescape(resolve(a:path)), 1),
                \     s:resep, s:sesep, 'g')
endfunction
"▶1 parseplugpath   :: filename + FS → (plugtype, plid, runtimepath)
let s:rtpcache={}
let s:dircache={}
function s:F.parseplugpath(file)
    if has_key(s:rtpcache, &runtimepath)
        let rtps=s:rtpcache[&runtimepath]
    else
        "   (split(...))                 split runtimepath on non-escaped «,»
        " → (last substitute)           unescape commas and backward slashes
        " → (last but one substitute)   expand ${VAR} using eval()
        " → (fnamemodify(..., ':p'))    turn path into full
        " → (filter(..., isdirectory))  filter out existing directories
        " → (v:val[:-2])                remove trailing path separator (resolve
        "                               does not work with it)
        " → (s:F.normpath(...))         normalize path (resolve symlinks,
        "                               translate slashes for win32, remove 
        "                               duplicating path separators)
        let rtps=map(filter(map(split(&runtimepath, '\v%(\\@<!\\%(\\\\)*)@<!,'),
                    \'fnamemodify(substitute(substitute(v:val, '.
                    \                                  '''\\\([\\,]\)'', '.
                    \                                  '"\\1", "g"), '.
                    \                        '''\$\w\+'', '.
                    \                        '"\\=eval(submatch(0))","g"),'.
                    \            '":p")'), 'isdirectory(v:val)'),
                    \'s:F.normpath(v:val[:-2])')
        let s:rtpcache[&runtimepath]=rtps
    endif
    let file=fnamemodify(a:file, ':p')
    " XXX fnamemodify here removes trailing path separator as well. This 
    " behavior must be kept in order to work with resolve()
    let curpath=fnamemodify(file, ':h')
    let removedcomponents=[fnamemodify(file, ':t:r')]
    let foundrtp=''
    let lastpath=''
    let adddirs=[]
    while lastpath isnot# curpath
        let lastpath=curpath
        if has_key(s:dircache, curpath)
            call extend(removedcomponents, s:dircache[curpath][0], 0)
            let foundrtp=s:dircache[curpath][1]
            break
        endif
        call add(adddirs, curpath)
        let rcurpath=s:F.normpath(curpath)
        if index(rtps, rcurpath)!=-1
            let foundrtp=rcurpath
            break
        endif
        call insert(removedcomponents, fnamemodify(curpath, ':t'))
        let curpath=fnamemodify(curpath, ':h')
    endwhile
    let i=1
    for dir in adddirs
        let s:dircache[dir]=[removedcomponents[0:-i-1], foundrtp]
        let i+=1
    endfor
    if !empty(foundrtp)
        return [((len(removedcomponents)>1)?
                    \ removedcomponents[0]:
                    \ '/script'),
                    \join(removedcomponents, '/'), foundrtp]
    else
        return ['/unknown', join(removedcomponents, '/'), '']
    endif
endfunction
"▶1 recdictmap      :: dict, expr[, path, processed] → dict + ?
function s:F.recdictmap(dict, expr, ...)
    if a:0
        let [path, processed]=a:000
        if type(a:dict)==type({})
            if empty(filter(copy(processed), 'v:val is a:dict'))
                call add(processed, a:dict)
            else
                return a:dict
            endif
        endif
    else
        let path=[]
        let processed=[a:dict]
    endif
    return map(a:dict, 'type(v:val)=='.type({}).' ? '.
                \           's:F.recdictmap(v:val, a:expr, path+[v:key], '.
                \                          'processed) : '.
                \           '('.a:expr.')')
endfunction
"▶1 createconsfunc  :: efid, fname, consargs, suf → function
function s:F.createconsfunc(efid, fname, consargs, suf)
    let r={}
    execute  "function r.F(...)\n".
                \'    return call(s:features['.a:efid.'].cons'.a:suf.', '.
                \                '['.printf(a:consargs,a:fname)."]+a:000,{})\n".
                \'endfunction'
    return r.F
endfunction
"▶1 createcons      :: plugdict, shadowdict, feature → dict
function s:F.createcons(plugdict, shadowdict, feature)
    if type(a:feature.cons)==type({})
        return s:F.recdictmap(deepcopy(a:feature.cons),
                    \'s:F.createconsfunc('.string(a:feature.escapedid).', '.
                    \                      string(a:feature.name).', '.
                    \                      string(a:shadowdict.consargs).', '.
                    \                    '".".join(path+[v:key], "."))')
    else
        return s:F.createconsfunc(a:feature.escapedid, a:feature.name,
                    \             a:shadowdict.consargs, '')
    endif
endfunction
"▶1 addcons         :: plugdict + s:featordered.all → + p:_f
function s:F.addcons(plugdict)
    let shadowdict=s:shadow[a:plugdict.id]
    for feature in filter(copy(s:featordered.all),
                \         'has_key(v:val, "cons") && '.
                \         'has_key(a:plugdict.dependencies, v:val.plid)')
        let a:plugdict.g._f[feature.name]=s:F.createcons(a:plugdict, shadowdict,
                    \                                    feature)
    endfor
endfunction
"▶1 getfeatures     :: plugdict, key → [feature]
function s:F.getfeatures(plugdict, key)
    if !has_key(s:featordered, a:key)
        let s:featordered[a:key]=filter(copy(s:featordered.all),
                    \                   'has_key(v:val, "'.a:key.'")')
    endif
    return filter(copy(s:featordered[a:key]),
                \ 'has_key(a:plugdict.dependencies, v:val.plid) ||'.
                \ 'has_key(v:val, "ignoredeps")')
endfunction
"▶1 runfeatures     :: plugdict, fkey[, …] + shadowdict → plugdict + shadowdict
function s:F.runfeatures(plugdict, key, ...)
    let fdicts=s:shadow[a:plugdict.id].features
    let fnames={}
    for feature in filter(s:F.getfeatures(a:plugdict, a:key),
                \         '!has_key(fnames, v:val.name)')
        let fnames[feature.name]=feature
        call call(feature[a:key], [a:plugdict, fdicts[feature.name]]+a:000, {})
    endfor
    " XXX required in order not to copy list
    return a:plugdict
endfunction
"▶1 initfeatures    :: plugdict + shadowdict → + shadowdict
function s:F.initfeatures(plugdict)
    let fdicts=s:shadow[a:plugdict.id].features
    for feature in filter(s:F.getfeatures(a:plugdict, 'all'),
                \         '!has_key(fdicts, v:val.name)')
        let fdict={}
        let fdicts[feature.name]=fdict
        if has_key(feature, 'init')
            call extend(fdict, deepcopy(feature.init))
        endif
        if has_key(feature, 'register')
            call feature.register(a:plugdict, fdict)
        endif
    endfor
endfunction
"▶1 updatedeplen    :: plid, newval, dict + s:deplen → + s:deplen
function s:F.updatedeplen(plid, newval, updated)
    let s:deplen[a:plid]=a:newval
    let a:updated[a:plid]=1
    if has_key(s:dependents, a:plid)
        let nv=a:newval+1
        call map(keys(s:dependents[a:plid]),
                    \'((!has_key(a:updated, v:val) && '.
                    \  's:deplen[v:val]<'.nv.')?'.
                    \   's:F.updatedeplen(v:val, '.nv.', a:updated):'.
                    \   '0)')
    endif
endfunction
"▶1 newplugin       :: version, sid, file, dependencies, g → +s:pls,
let s:ftplugtypes=['ftplugin', 'syntax', 'indent']
function s:F.newplugin(version, sid, file, dependencies, g)
    "▶2 Checking whether a:file is a string
    if type(a:file)!=type('')
        call s:_f.throw('filenotstr')
    elseif empty(a:file)
        call s:_f.throw('fileempty')
    endif
    "▶2 plugtype, plid, plrtp, plversion
    if a:version is 0
        let plugtype='/anonymous'
        let plid=a:file
        let plrtp=''
        let plversion=[0, 0]
    else
        let [plugtype, plid, plrtp]=s:F.parseplugpath(a:file)
        "▶3 Verifying plugin version
        if type(a:version)!=type([])
            call s:_f.throw('vernotlist', plid)
        elseif len(a:version)<2
            call s:_f.throw('vershort', plid)
        elseif !empty(filter(copy(a:version),
                    \        'type(v:val)!='.type(0).' || v:val<0'))
            call s:_f.throw('vernotnum', plid)
        endif
        "▲3
        let plversion=a:version
    endif
    "▶2 Checking whether a:g is dictionary and a:sid is non-negative number
    if type(a:g)!=type({})
        call s:_f.throw('gnotdict', plid)
    elseif type(a:sid)!=type(0)
        call s:_f.throw('sidnotnum', plid)
    elseif !(a:sid>0 || (type(a:version)==type(0) && a:sid==0))
        call s:_f.throw('sidnonpos', plid)
    endif
    "▶2 Checking for double registration
    if has_key(s:pls, plid)
        if s:pls[plid].runtimepath is# plrtp
            call s:_f.throw('doublereg', plid)
        endif
        if plugtype[0] isnot# '/'
            call s:_f.warn('plregistered', plid, plrtp)
        endif
        while has_key(s:pls, plid)
            let plid.='/'
        endwhile
    endif
    "▶2 Constructing plugdict
    "▶3 Some trivial construction
    let plugdict={
                \         'type': plugtype,
                \           'id': plid,
                \  'runtimepath': plrtp,
                \      'version': plversion,
                \   'isftplugin': index(s:ftplugtypes, plugtype)!=-1,
                \         'file': ((a:version is 0)?(get(a:g, '_sfile', 0)):
                \                                   (a:file)),
                \          'sid': a:sid,
                \ 'dependencies': {},
                \       'status': 1,
                \            'g': a:g,
            \}
    let plugdict.g._f={}
    "▶3 Processing dependencies
    if type(a:dependencies)!=type({})
        call s:_f.throw('depnotdict', plid)
    endif
    let d={}
    let deps=copy(a:dependencies)
    "▶4 Adding frawor to dependencies
    if exists('s:_frawor')
        if !has_key(deps, s:_frawor.id)
            let deps[s:_frawor.id]=s:pls[s:_frawor.id].version
        endif
    else
        let deps[plid]=plversion
    endif
    "▲4
    for [dplid, d.Version] in items(deps)
        let dplid=s:F.expandplid(dplid, plid)
        "▶4 Verifying dependency version
        if type(d.Version)!=type([])
            call s:_f.throw('d_vernotlist', dplid, plid)
        elseif empty(d.Version)
            call s:_f.throw('d_vershort', dplid, plid)
        elseif !empty(filter(copy(d.Version), 'type(v:val)!='.type(0)))
            call s:_f.throw('d_vernotnum', dplid, plid)
        endif
        "▲4
        let plugdict.dependencies[dplid]=d.Version
        if !has_key(s:dependents, dplid)
            let s:dependents[dplid]={}
        endif
        let s:dependents[dplid][plid]=plugdict
    endfor
    "▶3 Locking plugdict
    lockvar 1 plugdict
    lockvar plugdict.version
    lockvar! plugdict.dependencies
    unlockvar plugdict.status
    "▶2 Shadow dictionary
    let shadowdict={}
    let shadowdict.escapedid=substitute(string(plid), '\n', '''."\n".''', 'g')
    let shadowdict.intprefix='s:pls['.shadowdict.escapedid.']'
    let shadowdict.consargs=shadowdict.intprefix.', '.
                \           's:shadow['.shadowdict.escapedid.'].features.%s'
    let shadowdict.features={}
    let shadowdict.loadedfs={}
    let s:shadow[plugdict.id]=shadowdict
    "▶3 Locking shadowdict
    lockvar 1 shadowdict
    "▶2 Constructing _frawor dictionary
    let plugdict.g._frawor={
                \       'type': plugdict.type,
                \         'id': plugdict.id,
                \'runtimepath': plugdict.runtimepath,
            \}
    "▲2
    let s:pls[plid]=plugdict
    let s:shadow[plid]=shadowdict
    let s:deplen[plid]=max(map(keys(plugdict.dependencies),
                \              '((v:val is# '.string(plid).')?'.
                \                  '(0):'.
                \                  '(get(s:deplen, v:val, 0)))'))+1
    call s:F.updatedeplen(plid, s:deplen[plid], {})
    call s:F.initfeatures(plugdict)
    let plugdict.g._pluginloaded=0
    call s:F.loadplugin(plugdict)
endfunction
"▶1 addfeature      :: plugdict, feature(ircl)[, load] → + shadowdict
function s:F.addfeature(plugdict, feature, ...)
    let shadowdict=s:shadow[a:plugdict.id]
    "▶2 `init' and `register' keys
    if !has_key(shadowdict.features, a:feature.name)
        let fdict={}
        let shadowdict.features[a:feature.name]=fdict
        if has_key(a:feature, 'init')
            call extend(fdict, deepcopy(a:feature.init))
        endif
        if has_key(a:feature, 'register')
            call a:feature.register(a:plugdict, fdict)
        endif
    endif
    "▶2 `cons' key
    if has_key(a:feature,'cons') && !has_key(a:plugdict.g._f, a:feature.name)
                \&& has_key(a:plugdict.dependencies, a:feature.plid)
        let a:plugdict.g._f[a:feature.name]=s:F.createcons(a:plugdict,
                    \                                      shadowdict,
                    \                                      a:feature)
    endif
    "▶2 `load' key
    if has_key(a:feature, 'load') && !has_key(shadowdict.loadedfs,
                \                             a:feature.name)
                \&& ((a:0 && a:1) || a:plugdict.status==2)
        call a:feature.load(a:plugdict, shadowdict.features[a:feature.name])
        let shadowdict.loadedfs[a:feature.name]=1
    endif
    "▲2
    return a:feature
endfunction
"▶1 getdeps         :: plugdict, hasdep::{plid: _} + s:dependents,… → [plugdict]
function s:F.getdeps(plugdict, hasdep)
    let r=[a:plugdict]
    let a:hasdep[a:plugdict.id]=1
    for dplid in keys(get(s:dependents, a:plugdict.id, {}))
        " XXX cannot use filter() as a:hasdep gets modified by s:F.getdeps
        if !has_key(a:hasdep, dplid)
            let a:hasdep[dplid]=1
            let r+=s:F.getdeps(s:pls[dplid], a:hasdep)
        endif
    endfor
    return r
endfunction
"▶1 depcomp         :: plugdict, plugdict + s:dependents → -1|0|1
" Makes plugins which are being less depended on first in a list when passed as 
" a second argument to sort()
function s:DepComp(plugdict1, plugdict2)
    let plid1=a:plugdict1.id
    let plid2=a:plugdict2.id
    let dl1=s:deplen[plid1]
    let dl2=s:deplen[plid2]
    if dl1==dl2
        return ((plid1>plid2)?(1):(-1))
    endif
    return ((dl1<dl2)?(1):(-1))
endfunction
let s:_functions+=['s:DepComp']
"▶1 getordereddeps  :: plugdict + s:dependents → [plugdict]
function s:F.getordereddeps(plugdict)
    return sort(s:F.getdeps(a:plugdict, {}), function('s:DepComp'))
endfunction
"▶1 loadplugin      :: Either plugdict plid → 0|1|2 + plugdict, …
function s:F.loadplugin(plid)
    "▶2 Get plugdict
    if type(a:plid)==type('')
        let plid=s:F.expandplid(a:plid)
        "▶3 Checking for empty plid
        if empty(plid)
            call s:_f.throw('plidempty')
        endif
        "▶3 Checking whether plugin is already being loaded
        if has_key(s:loading, plid)
            return 2
        endif
        "▲3
        if !has_key(s:pls, plid)
            execute 'runtime! '.fnameescape(plid.'.vim')
        endif
        "▶3 Checking whether plugin was successfully loaded
        if !has_key(s:pls, plid)
            return 0
        endif
        "▲3
        let plugdict=s:pls[plid]
    "▶3 Processing dictionary supplied instead of plugin ID
    elseif type(a:plid)==type({})
        if has_key(a:plid, 'id') && type(a:plid.id)==type('') &&
                    \has_key(s:pls, a:plid.id) && s:pls[a:plid.id] is# a:plid
            let plid=a:plid.id
            let plugdict=a:plid
        else
            call s:_f.throw('invplugdict')
        endif
    "▶3 Error: plid type unknown
    else
        call s:_f.throw('invloadarg')
    endif
    "▲2
    if plugdict.status!=2
        let shadowdict=s:shadow[plugdict.id]
        let s:loading[plid]=1
        let d={}
        try
            let olddeplen=s:deplen[plid]
            "▶2 Loading dependencies
            for [dplid, d.Version] in items(plugdict.dependencies)
                if has_key(s:loading, dplid)
                    if dplid isnot# plid
                        call s:_f.warn('recdep', dplid, plid)
                    endif
                    continue
                endif
                if !has_key(s:pls, dplid) || s:pls[dplid].status!=2
                    if s:F.loadplugin(dplid)
                        " It must have run updatedeplen on its own and thus has 
                        " updated all plid dependants
                        let olddeplen=s:deplen[plid]
                    else
                        call s:_f.throw('reqfailed', dplid, plid)
                    endif
                endif
                let dversion=s:pls[dplid].version
                "▶3 Checking dependency version
                if d.Version[0]!=dversion[0]
                    call s:_f.throw('majmismatch', dplid, plid,
                                \                  d.Version[0],
                                \                  dversion[0])
                elseif s:F.compareversions(d.Version, dversion)>0
                    call s:_f.throw('oldversion', dplid, plid,
                                \                 join(d.Version, '.'),
                                \                 join(dversion,  '.'))
                endif
                "▲3
            endfor
            "▶2 Running features
            for feature in s:F.getfeatures(plugdict, 'all')
                call s:F.addfeature(plugdict, feature, 1)
            endfor
            "▲2
            if s:deplen[plid]>olddeplen
                call s:F.updatedeplen(plid, s:deplen[plid], {})
            endif
            "▶2 Modifying plugdict status
            let plugdict.g._pluginloaded=1
            let plugdict.status=2
            lockvar! plugdict.status
            "▶2 Adding features to already loaded plugins
            if has_key(shadowdict.features, 'newfeature')
                for feature in values(shadowdict.features.newfeature)
                    call map(((has_key(feature, 'ignoredeps'))?
                                \       (values(s:pls)):
                                \       (values(get(s:dependents, plugdict.id,
                                \                   {})))),
                                \'s:F.addfeature(v:val, feature)')
                endfor
            endif
            "▲2
        finally
            unlet s:loading[plid]
        endtry
    endif
    return 1
endfunction
"▶1 unloadplugin    :: Either plugdict plid + … → [filename]
" Returns a list of files that should be sourced to load plugin back
function s:F.unloadplugin(plid)
    "▶2 Get plugdict
    if type(a:plid)==type('')
        let plid=s:F.expandplid(a:plid)
        if has_key(s:pls, plid)
            let plugdict=s:pls[plid]
        else
            call s:_f.throw('notloaded', plid)
        endif
        unlet plid
    elseif type(a:plid)==type({})
        if has_key(a:plid, 'id') && type(a:plid.id)==type("") &&
                    \has_key(s:pls, a:plid.id) && s:pls[a:plid.id] is# a:plid
            let plugdict=a:plid
        else
            call s:_f.throw('invplugdict')
        endif
    else
        call s:_f.throw('invunloadarg')
    endif
    "▲2
    if plugdict.status!=0
        let ordered=s:F.getordereddeps(plugdict)
        let tosource=map(reverse(copy(ordered)), 'v:val.file')
        " XXX runfeature returns v:val
        call map(ordered, 's:F.runfeatures(v:val, "unloadpre")')
        for plugdict in ordered
            call s:F.runfeatures(plugdict, 'unload')
            if exists('*plugdict.g._unload')
                call plugdict.g._unload()
            endif
            unlockvar plugdict.status
            let plugdict.status=0
            lockvar! plugdict.status
            "▶2 Clear references to this plugin
            unlet s:pls[plugdict.id]
            if has_key(s:dependents, plugdict.id)
                unlet s:dependents[plugdict.id]
            endif
            call map(s:dependents, 'filter(v:val, "v:key isnot# plugdict.id")')
            "▲2
            unlockvar plugdict.g
            call map(keys(plugdict.g), 'remove(plugdict.g, v:val)')
        endfor
        return tosource
    else
        return []
    endif
endfunction
"▶1 FraworRegister
function FraworRegister(...)
    return call(s:F.newplugin, a:000, {})
endfunction
let s:_functions+=['FraworRegister']
"▶1 FraworLoad
function FraworLoad(...)
    return call(s:F.loadplugin, a:000, {})
endfunction
let s:_functions+=['FraworLoad']
"▶1 FraworUnload
function! FraworUnload(...)
    return call(s:F.unloadplugin, a:000, {})
endfunction
let s:_functions+=['FraworUnload']
"▶1 isfunc          :: funcref, key, fname, plid → + throw
function s:F.isfunc(Func, key, fname, plid)
    if type(a:Func)!=2
        call s:_f.throw('nfref', a:fname, a:plid, a:key)
    elseif !exists('*a:Func')
        call s:_f.throw('ncall', a:fname, a:plid, a:key)
    elseif stridx(a:key, '.')!=-1 && a:key!~#'^cons\%(\.\w\+\)\+$'
        call s:_f.throw('invkey', a:fname, a:plid, a:key)
    endif
endfunction
"▶1 featcomp        :: feature, feature + s:deplen → -1|0|1
function s:F.featcomp(feature1, feature2)
    let plid1=a:feature1.plid
    let plid2=a:feature2.plid
    let dl1=s:deplen[plid1]
    let dl2=s:deplen[plid2]
    if dl1==dl2
        if plid1 is# plid2
            return ((a:feature1.id>a:feature2.id)?(1):(-1))
        endif
        return ((plid1>plid2)?(1):(-1))
    endif
    return ((dl1<dl2)?(1):(-1))
endfunction
"▶1 biadd                      :: [a], a, cmp → + [a]
function s:F.biadd(list, item, Cmp)
    let llist=len(a:list)
    let d={'cmp': a:Cmp}
    if !llist
        call add(a:list, a:item)
    elseif llist==1
        call call((d.cmp(a:list[0], a:item)>0)?('insert'):('add'),
                    \[a:list, a:item])
    else
        if d.cmp(a:list[0], a:item)>0
            call insert(a:list, a:item)
            return
        elseif d.cmp(a:list[-1], a:item)<0
            call add(a:list, a:item)
            return
        endif
        let lborder=0
        let rborder=llist-1
        let cur=(((rborder+1)/2)-1)
        while lborder!=rborder
            let cr=d.cmp(a:list[cur], a:item)
            let shift=((rborder-lborder)/2)
            if !shift
                break
            endif
            let {(cr>0)?('r'):('l')}border=cur
            let cur=lborder+shift
        endwhile
        call insert(a:list, a:item, rborder)
    endif
endfunction
"▶1 features.newfeature.cons   :: {f}, fid, fopts → + s:features, shadowdict, …
let s:newfeature={
            \'plid': 'plugin/frawor',
            \'name': 'newfeature',
            \'init': {},
        \}
let s:newfeature.id=s:newfeature.plid.'/'.s:newfeature.name
let s:newfeature.escapedid=string(s:newfeature.id)
function s:newfeature.cons(plugdict, fdict, fid, fopts)
    "▶2 Check arguments
    if type(a:fid)!=type('')
        call s:_f.throw('fidnotstr', a:plugdict.id)
    elseif empty(a:fid) || a:fid=~#'\W'
        call s:_f.throw('fidinvstr', a:plugdict.id, a:fid)
    elseif has_key(a:fdict, a:fid)
        call s:_f.throw('featreg', a:fid, a:plugdict.id)
    elseif type(a:fopts)!=type({})
        call s:_f.throw('foptsnotdct', a:fid, a:plugdict.id)
    endif
    "▲2
    let feature={
                \'plid': a:plugdict.id,
                \'name': a:fid,
                \  'id': a:plugdict.id.'/'.a:fid,
            \}
    let feature.escapedid=substitute(string(feature.id), '\n', '''."\n".''','g')
    "▶2 Adding keys that hold functions
    let addedsomething=0
    for key in filter(copy(s:featfunckeys), 'has_key(a:fopts, v:val)')
        if key is# 'cons' && type(a:fopts[key])==type({})
            call s:F.recdictmap(deepcopy(a:fopts[key]),
                        \'s:F.isfunc(v:val, '.
                        \           '"cons.".join(path+[v:key], "."), '.
                        \            string(feature.name).', '.
                        \            string(feature.plid).')')
        else
            call s:F.isfunc(a:fopts[key], key, feature.name, feature.plid)
        endif
        let feature[key]=a:fopts[key]
        let addedsomething=1
    endfor
    "▶3 Must have added something
    if !addedsomething
        call s:_f.throw('nofeatkeys', feature.name, feature.plid)
    endif
    "▶2 Adding `ignoredeps'
    if has_key(a:fopts, 'ignoredeps')
        let feature.ignoredeps=1
    endif
    "▶2 Adding `init'
    if has_key(a:fopts, 'init')
        if type(a:fopts.init)!=type({})
            call s:_f.throw('initndct', feature.name, a:plugdict.id)
        endif
        let feature.init=a:fopts.init
    endif
    "▲2
    let a:fdict[feature.name]=feature
    let s:features[feature.id]=feature
    let s:plfeatures[a:plugdict.id]=a:fdict
    let s:featordered={'all': s:featordered.all}
    call s:F.biadd(s:featordered.all, feature, s:F.featcomp)
    "▶2 Running addfeature()
    call map(((has_key(feature, 'ignoredeps'))?
                \(values(s:pls)):
                \((has_key(s:dependents, a:plugdict.id))?
                \   (values(get(s:dependents, a:plugdict.id, {}))):
                \   ([]))),
                \'s:F.addfeature(v:val, feature)')
endfunction
"▶1 features.newfeature.unload :: {f} → + s:features, shadowdict
function s:newfeature.unload(plugdict, fdict)
    if !empty(a:fdict)
        let s:featordered={'all': s:featordered.all}
        unlet s:plfeatures[a:plugdict.id]
    endif
    for feature in values(a:fdict)
        if has_key(feature, 'ignoredeps')
            for shadowdict in values(s:shadow)
                if has_key(shadowdict.features, feature.name)
                    unlet shadowdict.features[feature.name]
                endif
                if has_key(shadowdict.loadedfs, feature.name)
                    unlet shadowdict.loadedfs[feature.name]
                endif
            endfor
        endif
        unlet s:features[feature.id]
        call filter(s:featordered.all, 'v:val isnot feature')
    endfor
endfunction
let s:features[s:newfeature.id]=s:newfeature
let s:featordered.all+=[s:newfeature]
"▶1 Plugin registration
call s:F.newplugin([1, 1], s:Eval('+matchstr(expand("<sfile>"), ''\d\+'')'),
            \      expand('<sfile>:p'), {}, s:)
let s:shadow[s:_frawor.id].features.newfeature.newfeature=s:newfeature
unlet s:newfeature
"▶1 warn feature    :: {f}, msgid, … + p:_messages → message + echomsg
function s:F.warn(plugdict, fdict, msgid, ...)
    if !has_key(a:plugdict.g, '_messages')
        call s:_f.throw('nomessages', a:plugdict.id)
    elseif type(a:plugdict.g._messages)!=type({})
        call s:_f.throw('mesnotdct', a:plugdict.id)
    elseif type(a:msgid)!=type('')
        call s:_f.throw('mesnotstr', a:plugdict.id)
    elseif !has_key(a:plugdict.g._messages, a:msgid)
        call s:_f.throw('nomessage', a:plugdict.id, a:msgid)
    endif
    let message=a:plugdict.g._messages[a:msgid]
    if a:0
        let message=call('printf', [message]+a:000)
    endif
    let message='Frawor:'.escape(a:plugdict.id, '\:').':'.
                \escape(a:msgid, '\:').':'.message
    echohl ErrorMsg
    for msgline in split(message, "\n", 1)
        if empty(msgline)
            echohl None
            echomsg ' '
            echohl ErrorMsg
        else
            echomsg msgline
        endif
    endfor
    echohl None
    return message
endfunction
call s:_f.newfeature('warn', {'cons': s:F.warn})
"▶1 throw feature   :: {f}, msgid, … → + throw
function s:F.throw(plugdict, fdict, msgid, ...)
    throw call(s:F.warn, [a:plugdict, a:fdict, a:msgid]+a:000, {})
endfunction
call s:_f.newfeature('throw', {'cons': s:F.throw})
"▶1 require feature :: {f}, plid, version, throw → + plugdict
function s:F.require(plugdict, fdict, dplid, dversion, throw, ...)
    "▶2 Check arguments
    if type(a:dplid)!=type('') || empty(a:dplid)
        call s:_f.throw('plidnstr', a:plugdict.id)
    elseif type(a:dversion)!=type([]) || empty(a:dversion) ||
                \!empty(filter(copy(a:dversion), 'type(v:val)!='.type(0)))
        call s:_f.throw('invplversion', a:dplid, a:plugdict.id)
    elseif type(a:throw)!=type(0)
        call s:_f.throw('thrownbool', a:dplid, a:plugdict.id)
    elseif a:0 && type(a:1)!=type(0)
        call s:_f.throw('plidrnbool', a:dplid, a:plugdict.id)
    endif
    "▲2
    let dplid=s:F.expandplid(a:dplid, a:plugdict.id)
    if has_key(a:plugdict.dependencies, dplid)
        return (a:0 && a:1 ? dplid : 2)
    endif
    "▶2 Add dependency
    unlockvar 1 a:plugdict.dependencies
    let a:plugdict.dependencies[dplid]=copy(a:dversion)
    lockvar 1 a:plugdict.dependencies
    lockvar! a:plugdict.dependencies[dplid]
    if !has_key(s:dependents, dplid)
        let s:dependents[dplid]={}
    endif
    let s:dependents[dplid][a:plugdict.id]=a:plugdict
    "▲2
    let shadowdict=s:shadow[a:plugdict.id]
    let fdicts=shadowdict.features
    "▶2 Load dependency if required
    let olddstatus=0
    let doload=1
    if has_key(s:pls, dplid)
        let olddstatus=s:pls[dplid].status
        let doload=(olddstatus!=2)
    endif
    if doload
        if s:F.loadplugin(dplid)
            if olddstatus==0
                if has_key(s:loading, a:plugdict.id) && has_key(s:plfeatures,
                            \                                   dplid)
                    let dfeatures=s:plfeatures[dplid]
                    call map(filter(values(dfeatures), 'has_key(v:val,"load")'),
                                \'v:val.load(a:plugdict, fdicts[v:val.name])')
                endif
                call s:F.runfeatures(a:plugdict, 'depadd', dplid)
                return (a:0 && a:1 ? dplid : 1)
            endif
        else
            if a:throw
                call s:_f.throw('reqfailed', dplid, a:plugdict.id)
            else
                unlockvar 1 a:plugdict.dependencies
                call remove(a:plugdict.dependencies, dplid)
                lockvar 1 a:plugdict.dependencies
                return 0
            endif
        endif
    elseif s:deplen[dplid]+1>s:deplen[a:plugdict.id]
        call s:F.updatedeplen(a:plugdict.id, s:deplen[dplid]+1, {})
    endif
    "▲2
    let dfeatures=get(s:plfeatures, dplid, {})
    for feature in filter(values(dfeatures), '!has_key(fdicts, v:val.name)')
        let fdict={}
        let fdicts[feature.name]=fdict
        if has_key(feature, 'init')
            call extend(fdict, deepcopy(feature.init))
        endif
        if has_key(feature, 'register')
            call feature.register(a:plugdict, fdict)
        endif
        if has_key(feature, 'cons')
            let a:plugdict.g._f[feature.name]=
                        \s:F.createcons(a:plugdict, shadowdict, feature)
        endif
        if has_key(feature, 'load') && (a:plugdict.status==2 ||
                    \                   has_key(s:loading, a:plugdict.id))
            call feature.load(a:plugdict, fdict)
        endif
    endfor
    call s:F.runfeatures(a:plugdict, 'depadd', dplid)
    return (a:0 && a:1 ? dplid : 1)
endfunction
call s:_f.newfeature('require', {'cons': s:F.require})
"▶1 Load modules with ignoredeps features
call FraworLoad('@/functions')
call FraworLoad('@/autocommands')
"▶1
call frawor#Lockvar(s:, 'dependents,features,featordered,loading,shadow,pls,'.
            \           'rtpcache,dircache,deplen,plfeatures')
lockvar 1 f
" vim: fmr=▶,▲ sw=4 ts=4 sts=4 et tw=80
