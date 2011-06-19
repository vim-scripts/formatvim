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
let s:selfdeps={}
let s:pls={} " Plugin dictionaries
let s:loading={}
let s:features={}
let s:shadow={}
let s:featfunckeys=['cons', 'load', 'unload', 'unloadpre', 'register']
let s:f={}
call map(copy(s:featfunckeys), 'extend(s:f, {v:val : {}})')
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
            \}
endif
"▶1 s:Eval
function s:Eval(expr)
    return eval(a:expr)
endfunction
let s:_functions+=['s:Eval']
"▶1 expandplid      :: String → plid
let s:prefixes={
            \'@/': 'plugin/frawor/',
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
function s:F.normpath(path)
    return expand(fnameescape(substitute(resolve(a:path),
                \                        '\V'.escape(s:sep, '\').'\+',
                \                        escape(s:sep, '\&~'), 'g')))
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
        return [get(removedcomponents, 0, 'plugin'),
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
                \           'eval(a:expr)')
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
"▶1 addcons         :: plugdict + s:f.cons → + p:_f
function s:F.addcons(plugdict)
    let shadowdict=s:shadow[a:plugdict.id]
    for feature in sort(values(s:f.cons), function('s:FeatComp'))
        if has_key(a:plugdict.dependencies, feature.plid)
            let a:plugdict.g._f[feature.name]=s:F.createcons(a:plugdict,
                        \                                    shadowdict,
                        \                                    feature)
        endif
    endfor
endfunction
"▶1 featcomp        :: feature, feature + s:selfdeps → -1|0|1
function s:FeatComp(feature1, feature2)
    let plid1=a:feature1.plid
    let plid2=a:feature2.plid
    let idx1=s:selfdeps[plid1]
    let idx2=s:selfdeps[plid2]
    if idx1==idx2
        if plid1 is# plid2
            return ((a:feature1.id>a:feature2.id)?(1):(-1))
        endif
        return ((plid1>plid2)?(1):(-1))
    endif
    return ((idx1>idx2)?(1):(-1))
endfunction
" " Can't add s:FeatComp to _functions because it is required for unloadplugin 
" " to  work and thus should not be removed by unloadpre event
" let function('s:FeatComp')=function('s:FeatComp')
"▶1 getfeatures     :: plugdict, {: feature} → [feature]
function s:F.getfeatures(plugdict, featuresdict)
    return sort(filter(values(a:featuresdict),
                \      'has_key(a:plugdict.dependencies, v:val.plid) ||'.
                \      'has_key(v:val, "ignoredeps")'),
                \function('s:FeatComp'))
endfunction
"▶1 runfeatures     :: plugdict, fkey + shadowdict, +s:f → plugdict + shadowdict
function s:F.runfeatures(plugdict, key)
    let fdicts=s:shadow[a:plugdict.id].features
    let fnames={}
    for feature in s:F.getfeatures(a:plugdict, s:f[a:key])
        if has_key(fnames, feature.name)
            continue
        endif
        let fnames[feature.name]=feature
        call call(feature[a:key], [a:plugdict, fdicts[feature.name]], {})
    endfor
    " XXX required in order not to copy list
    return a:plugdict
endfunction
"▶1 initfeatures    :: plugdict + shadowdict → + shadowdict
function s:F.initfeatures(plugdict)
    let fdicts=s:shadow[a:plugdict.id].features
    for feature in s:F.getfeatures(a:plugdict, s:features)
        if has_key(fdicts, feature.name)
            continue
        endif
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
"▶1 newplugin       :: version, sid, file, dependencies, oneload, g → +s:pls,
function s:F.newplugin(version, sid, file, dependencies, oneload, g)
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
                \      'oneload': !!a:oneload,
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
        let s:dependents[dplid][plid]=1
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
    "▶3 Locking shadow dictionary
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
    let s:selfdeps={}
    call map(s:F.getordereddeps(s:pls[s:_frawor.id]),
                \'extend(s:selfdeps, {v:val.id : v:key})')
    call s:F.initfeatures(plugdict)
    let plugdict.g._pluginloaded=0
    if a:oneload
        call s:F.loadplugin(plid)
    else
        call s:F.addcons(plugdict)
    endif
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
"▶1 getordereddeps  :: plugdict + s:dependents → [plugdict]
function s:F.getordereddeps(plugdict)
    let deps=sort(s:F.getdeps(a:plugdict, {}), function('s:DepComp'))
    let ordered=[]
    let withdeps=[]
    call map(deps, 'add(((empty(get(s:dependents, v:val.id, {})))?'.
                \           '(ordered):'.
                \           '(withdeps)), '.
                \      'v:val)')
    let orderedids=map(copy(ordered), 'v:val.id')
    unlet deps
    while !empty(withdeps)
        let removedsmth=0
        let i=0
        while i<len(withdeps)
            if empty(filter(keys(get(s:dependents, withdeps[i].id, {})),
                        \   'index(orderedids, v:val)==-1'))
                call add(ordered,    withdeps[i])
                call add(orderedids, withdeps[i].id)
                call remove(withdeps, i)
                let removedsmth=1
            else
                let i+=1
            endif
        endwhile
        if !removedsmth && !empty(withdeps)
            call add(ordered,    withdeps[0])
            call add(orderedids, withdeps[0].id)
            call remove(withdeps, 0)
        endif
    endwhile
    return ordered
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
        if !has_key(s:pls, a:plid)
            return 0
        endif
        "▲3
        let plugdict=s:pls[a:plid]
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
            "▶2 Loading dependencies
            for [dplid, d.Version] in items(plugdict.dependencies)
                if has_key(s:loading, dplid)
                    if dplid isnot# plid
                        call s:_f.warn('recdep', dplid, plid)
                    endif
                    continue
                endif
                if s:F.loadplugin(dplid)
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
                else
                    call s:_f.throw('reqfailed', dplid, plid)
                endif
            endfor
            "▲2
            "▶2 Running features
            for feature in s:F.getfeatures(plugdict, s:features)
                call s:F.addfeature(plugdict, feature, 1)
            endfor
            "▲2
            if !plugdict.oneload
                execute 'source '.fnameescape(plugdict.file)
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
                                \       (map(keys(get(s:dependents,
                                \                     plugdict.id, {})),
                                \            's:pls[v:val]'))),
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
"▶1 getdeps         :: plugdict, hasdep::{plid: _} + s:dependents,… → [plugdict]
function s:F.getdeps(plugdict, hasdep)
    let r=[a:plugdict]
    let a:hasdep[a:plugdict.id]=1
    for dplugdict in map(keys(get(s:dependents, a:plugdict.id, {})),
                \        's:pls[v:val]')
        if !has_key(a:hasdep, dplugdict.id)
            let a:hasdep[dplugdict.id]=1
            let r+=s:F.getdeps(dplugdict, a:hasdep)
        endif
    endfor
    return r
endfunction
"▶1 depcomp         :: plugdict, plugdict + s:dependents → -1|0|1
" Makes plugins which are being less depended on first in a list when passed as 
" a second argument to sort()
function s:DepComp(plugdict1, plugdict2)
    let depnum1=len(keys(get(s:dependents, a:plugdict1.id, {})))
    let depnum2=len(keys(get(s:dependents, a:plugdict2.id, {})))
    return ((depnum1>depnum2)?
                \(1):
                \((depnum1<depnum2)?
                \   (-1):
                \   ((a:plugdict1.id>a:plugdict2.id)?
                \       (1):
                \       (-1))))
endfunction
let s:_functions+=['s:DepComp']
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
            unlet s:selfdeps[plugdict.id]
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
"▶1 _unload
function s:._unload()
    delfunction s:FeatComp
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
    for key in s:featfunckeys
        if has_key(a:fopts, key)
            if key is# 'cons'
                if type(a:fopts[key])==type({})
                    call s:F.recdictmap(deepcopy(a:fopts[key]),
                                \'s:F.isfunc(v:val, '.
                                \           '"cons.".join(path+[v:key], "."), '.
                                \            string(feature.name).', '.
                                \            string(feature.plid).')')
                else
                    call s:F.isfunc(a:fopts[key], key, feature.name,
                                \   feature.plid)
                endif
            else
                call s:F.isfunc(a:fopts[key], key, feature.name, feature.plid)
            endif
            let feature[key]=a:fopts[key]
            let s:f[key][feature.id]=feature
            let addedsomething=1
        endif
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
        let s:f.register[feature.id]=feature
    endif
    "▲2
    let a:fdict[feature.name]=feature
    let s:features[feature.id]=feature
    "▶2 Running addfeature()
    call map(((has_key(feature, 'ignoredeps'))?
                \(values(s:pls)):
                \((has_key(s:dependents, a:plugdict.id))?
                \   (map(keys(get(s:dependents, a:plugdict.id, {})),
                \        's:pls[v:val]')):
                \   ([]))),
                \'s:F.addfeature(v:val, feature)')
endfunction
"▶1 features.newfeature.unload :: {f} → + s:features, shadowdict, s:f
function s:newfeature.unload(plugdict, fdict)
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
        for featdict in values(s:f)
            if has_key(featdict, feature.id)
                unlet featdict[feature.id]
            endif
        endfor
    endfor
endfunction
let s:features[s:newfeature.id]=s:newfeature
let s:f.cons[s:newfeature.id]=s:newfeature
let s:f.load[s:newfeature.id]=s:newfeature
let s:f.unload[s:newfeature.id]=s:newfeature
"▶1 Plugin registration
call s:F.newplugin([0, 0], s:Eval('+matchstr(expand("<sfile>"), ''\d\+'')'),
            \      expand('<sfile>:p'), {}, 1, s:)
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
"▶1
call frawor#Lockvar(s:, 'dependents,features,f,selfdeps,loading,shadow,pls,'.
            \           'rtpcache,dircache')
lockvar 1 f
" vim: fmr=▶,▲ sw=4 ts=4 sts=4 et tw=80
