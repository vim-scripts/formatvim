"{{{1 Начало
scriptencoding utf-8
if (exists("s:g._pluginloaded") && s:g._pluginloaded) ||
            \exists("g:formatOptions.DoNotLoad")
    finish
"{{{1 Первая загрузка
elseif !exists("s:g._pluginloaded")
    "{{{2 Объявление переменных
    execute load#Setup('2.3', 1, 1, 1)
    call map(["stuf", "mng", "comp", "fmt"], 'extend(s:F, {v:val : {}})')
    lockvar 1 s:F
    let s:g.fmt={"formats":{}}
    "{{{2 Словарные функции
    let s:g._load.dictfunctions=[
                \["format", "fmt.format", {
                \       "model": "prefixed",
                \       "required": [["keyof", s:g.fmt.formats]],
                \       "optional": [[["num", [0]], {}, 0],
                \                    [["num", [1]], {"trans": ["earg", ""]},
                \                     "line('$')"]],
                \       "prefoptional": {
                \           "columns":         [["num", [-1]],     {},  0],
                \           "collapsfiller":   [["num", [ 1]],     {}, -1],
                \           "foldcolumn":      [["num", [-1]],     {}, -2],
                \           "folds":           [["bool", ""],      {}, -1],
                \           "allfolds":        [["bool", ""],      {}, -1],
                \           "number":          [["bool", ""],      {}, -1],
                \           "relativenumber":  [["bool", ""],      {}, -1],
                \           "list":            [["bool", ""],      {}, -1],
                \           "tags":            [["in", ['all']],   {}, -1],
                \           "progress":        [["in", ['lines']], {}, -1],
                \           "concealed":       [["in", ['real']],  {}, -1],
                \       },
                \       "altpref": ["relativenumber", "number", "folds", "list",
                \                   "allfolds", "tags", "progress", "concealed",
                \                   "foldcolumn", "collapsfiller"],
                \   }
                \]
            \]
    "{{{2 Команды
    let s:g._load.commands={
                \"Command": {
                \      "nargs": '+',
                \       "func": "mng.main",
                \      "range": '%',
                \        "bar": "",
                \   "complete": "customlist,s:_complete",
                \},
            \}
    "{{{2 Функции
    let s:g._load.functions=[
                \["Add", "fmt.add", {
                \       "model": "simple",
                \       "required": [
                \           ["and", [["type", type("")],
                \                    ["not", ["keyof", s:g.fmt.formats]]]],
                \           ["type", type({})],
                \       ],
                \   }
                \],
                \["Delete", "fmt.del", {
                \       "model": "simple",
                \       "required": [["keyof", s:g.fmt.formats]],
                \   }
                \]
            \]
    let s:g.extfuncdicts={}
    call map(copy(s:g._load.functions),
                \'extend(s:g.extfuncdicts, {v:val[0]: v:val[2]})')
    "{{{2 Регистрация дополнения
    let s:g._load.requires=[["load", '0.0'],
                \           ["comp", '0.6'],
                \           ["chk",  '0.3'],
                \           ["stuf", '0.0']]
    let s:g._load.reginfo=s:F.plug.load.registerplugin(s:g._load)
    let s:F.main.eerror=s:g._load.reginfo.functions.eerror
    let s:F.main.option=s:g._load.reginfo.functions.option
    finish
endif
"{{{1 Вторая загрузка
let s:g._pluginloaded=1
unlet s:g._load
"{{{2 Настройки
let s:g.defaultOptions={
            \"DefaultFormat":    "html",
            \"KeepColorCache":    1,
            \"IgnoreCursor":      1,
            \"IgnoreFolds":       0,
            \"IgnoreList":        0,
            \"IgnoreTags":        1,
            \"AllFolds":          0,
            \"ShowProgress":      0,
            \"CollapsFiller":     0,
            \"NoLineNR":         -1,
            \"RelativeNumber":   -1,
            \"FoldColumn":       -1,
            \"MaxDupTags":        5,
            \"FormatConcealed":   1,
            \"AddTagCmdEscapes": '[]*.~',
            \"ColorFile":         0,
        \}
let s:g.chk={}
let s:g.chk.options={
            \"DefaultFormat":    ["keyof", s:g.fmt.formats],
            \"KeepColorCache":   ["bool", ""],
            \"IgnoreCursor":     ["bool", ""],
            \"IgnoreFolds":      ["bool", ""],
            \"IgnoreList":       ["bool", ""],
            \"IgnoreTags":       ["nums", [0, 2]],
            \"FormatConcealed":  ["nums", [0, 2]],
            \"AllFolds":         ["bool", ""],
            \"ShowProgress":     ["num", [0, 2]],
            \"CollapsFiller":    ["num", [0]],
            \"NoLineNR":         ["num", [-1, 1]],
            \"RelativeNumber":   ["num", [-1, 1]],
            \"FoldColumn":       ["num", [-1]],
            \"MaxDupTags":       ["num", [0]],
            \"AddTagCmdEscapes": ["type", type("")],
            \"ColorFile":        ["or", [["equal", 0],
            \                            ["file", "r"]]],
        \}
"{{{2 Выводимые сообщения
let s:g.p={
            \"emsg": {
            \   "misskey": "Required key is missing: %s",
            \   "synnsup": "I wonder, why do you need this plugin: ".
            \              "this vim is compiled without syntax support. ".
            \              "Plugin is unloading, do not try to reload it.",
            \   "misscol": "File with colors list not found, ".
            \              "see format-opt-ColorFile",
            \},
            \"etype": {
            \   "syntax": "SyntaxError",
            \    "iform": "InvalidFormat",
            \   "notimp": "NotImplemented",
            \     "badf": "BadFilename",
            \},
        \}
"{{{1 Вторая загрузка — функции
"{{{2 Внешние дополнения
let s:F.plug.stuf=s:F.plug.load.getfunctions("stuf")
let s:F.plug.comp=s:F.plug.load.getfunctions("comp")
let s:F.plug.chk =s:F.plug.load.getfunctions("chk")
"{{{2 stuf: strlen, htmlstrlen, bbstrlen
"{{{3 stuf.strlen
function s:F.stuf.strlen(str)
    return len(split(a:str, '\zs'))
endfunction
"{{{3 stuf.htmlstrlen
function s:F.stuf.htmlstrlen(str)
    let str=a:str
    let str=substitute(str, '\_\s\+', ' ', 'g')
    let str=substitute(str, '<.\{-}>', '', 'g')
    let str=substitute(str, '&[^;]\+;\|.', '.', 'g')
    return len(str)
endfunction
"{{{3 stuf.bbstrlen
function s:F.stuf.bbstrlen(str)
    let str=a:str
    let str=substitute(str, '\[.\{-}\]', '', 'g')
    let str=substitute(str, '&[^;]\+;\|.', '.', 'g')
    return len(str)
endfunction
"{{{2 main: eerror, destruct, option
"{{{3 main.destruct: выгрузить плагин
function s:F.main.destruct()
    call s:F.plug.comp.delcomp(s:g.comp._cname)
    unlet s:g
    unlet s:F
    return 1
endfunction
"{{{2 fmt: format, add, del
"{{{3 fmt.getexpr
"{{{4 s:g.fmt.colors
if has("gui_running")
    let s:g.fmt.whatterm = "gui"
    augroup FormatRedrawProgress
        autocmd!
        autocmd VimResized * call s:F.fmt.redrawprogress()
    augroup END
else
    let s:g.fmt.whatterm = "cterm"
    let s:g.fmt.colorfile=s:F.main.option("ColorFile")
    if type(s:g.fmt.colorfile)!=type("")
        let s:g.fmt.colorfile=fnamemodify(expand('<sfile>:h:h'), ':p')
        " According to the help, if file is a directory, fnamemodify will leave 
        " path separator at the end of the filename when invoked with `:p' 
        " modifier
        let s:g.fmt.pathseparator=s:g.fmt.colorfile[-1:]
        let s:g.fmt.colorfile.=
                    \join(['config', 'formatvim',
                    \      'colors-default-'.&t_Co.'.yaml'],
                    \      s:g.fmt.pathseparator)
        if !filereadable(s:g.fmt.colorfile)
            let s:g.fmt.colorfile.=
                        \join(['config', 'formatvim', 'colors-default.yaml'],
                        \      s:g.fmt.pathseparator)
        endif
    endif
    if !filereadable(s:g.fmt.colorfile)
        call s:F.main.eerror("<script>", "badf", ["misscol"])
    endif
    let s:g.fmt.colors=map(filter(readfile(s:g.fmt.colorfile, 'b'),
                \                 'v:val[:1]==#"- "'),
                \          'v:val[3:9]')
endif
"{{{4 s:g.fmt.expressions
let s:g.fmt.expressions={
            \"f": "@fgcolor@",
            \"b": "@bgcolor@",
            \"S": "@styleid@",
            \"N": "@-@",
            \"C": "@.@",
            \"s": "@@@",
            \":": "@:@",
        \}
"{{{4 s:g.fmt.complexexpressions
let s:g.fmt.complexexpressions={
            \'#': "'((@_donr@ || @_dornr@)?".
            \       "(repeat('.s:F.plug.stuf.squote(a:opts.leadingspace).', ".
            \               "@_linenumlen@-len(@@@)).@@@):".
            \       "(''''))'",
            \'-': "'repeat('.s:F.plug.stuf.squote(a:opts.difffillchar).', (".
            \             "(@_columns@)-(@=@))/'.".
            \             "a:opts.strlen(a:opts.difffillchar).')'",
            \'+': "'repeat('.s:F.plug.stuf.squote(a:opts.leadingspace).', (".
            \             "(@_columns@)-(@=@))/'.".
            \             "a:opts.strlen(a:opts.leadingspace).')'",
            \'_': "'((@_donr@ || @_dornr@)?".
            \       "(repeat('.s:F.plug.stuf.squote(a:opts.leadingspace).', ".
            \               "@_linenumlen@)):".
            \       "(''''))'",
            \' ': "s:F.plug.stuf.squote(a:opts.leadingspace)",
            \'^': "'((a:opts.donr || a:opts.dornr)?('.".
            \       "s:F.plug.stuf.squote(a:opts.leadingspace).'):".
            \       "(''''))'",
            \'~': "s:F.plug.stuf.squote(a:opts.difffillchar)",
        \}
"}}}4
function s:F.fmt.getexpr(str, opts)
    "{{{4 Простые выражения (%f, %b, %S, %N, %C, %s, %:)
    if has_key(s:g.fmt.expressions, a:str)
        return s:g.fmt.expressions[a:str]
    "{{{4 Сложные выражения (%#, %-, %_, %<SPACE>, %^, %~)
    elseif has_key(s:g.fmt.complexexpressions, a:str)
        return eval(s:g.fmt.complexexpressions[a:str])
    "{{{4 %={expr}=%
    elseif a:str=~'^='
        let str=a:str
        let str=substitute(str, "''", "'", 'g')
        let str=substitute(str, '\\\([\\%]\)', '\1', 'g')
        let str=substitute(str, '^=\|=%$', '', 'g')
        return str
    "{{{4 %'{expr}'%
    elseif a:str=~"^'"
        let str=a:str
        let str=substitute(str, "''", "'", 'g')
        let str=substitute(str, '^''\|''%$', '', 'g')
        return str
    "{{{4 %>{expr}
    elseif a:str=~"^>"
        let str=a:str
        let str=substitute(str, "''", "'", 'g')
        let str=substitute(str, '^>', '', '')
        return str
    "{{{4 %!{commands}!%
    elseif a:str=~'^!'
        let str=a:str
        let str=substitute(str, "''", "'", 'g')
        let str=substitute(str, '^!', "    ", '')
        let str=substitute(str, '!%$', "\n    return ''", '')
        return str
    "{{{4 %@
    elseif a:str==#'@'
        return "'%@'"
    "{{{4 Остальные %.
    else
        return "'".a:str."'"
    endif
endfunction
"{{{3 fmt.compile
" { {@key@}: [{where it is constant}] }
let s:g.fmt.args={
            \".": ["linestart", "linenr", "fold", "collapsedfiller",
            \      "begin", "end", "sbsdstart", "style"],
            \"-": ["begin", "style"],
            \"@": ["begin", "end", "sbsdstart", "sbsdsep", "sbsdend"],
        \}
function s:F.fmt.compile(Str, opts, key)
    "{{{4 Объявление переменных
    let requires=[]
    let args=[]
    let str=a:Str
    let noreturn=0
    if str[0:1]==#'%!'
        let noreturn=1
    endif
    let str=s:F.plug.stuf.squote(str)
    "{{{4 Замена %*
    let str=substitute(str,
                \'%\(=\([^\\%]\|\\.\)\+=%\|''.\{-}''%\|!.\{-}!%\|>.*\|.\)',
                \'\=substitute("''.".'.
                \       's:F.fmt.getexpr(submatch(1), a:opts).".''",'.
                \   '"^''\\.''\\|''\\.''$", "", "g")',
                \'g')
    let str=substitute(str, '\r', "\n", 'g')
    "{{{4 @@@:     a:str, исходная строка
    if index(s:g.fmt.args["@"], a:key)!=-1
        let str=substitute(str, '@@@', "''", 'g')
    else
        let str=substitute(str, '@@@',  '\=add(requires, "a:str")[-1]', 'g')
        call add(args, "str")
    endif
    "{{{4 Удаление лишних штрихов
    let str=substitute(str, "^''\\.\\|\\.''$", "", "g")
    "{{{4 @word@:  a:spec[0], спецификация; @~@
    let str=substitute(str, '@\([a-z]\+\)@',
                \'\="a:spec[0].".add(requires, submatch(1))[-1]', 'g')
    let str=substitute(str, '@\~@','\=add(requires, "a:spec[0]")[-1]', 'g')
    call add(args, "spec")
    "{{{4 @-@:     a:line, номер строки
    if index(s:g.fmt.args["-"], a:key)!=-1
        let str=substitute(str, '@-@', '0', 'g')
    else
        let str=substitute(str, '@-@', '\=add(requires, "a:line")[-1]', 'g')
        call add(args, "line")
    endif
    "{{{4 @.@:     a:char, номер текущего символа
    if index(s:g.fmt.args["."], a:key)!=-1
        let str=substitute(str, '@\.@', '0', 'g')
    else
        let str=substitute(str, '@\.@', '\=add(requires, "a:char")[-1]',   'g')
        call add(args, "char")
    endif
    "{{{4 @=@:       cur, длина строки
    if match(str, '@=@')!=-1
        call add(requires, '=')
        let str=substitute(str, '\(^\|''\@<=\.\)'.
                    \               '\(\(\(''\.\)\@!.\)*\)@=@',
                    \'\n    '.
                    \'let str.=\2a:opts.strlen(a:cur.str)',
                    \'g')
        let str=substitute('let str='.str, '^let str=\ze\n',
                    \'let str=""', '')
        let str.="\n    return str"
    else
        if !noreturn
            let str='return '.str
        endif
    endif
    call add(args, "cur")
    "{{{4 @_word@: a:opts, настройка
    let str=substitute(str, '@_\([a-z]\+\)@',
                \'\="a:opts.".add(requires, "_".submatch(1))[-1][1:]', 'g')
    call add(args, "opts")
    "{{{4 Добавление стиля в список аргмунетов
    if a:key==#"begin" || a:key==#"end"
        call add(args, "style")
    endif
    "{{{4 @?@:     a:concealed, скрытый символ; @&word@, @^@ и @&@
    if a:key==#"concealed"
        let str=substitute(str, '@?@', '\=add(requires, "a:concealed")[-1]','g')
        let str=substitute(str, '@&\([a-z]\+\)@',
                    \'\="a:cspec[0].".add(requires, "&".submatch(1))[-1][1:]',
                    \'g')
        let str=substitute(str, '@&@', '\=add(requires, "a:cspec[1]")[-1]', 'g')
        let str=substitute(str, '@\^@','\=add(requires, "a:cspec[0]")[-1]', 'g')
        call add(args, "concealed")
        call add(args, "cspec")
    else
        let str=substitute(str, '@?@', "''", 'g')
        let str=substitute(str, '@&\([a-z]\)\+@',
                    \'\="a:spec[0].".add(requires, submatch(1))[-1]', 'g')
        let str=substitute(str, '@\^@','\=add(requires, "a:spec[0]")[-1]', 'g')
    endif
    "{{{4 @:@, @&@: a:spec[1] или a:style, стиль
    let str=substitute(str, '@[:&]@', '\=add(requires, "'.
                \((index(["begin", "end"], a:key)!=-1)?
                \   ("a:style"):
                \   ("a:spec[1]")).
                \'")[-1]',  'g')
    "{{{4 %%@, %@ → @
    let str=substitute(str, '%%@', '%@', 'g')
    let str=substitute(str,  '%@',  '@', 'g')
    "{{{4 Создание функции
    let r={}
    execute      "function r.r(".join(args, ", ").")\n".
                \'    '.str."\n".
                \'endfunction'
    return [r.r, requires]
endfunction
"{{{3 fmt.prepare
function s:F.fmt.prepare(format, startline, endline, options)
    let selfname="fmt.prepare"
    "{{{4 s:F.fmt.getcolor
    if !has_key(s:F.fmt, "getcolor")
        if s:g.fmt.whatterm==#"gui"
            function s:F.fmt.getcolor(color)
                return a:color
            endfunction
        else
            function s:F.fmt.getcolor(color)
                if a:color!~#'^\d\+$'
                    return ""
                endif
                return get(s:g.fmt.colors, a:color, "")
            endfunction
        endif
    endif
    "{{{4 opts
    let opts={}
    let opts.leadingspace=get(a:format, 'leadingspace', " ")
    let opts.difffillchar=get(a:format, 'difffillchar', "-")
    let opts.columns=
                \((a:options.columns+0)?
                \   (a:options.columns+0):
                \   (get(a:format, 'columns', winwidth(0))))
    let opts.strlen=get(a:format, 'strlen', s:F.stuf.strlen)
    let opts.linenumlen=len(a:endline)
    let id=hlID("normal")
    let opts.fgcolor=s:F.fmt.getcolor(synIDattr(id, "fg#", s:g.fmt.whatterm))
    let opts.bgcolor=s:F.fmt.getcolor(synIDattr(id, "bg#", s:g.fmt.whatterm))
    if opts.fgcolor==""
        let opts.fgcolor=((&background=="dark")?("#ffffff"):("#000000"))
    endif
    if opts.bgcolor==""
        let opts.bgcolor=((&background=="dark")?("#000000"):("#ffffff"))
    endif
    "{{{4 «Компиляция» некоторых ключей
    let cformat={}
    for key in  ["linestart", "line", "lineend", "begin", "end", "style",
                \"linenr", "fold", "difffiller", "collapsedfiller",
                \"foldstart", "foldend", "foldcolumn", "sbsdstart",
                \"sbsdsep", "sbsdend", "tagstart", "tagend", "concealed"]
        if has_key(a:format, key)
            let [cformat[key], cformat["r_".key]]=s:F.fmt.compile(a:format[key],
                        \                                         opts, key)
            lockvar! cformat[key]
            lockvar! cformat["r_".key]
        endif
    endfor
    "}}}4
    let cformat.opts=opts
    "{{{4 Блокировки
    lockvar! cformat.opts
    "}}}4
    return cformat
endfunction
"{{{3 s:g.fmt.formats
"{{{4 HTML
let s:g.fmt.escapehtml="substitute(".
            \           "substitute(".
            \            "substitute(".
            \             "substitute(".
            \              "substitute(@@@, '&', '&#38;', 'g'), ".
            \             "'\"', '\\&#34;', 'g'), ".
            \            "'<', '\\&#60;', 'g'), ".
            \           "'>', '\\&#62;', 'g'), ".
            \          "' ', '\\&nbsp;', 'g')"
let s:g.fmt.htmlstylestr='((@inverse@)?'.
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
let s:g.fmt.stylelist=["Line", "Fold", "DiffFiller", "CollapsedFiller"]
let s:g.fmt.formats.html={
            \"style":        '%>((@styleid@!=#"")?'.
            \                   '(".s".@styleid@." {".'.
            \                     s:g.fmt.htmlstylestr.
            \                   '."} "):'.
            \                   '(""))',
            \"begin":        "<html xmlns=\"http://www.w3.org/1999/xhtml\">".
            \                "<head>".
            \                "<meta http-equiv=\"content-type\" ".
            \                       "content=\"text/hmtl; charset=UTF-8\" />".
            \                '<meta name="generator" content="format.vim" />'.
            \                "<style type=\"text/css\"> ".
            \                "body { font-family: monospace; ".
            \                        "white-space: nowrap; ".
            \                        "margin: 0; padding: 0; border: 0;  ".
            \                        "color: %'@_fgcolor@'%; ".
            \                        "background-color: %'@_bgcolor@'% } ".
            \                "div { margin: 0; padding: 0; border: 0; ".
            \                      "color: %'@_fgcolor@'%; ".
            \                      "background-color: %'@_bgcolor@'% } ".
            \                ".open-fold   > .fulltext { display: block; }".
            \                ".closed-fold > .fulltext { display: none;  }".
            \                ".open-fold   > .toggle-open   {display: none; }".
            \                ".open-fold   > .toggle-closed {display: block;}".
            \                ".closed-fold > .toggle-open   {display: block;}".
            \                ".closed-fold > .toggle-closed {display: none; }".
            \                ".closed-fold:hover > .fulltext{display: block;}".
            \                ".closed-fold:hover > .toggle-filler ".
            \                                              "{display: none;}".
            \                ".Line { height: 1em; }".
            \                ".Present { display: none; }".
            \                ".Line:hover .Shown { display: none; }".
            \                ".Line:hover .Present { display: inline; }".
            \                ".s%'hlID('Conceal')'% { font-weight: normal; ".
            \                                        "font-style: normal; ".
            \                                        "text-decoration: none; ".
            \                                      "}".
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
            \                "%:</style>".
            \                '<title>%'''.substitute(s:g.fmt.escapehtml, '@@@',
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
            \"end":          '%''((@_sbsd@)?("</table>"):(""))''%'.
            \                '</body></html>',
            \"linestart":    '<div class="s%S %''s:g.fmt.stylelist[@@@]''%"'.
            \                  '%''((@@@<=1)?'.
            \                       '(" id=\"".'.
            \                        '((@@@==0)?'.
            \                            '("line"):'.
            \                            '("fold")).'.
            \                        '@-@."-".@_sbsd@."\""):'.
            \                       '(""))''%>',
            \"linenr":       '<span class="s%S LineNR">'.
            \                       '%''((@_foldcolumn@)?'.
            \                               '(@_leadingspace@):'.
            \                               '(""))''%%#% </span>',
            \"line":         '<span class="s%S">%'''.s:g.fmt.escapehtml.
            \                                           '''%</span>',
            \"concealed":    '<span class="Concealed">'.
            \                   '<span class="s%S Shown">%'''.
            \                                        s:g.fmt.escapehtml.
            \                                           '''%</span>'.
            \                   '<span class="s%=@&styleid@=% Present">%'''.
            \                       substitute(s:g.fmt.escapehtml, '@@@', '@?@',
            \                                  '').'''%</span>'.
            \                '</span>',
            \"lineend":      "</div>",
            \"tagstart":     "%!let tag=get(get(get(@_tags@, @@@, []), 0, ".
            \                                  "[]), 0, '')!%".
            \                "<a href=\"%'(".
            \                   "(type(tag)==".type('').")?(''):".
            \                       "(((type(tag)==".type([]).")?".
            \                           "(substitute(".
            \                               substitute(s:g.fmt.escapehtml,
            \                                          '@@@', "tag[0]", '').
            \                            ', "\"", "&#34;", "").'.
            \                            '"#line".tag[1]):'.
            \                           '("#line".tag))."-0"))'.
            \                "'%\">",
            \"tagend":       '</a>',
            \"foldcolumn":   '<span class="s%S FoldColumn">%'''.
            \                   'substitute(@@@, ">", "\\&gt;", "g")''%</span>',
            \"fold":         '<span class="s%S Text">%'''.
            \                       s:g.fmt.escapehtml.
            \                '''%</span>'.
            \                '<span class="FoldFiller">% %-</span>',
            \"difffiller":   '<span class="s%S DiffFiller">%-</span>',
            \"collapsedfiller": '<span class="s%S Text">'.
            \                       '%~ Deleted lines: %s %-'.
            \                   '</span>',
            \"leadingspace": "&nbsp;",
            \"foldstart":    '<div id="fold%N" class="closed-fold">'.
            \                   '<div class="toggle-open s%S" id="cf%N">'.
            \                   '<a href="javascript:toggleFold(''fold%N'')">'.
            \                       '%'''.s:g.fmt.escapehtml.'''%</a></div>'.
            \                '<div class="fulltext" '.
            \                   'onclick="toggleFold(''fold%N'')">',
            \"foldend":      "</div></div>",
            \"strlen":       s:F.stuf.htmlstrlen,
            \"sbsdstart":    '<tr class="SbSDLine" id="sbsd%N">'.
            \                '<td class="SbSD1">',
            \"sbsdsep":      '</td><td class="SbSDSep SbSDSep%C">|</td>'.
            \                '<td class="SbSD%C">',
            \"sbsdend":      '</td></tr>',
        \}
let s:g.fmt.styleattr="%'((@styleid@!=#\"\")?".
            \            "(' style=\"'.".s:g.fmt.htmlstylestr.".'\"'):".
            \            "(''))'%"
let s:g.fmt.formats["html-vimwiki"]={
            \"style":           s:g.fmt.styleattr,
            \"begin":           "<div style=\"font-family: monospace; %'".
            \                           s:g.fmt.htmlstylestr."'%\">",
            \"end":             "</div>",
            \"linestart":       "<div%:>",
            \"linenr":          "<span%:>%#% </span>",
            \"foldcolumn":      "<span%:>%'".
            \                       "substitute(@@@, '>', '\\&gt;', 'g')'%".
            \                   "</span>",
            \"lineend":         "</div>",
            \"fold":            "<span%:>%'".s:g.fmt.escapehtml."'%% %-</span>",
            \"difffiller":      "<span%:>%-</span>",
            \"collapsedfiller": "<span%:>%~ Deleted lines: %s %-</span>",
            \"leadingspace":    "&nbsp;",
            \"strlen":          s:F.stuf.htmlstrlen,
            \"line":            "<span%:>%'".s:g.fmt.escapehtml."'%</span>",
        \}
"{{{4 BBcode (unixforum)
let s:g.fmt.bbufostylestart=
            \'((@inverse@)?'.
            \   '((@bgcolor@!=#"")?("[color=".@bgcolor@):("")):'.
            \   '("[color=".((@fgcolor@!=#"")?(@fgcolor@):(@_fgcolor@))))."]".'.
            \'((@bold@)?("[b]"):("")).((@italic@)?("[i]"):(""))'
let s:g.fmt.bbufostyleend='((@italic@)?("[/i]"):("")).'.
            \'((@bold@)?("[/b]"):("")).'.
            \'(((@inverse@ && (@bgcolor@!=#"")) || (!@inverse@))?'.
            \   '("[/color]"):(""))'
let s:g.fmt.formats["bbcode-unixforum"]={
            \"begin":        '%>((&background==#"dark")?'.
            \                   '("[sh=".substitute(expand("%:p:~%"), ''[]'', '.
            \                   '''\="&#".char2nr(submatch(0)).";"'', "g")." '.
            \                   '(Created by format.vim)]"):'.
            \                   '("[codebox]"))',
            \"end":          '%>((&background==#"dark")?'.
            \                   '("[/sh]"):'.
            \                   '("[/codebox]"))',
            \"linenr":       '%>substitute(@:@, "%s", ''\='.
            \                           'repeat(@_leadingspace@, '.
            \                                     "@_linenumlen@-len(@-@)).".
            \                         '@-@.@_leadingspace@'', "")',
            \"line":         '%>substitute(@:@, "%s", ''\='.
            \                   'substitute('.
            \                    'substitute('.
            \                     'substitute(@@@, "&", "\\&#38;", "g"), '.
            \                     '"\\[", "\\&#91;", "g"), '.
            \                    '"\\]", "\\&#93;", "g")'', "")',
            \"leadingspace": " ",
            \"strlen":       s:F.stuf.bbstrlen,
            \"style":        "%>"  .  s:g.fmt.bbufostylestart.
            \                '."%s".'.s:g.fmt.bbufostyleend,
            \"sbsdsep":      "%+|",
            \"difffiller":   "%-",
            \"columns":      -1,
        \}
"{{{4 LaTeX (xcolor)
let s:g.fmt.texescape=
            \'substitute('.
            \   'substitute(@@@, ''[\\\[\]{}&$_\^%#]'', '.
            \              '''\=''''\char''''.char2nr(submatch(0))."{}"'', '.
            \              '"g"),'.
            \'" ", ''\\enskip{}'', "g")'
let s:g.fmt.texstylestart=
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
let s:g.fmt.texstyleend=
            \'repeat("}", '.
            \   '((@inverse@)?'.
            \       '(2):'.
            \       '((@bgcolor@!=#"")+1)))'
let s:g.fmt.formats["latex-xcolor"]={
            \"begin":        '\documentclass[a4paper,12pt]{article}'.
            \                '\usepackage[utf8]{inputenc}'.
            \                '\usepackage[HTML]{xcolor}'.
            \                '\pagecolor[HTML]{%''toupper(@_bgcolor@[1:])''%}'.
            \                '\color[HTML]{%''toupper(@_fgcolor@[1:])''%}'.
            \                '\begin{document}\ttfamily',
            \"linestart":    '\noindent ',
            \"line":         '%>'.s:g.fmt.texstylestart.".".
            \                     s:g.fmt.texescape.".".
            \                     s:g.fmt.texstyleend,
            \"lineend":      '\par',
            \"end":          '\end{document}',
            \"leadingspace": '\enskip{}',
        \}
"{{{4 tokens
let s:g.fmt.linetypes=['lr', 'lf', 'ld', 'lc']
let s:g.fmt.formats.tokens={
            \"begin":           "%>string(['b', @~@, expand('%'), bufnr('%')])",
            \"sbsdstart":       "['ss', ",
            \"foldstart":       "['fs', %:, %'string(@@@)'%, %C]",
            \"foldend":         "['fe', %:, %'string(@@@)'%, %C]",
            \"linestart":       "['%'s:g.fmt.linetypes[@@@]'%', %:, ",
            \"foldcolumn":      "['fc', %'string(@@@)'%, %:], ",
            \"linenr":          "['ln', %s,              %:], ",
            \"tagstart":        "['ts', %'string(@@@)'%], ",
            \"line":            "['l' , %'string(@@@)'%, %:], ",
            \"concealed":       "%'string(['c', @@@, @~@, @?@, @^@])'%, ",
            \"tagend":          "['te', %'string(@@@)'%], ",
            \"fold":            "['f' , %'string(@@@)'%, %:], ",
            \"difffiller":      "['df', '',              %:], ",
            \"collapsedfiller": "['cf', %'string(@@@)'%, %:], ",
            \"style":           "%>string(@~@)",
            \"lineend":         "]",
            \"sbsdsep":         ", ",
            \"sbsdend":         "]",
            \"end":             "%>string(['e', @~@, @_tags@])",
        \}
"{{{3 fmt.getspecdict
function s:F.fmt.getspecdict(id, ...)
    if type(a:id)==type([])
        let r=s:F.fmt.getspecdict(a:id[0])
        for id in a:id[1:]
            let r=call(s:F.fmt.mergespecdicts,
                        \[r, s:F.fmt.getspecdict(id)]+a:000, {})
        endfor
        return r
    endif
    return {
    \            "styleid": a:id,
    \            "fgcolor": s:F.fmt.getcolor(
    \                           synIDattr(a:id, 'fg#', s:g.fmt.whatterm)),
    \            "bgcolor": s:F.fmt.getcolor(
    \                           synIDattr(a:id, "bg#", s:g.fmt.whatterm)),
    \            "bold":        synIDattr(a:id, "bold"),
    \            "italic":      synIDattr(a:id, "italic"),
    \            "underline":   synIDattr(a:id, "underline"),
    \            "inverse":     synIDattr(a:id, "inverse"),
    \}
endfunction
"{{{3 fmt.mergespecdicts
let s:g.fmt.mergeactions={
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
lockvar! s:g.fmt.mergeactions
function s:F.fmt.mergespecdicts(oldspecdict, newspecdict, ...)
    let r={}
    for [key, expr] in items(s:g.fmt.mergeactions)
        let r[key]=eval(expr)
    endfor
    return r
endfunction
"{{{3 fmt.hasreq
function s:F.fmt.hasreq(cformat, key, reqs)
    for req in a:cformat["r_".a:key]
        if index(a:reqs, req)!=-1
            return 1
        endif
    endfor
    return 0
endfunction
"{{{3 fmt.redrawprogress
function s:F.fmt.redrawprogress()
    if !has_key(cformat, "frunning") || !s:g.fmt.progress.showprogress
        return 0
    endif
    let barlen=((winwidth(0))-
                \((s:g.fmt.progress.showprogress==2)?
                \    ((opts.linenumlen)*2+10):
                \    (8)))
    let colnum=barlen*s:g.fmt.progress.linesprocessed/
                \     s:g.fmt.progress.linestoprocess
    let s:g.fmt.progress.oldcolnum=0
    let bar="[".repeat("=", s:g.fmt.progress.oldcolnum).">".
                \repeat(" ", barlen-s:g.fmt.progress.oldcolnum)."] ".
                \((s:g.fmt.progress.showprogress==2)?
                \   (repeat(" ", len(s:g.fmt.progress.endline)-
                \                len(s:g.fmt.progress.curline)).
                \    (s:g.fmt.progress.curline).
                \    "/".(s:g.fmt.progress.endline)." "):
                \   ("")).
                \repeat(" ", 3-len(s:g.fmt.progress.progress)).
                \(s:g.fmt.progress.progress)."%%"
endfunction
"{{{3 fmt.tags
function s:F.fmt.tags(ignoretags)
    "{{{4 Объявление переменных
    if a:ignoretags==2
        return []
    endif
    let fname=expand('%:.') " Имя обрабатываемого файла
    let tags=taglist('.')   " Список тёгов
    let r={}                " Результат
    let fcontents={}        " Кэш содержимого файлов
    " Список символов, которых надо дополнительно экранировать
    let addescapes=s:F.main.option("AddTagCmdEscapes")
    "{{{4 Обработка тёгов (основной цикл)
    for tag in tags
        "{{{5 Объявление переменных
        " Имя файла, содержащего определение
        let tfname=fnamemodify(tag.filename, ':.')
        " Перепенная, определяющая, не совпадает ли файл с тёгом с данным
        let incurf=(tfname==#fname)
        if a:ignoretags && !incurf
            continue
        endif
        if !has_key(r, tag.name)
            let r[tag.name]=[]
        endif
        call add(r[tag.name], [tag])
        "{{{5 Тёг находится в текущем файле
        if incurf
            if tag.cmd[0]==#'/'
                try
                    let linenr=search(
                                \escape(
                                \   substitute(tag.cmd, '^/\|/$', '', 'g'),
                                \   addescapes), 'nw')
                    if linenr
                        call insert(r[tag.name][-1], linenr)
                    endif
                catch
                endtry
            else
                call insert(r[tag.name][-1], matchstr(tag.cmd, '^\d\+')+0)
            endif
            if len(r[tag.name][-1])==2
                if len(r[tag.name])>1
                    call insert(r[tag.name], remove(r[tag.name], -1))
                endif
            else
                call remove(r[tag.name], -1)
            endif
        "{{{5 Тёг находится в другом файле
        elseif filereadable(tfname)
            let linenr=0
            if tag.cmd[0]==#'/'
                if !has_key(fcontents, tfname)
                    let fcontents[tfname]=readfile(tfname, 'b')
                endif
                let fc=fcontents[tfname]
                let pattern=escape(substitute(tag.cmd, '^/\|/$', '', 'g'),
                            \      addescapes)
                let linenr=1
                let found=0
                try
                    for line in fc
                        if line=~#pattern
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
                let linenr=matchstr(tag.cmd, '^\d\+')+0
            endif
            if linenr
                call insert(r[tag.name][-1], [tfname, linenr])
            else
                call remove(r[tag.name], -1)
            endif
        "{{{5 Файл, в котором должен находится тёг, не существует
        else
            call remove(r[tag.name], -1)
        endif
    endfor
    "{{{4 Удаление лишних записей
    call filter(r, '!empty(v:val)')
    let maxduptags=s:F.main.option("MaxDupTags")
    if maxduptags
        call filter(r, 'type(get(v:val, '.maxduptags.', 0))=='.type(0))
    endif
    return r
endfunction
"{{{3 fmt.format
"{{{4 s:g.chk.format
let s:g.chk.format=[
            \["and", [["haskey", "line"],
            \         ["dict", [[["in", ["linestart", "line", "lineend",
            \                            "begin", "end", "difffiller",
            \                            "leadingspace", "fold", "linenr",
            \                            "foldstart", "foldend", "sbsdstart",
            \                            "sbsdsep", "sbsdend", "tagstart",
            \                            "tagend", "concealed"]],
            \                    ["type", type("")]],
            \                   [["equal", "strlen"], ["isfunc",0]],
            \                   [["equal", "columns"], ["num", -1]],
            \                   [["equal", "haslf"],  ["bool",  1]],
            \                   [["equal", "nolf"],   ["bool",  1]]]]]],
        \]
let s:g.extfuncdicts.Add.required[1]=s:g.chk.format
"{{{4 s:g.fmt
let s:g.fmt.compiled={}
let s:g.fmt.progress={}
let s:g.fmt.notpersistentdf=["a:line", "a:char", "="]
let s:g.fmt.notpersistentfdc=["a:line"]
let s:g.fmt.npsbsdstart=["a:line"]
"}}}4
function s:F.fmt.format(type, startline, endline, options, ...)
    "{{{4 Объявление переменных
    let oldmagic=&magic
    set magic
    let [startline, endline]=sort([a:startline, a:endline])
    if startline<1
        let startline=1
        if endline<1
            let endline=1
        endif
    endif
let formatfunction=["function s:F.fmt.compiledformat()"]
    "{{{5 cformat, opts
    let quotedtype=s:F.plug.stuf.squote(a:type)
    call extend(formatfunction, [
    \"let cformat=s:g.fmt.compiled[".quotedtype."]",
    \"let opts=cformat.opts",])
    if has_key(s:g.fmt.compiled, a:type)
        let cformat=s:g.fmt.compiled[a:type]
        call add(formatfunction,
        \"let opts.linenumlen=".len(endline))
    else
        let cformat=s:F.fmt.prepare(s:g.fmt.formats[a:type], startline,
                    \                                          endline,
                    \               a:options)
        let s:g.fmt.compiled[a:type]=cformat
        " Здесь содержится список определённых стилей
        let cformat.cache={}
        " Строка, в которой содержатся сами стили
        let cformat.stylestr=""
    endif
    "{{{5 Убеждаемся, что ранее запущенное форматирование завершилось успешно
    " Если нет, то мы не можем полагаться на кэш
    let sbsd=((a:000==[])?(0):(a:000[0]))
    if sbsd<=1 && has_key(cformat, "frunning")
        unlet cformat.frunning
        let cformat.cache={}
        let cformat.stylestr=""
        if has_key(s:F.fmt, "compiledformat")
            unlet s:F.fmt.compiledformat
        endif
        if has_key(s:F.fmt, "compiledspec")
            unlet s:F.fmt.compiledspec
        endif
    endif
    let cformat.frunning=1
    "}}}5
    let opts=cformat.opts
    unlockvar! opts
    "{{{5 opts.columns
    let columns=0+(((a:options.columns)+0)?
                \       (a:options.columns):
                \       (get(s:g.fmt.formats[a:type], 'columns', winwidth(0))))
    if columns==-1
        let columns=max(map(getline(1, line('$')), 's:F.stuf.strlen(v:val)'))
    endif
    let opts.columns=columns
    call add(formatfunction,
    \"let opts.columns=".columns)
    "}}}5
    let opts.sbsd=sbsd
    call add(formatfunction, 'let opts.sbsd='.sbsd)
    "{{{5 Складки
    " Складки игнорируются, если истинна настройка «IgnoreFolds», отсутствует 
    " ключ «fold» или Vim собран без поддержки складок
    let ignorefolds=((a:options.folds==-1)?
                \       (s:F.main.option("IgnoreFolds")):
                \       (!a:options.folds)) ||
                \!has("folding")
    let allfolds=!(ignorefolds || sbsd) &&
                \((a:options.allfolds==-1)?
                \       (s:F.main.option("AllFolds")):
                \       (a:options.allfolds)) &&
                \(has_key(cformat, "foldstart") ||
                \ has_key(cformat, "foldend"))
    let foldcolumn=0
    if !ignorefolds && has_key(cformat, "foldcolumn")
        let foldcolumn=((a:options.foldcolumn==-2)?
                \           (s:F.main.option("FoldColumn")):
                \           (a:options.foldcolumn))
        if foldcolumn==-1
            let foldcolumn=&foldcolumn
        endif
    endif
    let ignorefolds=ignorefolds || !has_key(cformat, "fold")
    call add(formatfunction, "let opts.ignorefolds=".ignorefolds)
    call add(formatfunction, "let opts.allfolds=".allfolds)
    call add(formatfunction, "let opts.foldcolumn=".foldcolumn)
    "}}}5
    let npregex='\t\|\p\@!.'
    " Список строк с возвращаемыми значениями
    call add(formatfunction, "let r=[]")
    " Номер преобразовываемой линии
    call add(formatfunction, "let curline=".startline)
    "{{{5 «Скрытые» символы
    let formatconcealed=0
    if has("conceal") && &conceallevel
        if a:options.concealed is -1
            let formatconcealed=s:F.main.option("FormatConcealed")
        elseif a:options.concealed is 'real'
            let formatconcealed=2
        else
            let formatconcealed=a:options.concealed
        endif
    endif
    if formatconcealed==2 && !has_key(cformat, "concealed")
        let formatconcealed=1
    endif
    let opts.formatconcealed=formatconcealed
    call add(formatfunction, 'let opts.formatconcealed='.formatconcealed)
    "{{{5 Курсор
    let ignorecursor=s:F.main.option("IgnoreCursor")
    "{{{5 Форматы
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
    call extend(formatfunction, [
    \'let normalspec  = s:F.fmt.compiledspec(cformat, "Normal")',
    \'let specialspec = s:F.fmt.compiledspec(cformat, "SpecialKey")',
    \'let ntspec      = s:F.fmt.compiledspec(cformat, "NonText")',
    \])
    let speciallines={}
    let specialcolumns={}
    "{{{6 Курсор
    let docline=0
    let cline=line('.')
    if !ignorecursor
        let ccolumn=virtcol('.')
        if &cursorcolumn
            call add(formatfunction,
            \'let ccspec=s:F.fmt.compiledspec(cformat, "CursorColumn")')
            let specialcolumns[ccolumn]=[1]
        endif
        if startline<=cline && cline<=endline
            if &cursorline
                let docline=1
                call add(formatfunction,
                \'let clspec=s:F.fmt.compiledspec(cformat, "Normal", '.
                \                                '"CursorLine")')
            endif
            " guicursor is ignored in cterm
            if 0 && s:g.fmt.whatterm==#"gui"
                let icstr=matchstr(&guicursor,
                            \'\(\%(,\|^\)'.
                            \   '[a-z\-]*[a-z]\@<!'.
                            \       'i'.
                            \   '[a-z]\@![a-z\-]*:\)\@<='.
                            \'[^,]*')
                let icstr=substitute(icstr,
                            \'\(^\|-\)\@<='.
                            \   'blink\%(wait\|on\|off\)\d\+'.
                            \'\(-\|$\)\@=', '', 'g')
                let ctype=matchstr(icstr,
                            \'\(^\|-\)\@<='.
                            \   '\(\(hor\|ver\)\d\+\|block\)'.
                            \'\(-\|$\)\@=')
                call add(formatfunction,
                \'let cspec=s:F.fmt.compiledspec(cformat, "Cursor")')
            else
                let ctype="block"
            endif
            let speciallines[cline]={ ccolumn : [0] }
        elseif !&cursorcolumn
            let ignorecursor=1
        endif
    endif
    "{{{6 Функция «fmt.compiledspec»
    let specfunction=[
\"function s:F.fmt.compiledspec(cformat, hlname".
\                               ((&diff || docline)?(", ..."):("")).")",
    \"let id=hlID(a:hlname)",]
    if &diff || docline
        call extend(specfunction, [
        \"if len(a:000)",
        \"    let addids=map(copy(a:000), 'hlID(v:val)')",
        \"    let tmpid=[id]+addids",
        \"    unlet id",
        \"    let id=tmpid",
        \"    let name=join(id, '_')",
        \"else",
        \"    let name=id",
        \"endif",
        \])
    else
        call add(specfunction, "let name=id")
    endif
    call extend(specfunction, [
    \"if has_key(a:cformat.cache, name)",
    \"    return a:cformat.cache[name]",
    \"endif",
    \((docline)?
    \   ("let r=[call(s:F.fmt.getspecdict, ".
    \           "[id]+((a:hlname==#'LineNR')?([0]):([])), {}), '']"):
    \   ("let r=[s:F.fmt.getspecdict(id), '']")),
    \])
    if has_key(cformat, "style")
        call add(specfunction,
        \'let r[1]=a:cformat.style(id, r, "", a:cformat.opts)')
        if index(cformat.r_begin+cformat.r_end, "a:style")!=-1
            call add(specfunction, 'let a:cformat.stylestr.=r[1]')
        endif
    endif
    call extend(specfunction, [
    \'let a:cformat.cache[name]=r',
    \'return r',
\'endfunction'])
    execute join(specfunction, "\n")
    call add(formatfunction, "let opts.ignorecursor=".ignorecursor)
    if foldcolumn
        call add(formatfunction,
        \'let fcspec  = s:F.fmt.compiledspec(cformat, "FoldColumn")')
    endif
    if !ignorefolds || allfolds
        call add(formatfunction,
        \'let foldspec=s:F.fmt.compiledspec(cformat, "Folded")')
    endif
    let donr=0
    let dornr=0
    if has_key(cformat, "linenr")
        let donr=((a:options.number==-1)?
                    \(s:F.main.option("NoLineNR")):
                    \(!a:options.number))
        if donr!=-1
            let donr=!donr
        endif
        let dornr=((a:options.relativenumber==-1)?
                    \(s:F.main.option("RelativeNumber")):
                    \(a:options.relativenumber))
        if dornr==-1
            if exists("&relativenumber")
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
            \'let nrspec=s:F.fmt.compiledspec(cformat, "LineNr")')
            if docline
                call add(formatfunction,
                \'let nrclspec=s:F.fmt.compiledspec(cformat, "LineNR", '.
                \                                  '"CursorLine")')
            endif
        endif
        if dornr
            let donr=0
        endif
    endif
    let opts.donr=donr
    call add(formatfunction, "let opts.donr=".donr)
    let opts.dornr=dornr
    call add(formatfunction, "let opts.dornr=".dornr)
    if &diff
        call add(formatfunction,
        \'let fillspec=s:F.fmt.compiledspec(cformat, "DiffDelete")')
    endif
    "{{{5 side-by-side diff
    if sbsd==1
        "{{{6 Используемые буфера
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
        "{{{6 Получение реальных номеров линий в текущем буфере
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
        "{{{6
        call insert(dwinnrs, curwin)
        for dwinnr in dwinnrs
            if getwinvar(curwin, '&foldmethod')!=#"diff" ||
                        \getwinvar(dwinnr, '&foldmethod')!=#"diff"
                let a:options.ignorefolds=1
                let ignorefolds=1
            endif
        endfor
        let r=[]
        let i=2
        let width=0
        let Curcompiledspec=s:F.fmt.compiledspec
        for dwinnr in dwinnrs
            "{{{6 Получение номеров линий в другом буфере
            execute dwinnr."wincmd w"
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
            "{{{6 Получение отформатированных текстов
            let a:options.allfolds=0
            let a:options.collapsfiller=0
            let s:F.fmt.compiledspec=Curcompiledspec
            let normalspec=s:F.fmt.compiledspec(cformat, "Normal")
            unlet s:F.fmt.compiledspec
            if !ignorefolds
                normal! zM
            endif
            let r2=s:F.fmt.format(a:type, dstartline, dendline, a:options, i)
            "{{{6 Добавление sbsdstart или sbsdsep
            let oldcolumns=opts.columns
            let opts.columns=width
            let width+=oldcolumns+1
            let opts.sbsd=sbsd
            if empty(r)
                let r=r2
                if has_key(cformat, "sbsdstart")
                    call map(r, 'cformat.sbsdstart(normalspec, v:key, "", '.
                                \                 'opts).v:val')
                endif
            else
                let r2=r2[(dstartinfiller):(len(r)-1+dstartinfiller)]
                if has_key(cformat, "sbsdsep")
                    call map(r, 'v:val.'.
                                \'cformat.sbsdsep(normalspec, v:key, i-1, '.
                                \                'v:val, opts).r2[v:key]')
                endif
            endif
            let i+=1
        endfor
        "{{{6 Добавление sbsdend
        let opts.columns=width-1
        execute curwin."wincmd w"
        let opts.sbsd=sbsd
        if has_key(cformat, "sbsdend")
            call map(r, 'v:val.'.
                        \'cformat.sbsdend(normalspec, v:key, '.
                        \                 len(dwinnrs).', v:val, opts)')
        endif
        "{{{6 Начало и конец представления
        if has_key(cformat, "begin")
            call insert(r, cformat.begin(normalspec, "", opts,
                        \                cformat.stylestr))
        endif
        if has_key(cformat, "end")
            call add(r, cformat.end(normalspec, endline, "", opts,
                        \           cformat.stylestr))
        endif
        "{{{6 nolf/haslf
        if has_key(cformat, "nolf") && cformat.nolf
            let r=[join(r, "")]
        endif
        if has_key(cformat, "haslf") && cformat.haslf
            let oldr=r
            let r=[]
            for item in oldr
                let r+=split(item, "\n")
            endfor
        endif
        "}}}6
        return r
    endif
    "{{{5 Тёги
    let ignoretags=2
    if has_key(cformat, 'tagstart') || has_key(cformat, 'tagend')
        if a:options.tags is -1
            let ignoretags=s:F.main.option("IgnoreTags")
        elseif a:options.tags is 'all'
            let ignoretags=0
        else
            let ignoretags=(2-a:options.ignoretags)
        endif
    endif
    if ignoretags!=2
        let opts.tags=s:F.fmt.tags(ignoretags)
        let tagregex=join(map(reverse(sort(keys(opts.tags))),
                    \         's:F.plug.stuf.regescape(v:val)'), '\|')
    else
        let opts.tags={}
        let tagregex=""
    endif
    "{{{5 Progress bar
    let showprogress=0
    if has("statusline")
        if a:options.progress is -1
            let showprogress=s:F.main.option("ShowProgress")
        elseif a:options.progress is 'lines'
            let showprogress=2
        else
            let showprogress=a:options.progress
        endif
    endif
    let s:g.fmt.progress.showprogress=showprogress
    if showprogress
        " Сохранённое значения настройки 'statusline'
        let oldstatusline=getwinvar(0, "&statusline")
        let oldlaststatus=&laststatus " Сохранённое значение 'laststatus'
        set laststatus=2
        call extend(formatfunction, [
        \"let oldprogress=0",
        \'let linesprocessed=0',
        \'let linestoprocess='.(endline-startline+1),
        \])
        if s:g.fmt.whatterm==#"cterm"
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
            \"let oldcolnum=0",
            \"let barstart=\"[\"",
            \"let barlen=".barlen,
            \'let barend=repeat(" ", barlen)."] "',
            \])
        else
            let canresize=1
            let s:g.fmt.progress.oldcolnum=0
            let s:g.fmt.progress.curline=startline
            let s:g.fmt.progress.progress=0
            let s:g.fmt.progress.endline=endline
            let s:g.fmt.progress.linesprocessed=0
            let s:g.fmt.progress.linestoprocess=(endline-startline+1)
        endif
    endif
    "{{{5 Удалённая строка: предсоздание, если возможно
    if &diff
        let persistentfiller=0
        let collapsafter=((a:options.collapsfiller==-1)?
                    \       (s:F.main.option("CollapsFiller")):
                    \       (a:options.collapsfiller))
        if !has_key(cformat, 'difffiller') &&
                    \has_key(cformat, 'collapsedfiller')
            let collapsafter=1
        endif
        if collapsafter && has_key(cformat, "collapsedfiller")
            let persistentfiller=0
        elseif has_key(cformat, "difffiller")
            let collapsafter=0
            let persistentfiller=!s:F.fmt.hasreq(cformat, "difffiller",
                        \                        s:g.fmt.notpersistentdf)
            if persistentfiller
                let fillspec=s:F.fmt.compiledspec(cformat, "DiffDelete")
                let fillerstr=cformat.difffiller(opts.difffillchar, fillspec, 0,
                            \                    0, "", opts)
            endif
        else
            let persistentfiller=1
            let fillerstr=""
        endif
    endif
    "{{{5 listchars: отображение некоторых символов в соответствии с 'listchars'
    let listchars={}
    if &list && !((a:options.list)?
                \   (s:F.main.option("IgnoreList")):
                \   (!a:options.list))
        let lcs=split(&listchars,
                    \',\ze\(eol\|tab\|trail\|extends\|precedes\|nbsp\):')
        for lc in lcs
            let [o, v]=matchlist(lc, '^\(\w*\):\(.*\)$')[1:2]
            let listchars[o]=map(split(v, '\zs'), 'escape(v:val, "&\\")')
            if o==#"nbsp"
                let npregex='\t\| \|\p\@!.'
            endif
        endfor
    endif
    let npregex=s:F.plug.stuf.squote(npregex)
    "{{{4 Складки
    if allfolds || foldcolumn
        "{{{5 Объявление переменных
        let persistentfdc=!s:F.fmt.hasreq(cformat, "foldcolumn",
                    \                     s:g.fmt.notpersistentfdc)
        call add(formatfunction,
        \"let fcurline=".startline)
        "{{{5 Сохранение старых значений
        let oldfoldminlines=getwinvar(0, '&foldminlines')
        call setwinvar(0, '&foldminlines', 0)
        "{{{5 Складки, закрытые в данный момент
        if !ignorefolds
            call extend(formatfunction, [
            \"let closedfolds={}",
            \"let closedfoldslist=[]",])
            if !allfolds
                call add(formatfunction, "let closedfoldsends=[]")
            endif
            call extend(formatfunction, [
            \"while fcurline<=".endline,
            \"    if foldclosed(fcurline)!=-1",
            \"        call add(closedfoldslist, fcurline)",
            \"        let closedfolds[fcurline]=".
            \               ((has_key(cformat, "linestart"))?
            \                    ("cformat.linestart(1, ".
            \                                 "foldspec, fcurline, '', ".
            \                                 "opts)"):
            \                    ('""'))])
            if !foldcolumn
                if donr || dornr
                    call add(formatfunction,
                    \'    let closedfolds[fcurline].=cformat.linenr('.
                    \                           ((dornr)?
                    \                               ('abs(fcurline-'.cline.')'):
                    \                               ('fcurline')).', '.
                    \                           'foldspec, '.
                    \                           'fcurline, '.
                    \                           'closedfolds[fcurline], '.
                    \                           'opts)')
                endif
                call add(formatfunction,
                \"        let closedfolds[fcurline].=".
                \               "cformat.fold(foldtextresult(fcurline), ".
                \                            "foldspec, fcurline, ".
                \                            "closedfolds[fcurline], ".
                \                            "opts)".
                \               ((has_key(cformat, "lineend"))?
                \                   ('.cformat.lineend(1, foldspec, fcurline,'.
                \                                   ' 0, "", opts)'):
                \                   ("")))
            endif
            if !allfolds
                call add(formatfunction,
                \"call add(closedfoldsends, foldclosedend(fcurline))")
                if showprogress
                    call add(formatfunction,
                    \'let linestoprocess-=(closedfoldsends[-1]-fcurline)')
                endif
                call add(formatfunction,
                \"let fcurline=closedfoldsends[-1]")
            endif
            call extend(formatfunction, [
            \"    endif",
            \"    let fcurline+=1",
            \"endwhile",])
        endif
        "{{{5 Остальные складки
        "{{{6 Объявление переменных: foldcolumn
        if foldcolumn
            call extend(formatfunction, [
            \"let foldlevel=-1",
            \"let fdchange=0",
            \"let foldlevels={}",
            \"let foldcolumns={}",])
            if !persistentfdc
                call extend(formatfunction, [
                \"let foldcolumnstarts={}",
                \"let foldcolumns[-1]=repeat(opts.leadingspace, ".
                \                           "opts.foldcolumn)",
                \])
            else
                call add(formatfunction,
                \"let foldcolumns[-1]=repeat([".
                \         'cformat.foldcolumn(repeat(opts.leadingspace,'.
                \                                   'opts.foldcolumn), '.
                \                            'fcspec, 0, '.
                \                            '-1, "", '.
                \                            'opts)], 3)')
            endif
        endif
        "{{{6 Объявление общих переменных
        call extend(formatfunction, [
        \"let possiblefolds={}",
        \"let &foldlevel=0",
        \"let oldfoldnumber=-1",
        \"let foldnumber=0",])
        "{{{6 Основной цикл: получение всех складок
        "{{{7 Начало цикла
        call extend(formatfunction, [
        \"while oldfoldnumber!=foldnumber",
        \"    let oldfoldnumber=foldnumber",
        \"    let fcurline=".startline,])
            "{{{7 foldcolumn
            if foldcolumn
                "{{{8 Получения текста
                call extend(formatfunction, [
                \"if &foldlevel>=".(foldcolumn-1),
                \"    let rangestart=&foldlevel-".(foldcolumn-3),
                \"    let rangeend=&foldlevel",
                \"    if rangestart<=rangeend",
                \"        if rangeend<10",
                \"            let fdctext=join(range(rangestart, ".
                \                                   "rangeend), '')",
                \"        elseif rangestart<10",
                \"            let fdctext=join(range(rangestart, 9),".
                \                             "'').".
                \                        "repeat('>', rangeend-9)",
                \"        else",
                \"            let fdctext=repeat('>', ".(foldcolumn-2).")",
                \"        endif",
                \"    else",
                \"        let fdctext=''",
                \"    endif",
                \"    let fdcnexttext=fdctext.((&foldlevel>=10)?".
                \                                   "('>'):".
                \                                   "((&foldlevel)?".
                \                                       "(&foldlevel+1):".
                \                                       "('|')))",
                \"    if &foldlevel>=".foldcolumn,
                \"        let fdcclosedtext=((rangestart<=10)?".
                \                               "(rangestart-1):".
                \                               "('>')).fdctext.'+'",
                \"    else",
                \"        let fdcclosedtext=repeat('|', ".(foldcolumn-1).").".
                \                                 "'+'",
                \"    endif",
                \"    let fdctextend=repeat(opts.leadingspace, ".
                \                          "opts.foldcolumn-1-len(fdctext))",
                \"else",
                \"    let fdctext=repeat('|', &foldlevel)",
                \"    let fdcnexttext=fdctext.'|'",
                \"    let fdctextend=repeat(opts.leadingspace, ".
                \                          "opts.foldcolumn-1-len(fdctext))",
                \"    let fdcclosedtext=fdctext.'+'.fdctextend",
                \"endif",
                \"let fdcnexttext.=fdctextend",
                \"let fdcopenedtext=fdctext.'-'.fdctextend",
                \])
                "{{{8 Создание колонки или сохранение текста
                if persistentfdc
                    call add(formatfunction,
                    \'let foldcolumns[&foldlevel]=['.
                    \         'cformat.foldcolumn(fdcclosedtext, '.
                    \                            'fcspec, 0, '.
                    \                            '&foldlevel, "", '.
                    \                            'opts), '.
                    \         'cformat.foldcolumn(fdcopenedtext, '.
                    \                            'fcspec, 0, '.
                    \                            '&foldlevel, "", '.
                    \                            'opts), '.
                    \         'cformat.foldcolumn(fdcnexttext, '.
                    \                            'fcspec, 0, '.
                    \                            '&foldlevel, "", '.
                    \                            'opts)]')
                else
                    call add(formatfunction,
                    \'let foldcolumns[&foldlevel]=fdcnexttext')
                endif
            endif
            "{{{7 Получения положения складок
            call extend(formatfunction, [
            \"while fcurline<=".endline,
            \"    if foldclosed(fcurline)>-1",])
                    "{{{8 Объявление переменных
                    call add(formatfunction,
                    \"let foldend=foldclosedend(fcurline)")
                    "{{{8 Получение foldstart и foldend
                    if allfolds
                        "{{{9 Объявление переменных
                        call add(formatfunction,
                        \"let foldtext=foldtextresult(fcurline)")
                        "{{{9 foldstart
                        if has_key(cformat, "foldstart")
                            call extend(formatfunction, [
                            \"if !has_key(possiblefolds, fcurline)",
                            \"    let possiblefolds[fcurline]={}",
                            \"endif",
                            \"if !has_key(possiblefolds[fcurline], 'start')",
                            \"    let possiblefolds[fcurline].start=[]",
                            \"endif",
                            \"call add(possiblefolds[fcurline].start, ".
                            \            "cformat.foldstart(foldtext, ".
                            \                              "foldspec, ".
                            \                              "fcurline, ".
                            \                              "&foldlevel, '', ".
                            \                              "opts))",
                            \])
                        endif
                        "{{{9 foldend
                        if has_key(cformat, "foldend")
                            call extend(formatfunction, [
                            \"let foldinsbefore=foldend+1",
                            \"if !has_key(possiblefolds, foldinsbefore)",
                            \"    let possiblefolds[foldinsbefore]={}",
                            \"endif",
                            \"if !has_key(possiblefolds[foldinsbefore], 'end')",
                            \"    let possiblefolds[foldinsbefore].end=[]",
                            \"endif",
                            \"call insert(possiblefolds[foldinsbefore].end, ".
                            \            "cformat.foldend(foldtext, foldspec, ".
                            \                            "foldend, ".
                            \                            "&foldlevel, '', ".
                            \                            "opts))"])
                        endif
                    endif
                    "{{{8 foldcolumn
                    if foldcolumn
                        "{{{9 foldlevels
                        call extend(formatfunction, [
                        \'let foldlevels[fcurline]=&foldlevel',
                        \'if !has_key(foldlevels, foldend+1)',
                        \'    let foldlevels[foldend+1]=&foldlevel-1',
                        \'endif',
                        \])
                        "{{{9 Получение foldcolumn,
                        " если она не была предсоздана
                        if !persistentfdc
                            if !ignorefolds
                                call extend(formatfunction, [
                                \'if has_key(closedfolds, fcurline)',
                                \'    let closedfolds[fcurline].='.
                                \           'cformat.foldcolumn('.
                                \                       'fdcclosedtext, '.
                                \                       'fcspec, fcurline, '.
                                \                       '&foldlevel, "", '.
                                \                       'opts)'.
                                \           ((dornr || donr)?(
                                \             '.cformat.linenr('.
                                \               ((dornr)?
                                \                   ('abs(fcurline-'.cline.')'):
                                \                   ('fcurline')).', '.
                                \               'foldspec, '.
                                \               'fcurline, '.
                                \               'closedfolds[fcurline], '.
                                \               'opts)'):('')),
                                \'    let closedfolds[fcurline].='.
                                \     'cformat.fold(foldtextresult(fcurline), '.
                                \                  'foldspec, fcurline, '.
                                \                  'closedfolds[fcurline], '.
                                \                  'opts)'.
                                \((has_key(cformat, "lineend"))?
                                \   ('.cformat.lineend(1, foldspec, fcurline,'.
                                \                    ' 0, "", opts)'):
                                \   ('')),
                                \'endif',
                                \])
                            endif
                            call add(formatfunction,
                            \'let foldcolumnstarts[fcurline]='.
                            \         'cformat.foldcolumn(fdcopenedtext, '.
                            \                          'fcspec, fcurline, '.
                            \                          '&foldlevel, "", opts)')
                        "{{{9 Получение foldcolumn для закрытой складки
                        elseif !ignorefolds
                            call extend(formatfunction, [
                            \'if has_key(closedfolds, fcurline)',
                            \'    let closedfolds[fcurline].='.
                            \               'foldcolumns[&foldlevel][0]'.
                            \               ((dornr || donr)?(
                            \                 '.cformat.linenr('.
                            \                   ((dornr)?
                            \                       ('abs(fcurline-'.cline.')'):
                            \                       ('fcurline')).', '.
                            \                   'foldspec, '.
                            \                   'fcurline, '.
                            \                   'closedfolds[fcurline], '.
                            \                   'opts)'):('')),
                            \'    let closedfolds[fcurline].='.
                            \         'cformat.fold(foldtextresult(fcurline), '.
                            \                      'foldspec, fcurline, '.
                            \                      'closedfolds[fcurline], '.
                            \                      'opts)'.
                            \         ((has_key(cformat, "lineend"))?
                            \           ('.cformat.lineend(1, foldspec, '.
                            \                             'fcurline, 0, "", '.
                            \                             'opts)'):
                            \           ('')),
                            \'endif',
                            \])
                        endif
                    endif
                    "{{{8 Завершение цикла
                    call extend(formatfunction, [
                    \"let fcurline=foldend",
                    \"let foldnumber+=1",
                \"endif",
                \"let fcurline+=1",
            \"endwhile",
            \"let &foldlevel+=1",
        \"endwhile",
        \])
    endif
    "{{{4 Основной цикл: создание указанного представления
    call extend(formatfunction, [
    \'while curline<='.(endline+((&diff)?(1):(0))),
        \'let curstr=""',])
        "{{{5 foldlevel
        if foldcolumn
            call extend(formatfunction, [
            \'if has_key(foldlevels, curline)',
            \'    let fdchange=foldlevel<=foldlevels[curline]',
            \'    let foldlevel=foldlevels[curline]',
            \'else',
            \'    let fdchange=0',
            \'endif',
            \])
        endif
        "{{{5 Progress bar
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
                \                   ('s:g.fmt.progress.'):
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
            \       ("")).
            \   'repeat(" ", 3-len(progress)).progress."%%"',
            \'call setwinvar(0, "&statusline", bar)',
            \'redrawstatus',])
            if showprogress!=2
                call add(formatfunction, 'endif')
            endif
            call extend(formatfunction, [
            \'let oldprogress=progress',
            \'let '.((canresize)?
            \                   ('s:g.fmt.progress.'):
            \                   ('')).'oldcolnum=colnum'])
            if canresize
                call extend(formatfunction, [
                \'let s:g.fmt.progress.progress=progress',
                \'let s:g.fmt.progress.linesprocessed=linesprocessed',
                \])
                if showprogress==2
                    call add(formatfunction,
                    \'let s:g.fmt.progress.curline=curline')
                endif
            endif
        endif
        "{{{5 Обработка удалённых строк
        " Если не включён режим разности, то никаких удалённых строк быть не 
        " может
        if &diff
            call extend(formatfunction, [
            \'let filler=diff_filler(curline)',
            \'if filler>0',
            \'    let curstrstart='.
            \           ((has_key(cformat, "linestart"))?
            \               ('cformat.linestart(2'.
            \                               ((collapsafter)?
            \                                   ('+(filler>='.collapsafter.')'):
            \                                   ('')).
            \                               ', fillspec, curline, "", '.
            \                               'opts)'):
            \               ('""')),])
                "{{{6 foldcolumn
                if foldcolumn
                    call add(formatfunction,
                    \'let curstrstart.='.
                    \   ((persistentfdc)?
                    \       ('foldcolumns[foldlevel][2]'):
                    \       ('cformat.foldcolumn(foldcolumns[foldlevel], '.
                    \                           'fcspec, curline, '.
                    \                           'foldlevel, curstrstart, '.
                    \                           'opts)')))
                endif
                "{{{6 Номер строки
                if donr || dornr
                    call add(formatfunction,
                    \'let curstrstart.=cformat.linenr("", nrspec, '.
                    \                                'curline, "", '.
                    \                                'opts)')
                endif
                "{{{6 Заполнитель
                if !persistentfiller
                    if collapsafter
                        call add(formatfunction, 'if filler<'.collapsafter)
                    endif
                    call extend(formatfunction, [
                    \'let curfil=filler',
                    \'while curfil',
                    \'    let curstr=curstrstart',
                    \'    let curstr.=cformat.difffiller(opts.difffillchar, '.
                    \                                   'fillspec, curline, '.
                    \                                   'curfil, curstr, opts)',
                    \])
                    if has_key(cformat, "lineend")
                        call add(formatfunction,
                        \'let curstr.=cformat.lineend(2, fillspec, curline,'.
                        \                            ' 0, curstr, opts)')
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
                        \'    let curstr.=cformat.collapsedfiller('.
                        \                               'filler, '.
                        \                               'fillspec, curline,'.
                        \                               'curstr, '.
                        \                               'opts)',])
                        if has_key(cformat, "lineend")
                            call add(formatfunction,
                            \'let curstr.=cformat.lineend(3, fillspec, '.
                            \                           'curline, 0, curstr, '.
                            \                           'opts)')
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
                    \'    let curstr.='.s:F.plug.stuf.squote(fillerstr),])
                    if has_key(cformat, "lineend")
                        call add(formatfunction,
                        \'let curstr.=cformat.lineend(2, fillspec, curline,'.
                        \                            ' 0, curstr, opts)')
                    endif
                    call add(formatfunction,
                    \'let r+=repeat([curstr], filler)')
                endif
            "{{{6 Обнуление текущей строки
            call extend(formatfunction, [
            \'    let curstr=""',
            \'endif',
            \'if curline>'.endline,
            \'    break',
            \'endif',
            \])
        endif
        "{{{5 Обработка складок
        "{{{6 Закрытые складки,
        " если нет foldcolumn и не требуется создавать остальные складки
        if !ignorefolds && !allfolds && !foldcolumn
            call extend(formatfunction, [
            \'if foldclosed(curline)>-1',
            \'let curstr='.
            \           ((has_key(cformat, "linestart"))?
            \               ('cformat.linestart(1, foldspec, curline, "", '.
            \                                  'opts)'):
            \               ('')).
            \           ((donr||dornr)?
            \              ('.cformat.linenr('.
            \                   ((dornr)?
            \                       ('abs(curline-'.cline.')'):
            \                       ('curline')).', '.
            \                              'foldspec, '.
            \                              'curline, "", opts)'):
            \              ('')),
            \'let curstr.=cformat.fold(foldtextresult(curline), '.
            \                         'foldspec, '.
            \                         'curline, curstr, opts)'.
            \           ((has_key(cformat, "lineend"))?
            \               ('.cformat.lineend(1, foldspec, curline, 0, "", '.
            \                                 'opts)'):
            \               ('')),
            \'    call add(r, curstr)',
            \'    let curline=foldclosedend(curline)+1',
            \'    continue',
            \'else',
            \])
        "{{{6 foldcolumn и остальные складки
        elseif allfolds || foldcolumn
            "{{{7 Все складки
            if allfolds
                call extend(formatfunction, [
                \'if has_key(possiblefolds, curline)',
                \'    let pf=possiblefolds[curline]',])
                if has_key(cformat, "foldend")
                    call extend(formatfunction, [
                    \'    if has_key(pf, "end")',
                    \'        call extend(r, pf.end)',
                    \'    endif',])
                endif
                if has_key(cformat, "foldstart")
                    call extend(formatfunction, [
                    \'    if has_key(pf, "start")',
                    \'        call extend(r, pf.start)',
                    \'    endif',])
                endif
                call add(formatfunction,
                \'endif')
            endif
            "{{{7 Закрытые складки
            if !ignorefolds
                call extend(formatfunction, [
                \'if len(closedfoldslist) && curline==closedfoldslist[0]',
                \'    let closedfoldslist=closedfoldslist[1:]',
                \'    call add(r, closedfolds[curline])',
                \])
                if !allfolds
                    call extend(formatfunction, [
                    \"let curline=remove(closedfoldsends, 0)+1",
                    \"let foldlevel-=1",
                    \"continue",])
                endif
                call add(formatfunction, 'endif')
            endif
        endif
        "{{{5 Обработка нормальных строк
        "{{{6 Объявление переменных
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
        "{{{7 specialcolumns
        let hasspcol=0
        if tagregex!=#"" && has_key(cformat, 'tagend')
            let hasspcol=1
            call add(formatfunction, 'let specialcolumns={}')
        endif
        "{{{7 Если есть отличия в строке (от другого буфера с &diff)
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
            \                             s:g.fmt.whatterm.'")',
            \'    let dspec=s:F.fmt.compiledspec(cformat, "Normal", '.
            \                                   'diffhlname)',
            \'endif',])
        endif
        "{{{7 Пробелы в конце строки
        if has_key(listchars, "trail")
            call extend(formatfunction, [
            \'let trail=len(matchstr(linestr, ''\s\+$''))',
            \'if trail',
            \'    let linelen-=trail',
            \'    let linestr=linestr[:(linelen-1)].'.
            \                'substitute(linestr[(linelen):], " ", '.
            \                   s:F.plug.stuf.squote(escape(listchars.trail[0],
            \                                               '&~\')).', "g")',
            \'endif',
            \])
        endif
        let nstring=((docline)?
                    \   ('((curline=='.cline.')?(clspec):(normalspec))'):
                    \   ('normalspec'))
        "{{{6 Начало строки
        "{{{7 linestart
        if has_key(cformat, "linestart")
            call add(formatfunction,
            \'let curstr.=cformat.linestart("", '.
            \   ((&diff)?('((diffattr)?(dspec):('.nstring.'))'):(nstring)).', '.
            \   'curline, curstr, opts)')
        endif
        "{{{7 Foldcolumn
        if foldcolumn
            if persistentfdc
                call add(formatfunction,
                \'let curstr.=foldcolumns[foldlevel][2-fdchange]')
            else
                call extend(formatfunction, [
                \'if has_key(foldcolumnstarts, curline)',
                \'    let curstr.=foldcolumnstarts[curline]',
                \'else',
                \'    let curstr.=cformat.foldcolumn(foldcolumns[foldlevel], '.
                \                                   'fcspec, curline, '.
                \                                   'foldlevel, "", opts)',
                \'endif',
                \])
            endif
        endif
        "{{{7 Номер
        if donr || dornr
            call add(formatfunction,
            \'let curstr.=cformat.linenr('.
            \                            ((dornr)?
            \                                ('abs(curline-'.cline.')'):
            \                                ('curline')).', '.
            \                            ((docline)?
            \                               ('((curline=='.cline.')?'.
            \                                   '(nrclspec):'.
            \                                   '(nrspec))'):
            \                               ('nrspec')).', '.
            \                           'curline, curstr, opts)')
        endif
        "{{{6 Обработка остальной строки
        if tagregex!=#""
            call add(formatfunction, 'let ignoretag=0')
        endif
        call extend(formatfunction, [
        \'let id=0',
        \'while curcol<=linelen',
        \'    let startcol=curcol',
        \])
            "{{{7 Получение длины зоны с идентичной подсветкой
            "{{{8 Тёги
            if tagregex==#""
                let taglines=[]
            else
                let taglines=[
                            \'if !ignoretag',
                            \'    let tag=matchstr(linestr, ''\k\@<!\%''.'.
                            \             'curcol.''c\%('.
                            \             s:F.plug.stuf.squote(tagregex)[1:-2].
                            \             '\)\k\@!'')',
                            \'    if tag!=#""',
                            \'        let ignoretag=1',
                            \'        break',
                            \'    endif',
                            \'endif']
                call extend(formatfunction, [
                \'if !ignoretag',
                \'    let tag=matchstr(linestr, ''\k\@<!\%''.'.
                \             'curcol.''c\%('.
                \             s:F.plug.stuf.squote(tagregex)[1:-2].
                \             '\)\k\@!'')',
                \'else',
                \'    let tag=""',
                \'endif',
                \'if tag!=#""',
                \'    let ignoretag=1',
                \'else',
                \'    let ignoretag=(index(values(specialcolumns), "tag")!=-1)',
                \])
            endif
            "{{{8 Скрытые символы
            call add(formatfunction,
            \'let id=synID(curline, curcol, 1)')
            if formatconcealed
                let nocconceal=(docline&&(&concealcursor=~#'n'))
                if nocconceal
                    call extend(formatfunction, [
                    \'if curline=='.cline,
                    \'    let concealed=0'
                    \'else'
                    \])
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
                        \   s:F.plug.stuf.squote(listchars.conceal[0]))
                    else
                        call add(formatfunction, 'let concealinfo[1]=" "')
                    endif
                    call add(formatfunction, 'endif')
                elseif &conceallevel==3
                    call add(formatfunction, 'let concealinfo[1]=""')
                endif
                call add(formatfunction, 'else')
            endif
            "{{{8 Строка отличается
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
                \               ('!has_key(specialcolumns, curcol) && '):("")).
                \          'curcol<=linelen']+taglines+[
                \'        let curcol+=1',
                \'    endwhile',
                \'else',
                \])
            endif
            "{{{8 Строка не отличается или не включен режим различий
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
                call add(formatfunction, "endif")
            endif
            if formatconcealed
                call add(formatfunction, "endif")
            endif
            if tagregex!=#""
                call add(formatfunction, "endif")
            endif
            "{{{7 Форматирование части строки с идентичной подсветкой
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
            "{{{8 Получение спецификации подсветки найденной части
            if formatconcealed
                call add(formatfunction, 'if concealed')
                if formatconcealed==2
                    call add(formatfunction,
                    \'let hlname=synIDattr(synIDtrans(id), "name", "'.
                    \                       s:g.fmt.whatterm.'")')
                else
                    call add(formatfunction, 'let hlname="Conceal"')
                endif
                call add(formatfunction, 'else')
            endif
            if has_key(listchars, "trail")
                call extend(formatfunction, [
                \'if trail==-1',
                \'    let hlname="SpecialKey"',
                \'else',
                \])
            endif
            call add(formatfunction,
            \'    let hlname=synIDattr(synIDtrans(id), "name", "'.
            \                          s:g.fmt.whatterm.'")')
            if has_key(listchars, "trail")
                call add(formatfunction, "endif")
            endif
            if formatconcealed
                call add(formatfunction, "endif")
            endif
            if &diff
                call extend(formatfunction, [
                \'if diffattr',
                \'    let diffhlname=synIDattr(synIDtrans(diffid), "name", "'.
                \                               s:g.fmt.whatterm.'")',
                \'    let spec=s:F.fmt.compiledspec(cformat, hlname, '.
                \                                  'diffhlname)',
                \'    let ddspec=s:F.fmt.compiledspec(cformat, "Normal", '.
                \                                    'diffhlname)',
                \'else'
                \])
            endif
            call add(formatfunction,
            \((docline)?
            \   ('let spec=call(s:F.fmt.compiledspec, '.
            \                  '[cformat, hlname]+'.
            \                   '((curline=='.cline.')?'.
            \                       '(["CursorLine"]):'.
            \                       '([])), {})'):
            \   ('let spec=s:F.fmt.compiledspec(cformat, hlname)')))
            if &diff
                call add(formatfunction, "endif")
            endif
            if formatconcealed==2
                call extend(formatfunction, [
                \'if concealed',
                \'    let cspec=s:F.fmt.compiledspec(cformat, "Conceal")',
                \'endif',
                \])
            endif
            "{{{8 Обработка табуляции и непечатных символов
            " rstartcol — длина обработанной части строки с учётом
            "             возможного наличия многобайтных символов
            if formatconcealed
                call add(formatfunction, "if !concealed")
            endif
            call extend(formatfunction, [
            \'let idx=match(cstr, '.npregex.')',
            \'if idx!=-1',
            \'    let rstartcol=(s:F.stuf.strlen(linestr[:(startcol-1)]))',
            \'    while idx!=-1',])
                    "{{{9 Объявление переменных
                    " fcstr — часть текущей подстроки до табуляции
                    " ridx  — Длина fcstr с учётом возможного наличия
                    "         многобайтных символов
                    call extend(formatfunction, [
                    \'let fcstr=((idx)?(cstr[:(idx-1)]):(""))',
                    \'let ridx=(s:F.stuf.strlen(fcstr))',
                    \'let istab=(cstr[idx]==#"\t")',])
                    "{{{9 Форматирование строки до табуляции
                    if !has_key(listchars, "tab")
                        call add(formatfunction, 'if !istab')
                    endif
                    call extend(formatfunction, [
                    \'if fcstr!=""',
                    \'    let curstr.=cformat.line(fcstr, '.
                    \           ((&diff)?
                    \               ('((diffattr)?(ddspec):(spec))'):
                    \               ('(spec)')).', '.
                    \           'curline, idx, curstr, opts)',
                    \'endif',])
                    if !has_key(listchars, "tab")
                        call add(formatfunction, 'endif')
                    endif
                    "{{{9 Представление табуляции
                    " i — видимая длина символа табуляции
                    let longtab=((&list && has_key(listchars, 'tab')) || !&list)
                    if longtab
                        call extend(formatfunction, [
                        \'if istab',
                        \'    let i='.&tabstop.'-'.
                        \           '((rstartcol+ridx-1)%('.&tabstop.'))',])
                            "{{{10 Есть ключ «tab» у настройки 'listchars'
                            if has_key(listchars, "tab")
                                " tabstr — Представление символа «\t»
                                call extend(formatfunction, [
                                \'let tabstr='.
                                \   s:F.plug.stuf.squote(listchars.tab[0]),
                                \'let tabstr.=repeat('.
                                \   s:F.plug.stuf.squote(listchars.tab[1]).', '.
                                \'i-1)',
                                \'let curstr.=cformat.line(tabstr, '.
                                \   ((&diff)?
                                \       ('((diffattr)?(ddspec):(specialspec))'):
                                \       ('specialspec')).", ".
                                \   'curline, idx, curstr, opts)',
                                \'let cstr=cstr[(idx+1):]',])
                            "{{{10 Указанного ключа нет
                            else
                                call extend(formatfunction, [
                                \'let tabstr=repeat(" ", i)',
                                \'let cstr=fcstr.tabstr.cstr[(idx+1):]',])
                            endif
                        call add(formatfunction, 'else')
                    endif
                    "{{{9 Представление спецсимвола
                    call extend(formatfunction, [
                    \'    let cstr=cstr[(len(fcstr)):]',
                    \'    let char=matchstr(cstr, "^.")',
                    \'    let cstr=cstr[(len(char)):]',])
                    if has_key(listchars, "nbsp")
                        call extend(formatfunction, [
                        \'if char==#" "',
                        \'    let curstr.=cformat.line('.
                        \   s:F.plug.stuf.squote(listchars.nbsp[0]).', '.
                        \       ((&diff)?
                        \           ('((diffattr)?(ddspec):(specialspec))'):
                        \           ('specialspec')).", ".
                        \       'curline, idx, curstr, opts)',
                        \'else',])
                    endif
                    call add(formatfunction,
                    \'let curstr.=cformat.line(strtrans(char), '.
                    \       ((&diff)?
                    \           ('((diffattr)?(ddspec):(ntspec))'):
                    \           ('ntspec')).", ".
                    \       'curline, idx, curstr, opts)')
                    if has_key(listchars, "nbsp")
                        call add(formatfunction, "endif")
                    endif
                    if longtab
                        call add(formatfunction, "endif")
                    endif
                    "{{{9 Завершение цикла
                    " Следующий символ
                    call extend(formatfunction, [
            \'        let idx=match(cstr, '.npregex.')',
            \'    endwhile',
            \'endif'])
            "{{{9 Скрытые символы
            if formatconcealed
                call add(formatfunction, "endif")
                if formatconcealed==2
                    call extend(formatfunction, [
                    \'if concealed',
                    \'    let curstr.=cformat.concealed(concealinfo[1], '.
                    \                                  'cspec, curline, '.
                    \                                  'curcol, curstr, opts, '.
                    \                                  'cstr, spec)',
                    \'else',
                    \])
                endif
            endif
            "{{{8 Сброс trail
            if has_key(listchars, 'trail')
                call extend(formatfunction, [
                \'if trail>0 && curcol>linelen',
                \'    let linelen+=trail',
                \'    let trail=-1',
                \'endif',])
            endif
            "{{{8 Включение отформатированной части
            call extend(formatfunction, [
            \'if cstr!=""',
            \'    let curstr.=cformat.line(cstr, spec, curline, curcol, '.
            \                             'curstr, opts)',
            \'endif',])
            if formatconcealed==2
                call add(formatfunction, 'endif')
            endif
            "{{{7 Тёги
            if tagregex!=#""
                if has_key(cformat, 'tagend')
                    call extend(formatfunction, [
                    \'if has_key(specialcolumns, curcol) && '.
                    \       'specialcolumns[curcol]==#"tag"',
                    \'    let curstr.=cformat.tagend(tag, spec, curline, '.
                    \                               'curcol, curstr, opts)',
                    \'    call remove(specialcolumns, curcol)',
                    \'    let tag=""',
                    \'    let ignoretag=0',
                    \'endif',])
                endif
                if has_key(cformat, 'tagstart')
                    call extend(formatfunction, [
                    \'if tag!=#""',
                    \'    let curstr.=cformat.tagstart(tag, spec, curline, '.
                    \                                 'curcol, curstr, opts)',])
                    if has_key(cformat, 'tagend')
                        call add(formatfunction,
                        \'    let specialcolumns[curcol+len(tag)]="tag"')
                    endif
                    call add(formatfunction, "endif")
                endif
            endif
            "}}}7
        call add(formatfunction, 'endwhile')
        "{{{7 Форматирование символа конца строки
        if has_key(listchars, "eol")
            call add(formatfunction,
            \'let curstr.=cformat.line('.
            \       s:F.plug.stuf.squote(listchars.eol[0]).', '.
            \       ((&diff)?
            \           ('((diffattr)?(dspec):(ntspec))'):
            \           ('ntspec')).", ".
            \       'curline, curcol+1, curstr, opts)')
        endif
        "{{{7 Конец строки
        if has_key(cformat, "lineend")
            call add(formatfunction,
            \'let curstr.=cformat.lineend("", '.nstring.', curline, curcol, '.
            \                            'curstr, opts)')
        endif
        "{{{7 Складки
        if !ignorefolds && !allfolds && !foldcolumn
            call add(formatfunction, "endif")
        endif
        "{{{7 Завершение цикла
        call extend(formatfunction, [
    \'    call add(r, curstr)',
    \'    let curline+=1',
    \'endwhile'
    \])
    "{{{4 Начало и конец представления
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
        if has_key(cformat, "begin")
            call add(formatfunction,
            \'call insert(r, cformat.begin(normalspec, "", opts, '.
            \            'cformat.stylestr))')
        endif
        if has_key(cformat, "end")
            call add(formatfunction,
            \'call add(r, cformat.end(normalspec, '.endline.', "", opts, '.
            \          'cformat.stylestr))')
        endif
    endif
    call add(formatfunction, "return r")
call add(formatfunction, "endfunction")
    " " FIXME remove debugging line
    " call writefile(formatfunction, $HOME."/tmp/vim/cffunc.vim", 1)
    execute join(formatfunction, "\n")
    "{{{4 r
    let r=s:F.fmt.compiledformat()
    unlet s:F.fmt.compiledformat
    unlet s:F.fmt.compiledspec
    "{{{4 Восстановление старых значений
    let &magic=oldmagic
    if showprogress
        let &laststatus=oldlaststatus
        call setwinvar(0, '&statusline', oldstatusline)
        if canresize
            let s:g.fmt.progress.showprogress=0
        endif
    endif
    if foldcolumn || allfolds
        call setwinvar(0, '&foldminlines', oldfoldminlines)
    endif
    if sbsd
        return r
    endif
    "{{{4 cformat.nolf
    if has_key(cformat, "nolf") && cformat.nolf
        let r=[join(r, "")]
    endif
    "{{{4 cformat.haslf
    if has_key(cformat, "haslf") && cformat.haslf
        let oldr=r
        let r=[]
        for item in oldr
            let r+=split(item, "\n")
        endfor
    endif
    "{{{4 Удалить кэш, если это требуется
    if !s:F.main.option("KeepColorCache")
        let cformat.cache={}
        let cformat.stylestr=""
    endif
    "}}}4
    unlet cformat.frunning
    return r
endfunction
"{{{3 fmt.add
function s:F.fmt.add(type, format)
    let s:g.fmt.formats[a:type]=deepcopy(a:format)
    return 1
endfunction
"{{{3 fmt.del
function s:F.fmt.del(type)
    if has_key(s:g.fmt.formats, a:type)
        unlet s:g.fmt.formats[a:type]
        if has_key(s:g.fmt.compiled, a:type)
            unlet s:g.fmt.compiled[a:type]
            return 2
        endif
        return 1
    endif
    return 0
endfunction
"{{{3 fmt.purgecolorcaches
function s:F.fmt.purgecolorcaches()
    for cformat in values(s:g.fmt.compiled)
        let cformat.cache={}
        let cformat.stylestr=""
    endfor
endfunction
augroup FormatPurgeColorCaches
    autocmd!
    autocmd ColorScheme * call s:F.fmt.purgecolorcaches()
augroup END
"{{{2 mng: main
"{{{3 mng.main
"{{{4 s:g.chk.cmd
let s:g.chk.cmd={
            \"model": "actions",
            \"actions": {
            \   "diffformat": {
            \       "model": "prefixed",
            \       "optional": [[["keyof", s:g.fmt.formats],
            \                     {"trans": ["call", ["DefaultFormat"]]},
            \                     s:F.main.option]],
            \       "prefoptional": {
            \           "columns":         [["nums", [-1]],       {},  0],
            \           "foldcolumn":      [["nums", [-1]],       {}, -2],
            \           "folds":           [["in",   ['0', '1']], {}, -1],
            \           "number":          [["in",   ['0', '1']], {}, -1],
            \           "relativenumber":  [["in",   ['0', '1']], {}, -1],
            \           "list":            [["in",   ['0', '1']], {}, -1],
            \           "tags":            [["in", ['all']],      {}, -1],
            \           "progress":        [["in", ['lines']],    {}, -1],
            \           "concealed":       [["in", ['real']],     {}, -1],
            \       },
            \       "altpref": ["relativenumber", "number", "folds", "list",
            \                   "tags", "progress", "concealed", "foldcolumn"],
            \   },
            \   "format": {
            \       "model": "prefixed",
            \       "optional": [[["keyof", s:g.fmt.formats],
            \                     {"trans": ["call", ["DefaultFormat"]]},
            \                     s:F.main.option]],
            \       "prefoptional": {
            \           "columns":         [["nums", [-1]],       {},  0],
            \           "collapsfiller":   [["nums", [0]],        {}, -1],
            \           "foldcolumn":      [["nums", [-1]],       {}, -2],
            \           "folds":           [["in",   ['0', '1']], {}, -1],
            \           "allfolds":        [["in",   ['0', '1']], {}, -1],
            \           "number":          [["in",   ['0', '1']], {}, -1],
            \           "relativenumber":  [["in",   ['0', '1']], {}, -1],
            \           "list":            [["in",   ['0', '1']], {}, -1],
            \           "tags":            [["in", ['all']],      {}, -1],
            \           "progress":        [["in", ['lines']],    {}, -1],
            \           "concealed":       [["in", ['real']],     {}, -1],
            \       },
            \       "altpref": ["relativenumber", "number", "folds", "list",
            \                   "allfolds", "tags", "progress", "concealed",
            \                   "foldcolumn", "collapsfiller"],
            \   },
            \   "delete": {
            \       "model": "simple",
            \       "required": [["keyof", s:g.fmt.formats]],
            \   },
            \   "list": {"model": "optional",},
            \   "purgecolorcaches": {"model": "optional",},
            \},
        \}
"}}}4
function s:F.mng.main(startline, endline, action, ...)
    let action=tolower(a:action)
    "{{{4 Проверка ввода
    let args=s:F.plug.chk.checkarguments(s:g.chk.cmd, [action]+a:000)
    let action=args[0]
    if type(args)!=type([])
        return 0
    endif
    "{{{4 Действия
    if action==#"format" || action==#"diffformat"
        let result=call(s:F.fmt.format, [args[1], a:startline, a:endline,
                    \                    args[2], (action==#"diffformat")], {})
        new ++enc=utf-8
        call setline(1, result)
        return 1
    elseif action==#"delete"
        return s:F.fmt.del(args[1])
    elseif action==#"list"
        echo join(keys(s:g.fmt.formats), "\n")
        return 1
    elseif action==#"purgecolorcaches"
        call s:F.fmt.purgecolorcaches()
    endif
    "}}}4
    return 0
endfunction
"{{{2 comp
function s:F.comp.getcolumns(arglead)
    return ['-1', '80', "".&columns, "".winwidth()]
endfunction
let s:g.comp={}
let s:g.comp._cname="format"
let s:g.comp.a={"model": "actions"}
let s:g.comp.a.actions={}
let s:g.comp.a.actions.format={
            \"model": "pref",
            \"arguments": [["keyof", s:g.fmt.formats]],
            \"prefix": {
            \   "columns":         ["func", s:F.comp.getcolumns],
            \   "collapsfiller":   ["list", []],
            \   "foldcolumn":      ["list", []],
            \   "tags":            ["list", ['all']],
            \   "progress":        ["list", ['lines']],
            \   "concealed":       ["list", ['real']],
            \},
            \"altpref": ["relativenumber", "number", "folds", "list",
            \            "allfolds", "tags", "progress", "concealed",
            \            "foldcolumn", "collapsfiller"],
        \}
if has("diff")
    let s:g.comp.a.actions.diffformat={
                \"model": "pref",
                \"arguments": [["keyof", s:g.fmt.formats]],
                \"prefix": {
                \   "columns":    ["func", s:F.comp.getcolumns],
                \   "foldcolumn": ["list", []],
                \   "tags":       ["list", ['all']],
                \   "progress":   ["list", ['lines']],
                \   "concealed":  ["list", ['real']],
                \},
                \"altpref": ["relativenumber", "number", "folds", "list",
                \            "tags", "progress", "concealed", "foldcolumn"],
            \}
else
    unlet s:g.comp.a.actions.format.prefix.collapsfiller
endif
if !has("folding")
    unlet s:g.comp.a.actions.format.prefix.ignorefolds
    unlet s:g.comp.a.actions.format.prefix.foldcolumn
    unlet s:g.comp.a.actions.format.prefix.allfolds
    unlet s:g.comp.a.actions.diffformat.prefix.ignorefolds
    unlet s:g.comp.a.actions.diffformat.prefix.foldcolumn
endif
if !has("statusline")
    unlet s:g.comp.a.actions.format.prefix.progress
    unlet s:g.comp.a.actions.diffformat.prefix.progress
endif
let s:g.comp.a.actions.delete={
            \"model": "simple",
            \"arguments": [["keyof", s:g.fmt.formats]],
        \}
let s:g.comp.a.actions.list={
            \"model": "simple",
            \"arguments": [],
        \}
let s:g.comp.a.actions.purgecolorcaches={
            \"model": "simple",
            \"arguments": [],
        \}
let s:F.comp._complete=s:F.plug.comp.ccomp(s:g.comp._cname, s:g.comp.a)
"{{{1
unlet s:g.extfuncdicts
lockvar! s:F
unlockvar s:F.fmt
lockvar! s:g
unlockvar s:g.fmt.formats
unlockvar s:g.fmt.compiled
unlockvar s:g.fmt.progress
if !has("syntax")
    call s:F.main.eerror("", "notimp", ["synnsup"])
    LoadCommand unload format
endif
" vim: ft=vim:ts=8:fdm=marker:fenc=utf-8

