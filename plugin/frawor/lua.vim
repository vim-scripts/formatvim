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
"▶1 s:haslua
let s:haslua=0
if (has('lua') || has('lua/dyn')) && exists(':lua')==2
    try
        silent! lua vim.command('let s:haslua=1')
    catch
    endtry
endif
if !s:haslua
    finish
endif
"▶1 addluadir feature
let s:addedpaths={}
"▶2 addluadir :: {f} → + lua:package.path
function s:F.addluadir(plugdict, fdict)
    if empty(a:plugdict.runtimepath)
        return
    endif
    let dir=s:_r.os.path.join(a:plugdict.runtimepath, 'lua')
    if s:_r.os.path.isdir(dir)
        let dir=escape(dir, ';?')
        let pathstr=';'.s:_r.os.path.join(dir, '?.lua').';'.
                    \   s:_r.os.path.join(dir, '?', 'init.lua')
        if has_key(s:addedpaths, dir)
            let s:addedpaths[dir]+=1
        else
            let s:addedpaths[dir]=1
            lua package.path=package.path..vim.eval('pathstr')
        endif
        let a:fdict.imported=dir
        let a:fdict.pathstr=pathstr
    endif
endfunction
"▶2 delluadir :: {f} → + lua:package.path
function s:F.delluadir(plugdict, fdict)
    if has_key(a:fdict, 'imported')
        let s:addedpaths[a:fdict.imported]-=1
        if s:addedpaths[a:fdict.imported]<=0
            unlet s:addedpaths[a:fdict.imported]
            let ppath=[]
            lua vim.eval('add(ppath,'..string.format('%q', package.path)..')')
            let importidx=stridx(ppath[0], a:fdict.pathstr)
            let importendidx=importidx+len(a:fdict.pathstr)
            let ppath[0]=((importidx>0)?(ppath[0][:(importidx-1)]):('')).
                        \ppath[0][(importendidx+1):]
            lua package.path=vim.eval('ppath[0]')
        endif
    endif
endfunction
"▶2 register feature
call s:_f.newfeature('addluapath', {'register': s:F.addluadir,
            \                      'unloadpre': s:F.delluadir,
            \                     'ignoredeps': 1,})
"▶1
call frawor#Lockvar(s:, 'addedpaths')
" vim: fmr=▶,▲ sw=4 ts=4 sts=4 et tw=80
