"▶1 Начало
scriptencoding utf-8
execute frawor#Setup('3.0', {'@/options': '0.0',
            \                     '@/os': '0.0',
            \                    '@/fwc': '0.0',
            \        '@/fwc/constructor': '4.2',
            \              '@/functions': '0.0',
            \                  '@/table': '0.1',
            \   '@/decorators/altervars': '0.0',
            \                 '@/base64': '0.0',})
let s:formats={}
let s:keylist=['begin',
            \   'sbsdstart',
            \    'sbsdsep',
            \    'foldstart',
            \     'linestart',
            \      'foldcolumn', 'sign', 'linenr',
            \      'tagstart',
            \       'concealedstart',
            \        'line',
            \       'concealedend',
            \      'tagend',
            \      'fold', 'difffiller', 'collapsedfiller',
            \     'lineend',
            \    'foldend',
            \   'sbsdend',
            \  'end', 'style']
" Used solely to not let vim delete functions which were profiled
let s:profiled=[]
let s:strdisplaywidthstr=(exists('*strdisplaywidth')?'strdisplaywidth': 's:_r.strdisplaywidth')
"▶1
if !has('syntax')
    call s:_f.warn('synnsup')
endif
"▶1 Options
" Debugging options:
"   Debugging: Disabled by default, enables other Debugging_* options.
"   Debugging_FuncF: If not zero, writes the resulting compiled function to the given file
"   Debugging_MinFu: If true, minimizes compiled function code
"   Debugging_Break: Dictionary mapping function name to a list of breaks. Break is either a regex 
"                    that line must match or a line number. Regex is a subject to %var substitutions 
"                    for compiledformat function.
"   Debugging_SaveO: Save opts.* values in Debugging_FuncF.
let s:_options={
            \   'DefaultFormat': {'default': 'html',
            \                     'checker': 'key formats',},
            \    'IgnoreCursor': {'default':  1,  'filter': 'bool'},
            \     'IgnoreFolds': {'default':  0,  'filter': 'bool'},
            \      'IgnoreList': {'default':  0,  'filter': 'bool'},
            \        'AllFolds': {'default':  0,  'filter': 'bool'},
            \     'IgnoreSigns': {'default':  0,  'filter': 'bool'},
            \      'IgnoreDiff': {'default':  0,  'filter': 'bool'},
            \      'IgnoreTags': {'default':  1, 'checker': 'range  0  2' },
            \    'ShowProgress': {'default':  0, 'checker': 'range  0  2' },
            \   'CollapsFiller': {'default':  0, 'checker': 'range  0 inf'},
            \        'NoLineNR': {'default': -1, 'checker': 'range -1  1' },
            \  'RelativeNumber': {'default': -1, 'checker': 'range -1  1' },
            \      'FoldColumn': {'default': -1, 'checker': 'range -1 inf'},
            \      'MaxDupTags': {'default':  5, 'checker': 'range  0 inf'},
            \ 'FormatConcealed': {'default':  1, 'checker': 'range  0  2' },
            \      'MinColumns': {'default': 40, 'checker': 'range  0 inf'},
            \   'FormatMatches': {'default': -1,
            \                     'checker': 'in [none search matches all]'},
            \     'StartTagReg': {'default':  0, 'checker': 'isreg'},
            \       'EndTagReg': {'default':  0, 'checker': 'isreg'},
            \       'ColorFile': {'default':  0,
            \                      'scopes': 'g',
            \                     'checker': 'either (is=(0) path)'},
            \'AddTagCmdEscapes': {'default': '[]*.~',
            \                     'checker': 'type string'},
            \   'UseStyleNames': {'default': 0, 'filter': 'bool'},
            \
            \       'Debugging': {'default': 0, 'filter': 'bool'},
            \ 'Debugging_FuncF': {'default': 0,
            \                     'checker': 'either (is=(0) path)'},
            \ 'Debugging_MinFu': {'default': 0, 'filter': 'bool'},
            \ 'Debugging_Break': {'default': 0,
            \                     'checker': 'dict {?either ((in keylist)'.
            \                                               '(in [compiledformat '.
            \                                                    'compiledspec '.
            \                                                    'strescape]))'.
            \                                      'list (either ((range 1 inf) '.
            \                                                    '(isreg)))}'},
            \ 'Debugging_SaveO': {'default': 1, 'filter': 'bool'},
            \
            \'HTMLAnchorFileNameExpr': {'default': 'a:tag._tfname.".html"',
            \                           'checker': 'type string'},
            \'HTMLUseTagNameInAnchor': {'default': 0, 'filter': 'bool'},
            \'HTMLAddLinkAtTagLine':   {'default': 1, 'filter': 'bool'},
            \'HTMLTitleExpr':          {'default': 'expand(''%:p:~'')',
            \                           'checker': 'type string',},
            \
            \'VOHelpPrefix':     {'default': 'http://vimpluginloader.sourceforge.net/doc/',
            \                     'checker': 'type string',},
            \'VOHelpSuffix':     {'default': '.html', 'checker': 'type string'},
            \'VOHelpAnchorExpr': {'default': 'tag.__ename=~#'':''?'.
            \                                   '(''line''.tag._linenr.''-0 (''.tag.name.'')''):'.
            \                                   '(tag.__ename)',
            \                     'checker': 'type string',},
        \}
"▶1 Выводимые сообщения
let s:_messages={
            \   'misskey': 'Required key is missing: %s',
            \   'synnsup': 'I wonder, why do you need this plugin: '.
            \              'this vim is compiled without syntax support',
            \   'misscol': 'File with colors list not found, '.
            \              'see :h format-o-ColorFile',
            \    'exists': 'Format already exists',
            \   'upcspec': 'Undefined %%. sequence: %%%s',
            \'nomagicchg': 'Changing magic state is not allowed',
            \   'nofloat': 'You must either use terminal vim or vim compiled '.
            \              'with +float feature',
            \'toolongpat': 'Pattern is too long. This may be caused by '.
            \              'too long StartTagReg or EndTagReg options or by '.
            \              'too long single tag.',
            \    'atnstr': 'The result of evaluating @<@{expr}@>@ is not a string',
            \   'nelines': 'Internal error: formatted buffer does not contain '.
            \              'enough lines. If you can reproduce this error please '.
            \              'post a bug report',
        \}
"▶1 squote
function s:F.squote(str)
    return substitute(substitute(string(a:str), "\n", '''."\\n".''', 'g'),
                \                               '%',  '%%',          'g')
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
    elseif stridx(r, '/')==-1 && stridx(r, s:_r.os.sep)==-1
        let r=s:_r.os.path.join(s:_frawor.runtimepath, 'config', 'formatvim', r.'.yaml')
    else
        return r
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
            \ 'S': '@S@',
            \'.S': '@.S@',
            \ 'N': '@-@',
            \ 'C': '@.@',
            \ ':': '@:@',
            \ '%': "'%'",
            \ '@': "'@'",
            \ '~': '@_difffillchar@',
            \'.~': '@_foldfillchar@',
            \ '-': 'repeat(@_difffillchar@,@_columns@-@=@)',
            \'.-': 'repeat(@_foldfillchar@,@_columns@-@=@)',
            \ '|': '@_vertseparator@',
        \}
"▶2 s:fcompexpressions
let s:spacesexpr="''repeat(''.s:F.squote(@_leadingspace@).'',''.@_linenumlen@.''-len(@@@))''"
let s:fcompexpressions={
            \ '#': "'@<@(@_dosomenr@?".
            \               "((@_donr@ && @_dornr@)?".
            \                   "(''((@-@==''.@_cline@.'')?".
            \                       "(@@@.''.".s:spacesexpr.".''):".
            \                       "(''.".s:spacesexpr.".''.@@@))''):".
            \                   "(".s:spacesexpr.".''.@@@'')):".
            \               "(''\"\"''))@>@'",
            \ '+': "'repeat('.a:opts.qleadingspace.','.a:opts.columns.'-@=@)'",
            \ '_': "'@<@".
            \           "(@_dosomenr@?".
            \               "(''repeat(''.s:F.squote(@_leadingspace@).'',''.@_linenumlen@.'')''):".
            \               "(''\"\"'')".
            \           ")".
            \       "@>@'",
            \ ' ': 'a:opts.qleadingspace',
            \ '^': "'@<@".
            \           "(@_dosomenr@?".
            \               "(s:F.squote(@_leadingspace@)):".
            \               "(''\"\"'')".
            \           ")".
            \       "@>@'",
            \ 's': "get(a:cf.format, 'strescape', '@@@')",
        \}
unlet s:spacesexpr
"▲2
function s:F.getexpr(cf, str, opts)
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
            \      'sbsdend'],
            \'-': ['line', 0, 'begin', 'style'],
            \'.': ['char', 0, 'linestart', 'linenr', 'fold',
            \      'collapsedfiller', 'begin', 'end', 'sbsdstart', 'style'],
        \}
let s:atexpratargs={
            \'opts': 'a:opts',
        \}
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
        if atv is# '<'
            let idx=stridx(str, '@>@')
            if idx!=-1
                let expr=str[2:(idx-1)]
                try
                    let expr=s:F.getats(expr, a:opts, 0, 0, s:atexpratargs)
                    let result=eval(expr)
                endtry
                if type(result)!=type('')
                    call s:_f.throw('atnstr')
                endif
                let arg=''
                let r.=s:F.getats(result, a:opts, a:req, a:key, a:atargs)
                let str=str[(idx+3):]
            endif
        elseif atv is# '_' && str[1] is# '_'
            let arg=matchstr(str, '\v^_\w+\@@=', 1)
            if empty(arg)
                unlet arg
            else
                let str=str[len(arg)+2:]
                if a:req isnot 0
                    call s:F.inqreq(a:req, 'a:opts')
                endif
                let arg=(a:atargs.opts).'.'.arg
            endif
        elseif atv is# '_'
            let arg=matchstr(str, '\v^\l+\@@=', 1)
            if empty(arg)
                unlet arg
            else
                let str=str[len(arg)+2:]
                if type(a:opts[arg])==type('') || type(a:opts[arg])==type(0)
                    let arg=string(a:opts[arg])
                else
                    if a:req isnot 0
                        call s:F.inqreq(a:req, 'a:opts')
                    endif
                    let arg=(a:atargs.opts).'.'.arg
                endif
            endif
        elseif a:key is 0
            " Do nothing
        elseif has_key(s:atargs, atv) && str[1] is# '@'
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
        elseif atv is# '!'
            call s:F.inqreq(a:req, 'a:cf')
            if str[1] is# '!'
                call s:F.inqreq(a:req, 'sbsdstate')
                let arg=matchstr(str, '\v^\l+%(\@)@=', 2)
                let str=str[len(arg)+3:]
                let arg=(a:atargs.cf).'.sbsdstate.'.arg
            else
                call s:F.inqreq(a:req, 'state')
                let arg=matchstr(str, '\v^\l+%(\@)@=', 1)
                let str=str[len(arg)+2:]
                let arg=(a:atargs.cf).'.state.'.arg
            endif
        elseif atv is# 'S' && str[1] is# '@'
            call s:F.inqreq(a:req, 'a:spec')
            let arg=a:atargs.spec.'[0].'.(a:opts.usestylenames?('name'):('styleid'))
            let str=str[2:]
        elseif atv is# '.' && str[1:2] is# 'S@'
            call s:F.inqreq(a:req, 'a:cspec')
            let arg=a:atargs.cspec.'[0].'.(a:opts.usestylenames?('name'):('styleid'))
            let str=str[3:]
        elseif atv is# '=' && str[1] is# '@'
            call s:F.inqreq(a:req, '=')
            call s:F.inqreq(a:req, 'a:cur')
            call s:F.inqreq(a:req, 'a:opts')
            call s:F.inqreq(a:req, 'a:opts.strlen')
            let r=substitute(r, '\v%(^|\''@<=\.)(%(%(\''\.)@!.)*)',
                        \    '\nlet str.=\1'.a:atargs.opts.
                        \                   '.strlen('.a:atargs.cur.'.str)', '')
            let arg=''
            let str=str[2:]
        elseif atv is# '~'
            let arg=a:atargs.spec.'[0]'
            call s:F.inqreq(a:req, 'a:spec')
            let str=str[2:]
        elseif atv is# '^'
            let arg=a:atargs.cspec.'[0]'
            call s:F.inqreq(a:req, 'a:cspec')
            let str=str[2:]
        elseif atv is# ':'
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
function s:F.procpc(cf, str, opts, key, req, atargs, escpc)
    let str=a:str
    "▶2 Process %*
    let chunks=[]
    while !empty(str)
        let pidx=stridx(str, '%')
        if pidx==-1
            call add(chunks, s:F.squote(str))
            break
        elseif pidx!=0
            call add(chunks, s:F.squote(str[:(pidx-1)]))
        endif
        let str=str[(pidx+1):]
        let [shift, chunk]=s:F.getexpr(a:cf, str, a:opts)
        if a:escpc
            let chunk=substitute(chunk, '%', '%%', 'g')
        endif
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
let s:keyargslist=['str', 'spec', 'line', 'char', 'cur', 'opts', 'style', 'cf']
let s:keynoargs={'str': s:atargs['@'][2:],
            \   'line': s:atargs['-'][2:],
            \   'char': s:atargs['.'][2:],
            \  'style': filter(copy(s:keylist), 'v:val isnot# "begin" && '.
            \                                   'v:val isnot# "end"')}
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
let s:keyargs.strescape=['str', 'opts']
let s:defatargs={}
call map(s:keyargslist, 'extend(s:defatargs, {v:val : "a:".v:val})')
unlet s:key s:arg s:keyargslist s:keynoargs
"▲2
function s:F.fmtcompileone(cf, str, opts, key)
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
    let funstr='function r.f('.args.")\n"
    if exists('cmd')
        let funstr.=cmd."\n"
    endif
    let expr=s:F.procpc(a:cf, str, a:opts, a:key, r.req, s:defatargs, 0)."\n"
    let r.isconst=empty(filter(keys(r.req), 'v:val[0:5] isnot# "a:opts"'))
    if has_key(r.req, '=')
        let funstr.='let str='.expr."\nreturn str"
        let r.isexpr=0
    else
        let funstr.='return '.expr
    endif
    let funstr.="\nendfunction"
    execute funstr
    call a:cf.savefunc(a:key, funstr, r.f)
    return r
endfunction
"▶1 fmtprepare
function s:F.fmtprepare(type, options, slnr, elnr, sbsd)
    let format=s:formats[a:type]
    "▶2 s:F.getcolor
    if !has_key(s:F, 'getcolor')
        unlockvar 1 s:F
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
        lockvar s:F
    endif
    "▶2 opts
    let opts={}
    let opts.strlen=get(format, 'strlen', s:_r.strdisplaywidth)
    call map(copy(get(format, 'addopts', {})), 'extend(opts, {"_".v:key : deepcopy(v:val)})')
    let id=hlID('Normal')
    let opts.fgcolor=s:F.getcolor(synIDattr(id, 'fg#', s:whatterm))
    let opts.bgcolor=s:F.getcolor(synIDattr(id, 'bg#', s:whatterm))
    if opts.fgcolor==''
        let opts.fgcolor=((&background is# 'dark')?('#ffffff'):('#000000'))
    endif
    if opts.bgcolor==''
        let opts.bgcolor=((&background is# 'dark')?('#000000'):('#ffffff'))
    endif
    call s:F.initopts(opts, a:options, format, a:sbsd)
    lockvar! opts
    "▲2
    let cf=s:cf.new(format, opts)
    return cf
endfunction
"▶1 s:formats
"▶2 HTML
let s:htmlreplaces={
            \'&': '&amp;',
            \'"': '&#34;',
            \'<': '&lt;',
            \'>': '&gt;',
        \}
let s:escapehtml='substitute(@@@,''['.join(keys(s:htmlreplaces),'').']'','.
            \              '''\=@__replaces@[submatch(0)]'',''g'')'
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
let s:htmlinput='<input class="s%%S %s" type="xxxinvalid" '.
            \          'readonly="readonly" tabindex="-1" '.
            \          'onselect="this.blur(); return false;" '.
            \          'onmousedown="this.blur(); return false;" '.
            \          'onclick="this.blur(); return false;" '.
            \          'size="%s" value="%s" %s/>'
let s:formats.html={
            \'style':        '%>((@S@!=#"")?'.
            \                   '(".s".@S@." {".'.
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
            \                    'text-indent: 0; white-space: pre; } '.
            \                'div { margin: 0; padding: 0; border: 0; '.
            \                      'color: %''@_fgcolor@''%; '.
            \                      'background-color: %''@_bgcolor@''%; '.
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
            \                '.SignImage { background-size: contain; '.
            \                             'background-repeat: no-repeat; '.
            \                             'background-position: center; }'.
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
            \                '.Line:hover .Shown   { display: none; }'.
            \                '.Line:hover .Present { display: inline; }'.
            \                '            .TagLink { margin-left: 1em; }'.
            \                '            .TagLink { display: none; }'.
            \                '.Line:hover .TagLink { display: inline; }'.
            \                '.s%''hlID("Conceal")''% { font-weight: normal; '.
            \                                          'font-style: normal; '.
            \                                          'text-decoration: none;'.
            \                                        '}'.
            \                '%''((@_allfolds@)?'.
            \                    '(".Fold {display:none;}'.
            \                      'a {white-space:pre;'.
            \                         'font-family:inherit;'.
            \                         'color:inherit;}'.
            \                      '.fulltext{white-space:nowrap;}"):'.
            \                    '("")).'.
            \                   '((@_sbsd@)?'.
            \                    '("table, tr, td { margin: 0; '.
            \                                      'padding: 0; '.
            \                                      'border: 0; } "):'.
            \                    '(""))''%'.
            \                '%:</style>'.
            \                '<title>%'''.substitute(s:escapehtml, '\V@@@',
            \                                        'eval(@___titleexpr@)', '').
            \                '''%</title>'.
            \                '%''((@_allfolds@)?('''.
            \                   '<script type="text/javascript">'.
            \                       'function toggleFold(event, objID) {'.
            \                           'var fold;'.
            \                           'fold=document.getElementById(objID);'.
            \                           'if(fold.className=="closed-fold")'.
            \                               '{fold.className="open-fold";'.
            \                                'if (event){event._doNotClose_=true;}}'.
            \                           'else {if (!event._doNotClose_){'.
            \                                   'fold.className="closed-fold";'.
            \                                   'if (event){event.stopPropagation();}}}'.
            \                  '}</script>'''.
            \                '):(""))''%'.
            \                '</head><body class="s%S">'.
            \                '%''((@_sbsd@)?("<table cellpadding=\"0\" '.
            \                       'cellspacing=\"0\">"):(""))''%',
            \'end':          '%''((@_sbsd@)?("</table>"):(""))''%'.
            \                '</body></html>',
            \'linestart':    '<p class="s%S %''@__stylelist@[@@@]''%"'.
            \                  '%''(@@@<=1?'.
            \                       '(" id=\"".'.
            \                        '(@@@==0?'.
            \                            '"line":'.
            \                            '"fold").'.
            \                        '@-@."-".@_sbsd@."\""):'.
            \                       '"")''%>'.
            \                '%''(@@@==0?join(map(copy('.
            \                       'get(@_curtags@,@-@,[])),'.
            \                   '"''<span id=\"''.v:val.__ename.''\">''"),'.
            \                  '""):"")''%',
            \'linenr':       printf(s:htmlinput, 'LineNR',
            \                       '%''(@_linenumlen@+1)''%',
            \                       '%#% ', ''),
            \'line':         '%>empty(@S@)'.
            \                   '?'.s:escapehtml.
            \                   ':''<span class="s''.@S@.''">''.'.
            \                           s:escapehtml.
            \                   '.''</span>''',
            \'concealedstart': '<span class="Concealed">'.
            \                       '<span class="s%S Shown">%s</span>'.
            \                       '<span class="Present">',
            \'concealedend': '</span></span>',
            \'lineend':      '%''repeat("</span>",'.
            \                          'len(get(@_curtags@,@-@,[]))*(@@@==0)).'.
            \                 '('.'@___addlinkattagline@'.
            \                  '&&!empty(get(@_curtags@,@-@))'.
            \                  '&&@@@==0'.
            \                   '?"<span class=\"TagLink\">'.
            \                       '<a href=\"#".@_curtags@[@-@][0].__ename."\">'.
            \                         'LINK'.
            \                       '</a>'.
            \                     '</span>"'.
            \                   ':"")''%</p>',
            \'tagstart':     '%''get(get(@_tags@,@@@,[]),0,'.
            \                            '[{"__anchor":"<a>"}])[-1].__anchor''%',
            \'tagend':       '</a>',
            \'foldcolumn':   printf(s:htmlinput, 'FoldColumn',
            \                       '%''@_foldcolumn@''%',
            \                       '%''substitute(@@@,''\\V>'',''\\&gt;'','.
            \                                     '''g'')''%', ''),
            \'fold':         '<span class="Text">%s</span>'.
            \                '<span class="FoldFiller">% %.-</span>',
            \'difffiller':   '<span class="DiffFiller">%-</span>',
            \'collapsedfiller': '<span class="CollapsedFiller">'.
            \                       '%~ Deleted lines: %s %-'.
            \                   '</span>',
            \'foldstart':    '<div id="fold%N" class="closed-fold" '.
            \                      'onclick="toggleFold(event, ''fold%N'')">'.
            \                   '<div class="toggle-open s%S" id="cf%N">'.
            \                   '<a href="javascript:undefined">%s</a></div>'.
            \                '<div class="fulltext">',
            \'foldend':      '</div></div>',
            \'strescape':    s:escapehtml,
            \'sbsdstart':    '<tr class="SbSDLine" id="sbsd%N">'.
            \                '<td class="SbSD1">',
            \'sbsdsep':      '</td><td class="SbSDSep SbSDSep%C s%S">%|</td>'.
            \                '<td class="SbSD%C">',
            \'sbsdend':      '</td></tr>',
            \'sign':         printf(s:htmlinput, 'Sign', 2, '%s', ''),
            \'addopts': {'stylelist': ['Line', 'Fold', 'DiffFiller',
            \                          'CollapsedFiller', 'TrailLine'],
            \            'replaces': s:htmlreplaces,},
        \}
unlet s:htmlreplaces
"▶3 strlen
function s:formats.html.strlen(str)
    let str=a:str
    let str=substitute(str, '<input .\{-}value="\([^"]*\)".\{-}>', '\1', 'g')
    let str=substitute(str, '\m<.\{-}>', '',  'g')
    let str=substitute(str, '\m&.\{-};', '.', 'g')
    return s:_r.strdisplaywidth(str)
endfunction
"▶3 addopts.anchorescape
" wiki-style .XX escapes
function s:formats.html.addopts.anchorescape(char)
    let nr=char2nr(a:char)
    let nrchar=nr2char(nr)
    let r=''
    while nr
        let r .= printf('.%02x', nr%0x100)
        let nr = nr/0x100
    endwhile
    " Caught character with diacritics
    if nrchar isnot# a:char && len(nrchar)<len(a:char)
        let r.=self._anchorescape(a:char[len(nrchar):])
    endif
    return r
endfunction
"▶3 addopts.addename
function s:formats.html.addopts.addename(opts, tag)
    " http://www.w3.org/TR/html4/types.html#type-name:
    " > ID and NAME tokens must begin with a letter ([A-Za-z]) and may be followed by any number of
    " > letters, digits ([0-9]), hyphens ("-"), underscores ("_"), colons (":"), and periods (".").
    let a:tag.__ename=substitute(a:tag.name, '[^a-zA-Z0-9_\-]',
                \               '\=a:opts._anchorescape(submatch(0))', 'g')
endfunction
"▶3 tagproc
function s:formats.html.tagproc(opts, tag)
    call a:opts._addename(a:opts, a:tag)
    if a:opts.__usetagname
        let a:tag.__href='#'.a:tag.__ename
    else
        let a:tag.__href='#line'.a:tag._linenr.'-0'
    endif
    if !a:tag._incurf
        let fname=a:opts.strescape(eval(a:opts.__anchorfnameexpr))
        let a:tag.__href=fname.a:tag.__href
    endif
    let a:tag.__anchor='<a href="'.a:tag.__href.'">'
    return a:tag
endfunction
"▶3 addoptsfun
function s:formats.html.addoptsfun()
    return {
                \      'usetagname': s:_f.getoption('HTMLUseTagNameInAnchor'),
                \ 'anchorfnameexpr': s:_f.getoption('HTMLAnchorFileNameExpr'),
                \'addlinkattagline': s:_f.getoption('HTMLAddLinkAtTagLine'),
                \       'titleexpr': s:_f.getoption('HTMLTitleExpr')
            \}
endfunction
"▲3
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
    let s:formats.html.addopts.readfile=s:F.readfile
    let s:formats.html.sign="%=((@.@==2)?".
                \"(''=%".printf(s:htmlinput, 'Sign SignImage', 2, '  ',
                \               'style="background-image:url(%'''.
                \                   '@__readfile@(@@@)''%)"')."%=''):".
                \"(''=%".s:formats.html.sign."%=''))=%"
endif
unlet s:htmlinput
let s:styleattr='%''((!empty(@styleid@))?'.
            \            '(" style=\"".'.s:htmlstylestr.'."\""):'.
            \            '(""))''%'
let s:formats['html-vimwiki']={
            \'style':           s:styleattr,
            \'begin':           '<div style="font-family: monospace; %'''.
            \                           s:htmlstylestr.'''%">',
            \'end':             '</div>',
            \'linestart':       '<div%:>',
            \'linenr':          '<span%:>%#% </span>',
            \'foldcolumn':      '<span%:>%s</span>',
            \'lineend':         '</div>',
            \'fold':            '<span%:>%s% %.-</span>',
            \'difffiller':      '<span%:>%-</span>',
            \'collapsedfiller': '<span%:>%~ Deleted lines: %s %-</span>',
            \'strlen':          s:formats.html.strlen,
            \'strescape':       substitute(s:escapehtml, '&', '& ', ''),
            \'line':            '<span%:>%s</span>',
            \'addopts':         {'replaces': extend({' ': '&nbsp;'},
            \                                       s:formats.html.addopts.replaces)},
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
            \'strescape':    s:bbufoescape,
            \'style':        '%>'  .  s:bbufostylestart.
            \                '."%s".'.s:bbufostyleend,
            \'sbsdsep':      '%+%|',
            \'difffiller':   '%-',
        \}
unlet s:bbufostylestart s:bbufostyleend s:bbufoescape
"▶3 stuf.bbstrlen
function s:formats['bbcode-unixforum'].strlen(str)
    let str=a:str
    let str=substitute(str, '\m\[.\{-}\]', '', 'g')
    let str=substitute(str, '\m&[^;]\+;\|.', '.', 'g')
    return len(str)
endfunction
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
    return s:_r.strdisplaywidth(substitute(a:str, "\e\\[[^m]*m", '', 'g'))
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
"▶2 vimorg-tagged
let s:formats['vimorg-tagged']={
            \'line': '%s',
            \'end': '%>@!foundtagsstr@',
            \'tagend': '%>@!recordtag@(@_tags@,@@@)',
            \'state': {},
            \'addopts': {'anchorescape': s:formats.html.addopts.anchorescape},
            \'tagproc': s:formats.html.addopts.addename,
            \'haslf': 1,
        \}
function s:formats['vimorg-tagged'].state.init(opts)
    let self.foundtags={}
    let self.foundtagsstr=''
    let self.lastfound=1
    let self.helpprefix=s:_f.getoption('VOHelpPrefix')
    let self.helpsuffix=s:_f.getoption('VOHelpSuffix')
    let self.anchorexpr=s:_f.getoption('VOHelpAnchorExpr')
endfunction
function s:formats['vimorg-tagged'].state.recordtag(tags, tag)
    if !has_key(a:tags, a:tag) || empty(a:tags[a:tag])
        return ''
    endif
    if has_key(self.foundtags, a:tag)
        return ' ['.self.foundtags[a:tag].']'
    endif
    let tagnr=self.lastfound
    let self.lastfound+=1
    let self.foundtags[a:tag]=tagnr
    let tag=a:tags[a:tag][0][-1]
    let tname=a:tag
    let helplink='['.tagnr.'] '. self.helpprefix . fnamemodify(tag._tfname, ':t') . self.helpsuffix
    let helplink.='#'.eval(self.anchorexpr)
    let self.foundtagsstr.="\n".helplink
    return ' ['.tagnr.']'
endfunction
"▶2 tokens
let s:formats.tokens={
            \'begin':           "%>string(['b', @~@, expand('%'), bufnr('%')])",
            \'sbsdstart':       "['ss', %'string(@_vertseparator@)'%, ",
            \'foldstart':       "['fs', %:, %s, %C]",
            \'foldend':         "['fe', %:, %s, %C]",
            \'linestart':       "['%'@__linetypes@[@@@]'%', %:, ",
            \'foldcolumn':      "['fc', %s, %:], ",
            \'sign':            "['sc', %s, %:, %C], ",
            \'linenr':          "['ln', %s, %:], ",
            \'tagstart':        "['ts', %s    ], ",
            \'line':            "['l' , %s, %:], ",
            \'concealedstart':  "['cs', %s, %:], ",
            \'concealedend':    "['ce', %s, %:], ",
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
function s:F.getspecdict(hlname, ...)
    if type(a:hlname)==type([])
        let r=s:F.getspecdict(a:hlname[0])
        for hlname in a:hlname[1:]
            let r=call(s:F.mergespecdicts,
                        \[r, s:F.getspecdict(hlname)]+a:000, {})
        endfor
        return r
    endif
    let id=synIDtrans(hlID(a:hlname))
    return {
    \            'name':    a:hlname,
    \            'styleid': id,
    \            'fgcolor': s:F.getcolor(
    \                           synIDattr(id, 'fg#', s:whatterm)),
    \            'bgcolor': s:F.getcolor(
    \                           synIDattr(id, 'bg#', s:whatterm)),
    \            'bold':        synIDattr(id, 'bold'),
    \            'italic':      synIDattr(id, 'italic'),
    \            'underline':   synIDattr(id, 'underline'),
    \            'inverse':     synIDattr(id, 'inverse'),
    \}
endfunction
"▶1 mergespecdicts
function s:F.mergespecdicts(oldspecdict, newspecdict, ...)
    return {
                \'name':    a:oldspecdict.name.   '_'.a:newspecdict.name,
                \'styleid': a:oldspecdict.styleid.'_'.a:newspecdict.styleid,
                \'fgcolor': ((empty(a:newspecdict.fgcolor) && !a:0)
                \                 ?(a:oldspecdict.fgcolor)
                \                 :(a:newspecdict.fgcolor)),
                \'bgcolor':   ((empty(a:newspecdict.bgcolor))
                \                 ?(a:oldspecdict.bgcolor)
                \                 :(a:newspecdict.bgcolor)),
                \'bold':      a:oldspecdict.bold      || a:newspecdict.bold,
                \'italic':    a:oldspecdict.italic    || a:newspecdict.italic,
                \'underline': a:oldspecdict.underline || a:newspecdict.underline,
                \'inverse':   a:oldspecdict.inverse   || a:newspecdict.inverse,
            \}
                " \'cleared':   a:newspecdict.styleid == hlID('Normal'),
endfunction
"▶1 redrawprogress
function s:F.redrawprogress()
    if !s:progress.showprogress
        return 0
    endif
    let barlen=((winwidth(0))-
                \((s:progress.showprogress==2)?
                \    (len(s:progress.elnr)*2+10):
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
"▶1 cmppos
function s:F.cmppos(pos1, pos2)
    return ((a:pos1[0]<a:pos2[0])
                \?(-1)
                \:((a:pos1[0]>a:pos2[0])
                \  ?(1)
                \  :((a:pos1[1]<a:pos2[1])
                \    ?(-1)
                \    :((a:pos1[1]>a:pos2[1])
                \      ?(1)
                \      :(0)))))
endfunction
"▶1 matchestoevents
function s:F.matchestoevents(matches)
    let lineevents={}
    for mtch in a:matches
        if mtch.startpos ==# mtch.endpos
            continue
        endif
        let lineevents[mtch.startpos[0]]=
                    \extend(get(lineevents, mtch.startpos[0], {}),
                    \       {
                    \           mtch.startpos[1]:
                    \               add(get(get(lineevents, mtch.startpos[0], {}),
                    \                                       mtch.startpos[1], []),
                    \                   ['push', mtch]),
                    \       })
        let lineevents[mtch.endpos[0]]=
                    \extend(get(lineevents, mtch.endpos[0], {}),
                    \       {
                    \           mtch.endpos[1]:
                    \               add(get(get(lineevents, mtch.endpos[0], {}),
                    \                                       mtch.endpos[1], []),
                    \                   ['pop', mtch]),
                    \       })
    endfor
    return lineevents
endfunction
"▶1 ItemsNrSort
function s:ItemsNrSort(i1, i2)
    return a:i1[0]>a:i2[0]?1:-1
endfunction
let s:_functions+=[function('s:ItemsNrSort')]
"▶1 nritems
function s:F.nritems(dct)
    return map(items(a:dct), '[+v:val[0], v:val[1]]')
endfunction
"▶1 eventstosplcolumns
function s:F.eventstosplcolumns(lineevents)
    let splcolumns={}
    let stack=[]
    let emptymtch={}
    let oldmtch=emptymtch
    for [lnr, columnevents] in sort(s:F.nritems(a:lineevents), function('s:ItemsNrSort'))
        let splcolumns[lnr]={}
        for [col, cevents] in sort(s:F.nritems(columnevents), function('s:ItemsNrSort'))
            for [type, mtch] in cevents
                if type is# 'pop'
                    let i=-1
                    while stack[i] isnot mtch
                        let i-=1
                    endwhile
                    call remove(stack, i)
                elseif type is# 'push'
                    call add(stack, mtch)
                endif
                if empty(stack)
                    let mmtch=emptymtch
                else
                    let mmtch=stack[0]
                    for cmtch in stack[1:]
                        if s:CmpMatches(mmtch, cmtch)==-1
                            let mmtch=cmtch
                        endif
                    endfor
                endif
                if mmtch isnot oldmtch
                    let splcolumns[lnr][col]=[['matchborder', mmtch is emptymtch ? 0 : mmtch.group]]
                    let oldmtch=mmtch
                endif
            endfor
        endfor
    endfor
    call filter(splcolumns, '!empty(v:val)')
    return splcolumns
endfunction
"▶1 CmpMatches
function s:CmpMatches(m1, m2)
    " Note: sorting must be stable
    " Note2: It is impossible for two dictionaries to have equal .num keys. Thus if a:m1.num is not 
    "        greater then a:m2.num then it is definitely lesser.
    return a:m1.priority>a:m2.priority
                \?1
                \:(a:m1.num>a:m2.num
                \   ?1
                \   :-1)
endfunction
let s:_functions+=[function('s:CmpMatches')]
"▶1 formatmatches
function s:F.formatmatches(opts, slnr, elnr)
    let toformat=[]
    if a:opts.formatmatches
        " According to the help &ignorecase option has no effect on matches
        call extend(toformat, map(getmatches(),
                    \'extend(v:val, {"pattern": '.
                    \                'substitute(v:val.pattern,''^\(\\%#=\d\)\?'',''\1\\C'',"")})'))
    endif
    " Search must have the highest .num key because it always wins over other matches with the same 
    " priority. If two non-search matches match at the same position match defined later wins. Match 
    " defined later appears later in the getmatches() output. Thus search must appear the last one 
    " in toformat list.
    if a:opts.formatsearch
        call add(toformat, {'group': 'Search', 'pattern': @/, 'priority': 0})
    endif
    if empty(toformat)
        return {}
    endif
    " Escape unescaped `/'.
    call map(toformat, 'extend(v:val, {"pattern": substitute(v:val.pattern, '.
                \'''\v%(\\@<!%(\\\\)*\\)@<!\/'', ''\\/'', "g"), "num": v:key})')
    call sort(toformat, function('s:CmpMatches'))
    let d={'recordmlmatch': s:F.recordmlmatchmatch, 'matches': [], 'pasteol': {}}
    let [fstmtch; othmtches]=toformat
    " FIXME Will not format match that starts before a:slnr, but ends at or after this line
    let d.priority=fstmtch.priority
    let d.group=fstmtch.group
    let d.num=fstmtch.num
    call s:F.collectmultilinematches(a:slnr, a:elnr, fstmtch.pattern, d)
    for mtch in othmtches
        let d.priority=mtch.priority
        let d.group=mtch.group
        let d.pointer=0
        let d.matcheslen=len(d.matches)
        let d.num=mtch.num
        call s:F.collectmultilinematches(a:slnr, a:elnr, mtch.pattern, d)
    endfor
    let splcolumns=s:F.eventstosplcolumns(s:F.matchestoevents(d.matches))
    return [splcolumns, d.pasteol]
endfunction
"▶1 recordspecialmatch
function s:F.recordspecialmatch(lnr, col, char) dict
    call extend(self.splcolumns,
                \{a:lnr :
                \   extend(get(self.splcolumns, a:lnr, {}),
                \       {a:col             : [['special', a:char]]})})
endfunction
"▶1 formatspecialchars
function s:F.formatspecialchars(opts, slnr, elnr)
    let d={'recordmatch': s:F.recordspecialmatch, 'splcolumns': {}}
    call s:F.collectonelinematches(a:slnr, a:elnr, a:opts.npregex, d)
    return d.splcolumns
endfunction
"▲1
"▶1 recordmlmatchmatch
function s:F.recordmlmatchmatch(slnr, scol, match)
    let matchdct={
                \   'startpos': [a:slnr, a:scol],
                \     'endpos': [a:slnr+len(a:match)-1,
                \                ((len(a:match)==1)
                \                       ?(a:scol+(empty(a:match[0])
                \                           ?len(matchstr(getline('.'),'^.',a:scol-1))
                \                           :len(a:match[0])))
                \                       :(1+len(a:match[-1])))],
                \       'group': self.group,
                \    'priority': self.priority,
                \       'match': a:match,
                \         'num': self.num,
                \}
    call map(a:match[:-1-(len(a:match)>1||(col('$')!=1&&a:scol!=col('$')))],
                \'empty(v:val)'.
                \   '?extend(self.pasteol, {'.
                \       a:slnr.'+v:key : matchdct.group'.
                \    '})'.
                \   ':0')
    if has_key(self, 'pointer')
        while self.pointer<self.matcheslen &&
                    \s:F.cmppos(self.matches[self.pointer].startpos, matchdct.startpos)==-1
            let self.pointer+=1
        endwhile
        call insert(self.matches, matchdct, self.pointer)
        let self.pointer+=1
        let self.matcheslen+=1
    else
        call add(self.matches, matchdct)
    endif
endfunction
"▶1 recordtagmatch
function s:F.recordtagmatch(lnr, col, tname) dict
    call extend(self.splcolumns,
                \{a:lnr :
                \   extend(get(self.splcolumns, a:lnr, {}),
                \       {a:col             : [['tagstart', a:tname]],
                \        a:col+len(a:tname): [['tagend',   a:tname]]})})
    let self.foundtnames[a:tname]=1
endfunction
"▶1 Collect matches
if v:version>703 || (v:version==703 && has('patch627')) "▶2
    function s:F.collectmatches(slnr, elnr, regex, d)
        let save_history=&history
        if save_history
            let &history+=1
            let lasthistitem=histget('/', -1)
        endif
        let save_atslash=@/
        try
            execute 'lockmarks keepmarks keepjumps silent '.a:slnr.','.a:elnr
                        \ 's/'.a:regex.'/\=a:d.recordmatch(line("."), col("."), submatch(0))/gne'
        " Too long pattern error
        catch /\m^Vim(substitute):E339:/
            throw 'TOO LONG REGEX'
        finally
            if save_history
                let &history=save_history
                if histget('/', -1) isnot# lasthistitem
                    call histdel('/', -1)
                endif
            endif
            let @/=save_atslash
        endtry
    endfunction
    let s:F.collectonelinematches=s:F.collectmatches
    function s:F.multilinewrapper(lnr, col, match) dict
        let lines=split(a:match, "\n", 1)
        if len(lines)==1
            return self.recordmlmatch(a:lnr, a:col, lines)
        endif
        let lnr=a:lnr
        let realmatch=[]
        let idx=a:col-1
        while !empty(lines)
            let line=getline(lnr)
            let chunk=remove(lines, 0)
            if empty(lines)
                call add(realmatch, chunk)
                break
            else
                " If we did not hit NUL chunk represents match from starting column (first column in 
                " case of non-starting line) to the end of line.
                if line[(idx):] is# chunk
                    call add(realmatch, chunk)
                else
                    " If we did match was split at NUL (as it is represented as newline). We need to 
                    " determine how many NULs were there. Alternative and, probably, better approach 
                    " would be comparing len(chunk) to len(line)-idx in the same cycle. Note that 
                    " match may be actually one line match, but contain NULs.
                    let chunk.="\n".remove(lines, 0)
                    while line[(idx):] isnot# chunk && !empty(lines)
                        let chunk.="\n".remove(lines, 0)
                    endwhile
                    call add(realmatch, chunk)
                endif
                " In non-starting line match starts in first column
                let idx=0
            endif
            let lnr+=1
        endwhile
        call self.recordmlmatch(a:lnr, a:col, realmatch)
    endfunction
    function s:F.collectmultilinematches(slnr, elnr, regex, d)
        let a:d.recordmatch=s:F.multilinewrapper
        call s:F.collectmatches(a:slnr, a:elnr, a:regex, a:d)
    endfunction
else "▶2
    function s:F.collectonelinematches(slnr, elnr, regex, d)
        let winview=winsaveview()
        try
            let lnr=a:slnr
            while lnr
                call cursor(lnr, 0)
                let lnr=search(a:regex, 'nWc', a:elnr)
                if lnr
                    let line=getline(lnr)
                    let notinlinestr="\n\n"
                    while stridx(line, notinlinestr)!=-1
                        let notinlinestr.="\n"
                    endwhile
                    let matches=[]
                    let chunks=split(substitute(line,
                                \               a:regex,
                                \              '\=[notinlinestr, add(matches, submatch(0))][0]',
                                \              'g'), notinlinestr, 1)
                    let col=1
                    for m in matches
                        let col+=len(remove(chunks, 0))
                        call a:d.recordmatch(lnr, col, m)
                        let col+=len(m)
                    endfor
                    let lnr+=1
                endif
            endwhile
        catch /\m^Vim(let):E339:/
            throw 'TOO LONG REGEX'
        finally
            call winrestview(winview)
        endtry
    endfunction
endif
"▶1 collecttags
function s:F.collecttags(slnr, elnr, tags, tagregexpref, tagregexsuf, d)
    let tagregex=join(map(map(copy(a:tags), 'v:val.name'), 'escape(v:val, "\\")'), '\|')
    let tagregex=escape(a:tagregexpref.tagregex.a:tagregexsuf, '/')
    try
        call s:F.collectonelinematches(a:slnr, a:elnr, tagregex, a:d)
    catch /\m\c^TOO LONG REGEX$/
        let tlen=len(a:tags)
        if tlen==1
            call s:_f.warn('toolongpat')
        else
            call s:F.collecttags(a:slnr, a:elnr, a:tags[:(tlen/2)], a:tagregexpref, a:tagregexsuf,
                        \        a:d)
            call s:F.collecttags(a:slnr, a:elnr, a:tags[(tlen/2+1):], a:tagregexpref, a:tagregexsuf,
                        \        a:d)
        endif
    endtry
endfunction
"▶1 formattags
function s:F.formattags(opts, slnr, elnr, starttagreg, endtagreg)
    "▶2 Объявление переменных
    if a:opts.ignoretags==2
        return []
    endif
    let fname=expand('%:.') " Имя обрабатываемого файла
    let tags=taglist('.')   " Список тёгов
    if empty(tags)
        return [{}, {}, {}, []]
    endif
    let tag2flmap={}        " Словарь: имя тёга — список местонахождений
    let fcontents={}        " Кэш содержимого файлов
    " Список символов, которых надо дополнительно экранировать
    let addescapes=s:_f.getoption('AddTagCmdEscapes')
    let curfl2tagsmap={}    " Словарь: номер линии (в этом файле) — список тёгов
    let filetags={}         " Dictionary mapping file names to list of 
                            " tags contained there and commands to find them
    let splcolumns={}       " Dictionary mapping lines to specialcolumns dictionary that maps 
                            " columns to name of tags that start or stop at given position
    let winview=winsaveview()
    "▶2 Process tags in the current file
    try
        "▶3 Init some tag keys and filter tags
        call map(tags, 'extend(v:val, {"_incurf":('.
                    \       'extend(v:val, {"_tfname": fnamemodify(v:val.filename, ":.")})'.
                    \                 '._tfname is# fname)})')
        if a:opts.ignoretags
            call filter(tags, '!v:val._incurf')
        endif
        "▶3 Generate prefix and suffix of the regular expression
        let tagregexpref='\C\V'
        if !empty(a:starttagreg)
            let tagregexpref.=a:starttagreg.'\zs'
        endif
        let tagregexpref.='\k\@<!'
        if !(empty(a:starttagreg) && empty(a:endtagreg))
            let tagregexpref.='\%('
        endif
        let tagregexsuf=''
        if !(empty(a:starttagreg) && empty(a:endtagreg))
            let tagregexsuf.='\)'
        endif
        let tagregexsuf.='\V\k\@!'
        if !empty(a:endtagreg)
            let tagregexsuf.='\ze'.a:endtagreg
        endif
        "▶3 Collect tags
        let foundtnames={}
        let d={'recordmatch': s:F.recordtagmatch,
                    \'splcolumns': splcolumns, 'foundtnames': foundtnames, 'tags': tags}
        call s:F.collecttags(a:slnr, a:elnr, tags, tagregexpref, tagregexsuf, d)
        call cursor(a:slnr, 0)
        " !empty(extend(, non-empty-dict)) always results in 1
        call filter(tags, 'has_key(foundtnames, v:val.name) '.
                    \       '? !empty(extend(v:val, {"_found": 1}))'.
                    \       ': (v:val._incurf '.
                    \           '? !empty(extend(v:val, {"_found": 0}))'.
                    \           ': 0)')
        let usedtags=copy(tags)
        "▶3 Obtain line numbers for found tags
        " TODO Check whether checking this lazily (when tag is encountered) adds more overhead 
        " compared to current solution.
        for tag in tags
            "▶3 Initialize tag2flmap if needed
            if tag._found
                if !has_key(tag2flmap, tag.name)
                    let tag2flmap[tag.name]=[]
                endif
                call add(tag2flmap[tag.name], [tag])
            endif
            "▶3 Тёг находится в текущем файле
            if tag._incurf
                if tag.cmd[0] is# '/'
                    try
                        " Note: lines that do not fall into the formatted range are ignored
                        let linenr=search(
                                    \escape(
                                    \   substitute(tag.cmd, '\m^/\|/$', '', 'g'),
                                    \   addescapes), 'nwc')
                    catch
                    endtry
                else
                    let linenr=(+matchstr(tag.cmd, '\v^\d+'))
                endif
                if linenr>a:elnr || linenr<a:slnr
                    let tag._incurf=0
                endif
                if linenr
                    let tag._linenr=linenr
                    if tag._found
                        call insert(tag2flmap[tag.name][-1], linenr)
                    endif
                    let curfl2tagsmap[linenr]=get(curfl2tagsmap, linenr, [])+[tag]
                endif
                if tag._found
                    if len(tag2flmap[tag.name][-1])==2
                        if len(tag2flmap[tag.name])>1
                            call insert(tag2flmap[tag.name],
                                        \remove(tag2flmap[tag.name], -1))
                        endif
                    else
                        call remove(tag2flmap[tag.name], -1)
                    endif
                endif
            "▶3 Тёг находится в другом файле
            elseif filereadable(tag._tfname)
                let tfname=tag._tfname
                if tag.cmd[0] is# '/'
                    let filetags[tfname]=add(get(filetags, tfname, []),
                                \            [tag, tag2flmap[tag.name], len(tag2flmap[tag.name])-1,
                                \             tag2flmap[tag.name][-1]])
                else
                    let linenr=(+matchstr(tag.cmd, '\v^\d+'))
                    if linenr
                        call insert(tag2flmap[tag.name][-1], [tfname, linenr])
                        let tag._linenr=linenr
                    else
                        call remove(tag2flmap[tag.name], -1)
                    endif
                endif
            "▶3 Файл, в котором должен находится тёг, не существует
            else
                call remove(tag2flmap[tag.name], -1)
            endif
        endfor
    finally
        call winrestview(winview)
    endtry
    "▶2 Tags in the files that should be searched for
    " WARNING: tags list below is modified
    for [tfname, tags] in items(filetags)
        let fc=readfile(tfname, 'b')
        call map(tags, 'add(v:val, '.
                    \'"\\m".escape(substitute(v:val[0].cmd, ''\m^/\|/$'', "", "g"), addescapes))')
        let linenr=1
        for line in fc
            try
                if empty(filter(tags,
                            \'line=~#v:val[-1]'
                            \   .'? empty(insert(v:val[-2], [tfname, linenr]))'
                            \   .': !empty(extend(v:val[0], {"_linenr": linenr}))'))
                    break
                endif
            catch
            endtry
            let linenr+=1
        endfor
        call map(reverse(tags), 'remove(v:val[1], v:val[2])')
    endfor
    unlet filetags tags
    "▶2 Удаление лишних записей
    call filter(usedtags, 'has_key(v:val, "_linenr")')
    call map(tag2flmap, 'filter(v:val, "has_key(v:val[-1], \"_linenr\")")')
    call filter(tag2flmap, '!empty(v:val)')
    let maxduptags=s:_f.getoption('MaxDupTags')
    if maxduptags
        call filter(tag2flmap, 'type(get(v:val, '.maxduptags.', 0))=='.type(0))
    endif
    return [tag2flmap, curfl2tagsmap, splcolumns, usedtags]
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
"▶1 cf
let s:cf={}
"▶2 cf.new
function s:cf.new(format, opts)
    let cf=extend(copy(self), {'format':   a:format,
                \              'opts':     a:opts,
                \              'vars':     {},
                \              'nextvar':  'a',
                \              'cache':    {},
                \              'stylestr': ''})
    if !a:opts.minimizefunc
        call map(copy(s:cf), 'v:key[-6:] is# "_nomin" && empty(extend(cf, {v:key[:-7]: v:val}))')
    endif
    if has_key(a:format, 'sbsdstate')
        let cf.sbsdstate=deepcopy(a:format.sbsdstate)
        if exists('*cf.sbsdstate.init')
            call cf.sbsdstate.init(cf.opts)
        endif
    endif
    if cf.opts.funcfile isnot 0 && filereadable(cf.opts.funcfile)
        call writefile([], cf.opts.funcfile)
    endif
    return cf
endfunction
"▶2 cf.savefunc
function s:cf.savefunc(fname, ftext, Func)
    if !self.opts.debugging
        return
    endif
    let ftext=(type(a:ftext)==type([]) ? a:ftext : split(a:ftext, "\n"))
    if self.opts.breaks isnot 0
        if has_key(self.opts.breaks, a:fname)
            let breakarg=matchstr(string(a:Func), '''\@<=.*''\@=')
            for v in self.opts.breaks[a:fname]
                if type(v)==type(0)
                    execute 'breakadd func' v breakarg
                else
                    if a:fname is# 'compiledformat'
                        let v=self.expr(v)
                    endif
                    let lnr=1
                    for line in ftext[1:]
                        if line=~#v
                            execute 'breakadd func' lnr breakarg
                        endif
                        let lnr+=1
                    endfor
                endif
            endfor
        endif
    endif
    if self.opts.funcfile isnot 0
        let firstline=substitute(ftext[0], '\v(^function\ )@<=([^(]+)', 'Compiled:'.a:fname, 'g')
        let lastline=ftext[-1]
        let ftext=add(insert(map(ftext[1:-2],'repeat(" ",shiftwidth()).v:val'),firstline),lastline)
        let self.fcontents=extend(get(self, 'fcontents', []), ftext)
    endif
endfunction
"▶2 cf.writefunc
function s:cf.writefunc()
    if self.opts.funcfile is 0
        return
    endif
    if self.opts.saveopts
        let optslst=['let opts={}']
        let keys=sort(keys(self.opts))
        let maxklen=max(map(copy(keys), 'len(v:val)'))
        for k in keys
            call add(optslst, printf('let opts.%-*s = %s', maxklen, k, string(self.opts[k])))
        endfor
    else
        let optslst=[]
    endif
    call writefile(optslst+get(self, 'fcontents', []), self.opts.funcfile)
endfunction
"▶2 cf.compile
function s:cf.compile(slnr, elnr, options, sbsd)
    let cformat={}
    let self.cformat=cformat
    let cformat.strescape=s:F.fmtcompileone(self, '%>'.get(self.format, 'strescape', '@@@'),
                \                           self.opts, 'strescape')
    unlockvar self.opts
    call s:F.initstrescapeopts(self.opts, self)
    call s:F.initfileopts(self.opts, a:slnr, a:elnr, a:options, self.format, a:sbsd)
    lockvar! self.opts
    for key in s:keylist
        if has_key(self.format, key)
            let cformat[key]=s:F.fmtcompileone(self, self.format[key], self.opts, key)
            lockvar! cformat[key]
            if self.opts.profiling || self.opts.debugging
                call add(s:profiled, cformat[key].f)
            endif
        endif
    endfor
    for key in ['haslf', 'nolf']
        let cformat[key]=get(self.format, key, 0)
        lockvar cformat[key]
    endfor
    let cformat.compiledspec=s:F.compilespecfunc(self)
    lockvar! cformat
    if self.opts.profiling || self.opts.debugging
        call add(s:profiled, cformat.compiledspec)
    endif
    unlockvar self.opts
    call s:F.initcfopts(self.opts, self)
    lockvar! self.opts
    if has_key(self.format, 'state')
        let self.state=deepcopy(self.format.state)
        if exists('*self.state.init')
            call self.state.init(self.opts)
        endif
    endif
endfunction
"▶2 cf.has
function s:cf.has(key)
    return has_key(self.cformat, a:key)
endfunction
"▶2 cf.newvar
function s:F.inc(next)
    if empty(a:next)
        return add(a:next, 'a')
    endif
    let c=a:next[-1]
    if c is# '9'
        call remove(a:next, -1)
        return add(s:F.inc(a:next), 'a')
    elseif c is# 'Z'
        if len(a:next)>1
            let a:next[-1]='0'
        else
            call remove(a:next, -1)
            return add(s:F.inc(a:next), 'a')
        endif
    elseif c is# 'z'
        let a:next[-1]='A'
    else
        let a:next[-1]=nr2char(char2nr(c)+1)
    endif
    return a:next
endfunction
function s:cf.newvar(var)
    if a:var !~# '\v^(\a\:)@!\a\w*$'
        throw 'Invalid variable name: '.a:var
    endif
    if !has_key(self.vars, a:var)
        let self.vars[a:var]=self.nextvar
        let i=len(self.nextvar)-1
        let self.nextvar=join(s:F.inc(split(self.nextvar, '\v.@=')), '')
    endif
    return self.vars[a:var]
endfunction
function s:cf.newvar_nomin(var)
    return a:var
endfunction
"▶2 cf.getvar
function s:cf.getvar(var)
    let v=matchstr(a:var, '\v^(\a\:)@!\w+')
    if empty(v)
        return a:var
    elseif !has_key(self.vars, v)
        throw 'No variable: '.v
    endif
    return self.vars[v]
endfunction
"▶2 cf.getvar_nomin
function s:cf.getvar_nomin(var)
    return a:var
endfunction
"▶2 cf.expr
function s:cf.expr(expr, ...)
    return substitute(a:expr, '\v\%(\%|\-?\d+|\a\w*)',
                \     '\=submatch(1) is# "%"   ? '.
                \           '"%" : '.
                \           (a:0&&a:1
                \               ? 'self.newvar(submatch(1))'
                \               : 'self.getvar(submatch(1))'),
                \     'g')
endfunction
"▶2 cf.specstr
function s:cf.specstr(list)
    if type(a:list)==type('')
        return 'call(%cformat.compiledspec,[%cf]+'.a:list.',{})'
    else
        return '%cformat.compiledspec(%cf,'.join(a:list,',').')'
    endif
endfunction
"▶2 cf.get
function s:cf.get(key, ...)
    if self.cformat[a:key].isconst
        return s:F.squote(call(self.cformat[a:key].f, a:000+[self.opts, self], {}))
    elseif self.cformat[a:key].isexpr
        let atargs=copy(s:defatargs)
        call map(s:keyargs[a:key][:-3], 'extend(atargs,{v:val : a:000[v:key]})')
        let atargs.opts='%opts'
        let atargs.cf='%cf'
        return s:F.procpc(self, self.cformat[a:key].str, self.opts, a:key, 0, atargs, 1)
    endif
    return '%cformat.'.a:key.'.f('.join(a:000, ',').',%opts,%cf)'
endfunction
"▶2 cf.getnrstr
function s:cf.getnrstr(nrvarstr)
    return ((self.opts.dornr)?
                \   ((self.opts.donr)?
                \       ('(('.a:nrvarstr.'=='.self.opts.cline.')?'.
                \           self.opts.cline.' : '.
                \           ('abs('.a:nrvarstr.'-'.self.opts.cline.')').')'):
                \       ('abs('.a:nrvarstr.'-'.self.opts.cline.')')):
                \   (a:nrvarstr))
endfunction
"▶2 cf.hasreq
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
        let tagreg='\m\%('.tagreg.'\)\V'
    endif
    return tagreg
endfunction
"▶1 ff
let s:ff={}
let s:ffcomp={}
"▶2 ffcomp.c
function s:ffcomp.c(cmd, arg)
    return get(self._cmds, a:cmd, a:cmd).
                \((a:arg =~# '\v^[a-zA-Z0-9_@!]')?(' '):('')).a:arg
endfunction
"▶2 ff.expr
function s:ff.expr(...)
    return call(self.__cf.expr, a:000, self.__cf)
endfunction
"▶2 ff.__let
function s:ff.__let(var, type, expr)
    return self._out()._deeper('let',self.expr(a:var, 1),a:type,self.expr(a:expr))
                \._out()
endfunction
"▶2 ff.let
function s:ff.let(var, expr)
    return self.__let(a:var, '', a:expr)
endfunction
"▶2 ff.__leta
function s:ff.__leta(var, type, expr)
    if !empty(self._l) && self._l[-1][0] is# 'let' && self._l[-1][2] is# a:type
        let var=self.expr(a:var, 1)
        let expr=self.expr(a:expr)
        let lblock=self._l[-1]
        if lblock[1][0] is# '['
            let lblock[1]=lblock[1][:-2].','.var.']'
            let lblock[3]=lblock[3][:-2].','.expr.']'
        else
            let lblock[1]='['.lblock[1].','.var.']'
            let lblock[3]='['.lblock[3].','.expr.']'
        endif
        return self
    else
        return call(self.__let, [a:var, a:type, a:expr], self)
    endif
endfunction
"▶2 ff.leta
" TODO: Automatically determine validity of concatenating lets by recording variables used by right 
" expression
function s:ff.leta(var, expr)
    return self.__leta(a:var, '', a:expr)
endfunction
"▶2 ff.letabreak
function s:ffcomp.letabreak(...)
    " Do nothing
endfunction
function s:ff.letabreak()
    return self._out()._deeper('letabreak')._out()
endfunction
"▶2 ff.letspec
function s:ff.letspec(spname, ...)
    return self.leta('%'.a:spname.'spec', self.__cf.specstr(map(copy(a:000),'"''".v:val."''"')))
endfunction
"▶2 ff.letcf
function s:ff.letcf(var, ...)
    if self.__cf.has(a:1)
        return self.leta(a:var, call(self.__cf.get, a:000+["''"], self.__cf))
    else
        return self.leta(a:var, "''")
    endif
endfunction
"▶2 ff.appendcf
function s:ff.appendcf(var, ...)
    if self.__cf.has(a:1)
        return self.append(a:var, call(self.__cf.get, a:000+[a:var], self.__cf))
    else
        return self
    endif
endfunction
"▶2 ff.letc
function s:ff.letc(var, ...)
    let self.__curvar=a:var
    if a:0>1
        return call(self.letcf, [self.__curvar]+a:000, self)
    else
        return call(self.let,   [self.__curvar, a:1],  self)
    endif
endfunction
"▶2 ff.appendc
function s:ff.appendc(...)
    if a:0>1
        return call(self.appendcf, [self.__curvar]+a:000, self)
    else
        return call(self.append,   [self.__curvar, a:1],  self)
    endif
endfunction
"▶2 ff.for
function s:ff.for(var, expr)
    return call(self.__orig.for, [self.expr(a:var, 1), self.expr(a:expr)], self)
endfunction
"▶2 ff.call, .while, .if, .elseif, .addif, .strappend, .echo, .echomsg, .echon, .unlet
for s:f in ['call', 'while', 'if', 'elseif', 'addif', 'strappend', 'echo', 'echomsg', 'echon',
            \'unlet']
    execute      'function s:ff.'.s:f."(...)\n".
                \'    return call(self.__orig.'.s:f.', '.
                \                'map(copy(a:000), "self.expr(v:val)"), '.
                \                "self)\n".
                \'endfunction'
endfor
unlet s:f
"▶2 ff.increment
function s:ff.increment(var, ...)
    return self.__let(a:var, '+', get(a:000, 0, 1))
endfunction
"▶2 ff.decrement
function s:ff.decrement(var, ...)
    return self.__let(a:var, '-', get(a:000, 0, 1))
endfunction
"▶2 newff
function s:F.newff(cf)
    let r=s:_r.new_constructor()
    let r.__orig=filter(copy(r), 'type(v:val)==2')
    call extend(r, s:ff)
    call extend(r._comp, s:ffcomp)
    let r.append=r.strappend
    let r.__cf=a:cf
    if !a:cf.opts.minimizefunc
        let r.__leta=r.__let
    endif
    return r
endfunction
"▶1 s:NRSort :: Integer, Integer → -1|1
" We really don’t care about the order of equal integers
function s:NRSort(a, b)
    return a:a>a:b ? 1 : -1
endfunction
let s:_functions+=['s:NRSort']
"▶1 mergesplcolumns
function s:F.mergesplcolumns(splcolumns1, splcolumns2)
    let splcolumns=deepcopy(a:splcolumns1)
    call map(copy(a:splcolumns2),
                \'has_key(splcolumns, v:key)'.
                \   '?map(copy(v:val), '.
                \       '"has_key(splcolumns[".v:key."], v:key)'.
                \           '?extend(splcolumns[".v:key."][v:key], v:val)'.
                \           ':extend(splcolumns[".v:key."], {v:key : v:val})")'.
                \   ':extend(splcolumns, {v:key : v:val})')
    return splcolumns
endfunction
"▶1 initfileopts
function s:F.initfileopts(opts, slnr, elnr, options, format, sbsd)
    let opts=a:opts
    " TODO Control it with a:options?
    let opts.sbsd=a:sbsd
    "▶2 Intended display width
    let columns=0+(((a:options.columns)+0)?
                \       (a:options.columns):
                \       (-1))
    if columns==-1
        let columns=max(map(range(1, line('$')), 'virtcol([v:val,''$''])-1')
                    \   +[s:_f.getoption('MinColumns')])
    endif
    let opts.columns=columns
    "▶2 Folds
    let foldcolumn=0
    if !opts.ignorefolds && has_key(a:format, 'foldcolumn')
        " TODO Support for formatting foldcolumn using .line
        let foldcolumn=((a:options.foldcolumn==-2)?
                \           (s:_f.getoption('FoldColumn')):
                \           (a:options.foldcolumn))
        if foldcolumn==-1
            let foldcolumn=&foldcolumn
        endif
    endif
    let opts.foldminlines=&foldminlines
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
    if formatconcealed==2
                \&& !(has_key(a:format, 'concealedstart') || has_key(a:format, 'concealedend'))
        let formatconcealed=1
    endif
    let opts.formatconcealed=formatconcealed
    let opts.conceallevel=&conceallevel
    "▶2 Cursor
    let opts.ignorecursor=(a:options.cursor==-1?
                \               s:_f.getoption('IgnoreCursor'):
                \               !a:options.cursor)
    let opts.cline=line('.')
    let hascline=(a:slnr<=opts.cline && opts.cline<=a:elnr)
    let opts.docline=(!opts.ignorecursor && &cursorline && hascline)
    let opts.hascline=(!opts.ignorecursor && hascline)
    if formatconcealed && !opts.ignorecursor
        let opts.formatconcealedcursor=stridx(&concealcursor, 'n')==-1
    else
        let opts.formatconcealedcursor=0
    endif
    let opts.checkcline=opts.docline || opts.formatconcealedcursor
    "▶2 Line numbers
    if has_key(a:format, 'linenr')
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
        if opts.donr==-1
            let opts.donr=&number
        endif
        let opts.dosomenr=(opts.donr || opts.dornr)
        if opts.dosomenr
            if opts.donr
                let opts.linenumlen=max([len(a:elnr), &numberwidth-1])
            elseif opts.dornr
                let opts.linenumlen=max([len(a:elnr-a:slnr), &numberwidth-1])
            endif
            let opts.columns+=1+opts.linenumlen
        else
            let opts.linenumlen = 0
        endif
    else
        " TODO Add support for formatting line numbers using .line
        let opts.donr       = 0
        let opts.dornr      = 0
        let opts.dosomenr   = 0
        let opts.linenumlen = 0
    endif
    "▶2 Structures with tags
    if opts.ignoretags!=2
        let starttagreg=s:F.gettagreg(a:options, 'start')
        let endtagreg=s:F.gettagreg(a:options, 'end')
        let [opts.tags, opts.curtags, opts.tagssplcolumns, usedtags]=
                    \s:F.formattags(opts, a:slnr, a:elnr, starttagreg, endtagreg)
        if has_key(a:format, 'tagproc')
            call map(usedtags, 'a:format.tagproc(opts, v:val)')
        endif
        let opts.dotags=(opts.ignoretags!=2 && !empty(opts.tagssplcolumns))
    else
        let opts.tags={}
        let opts.curtags={}
        let usedtags=0
        let opts.dotags=0
    endif
    "▶2 Structures with matches
    if opts.formatsomematch
        let [opts.matchessplcolumns, opts.matchespasteol]=s:F.formatmatches(opts, a:slnr, a:elnr)
        let opts.domatches=!empty(opts.matchessplcolumns)
    else
        let opts.domatches=0
        let opts.matchespasteol=0
    endif
    "▶2 'listchars'
    let listchars={}
    let npregex='\v\t|\p@!.'
    if &list && !((a:options.list)?
                \   (s:_f.getoption('IgnoreList')):
                \   (!a:options.list))
        let opts.list=1
        call map(map(split(&listchars,
                    \'\v\,%(%(eol|tab|trail|extends|precedes|nbsp|conceal)\:)@='),
                    \'matchlist(v:val,''\v^(\w+)\:(.*)$'')[1:2]'),
                    \'extend(listchars, {v:val[0]: substitute(v:val[-1],''\\\(.\)'',''\1'',"g")})')
        if has_key(listchars, 'nbsp')
            let npregex='\v\t| |\p@!.'
        endif
    else
        let opts.list=0
        let listchars.tab='  '
    endif
    let opts.npregex=npregex
    let opts.listchars=listchars
    let opts.spsplcolumns=s:F.formatspecialchars(a:opts, a:slnr, a:elnr)
    "▶2 special columns
    if !empty(get(opts, 'matchessplcolumns')) && empty(get(opts, 'tagssplcolumns'))
        let opts.splcolumns=s:F.mergesplcolumns(opts.matchessplcolumns, opts.spsplcolumns)
    elseif !empty(get(opts, 'tagssplcolumns')) && empty(get(opts, 'matchessplcolumns'))
        let opts.splcolumns=s:F.mergesplcolumns(opts.tagssplcolumns, opts.spsplcolumns)
    elseif !empty(get(opts, 'tagssplcolumns')) && !empty(get(opts, 'matchessplcolumns'))
        let opts.splcolumns=s:F.mergesplcolumns(
                    \s:F.mergesplcolumns(opts.tagssplcolumns, opts.matchessplcolumns),
                    \opts.spsplcolumns)
    else
        let opts.splcolumns=opts.spsplcolumns
    endif
    "▶2 Signs
    let dosigns=0
    if has_key(a:format, 'sign')
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
    "▲2
    "▶2 Progress bar: bar length
    let opts.barlen=((winwidth(0))-
                \((opts.showprogress==2)?
                \    (len(a:elnr)*2+10):
                \    (8)))
    if opts.barlen<0
        let opts.showprogress=0
    endif
    "▲2
    let opts.dolinemergehl=(opts.dodiff || opts.docline || opts.dosigns)
    let opts.domergehl=(opts.dolinemergehl || opts.domatches)
    return opts
endfunction
"▶1 initstrescapeopts
function s:F.initstrescapeopts(opts, cf)
    let opts=a:opts
    let opts.strescape_=a:cf.cformat.strescape.f
    function! opts.strescape(s) dict
        return self.strescape_(a:s, self)
    endfunction
    let opts.leadingspace  = opts.strescape(' ')
    let opts.difffillchar  = opts.strescape(opts.fillchars.diff)
    let opts.foldfillchar  = opts.strescape(opts.fillchars.fold)
    let opts.vertseparator = opts.strescape(opts.fillchars.vert)
    let opts.qleadingspace = s:F.squote(opts.leadingspace)
    return opts
endfunction
"▶1 initcfopts
function s:F.initcfopts(opts, cf)
    let opts=a:opts
    "▶2 persistentfiller
    let opts.persistentfiller=0
    if opts.dodiff
        if opts.collapsafter
            let opts.persistentfiller=0
        elseif a:cf.has('difffiller')
            let opts.persistentfiller=!a:cf.hasreq('difffiller', ['a:line', 'a:char', '=', 'a:cf'])
        else
            let opts.persistentfiller=1
        endif
    endif
    "▶2 persistent fold column
    if a:cf.has('foldcolumn')
        let opts.persistentfdc=!a:cf.hasreq('foldcolumn', ['a:line', 'a:cf'])
    else
        let opts.persistentfdc=1
    endif
    "▶2 persistent sign column
    if a:cf.has('sign')
        let opts.persistentsc=!a:cf.hasreq('sign', ['a:line', 'a:cf'])
    else
        let opts.persistentsc=1
    endif
    "▲2
    return opts
endfunction
"▶1 initopts
function s:F.initopts(opts, options, format, sbsd)
    let opts=a:opts
    call filter(opts, 'v:key[:1] isnot# "__"')
    let opts.highlight=s:F.gethighlight()
    let opts.dodiff=(s:_f.getoption('IgnoreDiff') || !get(a:options, 'diff', 1))
                \       ?0
                \       :&diff
    let opts.usestylenames=s:_f.getoption('UseStyleNames')
    "▶2 Debugging/profiling
    let opts.profiling=v:profiling
    let opts.debugging=s:_f.getoption('Debugging')
    if opts.debugging
        let opts.funcfile     = s:_f.getoption('Debugging_FuncF')
        let opts.minimizefunc = s:_f.getoption('Debugging_MinFu')
        let opts.breaks       = s:_f.getoption('Debugging_Break')
        let opts.saveopts     = s:_f.getoption('Debugging_SaveO')
    else
        let opts.funcfile     = 0
        let opts.minimizefunc = 1
        let opts.breaks       = 0
        let opts.saveopts     = 0
    endif
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
                \(has_key(a:format, 'foldstart') ||
                \ has_key(a:format, 'foldend'))
    let ignorefolds=ignorefolds || !has_key(a:format, 'fold')
    let opts.ignorefolds = ignorefolds
    let opts.allfolds    = allfolds
    "▶2 fillchars
    let fillchars={}
    if has('windows') && has('folding') && (!ignorefolds || opts.dodiff || a:sbsd==1)
        let fcs=split(&fillchars, '\v\,%(%(stl%(nc)?|vert|fold|diff)\:)@=')
        for fc in fcs
            let [o, v]=matchlist(fc, '\v^(\w*)\:(.*)$')[1:2]
            let fillchars[o]=v
        endfor
    endif
    let opts.fillchars = extend({'diff': '-', 'fold': '-', 'vert': '|'}, fillchars)
    "▶2 Tags
    let opts.ignoretags=2
    if has_key(a:format, 'tagstart') || has_key(a:format, 'tagend')
        if a:options.tags is -1
            let opts.ignoretags=s:_f.getoption('IgnoreTags')
        elseif a:options.tags is# 'all'
            let opts.ignoretags=0
        elseif a:options.tags is# 'local'
            let opts.ignoretags=1
        else
            let opts.ignoretags=(2-a:options.tags)
        endif
    endif
    "▶2 Matches
    let matches=((a:options.matches == -1)?
                \   (s:_f.getoption('FormatMatches')):
                \   (a:options.matches))
    if matches is -1
        if has('extra_search') && &hlsearch
            let matches='all'
        else
            let matches='matches'
        endif
    endif
    let opts.formatsearch  = (matches is# 'all' || matches is# 'search')  && !empty(@/)
    let opts.formatmatches = (matches is# 'all' || matches is# 'matches') && !empty(getmatches())
    let opts.formatsomematch = opts.formatsearch || opts.formatmatches
    "▶2 collapsafter
    if a:sbsd
        let opts.collapsafter=0
    else
        let opts.collapsafter=((a:options.collapsfiller==-1)?
                    \               (s:_f.getoption('CollapsFiller')):
                    \               (a:options.collapsfiller))
        if !has_key(a:format, 'difffiller') && has_key(a:format, 'collapsedfiller')
            let opts.collapsafter=1
        elseif !has_key(a:format, 'collapsedfiller')
            let opts.collapsafter=0
        endif
    endif
    "▲2
    "▶2 addoptsfun
    if has_key(a:format, 'addoptsfun')
        call map(copy(a:format.addoptsfun()), 'extend(opts, {"__".v:key : deepcopy(v:val)})')
    endif
    "▶2 Progress bar
    let opts.showprogress=0
    if has('statusline')
      if a:options.progress is -1
        let opts.showprogress=s:_f.getoption('ShowProgress')
      elseif a:options.progress is 'lines'
        let opts.showprogress=2
      elseif a:options.progress is 'percent'
        let opts.showprogress=1
      else
        let opts.showprogress=a:options.progress
      endif
    endif
    let opts.canresize=(s:whatterm is# 'gui')
    "▲2
    return opts
endfunction
"▶1 highlight
function s:F.gethighlight()
    let highlight={}
    call map(split(&highlight, ','), 'extend(highlight, {v:val[0]: v:val[2:]})')
    " FIXME 'highlight' option does not necessary hold C:HiGroup pairs
    return map({
                \'SpecialKey':   '8',
                \'NonText':      '@',
                \'Directory':    'd',
                \'ErrorMsg':     'e',
                \'IncSearch':    'i',
                \'Search':       'l',
                \'MoreMsg':      'm',
                \'ModeMsg':      'M',
                \'LineNr':       'n',
                \'CursorLineNr': 'N',
                \'Question':     'r',
                \'StatusLine':   's',
                \'StatusLineNC': 'S',
                \'Title':        't',
                \'VertSplit':    'c',
                \'Visual':       'v',
                \'VisualNOS':    'V',
                \'WarningMsg':   'w',
                \'WildMenu':     'W',
                \'Folded':       'f',
                \'FoldColumn':   'F',
                \'DiffAdd':      'A',
                \'DiffChange':   'C',
                \'DiffDelete':   'D',
                \'DiffText':     'T',
                \'SignColumn':   '>',
                \'SpellBad':     'B',
                \'SpellCap':     'P',
                \'SpellRare':    'R',
                \'SpellLocal':   'L',
                \'Conceal':      '-',
                \'Pmenu':        '+',
                \'PmenuSel':     '=',
                \'PmenuSbar':    'x',
                \'PmenuThumb':   'X',
            \}, 'get(highlight, v:val, v:key)')
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
    call a:ff.letspec('normal',  'Normal')
    if a:opts.formatconcealed
        call a:ff.letspec('con', a:opts.highlight.Conceal)
    endif
    if a:opts.dosigns
        call a:ff.letspec('sc',  a:opts.highlight.SignColumn)
    endif
    "▶2 Folds
    if a:opts.foldcolumn
        call a:ff.letspec('fc',   a:opts.highlight.FoldColumn)
    endif
    if !a:opts.ignorefolds || a:opts.allfolds
        call a:ff.letspec('fold', a:opts.highlight.Folded)
    endif
    "▲2
    if a:opts.dodiff
        call a:ff.letspec('fill', a:opts.highlight.DiffDelete)
    endif
    "▶2 Line numbers
    if a:opts.dosomenr
        call a:ff.letspec('nr',   a:opts.highlight.LineNr)
        if a:opts.hascline
            if v:version>703 || (v:version==703 && has('patch479'))
                call a:ff.letspec('nrcl', a:opts.highlight.CursorLineNr)
            else
                call a:ff.letspec('nrcl', a:opts.highlight.LineNr, 'CursorLine')
            endif
        endif
    endif
    "▲2
endfunction
"▶1 compilespecfunc
function s:F.compilespecfunc(cf)
    let opts=a:cf.opts
    let cformat=a:cf.cformat
    let d={}
    let hlnamearg='a:hlname'
    if opts.domergehl
        let hlnamearg='a:0?([a:hlname]+a:000):a:hlname'
    endif
    let specfunction=[
\'function d.compiledspec(cf, hlname'.((opts.domergehl)?(', ...'):('')).')',
    \   (opts.domergehl
    \       ?('let key=a:0?join([a:hlname]+a:000,''+''):(empty(a:hlname)?''-'':a:hlname)')
    \       :('let key=empty(a:hlname)?''-'':a:hlname')),
    \'if has_key(a:cf.cache,key)',
    \    'retu a:cf.cache[key]',
    \'en',
    \((opts.docline)?
    \   ('let r=[call(s:F.getspecdict,'.
    \           '['.hlnamearg.']+'.
    \            '((a:hlname is#'.string(opts.highlight.LineNr).')?([0]):([])),{}),'''']'):
    \   ('let r=[s:F.getspecdict('.hlnamearg.'),'''']')),
    \]
    if a:cf.has('style')
        call add(specfunction,
        \'let r[1]=a:cf.cformat.style.f(key,r,'''',a:cf.opts,a:cf)')
        if (a:cf.has('begin') && a:cf.hasreq('begin', ['a:style'])) ||
                    \(a:cf.has('end') && a:cf.hasreq('end', ['a:style']))
            call add(specfunction, 'let a:cf.stylestr.=r[1]')
        endif
    endif
    call extend(specfunction, [
    \'let a:cf.cache[key]=r',
    \'retu r',
\'endfunction'])
    execute join(specfunction, "\n")
    call a:cf.savefunc('compiledspec', specfunction, d.compiledspec)
    return d.compiledspec
endfunction
"▶1 gentrailinglines
function s:F.gentrailinglines(ldiff, slnr, cf)
    let cformat=a:cf.cformat
    let opts=a:cf.opts
    let ldiff=a:ldiff
    let clnr=a:slnr+1
    let ntspec=cformat.compiledspec(a:cf, 'NonText')
    if !opts.ignorefolds
        let fcspec=cformat.compiledspec(a:cf, 'FoldColumn')
    endif
    if opts.dosigns
        let scspec=cformat.compiledspec(a:cf, 'SignColumn')
    endif
    let r=[]
    while ldiff
        let curstr=''
        if a:cf.has('linestart')
            let curstr.=cformat.linestart.f(4, ntspec, clnr, curstr, opts, a:cf)
        endif
        if opts.foldcolumn
            let curstr.=cformat.foldcolumn.f(repeat(' ', opts.foldcolumn), fcspec, clnr,
                        \                    0, curstr, opts, a:cf)
        endif
        if opts.dosigns
            let curstr.=cformat.sign.f('  ', scspec, clnr, 0, curstr, opts, a:cf)
        endif
        if opts.dosomenr
            " XXX
            " Do nothing: line numbers are not displayed in this case, neither any space 
            " is skipped
        endif
        let curstr.=cformat.line.f('~', ntspec, clnr, 0, curstr, opts, a:cf)
        if a:cf.has('lineend')
            let curstr.=cformat.lineend.f(4, ntspec, clnr, 1, curstr, opts, a:cf)
        endif
        call add(r, curstr)
        let clnr+=1
        let ldiff-=1
    endwhile
    return r
endfunction
"▶1 Run side-by-side diff
function s:F.sbsdrun(type, slnr, elnr, options, cf, sbsd)
    let opts=a:cf.opts
    let cformat=a:cf.cformat
    let normalspec=cformat.compiledspec(a:cf, 'Normal')
    let vsspec=cformat.compiledspec(a:cf, opts.highlight.VertSplit)
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
    for dwinnr in dwinnrs
        "▶2 Получение номеров линий в другом буфере
        execute dwinnr.'wincmd w'
        let clnr=1
        let virtclnr=1
        let maxline=line('$')
        let dslnr=0
        let dstartinfiller=0
        let delnr=0
        let notenoughlines=0
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
        if !delnr
            let delnr=line('$')
            let notenoughlines=1
        endif
        "▶2 Получение отформатированных текстов
        if !opts.ignorefolds
            normal! zM
        endif
        let r2=s:F.format(a:type, dslnr, delnr, a:options, i, a:cf)
        "▶2 Добавление sbsdstart или sbsdsep
        let oldcolumns=opts.columns
        unlockvar opts.columns
        let opts.columns=width
        let width+=oldcolumns+1
        unlockvar opts.sbsd
        let opts.sbsd=a:sbsd
        lockvar! opts
        if empty(r)
            let r=r2
            if a:cf.has('sbsdstart')
                call map(r, 'cformat.sbsdstart.f(normalspec, v:key, "", '.
                            \                   'opts, a:cf).v:val')
            endif
        else
            let r2=r2[(dstartinfiller):(len(r)-1+dstartinfiller)]
            if len(r2)<len(r)
                if !notenoughlines
                    call s:_f.warn('nelines')
                endif
                let r2+=s:F.gentrailinglines(len(r)-len(r2), delnr, a:cf)
            endif
            if a:cf.has('sbsdsep')
                call map(r, 'v:val.'.
                            \'cformat.sbsdsep.f(vsspec, v:key, i-1, '.
                            \                  'v:val, opts, a:cf).r2[v:key]')
            endif
        endif
        let i+=1
    endfor
    "▶2 Добавление sbsdend
    unlockvar opts.columns
    let opts.columns=width-1
    execute curwin.'wincmd w'
    unlockvar opts.sbsd
    let opts.sbsd=a:sbsd
    lockvar! opts
    if a:cf.has('sbsdend')
        call map(r, 'v:val.'.
                    \'cformat.sbsdend.f(normalspec, v:key, '.
                    \                   len(dwinnrs).', v:val, opts, a:cf)')
    endif
    "▶2 Начало и конец представления
    if a:cf.has('begin')
        call insert(r, cformat.begin.f(normalspec, '', opts, a:cf.stylestr, a:cf))
    endif
    if a:cf.has('end')
        call add(r, cformat.end.f(normalspec, a:elnr, '', opts, a:cf.stylestr, a:cf))
    endif
    "▶2 nolf/haslf
    if cformat.nolf
        let r=[join(r, '')]
    endif
    if cformat.haslf
        let oldr=r
        let r=[]
        for item in oldr
            let r+=split(item, "\n", 1)
        endfor
    endif
    "▲2
    return r
endfunction
"▶1 getlcsspecstr
function s:F.getlcsspecstr(specstr, opts)
    let lcsspecstr=a:opts.dodiff
                \     ?('(%diffattr'.
                \         '?%ddspec '.
                \         ':'.a:specstr.')')
                \     :a:specstr
    if a:opts.domatches
        let lcsspecstr='(%matchhlname is 0'.
                    \       '?'.lcsspecstr.' '.
                    \       ':%matchhlname)'
    endif
    return lcsspecstr
endfunction
"▶1 format
let s:progress={}
function s:F.format(type, slnr, elnr, options, ...)
    "▶2 Initialize variables
    let [slnr, elnr]=sort([a:slnr, a:elnr], 's:NRSort')
    let sbsd=((empty(a:000))?(0):(a:000[0]))
    if sbsd>1
      let cf=a:2
    else
      let cf=s:F.fmtprepare(a:type, a:options, slnr, elnr, sbsd)
    endif
    call cf.compile(slnr, elnr, a:options, sbsd)
    let cformat=cf.cformat
    let opts=cf.opts
    call s:F.compilespecfunc(cf)
    "▶2 side-by-side diff
    if sbsd==1
      return s:F.sbsdrun(a:type, slnr, elnr, a:options, cf, sbsd)
    endif
    "▲2
    "▶2 Precreation of deleted line if possible, here
    if opts.dodiff
      if opts.persistentfiller
        if cf.has('difffiller')
          let fillspec=cformat.compiledspec(cf, 'DiffDelete')
          let fillerstr=cformat.difffiller.f(opts.fillchars.fold, fillspec, 0, 0, '', opts, cf)
        else
          let fillerstr=''
        endif
      endif
    endif
    "▲2
    let ff=s:F.newff(cf)
    "▶2 Initialize ff variables
    call        ff.leta('%cf', 'a:cf')
    call        ff.leta('%cformat', 'a:cformat')
    call        ff.leta('%opts', 'a:opts')
    call        ff.leta('%r', '[]')    " List with formatted output
    call        ff.leta('%clnr', slnr) " Line being processed
    call        ff.leta('%matchhlname', 0)
    call        ff.leta('%oldmatchhlname', 0)
    call        ff.leta('%name2sptypemap', ff.expr(substitute(string({
                \       'special':     '%specialchar',
                \       'tagstart':    '%startedtag',
                \       'tagend':      '%endedtag',
                \       'matchborder': '%matchhlname',
                \       'trail':       '%dummy',
                \   }), ' ', '', 'g'), 1))
    call        ff.leta('%id', 0)
    call        ff.leta('%spcol', '[]')
    call        ff.leta('%concealinfo', '[0]')
    call        ff.leta('%nocbreak', 0)
    call        ff.leta('%concealedbreak', 0)
    call        ff.letabreak()
    call        s:F.initspecs(ff, opts)
    call        ff.letabreak()
    "▶2 Progress bar support: init
    if opts.showprogress
      set laststatus=2
      call      ff.leta('%oldprogress',    0                  )
      call      ff.leta('%linesprocessed', 0                  )
      call      ff.leta('%linestoprocess', elnr-slnr+1        )
      if !opts.canresize
        " Вторая часть прогресс бара
        " Старые значения % сделанного и длины строки из '=';
        " первая часть progress bar’а со строкой =
        call    ff.leta('%oldcolnum', 0)
        call    ff.leta('%barstart', string('['))
        call    ff.leta('%barlen', opts.barlen)
        call    ff.leta('%barend', string(repeat(' ', opts.barlen).'] '))
      else
        let     s:progress.showprogress=opts.showprogress
        let     s:progress.oldcolnum=0
        let     s:progress.clnr=slnr
        let     s:progress.progress=0
        let     s:progress.elnr=elnr
        let     s:progress.linesprocessed=0
        let     s:progress.linestoprocess=(elnr-slnr+1)
      endif
    endif
    "▶2 Precreation of all sign columns if possible, inside function
    if opts.dosigns
      if opts.persistentsc
        call    ff.letcf('%nosignsc', 'sign', '"  "', '%scspec', 0, 0)
        call    ff.leta('%scols', '{}')
        call    ff.for('[%sname,%sign]', 'items(%opts.signdefinitions)')
        call        ff.if('has_key(%sign,''texthl'')')
        call            ff.leta('%spec', cf.specstr(['%sign.texthl']))
        call        ff.else()
        call            ff.leta('%spec', '%scspec')
        call        ff.endif()
        if s:whatterm is# 'gui'
          call      ff.if('has_key(%sign,''icon'')')
          call          ff.letcf('%scols[%sname]', 'sign', '%sign.icon', '%spec', 0, 2)
          call      ff._up()
        endif
        call        ff.addif('has_key(%sign,''text'')')
        call            ff.letcf('%scols[%sname]', 'sign','%sign.text','%spec',0,1)
        call        ff.else()
        call            ff.letcf('%scols[%sname]', 'sign', '''  ''',  '%scspec', 0,1)
        call        ff.endif()
        call    ff.endfor()
      endif
    endif
    "▶2 Folds
    if opts.allfolds || opts.foldcolumn
      call      ff.leta('%fclnr', slnr)
      "▶3 Get folds closed at the moment
      if !opts.ignorefolds
        call    ff.leta('%closedfolds',     '{}')
        call    ff.leta('%closedfoldslist', '[]')
        if !opts.allfolds
          call  ff.leta('%closedfoldsends', '[]')
        endif
        call    ff.while('%fclnr<='.elnr)
        call        ff.if('foldclosed(%fclnr)!=-1')
        call            ff.call('add(%closedfoldslist,%fclnr)')
        call            ff.letc('%closedfolds[%fclnr]', 'linestart', 1, '%foldspec', '%fclnr')
        if !opts.foldcolumn
          if opts.dosigns
            call        ff.appendc('sign', '"  "', '%foldspec', '%fclnr', 0)
          endif
          if opts.dosomenr
            call        ff.appendc('sign', '"  "', '%foldspec', '%fclnr', 0)
          endif
          call          ff.appendc('fold', 'foldtextresult(%fclnr)', '%foldspec', '%fclnr')
          call          ff.appendc('lineend', 1, '%foldspec', '%fclnr', 0)
        endif
        if !opts.allfolds
          call          ff.call('add(%closedfoldsends, foldclosedend(%fclnr))')
          if opts.showprogress
            call        ff.decrement('%linestoprocess', '%closedfoldsends[-1]-%fclnr')
          endif
          call          ff.leta('%fclnr', '%closedfoldsends[-1]')
        endif
        call        ff.endif()
        call        ff.increment('%fclnr')
        call    ff.endwhile()
      endif
      "▲3
      call      setwinvar(0, '&foldminlines', 0)
      "▶3 Process other folds
      "▶4 Initializing fold column-related variables
      if opts.foldcolumn
        call    ff.leta('%foldlevel',   -1)
        call    ff.leta('%fdchange',     0)
        call    ff.leta('%foldlevels',  '{}')
        call    ff.leta('%foldcolumns', '{}')
        call    ff.leta('%foldclosedcolumns', '{}')
        if opts.persistentfdc
          call  ff.leta('%foldcolumns[-1]', 'repeat(['.
                      \      cf.get('foldcolumn',
                      \             'repeat('' '','.opts.foldcolumn.')',
                      \             '%fcspec', 0, -1, "''").'], 3)')
        else
          call  ff.leta('%foldcolumnstarts', '{}')
          call  ff.leta('%foldcolumns[-1]', repeat(' ', opts.foldcolumn))
        endif
      endif
      "▶4 Initializing common variables
      call      ff.leta('%possiblefolds', '{}')
      call      ff.leta('&foldlevel',     0)
      call      ff.leta('%oldfoldnumber', -1)
      call      ff.leta('%foldnumber',     0)
      "▶4 Main cycle: getting all folds
      call      ff.while('%oldfoldnumber!=%foldnumber')
      call          ff.leta('%oldfoldnumber', '%foldnumber')
      call          ff.leta('%fclnr', slnr)
      "▶5 Fold column
      if opts.foldcolumn
        if opts.foldcolumn>1
          call      ff.if('&foldlevel>='.(opts.foldcolumn-1))
        endif
        call            ff.leta('%rstart', '&foldlevel'.printf('%+d', -(opts.foldcolumn-3)))
        call            ff.leta('%rend',   '&foldlevel')
        call            ff.let('%fdctext',
                    \         '((%rstart<=%rend)?'.
                    \            '((%rend<10)?'.
                    \                '(join(range(%rstart,%rend),'''')):'.
                    \            '((%rstart<10)?'.
                    \                '(join(range(%rstart,9),'''').'.
                    \                 'repeat(''>'',%rend-9))'.
                    \            ':'.
                    \                '(repeat(''>'','.(opts.foldcolumn-2).'))))'.
                    \         ':'.
                    \            '(''''))')
        call            ff.let('%fdcnexttext', '%fdctext.((&foldlevel>=9)?'.
                    \                              '(''>''):'.
                    \                           '((&foldlevel)?'.
                    \                              '(&foldlevel+1):'.
                    \                              '(''|'')))')
        if opts.foldcolumn>1
          call          ff.leta('%fdcclosedtext', '((&foldlevel>='.opts.foldcolumn.')?'.
                    \                              '(((%rstart<=10)?'.
                    \                                  '(%rstart-1):'.
                    \                                  '(''>'')).%fdctext):'.
                    \                              '(repeat(''|'','.(opts.foldcolumn-1).'))).''+''')
        else
          call          ff.leta('%fdcclosedtext', '''+''')
        endif
        call            ff.leta('%fdctextend','repeat('' '','.(opts.foldcolumn-1).'-len(%fdctext))')
        if opts.foldcolumn>1
          call      ff.else()
          call          ff.let('%fdctext', 'repeat(''|'',&foldlevel)')
          call          ff.let('%fdcnexttext', '%fdctext.''|''')
          call          ff.leta('%fdctextend','repeat('' '','.(opts.foldcolumn-1).'-len(%fdctext))')
          call          ff.let('%fdcclosedtext', '%fdctext.''+''.%fdctextend')
          call      ff.endif()
        endif
        call        ff.append('%fdcnexttext', '%fdctextend')
        call        ff.leta('%fdcopenedtext', '%fdctext.''-''.%fdctextend')
        if opts.persistentfdc
          call      ff.let('%foldcolumns[&foldlevel]', '['.
                      \   join(map(['%fdcclosedtext', '%fdcopenedtext', '%fdcnexttext'],
                      \             'cf.get("foldcolumn",v:val,"%fcspec",0,'.
                      \                    '"&foldlevel","''''")'), ',').']')
        else
          call      ff.leta('%foldcolumns[&foldlevel]', '%fdcnexttext')
        endif
      endif
      "▶5 Obtaining folds positions
      call          ff.while('%fclnr<='.elnr)
      call              ff.if('foldclosed(%fclnr)>-1')
      call                  ff.leta('%foldend', 'foldclosedend(%fclnr)')
      if opts.allfolds
        let                 foldtextstr='foldtextresult(%fclnr)'
        if opts.dosomenr
          let               formatstr='''%%'.opts.linenumlen.'u'''
          if opts.donr && opts.dornr
            let             formatstr='%fclnr=='.opts.cline.
                        \                   '?'.substitute(formatstr, '%%', '%%-', '').
                        \                   ':'.formatstr
          endif
          let               foldtextstr='printf('.formatstr.','.cf.getnrstr('%fclnr').').'' ''.'.
                      \                 foldtextstr
        endif
        if opts.dosigns
          let               foldtextstr='''  ''.'.foldtextstr
        endif
        if opts.foldcolumn
          let               foldtextstr='%fdcclosedtext.'.foldtextstr
        endif
        call                ff.leta('%foldtext', foldtextstr)
        if opts.foldminlines>0
          call              ff.if('%foldend-%fclnr>'.opts.foldminlines)
        endif
        if cf.has('foldstart')
          call                  ff.if('!has_key(%possiblefolds,%fclnr)')
          call                      ff.let('%possiblefolds[%fclnr]', '{}')
          call                  ff.endif()
          call                  ff.if('!has_key(%possiblefolds[%fclnr],''start'')')
          call                      ff.let('%possiblefolds[%fclnr].start', '[]')
          call                  ff.endif()
          call                  ff.call('add(%possiblefolds[%fclnr].start,'.
                      \                      cf.get('foldstart', '%foldtext', '%foldspec', '%fclnr',
                      \                             '&foldlevel', "''").')')
        endif
        if cf.has('foldend')
          call                  ff.leta('%foldinsbefore', '%foldend+1')
          call                  ff.if('!has_key(%possiblefolds,%foldinsbefore)')
          call                      ff.let('%possiblefolds[%foldinsbefore]', '{}')
          call                  ff.endif()
          call                  ff.if('!has_key(%possiblefolds[%foldinsbefore],''end'')')
          call                      ff.let('%possiblefolds[%foldinsbefore].end', '[]')
          call                  ff.endif()
          call                  ff.call('add(%possiblefolds[%foldinsbefore].end,'.
                \                            cf.get('foldend', '%foldtext', '%foldspec',
                \                                   '%foldend', '&foldlevel', "''").')')
        endif
        if opts.foldminlines>0
          call              ff.endif()
        endif
      endif
      if opts.foldcolumn
        call                ff.leta('%foldlevels[%fclnr]', '&foldlevel')
        call                ff.if('!has_key(%foldlevels, %foldend+1)')
        call                    ff.let('%foldlevels[%foldend+1]', '&foldlevel-1')
        call                ff.endif()
        let             self.__curvar='%closedfolds[%fclnr]'
        if !opts.persistentfdc
         if !opts.ignorefolds
          call              ff.if('has_key(%closedfolds, %fclnr)')
          call                  ff.appendc('foldcolumn', '%fdcclosedtext', '%fcspec', '%fclnr',
                      \                '&foldlevel')
          if opts.dosigns
            call                ff.appendc('sign', '"  "', '%foldspec', '%fclnr', 0,)
          endif
          if opts.dosomenr
            call                ff.appendc('linenr',cf.getnrstr('%fclnr'), '%foldspec', '%fclnr')
          endif
          call                  ff.appendc('fold', 'foldtextresult(%fclnr)', '%foldspec', '%fclnr')
          call                  ff.appendc('lineend', 1, '%foldspec', '%fclnr', 0)
          call              ff.endif()
         endif
         call               ff.letcf('%foldcolumnstarts[%fclnr]', 'foldcolumn', '%fdcopenedtext',
                     \               '%fcspec', '%fclnr', '&foldlevel')
        elseif !opts.ignorefolds
         call               ff.if('has_key(%closedfolds, %fclnr)')
         call                   ff.appendc('%foldcolumns[&foldlevel][0]')
         if opts.dosigns
           call                 ff.appendc('sign', '"  "', '%foldspec', '%fclnr', 0)
         endif
         if opts.dosomenr
           call                 ff.appendc('linenr', cf.getnrstr('%fclnr'), '%foldspec', '%fclnr')
         endif
         call                   ff.appendc('fold', 'foldtextresult(%fclnr)', '%foldspec', '%fclnr')
         call                   ff.appendc('lineend', 1, '%foldspec', '%fclnr', 0)
         call               ff.endif()
        endif
      endif
      call                  ff.let('%fclnr', '%foldend')
      call                  ff.increment('%foldnumber')
      call              ff.endif()
      call              ff.increment('%fclnr')
      call          ff.endwhile()
      call          ff.increment('&foldlevel')
      call      ff.endwhile()
    endif
    "▶2 Main cycle: processing lines
    call        ff.while('%clnr<='.(elnr+((opts.dodiff)?(1):(0))))
    call            ff.letc('%curstr', "''")
    if opts.checkcline
        call        ff.leta('%iscline', '%clnr=='.opts.cline)
    endif
    "▶3 Fold column support
    if opts.foldcolumn
      if opts.dodiff
        call        ff.leta('%fillfoldlevel', '%foldlevel')
      endif
      call          ff.if('has_key(%foldlevels, %clnr)')
      call              ff.let('%fdchange', 1)
      call              ff.leta('%foldlevel', '%foldlevels[%clnr]')
      call          ff.else()
      call              ff.let('%fdchange', 0)
      call          ff.endif()
    endif
    "▶3 Progress bar support
    if opts.showprogress
      if opts.canresize
        call        ff.leta('%barlen', 'winwidth(0)-'.((opts.showprogress==2)?
                    \                                   ((len(elnr)*2)+10):
                    \                                   ('8')))
      endif
      call          ff.increment('%linesprocessed')
      call          ff.leta('%progress', '100*%linesprocessed/%linestoprocess')
      call          ff.leta('%colnum', ((opts.canresize)?
                  \                         ('%barlen'):
                  \                         (opts.barlen)).
                  \                    '*%linesprocessed/%linestoprocess')
      if opts.showprogress!=2
        call        ff.if('%progress!=%oldprogress || '.
                    \     '%colnum!='.((opts.canresize)?
                    \                       ('s:progress.'):
                    \                       ('%')).'oldcolnum')
      endif
      if opts.canresize
        call            ff.leta('%bar', '''[''.repeat(''='',%colnum).''>''.'.
                    \                         'repeat('' '',%barlen-%colnum).''] ''')
      else
        call            ff.if('%colnum!=%oldcolnum')
        call                ff.append('%barstart', 'repeat("=",%colnum-%oldcolnum)')
        call                ff.let('%barend', '%barend[%colnum-%oldcolnum :]')
        call            ff.endif()
        call            ff.let('%bar', '%barstart.">".%barend')
      endif
      call              ff.append('%bar', ((opts.showprogress==2)?
                  \                             ('repeat('' '','.opts.linenumlen.'-len(%clnr))'.
                  \                              '.%clnr.''/'.elnr.' ''.'):
                  \                             ('')).
                  \                       'repeat('' '',3-len(%progress)).%progress.''%%''')
      call              ff.call('setwinvar(0,''&statusline'',%bar)')
      call              ff.do('redrawstatus')
      if opts.showprogress!=2
        call        ff.endif()
      endif
      call          ff.let('%oldprogress', '%progress')
      call          ff.leta(((opts.canresize)?('s:progress.'):('%')).'oldcolnum', '%colnum')
      if opts.canresize
       call         ff.leta('s:progress.progress', '%progress')
       call         ff.leta('s:progress.linesprocessed', '%linesprocessed')
       if opts.showprogress==2
        call        ff.leta('s:progress.clnr', '%clnr')
       endif
      endif
    endif
    "▶3 Processing deleted lines
    if opts.dodiff
      call          ff.leta('%filler', 'diff_filler(%clnr)')
      call          ff.if('%filler>0')
      call              ff.letcf('%curstrstart', 'linestart',
                  \              2.((opts.collapsafter)?
                  \                      '+(%filler>='.opts.collapsafter.')':
                  \                      ''), '%fillspec', '%clnr')
      "▶4 Leading columns (fold, sign, number)
      if opts.foldcolumn
        call            ff.append('%curstrstart', ((opts.persistentfdc)?
                    \                      ('%foldcolumns[%fillfoldlevel][2]'):
                    \                      (cf.get('foldcolumn',
                    \                              '%foldcolumns[%fillfoldlevel]',
                    \                              '%fcspec', '%clnr',
                    \                              '%fillfoldlevel',
                    \                              '%curstrstart'))))
      endif
      if opts.dosigns
        call            ff.append('%curstrstart', ((opts.persistentsc)?
                    \                                      ('%nosignsc'):
                    \                                      (cf.get('sign', '"  "', '%scspec',
                    \                                              '%clnr', 0, '%curstrstart'))))
      endif
      if opts.dosomenr
        call            ff.appendcf('%curstrstart', 'linenr',"''", '%nrspec', '%clnr')
      endif
      "▶4 Filler
      if !opts.persistentfiller
        if opts.collapsafter
          call          ff.if('%filler<'.opts.collapsafter)
        endif
        call                ff.let('%curfil', '%filler')
        call                ff.while('%curfil')
        call                    ff.let('%curstr', '%curstrstart')
        call                    ff.appendc('difffiller', s:F.squote(opts.fillchars.diff),
                    \                      '%fillspec', '%clnr', '%curfil')
        call                    ff.appendc('lineend', 2, '%fillspec', '%clnr',0)
        call                    ff.call('add(%r,%curstr)')
        call                    ff.decrement('%curfil')
        call                ff.endwhile()
        if opts.collapsafter
          call          ff.else()
          call              ff.let('%curstr', '%curstrstart')
          call              ff.appendc('collapsedfiller', '%filler', '%fillspec', '%clnr')
          call              ff.appendc('lineend', 3, '%fillspec', '%clnr', 0)
          call              ff.call('add(%r,%curstr)')
          call          ff.endif()
        endif
      else
        call            ff.let('%curstr', '%curstrstart')
        call            ff.appendc(s:F.squote(fillerstr))
        call            ff.appendc('lineend', 2, '%fillspec', '%clnr', 0)
        call            ff.increment('%r', 'repeat([%curstr],%filler)')
      endif
      "▲4
      call              ff.let('%curstr', "''")
      call          ff.endif()
      call          ff.if('%clnr>'.elnr)
      call              ff.break()
      call          ff.endif()
    endif
    "▶3 Processing folds
    if !opts.ignorefolds && !opts.allfolds && !opts.foldcolumn "▶4
      call          ff.if('foldclosed(%clnr)!=-1')
      call              ff.letcf('%curstr', 'linestart', 1, '%foldspec', '%clnr')
      if opts.dosigns
        call            ff.appendc('sign', '"  "', '%foldspec', '%clnr', 0)
      endif
      if opts.dosomenr
        call            ff.appendc('linenr', cf.getnrstr('%clnr'), '%foldspec', '%clnr')
      endif
      call              ff.appendc('fold', 'foldtextresult(%clnr)', '%foldspec', '%clnr')
      call              ff.appendc('lineend', 1, '%foldspec', '%clnr', 0)
      call              ff.call('add(%r,%curstr)')
      call              ff.let('%clnr', 'foldclosedend(%clnr)+1')
      call              ff.continue()
      call          ff.else()
    elseif opts.allfolds || opts.foldcolumn "▶4
      if opts.allfolds
        call        ff.if('has_key(%possiblefolds,%clnr)')
        call            ff.let('%pf', '%possiblefolds[%clnr]')
        if cf.has('foldend')
          call          ff.if('has_key(%pf,''end'')')
          call              ff.increment('%r', '%pf.end')
          call          ff.endif()
        endif
        if cf.has('foldstart')
          call          ff.if('has_key(%pf,''start'')')
          call              ff.increment('%r', '%pf.start')
          call          ff.endif()
        endif
        call        ff.endif()
      endif
      if !opts.ignorefolds
        call        ff.if('!empty(%closedfoldslist)&&%clnr==%closedfoldslist[0]')
        call            ff.call('remove(%closedfoldslist,0)')
        call            ff.call('add(%r,%closedfolds[%clnr])')
        if !opts.allfolds
          call          ff.let('%clnr', 'remove(%closedfoldsends,0)+1')
          call          ff.decrement('%foldlevel')
          call          ff.continue()
        endif
        call        ff.endif()
      endif
    endif
    "▶3 Processing regular lines
    "▶4 Initializing variables
    call                ff.let('%linestr',  'getline(%clnr)')
    call                ff.let('%linelen',  'len(%linestr)')
    " Indicates that this line differs
    call                ff.leta('%diffattr', ((opts.dodiff)?('diff_hlID(%clnr,1)'):(0)))
    if opts.formatconcealed
      call              ff.leta('%concealdiff', 0)
    endif
    call                ff.leta('%specialcolumns', 'deepcopy(get(%opts.splcolumns,%clnr,{}))')
    if opts.dodiff "▶5
      " XXX diffid is taken from beyond the end of line because inside the line there may be 
      "     differences in highlighting: overall line is highlighted in one color and parts that 
      "     differ in the other
      call              ff.if('%diffattr')
      call                  ff.let('%diffid', 'diff_hlID(%clnr,%linelen+1)')
      call                  ff.let('%diffhlname', 'synIDattr(%diffid,''name'')')
      call                  ff.let('%dspec', cf.specstr(['''Normal''','%diffhlname']))
      call              ff.else()
      call                  ff.let('%diffid', 0)
      call              ff.endif()
    endif "▲5
    if has_key(opts.listchars, 'trail')
      call              ff.leta('%trail', 'match(%linestr,''\v\s*$'')')
      call              ff.let('%specialcolumns[%trail+1]',
                  \                           'add(get(%specialcolumns,%trail+1,[]),[''trail'',0])')
    endif
    "▶4 Line start
    "▶5 Find sign
    if opts.dosigns
      call              ff.leta('%sign', 'get(get(%opts.placedsigns,%clnr,[]),1,{})')
    endif
    "▶5 Determine line spec
    " Full rules are listed later. Rules used here:
    "   diff > cursorline > signs > normal
    " Anything but normal is cancelled by highlighting with higher priority.
    let                 linehlnamestrbase='[''Normal'']'
    let                 linehlnamestr=linehlnamestrbase
    if opts.dosigns
      let               linehlnamestr='(has_key(%sign,''linehl'')'.
                  \                         '?['.linehlnamestrbase[1:-2].',%sign.linehl]'.
                  \                         ':'.linehlnamestr.')'
    endif
    if opts.docline
      " XXX CursorLine highlight group is NOT controlled by &highlight option
      let               linehlnamestr='(%iscline'.
                  \                         '?['.linehlnamestrbase[1:-2].',''CursorLine'']'.
                  \                         ':'.linehlnamestr.')'
    endif
    if opts.dodiff
      let               linehlnamestr='(%diffattr'.
                  \                         '?['.linehlnamestrbase[1:-2].',%diffhlname]'.
                  \                         ':'.linehlnamestr.')'
    endif
    let                 linehlnamestrorig=linehlnamestr
    call                ff.let('%linehlname', linehlnamestr)
    let                 linehlnamestr='%linehlname'
    if linehlnamestrorig is# linehlnamestrbase
      call              ff.leta('%linespec', '%normalspec')
    else
      call              ff.let( '%linespec', cf.specstr(linehlnamestr))
    endif
    "▲5
    call                ff.appendc('linestart', 0, '%linespec', '%clnr')
    if opts.foldcolumn "▶5
      if opts.persistentfdc
        call            ff.appendc('%foldcolumns[%foldlevel][2-%fdchange]')
      else
        call            ff.if('has_key(%foldcolumnstarts,%clnr)')
        call                ff.appendc('%foldcolumnstarts[%clnr]')
        call            ff.else()
        call                ff.appendc('foldcolumn', '%foldcolumns[%foldlevel]', '%fcspec', '%clnr',
                    \                  '%foldlevel')
        call            ff.endif()
      endif
    endif
    if opts.dosigns "▶5
      call              ff.if('!empty(%sign)')
      if opts.persistentsc
        call                ff.appendc('%scols[%opts.placedsigns[%clnr][1].id]')
      else
        call                ff.let('%sign', '%opts.placedsigns[%clnr][1]')
        call                ff.let('%sspec', 'has_key(%sign,''texthl'')?'.
                    \                  cf.specstr(['%sign.texthl']).':%scspec')
        if s:whatterm is# 'gui'
          call              ff.addif('has_key(%sign,''icon'')')
          call                  ff.appendc('sign', '%sign.icon', '%sspec', '%clnr', 2)
          call              ff._up()
        endif
        call                ff.addif('has_key(%sign,''text'')')
        call                    ff.appendc('sign', '%sign.text', '%sspec', '%clnr', 1)
        call                ff.else()
        call                    ff.appendc('sign','"  "', '%scspec', '%clnr', 1)
        call                ff.endif()
      endif
      call              ff.else()
      if opts.persistentsc
        call                ff.appendc('%nosignsc')
      else
        call                ff.appendc('sign', '"  "', '%scspec', '%clnr', 0)
      endif
      call              ff.endif()
    endif
    if opts.dosomenr "▶5
      call              ff.appendc('linenr', cf.getnrstr('%clnr'),
                  \                ((opts.hascline)?
                  \                   ('(%iscline?'.
                  \                       '%nrclspec :'.
                  \                       '%nrspec)'):
                  \                   ('%nrspec')), '%clnr')
    endif
    "▶4 Processing line text
    "▶5 Initialize variables
    call                ff.leta('%cstartcol', 0)
    call                ff.leta('%oldid', hlID('Normal'))
    if opts.dodiff
      call              ff.leta('%olddiffid', '%diffid')
    endif
    if opts.formatconcealed
      call              ff.leta('%oldconcealinfo', '[0]')
      if opts.formatconcealed==1
        call            ff.leta('%concealed', 0)
      endif
    endif
    call                ff.leta('%curcol',   1)
    if opts.dosigns
      call              ff.leta('%hlnamebase', 'has_key(%sign,''linehl'')?[%sign.linehl]:[]')
    endif
    call                ff.leta('%startcol', '1')
    "▲5
    "▶5 Initialize lists
    " XXX Concealed list MUST be initialized in one loop as otherwise synconcealed()[-1] will report 
    "     different values on each loop run
    if opts.formatconcealed
      let               synconcealedstr='map(range(1,%linelen),''synconcealed(''.%clnr.'',v:val)'')'
      if opts.formatconcealedcursor
        let             synconcealedstr='%iscline?repeat([[0]],%linelen):'.synconcealedstr
      endif
      call              ff.leta('%synconcealed', synconcealedstr)
    endif
    "▲5
    call                ff.while('%curcol<=%linelen')
    "▶5 Initialize variables
    "▶6 idstr
    " Note: collecting all IDs and concealinfo at once with map(range()) appears to be much slower.
    let                     idstr='synID(%clnr,%curcol,1)'
    if has_key(opts.listchars, 'trail')
      let                   idstr='%curcol>%trail'.(opts.dolinemergehl?
                  \                                     '&&len(%linehlname)==1':
                  \                                     '').
                  \                     '?'.hlID(opts.highlight.SpecialKey).
                  \                     ':'.idstr
    endif
    "▶6 Concealed characters break condition, with hack
    if opts.formatconcealed
      let                   concealedbreakstr='(%concealinfo[0]||%oldconcealinfo[0])'.
                  \                          '&&%concealinfo!=#%oldconcealinfo'
      if opts.conceallevel==2
        " XXX This is a hack to make the following work as displayed:
        " :syntax match Group  /alpha/ conceal cchar=a
        " :syntax match Group1   /p/   contained containedin=Group
        " With the above syntax code text `alpha` is matched as below:
        "     alpha
        "     ^^^^^ Group
        "       ^   Group1
        " It is displayed as "a" (*single* a) when cole=2 (and "a-a" when cole=1 thus no hack needed 
        " for that level).
        " %nocbreak variable is used later to omit updating %oldconcealinfo
        let                 nocbreakstr='%concealinfo[0]'.
                    \                 '&&%oldconcealinfo[0]'.
                    \                 '&&!empty(%oldconcealinfo[1])'.
                    \                 '&&empty(%concealinfo[1])'
        let                 concealedbreakstr='!%nocbreak&&('.concealedbreakstr.')'
      endif
    endif
    "▲6
    let                     whilecond=
                \           '%curcol<=%linelen&&!empty(extend(l:,{''%id'':'.idstr.
                \            (opts.dodiff
                \               ? ',''%diffid'':diff_hlID(%clnr,%curcol)'
                \               : '').
                \            (opts.formatconcealed
                \               ? ',''%concealinfo'':%synconcealed[%curcol-1]'
                \               : '').
                \            ',''%spcol'':get(%specialcolumns,%curcol,[])}))'.
                \            (opts.formatconcealed && opts.conceallevel==2
                \               ? '&&!empty(extend(l:,{''%nocbreak'':'.nocbreakstr.'}))'
                \               : '').
                \            (opts.formatconcealed
                \               ? '&&!empty(extend(l:,{''%concealedbreak'':'.concealedbreakstr.'}))'
                \               : '').
                \            '&&%id==%oldid'.
                \            '&&empty(%spcol)'.
                \            (opts.dodiff
                \               ? '&&%diffid==%olddiffid'
                \               : '').
                \            (opts.formatconcealed
                \               ? '&&!%concealedbreak'
                \               : '').
                \            '&&!empty(extend(l:,{''%curcol'':%curcol+1}))'
    call                    ff.while(whilecond)
    call                    ff.endwhile()
    "▶5 Process breaks
    "▶6 Process special columns
    call                    ff.call('map(%spcol,'.
                \                            '''extend(l:,{%name2sptypemap[v:val[0]]:v:val[1]})'')')
    "▲6
    "▶6 Highlighting breaks in any case
    call                    ff.if('%startcol<%curcol'.(opts.formatconcealed==1?'&&!%concealed': ''))
    call                        ff.leta('%cstr', '%linestr[%startcol-1:%curcol-2]')
    let                         hlnamestr='[synIDattr(%oldid,''name'')]'
    let                         hlnamestradd='[]'
    if opts.dosigns
      let                       hlnamestradd='%hlnamebase'
    endif
    if opts.docline
      " XXX CursorLine highlight group is NOT controlled by &highlight option
      let                       hlnamestradd='(%iscline'.
                  \                                 '?[''CursorLine'']'.
                  \                                 ':'.hlnamestradd.')'
    endif
    if opts.dodiff
      let                       hlnamestradd='(%diffattr'.
                  \                                 '?[synIDattr(%olddiffid,''name'')]'.
                  \                                 ':'.hlnamestradd.')'
    endif
    if opts.domatches
      let                       hlnamestradd='(%oldmatchhlname is 0'.
                  \                                 '?'.hlnamestradd.
                  \                                ' :[%oldmatchhlname])'
    endif
    if hlnamestradd isnot# '[]'
      let                       hlnamestr.='+'.hlnamestradd
    endif
    if has_key(opts.listchars, 'trail')
      call                      ff.if('%startcol-1>=%trail')
      call                          ff.let('%cstr', 'substitute(%cstr,'' '','.
                  \                        escape(s:F.squote(opts.listchars.trail),'\&~').',''g'')')
      if opts.domatches
        let                     trailhlnamestr='(%oldmatchhlname is 0'.
                    \                                   '?('.hlnamestr.')'.
                    \                                   ':[%oldmatchhlname])'
        call                        ff.leta('%curspec', cf.specstr(trailhlnamestr))
        call                    ff.else()
      else
        call                    ff.endif()
      endif
    endif
    call                            ff.leta('%curspec', cf.specstr(hlnamestr))
    if has_key(opts.listchars, 'trail') && opts.domatches
      call                      ff.endif()
    endif
    call                        ff.appendc('line', '%cstr', '%curspec', '%clnr', '%startcol')
    call                    ff.endif()
    "▲6
    "▶6 Update oldid and startcol
    call                    ff.leta('%oldid', '%id')
    call                    ff.leta('%startcol', '%curcol')
    "▲6
    "▶6 Tag breaks
    if opts.dotags && cf.has('tagend')
      call                  ff.if('exists(''%endedtag'')')
      call                      ff.appendc('tagend', '%endedtag', '0', '%clnr', '%curcol')
      call                      ff.unlet('%endedtag')
      call                  ff.endif()
    endif
    if opts.dotags && cf.has('tagstart')
      call                  ff.if('exists(''%startedtag'')')
      call                      ff.appendc('tagstart', '%startedtag', '0', '%clnr', '%curcol')
      call                      ff.unlet('%startedtag')
      call                  ff.endif()
    endif
    "▲6
    "▶6 Concealed character breaks
    if opts.formatconcealed
      call                  ff.addif('%concealedbreak')
      let                       ccstrstr='%oldconcealinfo[1]'
      let                       ccstrlendiffstr='-!empty(%ccstr)'
      if opts.conceallevel==1
        let                     ccstrstr='empty('.ccstrstr.')'.
                    \                       '?'.s:F.squote(get(opts.listchars,'conceal',' ')).
                    \                       ':('.ccstrstr.')'
        let                     ccstrlendiffstr='-1'
      elseif opts.conceallevel==3
        let                     ccstrlendiffstr=''
      endif
      let                       concealdiffstr=s:strdisplaywidthstr.'('.
                  \                       '%linestr[%cstartcol-1:%curcol-2],'.
                  \                       '%cstartcol==1'.
                  \                           '?0'.
                  \                           ':'.s:strdisplaywidthstr.'(%linestr[:%cstartcol-2]))'.
                  \                         ccstrlendiffstr
      if opts.formatconcealed==1
        call                    ff.if('%oldconcealinfo[0]')
        call                        ff.let('%concealed', 0)
        if opts.conceallevel!=3
          call                      ff.leta('%ccstr', ccstrstr)
          if opts.conceallevel==2
            call                    ff.if('!empty(%ccstr)')
          endif
          call                          ff.appendc('line', '%ccstr','%conspec','%clnr','%cstartcol')
          if opts.conceallevel==2
            call                    ff.endif()
          endif
        endif
        call                        ff.increment('%concealdiff', concealdiffstr)
        call                    ff.endif()
        call                    ff.if('%concealinfo[0]')
        call                        ff.let('%concealed', 1)
        call                        ff.leta('%cstartcol', '%curcol')
        call                    ff.endif()
        " TODO
      elseif opts.formatconcealed==2
        if cf.has('concealedend')
          call                  ff.if('%oldconcealinfo[0]')
          call                      ff.let('%ccstr', ccstrstr)
          call                      ff.appendc('concealedend','%ccstr','%conspec','%clnr','%curcol')
          call                      ff.increment('%concealdiff', concealdiffstr)
          call                  ff.endif()
        endif
        call                    ff.if('%concealinfo[0]')
        call                        ff.let('%cstartcol', '%curcol')
        if cf.has('concealedstart')
          call                      ff.appendc('concealedstart',
                      \                         substitute(ccstrstr, 'old', '', 'g'),
                      \                         '%conspec', '%clnr', '%curcol')
        endif
        call                    ff.endif()
      endif
      call                  ff.endif()
    endif
    "▲6
    "▶6 Special characters
    call                    ff.if('exists(''%specialchar'')'.
                \                                     (opts.formatconcealed==1?'&&!%concealed': ''))
    if has_key(opts.listchars, 'tab')
      call                      ff.if("%specialchar is#'\t'")
      call                          ff.let('%virtstartcol',
                  \                         '%curcol==1?0:'.
                  \                             s:strdisplaywidthstr.'(%linestr[:(%curcol-2)])')
      let                           ival=(&tabstop-1).'-%virtstartcol%%'.&tabstop
      if opts.formatconcealed
        let                         cival='%concealdiff+'.ival
        if opts.formatconcealed==1
          let                       ival=cival
        endif
      endif
      let                           lcstabfirst=matchstr(opts.listchars.tab, '\v^.')
      let                           lcstabnext=opts.listchars.tab[len(lcstabfirst):]
      call                          ff.let('%cstr', s:F.squote(lcstabfirst).'.'.
                  \                                'repeat('.s:F.squote(lcstabnext).','.ival.')')
      if opts.list
        let                         tabhlnamestr='[''SpecialKey'']'
        if opts.dolinemergehl
          let                       tabhlnamestr='(len(%linehlname)>1?'.
                      \                      substitute(substitute(linehlnamestrorig,
                      \                          '''Normal''', 'synIDattr(%id,''name'')', 'g'),
                      \                          '%diffhlname', 'synIDattr(%diffid,''name'')', 'g').
                      \                     ':'.tabhlnamestr.')'
        endif
        if opts.domatches
            let                     tabhlnamestr='(%matchhlname is 0'.
                        \                           '?'.tabhlnamestr.
                        \                           ':[%matchhlname])'
        endif
        " FIXME Still not completely correct
      else
        let                         tabhlnamestr=substitute(hlnamestr, 'old', '', 'g')
      endif
      call                          ff.let('%tabspec', cf.specstr(tabhlnamestr))
      if opts.formatconcealed==2
        call                        ff.let('%ccstr', s:F.squote(lcstabfirst).'.'.
                    \                               'repeat('.s:F.squote(lcstabnext).','.cival.')')
        if cf.has('concealedstart')
          call                      ff.if('%ccstr isnot#%cstr')
          call                          ff.appendc('concealedstart', '%ccstr', '%tabspec', '%clnr',
                      \                            '%curcol')
          call                      ff.endif()
        endif
        " TODO Test narrowing down tabs when line is hovered
      endif
      call                          ff.appendc('line', '%cstr', '%tabspec', '%clnr', '%curcol')
      if opts.formatconcealed==2
        if cf.has('concealedend')
          call                      ff.if('%ccstr isnot#%cstr')
          call                          ff.appendc('concealedend', '%ccstr', '%tabspec', '%clnr',
                      \                            '%curcol')
          call                      ff.endif()
        endif
      endif
      if opts.formatconcealed
        call                        ff.let('%concealdiff', 0)
      endif
      call                      ff.else()
    endif
    let                             sphlnamestr=string(opts.highlight.NonText)
    if has_key(opts.listchars, 'nbsp')
      let                           sphlnamestr='(%specialchar is#'' '''.
                  \                                 '?'.string(opts.highlight.SpecialKey).
                  \                                 ':'.sphlnamestr.')'
    endif
    if opts.dolinemergehl
      let                           sphlnamestr=
                  \                     '(len(%linehlname)>1?'.
                  \                           substitute(linehlnamestrorig,
                  \                                   '''Normal''', 'synIDattr(%id,''name'')', 'g').
                  \                          ':'.sphlnamestr.')'
    endif
    if opts.domatches
      let                           sphlnamestr='(%matchhlname is 0?'.sphlnamestr.':[%matchhlname])'
    endif
    let                             spcharstr='strtrans(%specialchar)'
    if has_key(opts.listchars, 'nbsp')
      let                           spcharstr='(%specialchar is#'' '''.
                  \                             '?'.s:F.squote(opts.listchars.nbsp).
                  \                             ':'.spcharstr.')'
    endif
    " FIXME Not completely correct, see rules
    let                             sphlnamestr=substitute(substitute(hlnamestr,
                \                                    'old',                      '',           'g'),
                \                                    '\VsynIDattr(%id,''name'')', sphlnamestr, 'g')
    call                            ff.let('%spspec', cf.specstr(sphlnamestr))
    call                            ff.appendc('line', spcharstr, '%spspec', '%clnr', '%curcol')
    if has_key(opts.listchars, 'tab')
      call                      ff.endif()
    endif
    call                        ff.leta('%oldid', '-1')
    call                        ff.leta('%startcol', '%curcol+len(%specialchar)')
    call                        ff.let('%curcol', '%startcol-1')
    call                        ff.unlet('%specialchar')
    if opts.formatconcealed==1
      call                  ff.elseif('exists(''%specialchar'')')
      call                      ff.unlet('%specialchar')
    endif
    call                    ff.endif()
    "▲6
    "▶6 Record new variable values
    if opts.dodiff
      call                  ff.leta('%olddiffid', '%diffid')
    endif
    if opts.formatconcealed
      if opts.conceallevel==2
        call                ff.if('!%nocbreak')
      endif
      call                      ff.leta('%oldconcealinfo', '%concealinfo')
      if opts.conceallevel==2
        call                ff.endif()
      endif
    endif
    if opts.domatches
      call                  ff.leta('%oldmatchhlname', '%matchhlname')
    endif
    "▲6
    "▲5
    "▶5 Finish cycle
    call                    ff.increment('%curcol')
    call                ff.endwhile()
    "▲5
    "▲4
    "▶4 Line end
    "▶5 Concealed characters: formatconcealed=1
    if opts.formatconcealed==1
      call              ff.if('%concealed')
      call                  ff.leta('%ccstr', ccstrstr)
      if opts.conceallevel!=3
        if opts.conceallevel==2
          call              ff.if('!empty(%ccstr)')
        endif
        call                    ff.appendc('line', '%ccstr', '%conspec', '%clnr', '%cstartcol')
        if opts.conceallevel==2
          call              ff.endif()
        endif
      endif
      call              ff._up()
    endif
    "▲5
    "▶5 Regural text
    call                ff.addif('%startcol<=%linelen')
    call                    ff.leta('%cstr', '%linestr[%startcol-1:]')
    if has_key(opts.listchars, 'trail')
      call                  ff.if('%startcol-1>=%trail')
      call                      ff.let('%cstr', 'substitute(%cstr,'' '','.
                  \                        escape(s:F.squote(opts.listchars.trail),'\&~').',''g'')')
      if opts.domatches
        call                    ff.leta('%curspec', cf.specstr(trailhlnamestr))
        call                ff.else()
      else
        call                ff.endif()
      endif
    endif
    call                        ff.leta('%curspec', cf.specstr(hlnamestr))
    if has_key(opts.listchars, 'trail') && opts.domatches
      call                  ff.endif()
    endif
    call                    ff.appendc('line', '%cstr', '%curspec', '%clnr', '%startcol')
    call                ff.endif()
    "▲5
    "▶5 Concealed characters: formatconcealed=2
    if opts.formatconcealed==2 && cf.has('concealedend')
      call              ff.if('%oldconcealinfo[0]')
      call                  ff.appendc('concealedend', ccstrstr, '%conspec', '%clnr', '%curcol')
      call              ff.endif()
    endif
    "▲5
    "▶5 Special columns
    if opts.domatches || opts.dotags
      call              ff.if('has_key(%specialcolumns,%linelen+1)')
      call                  ff.call('map(%specialcolumns[%linelen+1],'.
                  \                    '''extend(l:,{%name2sptypemap[v:val[0]]:v:val[1]})'')')
      call                  ff.let('%oldmatchhlname', '%matchhlname')
      call              ff.endif()
    endif
    if opts.dotags && cf.has('tagstart')
      call                  ff.if('exists(''%startedtag'')')
      call                      ff.unlet('%startedtag')
      call                  ff.endif()
    endif
    "▲5
    "▶5 Tags
    if opts.dotags && cf.has('tagend')
      call                  ff.if('exists(''%endedtag'')')
      call                      ff.appendc('tagend', '%endedtag', '0', '%clnr', '%curcol')
      call                      ff.unlet('%endedtag')
      call                  ff.endif()
    endif
    if opts.dotags && cf.has('tagstart')
      call                  ff.if('exists(''%startedtag'')')
      call                      ff.unlet('%startedtag')
      call                  ff.endif()
    endif
    "▶5 Processing EOL
    if has_key(opts.listchars, 'eol') || !empty(opts.matchespasteol)
      if !empty(opts.matchespasteol)
        call            ff.if('has_key(%opts.matchespasteol,%clnr)')
        call                ff.leta('%savedmatchhlname', '%matchhlname')
        call                ff.leta('%matchhlname', '%opts.matchespasteol[%clnr]')
        if has_key(opts.listchars, 'eol')
          call          ff.endif()
        else
          call          ff.letabreak()
        endif
      endif
      let               eolhlnamestr=linehlnamestrorig
      let               eolhlnamestr=substitute(eolhlnamestr,
                  \                                 '''Normal''',string(opts.highlight.NonText),'g')
      if opts.dolinemergehl
        let             eolhlnamestr='(len(%linehlname)>1?%linehlname :'.eolhlnamestr.')'
      endif
      if opts.domatches
        let             eolhlnamestr='(%matchhlname is 0'.
                    \                       '?'.eolhlnamestr.
                    \                       ':[''Normal'',%matchhlname])'
      endif
      call                  ff.leta('%eolspec', cf.specstr(eolhlnamestr))
      call                  ff.appendc('line', s:F.squote(get(opts.listchars, 'eol', ' ')),
                  \                    '%eolspec', '%clnr', '%curcol+1')
      if !empty(opts.matchespasteol)
        if has_key(opts.listchars, 'eol')
          call          ff.if('exists(''%savedmatchhlname'')')
        endif
        call                ff.let('%matchhlname', '%savedmatchhlname')
        call                ff.unlet('%savedmatchhlname')
        call            ff.endif()
      endif
    endif
    call                ff.appendc('lineend', 0, '%linespec', '%clnr', '%curcol')
    "▲4
    "▶4 Rules
    " Order: colorcolumn > matches > diff > cursorline > signs > special > syntax
    " Rules:
    " (colorcolumn = colorcolumn and cursorcolumn)
    " (signs       = sign linehl)
    " (matches     = matches themselves and search)
    " (special     = highlighting of special characters defined by listchars (nbsp, tab, trail) and 
    "                non-printable characters highlighting)
    " (cancel      = fg, bg and other attributes are ignored)
    " (cleared     = after “hi clear …” or “hi link … Normal”)
    " - signs cancels special
    " - cursorline cancels signs and special
    " - matches cancel cursorline, signs and special
    " - colorcolumn does NOT cancel ANY highlighting
    " - If special is cancelled first character (applicable for tabs and non-printable characters, 
    "   otherwise read “all characters”) is highligted using syntax (if special is not cancelled 
    "   syntax is ignored)
    " - cleared diff cancels signs and cursorline and enables special
    " - cleared cursorline cancels signs and enables special
    " - cleared signs does not affect highlighting
    " - cleared matches does not affect highlighting
    " - cleared colorcolumn does not affect highlighting
    " - cleared diff makes match at the EOL extend past the EOL
    " - cursorline makes 'showbreak' characters underlined, but does not alter their highlighting
    "
    " Possible vim bugs:
    " - If special is cancelled first character (applicable for tabs and non-printable characters, 
    "   otherwise read “all characters”) is highligted using syntax (if special is not cancelled 
    "   syntax is ignored)
    "   (bug candidate is “first character” part)
    " - cleared diff makes match at the EOL extend past the EOL
    "
    " FIXME: When using search beware that Search linked to Normal group or with cleared 
    "        highlighting does not affect highlighting, while Search group with defined or linked to 
    "        a group with defined highlighting for one of fg/bg (but not both) merges with 
    "        underlying group.
    "        Search integration with other highlighting attributes needs more investigation.
    "▲4
    "▲3
    if !opts.ignorefolds && !opts.allfolds && !opts.foldcolumn
      call          ff.endif()
    endif
    call            ff.call('add(%r,%curstr)')
    call            ff.increment('%clnr')
    call        ff.endwhile()
    "▶2 Beginning and end
    if opts.allfolds
      call      ff.if('has_key(%possiblefolds,%clnr)')
      call          ff.let('%pf', '%possiblefolds[%clnr]')
      call          ff.if('has_key(%pf,''end'')')
      call              ff.increment('%r', '%pf.end')
      call          ff.endif()
      call      ff.endif()
    endif
    if !sbsd
      if cf.has('begin')
        call    ff.call('insert(%r,%cformat.begin.f(%normalspec,'''',%opts,%cf.stylestr,%cf))')
      endif
      if cf.has('end')
        call    ff.call('add(%r,%cformat.end.f(%normalspec,'.elnr.','''',%opts,%cf.stylestr,%cf))')
      endif
    endif
    call        ff.do('return '.cf.getvar('r'))
    "▲2
    let f   =    ['function d.compiledformat(cf, cformat, opts)']
                \   +ff._tolist(opts.minimizefunc)+
                \['endfunction']
    let d={}
    execute join(f, "\n")
    call cf.savefunc('compiledformat', f, d.compiledformat)
    call cf.writefunc()
    if opts.profiling || opts.debugging
      call add(s:profiled, d.compiledformat)
    endif
    "▶2 r
    let r=d.compiledformat(cf, cformat, opts)
    "▶2 s:progress
    if opts.showprogress && opts.canresize
      let s:progress.opts.showprogress=0
    endif
    "▶2 finish if sbsd is active
    if sbsd
      return r
    endif
    "▶2 cformat.nolf
    if cformat.nolf
      let r=[join(r, '')]
    endif
    "▶2 cformat.haslf
    if cformat.haslf
      let oldr=r
      let r=[]
      for item in oldr
        let r+=split(item, "\n", 1)
      endfor
    endif
    "▲2
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
        return 1
    endif
    return 0
endfunction
"▶1 cmd
let s:cmd={}
"▶2 s:cmd.@FWC
let s:filcomprefs=
            \              '           columns :=(-1)  |earg range -1 inf '.
            \              '?               to         path W '.
            \              '?      starttagreg :=(0)   isreg'.
            \              '?        endtagreg :=(0)   isreg'.
            \              '!           cursor :=(-1) '.
            \              '!           number :=(-1) '.
            \              '!   relativenumber :=(-1) '.
            \              '!             list :=(-1) '.
            \              '!+1           tags :=(-1)  in [local all] '.
            \              '!+1     foldcolumn :=(-2)  |earg range -1 inf '.
            \              '!            folds :=(-1) '.
            \              '!            signs :=(-1) '.
            \              '!+1      concealed :=(-1)  in [shown both] '.
            \              '!+1       progress :=(-1)  in [percent lines] '.
            \              '!+1        matches :=(-1)  in [search matches all] '
let s:filformats='[:*_f.getoption("DefaultFormat") key formats~start]'
let s:cmd['@FWC']=[
            \'-onlystrings _ _ '.
            \'<diffformat ('.s:filformats.'{'.s:filcomprefs.'}) '.
            \ '    format ('.s:filformats.'{'.s:filcomprefs.
            \              '!+1  collapsfiller :=(-1)  |earg range  0 inf '.
            \              '!         allfolds :=(-1) '.
            \             '}) '.
            \ '      list - '.
            \'>', 'filter']
unlet s:filformats s:filcomprefs
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
    endif
    "▲2
    return 0
endfunction
"▶1 cmd completion
let s:cmpcomprefs=                      'columns  in ["-1" "80" =string(&co) '.
            \                                        '=string(winwidth())] '.
            \                '?               to  path W '.
            \                '?      starttagreg _ '.
            \                '?        endtagreg _ '.
            \                '!           number '.
            \                '!   relativenumber '.
            \                '!             list '.
            \((has('diff'))?
            \               ('!             diff '                    ):('')).
            \                '!+1           tags  in [local all] '.
            \((has('folding'))?
            \               ('!+1     foldcolumn  _ '.
            \                '!            folds '                    ):('')).
            \((has('signs'))?
            \               ('!            signs'                     ):('')).
            \((has('conceal'))?
            \               ('!+1      concealed  in [shown both] '   ):('')).
            \((has('statusline'))?
            \               ('!+1       progress  in [percent lines] '):('')).
            \                '!+1        matches  in [all matches '.
            \                                        (has('extra_search')
            \                                           ?('search')
            \                                           :('')).']'
let s:cmpformats='[key formats]'
let s:cmdcomplete='<'.
            \((has('diff'))?
            \   ('diffformat ('.s:cmpformats.'{'.s:cmpcomprefs.'})'):
            \   ('')).
            \   '    format ('.s:cmpformats.'{'.s:cmpcomprefs.
            \           ((has('diff'))?(   '!+1  collapsfiller  _ '):('')).
            \           ((has('folding'))?('!         allfolds '   ):('')).'})'.
            \   '      list - '.
            \  '>'
"▶1 cmd definition
let s:_aufunctions.cmd=s:cmd
let s:_aufunctions.comp={
            \'function': s:_f.fwc.compile(s:cmdcomplete, 'complete')[0],
        \}
unlet s:cmd
unlet s:cmpformats s:cmpcomprefs
unlet s:cmdcomplete
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
            \        '(#exists not key formats) '.
            \        '(haskey line '.
            \         'dict {?in keylist  type string '.
            \                   'tagproc  isfunc 1 '.
            \                    'strlen  isfunc 1 '.
            \                'addoptsfun  isfunc 1 '.
            \                 'strescape  type string '.
            \                     'haslf  bool '.
            \                      'nolf  bool '.
            \                   'addopts  dict {/^[a-zA-Z0-9]\w*$/ _}'.
            \                     'state  dict {/^[a-zA-Z0-9]\w*$/ _}'.
            \                 'sbsdstate  dict {/^[a-zA-Z0-9]\w*$/ _}'.
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
call frawor#Lockvar(s:, 'formats,progress,profiled')
" vim: ft=vim:ts=8:fdm=marker:fenc=utf-8:fmr=▶,▲:tw=100
