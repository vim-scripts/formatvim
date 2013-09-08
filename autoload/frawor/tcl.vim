"▶1 Header
scriptencoding utf-8
execute frawor#Setup('0.0', {'@/os': '0.0',})
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
"▶1 s:hastcl
let s:hastcl=0
if has('tcl') && exists(':tcl')==2
    try
        silent! tcl ::vim::command 'let s:hastcl=1'
    catch
    endtry
endif
if !s:hastcl
    finish
endif
"▶1 addtcldir feature
let s:addedpaths={}
"▶2 addtcldir :: {f} → + tcl:package.path
function s:F.addtcldir(plugdict, fdict)
    if empty(a:plugdict.runtimepath)
        return
    endif
    let dir=s:_r.os.path.join(a:plugdict.runtimepath, 'tcl')
    if s:_r.os.path.isdir(dir)
        if has_key(s:addedpaths, dir)
            let s:addedpaths[dir]+=1
        else
            let s:addedpaths[dir]=1
            tcl lappend auto_path [::vim::expr 'dir'] ; list
        endif
        let a:fdict.imported=dir
    endif
endfunction
"▶2 deltcldir :: {f} → + tcl:package.path
function s:F.deltcldir(plugdict, fdict)
    if has_key(a:fdict, 'imported')
        let s:addedpaths[a:fdict.imported]-=1
        if s:addedpaths[a:fdict.imported]<=0
            unlet s:addedpaths[a:fdict.imported]
            tcl set auto_path
                        \ [lreplace $auto_path
                        \ {*}[lrepeat 2
                        \ [lsearch -exact $auto_path
                        \ [::vim::expr 'a:fdict.imported']]]] ; list
        endif
    endif
endfunction
"▶2 register feature
call s:_f.newfeature('addtclpath', {'register': s:F.addtcldir,
            \                      'unloadpre': s:F.deltcldir,})
"▶1
call frawor#Lockvar(s:, 'addedpaths')
" vim: fmr=▶,▲ sw=4 ts=4 sts=4 et tw=80
