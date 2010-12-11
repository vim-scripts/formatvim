function SetupTable(lines, columns)
    setlocal nolist
    setlocal buftype=nowrite
    for i in range(0, a:lines)
        for j in range(0, a:columns)
            let synname='L'.i.'C'.j
            let syncolor=i*(a:columns)+j
            let synreg='\%'.(i+1).'l\%'.(j+1).'c.'
            execute 'syntax match '.synname.' /'.synreg.'/'
            execute 'highlight '.synname.' ctermbg='.syncolor
        endfor
    endfor
    call setline(1, repeat([repeat(' ', a:columns)], a:lines)+[""])
    normal! G
endfunction
