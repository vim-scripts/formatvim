"▶1 Header
scriptencoding utf-8
execute frawor#Setup('1.1', {'@/os': '0.0',
            \         '@/resources': '0.0',
            \            '@/python': '1.0',})
"▶1 Define messages
if v:lang=~?'ru'
    let s:_messages={
                \
            \}
else
    let s:_messages={
                \
            \}
endif
"▶1 haspython*
let s:haspython=0
let s:haspython3=0
let s:pythons=['python', 'python3']
for s:python in s:pythons
    if has(s:python) && exists(':'.s:python)==2
        try
            execute s:python 'import sys, vim'
            execute s:python 'vim.command("let s:has'.s:python.'=1")'
        catch
        endtry
    endif
endfor
if !s:haspython && !s:haspython3
    finish
endif
"▶1 addpydir feature
let s:addedpaths={}
let s:addedpaths3={}
"▶2 addpydir :: {f} → + py:sys.path
function s:F.addpydir(plugdict, fdict)
    if empty(a:plugdict.runtimepath)
        return
    endif
    for p in ['', '3']
        let dir=s:_r.os.path.join(a:plugdict.runtimepath, 'python'.p)
        if s:haspython{p} && s:_r.os.path.isdir(dir)
            if has_key(s:addedpaths{p}, dir)
                let s:addedpaths{p}[dir]+=1
            else
                let s:addedpaths{p}[dir]=1
                execute 'python'.p 'sys.path.append(vim.eval("dir"))'
            endif
            let a:fdict['imported'.p]=dir
        endif
    endfor
endfunction
"▶2 delpydir :: {f} → + py:sys.path
function s:F.delpydir(plugdict, fdict)
    for p in ['', '3']
        let fkey='imported'.p
        if has_key(a:fdict, fkey)
            let s:addedpaths{p}[a:fdict[fkey]]-=1
            if s:addedpaths{p}[a:fdict[fkey]]<=0
                unlet s:addedpaths{p}[a:fdict[fkey]]
                execute 'python'.p 'sys.path.remove(vim.eval("a:fdict[fkey]"))'
            endif
        endif
    endfor
endfunction
"▶2 register feature
call s:_f.newfeature('addpythonpath', {'register': s:F.addpydir,
            \                         'unloadpre': s:F.delpydir,})
"▶1 FraworTypedCall
for s:p in [''] " ['', '3']
    " XXX Must go after newfeature call
    execute 'python'.s:p 'import frawor'
    execute 'python'.s:p 'frawor._ftc_name="<SNR>'.s:_sid.'_FraworTypedCall"'
endfor
unlet s:p
function s:F.gettypes(v)
    if type(a:v)==type({}) || type(a:v)==type([])
        let r=map(copy(a:v), 's:F.gettypes(v:val)')
        call map(a:v, 'type(v:val)==2 ? string(v:val)[10:-3] : v:val')
        return r
    else
        return type(a:v)
    endif
endfunction
function s:FraworTypedCall(...)
    let r=deepcopy(call('call', a:000))
    return [s:F.gettypes(r), r]
endfunction
let s:_functions+=['s:FraworTypedCall']
"▶1
call frawor#Lockvar(s:, 'addedpaths')
" vim: fmr=▶,▲ sw=4 ts=4 sts=4 et tw=80
