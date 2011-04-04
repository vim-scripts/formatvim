scriptencoding utf-8
if exists("g:loadOptions.DoNotLoad")
    finish
endif
function load#LoadFuncdict(...)
    if !exists("*LoadFuncdict")
        runtime plugin/load.vim
    endif
    if empty(a:000)
        return LoadFuncdict()
    else
        return call(LoadFuncdict().getfunctions, a:000, {})
    endif
endfunction
function load#Setoption(dictionary, option, value, ...)
    if type(a:dictionary)!=type("") || type(a:option)!=type("") ||
                \empty(a:option) || a:dictionary!~#'^\w'
        return
    elseif !exists(a:dictionary)
        try
            let {a:dictionary}={}
        catch
            return
        endtry
    elseif type({a:dictionary})!=type({})
        unlet {a:dictionary}
        let {a:dictionary}={}
    elseif has_key({a:dictionary}, a:option) &&
                \islocked(a:dictionary.'[a:option]')
        unlockvar {a:dictionary}[a:option]
    endif
    if !empty(a:000) && a:000[0] && has_key({a:dictionary}, a:option) &&
                \(type(a:value)==type([]) || type(a:value)==type({})) &&
                \(type(a:value)==type({a:dictionary}[a:option]))
        call extend({a:dictionary}[a:option], a:value)
    else
        let {a:dictionary}[a:option]=a:value
    endif
    return {a:dictionary}
endfunction
function load#CreateDictFunction(arguments, body)
    let r={}
    execute "function r.f(".a:arguments.")\n".a:body."\nendfunction"
    return r.f
endfunction
" load#Setup :: version, vpref[, cpref|0|1[, fpref|0|1[, Bool]]]
function load#Setup(apiversion, ...)
    let oprefix=get(a:000, 0, 0)
    if type(oprefix)!=type("")
        let prefix="substitute(s:g._load.oprefix, '^\\l', '\\U&', '')"
        let oprefix="substitute(fnamemodify(s:g._load.scriptfile, ':t:r'), ".
                    \          '''^\d\|[^a-zA-Z0-9]'', "", "g")'
    else
        let prefix=string(substitute(oprefix, '^\l', '\U&', ''))
        let oprefix=string(oprefix)
    endif
    let d={}
    function d.getexpr(arg, prefix, n)
        if a:arg is 0
            return ""
        endif
        let p="let s:g._load.".a:n."prefix="
        if type(a:arg)==type("")
            return (p).string(a:arg)
        elseif a:arg is 1
            return (p).a:prefix
        endif
        return ""
    endfunction
    let oneload=(!!get(a:000, 3, 0))
    return join([
                \"let s:F={'plug': {}, 'main': {}}",
                \"let s:g={}",
                \"let s:g._pluginloaded=".oneload,
                \"execute \"".
                \   "function s:SID()\\n".
                \   "    return matchstr(expand('<sfile>'), '\\\\d\\\\+')\\n".
                \   "endfunction\"",
                \"let s:F.plug.load=load#LoadFuncdict()",
                \"let s:g._load={".
                \           "'funcdict': s:F, ".
                \           "'globdict': s:g, ".
                \           "'sid': s:SID(), ".
                \           "'scriptfile': expand('<sfile>'), ".
                \           "'apiversion': ".string(a:apiversion).", ".
                \           "'oneload': ".oneload.", ".
                \       "}",
                \"let s:g._load.oprefix=".oprefix,
                \d.getexpr(get(a:000, 1, 0), prefix, "c"),
                \d.getexpr(get(a:000, 2, 0), prefix, "f"),
                \"delfunction s:SID",
            \], "\n")
endfunction

