"{{{1 Начало
scriptencoding utf-8
if (exists("s:g.pluginloaded") && s:g.pluginloaded) ||
            \exists("g:formatOptions.DoNotLoad")
    finish
"{{{1 Первая загрузка
elseif !exists("s:g.pluginloaded")
    "{{{2 Объявление переменных
    "{{{3 Словари с функциями
    " Функции для внутреннего использования
    let s:F={
                \"plug": {},
                \"stuf": {},
                \"main": {},
                \ "mng": {},
                \"comp": {},
                \ "fmt": {},
            \}
    lockvar 1 s:F
    "{{{3 Глобальная переменная
    let s:g={}
    let s:g.load={}
    let s:g.fmt={}
    let s:g.fmt.formats={}
    let s:g.pluginloaded=0
    let s:g.chk={}
    let s:g.load.scriptname=expand("<sfile>")
    let s:g.srccmd="source ".(s:g.load.scriptname)
    let s:g.chk.f=[
                \["format", "fmt.format", {
                \       "model": "optional",
                \       "required": [["keyof", s:g.fmt.formats]],
                \       "optional": [[["num", [0]], {}, 0],
                \                    [["num", [1]], {"trans": ["earg", ""]},
                \                     "line('$')"]],
                \   }
                \]
            \]
    let s:g.plugname=fnamemodify(s:g.load.scriptname, ":t:r")
    "{{{3 Команды и функции
    " Определяет команды. Для значений ключей словаря см. :h :command. Если 
    " некоторому ключу «key» соответствует непустая строка «str», то в аргументы 
    " :command передаётся -key=str, иначе передаётся -key. Помимо ключей 
    " :command, в качестве ключа словаря также используется строка «func». Ключ 
    " «func» является обязательным и содержит функцию, которая будет вызвана при 
    " запуске команды (без префикса s:F.).
    let s:g.load.commands={
                \"Command": {
                \      "nargs": '+',
                \       "func": "mng.main",
                \      "range": '%',
                \        "bar": "",
                \},
            \}
                " \   "complete": "customlist,s:_complete",
    let s:g.chk.ff=[
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
    "{{{3 sid
    function s:SID()
        return matchstr(expand('<sfile>'), '\d\+\ze_SID$')
    endfun
    let s:g.scriptid=s:SID()
    delfunction s:SID
    "}}}2
    let s:F.plug.load=load#LoadFuncdict()
    let s:g.reginfo=s:F.plug.load.registerplugin(s:g.chk.f, 'Format',
                \'Format', 'format', s:F, s:g, s:g.load.commands, s:g.chk.ff,
                \s:g.scriptid, s:g.load.scriptname, 0)
    let s:F.main.eerror=s:g.reginfo.functions.eerror
    let s:F.main.option=s:g.reginfo.functions.option
    finish
endif
"{{{1 Вторая загрузка
let s:g.pluginloaded=1
"{{{2 Настройки
let s:g.defaultOptions={
            \"DefaultFormat": "html",
            \"UseStyleCache": 1,
            \"IgnoreFolds":   0,
            \"IgnoreList":    0,
            \"NoLineNR":      0,
            \"ShowProgress":  0,
            \"CollapsFiller": 0,
        \}
let s:g.chk.options={
            \"DefaultFormat": ["keyof", s:g.fmt.formats],
            \"UseStyleCache": ["bool", ""],
            \"IgnoreFolds":   ["bool", ""],
            \"IgnoreList":    ["bool", ""],
            \"NoLineNR":      ["bool", ""],
            \"ShowProgress":  ["num", [0, 2]],
            \"CollapsFiller": ["num", [0]],
        \}
"{{{2 Чистка
unlet s:g.load
"{{{2 Выводимые сообщения
let s:g.p={
            \"emsg": {
            \   "misskey": "Required key is missing: %s",
            \},
            \"etype": {
            \   "syntax": "SyntaxError",
            \   "iform":  "InvalidFormat",
            \},
        \}
"{{{1 Вторая загрузка — функции
"{{{2 Внешние дополнения
let s:F.plug.stuf=s:F.plug.load.getfunctions("stuf")
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
    let str=substitute(str, '\_\s\+', ' ', 'g')
    let str=substitute(str, '[.\{-}]', '', 'g')
    let str=substitute(str, '&[^;]\+;\|.', '.', 'g')
    return len(str)
endfunction
"{{{2 main: eerror, destruct, option
"{{{3 main.destruct: выгрузить плагин
function s:F.main.destruct()
    unlet s:g
    unlet s:F
    return 1
endfunction
"{{{2 fmt: format, add, del
"{{{3 fmt.getexpr
"{{{4 s:g.fmt.colors
if has("gui_running")
    let s:g.fmt.whatterm = "gui"
else
    let s:g.fmt.whatterm = "cterm"
    if &t_Co == 8
        let s:g.fmt.colors = {
                    \0: "#808080",
                    \1: "#ff6060",
                    \2: "#00ff00",
                    \3: "#ffff00",
                    \4: "#8080ff",
                    \5: "#ff40ff",
                    \6: "#00ffff",
                    \7: "#ffffff"}
    else
        let s:g.fmt.colors = {
                    \ 0: "#000000",
                    \ 1: "#c00000",
                    \ 2: "#008000",
                    \ 3: "#804000",
                    \ 4: "#0000c0",
                    \ 5: "#c000c0",
                    \ 6: "#008080",
                    \ 7: "#c0c0c0",
                    \ 8: "#808080",
                    \ 9: "#ff6060",
                    \10: "#00ff00",
                    \11: "#ffff00",
                    \12: "#8080ff",
                    \13: "#ff40ff",
                    \14: "#00ffff",
                    \15: "#ffffff"}

        " Colors for 88 and 256 come from xterm.
        if &t_Co == 88
            call extend(s:g.fmt.colors, {
                        \ 16: "#000000",
                        \ 17: "#00008b",
                        \ 18: "#0000cd",
                        \ 19: "#0000ff",
                        \ 20: "#008b00",
                        \ 21: "#008b8b",
                        \ 22: "#008bcd",
                        \ 23: "#008bff",
                        \ 24: "#00cd00",
                        \ 25: "#00cd8b",
                        \ 26: "#00cdcd",
                        \ 27: "#00cdff",
                        \ 28: "#00ff00",
                        \ 29: "#00ff8b",
                        \ 30: "#00ffcd",
                        \ 31: "#00ffff",
                        \ 32: "#8b0000",
                        \ 33: "#8b008b",
                        \ 34: "#8b00cd",
                        \ 35: "#8b00ff",
                        \ 36: "#8b8b00",
                        \ 37: "#8b8b8b",
                        \ 38: "#8b8bcd",
                        \ 39: "#8b8bff",
                        \ 40: "#8bcd00",
                        \ 41: "#8bcd8b",
                        \ 42: "#8bcdcd",
                        \ 43: "#8bcdff",
                        \ 44: "#8bff00",
                        \ 45: "#8bff8b",
                        \ 46: "#8bffcd",
                        \ 47: "#8bffff",
                        \ 48: "#cd0000",
                        \ 49: "#cd008b",
                        \ 50: "#cd00cd",
                        \ 51: "#cd00ff",
                        \ 52: "#cd8b00",
                        \ 53: "#cd8b8b",
                        \ 54: "#cd8bcd",
                        \ 55: "#cd8bff",
                        \ 56: "#cdcd00",
                        \ 57: "#cdcd8b",
                        \ 58: "#cdcdcd",
                        \ 59: "#cdcdff",
                        \ 60: "#cdff00",
                        \ 61: "#cdff8b",
                        \ 62: "#cdffcd",
                        \ 63: "#cdffff",
                        \ 64: "#ff0000",
                        \ 65: "#ff008b",
                        \ 66: "#ff00cd",
                        \ 67: "#ff00ff",
                        \ 68: "#ff8b00",
                        \ 69: "#ff8b8b",
                        \ 70: "#ff8bcd",
                        \ 71: "#ff8bff",
                        \ 72: "#ffcd00",
                        \ 73: "#ffcd8b",
                        \ 74: "#ffcdcd",
                        \ 75: "#ffcdff",
                        \ 76: "#ffff00",
                        \ 77: "#ffff8b",
                        \ 78: "#ffffcd",
                        \ 79: "#ffffff",
                        \ 80: "#2e2e2e",
                        \ 81: "#5c5c5c",
                        \ 82: "#737373",
                        \ 83: "#8b8b8b",
                        \ 84: "#a2a2a2",
                        \ 85: "#b9b9b9",
                        \ 86: "#d0d0d0",
                        \ 87: "#e7e7e7"})
        elseif &t_Co == 256
            call extend(s:g.fmt.colors, {16: "#000000",
                        \ 17: "#00005f",
                        \ 18: "#000087",
                        \ 19: "#0000af",
                        \ 20: "#0000d7",
                        \ 21: "#0000ff",
                        \ 22: "#005f00",
                        \ 23: "#005f5f",
                        \ 24: "#005f87",
                        \ 25: "#005faf",
                        \ 26: "#005fd7",
                        \ 27: "#005fff",
                        \ 28: "#008700",
                        \ 29: "#00875f",
                        \ 30: "#008787",
                        \ 31: "#0087af",
                        \ 32: "#0087d7",
                        \ 33: "#0087ff",
                        \ 34: "#00af00",
                        \ 35: "#00af5f",
                        \ 36: "#00af87",
                        \ 37: "#00afaf",
                        \ 38: "#00afd7",
                        \ 39: "#00afff",
                        \ 40: "#00d700",
                        \ 41: "#00d75f",
                        \ 42: "#00d787",
                        \ 43: "#00d7af",
                        \ 44: "#00d7d7",
                        \ 45: "#00d7ff",
                        \ 46: "#00ff00",
                        \ 47: "#00ff5f",
                        \ 48: "#00ff87",
                        \ 49: "#00ffaf",
                        \ 50: "#00ffd7",
                        \ 51: "#00ffff",
                        \ 52: "#5f0000",
                        \ 53: "#5f005f",
                        \ 54: "#5f0087",
                        \ 55: "#5f00af",
                        \ 56: "#5f00d7",
                        \ 57: "#5f00ff",
                        \ 58: "#5f5f00",
                        \ 59: "#5f5f5f",
                        \ 60: "#5f5f87",
                        \ 61: "#5f5faf",
                        \ 62: "#5f5fd7",
                        \ 63: "#5f5fff",
                        \ 64: "#5f8700",
                        \ 65: "#5f875f",
                        \ 66: "#5f8787",
                        \ 67: "#5f87af",
                        \ 68: "#5f87d7",
                        \ 69: "#5f87ff",
                        \ 70: "#5faf00",
                        \ 71: "#5faf5f",
                        \ 72: "#5faf87",
                        \ 73: "#5fafaf",
                        \ 74: "#5fafd7",
                        \ 75: "#5fafff",
                        \ 76: "#5fd700",
                        \ 77: "#5fd75f",
                        \ 78: "#5fd787",
                        \ 79: "#5fd7af",
                        \ 80: "#5fd7d7",
                        \ 81: "#5fd7ff",
                        \ 82: "#5fff00",
                        \ 83: "#5fff5f",
                        \ 84: "#5fff87",
                        \ 85: "#5fffaf",
                        \ 86: "#5fffd7",
                        \ 87: "#5fffff",
                        \ 88: "#870000",
                        \ 89: "#87005f",
                        \ 90: "#870087",
                        \ 91: "#8700af",
                        \ 92: "#8700d7",
                        \ 93: "#8700ff",
                        \ 94: "#875f00",
                        \ 95: "#875f5f",
                        \ 96: "#875f87",
                        \ 97: "#875faf",
                        \ 98: "#875fd7",
                        \ 99: "#875fff",
                        \100: "#878700",
                        \101: "#87875f",
                        \102: "#878787",
                        \103: "#8787af",
                        \104: "#8787d7",
                        \105: "#8787ff",
                        \106: "#87af00",
                        \107: "#87af5f",
                        \108: "#87af87",
                        \109: "#87afaf",
                        \110: "#87afd7",
                        \111: "#87afff",
                        \112: "#87d700",
                        \113: "#87d75f",
                        \114: "#87d787",
                        \115: "#87d7af",
                        \116: "#87d7d7",
                        \117: "#87d7ff",
                        \118: "#87ff00",
                        \119: "#87ff5f",
                        \120: "#87ff87",
                        \121: "#87ffaf",
                        \122: "#87ffd7",
                        \123: "#87ffff",
                        \124: "#af0000",
                        \125: "#af005f",
                        \126: "#af0087",
                        \127: "#af00af",
                        \128: "#af00d7",
                        \129: "#af00ff",
                        \130: "#af5f00",
                        \131: "#af5f5f",
                        \132: "#af5f87",
                        \133: "#af5faf",
                        \134: "#af5fd7",
                        \135: "#af5fff",
                        \136: "#af8700",
                        \137: "#af875f",
                        \138: "#af8787",
                        \139: "#af87af",
                        \140: "#af87d7",
                        \141: "#af87ff",
                        \142: "#afaf00",
                        \143: "#afaf5f",
                        \144: "#afaf87",
                        \145: "#afafaf",
                        \146: "#afafd7",
                        \147: "#afafff",
                        \148: "#afd700",
                        \149: "#afd75f",
                        \150: "#afd787",
                        \151: "#afd7af",
                        \152: "#afd7d7",
                        \153: "#afd7ff",
                        \154: "#afff00",
                        \155: "#afff5f",
                        \156: "#afff87",
                        \157: "#afffaf",
                        \158: "#afffd7",
                        \159: "#afffff",
                        \160: "#d70000",
                        \161: "#d7005f",
                        \162: "#d70087",
                        \163: "#d700af",
                        \164: "#d700d7",
                        \165: "#d700ff",
                        \166: "#d75f00",
                        \167: "#d75f5f",
                        \168: "#d75f87",
                        \169: "#d75faf",
                        \170: "#d75fd7",
                        \171: "#d75fff",
                        \172: "#d78700",
                        \173: "#d7875f",
                        \174: "#d78787",
                        \175: "#d787af",
                        \176: "#d787d7",
                        \177: "#d787ff",
                        \178: "#d7af00",
                        \179: "#d7af5f",
                        \180: "#d7af87",
                        \181: "#d7afaf",
                        \182: "#d7afd7",
                        \183: "#d7afff",
                        \184: "#d7d700",
                        \185: "#d7d75f",
                        \186: "#d7d787",
                        \187: "#d7d7af",
                        \188: "#d7d7d7",
                        \189: "#d7d7ff",
                        \190: "#d7ff00",
                        \191: "#d7ff5f",
                        \192: "#d7ff87",
                        \193: "#d7ffaf",
                        \194: "#d7ffd7",
                        \195: "#d7ffff",
                        \196: "#ff0000",
                        \197: "#ff005f",
                        \198: "#ff0087",
                        \199: "#ff00af",
                        \200: "#ff00d7",
                        \201: "#ff00ff",
                        \202: "#ff5f00",
                        \203: "#ff5f5f",
                        \204: "#ff5f87",
                        \205: "#ff5faf",
                        \206: "#ff5fd7",
                        \207: "#ff5fff",
                        \208: "#ff8700",
                        \209: "#ff875f",
                        \210: "#ff8787",
                        \211: "#ff87af",
                        \212: "#ff87d7",
                        \213: "#ff87ff",
                        \214: "#ffaf00",
                        \215: "#ffaf5f",
                        \216: "#ffaf87",
                        \217: "#ffafaf",
                        \218: "#ffafd7",
                        \219: "#ffafff",
                        \220: "#ffd700",
                        \221: "#ffd75f",
                        \222: "#ffd787",
                        \223: "#ffd7af",
                        \224: "#ffd7d7",
                        \225: "#ffd7ff",
                        \226: "#ffff00",
                        \227: "#ffff5f",
                        \228: "#ffff87",
                        \229: "#ffffaf",
                        \230: "#ffffd7",
                        \231: "#ffffff",
                        \232: "#080808",
                        \233: "#121212",
                        \234: "#1c1c1c",
                        \235: "#262626",
                        \236: "#303030",
                        \237: "#3a3a3a",
                        \238: "#444444",
                        \239: "#4e4e4e",
                        \240: "#585858",
                        \241: "#626262",
                        \242: "#6c6c6c",
                        \243: "#767676",
                        \244: "#808080",
                        \245: "#8a8a8a",
                        \246: "#949494",
                        \247: "#9e9e9e",
                        \248: "#a8a8a8",
                        \249: "#b2b2b2",
                        \250: "#bcbcbc",
                        \251: "#c6c6c6",
                        \252: "#d0d0d0",
                        \253: "#dadada",
                        \254: "#e4e4e4",
                        \255: "#eeeeee"})
        endif
    endif
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
            \'#': "((a:opts.donr)?(".
            \       "'repeat('.s:F.plug.stuf.squote(a:opts.leadingspace).', '.".
            \       "a:opts.linenumlen.'-len(@-@)).@-@'):(''''''))",
            \'-': "'repeat('.s:F.plug.stuf.squote(a:opts.difffillchar).', ('.".
            \     "a:opts.columns.'-@=@)/'.".
            \       "s:F.stuf.strlen(a:opts.difffillchar).')'",
            \'_': "s:F.plug.stuf.squote(repeat(a:opts.leadingspace, ".
            \                                 "((a:opts.donr)?(".
            \                                   "a:opts.linenumlen):(0))))",
            \' ': "s:F.plug.stuf.squote(a:opts.leadingspace)",
            \'^': "((a:opts.donr)?s:F.plug.stuf.squote(a:opts.leadingspace):".
            \       "(''''''))",
            \'~': "s:F.plug.stuf.squote(a:opts.difffillchar)",
        \}
"}}}4
function s:F.fmt.getexpr(str, opts)
    if has_key(s:g.fmt.expressions, a:str)
        return s:g.fmt.expressions[a:str]
    elseif has_key(s:g.fmt.complexexpressions, a:str)
        return eval(s:g.fmt.complexexpressions[a:str])
    elseif a:str=~'^='
        let str=a:str
        let str=substitute(str, "''", "'", 'g')
        let str=substitute(str, '\\\(.\)', '\1', 'g')
        let str=substitute(str, '^=\|=%$', '', 'g')
        return str
    elseif a:str=~"^'"
        let str=a:str
        let str=substitute(str, "''", "'", 'g')
        let str=substitute(str, '^''\|''%$', '', 'g')
        return str
    elseif a:str=~"^>"
        let str=a:str
        let str=substitute(str, "''", "'", 'g')
        let str=substitute(str, '^>', '', '')
        return str
    elseif a:str==#'@'
        return "'%@'"
    else
        return "'".a:str."'"
    endif
endfunction
"{{{3 fmt.compile
function s:F.fmt.compile(Str, opts)
    if type(a:Str)==type(function("tr"))
        return a:Str
    else
        let requires=[]
        let str=a:Str
        let str=s:F.plug.stuf.squote(str)
        let str=substitute(str, '%\(=\([^\\%]\|\\.\)\+=%\|''.\{-}''%\|>.*\|.\)',
                    \'\=substitute("''.".'.
                    \       's:F.fmt.getexpr(submatch(1), a:opts).".''",'.
                    \   '"^''\\.''\\|''\\.''$", "", "g")',
                    \'g')
        let str=substitute(str, "^''\\.\\|\\.''$", "", "g")
        let str=substitute(str, '@_\([a-z]\+\)@',
                    \'\="a:opts.".add(requires, "_".submatch(1))[-1][1:]',
                    \'g')
        let str=substitute(str, '@\([a-z]\+\)@',
                    \'\="a:spec.".add(requires, submatch(1))[-1]',
                    \'g')
        let str=substitute(str, '@:@',  '\=add(requires, "a:style")[-1]',  'g')
        let str=substitute(str, '@-@',  '\=add(requires, "a:line")[-1]',   'g')
        let str=substitute(str, '@@@',  '\=add(requires, "a:str")[-1]',    'g')
        let str=substitute(str, '@\.@', '\=add(requires, "a:char")[-1]',   'g')
        if match(str, '@=@')!=-1
            call add(requires, '=')
            let str=substitute(str, '\(^\|''\@<=\.\)'.
                        \               '\(\(\(''\.\)\@!.\)*\)@=@',
                        \'\n    '.
                        \'let str.=\2a:opts.strlen(a:cur.str)',
                        \'g')
            let str=substitute('let str='.str, '^let str=\n    let str\.=',
                        \'let str=', '')
            let str.="\n    return str"
        else
            let str='return '.str
        endif
        let str=substitute(str, '%%@', '%@', 'g')
        let str=substitute(str,  '%@',  '@', 'g')
        let r={}
        execute      "function r.r(str, spec, line, char, cur, opts, style)\n".
                    \'    '.str."\n".
                    \'endfunction'
        return [r.r, requires]
    endif
endfunction
"{{{3 fmt.prepare
function s:F.fmt.prepare(format, startline, endline)
    let selfname="fmt.prepare"
    "{{{4 s:F.fmt.getcolor
    if !has_key(s:F.fmt, "getcolor")
        if s:g.fmt.whatterm==#"gui"
            function s:F.fmt.getcolor(color)
                return a:color
            endfunction
        else
            function s:F.fmt.getcolor(color)
                return ((has_key(s:g.fmt.colors, a:color))?
                            \(s:g.fmt.colors[a:color]):
                            \(""))
            endfunction
        endif
    endif
    "{{{4 opts
    let opts={}
    let opts.leadingspace=(has_key(a:format, 'leadingspace')?
                \(a:format.leadingspace):
                \(" "))
    let opts.difffillchar=(has_key(a:format, 'difffillchar')?
                \(a:format.difffillchar):
                \("-"))
    let opts.columns=(has_key(a:format, 'columns')?
                \(a:format.columns):
                \(&columns))
    let opts.strlen=(has_key(a:format, 'strlen')?
                \(a:format.strlen):
                \(s:F.stuf.strlen))
    let opts.linenumlen=len(a:endline)
    let opts.donr=has_key(a:format, "linenr") && !s:F.main.option("NoLineNR")
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
                \"linenr", "fold", "difffiller", "collapsedfiller"]
        if has_key(a:format, key)
            let [cformat[key], cformat["r_".key]]=s:F.fmt.compile(a:format[key],
                        \                                         opts)
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
"{{{3 fmt.spec
function s:F.fmt.spec(cformat, hlname, ...)
    let id=hlID(a:hlname)
    let diffid=-1
    if len(a:000)
        let diffid=hlID(a:000[0])
        let id.="_".diffid
    endif
    if has_key(a:cformat, "cache") && has_key(a:cformat.cache, id)
        return a:cformat.cache[id]
    endif
    let r={
                \"styleid": id,
                \"fgcolor": s:F.fmt.getcolor(
                \               synIDattr(id, "fg#", s:g.fmt.whatterm)),
                \"bgcolor": s:F.fmt.getcolor(
                \               synIDattr(id, "bg#", s:g.fmt.whatterm)),
                \"bold":        synIDattr(id, "bold"),
                \"italic":      synIDattr(id, "italic"),
                \"underline":   synIDattr(id, "underline"),
                \"inverse":     synIDattr(id, "inverse"),
            \}
    if diffid!=-1
        let r.bgcolor=s:F.fmt.getcolor(synIDattr(diffid, "bg#",
                    \                            s:g.fmt.whatterm))
    endif
    if has_key(a:cformat, "cache")
        let a:cformat.cache[id]=r
    endif
    if !has_key(a:cformat.hasstyles, id) && has_key(a:cformat, "style")
        let a:cformat.stylestr.=a:cformat.style(id, r, 0, 0, "", a:cformat.opts,
                    \                           a:cformat.stylestr)
        let a:cformat.hasstyles[id]=1
    endif
    return r
endfunction
"{{{3 fmt.format
"{{{4 s:g.fmt.formats
"{{{5 HTML/numbered
let s:g.fmt.escapehtml="%'substitute(substitute(@@@, '[<>\"&]', ".
            \          "'\\=\"&#\".char2nr(submatch(0)).\";\"', 'g'), ".
            \          "' ', '\\&nbsp;', 'g')'%"
let s:g.fmt.formats.html={
            \"style":        '%>((@styleid@!="")?'.
            \                   '(".s".@styleid@." {".'.
            \                     '((@inverse@)?("color: ".'.
            \                       '((@bgcolor@!="")?'.
            \                         '(@bgcolor@):'.
            \                         '(@_bgcolor@))."; background-color: ".'.
            \                       '((@fgcolor@!="")?'.
            \                         '(@fgcolor@):'.
            \                         '(@_fgcolor@)).";"):'.
            \                     '(((@fgcolor@!="")?'.
            \                       '("color: ".@fgcolor@.";"):'.
            \                       '("color: ".@_fgcolor@.";")).'.
            \                      '((@bgcolor@!="")?'.
            \                       '("background-color: ".@bgcolor@.";"):'.
            \                       '("background-color: ".@_bgcolor@.";")))).'.
            \                     '((@bold@)?'.
            \                       '("font-weight: bold;"):'.
            \                       '("")).'.
            \                     '((@italic@)?'.
            \                       '("font-style: italic;"):'.
            \                       '("")).'.
            \                     '((@underline@)?'.
            \                       '("text-decoration: underline;"):'.
            \                       '("")).'.
            \                   '"} "):'.
            \                   '(""))',
            \"begin":        "<html><head>".
            \                "<meta http-equiv=\"content-type\" ".
            \                       "content=\"text/hmtl; charset=UTF-8\" />".
            \                "<style> ".
            \                "body { font-family: monospace; ".
            \                        "white-space: nowrap; ".
            \                        "margin: 0; padding: 0; border: 0; } ".
            \                "div { margin: 0; padding: 0; border: 0; } ".
            \                "%:</style>".
            \                '<title>%''substitute(expand("%:p:~%"), '.
            \                '''[<>"&]'', '.
            \                '''\\="&#".char2nr(submatch(0)).";"'', "g")''%'.
            \                '</title></head>'.
            \                "<body class='s%S'>",
            \"end":          "</body></html>",
            \"linestart":    "<div class='s%S'>",
            \"linenr":       "<span class='s%S'>%#% </span>",
            \"line":         "<span class='s%S'>".s:g.fmt.escapehtml."</span>",
            \"lineend":      "</div>",
            \"fold":         "<div class='s%S'><span class='s%S'>%#%^".
            \                s:g.fmt.escapehtml."% %-</span></div>",
            \"difffiller":   "<div>%_%^".
            \                "<span class='s%S'>%-</span></div>",
            \"collapsedfiller": "<div>%_%^<span class='s%S'>".
            \                   '%~ Deleted lines: %s %-</span></div>',
            \"leadingspace": "&nbsp;",
            \"strlen":       s:F.stuf.htmlstrlen,
        \}
"{{{5 BBcode(unixforum)/not_numbered
let s:g.fmt.formats.bbcode_unixforum_nonr={
            \"begin": '[font="Courier New"][spoiler]',
            \"end":   '[/spoiler][/font]',
            \"linestart": "",
            \"line": '[color=%''((@fgcolor@!="")?(@fgcolor@."]"):'.
            \           '("White]")).'.
            \           '((@bold@)?("[b]"):("")).'.
            \           '((@italic@)?("[i]"):("")).'.
            \           'substitute(substitute(@@@, ''[&\[\]]'', '.
            \                   '''\="&#".char2nr(submatch(0)).";"'', "g"),'.
            \           '" ", ''\&#160;'', "g").'.
            \           '((@italic@)?("[/i]"):("")).'.
            \           '((@bold@)?("[/b]"):(""))''%[/color]',
            \"lineend": "",
            \"leadingspace": "&#160;",
            \"strlen": s:F.stuf.bbstrlen,
        \}
"{{{5 s:g.chk.format
let s:g.chk.format=[
            \["and", [["map", ["haskey", ["linestart",
            \                             "line",
            \                             "lineend"]]],
            \         ["dict", [[["in", ["linestart", "line", "lineend",
            \                            "begin", "end", "difffiller",
            \                            "leadingspace", "fold", "linenr"]],
            \                    ["type", type("")]],
            \                   [["equal", "strlen"], ["type", 2]],
            \                   [["equal", "columns"], ["num", 0]],
            \                   [["equal", "haslf"],  ["bool", 1]],
            \                   [["equal", "nolf"],   ["bool", 1]]]]]],
        \]
let s:g.chk.ff[0][2].required[1]=s:g.chk.format
"}}}5
let s:g.fmt.compiled={}
"}}}4
function s:F.fmt.format(type, startline, endline)
    "{{{4 Объявление переменных
    let oldmagic=&magic
    set magic
    let startline=a:startline
    let endline=a:endline
    "{{{5 cformat, opts
    if has_key(s:g.fmt.compiled, a:type)
        let cformat=s:g.fmt.compiled[a:type]
        let opts=cformat.opts
        unlockvar! opts
        let opts.linenumlen=len(endline)
        let opts.columns=(has_key(s:g.fmt.formats[a:type], 'columns')?
                    \(s:g.fmt.formats[a:type]):
                    \(&columns))
    else
        let cformat=s:F.fmt.prepare(s:g.fmt.formats[a:type], startline, endline)
        let opts=cformat.opts
        unlockvar! opts
        let s:g.fmt.compiled[a:type]=cformat
        if s:F.main.option("UseStyleCache")
            let cformat.cache={}
        endif
        let cformat.stylestr=""
    endif
    "}}}5
    " Складки игнорируются, если истинна настройка «IgnoreFolds», отсутствует 
    " ключ «fold» или Vim собран без поддержки складок
    let ignorefolds=s:F.main.option("IgnoreFolds") ||
                \!has_key(cformat, "fold") ||
                \!has("folding")
    let opts.ignorefolds=ignorefolds
    let npregex='\t\|\p\@!.'
    let cformat.hasstyles={} " Здесь содержится список определённых стилей. 
                             " Используется словарь для ускорения
    let r=[]                 " Список строк с возвращаемыми значениями
    let curline=startline    " Номер преобразовываемой линии
    "{{{5 Progress bar
    let showprogress=s:F.main.option("ShowProgress") " Показывать progress bar
    if !has("statusline")
        let showprogress=0
    endif
    if showprogress
        " Сохраненённое значения настройки 'statusline'
        let oldstatusline=getwinvar(0, "&statusline")
        let oldlaststatus=&laststatus " Сохранённое значение 'laststatus'
        let oldprogress=0        " Старое значение % сделанного
        let oldcolnum=0          " Старое значение длины строки из '='
        let barstart="["         " Первая часть progress bar’а со строкой =
        set laststatus=2
        " Вторая часть прогресс бара
        let barlen=((winwidth(0))-
                    \((showprogress==2)?
                    \    ((opts.linenumlen)*2+10):
                    \    (8)))
        if barlen<0
            let showprogress=0
        endif
        let barend=repeat(" ", barlen)."] "
    endif
    "{{{5 Форматы
    let normalspec  = s:F.fmt.spec(cformat, "Normal")     " Формат по умолчанию
    let specialspec = s:F.fmt.spec(cformat, "SpecialKey") " Для спецсимволов, 
                                                          " в т.ч. для lcs=tab 
                                                          " и lcs=trail
    let ntspec      = s:F.fmt.spec(cformat, "NonText")    " Для lcs=eol
    if !ignorefolds
        let foldspec    = s:F.fmt.spec(cformat, "Folded") " Формат складок
    endif
    let opts.donr=0
    if has_key(cformat, "linenr") && !s:F.main.option("NoLineNR")
        let nrspec      = s:F.fmt.spec(cformat, "LineNr") " Для номеров строк
        let opts.donr=1
    endif
    let donr=opts.donr
    if &diff
        let fillspec    = s:F.fmt.spec(cformat, "DiffDelete") " Для удалённых 
                                                              " строк
    endif
    lockvar! opts
    "{{{5 Удалённая строка: предсоздание, если возможно
    if &diff
        let persistentfiller=0
        let collapsafter=s:F.main.option("CollapsFiller")
        if collapsafter && has_key(cformat, "collapsedfiller")
            let persistentfiller=0
        elseif has_key(cformat, "difffiller")
            let collapsafter=0
            let persistentfiller=1
            let fillerstr=cformat.difffiller(opts.difffillchar, fillspec, 0, 0,
                        \                    "", opts, "")
            for requirement in cformat.r_difffiller
                if requirement=~'^a:line\|a:style$'
                    let persistentfiller=0
                    break
                endif
            endfor
        else
            let persistentfiller=1
            let fillerstr=""
        endif
    endif
    "{{{5 listchars: отображение некоторых символов в соответствии с 'listchars'
    let listchars={}
    if &list && !s:F.main.option("IgnoreList")
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
    "{{{4 Основной цикл: создание указанного представления
    while curline<=endline
        let curstr=""
        "{{{5 Progress bar
        if showprogress
            let progress=100*curline/endline
            let colnum=barlen*curline/endline
            if showprogress==2 || progress!=oldprogress || colnum!=oldcolnum
                if colnum!=oldcolnum
                    let barstart.="="
                    let barend=barend[1:]
                endif
                let bar=((barstart).">".(barend).
                            \((showprogress==2)?
                            \   (repeat(" ", opts.linenumlen-
                            \                len(curline)).
                            \    curline."/".endline." "):
                            \   ("")).
                            \(repeat(" ", 3-len(progress)).progress)."%%")
                call setwinvar(0, "&statusline", bar)
                redrawstatus
            endif
            let oldprogress=progress
            let oldcolnum=colnum
        endif
        "{{{5 Обработка удалённых строк
        " Если не включён режим разности, то никаких удалённых строк быть не 
        " может
        if &diff
            let filler=diff_filler(curline)
            if filler>0
                if !persistentfiller
                    if !collapsafter || filler<collapsafter
                        let curfil=filler
                        while curfil
                            call add(r, cformat.difffiller(opts.difffillchar,
                                        \                  fillspec, curline, 0,
                                        \                  "", opts,
                                        \                  cformat.stylestr))
                            let curfil-=1
                        endwhile
                    else
                        call add(cformat.collapsedfiller(filler, fillspec,
                                    \                    curline, 0, "", opts,
                                    \                    cformat.stylestr))
                    endif
                " Удалённая строка уже предсоздана
                else
                    let r+=repeat([fillerstr], filler)
                endif
                let curline+=1
                continue
            endif
        endif
        "{{{5 Обработка складок
        if foldclosed(curline)>-1 && !ignorefolds
            let curstr.=cformat.fold(foldtextresult(curline), foldspec,
                        \            curline, 0, curstr, opts, cformat.stylestr)
            let curline=foldclosedend(curline)
        "{{{5 Обработка нормальных строк
        else
            "{{{6 Объявление переменных
            let linestr=getline(curline)                " Текст строки целиком
            let linelen=len(linestr)                    " Длина строки
            let curcol=1                                " Номер текущего символа
            let diffattr=(&diff && diff_hlID(curline, 1)) " Наличие отличий
            "{{{7 Если есть отличия в строке (от другого буфера с &diff)
            if diffattr
                " diffid берётся для символа за пределами строки, так как если 
                " строка частично отличается, то она подсвечивается 
                " [фиолетовым], но сами отличия подсвечиваются [красным]. Символ 
                " за пределами строки подсвечивается как вся строка
                let diffid=diff_hlID(curline, linelen+1)
                let diffhlname=synIDattr(synIDtrans(diffid), "name",
                            \            s:g.fmt.whatterm)
                " Для отличающихся строк подсветка линии складывается из цвета 
                " символа, определённого файлом подсветки синтаксиса и цвета 
                " фона, определённого наличием отличий. dspec — спецификация 
                " стиля обычных символов
                let dspec=s:F.fmt.spec(cformat, "Normal", diffhlname)
            endif
            "{{{7 Пробелы в конце строки
            let trail=0
            if has_key(listchars, "trail")
                let trail=len(matchstr(linestr, '\s\+$'))
                if trail
                    " Мы не будем обрабатывать пробельные символы в конце строки 
                    " обычным способом
                    let linelen-=trail
                    let linestr=linestr[:(linelen-1)].
                                \substitute(linestr[(linelen):], ' ',
                                \           escape(listchars.trail[0], '&~\'),
                                \           'g')
                endif
            endif
            "{{{6 Начало строки
            let curstr.=cformat.linestart("",
                        \((diffattr)?(dspec):(normalspec)), curline, 0, curstr,
                        \                 opts, cformat.stylestr)
            "{{{7 Номер
            if donr
                let curstr.=cformat.linenr(curline, nrspec, curline, 0, curstr,
                            \              opts, cformat.stylestr)
            endif
            "{{{6 Обработка остальной строки
            let id=0
            while curcol<=linelen || (curcol==1 && diffattr)
                let startcol=curcol
                "{{{7 Получение длины зоны с идентичной подсветкой
                "{{{8 Строка отличается
                if diffattr
                    " Для отличающихся строк подсветка линии складывается из 
                    " цвета символа, определённого файлом подсветки синтаксиса 
                    " и цвета фона, определённого наличием отличий
                    let diffid=diff_hlID(curline, curcol)
                    let diffhlname=synIDattr(synIDtrans(diffid), "name",
                                \            s:g.fmt.whatterm)
                    " Для отличающихся строк подсветка линии складывается из цвета 
                    " символа, определённого файлом подсветки синтаксиса и цвета 
                    " фона, определённого наличием отличий. ddspec — 
                    " спецификация стиля обычных символов, но не для всей 
                    " строки, как dspec, а для текущего региона (нужно для 
                    " форматирования спецсимволов)
                    let ddspec=s:F.fmt.spec(cformat, "Normal", diffhlname)
                    let id=synID(curline, curcol, 1)
                    while id==synID(curline, curcol, 1) &&
                                \diffid==diff_hlID(curline, curcol) &&
                                \curcol<=linelen
                        let curcol+=1
                    endwhile
                "{{{8 Строка не отличается или не включен режим различий
                else
                    let id=synID(curline, curcol, 1)
                    let curcol+=1
                    while id==synID(curline, curcol, 1) &&
                                \curcol<=linelen
                        let curcol+=1
                    endwhile
                endif
                "{{{7 Форматирование части строки с идентичной подсветкой
                " cstr — текст найденной части
                let cstr=strpart(linestr, startcol-1, curcol-startcol)
                "{{{8 Получение спецификации подсветки найденной части
                if trail!=-1
                    let hlname=synIDattr(synIDtrans(id), "name",
                                \        s:g.fmt.whatterm)
                else
                    let hlname="SpecialKey"
                endif
                if diffattr
                    let diffhlname=synIDattr(synIDtrans(diffid), "name",
                                \s:g.fmt.whatterm)
                    let spec=s:F.fmt.spec(cformat, hlname, diffhlname)
                else
                    let spec=s:F.fmt.spec(cformat, hlname)
                endif
                "{{{8 Обработка табуляции и непечатных символов
                let idx=match(cstr, npregex)
                if idx!=-1
                    " rstartcol — длина обработанной части строки с учётом
                    "             возможного наличия многобайтных символов
                    let rstartcol=(s:F.stuf.strlen(linestr[:(startcol-1)]))
                    while idx!=-1
                        "{{{9 Объявление переменных
                        " fcstr — часть текущей подстроки до табуляции
                        " ridx  — Длина fcstr с учётом возможного наличия
                        "         многобайтных символов
                        let fcstr=((idx)?(cstr[:(idx-1)]):(""))
                        let ridx=(s:F.stuf.strlen(fcstr))
                        let istab=(cstr[idx]==#"\t")
                        "{{{9 Форматирование строки до табуляции
                        if (!istab || has_key(listchars, "tab"))
                            if fcstr!=""
                                let curstr.=cformat.line(fcstr,
                                            \((diffattr)?(ddspec):(spec)),
                                            \            curline, curcol,
                                            \            curstr, opts,
                                            \            cformat.stylestr)
                            endif
                        endif
                        "{{{9 Представление табуляции
                        if istab
                            " i — видимая длина символа табуляции
                            let i=&tabstop-((rstartcol+ridx-1)%(&tabstop))
                            "{{{10 Есть ключ «tab» у настройки 'listchars'
                            if has_key(listchars, "tab")
                                "{{{11 Представление символа «\t»
                                let tabstr=listchars.tab[0]
                                let tabstr.=repeat(listchars.tab[1], i-1)
                                "{{{11 Форматирование табуляции
                                let curstr.=cformat.line(tabstr,
                                            \((diffattr)?(ddspec):(specialspec)),
                                            \            curline, curcol,
                                            \            curstr, opts,
                                            \            cformat.stylestr)
                                "}}}11
                                let cstr=cstr[(idx+1):]
                            "{{{10 Указанного ключа нет
                            else
                                let tabstr=repeat(" ", i)
                                let cstr=fcstr.tabstr.cstr[(idx+1):]
                            endif
                        "{{{9 Представление спецсимвола
                        else
                            let cstr=cstr[(len(fcstr)):]
                            let char=matchstr(cstr, '^.')
                            let cstr=cstr[(len(char)):]
                            if char==#" "
                                let curstr.=cformat.line(listchars.nbsp[0],
                                            \((diffattr)?(ddspec):(ntspec)),
                                            \            curline, curcol, curstr,
                                            \            opts, cformat.stylestr)
                            else
                                let curstr.=cformat.line(strtrans(char),
                                            \((diffattr)?(ddspec):(ntspec)),
                                            \            curline, curcol, curstr,
                                            \            opts, cformat.stylestr)
                            endif
                        endif
                        "}}}9
                        let idx=match(cstr, npregex) " Следующий символ
                    endwhile
                endif
                "{{{8 Сброс trail
                if trail>0 && curcol>linelen
                    let linelen+=trail
                    let trail=-1
                endif
                "{{{8 Включение отформатированной части
                if cstr!=""
                    let curstr.=cformat.line(cstr, spec, curline, curcol,
                                \            curstr, opts, cformat.stylestr)
                endif
                "}}}7
            endwhile
            "{{{7 Форматирование символа конца строки
            if has_key(listchars, "eol")
                let curstr.=cformat.line(listchars.eol[0],
                            \((diffattr)?(dspec):(ntspec)), curline,
                            \            curcol, curstr, opts, cformat.stylestr)
            endif
            "{{{7 Конец строки
            let curstr.=cformat.lineend("", normalspec, curline, curcol, curstr,
                        \               opts, cformat.stylestr)
            "}}}7
        endif
        call add(r, curstr)
        let curline+=1
    endwhile
    "{{{4 Начало и конец представления
    if has_key(cformat, "begin")
        call insert(r, cformat.begin("", normalspec, 0, 0, "", opts,
                    \                cformat.stylestr))
    endif
    if has_key(cformat, "end")
        call add(r, cformat.end("", normalspec, endline, 0, "", opts,
                \               cformat.stylestr))
    endif
    "{{{4 Восстановление старых значений
    let &magic=oldmagic
    if showprogress
        let &laststatus=oldlaststatus
        call setwinvar(0, '&statusline', oldstatusline)
    endif
    "}}}4
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
    return r
endfunction
"{{{3 fmt.add
function s:F.fmt.add(type, format)
    let s:g.fmt.formats[a:type]=deepcopy(a:format)
    let s:g.fmt.compiled[a:type]=s:F.fmt.prepare(s:g.fmt.formats[a:type])
    return 1
endfunction
"{{{3 fmt.del
function s:F.fmt.del(type)
    unlet s:g.fmt.formats[a:type]
    if has_key(s:g.fmt.compiled, a:type)
        unlet s:g.fmt.compiled[a:type]
    endif
    return 1
endfunction
"{{{2 mng: main
"{{{3 mng.main
let s:g.chk.cmd={
            \"model": "actions",
            \"actions": {
            \   "format": {
            \       "model": "optional",
            \       "optional": [[["keyof", s:g.fmt.formats],
            \                     {"trans": ["call", ["DefaultFormat"]]},
            \                     s:F.main.option]],
            \   },
            \},
        \}
function s:F.mng.main(startline, endline, action, ...)
    let action=tolower(a:action)
    "{{{4 Проверка ввода
    let args=s:F.plug.chk.checkarguments(s:g.chk.cmd, [action]+a:000)
    let action=args[0]
    if type(args)!=type([])
        return 0
    endif
    "{{{4 Действия
    if action==#"format"
        let result=call(s:F.fmt.format, [args[1], a:startline, a:endline], {})
        new ++enc=utf-8
        call setline(1, result)
    endif
    "}}}4
endfunction
"{{{1
lockvar! s:F
unlockvar s:F.fmt
lockvar! s:g
unlockvar s:g.fmt.formats
unlockvar s:g.fmt.compiled
" vim: ft=vim:ts=8:fdm=marker:fenc=utf-8

