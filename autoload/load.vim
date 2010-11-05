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

