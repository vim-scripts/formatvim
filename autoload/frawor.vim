"▶1 Header
scriptencoding utf-8
if exists('s:_pluginloaded') || exists('g:fraworOptions._donotload') ||
            \exists('g:frawor__donotload')
    finish
endif
let s:F={}
let s:_functions=[]
function s:Eval(expr)
    return eval(a:expr)
endfunction
let s:_functions+=['s:Eval']
"▶1 frawor#Setup      :: version, dependencies[, oneload] → vimlstr
function frawor#Setup(version, dependencies)
    if type(a:version)==type('')
        let ver=map(split(a:version, '\.'), '+v:val')
    else
        let ver=a:version
    endif
    let deps=map(copy(a:dependencies),
                \'((type(v:val)==type(""))?'.
                \   '(map(split(v:val, "\\."), "+v:val")):'.
                \   '(v:val))')
    let dstr=substitute(string(deps), "\n", '''."\\n".''', 'g')
    return       "if !exists('s:_pluginloaded')\n"
                \."    execute \"function s:Eval(expr)\\n"
                \.              "    return eval(a:expr)\\n"
                \.              "endfunction\"\n"
                \."    let s:_sid=+matchstr(s:Eval('expand(\"<sfile>\")'), "
                \.                                              "'\\m\\d\\+')\n"
                \."    let s:_sfile=expand('<sfile>:p')\n"
                \."    let s:F={}\n"
                \."    let s:_functions=['s:Eval']\n"
                \."    call FraworRegister(".string(ver).", "
                \.                        "s:_sid, s:_sfile, ".dstr.", s:)\n"
                \."elseif s:_pluginloaded\n"
                \."    finish\n"
                \."endif\n"
endfunction
let s:_functions+=['frawor#Setup']
"▶1 frawor#Reload     :: Either plugdict plid → + :source
function! frawor#Reload(plid)
    for file in FraworUnload(a:plid)
        if file isnot 0
            execute 'source' fnameescape(file)
        endif
    endfor
endfunction
let s:_functions+=['frawor#Reload']
"▶1 frawor#Lockvar    :: p:, varnamelist → + :lockvar
function frawor#Lockvar(s, nolock)
    let nolock=split(a:nolock, ',')+['_pluginloaded', '_loading']
    for varname in filter(keys(a:s), 'index(nolock, v:val)==-1')
        lockvar! a:s[varname]
    endfor
endfunction
let s:_functions+=['frawor#Lockvar']
"▶1 Plugin registration
if !exists('*FraworRegister')
    runtime! plugin/frawor.vim
endif
call FraworRegister([0, 0], s:Eval('+matchstr(expand("<sfile>"), ''\d\+'')'),
            \       expand('<sfile>:p'), {}, s:)
"▶1
call frawor#Lockvar(s:, '')
" vim: fmr=▶,▲ sw=4 ts=4 sts=4 et tw=80
