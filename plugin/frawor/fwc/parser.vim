"▶1 Header
scriptencoding utf-8
execute frawor#Setup('0.0', {'@/resources': '0.0',
            \             '@/fwc/intfuncs': '0.0',
            \        '@/fwc/topconstructs': '0.0'}, 1)
let s:parser={}
"▶1 Define messages
let s:_messages={
            \     'int': 'internal error: %s',
            \     'eos': 'unexpected end of string',
            \  'ukfunc': 'unknown function: %s',
            \  'ukfarg': 'unknown function argument: %s',
            \'unmatchp': 'unmatched `%s''',
            \ 'uenvvar': 'unknown enviroment variable: %s',
            \  'invvar': 'invalid variable description: %s',
            \  'invact': 'invalid action description: %s',
            \'invssubs': 'invalid subscript in slice expression: %s',
            \ 'uoption': 'unknown option: %s',
            \  'argmis': 'missing arguments to %s',
            \  'actmis': 'missing arguments description',
            \ 'typemis': 'missing type description',
            \ 'invtype': 'invalid type description: %s',
            \   'invid': 'invalid identifier description: %s',
            \  'invreg': 'invalid regular expression: %s',
            \ 'wordend': 'regular expression cannot end with %s',
            \  'noexpr': 'expected expression, but got nothing',
        \}
"▶1 add        :: &self
" Adds an element to current context
function s:parser.add(item)
    call add(self.l, a:item)
    return self
endfunction
"▶1 conclose   :: &self
" Closes current context
function s:parser.conclose()
    call remove(self.stack, -1)
    let self.l=self.stack[-1]
    return self
endfunction
"▶1 addcon     :: ()[, conelement1[, ...]] + self → self + self
" Adds new context with given elements
function s:parser.addcon(...)
    let con=copy(a:000)
    call self.add(con)
    call add(self.stack, con)
    let self.l=con
    return self
endfunction
"▶1 removestr  :: (UInt) + self → self + self(s)
function s:parser.removestr(len)
    if a:len>0
        let self.s=self.s[(a:len):]
        let self.len-=a:len
    endif
    return self
endfunction
"▶1 delblanks  :: &self(s)
function s:parser.delblanks()
    return self.removestr(match(self.s, "[^ \t\n\r]"))
endfunction
"▶1 ungetc     :: (Char) + self → self + self(s)
function s:parser.ungetc(c)
    call add(self.ungot, a:c)
    let self.len+=len(a:c)
    return self
endfunction
"▶1 ungotjoin  :: &self(s)
function s:parser.ungotjoin()
    let joined=substitute(join(reverse(remove(self.ungot, 0, -1))),
                \         '\w\@<! \w\@!', '', 'g')
    if joined[-1:]=~#'^\w' && self.s=~#'^\w'
        let joined.=' '
    endif
    let self.len+=len(joined)
    let self.s=joined.self.s
    return self
endfunction
"▶1 readc      :: () + self → String + self(s)
" Gets next character or word
function s:parser.readc()
    if !empty(self.ungot)
        let c=remove(self.ungot, -1)
        let self.len-=len(c)
        return c
    endif
    call self.delblanks()
    if !self.len
        call self.throw('eos')
    endif
    let c=self.s[0]
    if c!~#'\w'
        call self.removestr(1)
    else
        let c=matchstr(self.s, '^\w\+')
        call self.removestr(len(c))
    endif
    return c
endfunction
"▶1 readstr    :: () + self → String + self(s)
" Gets next double-quoted string. Backslash just escapes next character, no 
" other translations are done
" {dstr} :: '"' ( ( ! '\' | '"' ) | ( '\\' | '\"' ) )* '"'
"  {str} :: {dstr} | {sstr}
function s:parser.readstr()
    if !empty(self.ungot)
        call self.throw('int', 'strungetc')
    endif
    let c=matchstr(self.s, '\v(\\.|[^\\"])*"')
    if empty(c)
        call self.throw('unmatchp', '"')
    endif
    call self.removestr(len(c))
    return substitute(c[:-2], '\\\(.\)', '\1', 'g')
endfunction
"▶1 readsstr   :: () + self → String + self(s)
" Gets next single-quoted string.
" {sstr} :: "'" ( "''" | ( ! "'" ) )* "'"
"  {str} :: {dstr} | {sstr}
function s:parser.readsstr()
    if !empty(self.ungot)
        call self.throw('int', 'strungetc')
    endif
    let c=matchstr(self.s, "\\v(''|[^'])*'")
    if empty(c)
        call self.throw('unmatchp', "'")
    endif
    call self.removestr(len(c))
    return substitute(c[:-2], "''", "'", 'g')
endfunction
"▶1 readreg    :: endstr + self → String + self(s)
" Gets the next regular expression. {endstr} determines border character
" {reg} :: ( "\" . | ! "\" {endstr} ) {endstr}
" {endstr} :: {char} \ {wordchar}
function s:parser.readreg(endstr)
    if !empty(self.ungot)
        call self.throw('int', 'regungetc')
    endif
    if a:endstr=~#'\v^\w'
        call self.throw('wordend', a:endstr)
    endif
    let c=matchstr(self.s, '\v(\\.|[^\\'.escape(a:endstr, '\]^-').'])+'.
                \          '\V'.escape(a:endstr, '\'))
    if empty(c)
        call self.throw('unmatchp', a:endstr)
    endif
    call self.removestr(len(c))
    let c=c[:-2]
    try
        call matchstr('', c)
    catch
        call self.throw('invreg', c)
    endtry
    return c
endfunction
"▶1 readflt    :: () + self → String|0 + self(s)
"  {flt} :: ( "+" | "-" ) ( "nan" | "inf" | {unum} )
" {unum} :: {d}* "."? {d}* ( "e" ( "+" | "-" )? [0-9]+ )?
"    {d} :: [0-9] | "_"
function s:parser.readflt()
    if !empty(self.ungot)
        call self.ungotjoin()
    endif
    call self.delblanks()
    let c=matchstr(self.s,
                \'\v\c^[+-]? *%(nan|inf|[0-9_]*\.?[0-9_]*%(e[+-]?\d+)?)')
    call self.removestr(len(c))
    if empty(c)
        return 0
    endif
    return substitute(substitute(substitute(substitute(tolower(c),
                \'[_ ]',           '',     'g'),
                \'^[+-]\=\d\@!',   '&0',   '' ),
                \'\.\d\@!',        '.0',   '' ),
                \'\v^[+-]?\d+e@=', '&.0',  '' )
endfunction
"▶1 readexpr   :: () + self → String + self(s)
let s:parens={'(': ')', '[': ']', '{': '}'}
let s:revparens={}
call map(copy(s:parens), 'extend(s:revparens, {v:val : v:key})')
function s:parser.readexpr()
    if !empty(self.ungot)
        call self.throw('int', 'fltungetc')
    endif
    call self.delblanks()
    let c=''
    let parens=[]
    while !empty(self.s)
        let chunk=matchstr(self.s, '\v^.{-}[''[\](){}"]')
        let stopsym=''
        if empty(chunk)
            let chunk=self.s
        else
            let stopsym=chunk[-1:]
        endif
        if has_key(s:parens, stopsym)
            call add(parens, s:parens[stopsym])
        elseif has_key(s:revparens, stopsym)
            let close=''
            while !empty(parens) && parens[-1] isnot# stopsym
                let close.=remove(parens, -1)
            endwhile
            let c.=close
            if empty(parens)
                let chunk=chunk[:-2]
            else
                call remove(parens, -1)
            endif
        elseif stopsym is# '"'
            let string=matchstr(self.s, '\v(\\.|[^\\"])*"', len(chunk))
            if empty(string)
                call self.throw('unmatchp', '"')
            else
                let chunk.=string
            endif
        elseif stopsym is# "'"
            let string=matchstr(self.s, '\v(''''|[^''])*''', len(chunk))
            if empty(string)
                call self.throw('unmatchp', "'")
            else
                let chunk.=string
            endif
        endif
        call self.removestr(len(chunk))
        let c.=chunk
        if empty(parens)
            break
        endif
    endwhile
    let c.=join(parens, '')
    if empty(c)
        call self.throw('noexpr')
    endif
    return c
endfunction
"▶1 scanlist   :: F + self → self
" Scans a list of elements that looks either like "{e1}, {e2}", "({e1} {e2})" or 
" "({e1}, {e2})" (last two can be combined).
" Input: {<farg>} ( "," {<farg>} )*
"      | "(" ( {<farg>} ","? )* ")"?
" Output: context({<farg>}*)
function s:parser.scanlist(F)
    call self.addcon()
    if self.len
        let c=self.readc()
        if c is# '('
            while self.len
                let c=self.readc()
                if c is# ')'
                    break
                elseif c isnot# ','
                    call self.ungetc(c)
                    call call(a:F, [], self)
                endif
            endwhile
        else
            call self.ungetc(c)
            while self.len
                call call(a:F, [], self)
                if self.len
                    let c=self.readc()
                    if c isnot# ','
                        call self.ungetc(c)
                        break
                    endif
                endif
            endwhile
        endif
    endif
    return self.conclose()
endfunction
"▶1 intfunc    :: &self
" Gets pipe, func, argument or matcher that may accept one or more arguments. 
" Arguments are described in s:_r.FWC_intfuncs.{func}.args and have a form 
" [?][*]{aname}, where {aname} is a part of get* function name, ? determines 
" whether argument can be omitted (it really makes a difference only at the end 
" of the string), * says that string should be scanned for a list of arguments 
" with arbitrary length, not just for a single one
" Input: {funcname} [arguments]?
"        {funcname} :: {wordchar}+
" Output: context(intfunc, {funcname}[, contexts])
function s:parser.intfunc()
    let type=self.l[0]
    let func=self.readc()
    if !has_key(s:_r.FWC_intfuncs, func) "▶2
        call self.throw('ukfunc', func)
    endif                                "▲2
    call self.addcon('intfunc', func)
    let fargs=s:_r.FWC_intfuncs[func].args
    if type is# 'matcher'
        let fargs=fargs+['?one']
    endif
    for farg in fargs
        if farg[0] is# '?'
            let farg=farg[1:]
        elseif !self.len "▶2
            call self.throw('argmis', type.'.'.func)
        endif            "▲2
        if farg[0] is# '*'
            let farg=farg[1:]
            call self.scanlist(((farg[:2] is# 'get')?
                        \           (s:_r.FWC_intfuncs[func][farg]):
                        \           (self['get'.farg])))
        else
            call call(((farg[:2] is# 'get')?
                        \(s:_r.FWC_intfuncs[func][farg]):
                        \(self['get'.farg])), [], self)
        endif
        unlet farg
    endfor
    return self.conclose()
endfunction
"▶1 getarg     :: &self!
" Simple wrapper to scan()
function s:parser.getarg()
    return self.scan()
endfunction
"▶1 getone     :: &self!
" Consumes a word and adds 1 to context if next word is "1", otherwise adds 0. 
" If next word is "0", it is consumed.
" Input: ( "0" | "1" )?
" Output: add(0|1)
function s:parser.getone()
    if !self.len
        call self.add(0)
    else
        let c=self.readc()
        if c is# '1'
            call self.add(1)
        else
            call self.add(0)
            if c isnot# '0'
                call self.ungetc(c)
            endif
        endif
    endif
    return self
endfunction
"▶1 getstring  :: &self!
" Gets either a string or variable name
" Input: ( "$" {var} | {str} | {wordchar}+ )?
" Output: add({string}) | *getvar
function s:parser.getstring()
    if self.len
        let c=self.readc()
        if c is# '$'
            call self.getvar()
        elseif c is# '"'
            call self.add(self.readstr())
        elseif c is# "'"
            call self.add(self.readsstr())
        elseif c=~#'^\w'
            call self.add(c)
        else
            call self.add('')
            call self.ungetc(c)
        endif
    else
        call self.add('')
    endif
    return self
endfunction
"▶1 getpath    :: &self!
" Gets path specification:
" Input: [( "d" | "f" )] [ "r" ] [( "w" | "W" | "p" )] [ "x" ]
"        & ! ( "d" | ^ ) "r"
"        & ! ( "d" ) ( "w" | "W" | "p" )? "x"
" 1. "d" for directory and "f" for regular file, otherwise both may be accepted
" 2. "r" for readable file (not directory)
" 3. "w" for writeable file or directory (unless "f" is specified),
"    "W" for writeable file or directory (unless "f" is specified) or
"        non-existant file in writeable directory (unless "d" is specified),
"    "p" like "W", but also accepts any path that can be created (for example,
"        if you have directory /a and you can write to it, then path /a/b/c/d 
"        will be accepted),
" 4. "x" for executable file (not directory)
" Output: add({pathspec})
function s:parser.getpath()
    let c=self.readc()
    if c=~#'\v^[df]?r?[wWp]?x?$' && c!~#'\v^%(d%(.{,2}x|r)|r)'
        call self.add(c)
    else
        call self.add('r')
        call self.ungetc(c)
    endif
    return self
endfunction
"▶1 getsubscr  :: &self!
" Input: ( "." ( ":" {n} {n} | {subscript} ) )*
"        {subscript} :: {str}
"                     | [0-9] {wordchar}*
"                     | {wordchar}+
"                     | "$" {var}
"                     | {var}
"                {n} :: "-"? {wordchar}+
"                     | "$" {var}
"                     | {var}
" Output: add((String|Number|context(Number, Number))*)
function s:parser.getsubscr()
    let requiresdot=0
    while self.len
        let c=self.readc()
        if requiresdot
            let requiresdot=0
            if c isnot# '.'
                call self.ungetc(c)
                break
            endif
            continue
        elseif c=~#'^\d'
            call self.add(+c)
        elseif c=~#'^\w'
            call self.add(c)
        elseif c is# '-'
            call self.add(-self.getc())
        elseif c is# '"'
            call self.add(self.readstr())
        elseif c is# "'"
            call self.add(self.readsstr())
        elseif c is# ':'
            call self.addcon()
            " Start and end subscripts
            for i in range(0, 1)
                let v=self.readc()
                if v is# '-'
                    call self.add(+v.(self.readc()))
                elseif v=~#'^\d'
                    call self.add(+v)
                elseif v is# '$'
                    call self.getvar()
                else
                    call self.ungetc(v)
                    call self.getvar()
                endif
            endfor
            call self.conclose()
        elseif c is# '$'
            call self.addcon()
            call self.getvar()
            call self.conclose()
        else
            call self.addcon()
            call self.ungetc(c)
            call self.getvar()
            call self.conclose()
        endif
        let requiresdot=1
    endwhile
    return self
endfunction
"▶1 getddescr  :: &self
" Gets dictionary description:
" Input: "{" ({keydescr} {arg})* "}"
"        {keydescr} :: {str}
"                    | "/" {reg}(endstr=/)
"                    | "?" {arg}
"                    | "*" {func}
"                    | "=" {expr}
"                    | "-"
"                    | {wordchar}+
" Output: context(ddescr, {keycon}*)
"         {keycon} :: context(eq,    String, {arg})
"                   | context(regex, String, {arg})
"                   | context(check, {arg},  {arg})
"                   | context(func,  {func}, {arg})
"                   | context(expr,  {expr}, {arg})
"                   | context(any,           {arg})
function s:parser.getddescr()
    call self.addcon('ddescr')
    if self.len
        let c=self.readc()
        if c isnot# '{'
            call self.ungetc(c)
        endif
        let prevlen=-1
        while self.len && self.len!=prevlen
            let prevlen=self.len
            let c=self.readc()
            if c is# '}'
                break
            elseif c is# '/'
                call self.addcon('regex', self.readreg('/'))
                call self.scan()
                call self.conclose()
            elseif c is# '*'
                call self.addcon('func')
                call self.getfunc()
                call self.scan()
                call self.conclose()
            elseif c is# '='
                call self.addcon('expr')
                call self.getexpr()
                call self.scan()
                call self.conclose()
            elseif c is# '?'
                call self.addcon('check')
                call self.scan()
                call self.scan()
                call self.conclose()
            elseif c is# '-'
                call self.addcon('any')
                call self.scan()
                call self.conclose()
            elseif c is# '"'
                call self.addcon('eq', self.readstr())
                call self.scan()
                call self.conclose()
            elseif c is# "'"
                call self.addcon('eq', self.readsstr())
                call self.scan()
                call self.conclose()
            elseif c=~#'^\w'
                call self.addcon('eq', c)
                call self.scan()
                call self.conclose()
            endif
        endwhile
    endif
    return self.conclose()
endfunction
"▶1 getreg     :: &self
" Gets regular expression
" Input: "$" {var}
"      | {startchar} {reg}(endchar={endchar})
"           {startchar} :: ! ( {wordchar} | "$" )
"             {endchar} :: pair({startchar}) | {startchar}
" Output: context(regex, {var}|String)
let s:pairs={
            \'(': ')',
            \'[': ']',
            \'{': '}',
            \'<': '>',
        \}
function s:parser.getreg()
    call self.addcon('regex')
    let c=self.readc()
    if c is# '$'
        call self.getvar()
    else
        call self.add(self.readreg(get(s:pairs, c, c)))
    endif
    return self.conclose()
endfunction
"▶1 getnumber  :: &self
" Get integer or floating point number (including ±inf and nan)
" Input: {flt}
"      | "$" {var}
"      | ""
" Output: context(inf, "+" | "-")
"       | context(nan)
"       | context(number, Number)
"       | context(float, Float)
"       | *getvar
function s:parser.getnumber()
    let f=self.readflt()
    if f is 0
        let c=self.readc()
        if c is# '$'
            return self.getvar()
        else
            call self.ungetc(c)
        endif
    elseif f[-3:] is# 'inf'
        let sign=f[0]
        if f[0] is# 'i'
            let sign='+'
        endif
        return self.addcon('inf', sign).conclose()
    elseif f is# 'nan'
        return self.addcon('nan').conclose()
    endif
    let r=eval(f)
    if type(r)==type(0)
        return self.addcon('number', r).conclose()
    else
        return self.addcon('float', r).conclose()
    endif
endfunction
"▶1 getexpr    :: &self
" Input: {expr}
" Output: context(expr, String)
function s:parser.getexpr()
    return self.addcon('expr', self.readexpr()).conclose()
endfunction
"▶1 getchvar   :: &self
" Input: ( ( "^"* ) | ( ">" | "<" )* ) ( "." {subscr} )?
" Output: context(argument, Number, {subscr}?)
"       | context(cur, UInt, {subscr}?)
function s:parser.getchvar()
    if self.len
        let c=self.readc()
        if c is# '<' || c is# '>'
            call self.addcon('argument', 0)
            call self.ungetc(c)
            while self.len
                let c=self.readc()
                if c is# '>'
                    let self.l[-1]+=1
                elseif c is# '<'
                    let self.l[-1]-=1
                else
                    break
                endif
            endwhile
        else
            call self.ungetc(c)
            call self.addcon('cur', 0)
            while self.len
                let c=self.readc()
                if c is# '^'
                    let self.l[-1]+=1
                else
                    break
                endif
            endwhile
        endif
        if c is# '.'
            call self.getsubscr()
        elseif self.len
            call self.ungetc(c)
        endif
    else
        call self.addcon('cur', 0)
    endif
    return self.conclose()
endfunction
"▶1 getlist    :: &self
" Input: ( "$" {var} | {str} | {wordchar}+ | {var} )* "]"?
" Output: context(list, ({var}|String)*)
function s:parser.getlist()
    call self.addcon('list')
    while self.len
        let c=self.readc()
        if c is# ']'
            break
        elseif c is# '$'
            call self.getvar()
        elseif c is# '"'
            call self.add(self.readstr())
        elseif c is# "'"
            call self.add(self.readsstr())
        elseif c=~#'^\w'
            call self.add(c)
        else
            call self.ungetc(c)
            call self.getvar()
        endif
    endwhile
    return self.conclose()
endfunction
"▶1 getvar     :: &self
" Input: {wordchar}+ {subscr}*
"      | "@" {chvar}
"      | "=" {expr}
"      | "[" {list}
"      | "$" {var}
"      | "*" {func}
"      | "(" {var} ")"
"      | {str}
" Output: context(plugvar, String, {subscr}*)
"       | {chvar}
"       | {expr}
"       | {list}
"       | context(evaluate, {var})
"       | context(string, String)
function s:parser.getvar()
    let c=self.readc()
    if c=~#'^\w'
        call self.addcon('plugvar')
        call self.ungetc(c)
        call self.getsubscr()
        call self.conclose()
    elseif c is# '@'
        return self.getchvar()
    elseif c is# '='
        return self.getexpr()
    elseif c is# '['
        call self.getlist()
    elseif c is# '*'
        call self.getfunc()
    elseif c is# '$'
        call self.addcon('evaluate')
        call self.getvar()
        call self.conclose()
    elseif c is# '"'
        call self.addcon('string', self.readstr())
        call self.conclose()
    elseif c is# "'"
        call self.addcon('string', self.readsstr())
        call self.conclose()
    elseif c is# '('
        call self.getvar()
        if self.readc() isnot# ')'
            call self.throw('unmatchp', '(')
        endif
    else
        call self.throw('invvar', c)
    endif
    return self
endfunction
"▶1 getfunc    :: &self
" Input: {var} ( "(" ( "." | {var} | "," )* ")"? )?
" Output: context(func, {var}, ({var}|context(this))*)
function s:parser.getfunc()
    call self.addcon('func')
    call self.getvar()
    if self.len
        let c=self.readc()
        if c is# '('
            while self.len
                let c=self.readc()
                if c is# ')'
                    break
                elseif c is# '.'
                    call self.addcon('this')
                    call self.conclose()
                elseif c isnot# ','
                    call self.ungetc(c)
                    call self.getvar()
                endif
            endwhile
        else
            call self.ungetc(c)
        endif
    endif
    return self.conclose()
endfunction
"▶1 getmatcher :: &self
" Input: {intfunc}
" Output: context(matcher, {intfunc})
function s:parser.getmatcher()
    return self.addcon('matcher').intfunc().conclose()
endfunction
"▶1 getomtchr  :: &self
" Input: ( "~" {intfunc} )?
" Output: context(matcher, {intfunc})?
function s:parser.getomtchr()
    if self.len
        let c=self.readc()
        if c is# '~'
            return self.getmatcher()
        endif
        return self.ungetc(c)
    endif
    return self
endfunction
"▶1 scanfie    :: contextName + self → self + self
" Input: {intfunc}
"      | "*" {func}
"      | "=" {expr}
" Output: context(<contextName>, {intfunc}|{func}|{expr})
function s:parser.scanfie(cname)
    call self.addcon(a:cname)
    let c=self.readc()
    if c is# '*'
        call self.getfunc()
    elseif c is# '='
        call self.getexpr()
    else
        call self.ungetc(c)
        call self.intfunc()
    endif
    return self.conclose()
endfunction
"▶1 scanmsg    :: &self
" Input: ( "#" | "^" | {wordchar}+ ( "(" ( [.%#] | {var} | "," ) ")"? )? )
" Output: context(msg, (String, {msgarg}* | 0 | 1))
"         {msgarg} :: context(curval)
"                   | context(curarg)
"                   | {var}
function s:parser.scanmsg()
    let c=self.readc()
    call self.addcon('msg', ((c is# '#')?(0):((c is# '^')?(1):(c))))
    if self.len
        let c=self.readc()
        if c is# '('
            while self.len
                let c=self.readc()
                if c is# ')'
                    break
                elseif c is# '.'
                    call self.addcon('curval')
                    call self.conclose()
                elseif c is# '%'
                    call self.addcon('curarg')
                    call self.conclose()
                elseif c is# '#'
                    call self.addcon('curidx')
                    call self.conclose()
                elseif c isnot# ','
                    call self.ungetc(c)
                    call self.getvar()
                endif
            endwhile
        else
            call self.ungetc(c)
        endif
    endif
    return self.conclose()
endfunction
"▶1 scan       :: &self
" Input: "[" {opt}  ⎫
"      | "{" {pref} ⎬ (only at toplevel or in context(action or optional))
"      | "<" {act}  ⎪
"      | "+" {arg}  ⎭
"      | ( ":" {var} )? ( | "(" ( "|" {pipe} | "#" {msg} | {intfunc} )* ")"?
"                         | ( "|" {pipe} | "#" {msg} )* {intfunc}? )
"        ⎺⎺⎺⎺⎺⎺\/⎺⎺⎺⎺⎺⎺
"           only in
"       context(optional)
" Output: {opt}                ⎫
"       | {pref}               ⎬ (only at toplevel or in context(action or
"       | {act}                ⎪                                 optional))
"       | context(next, {arg}) ⎭
"       | context(arg[, context(defval)], ({pipe}|{check}|{msg}|{intfunc})*)
"                    ⎺⎺⎺⎺⎺⎺⎺⎺⎺V⎺⎺⎺⎺⎺⎺⎺⎺⎺
"                          only in
"                     context(optional)
function s:parser.scan()
    "▶2 optional, prefixes, actions, next
    let c=self.readc()
    let type=get(self.l, 0, '')
    if !self.o.only && (type is# 'top' || type is# 'optional'
                \    || type is# 'action')
        if has_key(s:_r.FWC_topconstructs._chars, c)
            return call(s:_r.FWC_topconstructs[s:_r.FWC_topconstructs._chars[c]]
                        \.scan, [], self)
        endif
    endif
    "▲2
    call self.addcon('arg')
    "▶2 Default value
    if type is# 'optional' && c is# ':'
        call self.addcon('defval')
        call self.getvar()
        call self.conclose()
        let c=self.readc()
    endif
    "▶2 Define variables used to determine how to handle second word
    let accepttext=(type is# 'next' || self.o.only)
    let hasparen=0
    let hastext=0
    if c is# '('
        let hasparen=1
        let accepttext=1
    else
        call self.ungetc(c)
    endif
    "▲2
    let prevlen=-1
    while self.len && self.len!=prevlen
        let prevlen=self.len
        let c=self.readc()
        if c is# '|'
            call self.scanfie('pipe')
        elseif c is# '?'
            call self.scanfie('check')
        elseif c is# '#'
            call self.scanmsg()
        elseif (!hastext || accepttext) && c=~#'^\w'
            let hastext=1
            call self.ungetc(c)
            call self.intfunc()
            if !accepttext
                break
            endif
        elseif hasparen && c is# ')'
            break
        else
            call self.ungetc(c)
            break
        endif
    endwhile
    return self.conclose()
endfunction
"▶1 scanopts   :: &self
" Input: "-" "("? ( "no"? ( "only" | "recursive" | "onlystrings" ) )* ")"
" Output: add(<self.o>)
let s:options={'only': 0, 'recursive': 0, 'onlystrings': 0}
function s:parser.scanopts()
    let self.o=copy(s:options)
    call self.add(self.o)
    let hasparen=0
    let hasdash=0
    while self.len
        let c=self.readc()
        if hasdash
            if c is# '('
                let hasparen=1
            elseif has_key(self.o, c)
                let self.o[c]=1
                if !hasparen
                    let hasdash=0
                endif
            elseif has_key(self.o, c[2:])
                let self.o[c[2:]]=0
                if !hasparen
                    let hasdash=0
                endif
            elseif hasparen && c is# ')'
                let hasparen=0
                let hasdash=0
            else
                call self.throw('uoption', c)
            endif
        elseif c is# '-'
            let hasdash=1
        else
            call self.ungetc(c)
            break
        endif
    endwhile
    if hasparen
        call self.throw('unmatchp', '(')
    endif
    return self
endfunction
"▶1 parsestr   :: String → SynTree
function s:F.parsestr(string)
    "▶2 Setup self
    let s   =   {    's': a:string,
                \ 'tree': ['top'],
                \'stack': [],
                \'ungot': [],
                \    'l': 0,
                \  'len': len(a:string),
                \}
    call extend(s, s:parser, 'error')
    " FIXME Redefine this function with more verbose one
    let s.throw=s:_f.throw
    call add(s.stack, s.tree)
    let s.l=s.stack[-1]
    "▲2
    call s.scanopts()
    if s.o.only
        call s.scan()
    else
        let prevlen=-1
        while s.len && s.len!=prevlen
            let prevlen=s.len
            call s.scan()
        endwhile
    endif
    return s.tree
endfunction
"▶1 Post resource
call s:_f.postresource('fwc_parser', s:F.parsestr)
"▶1
call frawor#Lockvar(s:, '')
" vim: fmr=▶,▲ sw=4 ts=4 sts=4 et tw=80
