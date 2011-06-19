"▶1 Header
scriptencoding utf-8
if !exists('s:_pluginloaded')
    execute frawor#Setup('0.0', {'@/resources': '0.0'}, 0)
    finish
elseif s:_pluginloaded
    finish
endif
"▶1 strdisplaywidth  :: String, column → UInt
if exists('*strdisplaywidth')
    let s:F.strdisplaywidth=function('strdisplaywidth')
else
    function s:F.strdisplaywidth(str, col)
        let chars=split(a:str, '\v.@=')
        let curcol=a:col
        for char in chars
            if char[0] is# "\t"
                let curcol+=(&ts-curcol%&ts)
            else
                let charnr=char2nr(char[0])
                let curcol+=1+((0xFF00< charnr && charnr<=0xFF60) ||
                            \  (0xFFE0<=charnr && charnr<=0xFFE6) ||
                            \  charn==0x3000)
            endif
        endfor
        return curcol-a:col
    endfunction
endif
"▶1 printstr         :: len, String, col, align, hl → col + :echon
function s:F.printstr(len, str, col, align, hl)
    if a:hl isnot 0
        execute 'echohl' a:hl
    endif
    let width=s:F.strdisplaywidth(a:str, a:col)
    if width>=a:len
        echon a:str
        if a:hl isnot 0
            echohl NONE
        endif
        return width
    endif
    let spacenum=a:len-s:F.strdisplaywidth(a:str, a:col)
    if a:align is# 'left'
        echon a:str . repeat(' ', spacenum)
    elseif a:align is# 'right'
        echon repeat(' ', spacenum) . a:str
    else
        let lspn=spacenum/2
        let rspn=spacenum-lspn
        echon repeat(' ', lspn) . a:str . repeat(' ', rspn)
    endif
    if a:hl isnot 0
        echohl NONE
    endif
    return width+spacenum
endfunction
"▶1 printtline       :: cols, aligns, seps, lengths, hlgroups, colnum → + :echo
function s:F.printtline(columns, aligns, vseparators, lengths, hlgroups, colnum)
    let i=0
    let col=0
    while i<a:colnum
        let col+=s:F.printstr(get(a:lengths, i, 0), get(a:columns, i, ''), col,
                    \         get(a:aligns, i, 'left'), get(a:hlgroups, i, 0))
        let [separator, sephl]=get(a:vseparators, i, ['  ', 0])
        let col+=s:F.printstr(1, separator, col, 'center', sephl)
        let i+=1
    endwhile
    return col
endfunction
"▶1 printtable       :: lines[, opts] → + :echo
function s:F.printtable(lines, ...)
    let opts=get(a:000, 0, {})
    let lineswh=get(opts, 'header', [])+a:lines
    let colnum=max(map(copy(lineswh), 'len(v:val)'))
    if has_key(opts, 'vseparator')
        let vseparators=repeat([opts.vseparator], colnum-1)
    elseif has_key(opts, 'vseparators')
        let vseparators=copy(opts.vseparators)
    else
        let vseparators=[]
    endif
    call map(vseparators, 'type(v:val)=='.type('').'?[v:val, 0]:v:val')
    let lengths=[]
    let i=0
    let col=0
    while i<colnum
        call add(lengths, max(map(copy(lineswh),
                    \   '(i<len(v:val))?s:F.strdisplaywidth(v:val[i], col):0')))
        let col+=lengths[-1]
        let col+=s:F.strdisplaywidth(get(vseparators, i, ['  ', 0])[0], col)
        let i+=1
    endwhile
    " TODO split columns
    if has_key(opts, 'header')
        if has_key(opts, 'halign')
            let haligns=repeat([opts.halign], colnum)
        elseif has_key(opts, 'haligns')
            let haligns=opts.haligns
        else
            let haligns=[]
        endif
        echo ''
        execute 'echohl' get(opts, 'hhl', 'PreProc')
        let hvseparators=map(copy(vseparators), '[v:val[0], 0]')
        call s:F.printtline(opts.header, haligns, hvseparators, lengths,
                    \       get(opts, 'hhls', []), colnum)
        echohl NONE
    endif
    if has_key(opts, 'align')
        let aligns=repeat([opts.align], colnum)
    elseif has_key(opts, 'aligns')
        let aligns=opts.aligns
    else
        let aligns=[]
    endif
    if has_key(opts, 'hl')
        execute 'echohl' opts.hl
    endif
    for line in a:lines
        echo ''
        call s:F.printtline(line, aligns, vseparators, lengths,
                    \       get(opts, 'hls', []), colnum)
    endfor
    if has_key(opts, 'hl')
        echohl NONE
    endif
endfunction
"▶1 Register resource
call s:_f.postresource('printtable', s:F.printtable)
"▶1
call frawor#Lockvar(s:, '_pluginloaded')
" vim: fmr=▶,▲ sw=4 ts=4 sts=4 et tw=80
