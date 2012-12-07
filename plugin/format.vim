"▶1 Начало
scriptencoding utf-8
execute frawor#Setup('4.0', {'@/commands': '0.0',})
function s:F.cmd(...) abort
    call s:_f.require('@%format', [0, 0], 1)
    let s:F.cmd=s:_r.formatcmd
    lockvar! s:F s:_f s:_r
    return call(s:F.cmd, a:000, self)
endfunction
function s:F.cmdwrap(...)
    return call(s:F.cmd, a:000, self)
endfunction
let s:cmpcomprefs=                      'columns  in ["-1" "80" =string(&co) '.
            \                                        '=string(winwidth())] '.
            \                '?               to  path W '.
            \                '?      starttagreg _ '.
            \                '?        endtagreg _ '.
            \                '!           number '.
            \                '!   relativenumber '.
            \                '!             list '.
            \                '!+1           tags  in [local all] '.
            \((has('folding'))?
            \               ('!+1     foldcolumn  _ '.
            \                '!            folds '                    ):('')).
            \((has('signs'))?
            \               ('!            signs'                     ):('')).
            \((has('conceal'))?
            \               ('!+1      concealed  in [shown both] '   ):('')).
            \((has('statusline'))?
            \               ('!+1       progress  in [percent lines] '):(''))
let s:cmpformats='[key formats]'
let s:cmdcomplete=['<'.
            \((has('diff'))?
            \   ('diffformat ('.s:cmpformats.'{'.s:cmpcomprefs.'})'):
            \   ('')).
            \   '    format ('.s:cmpformats.'{'.s:cmpcomprefs.
            \           ((has('diff'))?(   '!+1  collapsfiller  _ '):('')).
            \           ((has('folding'))?('!         allfolds '   ):('')).'})'.
            \   '      list - '.
            \   'purgecolorcaches -'.
            \  '>']
unlet s:cmpformats s:cmpcomprefs
call s:_f.command.add('Format', s:F.cmdwrap,
            \                  {'complete': s:cmdcomplete,
            \                      'nargs': '+',
            \                      'range': '%',})
unlet s:cmdcomplete
unlet s:F.cmdwrap
"▶1
call frawor#Lockvar(s:, 'F,_f,_r')
" vim: ft=vim:ts=8:fdm=marker:fenc=utf-8:fmr=▶,▲:tw=100
