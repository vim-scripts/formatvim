"▶1 Header
scriptencoding utf-8
execute frawor#Setup('0.0', {'@/resources': '0.0'})
let s:F.base64={}
"▶1 and                :: UInt, UInt → UInt
if exists('*and')
    let s:F.and=function('and')
else
    function s:F.and(v1, v2)
        let [v1, v2]=[a:v1, a:v2]
        let list=[]
        while v1 || v2
            let [nv1, nv2]=[v1/2, v2/2]
            call add(list, ((nv1*2!=v1)&&(nv2*2!=v2)))
            let [v1, v2]=[nv1, nv2]
        endwhile
        let r=0
        while !empty(list)
            let r=(r*2) + remove(list, -1)
        endwhile
        return r
    endfunction
endif
"▶1 or                 :: UInt, UInt → UInt
if exists('*or')
    let s:F.or=function('or')
else
    function s:F.or(v1, v2)
        let [v1, v2]=[a:v1, a:v2]
        let list=[]
        while v1 || v2
            let [nv1, nv2]=[v1/2, v2/2]
            call add(list, ((nv1*2!=v1)||(nv2*2!=v2)))
            let [v1, v2]=[nv1, nv2]
        endwhile
        let r=0
        while !empty(list)
            let r=(r*2) + remove(list, -1)
        endwhile
        return r
    endfunction
endif
"▶1 base64.decode      :: b64str[, bytearray::Bool] → str | bytearray
let s:cd64=map(split('|$$$}rstuvwxyz{$$$$$$$>?@ABCDEFGHIJKLMNOPQRSTUVW$$$$$$XYZ[\]^_`abcdefghijklmnopq',
            \              '\v.@='),
            \        'char2nr(v:val)')
function s:F.base64.decode(str, ...)
    let str=map(split(substitute(a:str, '[^a-zA-Z0-9+/]', '', 'g'), '\v.@='),
                \'char2nr(v:val)')+[-1]
    let in=repeat([0], 4)
    let v=0
    let len=0
    let i=0
    let bytearray=(a:0 && a:1)
    if bytearray
        let r=[]
    else
        let r=''
    endif
    while !empty(str)
        let i=0
        let len=0
        while i<4 && !empty(str)
            let v=0
            while !empty(str) && v==0
                let v=remove(str, 0)
                let v=(((v<43)||(v>122))?(0):(s:cd64[v-43]))
                if v
                    let v=((v==36)?(0):(v-61))
                endif
            endwhile
            if !empty(str)
                let len+=1
                if v
                    let in[i]=v-1
                endif
            else
                let in[i]=0
            endif
            let i+=1
        endwhile
        if len
            let out=[    s:F.or(        in[0]*4,         in[1]/16),
                        \s:F.or(        in[1]*16,        in[2]/4),
                        \s:F.or(s:F.and(in[2]*64, 0xC0), in[3])]
            call map(out, 's:F.and(v:val, 0xFF)')
            if bytearray
                let r+=out[:(len-2)]
            else
                let r.=join(map(out[:(len-2)],
                            \   'eval(printf(''"\x%02x"'', v:val))'),
                            \'')
            endif
        endif
    endwhile
    return r
endfunction
"▶1 base64.encode      :: str | bytearray → b64str
let s:eqsigncode=char2nr('=')
let s:cb64=map(split('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/',
            \        '\v.@='), 'char2nr(v:val)')
function s:F.base64.encode(str)
    let r=''
    let bytearray=(type(a:str)==type([]))
    let in=repeat([0], 3)
    let idx=0
    let slen=len(a:str)
    while idx<slen
        let len=0
        let i=0
        while i<3
            if idx<slen
                let cur=a:str[idx]
                if !bytearray
                    let cur=char2nr(cur)
                endif
                let in[i]=cur
                let len+=1
                let idx+=1
            else
                let in[i]=0
            endif
            let i+=1
        endwhile
        if len
            let out=[    s:cb64[in[0]/4],
                        \s:cb64[s:F.or(((s:F.and(in[0], 0x03))*16),
                        \              ((s:F.and(in[1], 0xF0))/16))],
                        \((len>1)?
                        \   (s:cb64[s:F.or(s:F.and(in[1], 0x0F)*4,
                        \                  s:F.and(in[2], 0xC0)/64)]):
                        \   (s:eqsigncode)),
                        \((len>2)?
                        \   (s:cb64[s:F.and(in[2], 0x3F)]):
                        \   (s:eqsigncode))]
            let r.=join(map(copy(out), 'eval(printf(''"\x%02x"'', v:val))'), '')
        endif
    endwhile
    return r
endfunction
"▶1 base64.encodelines :: [string] → b64str
function s:F.base64.encodelines(lines)
    let bytes=[]
    let i=0
    let lls=len(a:lines)
    while i<lls
        let j=0
        let ll=len(a:lines[i])
        while j<ll
            let byte=char2nr(a:lines[i][j])
            if byte==10 " NL
                call add(bytes, 0)
            else
                call add(bytes, byte)
            endif
            let j+=1
        endwhile
        call add(bytes, 10)
        let i+=1
    endwhile
    call remove(bytes, -1) " Remove last NL
    return s:F.base64.encode(bytes)
endfunction
"▶1 base64.decodelines :: b64str → [string]
function s:F.base64.decodelines(b64str)
    let r=['']
    for byte in s:F.base64.decode(a:b64str, 1)
        if byte==10
            call add(r, '')
        elseif byte==0
            let r[-1].="\n"
        else
            let r[-1].=eval(printf('"\x%02x"', byte))
        endif
    endfor
    return r
endfunction
"▶1 post resource
call s:_f.postresource('base64', s:F.base64)
"▶1
call frawor#Lockvar(s:, '')
" vim: fmr=▶,▲ sw=4 ts=4 sts=4 et tw=80
