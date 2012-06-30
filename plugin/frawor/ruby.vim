"▶1 Header
scriptencoding utf-8
execute frawor#Setup('0.0', {'plugin/frawor/os': '0.0',}, 1)
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
"▶1 s:hasruby
let s:hasruby=0
if (has('ruby') || has('ruby/dyn')) && exists(':ruby')==2
    try
        silent! ruby VIM::command('let s:hasruby=1')
    catch
    endtry
endif
if !s:hasruby
    finish
endif
"▶1 addrubydir feature
let s:addedpaths={}
"▶2 addrubydir :: {f} → + ruby:@INC
function s:F.addrubydir(plugdict, fdict)
    if empty(a:plugdict.runtimepath)
        return
    endif
    let dir=s:_r.os.path.join(a:plugdict.runtimepath, 'ruby')
    if s:_r.os.path.isdir(dir)
        if has_key(s:addedpaths, dir)
            let s:addedpaths[dir]+=1
        else
            let s:addedpaths[dir]=1
            ruby $LOAD_PATH << VIM::evaluate('dir')
        endif
        let a:fdict.imported=dir
    endif
endfunction
"▶2 delrubydir :: {f} → + ruby:@INC
function s:F.delrubydir(plugdict, fdict)
    if has_key(a:fdict, 'imported')
        let s:addedpaths[a:fdict.imported]-=1
        if s:addedpaths[a:fdict.imported]<=0
            unlet s:addedpaths[a:fdict.imported]
            ruby $LOAD_PATH.delete(VIM::evaluate('a:fdict.imported'))
        endif
    endif
endfunction
"▶2 register feature
call s:_f.newfeature('addrubypath', {'register': s:F.addrubydir,
            \                       'unloadpre': s:F.delrubydir,
            \                      'ignoredeps': 1,})
"▶1
call frawor#Lockvar(s:, 'addedpaths')
" vim: fmr=▶,▲ sw=4 ts=4 sts=4 et tw=80
