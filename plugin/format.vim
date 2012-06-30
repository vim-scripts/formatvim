"▶1 Начало
scriptencoding utf-8
if !exists('s:_pluginloaded')
    execute frawor#Setup('3.0', {'@/resources': '0.0',
                \                 '@/commands': '0.0',
                \                '@/functions': '0.0',
                \                  '@/options': '0.0',
                \                       '@/os': '0.0',
                \                      '@/fwc': '0.0',
                \     '@/decorators/altervars': '0.0',
                \                   '@/base64': '0.0',}, 0)
    let s:cmd={}
    let s:cmdcomplete=[]
    call FraworLoad('@/commands')
    call FraworLoad('@/functions')
    call s:_f.command.add('Format', s:cmd, {'complete': s:cmdcomplete,
                \                              'nargs': '+',
                \                              'range': '%',})
    finish
elseif s:_pluginloaded
    finish
endif
let s:formats={}
let s:keylist=['begin', 'sbsdstart', 'sbsdsep', 'foldstart', 'linestart',
            \  'foldcolumn', 'sign', 'clstart', 'linenr',
            \  'tagstart', 'line', 'concealed', 'tagend',
            \  'fold', 'difffiller', 'collapsedfiller',
            \  'clend', 'lineend', 'foldend', 'sbsdend', 'end',
            \  'style']
"▶1 Options
let s:checkreg='(#nomagicchg not match /\\[vVmM]/ #^ |=("\\V".@.@) isreg)'
let s:_options={
            \   'DefaultFormat': {'default': 'html',
            \                     'checker': 'key s:formats',},
            \  'KeepColorCache': {'default':  1,  'filter': 'bool',},
            \    'IgnoreCursor': {'default':  1,  'filter': 'bool'},
            \     'IgnoreFolds': {'default':  0,  'filter': 'bool'},
            \      'IgnoreList': {'default':  0,  'filter': 'bool'},
            \        'AllFolds': {'default':  0,  'filter': 'bool'},
            \     'IgnoreSigns': {'default':  0,  'filter': 'bool'},
            \      'IgnoreTags': {'default':  1, 'checker': 'range  0  2' },
            \    'ShowProgress': {'default':  0, 'checker': 'range  0  2' },
            \   'CollapsFiller': {'default':  0, 'checker': 'range  0 inf'},
            \        'NoLineNR': {'default': -1, 'checker': 'range -1  1' },
            \  'RelativeNumber': {'default': -1, 'checker': 'range -1  1' },
            \      'FoldColumn': {'default': -1, 'checker': 'range -1 inf'},
            \      'MaxDupTags': {'default':  5, 'checker': 'range  0 inf'},
            \ 'FormatConcealed': {'default':  1, 'checker': 'range  0  2' },
            \     'StartTagReg': {'default':  0, 'checker': s:checkreg    },
            \       'EndTagReg': {'default':  0, 'checker': s:checkreg    },
            \       'ColorFile': {'default':  0,
            \                      'scopes': 'g',
            \                     'checker': 'either (is=(0) path)'},
            \'AddTagCmdEscapes': {'default': '[]*.~',
            \                     'checker': 'type string'},
        \}
"▶1 Выводимые сообщения
let s:_messages={
            \   'misskey': 'Required key is missing: %s',
            \   'synnsup': 'I wonder, why do you need this plugin: '.
            \              'this vim is compiled without syntax support',
            \   'misscol': 'File with colors list not found, '.
            \              'see format-opt-ColorFile',
            \    'exists': 'Format already exists',
            \   'upcspec': 'Undefined %%. sequence: %%%s',
            \'nomagicchg': 'Changing magic state is not allowed',
        \}
"▶1 *strlen
let s:F.stuf={}
"▶2 stuf.strlen
if exists('*strchars')
    let s:F.stuf.strlen=function('strchars')
else
    function s:F.stuf.strlen(str)
        return len(split(a:str, '\v.@='))
    endfunction
endif
"▶2 stuf.htmlstrlen
function s:F.stuf.htmlstrlen(str)
    let str=a:str
    let str=substitute(str, '\m<.\{-}>', '', 'g')
    let str=substitute(str, '\m&[^;]\+;\|.', '.', 'g')
    return len(str)
endfunction
"▶2 stuf.bbstrlen
function s:F.stuf.bbstrlen(str)
    let str=a:str
    let str=substitute(str, '\m\[.\{-}\]', '', 'g')
    let str=substitute(str, '\m&[^;]\+;\|.', '.', 'g')
    return len(str)
endfunction
"▶1 squote
function s:F.squote(str)
    return substitute(string(a:str), "\n", '''."\\n".''', 'g')
endfunction
"▶1 getexpr
"▶2 s:colors
if has('gui_running')
    let s:whatterm = 'gui'
    augroup FormatRedrawProgress
        autocmd VimResized * call s:F.redrawprogress()
    augroup END
    let s:_augroups+=['FormatRedrawProgress']
else
    let s:whatterm = 'cterm'
    let s:colorfile=s:_f.getoption('ColorFile')
    if type(s:colorfile)!=type('')
        let s:colorfile=fnamemodify(expand('<sfile>:h:h'), ':p')
        let s:colorfile=s:_r.os.path.join(expand('<sfile>:p:h:h'), 'config',
                    \                     'formatvim',
                    \                     'colors-default-'.&t_Co.'.yaml')
        if !filereadable(s:colorfile)
            let s:colorfile=s:_r.os.path.join(expand('<sfile>:p:h:h'), 'config',
                        \                     'formatvim',
                        \                     'colors-default.yaml')
        endif
    endif
    if !filereadable(s:colorfile)
        call s:_f.warn('misscol')
    else
        let s:colors=map(filter(readfile(s:colorfile, 'b'), 'v:val[:1]==#"- "'),
                    \    'v:val[3:9]')
    endif
endif
"▶2 s:fmtexpressions
let s:fmtexpressions={
            \ 'f': '@fgcolor@',
            \ 'b': '@bgcolor@',
            \ 'S': '@styleid@',
            \'.S': '@&styleid@',
            \ 'N': '@-@',
            \ 'C': '@.@',
            \ ':': '@:@',
            \ '%': "'%'",
            \ '@': "'@'",
            \ '~': '@_difffillchar@',
            \'.~': '@_foldfillchar@',
            \ '-': 'repeat(@_difffillchar@, ((@_columns@)-(@=@)))',
            \'.-': 'repeat(@_foldfillchar@, ((@_columns@)-(@=@)))',
            \ '|': '@_vertseparator@',
        \}
"▶2 s:fcompexpressions
let s:fcompexpressions={
            \ '#': "'((@_donr@ || @_dornr@)?".
            \        "(repeat('.s:F.squote(a:opts.leadingspace).', ".
            \                "@_linenumlen@-len(@@@)).@@@):".
            \        "(''''))'",
            \ '+': "'repeat('.s:F.squote(a:opts.leadingspace).', (".
            \              "(@_columns@)-(@=@)))'",
            \ '_': "'((@_donr@ || @_dornr@)?".
            \        "(repeat('.s:F.squote(a:opts.leadingspace).', ".
            \                "@_linenumlen@)):".
            \        "(''''))'",
            \ ' ': "s:F.squote(a:opts.leadingspace)",
            \ '^': "'((a:opts.donr || a:opts.dornr)?('.".
            \       "s:F.squote(a:opts.leadingspace).'):".
            \       "(''''))'",
            \ 's': "a:opts.strescape",
            \'.s': "substitute(a:opts.strescape, '\\V@@@', '@?@', 'g')",
        \}
"▲2
function s:F.getexpr(str, opts)
    let fkey=matchstr(a:str, '\v\.?.')
    "▶2 Простые выражения (%f, %b, %*S, %N, %C, %:, %%, %@, %*~, %*-, %|)
    if has_key(s:fmtexpressions, fkey)
        return [len(fkey), s:fmtexpressions[fkey]]
    "▶2 Сложные выражения (%#, %_, %<SPACE>, %^, %*s)
    elseif has_key(s:fcompexpressions, fkey)
        return [len(fkey), eval(s:fcompexpressions[fkey])]
    "▶2 %={expr}=%
    elseif fkey is# '='
        let str=matchstr(a:str, '\v^([^\\%]|\\.){-}(\=\%)@=', 1)
        let shift=3+len(str)
        let str=substitute(str, '\m\\\([\\%]\)', '\1', 'g')
        return [shift, str]
    "▶2 %'{expr}'%
    elseif fkey is# "'"
        let str=matchstr(a:str, '\v^.{-}(\''\%)@=', 1)
        let shift=3+len(str)
        return [shift, str]
    "▶2 %>{expr}
    elseif fkey is# '>'
        return [len(a:str), a:str[1:]]
    "▶2 Остальные %*
    else
        call s:_f.throw('upcspec', a:str)
    endif
endfunction
"▶1 increq
function s:F.inqreq(req, key)
    if a:req isnot 0
        let a:req[a:key]=get(a:req, a:key, 0)+1
    endif
endfunction
"▶1 getats
let s:atargs={
            \'@': ['str', "''", 'begin', 'end', 'sbsdstart', 'sbsdsep',
            \      'sbsdend', 'clstart', 'clend'],
            \'-': ['line', 0, 'begin', 'style'],
            \'.': ['char', 0, 'linestart', 'linenr', 'fold',
            \      'collapsedfiller', 'begin', 'end', 'sbsdstart', 'style',
            \      'clstart', 'clend'],
            \'?': ['concealed', "''"]+filter(copy(s:keylist),
            \                                'v:val isnot# "concealed"'),
        \}
let s:constopts=['leadingspace', 'strescape']
function s:F.getats(str, opts, req, key, atargs)
    let r=''
    let str=a:str
    while !empty(str)
        let atidx=stridx(str, '@')
        if atidx==-1
            let r.=str
            break
        elseif atidx!=0
            let r.=str[:(atidx-1)]
        endif
        let str=str[(atidx+1):]
        let atv=str[0]
        if has_key(s:atargs, atv) && str[1] is# '@'
            if index(s:atargs[atv], a:key, 2)==-1
                let arg=a:atargs[s:atargs[atv][0]]
            else
                let arg=s:atargs[atv][1]
            endif
            let str=str[2:]
        elseif atv=~#'\v^\l'
            let arg=matchstr(str, '\v^\l+%(\@)@=')
            if empty(arg)
                unlet arg
            else
                let str=str[len(arg)+1:]
                call s:F.inqreq(a:req, 'a:spec')
                let arg=a:atargs.spec.'[0].'.arg
            endif
        elseif atv is# '=' && str[1] is# '@'
            call s:F.inqreq(a:req, '=')
            call s:F.inqreq(a:req, 'a:cur')
            call s:F.inqreq(a:req, 'a:opts')
            call s:F.inqreq(a:req, 'a:opts.strlen')
            let r=substitute(r, '\v%(^|\''@<=\.)(%(%(\''\.)@!.)*)',
                        \    '\n    let str.=\1'.a:atargs.opts.
                        \                   '.strlen('.a:atargs.cur.'.str)', '')
            let arg=''
            let str=str[2:]
        elseif atv is# '_'
            let arg=matchstr(str, '\v^\l+%(\@)@=', 1)
            if empty(arg)
                unlet arg
            else
                let str=str[len(arg)+2:]
                if (a:req is 0 && (type(a:opts[arg])==type('') ||
                            \      type(a:opts[arg])==type(0)))
                            \  || index(s:constopts, arg)!=-1
                    let arg=string(a:opts[arg])
                else
                    call s:F.inqreq(a:req, 'a:opts')
                    let arg=(a:atargs.opts).'.'.arg
                endif
            endif
        elseif atv is# '~' || (atv is# '^' && a:key isnot# 'concealed')
            let arg=a:atargs.spec.'[0]'
            call s:F.inqreq(a:req, 'a:spec')
            let str=str[2:]
        elseif atv is# '^'
            let arg=a:atargs.cspec.'[0]'
            call s:F.inqreq(a:req, 'a:cspec')
            let str=str[2:]
        elseif atv is# ':' || (atv is# '&' && a:key isnot# 'concealed' &&
                    \          str[1] is# '@')
            if a:key is# 'begin' || a:key is# 'end'
                let arg=a:atargs.style
            else
                let arg=a:atargs.spec.'[1]'
                call s:F.inqreq(a:req, 'a:spec')
            endif
            let str=str[2:]
        elseif atv is# '&' && str[1] is# '@'
            let arg=a:atargs.cspec.'[1]'
            call s:F.inqreq(a:req, 'a:cspec')
            let str=str[2:]
        elseif atv is# '&'
            let arg=matchstr(str, '\v^\l+%(\@)@=', 1)
            if empty(arg)
                unlet arg
            else
                let spec=a:atargs[((a:key is# 'concealed')?('cspec'):('spec'))].
                            \'[0]'
                let str=str[len(arg)+2:]
                call s:F.inqreq(a:req, spec)
                let arg=spec.'.'.arg
            endif
        endif
        if exists('arg')
            if arg[0] is# 'a'
                call s:F.inqreq(a:req, arg)
            endif
            let r.=arg
            unlet arg
        else
            let r.='@'
        endif
    endwhile
    return r
endfunction
"▶1 procpc
function s:F.procpc(str, opts, key, req, atargs)
    let str=a:str
    "▶2 Process %*
    let chunks=[]
    while !empty(str)
        let pidx=stridx(str, '%')
        if pidx==-1
            call add(chunks, string(str))
            break
        elseif pidx!=0
            call add(chunks, string(str[:(pidx-1)]))
        endif
        let str=str[(pidx+1):]
        let [shift, chunk]=s:F.getexpr(str, a:opts)
        call add(chunks, s:F.getats(chunk, a:opts, a:req, a:key, a:atargs))
        let str=str[(shift):]
    endwhile
    "▶2 Join chunks
    let prevchar=0
    let expr=''
    while !empty(chunks)
        let chunk=remove(chunks, 0)
        if empty(chunk) || chunk is# '""' || chunk is# "''"
            continue
        endif
        let firstchar=chunk[0]
        if (prevchar is# "'" || prevchar is# '"') && firstchar is# prevchar
            let chunk=chunk[1:]
            let expr=expr[:-3]
        endif
        let expr.=chunk.'.'
        let prevchar=chunk[-1:]
    endwhile
    let expr=expr[:-2]
    if a:req isnot 0 && has_key(a:req, '=')
        let expr=substitute(expr, '\V.\n\@=', '', 'g')
    endif
    "▲2
    return expr
endfunction
"▶1 ftmcompile
"▶2 Create list of arguments
let s:keyargslist=['str', 'spec', 'line', 'char', 'cur', 'opts', 'style',
            \      'concealed', 'cspec']
let s:keynoargs={'str': s:atargs['@'][2:],
            \   'line': s:atargs['-'][2:],
            \   'char': s:atargs['.'][2:],
            \  'cspec': s:atargs['?'][2:],
            \  'style': filter(copy(s:keylist), 'v:val isnot# "begin" && '.
            \                                   'v:val isnot# "end"')}
let s:keynoargs.concealed=s:keynoargs.cspec
let s:keyargs={}
for s:key in s:keylist
    let s:keyargs[s:key]=[]
    for s:arg in s:keyargslist
        if has_key(s:keynoargs, s:arg) && index(s:keynoargs[s:arg], s:key)!=-1
            continue
        endif
        let s:keyargs[s:key]+=[s:arg]
    endfor
endfor
let s:defatargs={}
call map(s:keyargslist, 'extend(s:defatargs, {v:val : "a:".v:val})')
unlet s:key s:arg s:keyargslist s:keynoargs
"▲2
function s:F.fmtcompile(str, opts, key)
    let r={'req': {}, 'isexpr': 1, 'str': a:str}
    let str=a:str
    "▶2 %!
    if str[0:1] is# '%!'
        let cmd=matchstr(str, '\v.{-}%(\!\%)@=', 2)
        let str=str[(4+len(cmd)):]
        let cmd=s:F.getats(cmd, a:opts, r.req, a:key, s:defatargs)
        let r.isexpr=0
    endif
    "▲2
    let args=join(s:keyargs[a:key], ', ')
    let funstr='function r.f('.args.")\n    "
    if exists('cmd')
        let funstr.=cmd."\n    "
    endif
    let expr=s:F.procpc(str, a:opts, a:key, r.req, s:defatargs)."\n"
    let r.isconst=empty(filter(keys(r.req), 'v:val[0:5] isnot# "a:opts"'))
    if has_key(r.req, '=')
        let funstr.='let str='.expr."\n    return str"
        let r.isexpr=0
    else
        let funstr.='return '.expr
    endif
    let funstr.="\nendfunction"
    execute funstr
    return r
endfunction
"▶1 fmtprepare
function s:F.fmtprepare(format, startline, endline, options)
    "▶2 s:F.getcolor
    if !has_key(s:F, 'getcolor')
        if s:whatterm is# 'gui'
            function s:F.getcolor(color)
                return a:color
            endfunction
        else
            function s:F.getcolor(color)
                if a:color!~#'\v^\d+$'
                    return ''
                endif
                return get(s:colors, a:color, '')
            endfunction
        endif
    endif
    "▶2 opts
    let opts={}
    let opts.strlen=get(a:format, 'strlen', s:F.stuf.strlen)
    let opts.strescape=get(a:format, 'strescape', '@@@')
    let opts.leadingspace=eval(substitute(opts.strescape, '@@@', '" "', 'g'))
    let id=hlID('Normal')
    let opts.fgcolor=s:F.getcolor(synIDattr(id, 'fg#', s:whatterm))
    let opts.bgcolor=s:F.getcolor(synIDattr(id, 'bg#', s:whatterm))
    if opts.fgcolor==''
        let opts.fgcolor=((&background is# 'dark')?('#ffffff'):('#000000'))
    endif
    if opts.bgcolor==''
        let opts.bgcolor=((&background is# 'dark')?('#000000'):('#ffffff'))
    endif
    "▶2 «Компиляция» некоторых ключей
    let cformat={}
    for key in s:keylist
        if has_key(a:format, key)
            let cformat[key]=s:F.fmtcompile(a:format[key], opts, key)
            lockvar! cformat[key]
        endif
    endfor
    "▲2
    let cformat.opts=opts
    " Здесь содержится список определённых стилей
    let cformat.cache={}
    " Строка, в которой содержатся сами стили
    let cformat.stylestr=''
    "▶2 Блокировки
    lockvar! cformat.opts
    "▲2
    return cformat
endfunction
"▶1 s:formats
"▶2 HTML
let s:escapehtml="substitute(".
            \     "substitute(".
            \      "substitute(".
            \        "substitute(@@@, '\\V&', '\\&amp;', 'g'), ".
            \       "'\"', '\\&#34;', 'g'), ".
            \      "'<', '\\&lt;', 'g'), ".
            \     "'>', '\\&gt;', 'g')"
let s:htmlstylestr='((@inverse@)?'.
            \             '("color: ".'.
            \              '((@bgcolor@!=#"")?'.
            \                '(@bgcolor@):'.
            \                '(@_bgcolor@))."; background-color: ".'.
            \              '((@fgcolor@!=#"")?'.
            \                '(@fgcolor@):'.
            \                '(@_fgcolor@))."; "):'.
            \             '(((@fgcolor@!=#"")?'.
            \               '("color: ".@fgcolor@."; "):'.
            \               '("color: ".@_fgcolor@."; ")).'.
            \              '((@bgcolor@!=#"")?'.
            \               '("background-color: ".@bgcolor@."; "):'.
            \               '("background-color: ".@_bgcolor@."; ")))).'.
            \           '((@bold@)?'.
            \             '("font-weight: bold; "):'.
            \             '("")).'.
            \           '((@italic@)?'.
            \             '("font-style: italic; "):'.
            \             '("")).'.
            \           '((@underline@)?'.
        \             '("text-decoration: underline; "):'.
            \             '(""))'
let s:stylelist=['Line', 'Fold', 'DiffFiller', 'CollapsedFiller']
let s:formats.html={
            \'style':        '%>((@styleid@!=#"")?'.
            \                   '(".s".@styleid@." {".'.
            \                     s:htmlstylestr.
            \                   '."} "):'.
            \                   '(""))',
            \'begin':        "<!DOCTYPE html><html>".
            \                '<head>'.
            \                '<meta http-equiv="content-type" '.
            \                       'content="text/html; charset=utf-8" />'.
            \                '<meta name="generator" content="format.vim" />'.
            \                '<style type="text/css"> '.
            \                'body { font-family: monospace; '.
            \                        'white-space: nowrap; '.
            \                        'margin: 0; padding: 0; border: 0;  '.
            \                        'color: %''@_fgcolor@''%; '.
            \                        'background-color: %''@_bgcolor@''% } '.
            \                'p { margin: 0; padding: 0; border: 0; '.
            \                    'color: %''@_fgcolor@''%; '.
            \                    'background-color: %''@_bgcolor@''%; '.
            \                    'text-indent: 0; } '.
            \                'div { margin: 0; padding: 0; border: 0; '.
            \                      'color: %''@_fgcolor@''%; '.
            \                      'background-color: %''@_bgcolor@''% '.
            \                      'white-space: pre; } '.
            \                '.open-fold   > .fulltext { display: block; }'.
            \                '.closed-fold > .fulltext { display: none;  }'.
            \                '.open-fold   > .toggle-open   {display: none; }'.
            \                '.open-fold   > .toggle-closed {display: block;}'.
            \                '.closed-fold > .toggle-open   {display: block;}'.
            \                '.closed-fold > .toggle-closed {display: none; }'.
            \                '.closed-fold:hover > .fulltext{display: block;}'.
            \                '.closed-fold:hover > .toggle-filler '.
            \                                              '{display: none;}'.
            \                '.Sign { width: 2.5ex; } '.
            \                'span.Sign { display: inline-block; } '.
            \                '.Sign > image { max-width: 100%%; }'.
            \                '.Present { display: none; }'.
            \                '.Line { position: relative; zoom: 1; '.
            \                        'white-space: pre; }'.
            \                'input { display: inline; '.
            \                        'padding: 0; margin: 0; '.
            \                        'border: 0; background: none; '.
            \                        'font-family: monospace; '.
            \                        'font-size: 100%%; '.
            \                        'pointer-events: none; '.
            \                        'height: 100%%; }'.
            \                '.Line { min-height: 1em; } '.
            \                '.Line:hover .Shown { display: none; }'.
            \                '.Line:hover .Present { display: inline; }'.
            \                '.s%''hlID("Conceal")''% { font-weight: normal; '.
            \                                          'font-style: normal; '.
            \                                          'text-decoration: none;'.
            \                                        '}'.
            \                '%''((@_allfolds@)?'.
            \                    '(".Fold {display:none;}"):'.
            \                    '("")).'.
            \                   '((@_sbsd@)?'.
            \                    '("table, tr, td { margin: 0; '.
            \                                      'padding: 0; '.
            \                                      'border: 0; } '.
            \                     '.SbSDSep { color: ".@_bgcolor@."; '.
            \                                'background-color:".@_fgcolor@.";'.
            \                               '} "):'.
            \                    '(""))''%'.
            \                '%:</style>'.
            \                '<title>%'''.substitute(s:escapehtml, '\V@@@',
            \                                        'expand("%:p:\~%")', '').
            \                '''%</title>'.
            \                '%''((@_allfolds@)?('''.
            \                   '<script type="text/javascript">'.
            \                       'function toggleFold(objID) {'.
            \                           'var fold;'.
            \                           'fold=document.getElementById(objID);'.
            \                           'if(fold.className=="closed-fold")'.
            \                               '{fold.className="open-fold";}'.
            \                           'else {fold.className="closed-fold";}'.
            \                  '}</script>'''.
            \                '):(""))''%'.
            \                '</head><body class="s%S">'.
            \                '%''((@_sbsd@)?("<table cellpadding=\"0\" '.
            \                       'cellspacing=\"0\">"):(""))''%',
            \'end':          '%''((@_sbsd@)?("</table>"):(""))''%'.
            \                '</body></html>',
            \'linestart':    '<p class="s%S %''s:stylelist[@@@]''%"'.
            \                  '%''((@@@<=1)?'.
            \                       '(" id=\"".'.
            \                        '((@@@==0)?'.
            \                            '("line"):'.
            \                            '("fold")).'.
            \                        '@-@."-".@_sbsd@."\""):'.
            \                       '(""))''%>',
            \'clstart':      '<span class="s%S">',
            \'linenr':       '<input class="s%S LineNR" type="xxxinvalid" '.
            \                       'readonly="readonly" tabindex="-1" '.
            \                       'size="%''(@_linenumlen@+'.
            \                                 '!!@_foldcolumn@+1)''%" '.
            \                       'value="%''((@_foldcolumn@)?'.
            \                                    '(@_leadingspace@):'.
            \                                    '(""))''%%#% "/>',
            \'line':         '<span class="s%S">%s</span>',
            \'concealed':    '<span class="Concealed">'.
            \                   '<span class="s%S Shown">%s</span>'.
            \                   '<span class="s%.S Present">%.s</span>'.
            \                '</span>',
            \'clend':        '</span>',
            \'lineend':      '</p>',
            \'tagstart':     '%!let tag=get(get(get(@_tags@, @@@, []), 0, '.
            \                                  '[]), 0, "")!%'.
            \                '<a href="%''('.
            \                   '(type(tag)=='.type('').')?(""):'.
            \                       '(((type(tag)=='.type([]).')?'.
            \                           '(substitute('.
            \                               substitute(s:escapehtml,
            \                                          '\V@@@', 'tag[0]', '').
            \                            ', "\"", "&#34;", "").'.
            \                            '"#line".tag[1]):'.
            \                           '("#line".tag))."-0"))'.
            \                '''%">',
            \'tagend':       '</a>',
            \'foldcolumn':   '<input class="s%S FoldColumn" type="xxxinvalid" '.
            \                        'readonly="readonly" tabindex="-1" '.
            \                        'size="%''@_foldcolumn@''%" '.
            \                        'value="%''substitute(@@@, "\\V>", '.
            \                                             '"\\&gt;", "g")''%"'.
            \                '/>',
            \'fold':         '<span class="s%S Text">%s</span>'.
            \                '<span class="FoldFiller">% %.-</span>',
            \'difffiller':   '<span class="s%S DiffFiller">%-</span>',
            \'collapsedfiller': '<span class="s%S Text">'.
            \                       '%~ Deleted lines: %s %-'.
            \                   '</span>',
            \'foldstart':    '<div id="fold%N" class="closed-fold">'.
            \                   '<div class="toggle-open s%S" id="cf%N">'.
            \                   '<a href="javascript:toggleFold(''fold%N'')">'.
            \                       '%s</a></div>'.
            \                '<div class="fulltext" '.
            \                   'onclick="toggleFold(''fold%N'')">',
            \'foldend':      '</div></div>',
            \'strlen':       s:F.stuf.htmlstrlen,
            \'strescape':    s:escapehtml,
            \'sbsdstart':    '<tr class="SbSDLine" id="sbsd%N">'.
            \                '<td class="SbSD1">',
            \'sbsdsep':      '</td><td class="SbSDSep SbSDSep%C">%|</td>'.
            \                '<td class="SbSD%C">',
            \'sbsdend':      '</td></tr>',
            \'sign':         '<input class="s%S Sign" type="xxxinvalid" '.
            \                       'readonly="readonly" tabindex="-1" '.
            \                       'size="2" value="%s" />',
        \}
if s:whatterm is# 'gui'
    function s:F.readfile(fname)
        if !filereadable(a:fname)
            return ''
        endif
        let escapedfile=shellescape(fnamemodify(a:fname, ':p'))
        if executable('file')==1
            let mime=system('file --mime-type --brief -- '.escapedfile)[:-2]
        else
            let mime='image/'.tolower(fnamemodify(a:fname, ':e'))
            if mime!~#'\v^image\/[a-z\-]+$'
                let mime='image'
            endif
        endif
        if executable('base64')==1 && stridx(a:fname, "\n")==-1
            let b64=system('base64 -w0 -- '.escapedfile)
        else
            let b64=s:_r.base64.encodelines(readfile(a:fname, 'b'))
        endif
        return 'data:'.mime.';base64,'.b64
    endfunction
    let s:formats.html.sign="%=((@.@==2)?".
                \"(''=%<span class=\"Sign\">".
                \       "<img src=\"%=s:F.readfile(@@@)=%\" alt=\"%s\" />".
                \     "</span>%=''):".
                \"(''=%".s:formats.html.sign."%=''))=%"
endif
let s:styleattr='%''((@styleid@!=#"")?'.
            \            '(" style=\"''.'.s:htmlstylestr.'."\""):'.
            \            '(""))''%'
let s:formats['html-vimwiki']={
            \'style':           s:styleattr,
            \'begin':           '<div style="font-family: monospace; %'''.
            \                           s:htmlstylestr.'''%">',
            \'end':             '</div>',
            \'linestart':       '<div%:>',
            \'clstart':         '<span%:>',
            \'linenr':          '<span%:>%#% </span>',
            \'foldcolumn':      '<span%:>%'''.
            \                       'substitute(@@@, "\\V>","\\\\&gt;","g")''%'.
            \                   '</span>',
            \'clend':           '</span>',
            \'lineend':         '</div>',
            \'fold':            '<span%:>%s% %.-</span>',
            \'difffiller':      '<span%:>%-</span>',
            \'collapsedfiller': '<span%:>%~ Deleted lines: %s %-</span>',
            \'strlen':          s:F.stuf.htmlstrlen,
            \'strescape':       s:escapehtml,
            \'line':            '<span%:>%s</span>',
        \}
unlet s:escapehtml s:htmlstylestr
"▶2 BBcode (unixforum)
let s:bbufostylestart=
            \'((@inverse@)?'.
            \   '((@bgcolor@!=#"")?("[color=".@bgcolor@):("")):'.
            \   '("[color=".((@fgcolor@!=#"")?(@fgcolor@):(@_fgcolor@))))."]".'.
            \'((@bold@)?("[b]"):("")).((@italic@)?("[i]"):(""))'
let s:bbufostyleend='((@italic@)?("[/i]"):("")).'.
            \'((@bold@)?("[/b]"):("")).'.
            \'(((@inverse@ && (@bgcolor@!=#"")) || (!@inverse@))?'.
            \   '("[/color]"):(""))'
let s:bbufoescape='substitute('.
            \      'substitute('.
            \       'substitute(@@@, "\\V&", "\\&#38;", "g"), '.
            \       '"[", "\\&#91;", "g"), '.
            \      '"]", "\\&#93;", "g")'
let s:formats["bbcode-unixforum"]={
            \'begin':        '%>((&background==#"dark")?'.
            \                   '("[sh=".substitute(expand("%:p:~%"), "\\V[]",'.
            \                   '''\="&#".char2nr(submatch(0)).";"'', "g")." '.
            \                   '(Created by format.vim)]"):'.
            \                   '("[codebox]"))',
            \'end':          '%>((&background==#"dark")?'.
            \                   '("[/sh]"):'.
            \                   '("[/codebox]"))',
            \'linenr':       '%>substitute(@:@, "%s", ''\='.
            \                           'repeat(@_leadingspace@, '.
            \                                     "@_linenumlen@-len(@-@)).".
            \                         '@-@.@_leadingspace@'', "")',
            \'line':         '%>substitute(@:@, "%s", ''\='.s:bbufoescape.''','.
            \                             '"")',
            \'strlen':       s:F.stuf.bbstrlen,
            \'strescape':    s:bbufoescape,
            \'style':        '%>'  .  s:bbufostylestart.
            \                '."%s".'.s:bbufostyleend,
            \'sbsdsep':      '%+%|',
            \'difffiller':   '%-',
            \'columns':      -1,
        \}
unlet s:bbufostylestart s:bbufostyleend s:bbufoescape
"▶2 LaTeX (xcolor)
let s:texescape=
            \'substitute('.
            \   'substitute(@@@, ''\v[\\\[\]{}&$_\^%#]'', '.
            \              '''\=''''\char''''.char2nr(submatch(0))."{}"'', '.
            \              '"g"),'.
            \'" ", ''\\enskip{}'', "g")'
let s:texstylestart=
            \'((@inverse@)?'.
            \   '(''\colorbox[HTML]{''.'.
            \    '((@fgcolor@!=#"")?'.
            \       '(toupper(@fgcolor@[1:])):'.
            \       '(toupper(@_fgcolor@[1:])))."}{".'.
            \   '''\textcolor[HTML]{''.'.
            \    '((@bgcolor@!=#"")?'.
            \       '(toupper(@bgcolor@[1:])):'.
            \       '(toupper(@_bgcolor@[1:])))."}{"):'.
            \   '(((@bgcolor@!=#"")?'.
            \       '(''\colorbox[HTML]{''.toupper(@bgcolor@[1:])."}{"):'.
            \       '("")).'.
            \    '''\textcolor[HTML]{''.'.
            \    '((@fgcolor@!=#"")?'.
            \       '(toupper(@fgcolor@[1:])):'.
            \       '(toupper(@_fgcolor@[1:])))."}{"))'
let s:texstyleend=
            \'repeat("}", '.
            \   '((@inverse@)?'.
            \       '(2):'.
            \       '((@bgcolor@!=#"")+1)))'
let s:formats['latex-xcolor']={
            \'begin':        '\documentclass[a4paper,12pt]{article}'.
            \                '\usepackage[utf8]{inputenc}'.
            \                '\usepackage[HTML]{xcolor}'.
            \                '\pagecolor[HTML]{%''toupper(@_bgcolor@[1:])''%}'.
            \                '\color[HTML]{%''toupper(@_fgcolor@[1:])''%}'.
            \                '\begin{document}{\ttfamily\noindent',
            \'line':         '%>'.s:texstylestart.".".
            \                     s:texescape.".".
            \                     s:texstyleend,
            \'lineend':      '\\',
            \'end':          '}\end{document}',
            \'strescape':    s:texescape,
        \}
unlet s:texstylestart s:texstyleend s:texescape
"▶2 tokens
let s:linetypes=['lr', 'lf', 'ld', 'lc']
let s:formats.tokens={
            \'begin':           "%>string(['b', @~@, expand('%'), bufnr('%')])",
            \'sbsdstart':       "['ss', %'string(@_vertseparator@)'%, ",
            \'foldstart':       "['fs', %:, %s, %C]",
            \'foldend':         "['fe', %:, %s, %C]",
            \'linestart':       "['%'s:linetypes[@@@]'%', %:, ",
            \'clstart':         "['cl', %:], ",
            \'foldcolumn':      "['fc', %s, %:], ",
            \'sign':            "['sc', %s, %:, %C], ",
            \'linenr':          "['ln', %s, %:], ",
            \'tagstart':        "['ts', %s    ], ",
            \'line':            "['l' , %s, %:], ",
            \'concealed':       "%'string(['c', @@@, @~@, @?@, @^@])'%, ",
            \'tagend':          "['te', %s    ], ",
            \'fold':            "['f' , %s, %:], ",
            \'difffiller':      "['df', '', %:], ",
            \'collapsedfiller': "['cf', %s, %:], ",
            \'style':           '%>string(@~@)',
            \'lineend':         "]",
            \'sbsdsep':         ", ",
            \'sbsdend':         "]",
            \'end':             "%>string(['e', @~@, @_tags@])",
            \'strescape':       "string(@@@)",
        \}
"▶1 getspecdict
function s:F.getspecdict(id, ...)
    if type(a:id)==type([])
        let r=s:F.getspecdict(a:id[0])
        for id in a:id[1:]
            let r=call(s:F.mergespecdicts,
                        \[r, s:F.getspecdict(id)]+a:000, {})
        endfor
        return r
    endif
    return {
    \            'styleid': a:id,
    \            'fgcolor': s:F.getcolor(
    \                           synIDattr(a:id, 'fg#', s:whatterm)),
    \            'bgcolor': s:F.getcolor(
    \                           synIDattr(a:id, 'bg#', s:whatterm)),
    \            'bold':        synIDattr(a:id, 'bold'),
    \            'italic':      synIDattr(a:id, 'italic'),
    \            'underline':   synIDattr(a:id, 'underline'),
    \            'inverse':     synIDattr(a:id, 'inverse'),
    \}
endfunction
"▶1 mergespecdicts
let s:mergeactions={
            \'styleid':   'a:oldspecdict.styleid."_".a:newspecdict.styleid',
            \'fgcolor':   '((a:newspecdict.fgcolor!=#"" && a:000==[])?'.
            \                 '(a:newspecdict.fgcolor):'.
            \                 '(a:oldspecdict.fgcolor))',
            \'bgcolor':   '((a:newspecdict.bgcolor!=#"")?'.
            \                 '(a:newspecdict.bgcolor):'.
            \                 '(a:oldspecdict.bgcolor))',
            \'bold':      'a:oldspecdict.bold      || a:newspecdict.bold',
            \'italic':    'a:oldspecdict.italic    || a:newspecdict.italic',
            \'underline': 'a:oldspecdict.underline || a:newspecdict.underline',
            \'inverse':   'a:oldspecdict.inverse   || a:newspecdict.inverse',
        \}
lockvar! s:mergeactions
function s:F.mergespecdicts(oldspecdict, newspecdict, ...)
    let r={}
    for [key, expr] in items(s:mergeactions)
        let r[key]=eval(expr)
    endfor
    return r
endfunction
"▶1 redrawprogress
function s:F.redrawprogress()
    if !s:progress.showprogress
        return 0
    endif
    let barlen=((winwidth(0))-
                \((s:progress.showprogress==2)?
                \    ((opts.linenumlen)*2+10):
                \    (8)))
    let colnum=barlen*s:progress.linesprocessed/
                \     s:progress.linestoprocess
    let s:progress.oldcolnum=0
    let bar='['.repeat('=', s:progress.oldcolnum).'>'.
                \repeat(' ', barlen-s:progress.oldcolnum).'] '.
                \((s:progress.showprogress==2)?
                \   (repeat(' ', len(s:progress.endline)-
                \                len(s:progress.curline)).
                \    (s:progress.curline).
                \    '/'.(s:progress.endline).' '):
                \   ('')).
                \repeat(' ', 3-len(s:progress.progress)).
                \(s:progress.progress).'%%'
endfunction
"▶1 formattags
function s:F.formattags(ignoretags, starttagreg, endtagreg)
    "▶2 Объявление переменных
    if a:ignoretags==2
        return []
    endif
    let fname=expand('%:.') " Имя обрабатываемого файла
    let tags=taglist('.')   " Список тёгов
    let r={}                " Результат
    let fcontents={}        " Кэш содержимого файлов
    " Список символов, которых надо дополнительно экранировать
    let addescapes=s:_f.getoption('AddTagCmdEscapes')
    let ignoredtags={}
    "▶2 Обработка тёгов (основной цикл)
    for tag in tags
        "▶3 Объявление переменных
        " Имя файла, содержащего определение
        let tfname=fnamemodify(tag.filename, ':.')
        " Перепенная, определяющая, не совпадает ли файл с тёгом с данным
        let incurf=(tfname==#fname)
        if a:ignoretags && !incurf
            continue
        elseif has_key(ignoredtags, tag.name)
            continue
        elseif !search('\V\k\@<!'.a:starttagreg.escape(tag.name, '\').
                    \  a:endtagreg.'\k\@!', 'nwc')
            let ignoredtags[tag.name]=1
            continue
        endif
        if !has_key(r, tag.name)
            let r[tag.name]=[]
        endif
        call add(r[tag.name], [tag])
        "▶3 Тёг находится в текущем файле
        if incurf
            if tag.cmd[0]==#'/'
                try
                    let linenr=search(
                                \escape(
                                \   substitute(tag.cmd, '\m^/\|/$', '', 'g'),
                                \   addescapes), 'nw')
                    if linenr
                        call insert(r[tag.name][-1], linenr)
                    endif
                catch
                endtry
            else
                call insert(r[tag.name][-1], +matchstr(tag.cmd, '\v^\d+'))
            endif
            if len(r[tag.name][-1])==2
                if len(r[tag.name])>1
                    call insert(r[tag.name], remove(r[tag.name], -1))
                endif
            else
                call remove(r[tag.name], -1)
            endif
        "▶3 Тёг находится в другом файле
        elseif filereadable(tfname)
            let linenr=0
            if tag.cmd[0]==#'/'
                if !has_key(fcontents, tfname)
                    let fcontents[tfname]=readfile(tfname, 'b')
                endif
                let fc=fcontents[tfname]
                let pattern=escape(substitute(tag.cmd, '\m^/\|/$', '', 'g'),
                            \      addescapes)
                let linenr=1
                let found=0
                try
                    for line in fc
                        if line=~#'\m'.pattern
                            let found=1
                            break
                        endif
                        let linenr+=1
                    endfor
                catch
                    let found=0
                endtry
                if !found
                    let linenr=0
                endif
            else
                let linenr=+matchstr(tag.cmd, '\v^\d+')
            endif
            if linenr
                call insert(r[tag.name][-1], [tfname, linenr])
            else
                call remove(r[tag.name], -1)
            endif
        "▶3 Файл, в котором должен находится тёг, не существует
        else
            call remove(r[tag.name], -1)
        endif
    endfor
    "▶2 Удаление лишних записей
    call filter(r, '!empty(v:val)')
    let maxduptags=s:_f.getoption('MaxDupTags')
    if maxduptags
        call filter(r, 'type(get(v:val, '.maxduptags.', 0))=='.type(0))
    endif
    return r
endfunction
"▶1 getsigns
function s:F.getsigns(buf)
    let defined={}
    let placed={}
    redir => placedstr
        silent execute 'sign place buffer='.a:buf
    redir END
    for [line, id, name] in map(filter(split(placedstr, "\n"),
                \                      'v:val[:3] is# "    "'),
                \               'map(split(v:val[4:]), '.
                \                   '"v:val[stridx(v:val, ''='')+1:]")')
        if !has_key(defined, name)
            redir => defstr
                silent execute 'sign list' name
            redir END
            let defstr=defstr[(6+len(name)):]
            let defined[name]={'id': name}
            " TODO check icons with spaces
            for prop in split(defstr)
                let eqidx=stridx(prop, '=')
                let defined[name][prop[:(eqidx-1)]]=prop[(eqidx+1):]
            endfor
            if s:whatterm isnot# 'gui' && has_key(defined[name], 'icon')
                unlet defined[name].icon
            endif
        endif
        let placed[line]=[+id, defined[name]]
    endfor
    return [defined, placed]
endfunction
"▶1 cf.new
let s:cf={}
function s:cf.new(cformat, opts)
    return extend(copy(self), {'cformat': a:cformat, 'opts': a:opts})
endfunction
"▶1 cf.get
function s:cf.get(key, ...)
    if self.cformat[a:key].isconst
        return s:F.squote(call(self.cformat[a:key].f, a:000+[self.opts], {}))
    elseif self.cformat[a:key].isexpr
        let atargs=copy(s:defatargs)
        call map(s:keyargs[a:key][:-2], 'extend(atargs,{v:val : a:000[v:key]})')
        let atargs.opts='opts'
        return s:F.procpc(self.cformat[a:key].str, self.opts, a:key, 0, atargs)
    endif
    return 'cformat.'.a:key.'.f('.join(a:000, ', ').', opts)'
endfunction
"▶1 cf.getspecstr
function s:cf.getspecstr(...)
    let args='cformat, '.join(a:000, ', ')
    if self.opts.docline
        let condition='iscline'
        if self.opts.dosigns
            let condition.=' && !(has_key(opts.placedsigns, curline) && '.
                        \     'has_key(opts.placedsigns[curline][1], "linehl"))'
        endif
        return 'call(s:F.compiledspec, ['.args.']+'.
                \               '(('.condition.')?(["CursorLine"]):([])), {})'
    else
        return 's:F.compiledspec('.args.')'
    endif
endfunction
"▶1 cf.getnrstr
function s:cf.getnrstr(nrvarstr)
    return ((self.opts.dornr)?('abs('.a:nrvarstr.'-'.self.opts.cline.')'):
                \             (a:nrvarstr))
endfunction
"▶1 cf.escape
function s:cf.escape(str)
    return eval(substitute(self.opts.strescape, '@@@', 'a:str', 'g'))
endfunction
"▶1 cf.hasreq
function s:cf.hasreq(key, reqs)
    let reqs=self.cformat[a:key].req
    for req in a:reqs
        if has_key(reqs, req)
            return 1
        endif
    endfor
    return 0
endfunction
"▶1 gettagreg
function s:F.gettagreg(options, st)
    let tagreg=((a:options[a:st.'tagreg'] is 0)?
                \       (s:_f.getoption(toupper(a:st[0]).a:st[1:].'TagReg')):
                \       (a:options[a:st.'tagreg']))
    if tagreg is 0
        let tagreg=''
    else
        let tagreg='\%('.tagreg.'\)'
    endif
    return tagreg
endfunction
"▶1 format
"▶2 Some globals
let s:compiledfmts={}
let s:progress={}
let s:notpersistentdf=['a:line', 'a:char', '=']
let s:notpersistentfdc=['a:line']
let s:notpersistentsc=['a:line']
let s:npsbsdstart=['a:line']
"▲2
function s:F.format(type, startline, endline, options, ...)
    "▶2 Объявление переменных
    let [startline, endline]=sort([a:startline, a:endline])
    if startline<1
        let startline=1
        if endline<1
            let endline=1
        endif
    endif
    let d={}
let formatfunction=['function d.compiledformat()']
    "▶3 cformat, opts
    let quotedtype=s:F.squote(a:type)
    call extend(formatfunction, [
    \'let cformat=s:compiledfmts['.quotedtype.']',
    \'let opts=cformat.opts',])
    if has_key(s:compiledfmts, a:type)
        let cformat=s:compiledfmts[a:type]
    else
        let cformat=s:F.fmtprepare(s:formats[a:type], startline,
                    \                                          endline,
                    \               a:options)
        let s:compiledfmts[a:type]=cformat
    endif
    "▶3 Убеждаемся, что ранее запущенное форматирование завершилось успешно
    " Если нет, то мы не можем полагаться на кэш
    let sbsd=((empty(a:000))?(0):(a:000[0]))
    if sbsd<=1 && has_key(cformat, 'frunning')
        unlet cformat.frunning
        let cformat.cache={}
        let cformat.stylestr=''
        if has_key(s:F, 'compiledspec')
            unlet s:F.compiledspec
        endif
    endif
    let cformat.frunning=1
    "▲3
    let opts=cformat.opts
    let cf=s:cf.new(cformat, opts)
    unlockvar opts
    let opts.linenumlen=len(endline)
    "▶3 opts.columns
    let columns=0+(((a:options.columns)+0)?
                \       (a:options.columns):
                \       (get(s:formats[a:type], 'columns', winwidth(0))))
    if columns==-1
        let columns=max(map(range(1, line('$')), 'virtcol([v:val, "$"])-1'))
    endif
    let opts.columns=columns
    "▲3
    let opts.sbsd=sbsd
    "▶3 Складки
    " Складки игнорируются, если истинна настройка «IgnoreFolds», отсутствует 
    " ключ «fold» или Vim собран без поддержки складок
    let ignorefolds=((a:options.folds==-1)?
                \       (s:_f.getoption('IgnoreFolds')):
                \       (!a:options.folds)) ||
                \!has('folding')
    let allfolds=!(ignorefolds || sbsd) &&
                \((a:options.allfolds==-1)?
                \       (s:_f.getoption('AllFolds')):
                \       (a:options.allfolds)) &&
                \(has_key(cformat, 'foldstart') ||
                \ has_key(cformat, 'foldend'))
    let foldcolumn=0
    if !ignorefolds && has_key(cformat, 'foldcolumn')
        let foldcolumn=((a:options.foldcolumn==-2)?
                \           (s:_f.getoption('FoldColumn')):
                \           (a:options.foldcolumn))
        if foldcolumn==-1
            let foldcolumn=&foldcolumn
        endif
    endif
    let ignorefolds=ignorefolds || !has_key(cformat, 'fold')
    let opts.ignorefolds = ignorefolds
    let opts.allfolds    = allfolds
    let opts.foldcolumn  = foldcolumn
    let opts.columns    += foldcolumn
    "▲3
    let npregex='\v\t|\p@!.'
    " Список строк с возвращаемыми значениями
    call add(formatfunction, 'let r=[]')
    " Номер преобразовываемой линии
    call add(formatfunction, 'let curline='.startline)
    "▶3 «Скрытые» символы
    let formatconcealed=0
    if has('conceal') && &conceallevel
        if a:options.concealed is -1
            let formatconcealed=s:_f.getoption('FormatConcealed')
        elseif a:options.concealed is 'both'
            let formatconcealed=2
        elseif a:options.concealed is 'shown'
            let formatconcealed=1
        else
            let formatconcealed=a:options.concealed
        endif
    endif
    if formatconcealed==2 && !has_key(cformat, 'concealed')
        let formatconcealed=1
    endif
    let opts.formatconcealed=formatconcealed
    "▶3 Курсор
    let ignorecursor=s:_f.getoption('IgnoreCursor')
    "▶3 Форматы
    "normalspec  — Формат по умолчанию
    "specialspec — Для спецсимволов, в т.ч. для lcs=tab и lcs=trail
    "ntspec      — Для lcs=eol и lcs=nbsp
    "foldspec    — Формат складок
    "fcspec      — Формат foldcolumn
    "nrspec      — Для номеров строк
    "fillspec    — Для удалённых строк
    "ccspec      — Для колонки с курсором
    "clspec      — Для линии курсора
    "cspec       — Для самого курсора
    "conspec     — Для скрытых символов
    "scspec      — Для колонки со знаками
    call extend(formatfunction, [
    \'let normalspec  = s:F.compiledspec(cformat, "Normal")',
    \'let specialspec = s:F.compiledspec(cformat, "SpecialKey")',
    \'let ntspec      = s:F.compiledspec(cformat, "NonText")',
    \])
    let spspecstr='specialspec'
    let ntspecstr='ntspec'
    let speciallines={}
    let specialcolumns={}
    "▶4 Скрытые символы
    if formatconcealed==2
        call add(formatfunction,
        \'let conspec=s:F.compiledspec(cformat, "Conceal")')
    endif
    "▶4 dosigns
    let dosigns=0
    if has_key(cformat, 'sign')
        let dosigns=((a:options.signs==-1)?
                    \   (!s:_f.getoption('IgnoreSigns')):
                    \   (a:options.signs))
        if dosigns
            let [dsigns, psigns]=s:F.getsigns(bufnr('%'))
            if empty(psigns)
                let dosigns=0
            endif
        endif
    endif
    if dosigns
        call add(formatfunction,
        \'let scspec=s:F.compiledspec(cformat, "SignColumn")')
        let opts.signdefinitions=dsigns
        let opts.placedsigns=psigns
        let spspecstr='((has_key(opts.placedsigns, curline) && '.
                    \   'has_key(opts.placedsigns[curline][1], "linehl"))?'.
                    \       '(s:F.compiledspec(cformat, "SpecialKey", '.
                    \                  'opts.placedsigns[curline][1].linehl)):'.
                    \       '('.spspecstr.'))'
        let ntspecstr='((has_key(opts.placedsigns, curline) && '.
                    \   'has_key(opts.placedsigns[curline][1], "linehl"))?'.
                    \       '(s:F.compiledspec(cformat, "NonText", '.
                    \                  'opts.placedsigns[curline][1].linehl)):'.
                    \       '('.ntspecstr.'))'
    endif
    let opts.dosigns=dosigns
    "▶4 Курсор
    let docline=0
    let cline=line('.')
    if !ignorecursor
        let ccolumn=virtcol('.')
        if &cursorcolumn
            call add(formatfunction,
            \'let ccspec=s:F.compiledspec(cformat, "CursorColumn")')
            " let specialcolumns[ccolumn]=[1]
        endif
        if startline<=cline && cline<=endline
            if &cursorline
                let docline=1
                call add(formatfunction,
                \'let clspec=s:F.compiledspec(cformat, "Normal", '.
                \                                     '"CursorLine")')
            endif
            " guicursor is ignored in cterm
            if 0 && s:whatterm is# 'gui'
                let icstr=matchstr(&guicursor, '\m'.
                            \'\(\%(,\|^\)'.
                            \   '[a-z\-]*[a-z]\@<!'.
                            \       'i'.
                            \   '[a-z]\@![a-z\-]*:\)\@<='.
                            \'[^,]*')
                let icstr=substitute(icstr, '\m'.
                            \'\(^\|-\)\@<='.
                            \   'blink\%(wait\|on\|off\)\d\+'.
                            \'\(-\|$\)\@=', '', 'g')
                let ctype=matchstr(icstr, '\m'.
                            \'\(^\|-\)\@<='.
                            \   '\(\(hor\|ver\)\d\+\|block\)'.
                            \'\(-\|$\)\@=')
                call add(formatfunction,
                \'let cspec=s:F.compiledspec(cformat, "Cursor")')
            else
                let ctype='block'
            endif
            let speciallines[cline]={ ccolumn : [0] }
        elseif !&cursorcolumn
            let ignorecursor=1
        endif
    endif
    if docline
        call extend(formatfunction, [
        \'let clspspec=s:F.compiledspec(cformat, "SpecialKey", "CursorLine")',
        \'let clntspec=s:F.compiledspec(cformat, "NonText",    "CursorLine")',
        \])
        let spspecstr='((iscline)?(clspspec):('.spspecstr.'))'
        let ntspecstr='((iscline)?(clntspec):('.ntspecstr.'))'
    endif
    let opts.docline=docline
    let opts.cline=cline
    "▶4 Функция «fmt.compiledspec»
    let specfunction=[
\'function s:F.compiledspec(cformat, hlname'.
\                               ((&diff || docline)?(', ...'):('')).')',
    \'let id=hlID(a:hlname)',]
    if &diff || docline
        call extend(specfunction, [
        \'if a:0',
        \'    let addids=map(copy(a:000), "hlID(v:val)")',
        \'    let tmpid=[id]+addids',
        \'    unlet id',
        \'    let id=tmpid',
        \'    let name=join(id, "_")',
        \'else',
        \'    let name=id',
        \'endif',
        \])
    else
        call add(specfunction, 'let name=id')
    endif
    call extend(specfunction, [
    \'if has_key(a:cformat.cache, name)',
    \'    return a:cformat.cache[name]',
    \'endif',
    \((docline)?
    \   ('let r=[call(s:F.getspecdict, '.
    \           '[id]+((a:hlname==#"LineNR")?([0]):([])), {}), ""]'):
    \   ('let r=[s:F.getspecdict(id), ""]')),
    \])
    if has_key(cformat, 'style')
        call add(specfunction,
        \'let r[1]=a:cformat.style.f(id, r, "", a:cformat.opts)')
        if has_key(cformat.begin.req, 'a:style') ||
                    \has_key(cformat.end.req, 'a:style')
            call add(specfunction, 'let a:cformat.stylestr.=r[1]')
        endif
    endif
    call extend(specfunction, [
    \'let a:cformat.cache[name]=r',
    \'return r',
\'endfunction'])
    execute join(specfunction, "\n")
    "▲4
    let opts.ignorecursor=ignorecursor
    if foldcolumn
        call add(formatfunction,
        \'let fcspec  = s:F.compiledspec(cformat, "FoldColumn")')
    endif
    if !ignorefolds || allfolds
        call add(formatfunction,
        \'let foldspec=s:F.compiledspec(cformat, "Folded")')
    endif
    if &diff
        call add(formatfunction,
        \'let fillspec=s:F.compiledspec(cformat, "DiffDelete")')
    endif
    "▶3 donr, dornr
    let donr=0
    let dornr=0
    if has_key(cformat, 'linenr')
        let donr=((a:options.number==-1)?
                    \(s:_f.getoption('NoLineNR')):
                    \(!a:options.number))
        if donr!=-1
            let donr=!donr
        endif
        let dornr=((a:options.relativenumber==-1)?
                    \(s:_f.getoption('RelativeNumber')):
                    \(a:options.relativenumber))
        if dornr==-1
            if exists('+relativenumber')
                let dornr=&relativenumber
            else
                let dornr=0
            endif
        endif
        if !dornr && donr==-1
            let donr=&number
        endif
        if donr || dornr
            call add(formatfunction,
            \'let nrspec=s:F.compiledspec(cformat, "LineNr")')
            if docline
                call add(formatfunction,
                \'let nrclspec=s:F.compiledspec(cformat, "LineNR", '.
                \                                       '"CursorLine")')
            endif
        endif
        if dornr
            let donr=0
        endif
    endif
    let opts.donr=donr
    let opts.dornr=dornr
    if donr || dornr
        let opts.columns+=1+opts.linenumlen
    endif
    "▶3 fillchars
    let fillchars={}
    if has('windows') && has('folding') && (!ignorefolds || &diff || sbsd==1)
        let fcs=split(&fillchars, '\v\,%(%(stl%(nc)?|vert|fold|diff)\:)@=')
        for fc in fcs
            let [o, v]=matchlist(fc, '\v^(\w*)\:(.*)$')[1:2]
            let fillchars[o]=v
        endfor
    endif
    let opts.difffillchar  = cf.escape(get(fillchars, 'diff', '-'))
    let opts.foldfillchar  = cf.escape(get(fillchars, 'fold', '-'))
    let opts.vertseparator = cf.escape(get(fillchars, 'vert', '|'))
    "▶3 side-by-side diff
    if sbsd==1
        "▶4 Используемые буфера
        let lastwin=winnr('$')
        let curwin=winnr()
        let i=1
        let dwinnrs=[]
        while i<=lastwin
            if i!=curwin && getwinvar(i, '&diff')
                call add(dwinnrs, i)
            endif
            let i+=1
        endwhile
        if dwinnrs==[]
            return []
        endif
        "▶4 Получение реальных номеров линий в текущем буфере
        let curline=1
        let virtcurline=1
        let maxline=line('$')
        let virtstartline=0
        let virtendline=0
        while curline<=maxline
            let virtcurline+=diff_filler(curline)
            if !virtstartline && curline==startline
                let virtstartline=curline
            endif
            if curline==endline
                let virtendline=virtcurline
                break
            endif
            let virtcurline+=1
            let curline+=1
        endwhile
        "▶4
        call insert(dwinnrs, curwin)
        for dwinnr in dwinnrs
            if getwinvar(curwin, '&foldmethod') isnot# 'diff' ||
                        \getwinvar(dwinnr, '&foldmethod') isnot# 'diff'
                let a:options.ignorefolds=1
                let ignorefolds=1
            endif
        endfor
        let r=[]
        let i=2
        let width=0
        let Curcompiledspec=s:F.compiledspec
        for dwinnr in dwinnrs
            "▶4 Получение номеров линий в другом буфере
            execute dwinnr.'wincmd w'
            let curline=1
            let virtcurline=1
            let maxline=line('$')
            let dstartline=0
            let dstartinfiller=0
            let dendline=0
            while curline<=maxline+1
                let filler=diff_filler(curline)
                let virtcurline+=filler
                if !dstartline && virtcurline>=virtstartline
                    let dstartinfiller=filler-(virtcurline-virtstartline)
                    let dstartline=curline
                endif
                if virtcurline>virtendline
                    let dendline=((curline<=maxline)?(curline):(maxline))
                    break
                endif
                let virtcurline+=1
                let curline+=1
            endwhile
            "▶4 Получение отформатированных текстов
            let a:options.allfolds=0
            let a:options.collapsfiller=0
            let s:F.compiledspec=Curcompiledspec
            let normalspec=s:F.compiledspec(cformat, 'Normal')
            unlet s:F.compiledspec
            if !ignorefolds
                normal! zM
            endif
            let r2=s:F.format(a:type, dstartline, dendline, a:options, i)
            "▶4 Добавление sbsdstart или sbsdsep
            let oldcolumns=opts.columns
            unlockvar opts
            let opts.columns=width
            let width+=oldcolumns+1
            let opts.sbsd=sbsd
            lockvar! opts
            if empty(r)
                let r=r2
                if has_key(cformat, 'sbsdstart')
                    call map(r, 'cformat.sbsdstart.f(normalspec, v:key, "", '.
                                \                   'opts).v:val')
                endif
            else
                let r2=r2[(dstartinfiller):(len(r)-1+dstartinfiller)]
                if has_key(cformat, 'sbsdsep')
                    call map(r, 'v:val.'.
                                \'cformat.sbsdsep.f(normalspec, v:key, i-1, '.
                                \                  'v:val, opts).r2[v:key]')
                endif
            endif
            let i+=1
        endfor
        "▶4 Добавление sbsdend
        unlockvar opts
        let opts.columns=width-1
        execute curwin.'wincmd w'
        let opts.sbsd=sbsd
        lockvar! opts
        if has_key(cformat, 'sbsdend')
            call map(r, 'v:val.'.
                        \'cformat.sbsdend.f(normalspec, v:key, '.
                        \                   len(dwinnrs).', v:val, opts)')
        endif
        "▶4 Начало и конец представления
        if has_key(cformat, 'begin')
            call insert(r, cformat.begin.f(normalspec, '', opts,
                        \                  cformat.stylestr))
        endif
        if has_key(cformat, 'end')
            call add(r, cformat.end.f(normalspec, endline, '', opts,
                        \             cformat.stylestr))
        endif
        "▶4 nolf/haslf
        if has_key(cformat, 'nolf') && cformat.nolf
            let r=[join(r, '')]
        endif
        if has_key(cformat, 'haslf') && cformat.haslf
            let oldr=r
            let r=[]
            for item in oldr
                let r+=split(item, "\n")
            endfor
        endif
        "▲4
        return r
    endif
    "▶3 Тёги
    let ignoretags=2
    if has_key(cformat, 'tagstart') || has_key(cformat, 'tagend')
        if a:options.tags is -1
            let ignoretags=s:_f.getoption('IgnoreTags')
        elseif a:options.tags is 'all'
            let ignoretags=0
        elseif a:options.tags is 'local'
            let ignoretags=1
        else
            let ignoretags=(2-a:options.ignoretags)
        endif
    endif
    if ignoretags!=2
        let starttagreg=s:F.gettagreg(a:options, 'start')
        let endtagreg=s:F.gettagreg(a:options, 'end')
        let opts.tags=s:F.formattags(ignoretags, starttagreg, endtagreg)
        if empty(opts.tags)
            let tagregex=''
        else
            let tagregex='\V'
            if !empty(starttagreg)
                let tagregex.=starttagreg
            endif
            if !(empty(starttagreg) && empty(endtagreg))
                let tagregex.='\%('
            endif
            let tagregex.=join(map(reverse(sort(keys(opts.tags))),
                        \          'escape(v:val, "\\")'), '\|')
            if !(empty(starttagreg) && empty(endtagreg))
                let tagregex.='\)'
            endif
            if !empty(endtagreg)
                let tagregex.=endtagreg
            endif
            let tagregex.='\v'
        endif
    else
        let opts.tags={}
        let tagregex=''
    endif
    "▲3
    lockvar! opts
    "▶3 Progress bar
    let showprogress=0
    if has('statusline')
        if a:options.progress is -1
            let showprogress=s:_f.getoption('ShowProgress')
        elseif a:options.progress is 'lines'
            let showprogress=2
        elseif a:options.progress is 'percent'
            let showprogress=1
        else
            let showprogress=a:options.progress
        endif
    endif
    let s:progress.showprogress=showprogress
    if showprogress
        set laststatus=2
        call extend(formatfunction, [
        \'let oldprogress=0',
        \'let linesprocessed=0',
        \'let linestoprocess='.(endline-startline+1),
        \])
        if s:whatterm is# 'cterm'
            let canresize=0
            " Вторая часть прогресс бара
            let barlen=((winwidth(0))-
                        \((showprogress==2)?
                        \    ((opts.linenumlen)*2+10):
                        \    (8)))
            if barlen<0
                let showprogress=0
            endif
            " Старые значения % сделанного и длины строки из '='; первая часть 
            " progress bar’а со строкой =
            call extend(formatfunction, [
            \'let oldcolnum=0',
            \'let barstart="["',
            \'let barlen='.barlen,
            \'let barend=repeat(" ", barlen)."] "',
            \])
        else
            let canresize=1
            let s:progress.oldcolnum=0
            let s:progress.curline=startline
            let s:progress.progress=0
            let s:progress.endline=endline
            let s:progress.linesprocessed=0
            let s:progress.linestoprocess=(endline-startline+1)
        endif
    endif
    "▶3 Удалённая строка: предсоздание, если возможно
    if &diff
        let persistentfiller=0
        let collapsafter=((a:options.collapsfiller==-1)?
                    \       (s:_f.getoption('CollapsFiller')):
                    \       (a:options.collapsfiller))
        if !has_key(cformat, 'difffiller') &&
                    \has_key(cformat, 'collapsedfiller')
            let collapsafter=1
        endif
        if collapsafter && has_key(cformat, 'collapsedfiller')
            let persistentfiller=0
        elseif has_key(cformat, 'difffiller')
            let collapsafter=0
            let persistentfiller=!cf.hasreq('difffiller', s:notpersistentdf)
            if persistentfiller
                let fillspec=s:F.compiledspec(cformat, 'DiffDelete')
                let fillerstr=cformat.difffiller.f(opts.difffillchar, fillspec,
                            \                      0, 0, '', opts)
            endif
        else
            let persistentfiller=1
            let fillerstr=''
        endif
    endif
    "▶3 listchars: отображение некоторых символов в соответствии с 'listchars'
    let listchars={}
    if &list && !((a:options.list)?
                \   (s:_f.getoption('IgnoreList')):
                \   (!a:options.list))
        let lcs=split(&listchars,
                    \'\v\,%(%(eol|tab|trail|extends|precedes|nbsp)\:)@=')
        for lc in lcs
            let [o, v]=matchlist(lc, '\v^(\w*)\:(.*)$')[1:2]
            let listchars[o]=map(split(v, '\v.@='), 'escape(v:val, "&\\")')
            if o is# 'nbsp'
                let npregex='\v\t| |\p@!.'
            endif
        endfor
    endif
    let npregex=s:F.squote(npregex)
    "▶2 Знаки
    if dosigns
        let persistentsc=!cf.hasreq('sign', s:notpersistentsc)
        if persistentsc
            call extend(formatfunction, [
            \'let nosignsc='.cf.get('sign', '"  "', 'scspec', 0, 0, '""'),
            \'let scols={}',
            \'for [sname, sign] in items(opts.signdefinitions)',
            \'    if has_key(sign, "texthl")',
            \'        let spec=s:F.compiledspec(cformat, sign.texthl)',
            \'    else',
            \'        let spec=scspec',
            \'    endif',
            \])
            if s:whatterm is# 'gui'
                call extend(formatfunction, [
                \'if has_key(sign, "icon")',
                \'    let scols[sname]='.cf.get('sign', 'sign.icon', 'spec',
                \                               0, 2, '""'),
                \'else',
                \])
            endif
            call extend(formatfunction, [
            \'if has_key(sign, "text")',
            \'    let scols[sname]='.cf.get('sign', 'sign.text', 'spec', 0, 1,
            \                               '""'),
            \'else',
            \'    let scols[sname]='.cf.get('sign', '"  "', 'scspec', 0,1,'""'),
            \'endif',
            \])
            if s:whatterm is# 'gui'
                call add(formatfunction, 'endif')
            endif
            call add(formatfunction, 'endfor')
        endif
    endif
    "▶2 Складки
    if allfolds || foldcolumn
        "▶3 Объявление переменных
        let persistentfdc=!cf.hasreq('foldcolumn', s:notpersistentfdc)
        call add(formatfunction,
        \'let fcurline='.startline)
        call setwinvar(0, '&foldminlines', 0)
        "▶3 Складки, закрытые в данный момент
        if !ignorefolds
            call extend(formatfunction, [
            \'let closedfolds={}',
            \'let closedfoldslist=[]',])
            if !allfolds
                call add(formatfunction, 'let closedfoldsends=[]')
            endif
            call extend(formatfunction, [
            \'while fcurline<='.endline,
            \'    if foldclosed(fcurline)!=-1',
            \'        call add(closedfoldslist, fcurline)',
            \'        let closedfolds[fcurline]='.
            \               ((has_key(cformat, 'linestart'))?
            \                    (cf.get('linestart', 1, 'foldspec', 'fcurline',
            \                            '""')):
            \                    ('""'))])
            if !foldcolumn
                if dosigns
                    call add(formatfunction,
                    \'let closedfolds[fcurline].='.
                    \       cf.get('sign', '"  "', 'foldspec', 'fcurline', 0,
                    \               'closedfolds[fcurline]'))
                endif
                if donr || dornr
                    call add(formatfunction,
                    \'    let closedfolds[fcurline].='.
                    \                   cf.get('linenr',cf.getnrstr('fcurline'),
                    \                          'foldspec', 'fcurline',
                    \                          'closedfolds[fcurline]'))
                endif
                call add(formatfunction,
                \'        let closedfolds[fcurline].='.
                \               cf.get('fold', 'foldtextresult(fcurline)',
                \                              'foldspec', 'fcurline',
                \                              'closedfolds[fcurline]').
                \               ((has_key(cformat, 'lineend'))?
                \                   ('.'.cf.get('lineend', 1, 'foldspec',
                \                                         'fcurline', 0, '""')):
                \                   ('')))
            endif
            if !allfolds
                call add(formatfunction,
                \'call add(closedfoldsends, foldclosedend(fcurline))')
                if showprogress
                    call add(formatfunction,
                    \'let linestoprocess-=(closedfoldsends[-1]-fcurline)')
                endif
                call add(formatfunction,
                \'let fcurline=closedfoldsends[-1]')
            endif
            call extend(formatfunction, [
            \'    endif',
            \'    let fcurline+=1',
            \'endwhile',])
        endif
        "▶3 Остальные складки
        "▶4 Объявление переменных: foldcolumn
        if foldcolumn
            call extend(formatfunction, [
            \'let foldlevel=-1',
            \'let fdchange=0',
            \'let foldlevels={}',
            \'let foldcolumns={}',])
            if !persistentfdc
                call extend(formatfunction, [
                \'let foldcolumnstarts={}',
                \'let foldcolumns[-1]=repeat(opts.leadingspace, '.
                \                           'opts.foldcolumn)',
                \])
            else
                call add(formatfunction,
                \'let foldcolumns[-1]=repeat(['.
                \           cf.get('foldcolumn',
                \                  'repeat(opts.leadingspace, '.foldcolumn.')',
                \                  'fcspec', 0, -1, '""').'], 3)')
            endif
        endif
        "▶4 Объявление общих переменных
        call extend(formatfunction, [
        \'let possiblefolds={}',
        \'let &foldlevel=0',
        \'let oldfoldnumber=-1',
        \'let foldnumber=0',])
        "▶4 Основной цикл: получение всех складок
        "▶5 Начало цикла
        call extend(formatfunction, [
        \'while oldfoldnumber!=foldnumber',
        \'    let oldfoldnumber=foldnumber',
        \'    let fcurline='.startline,])
            "▶5 foldcolumn
            if foldcolumn
                "▶6 Получения текста
                call extend(formatfunction, [
                \'if &foldlevel>='.(foldcolumn-1),
                \'    let rangestart=&foldlevel-'.(foldcolumn-3),
                \'    let rangeend=&foldlevel',
                \'    if rangestart<=rangeend',
                \'        if rangeend<10',
                \'            let fdctext=join(range(rangestart, '.
                \                                   'rangeend), "")',
                \'        elseif rangestart<10',
                \'            let fdctext=join(range(rangestart, 9),'.
                \                             '"").'.
                \                        'repeat(">", rangeend-9)',
                \'        else',
                \'            let fdctext=repeat(">", '.(foldcolumn-2).')',
                \'        endif',
                \'    else',
                \'        let fdctext=""',
                \'    endif',
                \'    let fdcnexttext=fdctext.((&foldlevel>=9)?'.
                \                                   '(">"):'.
                \                                   '((&foldlevel)?'.
                \                                       '(&foldlevel+1):'.
                \                                       '("|")))',
                \'    if &foldlevel>='.foldcolumn,
                \'        let fdcclosedtext=((rangestart<=10)?'.
                \                               '(rangestart-1):'.
                \                               '(">")).fdctext."+"',
                \'    else',
                \'        let fdcclosedtext=repeat("|", '.(foldcolumn-1).').'.
                \                                 '"+"',
                \'    endif',
                \'    let fdctextend=repeat(opts.leadingspace, '.
                \                          'opts.foldcolumn-1-len(fdctext))',
                \'else',
                \'    let fdctext=repeat("|", &foldlevel)',
                \'    let fdcnexttext=fdctext."|"',
                \'    let fdctextend=repeat(opts.leadingspace, '.
                \                          'opts.foldcolumn-1-len(fdctext))',
                \'    let fdcclosedtext=fdctext."+".fdctextend',
                \'endif',
                \'let fdcnexttext.=fdctextend',
                \'let fdcopenedtext=fdctext."-".fdctextend',
                \])
                "▶6 Создание колонки или сохранение текста
                if persistentfdc
                    call add(formatfunction,
                    \'let foldcolumns[&foldlevel]=['.
                    \   join(map(['fdcclosedtext', 'fdcopenedtext',
                    \             'fdcnexttext'],
                    \            'cf.get("foldcolumn", v:val, "fcspec", 0, '.
                    \                   '"&foldlevel", ''""'')'), ', ').']')
                else
                    call add(formatfunction,
                    \'let foldcolumns[&foldlevel]=fdcnexttext')
                endif
            endif
            "▶5 Получения положения складок
            call extend(formatfunction, [
            \'while fcurline<='.endline,
            \'    if foldclosed(fcurline)>-1',])
                    "▶6 Объявление переменных
                    call add(formatfunction,
                    \'let foldend=foldclosedend(fcurline)')
                    "▶6 Получение foldstart и foldend
                    if allfolds
                        "▶7 Объявление переменных
                        call add(formatfunction,
                        \'let foldtext=foldtextresult(fcurline)')
                        "▶7 foldstart
                        if has_key(cformat, 'foldstart')
                            call extend(formatfunction, [
                            \'if !has_key(possiblefolds, fcurline)',
                            \'    let possiblefolds[fcurline]={}',
                            \'endif',
                            \'if !has_key(possiblefolds[fcurline], "start")',
                            \'    let possiblefolds[fcurline].start=[]',
                            \'endif',
                            \'call add(possiblefolds[fcurline].start, '.
                            \           cf.get('foldstart', 'foldtext',
                            \                  'foldspec', 'fcurline',
                            \                  '&foldlevel', '""').')',
                            \])
                        endif
                        "▶7 foldend
                        if has_key(cformat, 'foldend')
                            call extend(formatfunction, [
                            \'let foldinsbefore=foldend+1',
                            \'if !has_key(possiblefolds, foldinsbefore)',
                            \'    let possiblefolds[foldinsbefore]={}',
                            \'endif',
                            \'if !has_key(possiblefolds[foldinsbefore], "end")',
                            \'    let possiblefolds[foldinsbefore].end=[]',
                            \'endif',
                            \'call insert(possiblefolds[foldinsbefore].end, '.
                            \           cf.get('foldend', 'foldtext',
                            \                  'foldspec', 'foldend',
                            \                  '&foldlevel', '""').')',
                            \])
                        endif
                    endif
                    "▶6 foldcolumn
                    if foldcolumn
                        "▶7 foldlevels
                        call extend(formatfunction, [
                        \'let foldlevels[fcurline]=&foldlevel',
                        \'if !has_key(foldlevels, foldend+1)',
                        \'    let foldlevels[foldend+1]=&foldlevel-1',
                        \'endif',
                        \])
                        "▶7 Получение foldcolumn,
                        " если она не была предсоздана
                        if !persistentfdc
                            if !ignorefolds
                                let cffstr='closedfolds[fcurline]'
                                call extend(formatfunction, [
                                \'if has_key(closedfolds, fcurline)',
                                \'    let '.cffstr.'.='.
                                \           cf.get('foldcolumn',
                                \                  'fdcclosedtext', 'fcspec',
                                \                  'fcurline', '&foldlevel',
                                \                  cffstr)])
                                if dosigns
                                    call add(formatfunction,
                                    \'let '.cffstr.'.='.
                                    \       cf.get('sign', '"  "', 'foldspec',
                                    \              'fcurline', 0, cffstr))
                                endif
                                if dornr || donr
                                    call add(formatfunction,
                                    \'let '.cffstr.'.='.
                                    \   cf.get('linenr',cf.getnrstr('fcurline'),
                                    \          'foldspec', 'fcurline', cffstr))
                                endif
                                call add(formatfunction,
                                \'let '.cffstr.'.='.
                                \       cf.get('fold',
                                \              'foldtextresult(fcurline)',
                                \              'foldspec', 'fcurline', cffstr))
                                if has_key(cformat, 'lineend')
                                    call add(formatfunction,
                                    \'let '.cffstr.'.='.
                                    \   cf.get('lineend', 1, 'foldspec',
                                    \          'fcurline', 0, cffstr))
                                endif
                                call add(formatfunction, 'endif')
                                unlet cffstr
                            endif
                            call add(formatfunction,
                            \'let foldcolumnstarts[fcurline]='.
                            \       cf.get('foldcolumn', 'fdcopenedtext',
                            \              'fcspec', 'fcurline', '&foldlevel',
                            \              '""'))
                        "▶7 Получение foldcolumn для закрытой складки
                        elseif !ignorefolds
                            let cffstr='closedfolds[fcurline]'
                            call extend(formatfunction, [
                            \'if has_key(closedfolds, fcurline)',
                            \'    let '.cffstr.'.=foldcolumns[&foldlevel][0]'])
                            if dosigns
                                call add(formatfunction,
                                \'let '.cffstr.'.='.
                                \       cf.get('sign', '"  "', 'foldspec',
                                \              'fcurline', 0, cffstr))
                            endif
                            if dornr || donr
                                call add(formatfunction,
                                \'let '.cffstr.'.='.
                                \       cf.get('linenr',cf.getnrstr('fcurline'),
                                \              'foldspec', 'fcurline', cffstr))
                            endif
                            call add(formatfunction,
                            \'    let '.cffstr.'.='.
                            \           cf.get('fold',
                            \                  'foldtextresult(fcurline)',
                            \                  'foldspec', 'fcurline', cffstr))
                            if has_key(cformat, 'lineend')
                                call add(formatfunction,
                                \'let '.cffstr.'.='.
                                \       cf.get('lineend', 1, 'foldspec',
                                \              'fcurline', 0, cffstr))
                            endif
                            call add(formatfunction, 'endif')
                        endif
                    endif
                    "▶6 Завершение цикла
                    call extend(formatfunction, [
                    \'let fcurline=foldend',
                    \'let foldnumber+=1',
                \'endif',
                \'let fcurline+=1',
            \'endwhile',
            \'let &foldlevel+=1',
        \'endwhile',
        \])
    endif
    "▶2 Основной цикл: создание указанного представления
    " " FIXME
    " let debugline=len(formatfunction)
    call extend(formatfunction, [
    \'while curline<='.(endline+((&diff)?(1):(0))),
        \'let curstr=""',])
        "▶3 iscline
        if docline
            call add(formatfunction, 'let iscline=(curline=='.cline.')')
        endif
        "▶3 foldlevel
        if foldcolumn
            if &diff
                call extend(formatfunction, [
                \'let fillfoldlevel=foldlevel',
                \])
            endif
            call extend(formatfunction, [
            \'if has_key(foldlevels, curline)',
            \'    let fdchange=1',
            \'    let foldlevel=foldlevels[curline]',
            \'else',
            \'    let fdchange=0',
            \'endif',
            \])
        endif
        "▶3 Progress bar
        if showprogress
            if canresize
                call add(formatfunction,
                \'let barlen=winwidth(0)-'.
                \               ((showprogress==2)?
                \                   (((opts.linenumlen)*2)+10):
                \                   ('8')))
            endif
            call extend(formatfunction, [
            \'let linesprocessed+=1',
            \'let progress=100*linesprocessed/linestoprocess',
            \'let colnum='.((canresize)?
            \                   ('barlen'):
            \                   (barlen)).'*linesprocessed/linestoprocess',])
            if showprogress!=2
                call add(formatfunction,
                \'if progress!=oldprogress || '.
                \   'colnum!='.((canresize)?
                \                   ('s:progress.'):
                \                   ('')).'oldcolnum')
            endif
            if canresize
                call extend(formatfunction, [
                \'let bar="[".repeat("=", colnum).">".'.
                \           'repeat(" ", barlen-colnum)."] "',
                \])
            else
                call extend(formatfunction, [
                \'if colnum!=oldcolnum',
                \'    let barstart.=repeat("=", colnum-oldcolnum)',
                \'    let barend=barend[(colnum-oldcolnum):]',
                \'endif',
                \'let bar=((barstart).">".(barend))',
                \])
            endif
            call extend(formatfunction, [
            \'let bar.='.
            \   ((showprogress==2)?
            \       ('repeat(" ", '.opts.linenumlen.'-len(curline)).curline.'.
            \        '"/'.endline.' ".'):
            \       ('')).
            \   'repeat(" ", 3-len(progress)).progress."%%"',
            \'call setwinvar(0, "&statusline", bar)',
            \'redrawstatus',])
            if showprogress!=2
                call add(formatfunction, 'endif')
            endif
            call extend(formatfunction, [
            \'let oldprogress=progress',
            \'let '.((canresize)?
            \                   ('s:progress.'):
            \                   ('')).'oldcolnum=colnum'])
            if canresize
                call extend(formatfunction, [
                \'let s:progress.progress=progress',
                \'let s:progress.linesprocessed=linesprocessed',
                \])
                if showprogress==2
                    call add(formatfunction,
                    \'let s:progress.curline=curline')
                endif
            endif
        endif
        "▶3 Обработка удалённых строк
        " Если не включён режим разности, то никаких удалённых строк быть не 
        " может
        if &diff
            call extend(formatfunction, [
            \'let filler=diff_filler(curline)',
            \'if filler>0',
            \'    let curstrstart='.
            \           ((has_key(cformat, 'linestart'))?
            \               (cf.get('linestart', 2.
            \                       ((collapsafter)?
            \                           ('+(filler>='.collapsafter.')'):
            \                           ('')), 'fillspec', 'curline', '""')):
            \               ('""')),])
                "▶4 foldcolumn
                if foldcolumn
                    call add(formatfunction,
                    \'let curstrstart.='.
                    \   ((persistentfdc)?
                    \       ('foldcolumns[fillfoldlevel][2]'):
                    \       (cf.get('foldcolumn', 'foldcolumns[fillfoldlevel]',
                    \               'fcspec', 'curline', 'fillfoldlevel',
                    \               'curstrstart'))))
                endif
                "▶4 Знаки
                if dosigns
                    call add(formatfunction,
                    \'let curstrstart.='.
                    \   ((persistentsc)?
                    \       ('nosignsc'):
                    \       (cf.get('sign', '"  "', 'scspec', 'curline', 0,
                    \               'curstrstart'))))
                endif
                "▶4 Номер строки
                if donr || dornr
                    call add(formatfunction,
                    \'let curstrstart.='.cf.get('linenr', '""', 'nrspec',
                    \                           'curline', '""'))
                endif
                "▶4 Заполнитель
                if !persistentfiller
                    if collapsafter
                        call add(formatfunction, 'if filler<'.collapsafter)
                    endif
                    call extend(formatfunction, [
                    \'let curfil=filler',
                    \'while curfil',
                    \'    let curstr=curstrstart',
                    \'    let curstr.='.cf.get('difffiller',
                    \                          s:F.squote(opts.difffillchar),
                    \                          'fillspec', 'curline', 'curfil',
                    \                          'curstr'),
                    \])
                    if has_key(cformat, 'lineend')
                        call add(formatfunction,
                        \'let curstr.='.cf.get('lineend', 2, 'fillspec',
                        \                      'curline', 0, 'curstr'))
                    endif
                    call extend(formatfunction, [
                    \'    call add(r, curstr)',
                    \'    let curfil-=1',
                    \'endwhile'
                    \])
                    if collapsafter
                        call extend(formatfunction, [
                        \'else',
                        \'    let curstr=curstrstart',
                        \'    let curstr.='.cf.get('collapsedfiller', 'filler',
                        \                          'fillspec', 'curline',
                        \                          'curstr')])
                        if has_key(cformat, 'lineend')
                            call add(formatfunction,
                            \'let curstr.='.cf.get('lineend', 3, 'fillspec',
                            \                      'curline', 0, 'curstr'))
                        endif
                        call extend(formatfunction, [
                        \'    call add(r, curstr)',
                        \'endif',
                        \])
                    endif
                " Удалённая строка уже предсоздана
                else
                    call extend(formatfunction, [
                    \'    let curstr=curstrstart',
                    \'    let curstr.='.s:F.squote(fillerstr),])
                    if has_key(cformat, 'lineend')
                        call add(formatfunction,
                        \'let curstr.='.cf.get('lineend', 2, 'fillspec',
                        \                      'curline', 0, 'curstr'))
                    endif
                    call add(formatfunction,
                    \'let r+=repeat([curstr], filler)')
                endif
            "▶4 Обнуление текущей строки
            call extend(formatfunction, [
            \'    let curstr=""',
            \'endif',
            \'if curline>'.endline,
            \'    break',
            \'endif',
            \])
        endif
        "▶3 Обработка складок
        "▶4 Закрытые складки,
        " если нет foldcolumn и не требуется создавать остальные складки
        if !ignorefolds && !allfolds && !foldcolumn
            call extend(formatfunction, [
            \'if foldclosed(curline)!=-1',
            \'   let curstr='.
            \           ((has_key(cformat, 'linestart'))?
            \               (cf.get('linestart', 1, 'foldspec', 'curline',
            \                       '""')):
            \               ('""'))])
            if dosigns
                call add(formatfunction,
                \'let curstr.='.cf.get('sign', '"  "', 'foldspec', 'curline',
                \                      0, 'curstr'))
            endif
            if donr || dornr
                call add(formatfunction,
                \'let curstr.='.cf.get('linenr', cf.getnrstr('curline'),
                \                      'foldspec', 'curline', 'curstr'))
            endif
            call add(formatfunction,
            \'let curstr.='.cf.get('fold', 'foldtextresult(curline)',
            \                      'foldspec', 'curline', 'curstr'))
            if has_key(cformat, 'lineend')
                call add(formatfunction,
                \'let curstr.='.cf.get('lineend', 1, 'foldspec', 'curlne', 0,
                \                      'curstr'))
            endif
            call extend(formatfunction, [
            \'    call add(r, curstr)',
            \'    let curline=foldclosedend(curline)+1',
            \'    continue',
            \'else',
            \])
        "▶4 foldcolumn и остальные складки
        elseif allfolds || foldcolumn
            "▶5 Все складки
            if allfolds
                call extend(formatfunction, [
                \'if has_key(possiblefolds, curline)',
                \'    let pf=possiblefolds[curline]',])
                if has_key(cformat, 'foldend')
                    call extend(formatfunction, [
                    \'    if has_key(pf, "end")',
                    \'        call extend(r, pf.end)',
                    \'    endif',])
                endif
                if has_key(cformat, 'foldstart')
                    call extend(formatfunction, [
                    \'    if has_key(pf, "start")',
                    \'        call extend(r, pf.start)',
                    \'    endif',])
                endif
                call add(formatfunction,
                \'endif')
            endif
            "▶5 Закрытые складки
            if !ignorefolds
                call extend(formatfunction, [
                \'if !empty(closedfoldslist) && curline==closedfoldslist[0]',
                \'    let closedfoldslist=closedfoldslist[1:]',
                \'    call add(r, closedfolds[curline])',
                \])
                if !allfolds
                    call extend(formatfunction, [
                    \'let curline=remove(closedfoldsends, 0)+1',
                    \'let foldlevel-=1',
                    \'continue',])
                endif
                call add(formatfunction, 'endif')
            endif
        endif
        "▶3 Обработка нормальных строк
        "▶4 Объявление переменных
        " linestr  — текст строки целиком
        " linelen  — длина строки
        " curcol   — номер текущего символа
        " diffattr — указывает на наличие отличий
        " specialcolumns — словарь с «особыми» колонками: окончания тёгов,
        "                  cursorcolumn, …
        call extend(formatfunction, [
        \'let linestr=getline(curline)',
        \'let linelen=len(linestr)',
        \'let curcol=1',
        \'let diffattr='.((&diff)?('diff_hlID(curline, 1)'):(0)),
        \])
        "▶5 specialcolumns
        let hasspcol=0
        if !empty(tagregex) && has_key(cformat, 'tagend')
            let hasspcol=1
            call add(formatfunction,
            \'let specialcolumns='.string(specialcolumns))
        endif
        "▶5 Если есть отличия в строке (от другого буфера с &diff)
        " diffid берётся для символа за пределами строки, так как если строка 
        " частично отличается, то она подсвечивается [фиолетовым], но сами 
        " отличия подсвечиваются [красным]. Символ за пределами строки 
        " подсвечивается как вся строка.
        "
        " Для отличающихся строк подсветка линии складывается из цвета 
        " символа, определённого файлом подсветки синтаксиса и цвета фона, 
        " определённого наличием отличий. dspec — спецификация стиля обычных 
        " символов
        if &diff
            call extend(formatfunction, [
            \'if diffattr',
            \'    let diffid=diff_hlID(curline, linelen+1)',
            \'    let diffhlname=synIDattr(synIDtrans(diffid), "name", "'.
            \                             s:whatterm.'")',
            \'    let dspec=s:F.compiledspec(cformat, "Normal", '.
            \                                   'diffhlname)',
            \'endif',])
        endif
        "▶5 Пробелы в конце строки
        if has_key(listchars, 'trail')
            call extend(formatfunction, [
            \'let trail=len(matchstr(linestr, ''\v\s+$''))',
            \'if trail',
            \'    let linelen-=trail',
            \'    let linestr=linestr[:(linelen-1)].'.
            \                'substitute(linestr[(linelen):], " ", '.
            \                   s:F.squote(escape(listchars.trail[0],
            \                                               '&~\')).', "g")',
            \'endif',
            \])
        endif
        "▶4 Начало строки
        "▶5 linestart
        if has_key(cformat, 'linestart')
            call add(formatfunction,
            \'let curstr.='.cf.get('linestart', 0,
            \   ((&diff)?
            \       ('((diffattr)?(dspec):(normalspec))'):
            \       ('normalspec')), 'curline', 'curstr'))
        endif
        "▶5 Foldcolumn
        if foldcolumn
            if persistentfdc
                call add(formatfunction,
                \'let curstr.=foldcolumns[foldlevel][2-fdchange]')
            else
                call extend(formatfunction, [
                \'if has_key(foldcolumnstarts, curline)',
                \'    let curstr.=foldcolumnstarts[curline]',
                \'else',
                \'    let curstr.='.cf.get('foldcolumn',
                \                          'foldcolumns[foldlevel]',
                \                          'fcspec', 'curline', 'foldlevel',
                \                          'curstr'),
                \'endif',
                \])
            endif
        endif
        "▶5 Знак
        if dosigns
            call add(formatfunction,
            \'if has_key(opts.placedsigns, curline)')
            if persistentsc
                call add(formatfunction,
                \'let curstr.=scols[opts.placedsigns[curline][1].id]')
            else
                call extend(formatfunction, [
                \'let sign=opts.placedsigns[curline][1]',
                \'if has_key(sign, "texthl")',
                \'    let sspec=s:F.compiledspec(cformat, sign.texthl)',
                \'else',
                \'    let sspec=scspec',
                \'endif',])
                if s:whatterm is# 'gui'
                    call extend(formatfunction, [
                    \'if has_key(sign, "icon")',
                    \'    let curstr.='.cf.get('sign', 'sign.icon', 'sspec',
                    \                          'curline', 2, 'curstr'),
                    \'else',
                    \])
                endif
                call extend(formatfunction, [
                \'if has_key(sign, "text")',
                \'    let curstr.='.cf.get('sign', 'sign.text', 'sspec',
                \                          'curline', 1, 'curstr'),
                \'else',
                \'    let curstr.='.cf.get('sign', '"  "', 'scspec',
                \                          'curline', 1, 'curstr'),
                \'endif',
                \])
                if s:whatterm is# 'gui'
                    call add(formatfunction, 'endif')
                endif
            endif
            call add(formatfunction, 'else')
            if persistentsc
                call add(formatfunction, 'let curstr.=nosignsc')
            else
                call add(formatfunction,
                \'let curstr.='.cf.get('sign', '"  "', 'scspec', 'curline',
                \                      0, 'curstr'))
            endif
            call add(formatfunction, 'endif')
        endif
        "▶5 clstart
        if docline && has_key(cformat, 'clstart')
            call extend(formatfunction, [
            \'if iscline',
            \'    let curstr.='.cf.get('clstart', 'clspec','curline','curstr'),
            \'endif',
            \])
        endif
        "▶5 Номер
        if donr || dornr
            call add(formatfunction,
            \'let curstr.='.cf.get('linenr', cf.getnrstr('curline'),
            \                            ((docline)?
            \                               ('((curline=='.cline.')?'.
            \                                   '(nrclspec):'.
            \                                   '(nrspec))'):
            \                               ('nrspec')),
            \                      'curline', 'curstr'))
        endif
        "▶4 Обработка остальной строки
        if !empty(tagregex)
            call add(formatfunction, 'let ignoretag=0')
        endif
        call extend(formatfunction, [
        \'let id=0',
        \'while curcol<=linelen',
        \'    let startcol=curcol',
        \])
            if formatconcealed
                call add(formatfunction, 'let concealed=0')
            endif
            "▶5 Получение длины зоны с идентичной подсветкой
            "▶6 Тёги
            if empty(tagregex)
                let taglines=[]
            else
                let taglines=[
                            \'if !ignoretag',
                            \'    let tag=matchstr(linestr, ''\v\k@<!%''.'.
                            \             'curcol.''c%('.
                            \             s:F.squote(tagregex)[1:-2].
                            \             ')\k@!'')',
                            \'    if tag!=#""',
                            \'        let ignoretag=1',
                            \'        break',
                            \'    endif',
                            \'endif']
                call extend(formatfunction, [
                \'if !ignoretag',
                \'    let tag=matchstr(linestr, ''\v\k@<!%''.'.
                \             'curcol.''c%('.
                \             s:F.squote(tagregex)[1:-2].
                \             ')\k@!'')',
                \'else',
                \'    let tag=""',
                \'endif',
                \'if tag!=#""',
                \'    let ignoretag=1',
                \'else',
                \'    let ignoretag=(index(values(specialcolumns), "tag")!=-1)',
                \])
            endif
            "▶6 Скрытые символы
            call add(formatfunction,
            \'let id=synID(curline, curcol, 1)')
            if formatconcealed
                let nocconceal=(docline&&(stridx(&concealcursor, 'n')!=-1))
                if nocconceal
                    call add(formatfunction, 'if !iscline')
                endif
                call extend(formatfunction, [
                \'let concealinfo=synconcealed(curline, curcol)',
                \'let concealed=concealinfo[0]'])
                if nocconceal
                    call add(formatfunction, 'endif')
                endif
                call extend(formatfunction, [
                \'if concealed',
                \'    let curcol+=1',
                \'    while concealinfo==#synconcealed(curline, curcol)']+
                \taglines+[
                \'        let curcol+=1',
                \'    endwhile',])
                if &conceallevel==1
                    call add(formatfunction, 'if empty(concealinfo[1])')
                    if has_key(listchars, 'conceal')
                        call add(formatfunction,
                        \'let concealinfo[1]='.
                        \   s:F.squote(listchars.conceal[0]))
                    else
                        call add(formatfunction, 'let concealinfo[1]=" "')
                    endif
                    call add(formatfunction, 'endif')
                elseif &conceallevel==3
                    call add(formatfunction, 'let concealinfo[1]=""')
                endif
                call add(formatfunction, 'else')
            endif
            "▶6 Строка отличается
            if &diff
                " Для отличающихся строк подсветка линии складывается из цвета 
                " символа, определённого файлом подсветки синтаксиса и цвета 
                " фона, определённого наличием отличий. ddspec — спецификация 
                " стиля обычных символов, но не для всей строки, как dspec, 
                " а для текущего региона (нужно для форматирования спецсимволов)
                call extend(formatfunction, [
                \'if diffattr',
                \'    let diffid=diff_hlID(curline, curcol)',
                \'    let curcol+=1',
                \'    while id==synID(curline, curcol, 1) && '.
                \          'diffid==diff_hlID(curline, curcol) && '.
                \          ((hasspcol)?
                \               ('!has_key(specialcolumns, curcol) && '):('')).
                \          'curcol<=linelen']+taglines+[
                \'        let curcol+=1',
                \'    endwhile',
                \'else',
                \])
            endif
            "▶6 Строка не отличается или не включен режим различий
            call extend(formatfunction, [
            \'let curcol+=1',
            \'while id==synID(curline, curcol, 1) && '.
            \       ((hasspcol)?
            \            ('!has_key(specialcolumns, curcol) && '):("")).
            \       'curcol<=linelen']+taglines+[
            \'    let curcol+=1',
            \'endwhile',
            \])
            if &diff
                call add(formatfunction, 'endif')
            endif
            if formatconcealed
                call add(formatfunction, 'endif')
            endif
            if !empty(tagregex)
                call add(formatfunction, 'endif')
            endif
            "▶5 Форматирование части строки с идентичной подсветкой
            " cstr — текст найденной части
            if formatconcealed==1
                call extend(formatfunction, [
                \'if concealed',
                \'    let cstr=concealinfo[1]',
                \'else',
                \])
            endif
            call add(formatfunction,
            \'let cstr=strpart(linestr, startcol-1, curcol-startcol)')
            if formatconcealed==1
                call add(formatfunction, 'endif')
            endif
            "▶6 Получение спецификации подсветки найденной части
            if formatconcealed
                call add(formatfunction, 'if concealed')
                if formatconcealed==2
                    call add(formatfunction,
                    \'let hlname=synIDattr(synIDtrans(id), "name", "'.
                    \                      s:whatterm.'")')
                else
                    call add(formatfunction, 'let hlname="Conceal"')
                endif
                call add(formatfunction, 'else')
            endif
            if has_key(listchars, 'trail')
                call extend(formatfunction, [
                \'if trail==-1',
                \'    let hlname="SpecialKey"',
                \'else',
                \])
            endif
            call add(formatfunction,
            \'    let hlname=synIDattr(synIDtrans(id), "name", "'.
            \                          s:whatterm.'")')
            if has_key(listchars, 'trail')
                call add(formatfunction, 'endif')
            endif
            if formatconcealed
                call add(formatfunction, 'endif')
            endif
            if &diff
                call extend(formatfunction, [
                \'if diffattr',
                \'    let diffhlname=synIDattr(synIDtrans(diffid), "name", '.
                \                             '"'.s:whatterm.'")',
                \'    let spec='.cf.getspecstr('hlname', 'diffhlname'),
                \'    let ddspec='.cf.getspecstr('"Normal"', 'diffhlname'),
                \'else',])
            endif
            if dosigns
                call extend(formatfunction, [
                \'if has_key(opts.placedsigns, curline) && '.
                \   'has_key(opts.placedsigns[curline][1], "linehl")',
                \'    let spec=s:F.compiledspec(cformat, hlname, '.
                \                        'opts.placedsigns[curline][1].linehl)',
                \'else',
                \])
            endif
            call add(formatfunction,
            \'let spec='.cf.getspecstr('hlname'))
            if dosigns
                call add(formatfunction, 'endif')
            endif
            if &diff
                call add(formatfunction, 'endif')
            endif
            "▶6 Обработка табуляции и непечатных символов
            " rstartcol — длина обработанной части строки с учётом
            "             возможного наличия многобайтных символов
            if formatconcealed
                call add(formatfunction, 'if !concealed')
            endif
            call extend(formatfunction, [
            \'let idx=match(cstr, '.npregex.')',
            \'if idx!=-1',
            \'    let rstartcol=(s:F.stuf.strlen(linestr[:(startcol-1)]))',
            \'    while idx!=-1',])
                    "▶7 Объявление переменных
                    " fcstr — часть текущей подстроки до табуляции
                    " ridx  — Длина fcstr с учётом возможного наличия
                    "         многобайтных символов
                    call extend(formatfunction, [
                    \'let fcstr=((idx)?(cstr[:(idx-1)]):(""))',
                    \'let ridx=(s:F.stuf.strlen(fcstr))',
                    \'let istab=(cstr[idx]==#"\t")',])
                    "▶7 Форматирование строки до табуляции
                    if !has_key(listchars, 'tab')
                        call add(formatfunction, 'if !istab')
                    endif
                    call extend(formatfunction, [
                    \'if fcstr!=""',
                    \'    let curstr.='.cf.get('line', 'fcstr',
                    \           ((&diff)?
                    \               ('((diffattr)?(ddspec):(spec))'):
                    \               ('(spec)')), 'curline', 'idx', 'curstr'),
                    \'endif',])
                    if !has_key(listchars, 'tab')
                        call add(formatfunction, 'endif')
                    endif
                    "▶7 Представление табуляции
                    " i — видимая длина символа табуляции
                    let longtab=((&list && has_key(listchars, 'tab')) || !&list)
                    if longtab
                        call extend(formatfunction, [
                        \'if istab',
                        \'    let i='.&tabstop.'-'.
                        \           '((rstartcol+ridx-1)%('.&tabstop.'))',])
                            "▶8 Есть ключ «tab» у настройки 'listchars'
                            if has_key(listchars, 'tab')
                                " tabstr — Представление символа «\t»
                                call extend(formatfunction, [
                                \'let tabstr='.
                                \   s:F.squote(listchars.tab[0]),
                                \'let tabstr.=repeat('.
                                \   s:F.squote(listchars.tab[1]).', '.
                                \'i-1)',
                                \'let curstr.='.cf.get('line', 'tabstr',
                                \   ((&diff)?
                                \       ('((diffattr)?(ddspec):'.
                                \                    '('.spspecstr.'))'):
                                \       (spspecstr)), 'curline', 'idx',
                                \                     'curstr'),
                                \'let cstr=cstr[(idx+1):]',])
                            "▶8 Указанного ключа нет
                            else
                                call extend(formatfunction, [
                                \'let tabstr=repeat(" ", i)',
                                \'let cstr=fcstr.tabstr.cstr[(idx+1):]',])
                            endif
                        call add(formatfunction, 'else')
                    endif
                    "▶7 Представление спецсимвола
                    call extend(formatfunction, [
                    \'    let cstr=cstr[(len(fcstr)):]',
                    \'    let char=matchstr(cstr, "\\v^.")',
                    \'    let cstr=cstr[(len(char)):]',])
                    if has_key(listchars, 'nbsp')
                        call extend(formatfunction, [
                        \'if char is# " "',
                        \'    let curstr.='.cf.get('line',
                        \   s:F.squote(listchars.nbsp[0]),
                        \       ((&diff)?
                        \           ('((diffattr)?(ddspec):'.
                        \                        '('.spspecstr.'))'):
                        \           (spspecstr)), 'curline', 'idx', 'curstr'),
                        \'else',])
                    endif
                    call add(formatfunction,
                    \'let curstr.='.cf.get('line', 'strtrans(char)',
                    \       ((&diff)?
                    \           ('((diffattr)?(ddspec):('.ntspecstr.'))'):
                    \           (ntspecstr)), 'curline', 'idx', 'curstr'))
                    if has_key(listchars, 'nbsp')
                        call add(formatfunction, 'endif')
                    endif
                    if longtab
                        call add(formatfunction, 'endif')
                    endif
                    "▶7 Завершение цикла
                    " Следующий символ
                    call extend(formatfunction, [
            \'        let idx=match(cstr, '.npregex.')',
            \'    endwhile',
            \'endif'])
            "▶7 Скрытые символы
            if formatconcealed
                call add(formatfunction, 'endif')
                if formatconcealed==2
                    call extend(formatfunction, [
                    \'if concealed',
                    \'    let curstr.=cformat.concealed.f(concealinfo[1], '.
                    \                                    'conspec, curline, '.
                    \                                    'curcol, curstr, '.
                    \                                    'opts, cstr, spec)',
                    \'else',
                    \])
                endif
            endif
            "▶6 Сброс trail
            if has_key(listchars, 'trail')
                call extend(formatfunction, [
                \'if trail>0 && curcol>linelen',
                \'    let linelen+=trail',
                \'    let trail=-1',
                \'endif',])
            endif
            "▶6 Включение отформатированной части
            call extend(formatfunction, [
            \'if cstr!=""',
            \'    let curstr.='.cf.get('line', 'cstr', 'spec', 'curline',
            \                                  'curcol', 'curstr'),
            \'endif',])
            if formatconcealed==2
                call add(formatfunction, 'endif')
            endif
            "▶5 Тёги
            if !empty(tagregex)
                if has_key(cformat, 'tagend')
                    call extend(formatfunction, [
                    \'if has_key(specialcolumns, curcol) && '.
                    \       'specialcolumns[curcol] is# "tag"',
                    \'    let curstr.='.cf.get('tagend', 'tag', 'spec',
                    \                          'curline', 'curcol', 'curstr'),
                    \'    call remove(specialcolumns, curcol)',
                    \'    let tag=""',
                    \'    let ignoretag=0',
                    \'endif',])
                endif
                if has_key(cformat, 'tagstart')
                    call extend(formatfunction, [
                    \'if tag!=#""',
                    \'    let curstr.='.cf.get('tagstart', 'tag', 'spec',
                    \                          'curline', 'curcol', 'curstr'),])
                    if has_key(cformat, 'tagend')
                        call add(formatfunction,
                        \'    let specialcolumns[curcol+len(tag)]="tag"')
                    endif
                    call add(formatfunction, 'endif')
                endif
            endif
            "▲5
        call add(formatfunction, 'endwhile')
        "▶5 Форматирование символа конца строки
        if has_key(listchars, 'eol')
            call add(formatfunction,
            \'let curstr.='.cf.get('line',
            \       s:F.squote(listchars.eol[0]),
            \       ((&diff)?
            \           ('((diffattr)?(dspec):('.ntspecstr.'))'):
            \           (ntspecstr)), 'curline', 'curcol+1', 'curstr'))
        endif
        "▶5 Конец строки
        if docline && has_key(cformat, 'clend')
            call extend(formatfunction, [
            \'if iscline',
            \'    let curstr.='.cf.get('clend', 'clspec', 'curline', 'curstr'),
            \'endif',
            \])
        endif
        if has_key(cformat, 'lineend')
            call add(formatfunction,
            \'let curstr.='.cf.get('lineend', 0, 'normalspec', 'curline',
            \                      'curcol', 'curstr'))
        endif
        "▶5 Складки
        if !ignorefolds && !allfolds && !foldcolumn
            call add(formatfunction, 'endif')
        endif
        "▶5 Завершение цикла
        call extend(formatfunction, [
    \'    call add(r, curstr)',
    \'    let curline+=1',
    \'endwhile'
    \])
    "▶2 Начало и конец представления
    if allfolds
        call extend(formatfunction, [
        \'if has_key(possiblefolds, curline)',
        \'    let pf=possiblefolds[curline]',
        \'    if has_key(pf, "end")',
        \'        call extend(r, pf.end)',
        \'    endif',
        \'    if has_key(pf, "start")',
        \'        call extend(r, pf.start)',
        \'    endif',
        \'endif',
        \])
    endif
    if !sbsd
        if has_key(cformat, 'begin')
            call add(formatfunction,
            \'call insert(r, cformat.begin.f(normalspec, "", opts, '.
            \                               'cformat.stylestr))')
        endif
        if has_key(cformat, 'end')
            call add(formatfunction,
            \'call add(r, cformat.end.f(normalspec, '.endline.', "", opts, '.
            \                          'cformat.stylestr))')
        endif
    endif
    call add(formatfunction, 'return r')
call add(formatfunction, 'endfunction')
    " " FIXME remove debugging line
    " call writefile(formatfunction, $HOME."/tmp/vim/cffunc.vim", 1)
    execute join(formatfunction, "\n")
    " " FIXME
    " execute 'breakadd func' debugline string(d.compiledformat)[10:-3]
    "▶2 r
    let r=d.compiledformat()
    unlet s:F.compiledspec
    "▶2 s:progress
    if showprogress && canresize
        let s:progress.showprogress=0
    endif
    "▶2 finish if sbsd is active
    if sbsd
        return r
    endif
    "▶2 cformat.nolf
    if has_key(cformat, 'nolf') && cformat.nolf
        let r=[join(r, '')]
    endif
    "▶2 cformat.haslf
    if has_key(cformat, 'haslf') && cformat.haslf
        let oldr=r
        let r=[]
        for item in oldr
            let r+=split(item, "\n")
        endfor
    endif
    "▶2 Удалить кэш, если это требуется
    if !s:_f.getoption('KeepColorCache')
        let cformat.cache={}
        let cformat.stylestr=''
    endif
    "▲2
    unlet cformat.frunning
    return r
endfunction
"▶2 wrap function
let s:F.format=s:_f.wrapfunc({'function': s:F.format,
            \               '@altervars': [['+window'],
            \                              ['&l:laststatus'],
            \                              ['&l:statusline'],
            \                              ['&l:foldminlines'],]})
"▶1 addformat
function s:F.addformat(type, format)
    let s:formats[a:type]=deepcopy(a:format)
    return 1
endfunction
"▶1 delformat
function s:F.delformat(type)
    if has_key(s:formats, a:type)
        unlet s:formats[a:type]
        if has_key(s:compiledfmts, a:type)
            unlet s:compiledfmts[a:type]
            return 2
        endif
        return 1
    endif
    return 0
endfunction
"▶1 purgecolorcaches
function s:F.purgecolorcaches()
    let id=hlID('Normal')
    for cformat in values(s:compiledfmts)
        let cformat.cache={}
        let cformat.stylestr=''
        let cformat.opts.fgcolor=s:F.getcolor(synIDattr(id, 'fg#', s:whatterm))
        let cformat.opts.bgcolor=s:F.getcolor(synIDattr(id, 'bg#', s:whatterm))
        if empty(cformat.opts.fgcolor)
            let cformat.opts.fgcolor=((&background is# 'dark')?('#ffffff'):
                        \                                      ('#000000'))
        endif
        if empty(opts.bgcolor)
            let cformat.opts.bgcolor=((&background is# 'dark')?('#000000'):
                        \                                      ('#ffffff'))
        endif
    endfor
endfunction
augroup FormatPurgeColorCaches
    autocmd ColorScheme * call s:F.purgecolorcaches()
augroup END
let s:_augroups+=['FormatPurgeColorCaches']
"▶1 cmd
"▶2 s:cmd.@FWC
let s:filcomprefs=
            \              '           columns :=(-1)  |earg range -1 inf '.
            \              '?               to         path W '.
            \              '?      starttagreg :=(0)   '.s:checkreg.
            \              '?        endtagreg :=(0)   '.s:checkreg.
            \              '!           number :=(-1) '.
            \              '!   relativenumber :=(-1) '.
            \              '!             list :=(-1) '.
            \              '!+1           tags :=(-1)  in [local all] '.
            \              '!+1     foldcolumn :=(-2)  |earg range -1 inf '.
            \              '!            folds :=(-1) '.
            \              '!            signs :=(-1) '.
            \              '!+1      concealed :=(-1)  in [shown both] '.
            \              '!+1       progress :=(-1)  in [percent lines] '
let s:filformats='[:*_f.getoption("DefaultFormat") key formats~start]'
let s:cmd['@FWC']=[
            \'-onlystrings _ _ '.
            \'<diffformat ('.s:filformats.'{'.s:filcomprefs.'}) '.
            \ '    format ('.s:filformats.'{'.s:filcomprefs.
            \              '!+1  collapsfiller :=(-1)  |earg range  0 inf '.
            \              '!         allfolds :=(-1) '.
            \             '}) '.
            \ '      list - '.
            \ 'purgecolorcaches -'.
            \'>', 'filter']
"▲2
function s:cmd.function(startline, endline, action, ...)
    let action=a:action
    "▶2 Действия
    if action is# 'format' || action is# 'diffformat'
        let result=call(s:F.format, [a:1, a:startline, a:endline, a:2,
                    \                (action is# 'diffformat')], {})
        if has_key(a:2, 'to')
            call writefile(result, a:2.to, 1)
        else
            new ++enc=utf-8
            call setline(1, result)
        endif
        return 1
    elseif action is# 'list'
        echo join(keys(s:formats), "\n")
        return 1
    elseif action is# 'purgecolorcaches'
        call s:F.purgecolorcaches()
        return 1
    endif
    "▲2
    return 0
endfunction
"▶1 Completion
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
call add(s:cmdcomplete, '<'.
            \((has('diff'))?
            \   ('diffformat ('.s:cmpformats.'{'.s:cmpcomprefs.'})'):
            \   ('')).
            \   '    format ('.s:cmpformats.'{'.s:cmpcomprefs.
            \           ((has('diff'))?(   '!+1  collapsfiller  _ '):('')).
            \           ((has('folding'))?('!         allfolds '   ):('')).'})'.
            \   '      list - '.
            \   'purgecolorcaches -'.
            \  '>')
"▶1 format feature
let s:format={}
"▶2 format.add :: {f}, name, dict → _ + fdict, s:formats
function s:format.add(plugdict, fdict, name, dict)
    let s:formats[a:name]=extend(deepcopy(a:dict), {'id': a:name,
                \                                 'plid': a:plugdict.id,})
    let a:fdict[a:name]=s:formats[a:name]
endfunction
let s:format.add=s:_f.wrapfunc({'function': s:format.add,
            \'@FWC':['_ _ '.
            \        '(#misscol not key formats) '.
            \        '(haskey line '.
            \         'dict {?in keylist  type string '.
            \                    'strlen  isfunc 1 '.
            \                 'strescape  type string '.
            \                     'haslf  bool '.
            \                      'nolf  bool})', 'check'],
            \})
"▶2 formatunload :: {f} → + fdict, s:formats
function s:F.formatunload(plugdict, fdict)
    call map(keys(a:fdict), 's:F.delformat(v:val)')
endfunction
"▶2 Register feature
call s:_f.newfeature('format', {'cons': s:format,
            \                 'unload': s:F.formatunload,})
unlet s:format
"▶1
if !has('syntax')
    call s:_f.warn('synnsup')
endif
" vim: ft=vim:ts=8:fdm=marker:fenc=utf-8:fmr=▶,▲

