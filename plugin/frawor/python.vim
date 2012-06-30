"▶1 Header
scriptencoding utf-8
execute frawor#Setup('0.0', {'plugin/frawor/os': '0.0',
            \         'plugin/frawor/resources': '0.0',}, 1)
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
"▶1 py resource
let s:py={}
"▶2 py.run   :: cmd[, ...] + s:py.cmd → + ?
function s:py.run(cmd, ...)
    if type(a:cmd)==type([])
        let cmds=a:cmd
    else
        let cmds=[a:cmd]
    endif
    for cmd in cmds
        execute s:py.cmd cmd
    endfor
endfunction
"▶2 py.cmd
let s:haspython=0
let s:pythons=['python', 'python3']
for s:python in s:pythons
    if (has(s:python) || has(s:python.'/dyn')) && exists(':'.s:python)==2
        let s:py.cmd=s:python
        let s:py.filecmd=s:python[:1].s:python[6:].'file'
        try
            silent! call s:py.run(['import sys, vim',
                        \          'vim.command("let s:haspython=1")'])
        catch
        endtry
    endif
endfor
if !s:haspython
    finish
endif
"▶2 register resource
call s:_f.postresource('py', s:py)
"▶1 addpydir feature
let s:addedpaths={}
"▶2 addpydir :: {f} → + py:sys.path
function s:F.addpydir(plugdict, fdict)
    if empty(a:plugdict.runtimepath)
        return
    endif
    let dir=s:_r.os.path.join(a:plugdict.runtimepath, 'python')
    if s:_r.os.path.isdir(dir)
        if has_key(s:addedpaths, dir)
            let s:addedpaths[dir]+=1
        else
            let s:addedpaths[dir]=1
            call s:py.run('sys.path.append(vim.eval("a:1"))', dir)
        endif
        let a:fdict.imported=dir
    endif
endfunction
"▶2 delpydir :: {f} → + py:sys.path
function s:F.delpydir(plugdict, fdict)
    if has_key(a:fdict, 'imported')
        let s:addedpaths[a:fdict.imported]-=1
        if s:addedpaths[a:fdict.imported]<=0
            unlet s:addedpaths[a:fdict.imported]
            call s:py.run('sys.path.remove(vim.eval("a:1"))', a:fdict.imported)
        endif
    endif
endfunction
"▶2 register feature
call s:_f.newfeature('addpythonpath', {'register': s:F.addpydir,
            \                         'unloadpre': s:F.delpydir,
            \                        'ignoredeps': 1,})
"▶1
call frawor#Lockvar(s:, 'addedpaths')
" vim: fmr=▶,▲ sw=4 ts=4 sts=4 et tw=80
