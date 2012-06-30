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
"▶1 s:hasperl
let s:hasperl=0
if (has('perl') || has('perl/dyn')) && exists(':perl')==2
    try
        silent! perl VIM::DoCommand('let s:hasperl=1')
    catch
    endtry
endif
if !s:hasperl
    finish
endif
"▶1 addperldir feature
let s:addedpaths={}
"▶2 addperldir :: {f} → + perl:@INC
function s:F.addperldir(plugdict, fdict)
    if empty(a:plugdict.runtimepath)
        return
    endif
    let dir=s:_r.os.path.join(a:plugdict.runtimepath, 'perl')
    if s:_r.os.path.isdir(dir)
        if has_key(s:addedpaths, dir)
            let s:addedpaths[dir]+=1
        else
            let s:addedpaths[dir]=1
            perl push @INC, [VIM::Eval('dir')]->[1];
        endif
        let a:fdict.imported=dir
    endif
endfunction
"▶2 delperldir :: {f} → + perl:@INC
function s:F.delperldir(plugdict, fdict)
    if has_key(a:fdict, 'imported')
        let s:addedpaths[a:fdict.imported]-=1
        if s:addedpaths[a:fdict.imported]<=0
            unlet s:addedpaths[a:fdict.imported]
            perl @INC=(grep {$_ ne VIM::Eval('a:fdict.imported')} @INC);
        endif
    endif
endfunction
"▶2 register feature
call s:_f.newfeature('addperlpath', {'register': s:F.addperldir,
            \                       'unloadpre': s:F.delperldir,
            \                      'ignoredeps': 1,})
"▶1
call frawor#Lockvar(s:, 'addedpaths')
" vim: fmr=▶,▲ sw=4 ts=4 sts=4 et tw=80
