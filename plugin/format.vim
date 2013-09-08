"▶1 Начало
scriptencoding utf-8
execute frawor#Setup('4.0', {'@/commands': '0.0',
            \               '@/functions': '0.1',})
call s:_f.command.add('Format', {'function': ['@%format', [2,0], 'cmd']},
            \                  {'complete': {
            \                       'function': ['@%format', [2,0], 'comp']},
            \                   'nargs': '+',
            \                   'range': '%',
            \                   'usedictcompsplitfunc': 1})
"▶1
call frawor#Lockvar(s:, '_f')
" vim: ft=vim:ts=8:fdm=marker:fenc=utf-8:fmr=▶,▲:tw=100
