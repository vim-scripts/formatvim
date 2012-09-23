#!/usr/bin/vim -S
" ENVIRONMENT VARIBLES USED:
"   CT_LINES    Number of lines to show
"   CT_COLUMNS  Number of columns to show
"       If you use one of the above number of colors shown is 
"       CT_LINES*CT_COLUMNS
"
"   CT_AUTO     Number of colors to show. Lines and columns are determined 
"               automatically.
"   CT_TEMP     Name of the image to save file to.
"   CT_WINNID   Current window number.
"   CT_NOXDO    If non-empty, vim won’t use xdotool.
set nocompatible
set viminfo=
hi A ctermbg=White
hi B ctermbg=Black
function SetupTable(lines, columns)
    setlocal nolist
    setlocal buftype=nowrite
    for i in range(2, a:lines+2)
        for j in range(2, a:columns+2)
            let synname='L'.i.'C'.j
            let syncolor=(i-2)*(a:columns)+(j-2)
            let synreg='\%'.(i+1).'l\%'.(j+1).'c.'
            execute 'syntax match '.synname.' /'.synreg.'/'
            execute 'highlight '.synname.' ctermbg='.syncolor
        endfor
    endfor
    syn match A /\%1l.$/
    syn match B /\%2l.$/
    syn match A /^.\ze.$/
    syn match B /^.\zs.$/
    syn match A /\v(%1l%1c|%2l%2c|%1l%3c|%3l%1c|%2l%4c|%4l%2c)./
    syn match B /\v(%1l%2c|%2l%1c|%2l%3c|%3l%2c|%1l%4c|%4l%1c)./
    call setline(1, repeat([repeat(' ', a:columns+3)], a:lines+2)+["  ", ""])
    normal! G
endfunction
if !empty($CT_LINES.$CT_COLUMNS)
    call SetupTable(empty($CT_LINES)   ? 16 : ($CT_LINES),
                \   empty($CT_COLUMNS) ? 16 : ($CT_COLUMNS))
else
    let colnum=+$CT_AUTO
    let width=winwidth(0)
    let height=winheight(0)-4
    while height>=2
        if colnum%height == 0
            let newwidth=colnum/height
            if newwidth<width && newwidth>=2
                let width=colnum/height
                break
            endif
        endif
        let height-=1
    endwhile
    if height>=2 && width>=2
        call SetupTable(height, width)
    else
        cquit
    endif
    if empty($CT_TEMP)
        let temp='/tmp/colortable.png'
    else
        let temp=$CT_TEMP
    endif
    if !empty($CT_WINID)
        let winid=+$CT_WINID
    elseif executable('xdotool') && empty($CT_NOXDO)
        let winid=+system('xdotool getwindowfocus')
    endif
    redraw!
    if exists('winid')
        call system('import -format png -window '.winid.' '.temp)
    else
        call system('import -format png '.temp)
    endif
    qall!
endif
