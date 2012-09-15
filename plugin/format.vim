"▶1 Начало
scriptencoding utf-8
if !exists('s:_pluginloaded')
    execute frawor#Setup('3.0', {'@/resources': '0.0',
                \                 '@/commands': '0.0',
                \                '@/functions': '0.0',
                \                  '@/options': '0.0',
                \                       '@/os': '0.0',
                \                      '@/fwc': '0.0',
                \          '@/fwc/constructor': '4.1',
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
            \   'nofloat': 'You must either use terminal vim or vim compiled '.
            \              'with +float feature',
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
"▶1 addsubs
function s:F.addsubs(var, ...)
    return a:var.join(map(copy(a:000), '((type(v:val)=='.type(0).')?'.
                \                           '("[".v:val."]"):'.
                \                      '((v:val=~#"\\W")?'.
                \                           '("[".s:F.squote(v:val)."]")'.
                \                      ':'.
                \                           '(".".v:val)))'), '')
endfunction
"▶1 getcolors
function s:F.getcolors(file)
    if !filereadable(a:file)
        call s:_f.throw('misscol')
    endif
    return map(filter(readfile(a:file, 'b'), 'v:val[:1] is# "- "'),'v:val[3:9]')
endfunction
"▶1 getcolorfile
function s:F.getcolorfile()
    let r=s:_f.getoption('ColorFile')
    if type(r)!=type('')
        if s:whatterm isnot# 'gui'
            let r=s:_r.os.path.join(s:_frawor.runtimepath, 'config',
                        \                     'formatvim',
                        \                     'colors-default-'.&t_Co.'.yaml')
        endif
        if s:whatterm is# 'gui' || !filereadable(r)
            let r=s:_r.os.path.join(s:_frawor.runtimepath, 'config',
                        \                     'formatvim',
                        \                     'colors-default.yaml')
        endif
    elseif stridx(r, '/')==-1 && stridx(r, s:_r.os.sep)
        let r=s:_r.os.path.join(s:_frawor.runtimepath, 'config', 'formatvim', r)
    endif
    return r
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
    let s:colors=s:F.getcolors(s:F.getcolorfile())
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
        elseif atv is# '_' && str[1] is# '_'
            let arg=matchstr(str, '\v^_\w+\@@=', 1)
            if empty(arg)
                unlet arg
            else
                let str=str[len(arg)+2:]
                call s:F.inqreq(a:req, 'a:opts')
                let arg=(a:atargs.opts).'.'.arg
            endif
        elseif atv is# '_'
            let arg=matchstr(str, '\v^\l+\@@=', 1)
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
function s:F.fmtprepare(format)
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
    for [o, v] in items(get(a:format, 'addopts', {}))
        let opts['_'.o]=deepcopy(v)
        unlet v
    endfor
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
            \'linestart':    '%!let ide=substitute(@_strescape@, "@\\{3}", '.
            \                                     '"v:val.name", "")!%'.
            \                '<p class="s%S %''@__stylelist@[@@@]''%"'.
            \                  '%''((@@@<=1)?'.
            \                       '(" id=\"".'.
            \                        '((@@@==0)?'.
            \                            '("line"):'.
            \                            '("fold")).'.
            \                        '@-@."-".@_sbsd@."\""):'.
            \                       '(""))''%>'.
            \                '%''join(map(copy(get(@_curtags@, @-@, [])), '.
            \                            '"''<span id=\"''.".ide.".''\">''"), '.
            \                        '"")''%',
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
            \'lineend':      '%''repeat("</span>", '.
            \                          'len(get(@_curtags@, @-@, [])))''%</p>',
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
            \'addopts': {'stylelist': ['Line', 'Fold', 'DiffFiller',
            \                          'CollapsedFiller']},
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
unlet s:styleattr
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
            \'begin':        '%>((&background is# "dark")?'.
            \                   '("[sh=".substitute(expand("%:p:~%"), "\\V[]",'.
            \                   '''\="&#".char2nr(submatch(0)).";"'', "g")." '.
            \                   '(Created by format.vim)]"):'.
            \                   '("[codebox]"))',
            \'end':          '%>((&background is# "dark")?'.
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
"▶2 CSI
let s:c={}
if s:whatterm is# 'gui'
    function s:c.rgbtolist(color)
        return map(split(a:color[1:], '\v(..)@<='), 'eval("0x".v:val)')
    endfunction
    function s:c.distance(point1, point2)
        " For all x>0, y>0 sqrt(x)>sqrt(y) <=> x>y, thus no need in using 
        " floating-point arithmetics. 255*255*3 which is the maximum value is 
        " far beyond 32-bit border (needs 18 bits)
        return eval(join(map(map(range(len(a:point1)),
                    \            'a:point1[v:val]-a:point2[v:val]'),
                    \        'v:val*v:val'),
                    \    '+'))
    endfunction
    function s:c.rgbtoterm(color)
        if !exists('s:colors')
            let s:colors=s:F.getcolors(s:F.getcolorfile())
            lockvar! s:colors
        endif
        if !exists('s:colpoints')
            let s:colpoints=map(copy(s:colors), 'self.rgbtolist(v:val)')
            lockvar! s:colpoints
            let s:colmap={}
        elseif has_key(s:colmap, a:color)
            return s:colmap[a:color]
        endif
        let curcpoint=self.rgbtolist(a:color)
        let distances=map(copy(s:colpoints), 'self.distance(curcpoint, v:val)')
        let mindistance=min(distances)
        let r=index(distances, mindistance)
        let s:colmap[a:color]=r
        return r
    endfunction
else
    function s:c.rgbtoterm(color)
        return index(s:colors, a:color)
    endfunction
endif
function s:c.tocsi(color, isbg)
    let colcode=self.rgbtoterm(a:color)
    if colcode==0
        return "\e[".(10*a:isbg+39)."m"
    elseif colcode==16
        return "\e[".(10*a:isbg+30)."m"
    elseif colcode<8
        return "\e[".(10*a:isbg+30+colcode)."m"
    elseif colcode<16
        return "\e[".(10*a:isbg+90+colcode-8)."m"
    else
        return "\e[".(10*a:isbg+38).";5;".colcode."m"
    endif
endfunction
function s:c.strlen(str)
    return s:F.stuf.strlen(substitute(a:str, "\e\\[[^m]*m", '', 'g'))
endfunction
let s:formats.csi={
            \'style': '%>(@bold@     ?"\e[1m":"").'.
            \           '(@inverse@  ?"\e[7m":"").'.
            \           '(@underline@?"\e[4m":"").'.
            \           '(@italic@   ?""     :"").'.
            \           '(empty(@fgcolor@)?@__funcs@.tocsi(@_fgcolor@, 0):'.
            \                             '@__funcs@.tocsi(@fgcolor@,  0)).'.
            \           '(empty(@bgcolor@)?@__funcs@.tocsi(@_bgcolor@, 1):'.
            \                             '@__funcs@.tocsi(@bgcolor@,  1))',
            \'line':   "%:%s\e[0m",
            \'lineend': '%:',
            \'strlen': remove(s:c, 'strlen'),
            \'addopts': {'funcs': s:c},
        \}
unlet s:c
"▶2 tokens
let s:formats.tokens={
            \'begin':           "%>string(['b', @~@, expand('%'), bufnr('%')])",
            \'sbsdstart':       "['ss', %'string(@_vertseparator@)'%, ",
            \'foldstart':       "['fs', %:, %s, %C]",
            \'foldend':         "['fe', %:, %s, %C]",
            \'linestart':       "['%'@__linetypes@[@@@]'%', %:, ",
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
            \'addopts':         {'linetypes': ['lr', 'lf', 'ld', 'lc']},
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
                \   (repeat(' ', len(s:progress.elnr)-
                \                len(s:progress.clnr)).
                \    (s:progress.clnr).
                \    '/'.(s:progress.elnr).' '):
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
    let tag2flmap={}        " Словарь: имя тёга — список местонахождений
    let fcontents={}        " Кэш содержимого файлов
    " Список символов, которых надо дополнительно экранировать
    let addescapes=s:_f.getoption('AddTagCmdEscapes')
    let ignoredtags={}
    let curfl2tagsmap={}    " Словарь: номер линии (в этом файле) — список тёгов
    "▶2 Обработка тёгов (основной цикл)
    for tag in tags
        "▶3 Объявление переменных
        " Имя файла, содержащего определение
        let tfname=fnamemodify(tag.filename, ':.')
        " Перепенная, определяющая, не совпадает ли файл с тёгом с данным
        let incurf=(tfname is# fname)
        if a:ignoretags && !incurf
            continue
        elseif has_key(ignoredtags, tag.name)
            continue
        elseif !search('\V\k\@<!'.a:starttagreg.escape(tag.name, '\').
                    \  a:endtagreg.'\k\@!', 'nwc')
            let ignoredtags[tag.name]=1
            continue
        endif
        if !has_key(tag2flmap, tag.name)
            let tag2flmap[tag.name]=[]
        endif
        call add(tag2flmap[tag.name], [tag])
        "▶3 Тёг находится в текущем файле
        if incurf
            if tag.cmd[0] is# '/'
                try
                    let linenr=search(
                                \escape(
                                \   substitute(tag.cmd, '\m^/\|/$', '', 'g'),
                                \   addescapes), 'nw')
                catch
                endtry
            else
                let linenr=(+matchstr(tag.cmd, '\v^\d+'))
            endif
            if linenr
                call insert(tag2flmap[tag.name][-1], linenr)
                let curfl2tagsmap[linenr]=get(curfl2tagsmap, linenr, [])+[tag]
            endif
            if len(tag2flmap[tag.name][-1])==2
                if len(tag2flmap[tag.name])>1
                    call insert(tag2flmap[tag.name],
                                \remove(tag2flmap[tag.name], -1))
                endif
            else
                call remove(tag2flmap[tag.name], -1)
            endif
        "▶3 Тёг находится в другом файле
        elseif filereadable(tfname)
            let linenr=0
            if tag.cmd[0] is# '/'
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
                let linenr=(+matchstr(tag.cmd, '\v^\d+'))
            endif
            if linenr
                call insert(tag2flmap[tag.name][-1], [tfname, linenr])
            else
                call remove(tag2flmap[tag.name], -1)
            endif
        "▶3 Файл, в котором должен находится тёг, не существует
        else
            call remove(tag2flmap[tag.name], -1)
        endif
    endfor
    "▶2 Удаление лишних записей
    call filter(tag2flmap, '!empty(v:val)')
    let maxduptags=s:_f.getoption('MaxDupTags')
    if maxduptags
        call filter(tag2flmap, 'type(get(v:val, '.maxduptags.', 0))=='.type(0))
    endif
    return [tag2flmap, curfl2tagsmap]
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
function s:cf.new(cformat)
    return extend(copy(self), {'cformat': a:cformat,
                \              'opts':    a:cformat.opts})
endfunction
"▶1 cf.has
function s:cf.has(key)
    return has_key(self.cformat, a:key)
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
            let condition.=' && !(has_key(opts.placedsigns, clnr) && '.
                        \     'has_key(opts.placedsigns[clnr][1], "linehl"))'
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
"▶1 ff
let s:ff={}
let s:ffcomp={}
"▶2 .let
" function s:ffcomp.letlist(r, toextend, indent, item)
    " if len(a:item)==1
        " return self._comp.let(a:r, a:toextend, a:indent, a:item[0])
    " else
        " call add(a:r, repeat(' ', &sw*a:indent).'let '.
                    " \'['.join(map(copy(a:item), 'v:val[0]'), ',').']='.
                    " \'['.join(map(copy(a:item), 'v:val[1]'), ','))
    " endif
" endfunction
" function s:ff.let(var, expr)
    " if get(self._l, 0) is# 'letlist'
        " let self._l[1]+=[a:var, a:expr]
        " return self
    " else
        " return self._out()._deeper('letlist', [a:var, a:expr])
    " endif
" endfunction
"▶2 ff.letspec
function s:ff.letspec(spname, ...)
    return self.let(a:spname.'spec',
                \   's:F.compiledspec(cformat,'.
                \                 join(map(copy(a:000), '"''".v:val."''"'),',').
                \                   ')')
endfunction
"▶2 letcf
function s:ff.letcf(var, ...)
    if self.__cf.has(a:1)
        return self.let(a:var, call(self.__cf.get, a:000+['""'], self.__cf))
    else
        return self.let(a:var, '""')
    endif
endfunction
"▶2 appendcf
function s:ff.appendcf(var, ...)
    if self.__cf.has(a:1)
        return self.append(a:var, call(self.__cf.get, a:000+[a:var], self.__cf))
    else
        return self
    endif
endfunction
"▶2 letc
function s:ff.letc(var, ...)
    let self.__curvar=a:var
    if a:0>1
        return call(self.letcf, [self.__curvar]+a:000, self)
    else
        return call(self.let,   [self.__curvar, a:1],  self)
    endif
endfunction
"▶2 appendc
function s:ff.appendc(...)
    if a:0>1
        return call(self.appendcf, [self.__curvar]+a:000, self)
    else
        return call(self.append,   [self.__curvar, a:1],  self)
    endif
endfunction
"▶2 newff
function s:F.newff(cf)
    let r=s:_r.new_constructor()
    call extend(r, s:ff)
    call extend(r._comp, s:ffcomp)
    let r.append=r.strappend
    let r.__cf=a:cf
    return r
endfunction
"▶1 s:NRSort :: Integer, Integer → -1|1
" We really don’t care about the order of equal integers
function s:NRSort(a, b)
    return a:a>a:b ? 1 : -1
endfunction
let s:_functions+=['s:NRSort']
"▶1 getcompfmt
let s:compiledfmts={}
function s:F.getcompfmt(type)
    if !has_key(s:compiledfmts, a:type)
        let s:compiledfmts[a:type]=s:F.fmtprepare(s:formats[a:type])
    endif
    return s:compiledfmts[a:type]
endfunction
"▶1 initopts
function s:F.initopts(type, slnr, elnr, options, cf, sbsd)
    let opts=a:cf.opts
    unlockvar opts
    " TODO Control it with a:options?
    let opts.linenumlen=max([len(a:elnr), &numberwidth])
    let opts.sbsd=a:sbsd
    "▶2 Intended display width
    let columns=0+(((a:options.columns)+0)?
                \       (a:options.columns):
                \       (get(s:formats[a:type], 'columns', winwidth(0))))
    if columns==-1
        let columns=max(map(range(1, line('$')), 'virtcol([v:val, "$"])-1'))
    endif
    let opts.columns=columns
    "▶2 Folds
    " Ignore folds if IgnoreFolds is set, there is no “fold” key or vim does not 
    " support folding.
    let ignorefolds=((a:options.folds==-1)?
                \       (s:_f.getoption('IgnoreFolds')):
                \       (!a:options.folds)) ||
                \!has('folding')
    let allfolds=!(ignorefolds || a:sbsd) &&
                \((a:options.allfolds==-1)?
                \       (s:_f.getoption('AllFolds')):
                \       (a:options.allfolds)) &&
                \(a:cf.has('foldstart') ||
                \ a:cf.has('foldend'))
    let foldcolumn=0
    if !ignorefolds && a:cf.has('foldcolumn')
        " TODO Support for formatting foldcolumn using .line
        let foldcolumn=((a:options.foldcolumn==-2)?
                \           (s:_f.getoption('FoldColumn')):
                \           (a:options.foldcolumn))
        if foldcolumn==-1
            let foldcolumn=&foldcolumn
        endif
    endif
    let ignorefolds=ignorefolds || !a:cf.has('fold')
    let opts.ignorefolds = ignorefolds
    let opts.allfolds    = allfolds
    let opts.foldcolumn  = foldcolumn
    let opts.columns    += foldcolumn
    "▶2 Concealed characters
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
    if formatconcealed==2 && !a:cf.has('concealed')
        let formatconcealed=1
    endif
    let opts.formatconcealed=formatconcealed
    "▶2 Signs
    let dosigns=0
    if a:cf.has('sign')
        " TODO Support for formatting signs column using .line
        let dosigns=((a:options.signs==-1)?
                    \   (!s:_f.getoption('IgnoreSigns')):
                    \   (a:options.signs))
        if dosigns
            let gsr=s:F.getsigns(bufnr('%'))
            let opts.signdefinitions=gsr[0]
            let opts.placedsigns=gsr[1]
            if empty(opts.placedsigns)
                let dosigns=0
            endif
            let opts.columns+=2
        endif
    endif
    let opts.dosigns=dosigns
    "▶2 Cursor
    let opts.ignorecursor=s:_f.getoption('IgnoreCursor')
    let opts.cline=line('.')
    let opts.docline=(!opts.ignorecursor && &cursorline &&
                \     a:slnr<=opts.cline && opts.cline<=a:elnr)
    "▶2 Line numbers
    if a:cf.has('linenr')
        let opts.donr=((a:options.number==-1)?
                    \       (s:_f.getoption('NoLineNR')):
                    \       (!a:options.number))
        if opts.donr!=-1
            let opts.donr=!opts.donr
        endif
        let opts.dornr=((a:options.relativenumber==-1)?
                    \       (s:_f.getoption('RelativeNumber')):
                    \       (a:options.relativenumber))
        if opts.dornr==-1
            if exists('+relativenumber')
                let opts.dornr=&relativenumber
            else
                let opts.dornr=0
            endif
        endif
        if !opts.dornr && opts.donr==-1
            let opts.donr=&number
        endif
        if opts.dornr
            let opts.donr=0
        endif
        let opts.dosomenr=(opts.donr || opts.dornr)
        if opts.dosomenr
            let opts.columns+=1+opts.linenumlen
        endif
    else
        " TODO Add support for formatting line numbers using .line
        let opts.donr     = 0
        let opts.dornr    = 0
        let opts.dosomenr = 0
    endif
    "▶2 fillchars
    let fillchars={}
    if has('windows') && has('folding') && (!ignorefolds || &diff || a:sbsd==1)
        let fcs=split(&fillchars, '\v\,%(%(stl%(nc)?|vert|fold|diff)\:)@=')
        for fc in fcs
            let [o, v]=matchlist(fc, '\v^(\w*)\:(.*)$')[1:2]
            let fillchars[o]=v
        endfor
    endif
    let opts.difffillchar  = a:cf.escape(get(fillchars, 'diff', '-'))
    let opts.foldfillchar  = a:cf.escape(get(fillchars, 'fold', '-'))
    let opts.vertseparator = a:cf.escape(get(fillchars, 'vert', '|'))
    "▶2 Tags
    let opts.ignoretags=2
    if a:cf.has('tagstart') || a:cf.has('tagend')
        if a:options.tags is -1
            let opts.ignoretags=s:_f.getoption('IgnoreTags')
        elseif a:options.tags is# 'all'
            let opts.ignoretags=0
        elseif a:options.tags is# 'local'
            let opts.ignoretags=1
        else
            let opts.ignoretags=(2-a:options.ignoretags)
        endif
    endif
    "▶2 Structures with tags
    if opts.ignoretags!=2
        let starttagreg=s:F.gettagreg(a:options, 'start')
        let endtagreg=s:F.gettagreg(a:options, 'end')
        let [opts.tags, opts.curtags]=
                    \s:F.formattags(opts.ignoretags, starttagreg, endtagreg)
    else
        let opts.tags={}
        let opts.curtags={}
    endif
    "▲2
    lockvar! opts
    return opts
endfunction
"▶1 initspecs
function s:F.initspecs(ff, opts)
    "normalspec  — Default format
    "specialspec — Format for special symbols, including lcs=tab и lcs=trail
    "ntspec      — Format for lcs=eol и lcs=nbsp
    "foldspec    — Folds format
    "fcspec      — Fold column format (+folds)
    "nrspec      — Line number format (&nu||&rnu)
    "fillspec    — Deleted lines format (&diff)
    "clspec      — Cursor line format (&cul)
    "cspec       — Cursor format
    "conspec     — Concealed characters format
    "scspec      — Sign column format
    "▶2 Get highlight
    let highlight={}
    call map(split(&highlight, ','), 'extend(highlight, {v:val[0]: v:val[2:]})')
    for [k, def] in [
                \['8', 'SpecialKey'  ],
                \['@', 'NonText'     ],
                \['d', 'Directory'   ],
                \['e', 'ErrorMsg'    ],
                \['i', 'IncSearch'   ],
                \['l', 'Search'      ],
                \['m', 'MoreMsg'     ],
                \['M', 'ModeMsg'     ],
                \['n', 'LineNr'      ],
                \['N', 'CursorLineNr'],
                \['r', 'Question'    ],
                \['s', 'StatusLine'  ],
                \['S', 'StatusLineNC'],
                \['t', 'Title'       ],
                \['c', 'VertSplit'   ],
                \['v', 'Visual'      ],
                \['V', 'VisualNOS'   ],
                \['w', 'WarningMsg'  ],
                \['W', 'WildMenu'    ],
                \['f', 'Folded'      ],
                \['F', 'FoldColumn'  ],
                \['A', 'DiffAdd'     ],
                \['C', 'DiffChange'  ],
                \['D', 'DiffDelete'  ],
                \['T', 'DiffText'    ],
                \['>', 'SignColumn'  ],
                \['B', 'SpellBad'    ],
                \['P', 'SpellCap'    ],
                \['R', 'SpellRare'   ],
                \['L', 'SpellLocal'  ],
                \['-', 'Conceal'     ],
                \['+', 'Pmenu'       ],
                \['=', 'PmenuSel'    ],
                \['x', 'PmenuSbar'   ],
                \['X', 'PmenuThumb'  ],
                \]
        if has_key(highlight, k)
            let highlight[def]=remove(highlight, k)
        else
            let highlight[def]=def
        endif
    endfor
    "▲2
    call a:ff.letspec('normal',  'Normal')
    call a:ff.letspec('special', highlight.SpecialKey)
    call a:ff.letspec('nt',      highlight.NonText)
    let spspecstr='specialspec'
    let ntspecstr='ntspec'
    if a:opts.formatconcealed==2
        call a:ff.letspec('con', highlight.Conceal)
    endif
    if a:opts.dosigns
        call a:ff.letspec('sc',  highlight.SignColumn)
        let spspecstr='((has_key(opts.placedsigns, clnr) && '.
                    \   'has_key(opts.placedsigns[clnr][1], "linehl"))?'.
                    \       '(s:F.compiledspec(cformat,'.
                    \                  '"'.highlight.SpecialKey.'", '.
                    \                  'opts.placedsigns[clnr][1].linehl)):'.
                    \       '('.spspecstr.'))'
        let ntspecstr='((has_key(opts.placedsigns, clnr) && '.
                    \   'has_key(opts.placedsigns[clnr][1], "linehl"))?'.
                    \       '(s:F.compiledspec(cformat,'.
                    \                  '"'.highlight.NonText.'", '.
                    \                  'opts.placedsigns[clnr][1].linehl)):'.
                    \       '('.ntspecstr.'))'
    endif
    "▶2 Cursor
    if a:opts.docline
        call a:ff.letspec('cl', 'Normal', 'CursorLine')
        call a:ff.letspec('clsp', highlight.SpecialKey, 'CursorLine')
        call a:ff.letspec('clnt', highlight.NonText,    'CursorLine')
        let spspecstr='((iscline)?(clspspec):('.spspecstr.'))'
        let ntspecstr='((iscline)?(clntspec):('.ntspecstr.'))'
    endif
    "▶2 Folds
    if a:opts.foldcolumn
        call a:ff.letspec('fc',   highlight.FoldColumn)
    endif
    if !a:opts.ignorefolds || a:opts.allfolds
        call a:ff.letspec('fold', highlight.Folded)
    endif
    "▲2
    if &diff
        call a:ff.letspec('fill', highlight.DiffDelete)
    endif
    "▶2 Line numbers
    if a:opts.dosomenr
        call a:ff.letspec('nr',   highlight.LineNr)
        if a:opts.docline
            call a:ff.letspec('nrcl', highlight.CursorLineNr)
        endif
    endif
    "▲2
    return [spspecstr, ntspecstr, highlight]
endfunction
"▶1 compilefmtfunc
function s:F.compilefmtfunc(cf)
    let opts=a:cf.opts
    let cformat=a:cf.cformat
    let specfunction=[
\'function s:F.compiledspec(cformat, hlname'.
\                               ((&diff || opts.docline)?(', ...'):('')).')',
    \'let id=hlID(a:hlname)',]
    if &diff || opts.docline
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
    \((opts.docline)?
    \   ('let r=[call(s:F.getspecdict, '.
    \           '[id]+((a:hlname is# "LineNR")?([0]):([])), {}), ""]'):
    \   ('let r=[s:F.getspecdict(id), ""]')),
    \])
    if has_key(cformat, 'style')
        call add(specfunction,
        \'let r[1]=a:cformat.style.f(id, r, "", a:cformat.opts)')
        if (a:cf.has('begin') && a:cf.hasreq('begin', ['a:style'])) ||
                    \(a:cf.has('end') && a:cf.hasreq('end', ['a:style']))
            call add(specfunction, 'let a:cformat.stylestr.=r[1]')
        endif
    endif
    call extend(specfunction, [
    \'let a:cformat.cache[name]=r',
    \'return r',
\'endfunction'])
    execute join(specfunction, "\n")
endfunction
"▶1 Run side-by-side diff
function s:F.sbsdrun(type, slnr, elnr, options, cf, sbsd)
    let opts=a:cf.opts
    let cformat=a:cf.cformat
    "▶2 Используемые буфера
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
    "▶2 Получение реальных номеров линий в текущем буфере
    let clnr=1
    let virtclnr=1
    let maxline=line('$')
    let virtslnr=0
    let virtelnr=0
    while clnr<=maxline
        let virtclnr+=diff_filler(clnr)
        if !virtslnr && clnr==a:slnr
            let virtslnr=clnr
        endif
        if clnr==a:elnr
            let virtelnr=virtclnr
            break
        endif
        let virtclnr+=1
        let clnr+=1
    endwhile
    "▶2
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
    let d={}
    let d.Curcompiledspec=s:F.compiledspec
    for dwinnr in dwinnrs
        "▶2 Получение номеров линий в другом буфере
        execute dwinnr.'wincmd w'
        let clnr=1
        let virtclnr=1
        let maxline=line('$')
        let dslnr=0
        let dstartinfiller=0
        let delnr=0
        while clnr<=maxline+1
            let filler=diff_filler(clnr)
            let virtclnr+=filler
            if !dslnr && virtclnr>=virtslnr
                let dstartinfiller=filler-(virtclnr-virtslnr)
                let dslnr=clnr
            endif
            if virtclnr>virtelnr
                let delnr=((clnr<=maxline)?(clnr):(maxline))
                break
            endif
            let virtclnr+=1
            let clnr+=1
        endwhile
        "▶2 Получение отформатированных текстов
        let a:options.allfolds=0
        let a:options.collapsfiller=0
        let s:F.compiledspec=d.Curcompiledspec
        let normalspec=s:F.compiledspec(cformat, 'Normal')
        unlet s:F.compiledspec
        if !opts.ignorefolds
            normal! zM
        endif
        let r2=s:F.format(a:type, dslnr, delnr, a:options, i)
        "▶2 Добавление sbsdstart или sbsdsep
        let oldcolumns=opts.columns
        unlockvar opts
        let opts.columns=width
        let width+=oldcolumns+1
        let opts.sbsd=a:sbsd
        lockvar! opts
        if empty(r)
            let r=r2
            if a:cf.has('sbsdstart')
                call map(r, 'cformat.sbsdstart.f(normalspec, v:key, "", '.
                            \                   'opts).v:val')
            endif
        else
            let r2=r2[(dstartinfiller):(len(r)-1+dstartinfiller)]
            if a:cf.has('sbsdsep')
                call map(r, 'v:val.'.
                            \'cformat.sbsdsep.f(normalspec, v:key, i-1, '.
                            \                  'v:val, opts).r2[v:key]')
            endif
        endif
        let i+=1
    endfor
    "▶2 Добавление sbsdend
    unlockvar opts
    let opts.columns=width-1
    execute curwin.'wincmd w'
    let opts.sbsd=a:sbsd
    lockvar! opts
    if a:cf.has('sbsdend')
        call map(r, 'v:val.'.
                    \'cformat.sbsdend.f(normalspec, v:key, '.
                    \                   len(dwinnrs).', v:val, opts)')
    endif
    "▶2 Начало и конец представления
    if a:cf.has('begin')
        call insert(r, cformat.begin.f(normalspec, '', opts, cformat.stylestr))
    endif
    if a:cf.has('end')
        call add(r, cformat.end.f(normalspec, a:elnr, '',opts,cformat.stylestr))
    endif
    "▶2 nolf/haslf
    if a:cf.has('nolf') && cformat.nolf
        let r=[join(r, '')]
    endif
    if a:cf.has('haslf') && cformat.haslf
        let oldr=r
        let r=[]
        for item in oldr
            let r+=split(item, "\n")
        endfor
    endif
    "▲2
    return r
endfunction
"▶1 format
let s:progress={}
function s:F.format(type, slnr, elnr, options, ...)
    "▶2 Initialize variables
    let [slnr, elnr]=sort([a:slnr, a:elnr], 's:NRSort')
    let cformat=s:F.getcompfmt(a:type)
    "▶3 Getting sure previous formatting was successful
    "   If not, dropping cache
    let sbsd=((empty(a:000))?(0):(a:000[0]))
    if sbsd<=1 && has_key(cformat, 'frunning')
        unlet cformat.frunning
        call extend(cformat, {'cache': {}, 'stylestr': ''})
        if has_key(s:F, 'compiledspec')
            unlet s:F.compiledspec
        endif
    endif
    let cformat.frunning=1
    "▲3
    let cf=s:cf.new(cformat)
    let opts=s:F.initopts(a:type, slnr, elnr, a:options, cf, sbsd)
    call s:F.compilefmtfunc(cf)
    "▶2 side-by-side diff
    if sbsd==1
        return s:F.sbsdrun(a:type, slnr, elnr, a:options, cf, sbsd)
    endif
    "▲2
    let ff=s:F.newff(cf)
    "▶2 Initialize ff variables
    call ff.let('cformat', s:F.addsubs('s:compiledfmts', a:type))
    call ff.let('opts', s:F.addsubs('s:compiledfmts', a:type, 'opts'))
    call ff.let('r', '[]')    " List with formatted output
    call ff.let('clnr', slnr) " Line being processed
    let [spspecstr, ntspecstr, highlight]=s:F.initspecs(ff, opts)
    "▲2
    let specialcolumns={}
    "▶2 Tag helper variables
    if opts.ignoretags!=2
        if empty(opts.tags)
            let tagregex=''
        else
            let starttagreg=s:F.gettagreg(a:options, 'start')
            let endtagreg=s:F.gettagreg(a:options, 'end')
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
        let tagregex=''
    endif
    "▶2 Precreation of deleted line if possible, here
    if &diff
        let persistentfiller=0
        let collapsafter=((a:options.collapsfiller==-1)?
                    \               (s:_f.getoption('CollapsFiller')):
                    \               (a:options.collapsfiller))
        if !cf.has('difffiller') && cf.has('collapsedfiller')
            let collapsafter=1
        endif
        if collapsafter && cf.has('collapsedfiller')
            let persistentfiller=0
        elseif cf.has('difffiller')
            let collapsafter=0
            let persistentfiller=!cf.hasreq('difffiller',
                        \                   ['a:line', 'a:char', '='])
            if persistentfiller
                let fillspec=s:F.compiledspec(cformat, 'DiffDelete')
                let fillerstr=cformat.difffiller.f(opts.difffillchar,
                            \                            fillspec, 0, 0,
                            \                            '', opts)
            endif
        else
            let persistentfiller=1
            let fillerstr=''
        endif
    endif
    "▶2 Progress bar support: init
    "▶3 Determine whether bar is to be shown
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
    let showprogress=showprogress
    let s:progress.showprogress=showprogress
    "▲3
    if showprogress
        set laststatus=2
        call ff.let('oldprogress',    0                  )
        call ff.let('linesprocessed', 0                  )
        call ff.let('linestoprocess', elnr-slnr+1)
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
            call ff.let('oldcolnum', 0)
            call ff.let('barstart', string('['))
            call ff.let('barlen', barlen)
            call ff.let('barend', string(repeat(" ", barlen).'] '))
        else
            let canresize=1
            let s:progress.oldcolnum=0
            let s:progress.clnr=slnr
            let s:progress.progress=0
            let s:progress.elnr=elnr
            let s:progress.linesprocessed=0
            let s:progress.linestoprocess=(elnr-slnr+1)
        endif
    endif
    "▶2 Precreation of all sign columns if possible, inside function
    if opts.dosigns
        let persistentsc=!cf.hasreq('sign', ['a:line'])
        if persistentsc
            call ff.letcf('nosignsc', 'sign', '"  "', 'scspec', 0, 0)
            call ff.let('scols', '{}')
            call ff.for('[sname, sign]', 'items(opts.signdefinitions)')
            call    ff.if('has_key(sign, "texthl")')
            call        ff.let('spec', 's:F.compiledspec(cformat, sign.texthl)')
            call    ff.else()
            call        ff.let('spec', 'scspec')
            call    ff.endif()
            if s:whatterm is# 'gui'
                call ff.if('has_key(sign, "icon")')
                call    ff.letcf('scols[sname]', 'sign', 'sign.icon', 'spec',
                            \    0, 2)
                call ff.else()
            endif
            call ff.if('has_key(sign, "text")')
            call    ff.letcf('scols[sname]', 'sign','sign.text','spec',0,1)
            call ff.else()
            call    ff.letcf('scols[sname]', 'sign', '"  "', 'scspec', 0,1)
            call ff.endfor()
        endif
    endif
    "▶2 Folds
    if opts.allfolds || opts.foldcolumn
        let persistentfdc=!cf.hasreq('foldcolumn', ['a:line'])
        call ff.let('fclnr', slnr)
        call setwinvar(0, '&foldminlines', 0)
        "▶3 Get folds closed at the moment
        if !opts.ignorefolds
            call ff.let('closedfolds',     '{}')
            call ff.let('closedfoldslist', '[]')
            if !opts.allfolds
                call ff.let('closedfoldsends', '[]')
            endif
            call ff.while('fclnr<='.elnr)
            call    ff.if('foldclosed(fclnr)!=-1')
            call         ff.call('add(closedfoldslist, fclnr)')
            call         ff.letc('closedfolds[fclnr]', 'linestart', 1,
                        \        'foldspec', 'fclnr')
            if !opts.foldcolumn
                if opts.dosigns
                    call ff.appendc('sign', '"  "', 'foldspec', 'fclnr', 0)
                endif
                if opts.dosomenr
                    call ff.appendc('sign', '"  "', 'foldspec', 'fclnr', 0)
                endif
                call     ff.appendc('fold', 'foldtextresult(fclnr)', 'foldspec',
                            \       'fclnr')
                call     ff.appendc('lineend', 1, 'foldspec', 'fclnr', 0)
            endif
            if !opts.allfolds
                call     ff.call('add(closedfoldsends, foldclosedend(fclnr))')
                if showprogress
                    call ff.decrement('linestoprocess',
                                \     'closedfoldsends[-1]-fclnr')
                endif
                call     ff.let('fclnr', 'closedfoldsends[-1]')
            endif
            call    ff.endif()
            call    ff.increment('fclnr')
            call ff.endwhile()
        endif
        "▶3 Process other folds
        "▶4 Initializing fold column-related variables
        if opts.foldcolumn
            call ff.let('foldlevel',   -1)
            call ff.let('fdchange',     0)
            call ff.let('foldlevels',  '{}')
            call ff.let('foldcolumns', '{}')
            if persistentfdc
                call ff.let('foldcolumns[-1]', 'repeat(['.
                            \cf.get('foldcolumn',
                            \       'repeat('.s:F.squote(opts.leadingspace).','.
                            \               opts.foldcolumn.')',
                            \       'fcspec', 0, -1, '""').'], 3)')
            else
                call ff.let('foldcolumnstarts', '{}')
                call ff.let('foldcolumns[-1]',
                            \string(repeat(opts.leadingspace, opts.foldcolumn)))
            endif
        endif
        "▶4 Initializing common variables
        call ff.let('possiblefolds', '{}')
        call ff.let('&foldlevel',     0)
        call ff.let('oldfoldnumber', -1)
        call ff.let('foldnumber',     0)
        "▶4 Main cycle: getting all folds
        call ff.while('oldfoldnumber!=foldnumber')
        call      ff.let('oldfoldnumber', 'foldnumber')
        call      ff.let('fclnr', slnr)
        "▶5 Fold column
        if opts.foldcolumn
            call  ff.if('&foldlevel>='.(opts.foldcolumn-1))
            call     ff.let('rstart', '&foldlevel-'.(opts.foldcolumn-3))
            call     ff.let('rend',   '&foldlevel')
            call     ff.let('fdctext',
                         \'((rstart<=rend)?'.
                         \   '((rend<10)?'.
                         \       '(join(range(rstart, rend), "")):'.
                         \   '((rstart<10)?'.
                         \       '(join(range(rstart, 9), "").'.
                         \        'repeat(">", rend-9))'.
                         \   ':'.
                         \       '(repeat(">", '.(opts.foldcolumn-2).'))))'.
                         \':'.
                         \   '(""))')
            call     ff.let('fdcnexttext', 'fdctext.((&foldlevel>=9)?'.
                         \                            '(">"):'.
                         \                         '((&foldlevel)?'.
                         \                            '(&foldlevel+1):'.
                         \                            '("|")))')
            call     ff.let('fdcclosedtext',
                         \'((&foldlevel>='.opts.foldcolumn.')?'.
                         \   '(((rstart<=10)?'.
                         \       '(rstart-1):'.
                         \       '(">")).fdctext):'.
                         \   '(repeat("|", '.(opts.foldcolumn-1).')))."+"')
            call     ff.let('fdctextend',
                         \  'repeat('.s:F.squote(opts.leadingspace).', '.
                         \          (opts.foldcolumn-1).'-len(fdctext))')
            call  ff.else()
            call     ff.let('fdctext', 'repeat("|", &foldlevel)')
            call     ff.let('fdcnexttext', 'fdctext."|"')
            call     ff.let('fdctextend',
                         \  'repeat('.s:F.squote(opts.leadingspace).', '.
                         \          (opts.foldcolumn-1).'-len(fdctext))')
            call     ff.let('fdcclosedtext', 'fdctext."+".fdctextend')
            call  ff.endif()
            call  ff.append('fdcnexttext', 'fdctextend')
            call  ff.let('fdcopenedtext', 'fdctext."-".fdctextend')
            if persistentfdc
             call ff.let('foldcolumns[&foldlevel]', '['.
                         \   join(map(['fdcclosedtext', 'fdcopenedtext',
                         \             'fdcnexttext'],
                         \            'cf.get("foldcolumn",v:val,"fcspec",0,'.
                         \                   '"&foldlevel",''""'')'), ', ').']')
            else
             call ff.let('foldcolumns[&foldlevel]', 'fdcnexttext')
            endif
        endif
        "▶5 Obtaining folds positions
        call      ff.while('fclnr<='.elnr)
        call         ff.if('foldclosed(fclnr)>-1')
        call              ff.let('foldend', 'foldclosedend(fclnr)')
        if opts.allfolds
            call          ff.let('foldtext', 'foldtextresult(fclnr)')
            if cf.has('foldstart')
                call      ff.if('!has_key(possiblefolds, fclnr)')
                call         ff.let('possiblefolds[fclnr]', '{}')
                call      ff.endif()
                call      ff.if('!has_key(possiblefolds[fclnr], "start")')
                call         ff.let('possiblefolds[fclnr].start', '[]')
                call      ff.endif()
                call           ff.call('add(possiblefolds[fclnr].start, '.
                            \          cf.get('foldstart', 'foldtext',
                            \                 'foldspec', 'fclnr', '&foldlevel',
                            \                 '""').')')
            endif
            if cf.has('foldend')
                call       ff.let('foldinsbefore', 'foldend+1')
                call       ff.if('!has_key(possiblefolds, foldinsbefore)')
                call          ff.let('possiblefolds[foldinsbefore]', '{}')
                call       ff.endif()
                call       ff.if('!has_key(possiblefolds[foldinsbefore],"end")')
                call          ff.let('possiblefolds[foldinsbefore].end', '[]')
                call       ff.endif()
                call       ff.call('add(possiblefolds[foldinsbefore].end, '.
                            \      cf.get('foldend', 'foldtext', 'foldspec',
                            \             'foldend', '&foldlevel', '""').')')
            endif
        endif
        if opts.foldcolumn
            call          ff.let('foldlevels[fclnr]', '&foldlevel')
            call          ff.if('!has_key(foldlevels, foldend+1)')
            call              ff.let('foldlevels[foldend+1]', '&foldlevel-1')
            call          ff.endif()
            let self.__curvar='closedfolds[fclnr]'
            if !persistentfdc
              if !opts.ignorefolds
                call      ff.if('has_key(closedfolds, fclnr)')
                call         ff.appendc('foldcolumn', 'fdcclosedtext', 'fcspec',
                            \           'fclnr', '&foldlevel')
                if opts.dosigns
                    call      ff.appendc('sign', '"  "', 'foldspec', 'fclnr', 0,)
                endif
                if opts.dosomenr
                    call      ff.appendc('linenr',cf.getnrstr('fclnr'),
                                \        'foldspec', 'fclnr')
                endif
                call          ff.appendc('fold', 'foldtextresult(fclnr)',
                            \            'foldspec', 'fclnr')
                call          ff.appendc('lineend', 1, 'foldspec', 'fclnr', 0)
                call      ff.endif()
              endif
              call        ff.letcf('foldcolumnstarts[fclnr]', 'foldcolumn',
                          \        'fdcopenedtext', 'fcspec', 'fclnr',
                          \        '&foldlevel')
            elseif !opts.ignorefolds
              call        ff.if('has_key(closedfolds, fclnr)')
              call            ff.appendc('foldcolumns[&foldlevel][0]')
              if opts.dosigns
                  call        ff.appendc('sign', '"  "', 'foldspec', 'fclnr', 0)
              endif
              if opts.dosomenr
                  call        ff.appendc('linenr', cf.getnrstr('fclnr'),
                              \          'foldspec', 'fclnr')
              endif
              call            ff.appendc('fold', 'foldtextresult(fclnr)',
                          \              'foldspec', 'fclnr')
              call            ff.appendc('lineend', 1, 'foldspec', 'fclnr', 0)
              call        ff.endif()
            endif
        endif
        call              ff.let('fclnr', 'foldend')
        call              ff.increment('foldnumber')
        call         ff.endif()
        call         ff.increment('fclnr')
        call      ff.endwhile()
        call      ff.increment('&foldlevel')
        call ff.endwhile()
    endif
    "▶2 Main cycle: processing lines
    call ff.while('clnr<='.(elnr+((&diff)?(1):(0))))
    call     ff.letc('curstr', '""')
    if opts.docline
        call ff.let('iscline', 'clnr=='.opts.cline)
    endif
    "▶3 Fold column support
    if opts.foldcolumn
      if &diff
        call ff.let('fillfoldlevel', 'foldlevel')
      endif
      call   ff.if('has_key(foldlevels, clnr)')
      call        ff.let('fdchange', 1)
      call        ff.let('foldlevel', 'foldlevels[clnr]')
      call   ff.else()
      call        ff.let('fdchange', 0)
      call   ff.endif()
    endif
    "▶3 Progress bar support
    if showprogress
      if canresize
        call ff.let('barlen', 'winwidth(0)-'.((showprogress==2)?
                \                               (((opts.linenumlen)*2)+10):
                \                               ('8')))
      endif
      call   ff.increment('linesprocessed')
      call   ff.let('progress', '100*linesprocessed/linestoprocess')
      call   ff.let('colnum', ((canresize)?
              \                   ('barlen'):
              \                   (barlen)).
              \               '*linesprocessed/linestoprocess')
      if showprogress!=2
        call ff.if('progress!=oldprogress || '.
                    \'colnum!='.((canresize)?
                    \                 ('s:progress.'):
                    \                 ('')).'oldcolnum')
      endif
      if canresize
        call    ff.let('bar', '"[".repeat("=", colnum).">".'.
                    \         'repeat(" ", barlen-colnum)."] "')
      else
        call    ff.if('colnum!=oldcolnum')
        call       ff.append('barstart', 'repeat("=", colnum-oldcolnum)')
        call       ff.let('barend', 'barend[(colnum-oldcolnum):]')
        call    ff.endif()
        call    ff.let('bar', 'barstart.">".barend')
      endif
      call      ff.append('bar', ((showprogress==2)?
            \                     ('repeat(" ", '.opts.linenumlen.'-len(clnr))'.
            \                      '.clnr."/'.elnr.' ".'):
            \                     ('')).
            \                 'repeat(" ", 3-len(progress)).progress."%%"')
      call      ff.call('setwinvar(0, "&statusline", bar)')
      call      ff.do('redrawstatus')
      if showprogress!=2
        call ff.endif()
      endif
      call   ff.let('oldprogress', 'progress')
      call   ff.let(((canresize)?('s:progress.'):('')).'oldcolnum',
                  \ 'colnum')
      if canresize
       call  ff.let('s:progress.progress', 'progress')
       call  ff.let('s:progress.linesprocessed', 'linesprocessed')
       if showprogress==2
        call ff.let('s:progress.clnr', 'clnr')
       endif
      endif
    endif
    "▶3 Processing deleted lines
    if &diff
      call   ff.let('filler', 'diff_filler(clnr)')
      call   ff.if('filler>0')
      call      ff.letcf('curstrstart', 'linestart', 2.
                  \                     ((collapsafter)?
                  \                       '+(filler>='.collapsafter.')':
                  \                       ''), 'fillspec', 'clnr')
      "▶4 Leading columns (fold, sign, number)
      if opts.foldcolumn
        call    ff.append('curstrstart', ((persistentfdc)?
                    \                      ('foldcolumns[fillfoldlevel][2]'):
                    \                      (cf.get('foldcolumn',
                    \                              'foldcolumns[fillfoldlevel]',
                    \                              'fcspec', 'clnr',
                    \                              'fillfoldlevel',
                    \                              'curstrstart'))))
      endif
      if opts.dosigns
        call    ff.append('curstrstart', ((persistentsc)?
                    \                       ('nosignsc'):
                    \                       (cf.get('sign', '"  "', 'scspec',
                    \                               'clnr', 0, 'curstrstart'))))
      endif
      if opts.dosomenr
        call    ff.appendcf('curstrstart', 'linenr','""', 'nrspec', 'clnr')
      endif
      "▶4 Filler
      if !persistentfiller
        if collapsafter
          call  ff.if('filler<'.collapsafter)
        endif
        call        ff.let('curfil', 'filler')
        call        ff.while('curfil')
        call            ff.let('curstr', 'curstrstart')
        call            ff.appendc('difffiller', s:F.squote(opts.difffillchar),
                    \              'fillspec', 'clnr', 'curfil')
        call            ff.appendc('lineend', 2, 'fillspec', 'clnr',0)
        call            ff.call('add(r, curstr)')
        call            ff.decrement('curfil')
        call        ff.endwhile()
        if collapsafter
          call  ff.else()
          call      ff.let('curstr', 'curstrstart')
          call      ff.appendc('collapsedfiller', 'filler', 'fillspec', 'clnr')
          call      ff.appendc('lineend', 3, 'fillspec', 'clnr', 0)
          call      ff.call('add(r, curstr)')
          call  ff.endif()
        endif
      else
        call    ff.let('curstr', 'curstrstart')
        call    ff.appendc(s:F.squote(fillerstr))
        call    ff.appendc('lineend', 2, 'fillspec', 'clnr', 0)
        call    ff.increment('r', 'repeat([curstr], filler)')
      endif
      "▲4
      call      ff.let('curstr', '""')
      call   ff.endif()
      call   ff.if('clnr>'.elnr)
      call      ff.break()
      call   ff.endif()
    endif
    "▶3 Processing folds
    if !opts.ignorefolds && !opts.allfolds && !opts.foldcolumn "▶4
      call   ff.if('foldclosed(clnr)!=-1')
      call      ff.letcf('curstr', 'linestart', 1, 'foldspec', 'clnr')
      if opts.dosigns
        call    ff.appendc('sign', '"  "', 'foldspec', 'clnr', 0)
      endif
      if opts.dosomenr
        call    ff.appendc('linenr', cf.getnrstr('clnr'), 'foldspec',
                    \                 'clnr')
      endif
      call      ff.appendc('fold', 'foldtextresult(clnr)', 'foldspec', 'clnr')
      call      ff.appendc('lineend', 1, 'foldspec', 'clnr', 0)
      call      ff.call('add(r, curstr)')
      call      ff.let('clnr', 'foldclosedend(clnr)+1')
      call      ff.continue()
      call      ff.else()
    elseif opts.allfolds || opts.foldcolumn "▶4
      if opts.allfolds
        call ff.if('has_key(possiblefolds, clnr)')
        call    ff.let('pf', 'possiblefolds[clnr]')
        if cf.has('foldend')
          call  ff.if('has_key(pf, "end")')
          call      ff.increment('r', 'pf.end')
          call  ff.endif()
        endif
        if cf.has('foldstart')
          call  ff.if('has_key(pf, "start")')
          call      ff.increment('r', 'pf.start')
          call  ff.endif()
        endif
        call ff.endif()
      endif
      if !opts.ignorefolds
        call ff.if('!empty(closedfoldslist) && clnr==closedfoldslist[0]')
        call    ff.call('remove(closedfoldslist, 0)')
        call    ff.call('add(r, closedfolds[clnr])')
        if !opts.allfolds
          call  ff.let('clnr', 'remove(closedfoldsends, 0)+1')
          call  ff.decrement('foldlevel')
          call  ff.continue()
        endif
        call ff.endif()
      endif
    endif
    "▶3 Processing regular lines
    "▶4 Initializing variables
    call        ff.let('linestr',  'getline(clnr)')
    call        ff.let('linelen',  'len(linestr)')
    call        ff.let('curcol',   1)
    " Indicates that this line differs
    call        ff.let('diffattr', ((&diff)?('diff_hlID(clnr, 1)'):(0)))
    let hasspcol=0
    if !empty(tagregex) && cf.has('tagend')
        let hasspcol=1
        " Contains tag ends
        call    ff.let('specialcolumns', string(specialcolumns))
    endif
    if &diff "▶5
        " XXX diffid is taken from beyond the end of line because inside the 
        "     line there may be differences in highlighting: overall line is 
        "     highlighted in one color and parts that differ in the other
        call    ff.if('diffattr')
        call        ff.let('diffid', 'diff_hlID(clnr, linelen+1)')
        call        ff.let('diffhlname', 'synIDattr(synIDtrans(diffid),"name",'.
                    \                              '"'.s:whatterm.'")')
        call        ff.let('dspec', 's:F.compiledspec(cformat,"Normal",'.
                    \                                'diffhlname)')
        call    ff.endif()
    endif
    "▶5 Care about 'lcs' option
    let npregex='\v\t|\p@!.'
    let listchars={}
    if &list && !((a:options.list)?
                \   (s:_f.getoption('IgnoreList')):
                \   (!a:options.list))
        let lcs=split(&listchars,
                    \'\v\,%(%(eol|tab|trail|extends|precedes|nbsp)\:)@=')
        for lc in lcs
            let [o, v]=matchlist(lc, '\v^(\w*)\:(.*)$')[1:2]
            let listchars[o]=v
            if o is# 'nbsp'
                let npregex='\v\t| |\p@!.'
            endif
        endfor
    endif
    let npregex=s:F.squote(npregex)
    "▲5
    if has_key(listchars, 'trail') "▶5
      call      ff.let('trail', 'len(matchstr(linestr, ''\v\s+$''))')
      call      ff.if('trail')
      call          ff.decrement('linelen', 'trail')
      call          ff.let('linestr', 'linestr[:(linelen-1)].'.
                  \                   'substitute(linestr[(linelen):], " ", '.
                  \                        s:F.squote(escape(listchars.trail,
                  \                                          '&~\')).',"g")')
      call      ff.endif()
    endif                          "▲5
    "▶4 Line start
    call        ff.appendc('linestart', 0,
                \          ((&diff)?
                \              ('((diffattr)?(dspec):(normalspec))'):
                \              ('normalspec')), 'clnr')
    if opts.foldcolumn "▶5
      if persistentfdc
        call    ff.appendc('foldcolumns[foldlevel][2-fdchange]')
      else
        call    ff.if('has_key(foldcolumnstarts, clnr)')
        call        ff.appendc('foldcolumnstarts[clnr]')
        call    ff.else()
        call        ff.appendc('foldcolumn', 'foldcolumns[foldlevel]', 'fcspec',
                    \          'clnr', 'foldlevel')
        call    ff.endif()
      endif
    endif
    if opts.dosigns "▶5
      call      ff.if('has_key(opts.placedsigns, clnr)')
      if persistentsc
        call        ff.appendc('scols[opts.placedsigns[clnr][1].id]')
      else
        call        ff.let('sign', 'opts.placedsigns[clnr][1]')
        call        ff.let('sspec', 'has_key(sign, "texthl")?'.
                    \                  's:F.compiledspec(cformat,sign.texthl):'.
                    \                  'scspec')
        if s:whatterm is# 'gui'
          call      ff.addif('has_key(sign, "icon")')
          call          ff.appendc('sign', 'sign.icon', 'sspec', 'clnr', 2)
          call      ff._up()
        endif
        call        ff.addif('has_key(sign, "text")')
        call            ff.appendc('sign', 'sign.text', 'sspec', 'clnr', 1)
        call        ff.else()
        call            ff.appendc('sign','"  "', 'scspec', 'clnr', 1)
        call        ff.endif()
      endif
      call      ff.else()
      if persistentsc
        call        ff.appendc('nosignsc')
      else
        call        ff.appendc('sign', '"  "', 'scspec', 'clnr', 0)
      endif
      call      ff.endif()
    endif
    if opts.docline && cf.has('clstart') "▶5
      call      ff.if('iscline')
      call          ff.appendc('clstart', 'clspec', 'clnr')
      call      ff.endif()
    endif
    if opts.dosomenr "▶5
      call      ff.appendc('linenr', cf.getnrstr('clnr'),
                       \   ((opts.docline)?
                       \      ('((iscline)?'.
                       \          '(nrclspec):'.
                       \          '(nrspec))'):
                       \      ('nrspec')), 'clnr')
    endif
    "▶4 Processing line text
    if !empty(tagregex)
      call      ff.let('ignoretag', 0)
    endif
    call        ff.let('id', 0)
    call        ff.while('curcol<=linelen')
    call            ff.let('startcol', 'curcol')
    if opts.formatconcealed
      call          ff.let('concealed', 0)
    endif
    "▶5 Getting length of zone with same highlighting
    "▶6 Tags
    if empty(tagregex)
      let whcalls=[['increment', ['curcol']]]
    else
      let whcalls= [['if', ['!ignoretag']],
                  \ [   'let', ['tag', 'matchstr(linestr, '.
                  \                               '''\v\k@<!%''.'.
                  \                                 'curcol.''c%('.
                  \                                  s:F.squote(tagregex)[1:-2].
                  \                                 ')\k@!'')']],
                  \ [   'if', ['!empty(tag)']],
                  \ [       'let', ['ignoretag', 1]],
                  \ [       'break', []],
                  \ [   'endif', []],
                  \ ['endif', []],
                  \ ['increment', ['curcol']]]
      call          ff.let('tag', 'ignoretag?'.
                  \                     '"":'.
                  \                     'matchstr(linestr, '.
                  \                               '''\v\k@<!%''.'.
                  \                                 'curcol.''c%('.
                  \                                  s:F.squote(tagregex)[1:-2].
                  \                                 ')\k@!'')')
      call          ff.if('!empty(tag)')
      call              ff.let('ignoretag', 1)
      call          ff.else()
      call              ff.let('ignoretag', '(index(values(specialcolumns), '.
                  \                                       '"tag")!=-1)')
    endif
    "▲6
    call                ff.let('id', 'synID(clnr, curcol, 1)')
    "▶6 Concealed characters
    if opts.formatconcealed
      let nocconceal=(opts.docline && (stridx(&concealcursor, 'n')!=-1))
      if nocconceal
        call            ff.if('if !iscline')
      endif
      call                  ff.let('concealinfo', 'synconcealed(clnr, curcol)')
      call                  ff.let('concealed',   'concealinfo[0]')
      if nocconceal
        call            ff.endif()
      endif
      call              ff.addif('concealed')
      call                  ff.increment('curcol')
      call                  ff.while('concealinfo is#synconcealed(clnr,curcol)')
      call                      map(copy(whcalls),
                  \                 'call(ff[v:val[0]],v:val[1],ff)')
      call                  ff.endwhile()
      if &conceallevel==1
        call                ff.if('empty(concealinfo[1])')
        call                    ff.let('concealinfo[1]',
                    \                  s:F.squote(get(listchars,'conceal',' ')))
        call                ff.endif()
      elseif &conceallevel==3
        call                ff.let('concealinfo[1]', '""')
      endif
      call              ff._up()
    endif
    "▶6 Line with differences
    if &diff
      call              ff.addif('diffattr')
      call                  ff.let('diffid', 'diff_hlID(clnr, curcol)')
      call                  ff.increment('curcol')
      call                  ff.while('id==synID(clnr, curcol, 1) && '.
                  \                  'diffid==diff_hlID(clnr, curcol) && '.
                  \                  ((hasspcol)?
                  \                       ('!has_key(specialcolumns, '.
                  \                                 'curcol) && '):('')).
                  \                  'curcol<=linelen')
      call                      map(copy(whcalls),
                  \                 'call(ff[v:val[0]],v:val[1],ff)')
      call                  ff.endwhile()
      call              ff._up()
    endif
    call                ff.addelse()
    call                    ff.increment('curcol')
    call                    ff.while('id==synID(clnr, curcol, 1) && '.
                \                    ((hasspcol)?
                \                         ('!has_key(specialcolumns, '.
                \                                   'curcol) && '):('')).
                \                    'curcol<=linelen')
    call                        map(copy(whcalls),
                \                   'call(ff[v:val[0]],v:val[1],ff)')
    call                    ff.endwhile()
    "▶6 Close some if’s
    if opts.formatconcealed || &diff
      call              ff.endif()
    endif
    if !empty(tagregex)
      call          ff.endif()
    endif
    "▶5 Formatting line
    "▶6 Getting text to be formatted
    if opts.formatconcealed==1
      call          ff.if('concealed')
      call              ff.let('cstr', 'concealinfo[1]')
      call          ff.else()
    endif
    call                ff.let('cstr', 'strpart(linestr, startcol-1, '.
                \                                       'curcol-startcol)')
    if opts.formatconcealed==1
      call          ff.endif()
    endif
    "▶6 Getting specification according to which text will be formatted
    if opts.formatconcealed
      call          ff.addif('concealed')
      if opts.formatconcealed==2
        call            ff.let('hlname', 'synIDattr(synIDtrans(id), "name", '.
                    \                              '"'.s:whatterm.'")')
      else
        call            ff.let('hlname', string(highlight.Conceal))
      endif
      call          ff._up()
    endif
    if has_key(listchars, 'trail')
      call          ff.addif('trail==-1')
      call              ff.let('hlname', string(highlight.SpecialKey))
      call          ff._up()
    endif
    call            ff.addelse()
    call                ff.let('hlname', 'synIDattr(synIDtrans(id), "name", '.
                \                                   '"'.s:whatterm.'")')
    if has_key(listchars, 'trail') || opts.formatconcealed
      call          ff.endif()
    endif
    if &diff
      call          ff.addif('diffattr')
      call              ff.let('spec', cf.getspecstr('hlname', 'diffhlname'))
      call              ff.let('ddspec', cf.getspecstr('"Normal"','diffhlname'))
      call          ff._up()
    endif
    if opts.dosigns
      call          ff.addif('has_key(opts.placedsigns, clnr) && '.
                  \          'has_key(opts.placedsigns[clnr][1], "linehl")')
      call              ff.let('spec', 's:F.compiledspec(cformat, hlname, '.
                  \                         'opts.placedsigns[clnr][1].linehl)')
      call          ff._up()
    endif
    call            ff.addelse()
    call                ff.let('spec', cf.getspecstr('hlname'))
    if &diff || opts.dosigns
      call          ff.endif()
    endif
    "▶6 Processing tabs and unprintable symbols
    if opts.formatconcealed
      call          ff.if('!concealed')
    endif
    call                ff.let('idx', 'match(cstr, '.npregex.')')
    call                ff.if('idx!=-1')
    call                    ff.let('rstartcol',
                \                  's:F.stuf.strlen(linestr[:(startcol-1)])')
    call                    ff.while('idx!=-1')
    " Part of the current line up to next tabulation
    call                        ff.let('fcstr', '((idx)?(cstr[:(idx-1)]):(""))')
    call                        ff.let('ridx',  's:F.stuf.strlen(fcstr)')
    call                        ff.let('istab', 'cstr[idx] is# "\t"')
    "▶7 Formatting string up to tabulation
    if !has_key(listchars, 'tab')
      call                      ff.if('!istab')
    endif
    call                            ff.if('!empty(fcstr)')
    call                                ff.appendc('line', 'fcstr',
                \                                  ((&diff)?
                \                                      ('(diffattr?(ddspec):'.
                \                                                 '(spec))'):
                \                                      ('spec')), 'clnr', 'idx')
    call                            ff.endif()
    if !has_key(listchars, 'tab')
      call                      ff.endif()
    endif
    "▶7 Formatting tabulation
    let longtab=((&list && has_key(listchars, 'tab')) || !&list)
    if longtab
      call                      ff.if('istab')
      call                          ff.let('i', &tabstop.'-'.
                  \                             '((rstartcol+ridx-1)%'.
                  \                               &tabstop.')')
      if has_key(listchars, 'tab')
        let lcstabfirst=matchstr(listchars.tab, '\v^.')
        let lcstabnext=listchars.tab[len(lcstabfirst):]
        call                        ff.let('tabstr',s:F.squote(lcstabfirst).'.'.
                    \                      'repeat('.s:F.squote(lcstabnext).','.
                    \                              ' i-1)')
        call                        ff.appendc('line', 'tabstr',
                    \                          ((&diff)?
                    \                              ('(diffattr?(ddspec):'.
                    \                                         '('.spspecstr.'))'):
                    \                              (spspecstr)), 'clnr', 'idx')
        call                        ff.let('cstr', 'cstr[(idx+1):]')
      else
        call                        ff.let('tabstr', 'repeat(" ", i)')
        call                        ff.let('cstr','fcstr.tabstr.cstr[(idx+1):]')
      endif
      call                      ff.else()
    endif
    "▲7
    call                            ff.let('cstr', 'cstr[len(fcstr):]')
    call                            ff.let('char', 'matchstr(cstr, "\\v^.")')
    call                            ff.let('cstr', 'cstr[len(char):]')
    "▶7 Formatting non-breaking spaces
    if has_key(listchars, 'nbsp')
      call                          ff.if('char is# " "')
      call                              ff.appendc('line',
                  \                                s:F.squote(listchars.nbsp),
                  \                                    (&diff)?
                  \                                        ('(diffattr?'.
                  \                                          '(ddspec):'.
                  \                                          '('.spspecstr.'))'):
                  \                                        (spspecstr),
                  \                                'clnr', 'idx')
      call                          ff.else()
    endif
    "▲7
    call                                ff.appendc('line', 'strtrans(char)',
                \                                  (&diff)?
                \                                      ('(diffattr?'.
                \                                           '(ddspec):'.
                \                                           '('.ntspecstr.'))'):
                \                                      (ntspecstr),
                \                                  'clnr', 'idx')
    "▶7 Ending some if’s
    if has_key(listchars, 'nbsp')
      call                          ff.endif()
    endif
    if longtab
      call                      ff.endif()
    endif
    "▲7
    call                        ff.let('idx', 'match(cstr, '.npregex.')')
    call                    ff.endwhile()
    call                ff.endif()
    "▶6 Concealed characters
    if opts.formatconcealed
      call          ff.endif()
      if opts.formatconcealed==2
        call        ff.if('concealed')
        call            ff.appendc('cformat.concealed.f(concealinfo[1],'.
                    \                                  'conspec,clnr,curcol,'.
                    \                                  'curstr,opts,cstr,spec)')
        call        ff.else()
      endif
    endif
    "▶6 Reset trail
    if has_key(listchars, 'trail')
      call              ff.if('trail>0 && curcol>linelen')
      call                  ff.increment('linelen', 'trail')
      call                  ff.let('trail', -1)
      call              ff.endif()
    endif
    "▶6 Including formatted part
    call                ff.if('!empty(cstr)')
    call                    ff.appendc('line', 'cstr', 'spec', 'clnr', 'curcol')
    call                ff.endif()
    "▶6 End if
    if opts.formatconcealed==2
      call          ff.endif()
    endif
    "▶5 Tags support
    if hasspcol && cf.has('tagend')
      call          ff.if('get(specialcolumns, curcol) is# "tag"')
      call              ff.appendc('tagend', 'tag', 'spec', 'clnr', 'curcol')
      call              ff.call('remove(specialcolumns, curcol)')
      call              ff.let('tag', '""')
      call              ff.let('ignoretag', 0)
      call          ff.endif()
    endif
    if hasspcol && cf.has('tagstart')
      call          ff.if('!empty(tag)')
      call              ff.appendc('tagstart', 'tag', 'spec', 'clnr', 'curcol')
      if cf.has('tagstart')
        call            ff.let('specialcolumns[curcol+len(tag)]', '"tag"')
      endif
      call          ff.endif()
    endif
    "▲5
    call        ff.endwhile()
    "▶4 Processing EOL
    if has_key(listchars, 'eol') "▶5
      call      ff.appendc('line', s:F.squote(listchars.eol),
            \              (&diff)?
            \                  ('(diffattr?(dspec):('.ntspecstr.'))'):
            \                  (ntspecstr), 'clnr', 'curcol+1')
    endif
    if opts.docline && cf.has('clend') "▶5
      call      ff.if('iscline')
      call          ff.appendc('clend', 'clspec', 'clnr')
      call      ff.endif()
    endif
    if cf.has('lineend') "▶5
      call      ff.appendc('lineend', 0, 'normalspec', 'clnr', 'curcol')
    endif
    "▲3
    if !opts.ignorefolds && !opts.allfolds && !opts.foldcolumn
      call   ff.endif()
    endif
    call     ff.call('add(r, curstr)')
    call     ff.increment('clnr')
    call ff.endwhile()
    "▶2 Beginning and end
    if opts.allfolds
     cal ff.if('has_key(possiblefolds, clnr)')
     call    ff.let('pf', 'possiblefolds[clnr]')
     call    ff.if('has_key(pf, "end")')
     call        ff.increment('r', 'pf.end')
     call    ff.endif()
     cal ff.endif()
    endif
    if !sbsd
     if cf.has('begin')
      cal ff.call('insert(r, cformat.begin.f(normalspec, "", opts, '.
            \                               'cformat.stylestr))')
     endif
     if cf.has('end')
      cal ff.call('add(r, cformat.end.f(normalspec, '.elnr.', "", opts, '.
            \                          'cformat.stylestr))')
     endif
    endif
    call ff.do('return r')
    "▲2
    let f=['function d.compiledformat()']+ff._tolist()+['endfunction']
    let d={}
    " " FIXME Remove debugging line
    " call writefile(f, $HOME.'/tmp/cformat.vim')
    execute join(f, "\n")
    " " FIXME Remove debugging line
    " execute 'breakadd func' 1 string(d.compiledformat)[10:-3]
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
    if cf.has('nolf') && cformat.nolf
        let r=[join(r, '')]
    endif
    "▶2 cformat.haslf
    if cf.has('haslf') && cformat.haslf
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
function s:cmd.function(slnr, elnr, action, ...)
    let action=a:action
    "▶2 Действия
    if action is# 'format' || action is# 'diffformat'
        let result=call(s:F.format, [a:1, a:slnr, a:elnr, a:2,
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
            \                      'nolf  bool '.
            \                   'addopts  dict {/^\w\+$/ _}'.
            \              '})', 'check'],
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

