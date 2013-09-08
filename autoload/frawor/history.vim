"▶1 Header
scriptencoding utf-8
execute frawor#Setup('0.0', {'@/resources': '0.0',
            \     '@/decorators/altervars': '0.0',})
let s:history={}
"▶1 history.get :: htype + history → [String]
function s:history.get(htype)
    let r=[]
    let i=1
    let lasthist=histnr(a:htype)
    while i<=lasthist
        let histline=histget(a:htype, i)
        if !empty(histline)
            call add(r, histline)
        endif
        let i+=1
    endwhile
    return r
endfunction
"▶1 history.clear :: htype → + history
let s:history.clear=function('histdel')
"▶1 history.set :: htype, [String] → + history
function s:history.set(htype, histlines)
    call s:history.clear(a:htype)
    let i=0
    let lhistlines=len(a:histlines)
    while i<lhistlines
        call histadd(a:htype, a:histlines[i])
        let i+=1
    endwhile
endfunction
"▶1 Post resource
call s:_f.postresource('history', s:history)
"▶1 Create altspecial
let s:histtypes=['input', '@', 'expr', '=', 'cmd', ':', 'search', '/']
function s:F.histchecker(arg)
    return index(s:histtypes, a:arg[0])!=-1
endfunction
function s:F.histset(histlines, htype)
    return s:history.set(a:htype, a:histlines)
endfunction
call s:_f.addaltspecial('history', s:history.get, s:F.histset,
            \           {'requiresarg': 1, 'checker': s:F.histchecker,})
"▶1
call frawor#Lockvar(s:, '')
" vim: fmr=▶,▲ sw=4 ts=4 sts=4 et tw=80
