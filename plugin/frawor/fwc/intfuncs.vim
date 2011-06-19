"▶1 Header
scriptencoding utf-8
execute frawor#Setup('0.0', {'@/resources': '0.0',
            \                '@/os':        '0.0'}, 1)
let s:r={}
let s:cf='CHECKFAILED'
let s:cfstr=string(s:cf)
let s:cfreg='\v^'.s:cf.'$'
"▲1
"Completion  -------------------------------------------------------------------
"▶1 Path
"▶2 getfiles
function s:F.getfiles(arglead, filter, forcefilter)
    let fragments=s:_r.os.path.split(a:arglead)
    let globstart=''
    if a:arglead[0] is# s:_r.os.sep
        let globstart=s:_r.os.sep
    endif
    if a:arglead[-1:] is# s:_r.os.sep && get(fragments, -1, 0) isnot# ''
        call add(fragments, '')
    endif
    while len(fragments)>1 && (fragments[0] is# '.' || fragments[0] is# '..')
        let globstart.=remove(fragments, 0).s:_r.os.sep
    endwhile
    let startswithdot = a:arglead[0] is# '.'
    if empty(fragments)
        call add(fragments, '')
    endif
    let files=s:F.recdownglob(globstart, fragments, len(fragments)-1)
    let r=files
    if !empty(a:filter)
        let newfiles=[]
        for f in files
            let file=s:_r.os.path.abspath(f)
            if s:_r.os.path.isdir(file) || eval(a:filter)
                call add(newfiles, f)
            endif
        endfor
        if !empty(newfiles) || a:forcefilter
            let r=newfiles
        endif
    endif
    if !startswithdot
        call map(r, 's:_r.os.path.join(filter(s:_r.os.path.split(v:val), '.
                    \                        '"v:val isnot# ''.''"))')
    endif
    call map(r, 's:_r.os.path.isdir(v:val)?(v:val.s:_r.os.sep):(v:val)')
    return r
endfunction
"▶2 recdownglob
function s:F.recdownglob(globstart, fragments, i)
    if a:i<0
        return []
    endif
    let dotfragment=(a:fragments[a:i] is# '.' || a:fragments[a:i] is# '..')
                \   && (a:i<len(a:fragments)-1)
    let glist=[]
    if dotfragment
        let dir=s:_r.os.path.join(a:fragments[:(a:i)])
        if s:_r.os.path.isdir(dir)
            let glist=[dir]
        endif
    else
        let curdir=a:globstart.
                    \    ((a:i)?
                    \       (s:_r.os.path.join(a:fragments[:(a:i-1)])):
                    \       (''))
        if s:_r.os.path.isdir(curdir)
            let fcur=a:fragments[a:i]
            let dircontents=s:_r.os.listdir(curdir)
            let glist=s:r.smart.matcher(dircontents, fcur, 2)
            if !empty(curdir)
                call map(glist, 's:_r.os.path.join(curdir, v:val)')
            endif
        endif
    endif
    if empty(glist)
        return s:F.recdownglob(a:globstart, a:fragments, a:i-1)
    elseif a:i==len(a:fragments)-1
        return glist
    endif
    return s:F.recupglob(filter(glist, 's:_r.os.path.isdir(v:val)'),
                \        a:fragments, a:i+1)
endfunction
"▶2 recupglob
function s:F.recupglob(files, fragments, i)
    let dotfragment=(a:fragments[a:i] is# '.' || a:fragments[a:i] is# '..')
    let glist=[]
    if dotfragment
        let glist=[join(a:fragments[:(a:i)], s:g.plug.file.pathseparator)]
    endif
    let fcur=a:fragments[a:i]
    let directories={}
    "▶3 Variables for smartfilters
    let str=fcur
    let lowstr=tolower(fcur)
    let lstr=len(fcur)-1
    let estr=escape(fcur, '\')
    let reg='\V'.join(split(estr, '\v[[:punct:]]@<=|[[:punct:]]@='), '\.\*')
    let reg2='\V'.join(map(split(fcur,'\v\_.@='), 'escape(v:val,"\\")'), '\.\*')
    "▲3
    for filter in s:smartfilters
        for file in a:files
            let curdir=file
            if has_key(directories, curdir)
                let dircontents=directories[curdir]
            else
                let dircontents=s:_r.os.listdir(curdir)
                let directories[curdir]=dircontents
            endif
            let tmpglist=filter(copy(dircontents), filter)
            if !empty(tmpglist)
                if !empty(curdir)
                    call map(tmpglist, 's:_r.os.path.join(curdir, v:val)')
                endif
                let glist+=tmpglist
            endif
        endfor
        if !empty(glist)
            break
        endif
    endfor
    if a:i==len(a:fragments)-1 || empty(glist)
        return glist
    endif
    return s:F.recupglob(filter(glist, 's:_r.os.path.isdir(v:val)'),
                \        a:fragments, a:i+1)
endfunction
"▶1 getuserfunctions :: () → [[fname, fargs*]]
" TODO cache results
function s:F.getuserfunctions()
    redir => funlist
    silent function
    redir END
    return map(map(filter(split(funlist, "\n"), 'v:val[0] is# "f"'),
                \'split(v:val[9:-2], "(")'),
                \'[v:val[0]]+split(v:val[1], ", ")')
endfunction
"▶1 getinternalfunctions :: () + s:vimintfuncs → {fname: [length]}
function s:F.getinternalfunctions()
    if exists('s:vimintfuncs')
        return copy(s:vimintfuncs)
    endif
    let s:vimintfuncs={}
    let helpfile=s:_r.os.path.join($VIMRUNTIME, 'doc', 'eval.txt')
    if !filereadable(helpfile)
        return copy(s:vimintfuncs)
    endif
    let help=readfile(helpfile)
    let ruler=repeat('=', 78)
    let section=''
    while !empty(help)
        if remove(help, 0) is# ruler
            if remove(help, 0)[:19] is# '4. Builtin Functions'
                while !empty(help)
                    let line=remove(help, 0)
                    if empty(line) && !empty(s:vimintfuncs)
                        break
                    endif
                    let match=matchlist(line, '\v(\w+)\((.{-})\)')
                    if empty(match)
                        continue
                    endif
                    let fname=match[1]
                    let fargs=substitute(match[2], '\s', '', 'g')
                    let lengths=[]
                    if stridx(fargs, '...')!=-1
                        call add(lengths, -1)
                    endif
                    let bidx=stridx(fargs, '[')
                    if bidx!=-1
                        while bidx!=-1
                            call add(lengths, len(split(fargs[:(bidx)], ','))
                                        \                  +get(lengths, -1, 0))
                            let fargs=fargs[(bidx+1):]
                            let bidx=stridx(fargs, '[')
                        endwhile
                    else
                        call add(lengths, len(split(fargs, ',')))
                    endif
                    let s:vimintfuncs[fname]=lengths
                endwhile
                call filter(s:vimintfuncs, 'exists("*".v:key)')
                break
            endif
        endif
    endwhile
    lockvar s:vimintfuncs
    return copy(s:vimintfuncs)
endfunction
"▲1
"Filters/checkers --------------------------------------------------------------
"▶1 `func', `eval'
let s:r.func={'args': ['func'], 'breakscomp': 1}
" Checks whether result of running {func}({argument}) isn't 0
function s:r.func.check(desc, idx, type)
    return self['compile'.a:type](a:desc, a:idx, a:type)
endfunction
" Replaces {argument} with the result of running {func}({argument})
let s:r.func.pipe=s:r.func.check
" Replaces {argument} with the result of evaluating {expr}
" Checks whether result of running eval({expr}) isn't 0
let s:r.eval=copy(s:r.func)
let s:r.eval.args=['expr']
"▶1 `if'
" Processes argument if condition is met. Third argument describes the `else' 
" clause.
let s:r.if={'args': ['arg', 'arg', 'arg']}
function s:r.if.pipe(desc, idx, type)
    let condstr=self.getlvarid('cond')
    call self.try()
                \.pushms('throwignore')
                \.compilearg(a:desc[1], a:idx.'(cond)', 'check')
                \.popms()
                \.let(condstr, 1)
            \.up().catch(s:cfreg)
                \.let(condstr, 0)
            \.up()
    if len(a:desc[2])>1
        call self.addif(condstr).compilearg(a:desc[2], a:idx.'(if)', a:type)
                    \.up()
        if len(a:desc[3])>1
            call self.addif()
                        \.compilearg(a:desc[3], a:idx.'(else)', a:type)
                        \.up()
        endif
    else
        call self.addif('!'.condstr)
                    \.compilearg(a:desc[3], a:idx.'(else)', a:type)
                    \.up()
    endif
    return self.up()
endfunction
let s:r.if.complete=s:r.if.pipe
"▶1 `run'
" Replaces {argument} with the result of calling itself with {var} as argument 
" list
let s:r.run={'args': ['var']}
function s:r.run.pipe(desc, idx, type)
    let curargstr=self.argstr()
    call call(s:r.isfunc.check, [['isfunc', 0], a:idx, 'check'], self)
            \.try()
                \.let(curargstr, 'call('.curargstr.', '.
                \                                self.getvar(a:desc[1]).', {})')
            \.up().catch()
                \.addthrow('runfail', 1, a:idx, 'v:exception')
    let self.typechanged=1
    return self
endfunction
function s:r.run.complete(desc, idx, type)
    let getuserfunctionsstr=self.getfunstatvar('completers',
                \                              s:F.getuserfunctions,
                \                              'userfunctions').'()'
    let getintfuncsstr=self.getfunstatvar('completers',s:F.getinternalfunctions,
                \                         'vimfunctions').'()'
    if a:desc[1][0] is# 'list'
        " XXX a:desc[1] contains one more items then required, as well as output 
        " of getuserfunctions
        let ldescr=len(a:desc[1])
        return self.addmatches('map(filter('.getuserfunctionsstr.
                    \          ', "len(v:val)=='.ldescr.' || '.
                    \             '(len(v:val)<='.(ldescr+1).' && '.
                    \              'v:val[-1] is# ''...'')"), "v:val[0]")+'.
                    \          'sort(keys(filter('.getintfuncsstr.', '.
                    \                      '"index(v:val, '.(ldescr-1).')!=-1 '.
                    \                      '|| (v:val[0]==-1 && '.
                    \                          'v:val[-1]<='.(ldescr).')")))',
                    \          type([]))
    endif
    return self.addmatches('map('.getuserfunctionsstr.', "v:val[0]")', type([]))
endfunction
"▶1 `earg'
" Replaces {argument} with the result of evaluating itself
" TODO completion
let s:r.earg={'args': []}
function s:r.earg.pipe(desc, idx, type)
    let curargstr=self.argstr()
    call self.addtypecond([type('')], a:idx)
            \.try()
                \.let(curargstr, 'eval('.curargstr.')')
            \.up().catch()
                \.addthrow('evalfail', 1, a:idx, 'v:exception')
    let self.typechanged=1
    return self
endfunction
"▶1 `not'
let s:r.not={'args': ['arg'], 'breakscomp': 1}
"▶2 optimize
" XXX low-level hacks here
function s:r.not.optimize(idx, type)
    call self.down(self.l[1])
    let conditions=self.optgetconds()
    call self.up()
    if type(conditions)==type([])
        call remove(self.l, 0, -1)
        call self.add('if', 0, [])
        call self.nextthrow('!('.join(conditions, ' || ').')', 'notfail', a:idx)
        call remove(self.l, 1, 3)
    endif
    return self
endfunction
"▲2
function s:r.not.check(desc, idx, type)
    return self.try()
                \.pushms('throwignore')
                \.compilearg(a:desc[1], a:idx.'(not)', 'check')
                \.popms()
                \.throw("'NOTFAIL'")
            \.catch(s:cfreg).up()
            \.catch('\v^NOTFAIL$')
                \.addthrow('notfail', 1, a:idx)
endfunction
"▶1 `either'
" Checks whether {argument} matches one of given specifications
let s:r.either={'args': ['*arg']}
function s:r.either.check(desc, idx, type)
    let sucstr=self.getlvarid('succeeded')
    call self.let(sucstr, 1).addsavemsgs().pushms('throw')
    if !empty(a:desc[1])
        call self.try()
                    \.compilearg(a:desc[1][0], a:idx.'(either).0', 'check')
                \.up().catch(s:cfreg)
                    \.let(sucstr, 0).up()
    endif
    let i=1
    for arg in a:desc[1][1:]
        call self.addif('!'.sucstr)
                    \.let(sucstr, 1)
                    \.try()
                        \.compilearg(arg, a:idx.'(either).'.i, 'check')
                    \.up().catch(s:cfreg)
                        \.let(sucstr, 0)
                    \.up()
                \.up()
        let i+=1
    endfor
    call self.addif(sucstr).addrestmsgs().up().popms()
                \.addif().addthrow('eitherfail', 1, a:idx).up().up()
endfunction
function s:r.either.complete(desc, idx, type)
    let self.joinlists+=1
    let i=0
    for arg in a:desc[1]
        call self.compilearg(arg, a:idx.'(either).'.i, 'complete')
        let i+=1
    endfor
    let self.joinlists-=1
    call self.addjoinedmtchs()
    return self
endfunction
"▶1 `first'
" Same as `either', except for completion
let s:r.first=copy(s:r.either)
unlet s:r.first.complete
function s:r.first.complete(desc, idx, type)
    if !empty(a:desc[1])
        call self.compilearg(a:desc[1][0], a:idx.'(either).0', 'complete')
    endif
    let i=1
    for arg in a:desc[1][1:]
        call self.if('empty(@-@)')
                    \.compilearg(arg, a:idx.'(either).'.i, 'complete')
                \.up().endif()
        let i+=1
    endfor
    return self
endfunction
"▶1 `tuple'
let s:r.tuple={'args': ['*arg']}
"▶2 addtuple       :: tupledesc, idx, defaultArgType + self → self + self
function s:F.addtuple(tuple, idx, type)
    call add(self.subs, 0)
    for arg in a:tuple[1]
        call self.compilearg(arg, a:idx.'(tuple).'.self.subs[-1], a:type)
        call self.incsub()
    endfor
    call remove(self.subs, -1)
    return self
endfunction
"▲2
" Checks whether {argument} is a list with a fixed length and each element 
" matching given specification
function s:r.tuple.check(desc, idx, type)
    let curargstr=self.argstr()
    call self.addtypecond([type([])], a:idx)
                \.nextthrow('len('.curargstr.')!='.len(a:desc[1]),
                \           'invlstlen', a:idx, len(a:desc[1]),
                \                        'len('.curargstr.')')
    return call(s:F.addtuple, [a:desc, a:idx, a:type], self)
endfunction
" Checks whether {argument} is a list with a fixed length and then process given 
" pipes for each of the arguments
let s:r.tuple.pipe=s:r.tuple.check
"▶1 `list'
let s:r.list={'args': ['arg']}
"▶2 addlist        :: listdesc, idx, defaultArgType + self → self + self
function s:F.addlist(list, idx, type)
    let largstr=self.getlvarid('larg')
    let lststr=self.argstr()
    let istr=self.getlvarid('i')
    call add(self.subs, [istr])
    call     self.let(largstr, 'len('.lststr.')')
                \.let(istr, 0)
                \.while(istr.'<'.largstr)
                    \.compilearg(a:list[1], a:idx.'(list)', a:type)
                    \.increment(istr)
                \.up().up()
    call remove(self.subs, -1)
    return self
endfunction
"▲2
" Checks whether {argument} is a list where each item matches given 
" specification
function s:r.list.check(desc, idx, type)
    call self.addtypecond([type([])], a:idx)
    return call(s:F.addlist, [a:desc, a:idx, a:type], self)
endfunction
" Checks whether {argument} is a list and then filter each item using given 
" specification
let s:r.list.pipe=s:r.list.check
"▶1 `dict'
let s:r.dict={'args': ['get']}
"▶2 adddict        :: dicdesc, idx, type + self → self + self
function s:F.adddict(dic, idx, type)
    if len(a:dic[1])==1
        let curargstr=self.argstr()
        return self.nextthrow('!empty('.curargstr.')',
                    \         'keynmatch', a:idx, 'keys('.curargstr.')[0]')
    endif
    let keystr=self.getlvarid('key')
    call self.for(keystr, 'keys('.self.argstr().')')
    call add(self.subs, [keystr])
    let foundstr=self.getlvarid('found')
    let msglenstr=self.getlvarid('msglen')
    let pmsglenstr=self.getlvarid('pmsglen')
    let hascheck=0
    let i=-1
    for check in a:dic[1][1:]
        let i+=1
        if check[0] is# 'eq'
            call self.addif(keystr.' is# '.self.string(check[1]))
        elseif check[0] is# 'regex'
            call self.addif(keystr.'=~#'.self.string(check[1]))
        elseif check[0] is# 'func'
            call self.addif(self.getfunc(check[1], 0, keystr).' isnot 0')
        elseif check[0] is# 'expr'
            call self.addif(self.getexpr(check[1], keystr).' isnot 0')
        elseif check[0] is# 'any'
            call self.compilearg(check[1], a:idx.'.'.i.'(val)', a:type)
                        \.continue()
            break
        elseif check[0] is# 'check'
            if !hascheck
                call self.addsavemsgs()
            endif
            let hascheck=1
            call self.try()
                        \.pushms('throw')
                        \.let(foundstr, 0)
                        \.witharg([keystr])
                        \.compilearg(check[1], a:idx.'.'.i.'(key)', 'check')
                        \.without()
                        \.let(foundstr, 1)
                        \.compilearg(check[2], a:idx.'.'.i.'(val)', a:type)
                        \.popms()
                    \.up().catch(s:cfreg)
                        \.addif(foundstr)
                            \.fail()
                        \.addrestmsgs(1)
                    \.up().addif(foundstr)
                        \.continue().up()
            continue
        endif
        call self.compilearg(check[2], a:idx.'.'.i.'(val)', a:type).continue()
                    \.up()
    endfor
    if hascheck
        call remove(self.msgs.savevars, -1)
    endif
    call self.addthrow('keynmatch', 1, a:idx, keystr)
    call remove(self.subs, -1)
    return self
endfunction
"▶2 getddescr  :: &self
" Gets dictionary description:
" Input: "{" ({keydescr} {arg})* "}"
"        {keydescr} :: {str}
"                    | {wordchar}+
"                    | "/" {reg}(endstr=/)
"                    | "?" {arg}
"                    | "*" {func}
"                    | "=" {expr}
"                    | "-"
" Output: context(ddescr, {keycon}*)
"         {keycon} :: context(eq,    String, {arg})
"                   | context(regex, String, {arg})
"                   | context(check, {arg},  {arg})
"                   | context(func,  {func}, {arg})
"                   | context(expr,  {expr}, {arg})
"                   | context(any,           {arg})
function s:r.dict.get()
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
                call self.addcon('regex', self.readreg('/')).scan().conclose()
            elseif c is# '*'
                call self.addcon('func').getfunc().scan().conclose()
            elseif c is# '='
                call self.addcon('expr').getexpr().scan().conclose()
            elseif c is# '?'
                call self.addcon('check').scan().scan().conclose()
            elseif c is# '-'
                call self.addcon('any').scan().conclose()
            elseif c is# '"'
                call self.addcon('eq', self.readstr()).scan().conclose()
            elseif c is# "'"
                call self.addcon('eq', self.readsstr()).scan().conclose()
            elseif c=~#'^\w'
                call self.addcon('eq', c).scan().conclose()
            endif
        endwhile
    endif
    return self.conclose()
endfunction
"▲2
" Checks whether {argument} is a dictionary matching given {ddescr}
function s:r.dict.check(desc, idx, type)
    call self.addtypecond([type({})], a:idx)
    return call(s:F.adddict, [a:desc, a:idx, a:type], self)
endfunction
" Checks whether {argument} is a dictionary and transform it using given 
" {ddescr}
let s:r.dict.pipe=s:r.dict.check
"▶1 `in'
let s:r.in={'args': ['var', '?omtchr']}
" Checks whether {argument} is inside list {var}. Matcher is ignored
function s:r.in.check(desc, idx, type)
    return self.nextthrow('index('.self.getvar(a:desc[1]).', '.
                \                  self.argstr().')==-1',
                \         'ninlist', a:idx)
endfunction
" Picks up first element from {var}::List that matches {argument}. If {matcher} 
" is absent then {argument} may be of any type. In other case it should be 
" string.
function s:r.in.pipe(desc, idx, type, ...)
    let curargstr=self.argstr()
    if len(a:desc)==2 || (a:desc[2][1][0] is# 'intfunc' &&
                \         a:desc[2][1][1] is# 'exact' &&
                \         a:desc[2][1][2] is 0)
        return call(s:r[get(a:000, 0, 'in')].check, [a:desc, a:idx, a:type],
                    \self)
    else
        let matchstr=self.getlvarid('match')
        return self.addtypecond([type('')], a:idx)
                    \.let(matchstr, self.getmatcher(a:desc[2],
                    \                               self.getvar(a:desc[1]),
                    \                               curargstr, 0))
                    \.nextthrow(matchstr.' is 0',
                    \           'nmatch', a:idx, curargstr)
                    \.let(curargstr, matchstr)
    endif
endfunction
function s:r.in.complete(desc, idx, type)
    return self.addmatches(self.getvar(a:desc[1]), type([]))
endfunction
"▶1 `key'
let s:r.key={'args': ['var', '?omtchr']}
" Checks whether {argument} is a key of {var}. Matcher is ignored
function s:r.key.check(desc, idx, type)
    let curargstr=self.argstr()
    return self.addtypecond([type('')], a:idx)
                \.nextthrow('!has_key('.self.getvar(a:desc[1]).', '.
                \                       curargstr.')',
                \           'nindict', a:idx, curargstr)
endfunction
" Picks up first key from {var}::Dictionary that matches {argument}
function s:r.key.pipe(...)
    return call(s:r.in.pipe, a:000+['key'], self)
endfunction
function s:r.key.complete(desc, idx, type)
    return self.addmatches(self.getvar(a:desc[1]), type({}))
endfunction
"▶1 `take'
" Replaces {argument} with value of the first key from {var}::Dictionary that 
" matches {argument}
let s:r.take={'args': ['var', 'matcher'], 'stopscomp': 1}
function s:r.take.pipe(desc, idx, type)
    let curargstr=self.argstr()
    let varstr=self.getvar(a:desc[1])
    let matchstr=self.getlvarid('match')
    call self.addtypecond([type('')], a:idx)
                \.let(matchstr, self.getmatcher(a:desc[2], varstr,
                \                               curargstr, 0))
                \.nextthrow(matchstr.' is 0', 'nmatch', a:idx, curargstr)
                \.let(curargstr, varstr.'['.matchstr.']')
    let self.typechanged=1
    return self
endfunction
let s:r.take.complete=s:r.key.complete
"▶1 `substitute'
" Runs substitute on {argument}
let s:r.substitute={'args': ['reg', 'string', 'string'], 'breakscomp': 1}
function s:r.substitute.pipe(desc, idx, type)
    let curargstr=self.argstr()
    return self.addtypecond([type('')], a:idx)
                \.let(curargstr, 'substitute('.curargstr.', '.
                \((type(a:desc[1][1])==type(''))?
                \       (self.string(a:desc[1][1])):
                \       (self.getvar(a:desc[1][1]))).', '.
                \join(map(a:desc[2:], 'self.getstring(v:val)'), ', ').')')
endfunction
"▶1 `haskey'
" Checks whether {argument} is a dictionary with given keys
let s:r.haskey={'args': ['*string']}
function s:r.haskey.check(desc, idx, type)
    call self.addtypecond([type({})], a:idx)
    if len(a:desc[1])>1
        let keys='['.join(map(copy(a:desc[1]),
                    \         'type(v:val)==type("")?'.
                    \               'self.string(v:val):'.
                    \               'self.getvar(v:val)'), ', ').']'
        let absentkeys='filter('.keys.', '.
                    \          string('!has_key('.self.argstr().', v:val)').')'
        return self.nextthrow('!empty('.absentkeys.')',
                    \         'keysmis', a:idx,
                    \                    'join('.absentkeys.', ", ")')
    elseif !empty(a:desc[1])
        let keystr=((type(a:desc[1][0])==type(''))?
                    \       (self.string(a:desc[1][0])):
                    \       (self.getvar(a:desc[1][0])))
        return self.nextthrow('!has_key('.self.argstr().', '.keystr.')',
                    \         'keymis', a:idx, keystr)
    endif
endfunction
"▶1 `range'
" Checks whether {argument} is in given range
let s:r.range={'args': ['number', 'number', '?one']}
function s:r.range.check(desc, idx, type)
    let curargstr=self.argstr()
    "▶2 Determine whether we accept floating-point values
    let acceptfloat=has('float') &&
                \(a:desc[3] || a:desc[1][0] is# 'float'
                \           || a:desc[2][0] is# 'float')
    if acceptfloat
        call self.addtypecond([type(0), type(0.0)], a:idx)
    else
        call self.addtypecond([type(0)], a:idx)
    endif
    "▶2 Obtain range borders
    let range=map(a:desc[1:2],
                \'((v:val[0] is# "inf" || v:val[0] is# "nan")?'.
                \   '(""):'.
                \   '((v:val[0] is# "number"||v:val[0] is# "float")?'.
                \       '(v:val[1]):'.
                \       '(self.getvar(v:val))))')
    if type(range[0])!=type('') && type(range[1])!=type('') && range[0]>range[1]
        call reverse(range)
    endif
    "▶2 Construct condition
    let cond=''
    call map(range, '((type(v:val)=='.type('').')?'.
                \               '(v:val):'.
                \               '(string(v:val)))')
    if range[0] isnot# ''
        let cond.=range[0].'>'.curargstr
    endif
    if range[1] isnot# ''
        if !empty(cond)
            let cond.=' || '
        endif
        let cond.=curargstr.'>'.range[1]
    endif
    "▶2 Add condition to result
    if !empty(cond)
        call self.nextthrow(cond, 'nrange', a:idx,
                    \                       'string('.curargstr.')',
                    \                       'string('.range[0].')',
                    \                       'string('.range[1].')')
    endif
    "▲2
    return self
endfunction
"▶1 `match'
" Checks whether {argument} is a string that matches {reg}
let s:r.match={'args': ['reg']}
function s:r.match.check(desc, idx, type)
    let regex=((type(a:desc[1][1])==type(''))?
                \(self.string(a:desc[1][1])):
                \(self.getvar(a:desc[1][1])))
    let curargstr=self.argstr()
    return self.addtypecond([type('')], a:idx)
                \.nextthrow(curargstr.'!~#'.regex,
                \           'nregmatch', a:idx, curargstr, regex)
endfunction
"▶1 `path'
" Checks whether {argument} is a path matching given specification
let s:r.path={'args': ['get']}
"▶2 inwpath    :: path → Bool
function s:r.path.inwpath(path)
    if s:_r.os.path.exists(a:path)
        return 0
    endif
    let components=s:_r.os.path.split(a:path)
    if empty(components)
        return filewritable('.')==2
    endif
    let curpath=remove(components, 0)
    for component in components
        let curpath=s:_r.os.path.join(curpath, component)
        if filewritable(curpath)==2
            return 1
        elseif s:_r.os.path.exists(curpath)
            return 0
        endif
    endfor
    return 0
endfunction
"▶2 addpathp   :: idx + self → self + self
function s:r.path.addpathp(idx)
    let curargstr=self.argstr()
    let dirnamestr=self.getlvarid('dirname')
    let prevdirstr=self.getlvarid('prevdir')
    let foundstr=self.getlvarid('found')
    let normpathstr=self.getfunstatvar('os', s:_r.os.path.normpath, 'normpath')
    let existsstr=self.getfunstatvar('os', s:_r.os.path.exists, 'exists')
    let osdirnamestr=self.getfunstatvar('os', s:_r.os.path.dirname, 'dirname')
    call self.addif('!'.existsstr.'('.curargstr.')')
                \.let(dirnamestr, normpathstr.'('.curargstr.')')
                \.let(prevdirstr, '""')
                \.let(foundstr, 0)
                \.while(dirnamestr.' isnot# '.prevdirstr)
                    \.addif('filewritable('.dirnamestr.')==2')
                        \.let(foundstr, 1)
                        \.break().up()
                    \.addif(existsstr.'('.dirnamestr.')')
                        \.break().up()
                    \.let(prevdirstr, dirnamestr)
                    \.let(dirnamestr, osdirnamestr.'('.dirnamestr.')')
                \.up()
                \.nextthrow('!'.foundstr, 'nowrite', a:idx, curargstr)
            \.up().up()
    return self
endfunction
"▶2 getpath    :: &self!
" Gets path specification:
" Input: [df]? "r"? [wWp]? "x"?
"        & ! ( "d" | ^ ) "r"
"        & ! "d" [wWp]? "x"
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
function s:r.path.get()
    let c=self.readc()
    if c=~#'\v^[df]?r?[wWp]?x?$' && c!~#'\v^%(d%(.{,2}x|r)|r)'
        call self.add(c)
    else
        call self.add('r').ungetc(c)
    endif
    return self
endfunction
"▶2 check
function s:r.path.check(desc, idx, type)
    let curargstr=self.argstr()
    let existsstr=self.getfunstatvar('os', s:_r.os.path.exists, 'exists')
    let dirnamestr=self.getfunstatvar('os', s:_r.os.path.dirname, 'dirname')
    let isdirstr=self.getfunstatvar('os', s:_r.os.path.isdir, 'isdir')
    call self.addtypecond([type('')], a:idx)
    let spec=a:desc[1]
    if spec[0] is# 'd'
        let spec=spec[1:]
        if spec[0] is# 'w'
            call self.nextthrow('filewritable('.curargstr.')!=2',
                        \       'nwrite', a:idx, curargstr)
            let spec=spec[1:]
        elseif spec[0] is# 'W'
            call self.nextthrow('filewritable('.curargstr.')!=2 &&'.
                        \      '('.existsstr.'('.curargstr.')'.
                        \       '|| filewritable('.dirnamestr.'('.
                        \                                    curargstr.'))!=2)',
                        \      'nowrite', a:idx, curargstr)
            let spec=spec[1:]
        elseif spec[0] is# 'p'
            call call(s:r.path.addpathp, [a:idx], self)
                        \.nextthrow('!'.isdirstr.'('.curargstr.')',
                        \           'isdir', a:idx, curargstr)
            let spec=spec[1:]
        else
            call self.nextthrow('!'.isdirstr.'('.curargstr.')',
                        \       'isdir', a:idx, curargstr)
        endif
    else
        let fileonly=0
        if spec[0] is# 'f'
            let spec=spec[1:]
            let fileonly=1
        endif
        if fileonly
            if spec[0] is# 'r'
                call self.nextthrow('!filereadable('.curargstr.')',
                            \       'nread', a:idx, curargstr)
                let spec=spec[1:]
            elseif spec[-1:] isnot# 'x'
                call self.nextthrow(isdirstr.'('.curargstr.')',
                            \       'isfile', a:idx, curargstr)
            endif
        endif
        if spec[0] is# 'w'
            call self.nextthrow('!filewritable('.curargstr.')',
                        \       'nwrite', a:idx, curargstr)
            let spec=spec[1:]
        elseif spec[0] is# 'W'
            call self.nextthrow('!filewritable('.curargstr.') &&'.
                        \      '('.existsstr.'('.curargstr.')'.
                        \       '|| filewritable('.
                        \                     dirnamestr.'('.curargstr.'))!=2)',
                        \      'nowrite', a:idx, curargstr)
            let spec=spec[1:]
        elseif spec[0] is# 'p'
            call call(s:r.path.addpathp, [a:idx], self)
            let spec=spec[1:]
        endif
        if spec is# 'x'
            call self.nextthrow('!executable('.curargstr.')',
                        \       'nexecable', a:idx, curargstr)
        endif
    endif
    return self
endfunction
"▶2 complete
function s:r.path.complete(desc, idx, type)
    let spec=a:desc[1]
    let filter=''
    if spec[0] is# 'd'
        let spec=spec[1:]
        if spec[0] is# 'w'
            let filter='filewritable(file)==2'
            let spec=spec[1:]
        elseif spec[0] is# 'W'
            let filter='(filewritable(file)==2 || '.
                        \'(!s:_r.os.path.exists(file) && '.
                        \ 'filewritable(dirnamestr)==2))'
            let spec=spec[1:]
        elseif spec[0] is# 'p'
            let filter='(s:_r.os.path.exists(file)? '.
                        \   's:_r.os.path.isdir(file): '.
                        \   's:r.path.inwpath(file))'
            let spec=spec[1:]
        else
            let filter='s:_r.os.path.isdir(file)'
        endif
    else
        let fileonly=0
        if spec[0] is# 'f'
            let spec=spec[1:]
            let fileonly=1
        endif
        if fileonly
            if spec[0] is# 'r'
                let filter='filereadable(file)'
                let spec=spec[1:]
            elseif spec[-1:] isnot# 'x'
                " There is no way to exclude directories
            endif
        endif
        if spec[0] is# 'w'
            let filter='filewritable(file)'
            let spec=spec[1:]
        elseif spec[0] is# 'W'
            if !empty(filter)
                let filter.='? 1: '
            endif
            let filter.='(!s:_r.os.path.exists(file) && '.
                        \ 'filewritable(s:_r.os.path.dirname(file))==2)'
            let spec=spec[1:]
        elseif spec[0] is# 'p'
            if !empty(filter)
                let filter.='? 1: '
            endif
            let filter.='s:_r.os.path.inwpath(file)'
            let spec=spec[1:]
        endif
        if spec is# 'x'
            if !empty(filter)
                let filter='('.filter.') && '
            endif
            let filter.='executable(file)'
        endif
    endif
    let getfilesstr=self.getfunstatvar('completers', s:F.getfiles, 'path')
    return self.addmatches(getfilesstr.'('.self.comparg.', '.
                \                          self.string(filter).', 1)', type([]))
endfunction
"▶1 `type'
" Checks whether {argument} has one of given types
let s:r.type={'args': ['*get']}
"▶2 gettype    :: &self!
" Adds type number to the context.
" Valid arguments: string, number, float, dictionary, list, function
"                  "", '',  -0,     .0,       {},      [],     **
" Input: {typedescr}
" Output: add({typeNumber})
"         {typeNumber}: any number described in |type()|
let s:typechars={
            \'-': [type(0),   '0'],
            \'"': [type(""),  '"'],
            \"'": [type(''),  "'"],
            \'[': [type([]),  ']'],
            \'{': [type({}),  '}'],
            \'*': [2,         '*'],
        \}
let s:typewords={
            \    'number': type(0),
            \    'string': type(''),
            \      'list': type([]),
            \'dictionary': type({}),
            \  'function': 2,
        \}
if has('float')
    let s:typechars['.']=[type(0.0), '0']
    let s:typewords.float=type(0.0)
endif
function s:r.type.get()
    if !self.len
        call self.throw('typemis')
    endif
    let c=self.readc()
    if has_key(s:typechars, c)
        call self.add(s:typechars[c][0])
        if self.len
            let readchar=s:typechars[c][1]
            let c=self.readc()
            if c isnot# readchar
                call self.ungetc(c)
            endif
        endif
    else
        let type=tolower(c)
        if !has_key(s:typewords, type)
            call self.throw('invtype', c)
        endif
        call self.add(s:typewords[type])
    endif
    return self
endfunction
"▲2
function s:r.type.check(desc, idx, type)
    return self.addtypecond(a:desc[1], a:idx)
endfunction
"▶1 `isfunc'
" Checks whether {argument} is a callable function reference. Additional 
" argument determines whether strings should not be accepted
let s:r.isfunc={'args': ['?one']}
function s:r.isfunc.check(desc, idx, type)
    let curargstr=self.argstr()
    let frefpref='string('.curargstr.')[10:11]'
    let frefpref2='string('.curargstr.')[10:14]'
    if a:desc[1]
        call self.addtypecond([2], a:idx)
        call self.nextthrow('!exists('.string('*'.curargstr).') ||'.
                    \                       frefpref .' is# "s:" ||'.
                    \                       frefpref2.' ==? "<SID>"',
                    \       'nfunc', a:idx,
                    \                'string('.curargstr.')[10:-3]')
    else
        call self.nextthrow('!((type('.curargstr.')==2 && '.
                    \         'exists('.string('*'.curargstr).')&&'.
                    \          frefpref .' isnot# "s:" && '.
                    \          frefpref2.'    !=? "<SID>") '.
                    \        '|| (type('.curargstr.')=='.type('').
                    \            '&& '.curargstr.'=~#'.
                    \             '''\v^%([sla]@!\w:%(\w|\.)+|'.
                    \                    '%(<SNR>|s@!\w:)?\w+)$'''.
                    \            '&& exists("*".'.curargstr.')))',
                    \       'nsfunc', a:idx, 'string('.curargstr.')')
    endif
    return self
endfunction
"▶1 `isreg'
" Checks whether {argument} is a valid regular expression
let s:r.isreg={'args': []}
function s:r.isreg.check(desc, idx, type)
    let curargstr=self.argstr()
    return self.addtypecond([type('')], a:idx)
                \.try().call('matchstr("", '.curargstr.')').up()
                \.catch().addthrow('nreg', 1, a:idx, curargstr, 'v:exception')
endfunction
"▶1 `bool'
let s:r.bool={'args': [], 'breakscomp': 1}
" Checks whether {argument} is either 0 or 1
function s:r.bool.check(desc, idx, type)
    let curargstr=self.argstr()
    if !has_key(self.vars, 'bool')
        let self.vars.bool=((self.o.onlystrings)?(['0', '1']):([0, 1]))
    endif
    return self.nextthrow('index(@%@.bool, '.curargstr.')==-1',
                \         'nbool', a:idx, 'string('.curargstr.')')
endfunction
" Transforms {argument} to 0 if it is empty and to 1 otherwise
function s:r.bool.pipe(desc, idx, type)
    let curargstr=self.argstr()
    let self.typechanged=1
    if self.o.onlystrings
        return self.let(curargstr, curargstr.'=~?''\v^%(1|yes|ok|true)$''')
    else
        return self.let(curargstr, '!empty('.curargstr.')')
    endif
endfunction
"▶1 `is'
" Checks whether {argument} is {var}
let s:r.is={'args': ['var'], 'breakscomp': 1}
function s:r.is.check(desc, idx, type)
    let var=self.getvar(a:desc[1])
    let curargstr=self.argstr()
    return self.nextthrow(curargstr.' isnot# '.var,
                \         'isnot', a:idx, var, 'string('.curargstr.')')
endfunction
"▶1 `value'
" Overrides current value
let s:r.value={'args': ['var', 'arg']}
function s:r.value.check(desc, idx, type)
    call self.witharg(self.getvar(a:desc[1], 1))
                \.compilearg(a:desc[2], a:idx.'(value)', a:type)
                \.without()
endfunction
"▶1 `any', `_'
" Unconditionally accepts {argument}
let s:r.any={'args': []}
function s:r.any.check(...)
    return self
endfunction
let s:r._=s:r.any
"▲1
"Matchers ----------------------------------------------------------------------
"▶1 `func'
" Uses some other function as matcher. Function must accept a String (dot 
" argument, can be overriden by explicitely supplying a list of arguments) and 
" return a list of strings. Additional argument determines what should be done 
" if function returns list with more then one item
function s:r.func.matcher(ld, str, variants, acceptfirst)
    if a:acceptfirst is 2
        return a:variants
    elseif a:acceptfirst || len(a:variants)==1
        return a:variants[0]
    else
        return 0
    endif
endfunction
"▶1 `exact'
" Requires exact match. First additional argument determines whether match 
" should be done case-insensitively, second determines whether ambigious matches 
" should be accepted (only used if first argument is true)
let s:r.exact={'args': ['?one']}
function s:r.exact.matcher(ld, str, ignorecase, acceptfirst)
    if type(a:ld)==type({})
        if has_key(a:ld, a:str)
            return ((a:acceptfirst is 2)?([a:str]):(a:str))
        elseif a:ignorecase
            let list=sort(keys(a:ld))
        else
            return ((a:acceptfirst is 2)?([]):(0))
        endif
    else
        if index(a:ld, a:str)!=-1
            return ((a:acceptfirst is 2)?([a:str]):(a:str))
        elseif a:ignorecase
            let list=filter(copy(a:ld), 'type(v:val)=='.type(''))
        else
            return ((a:acceptfirst is 2)?([]):(0))
        endif
    endif
    let idx=index(list, a:str, 0, 1)
    if idx==-1
        return ((a:acceptfirst is 2)?([]):(0))
    elseif a:acceptfirst is 2
        let r=[list[idx]]
        while 1
            let idx=index(list, a:str, idx+1, 1)
            if idx==-1
                break
            else
                call add(r, list[idx])
            endif
        endwhile
        return r
    elseif a:acceptfirst
        return list[idx]
    else
        return ((index(list, a:str, idx+1, 1)==-1)?(list[idx]):(0))
    endif
endfunction
"▶1 `start'
" Requires match at the start of string. First optional arguments determines 
" case sensitivity, second determines whether ambigious matches should be 
" accepted (in this case first match in sorted list will be taken)
let s:r.start={'args': ['?one']}
function s:r.start.matcher(ld, str, ignorecase, acceptfirst)
    if type(a:ld)==type({})
        if has_key(a:ld, a:str)
            return ((a:acceptfirst is 2)?([a:str]):(a:str))
        endif
        let list=sort(keys(a:ld))
    else
        if index(a:ld, a:str)!=-1
            return ((a:acceptfirst is 2)?([a:str]):(a:str))
        endif
        let list=filter(copy(a:ld), 'type(v:val)=='.type(''))
    endif
    let r=[]
    let lstr=len(a:str)-1
    for value in list
        if type(value)==type('')
            if ((a:ignorecase)?(value[:(lstr)]==?a:str):
                        \      (value[:(lstr)] is# a:str))
                if a:acceptfirst is 1
                    return value
                elseif empty(r)
                    call add(r, value)
                else
                    return ((a:acceptfirst is 2)?([]):(0))
                endif
            endif
        endif
        unlet value
    endfor
    return ((a:acceptfirst is 2)?(r):(get(r, 0, 0)))
endfunction
"▶1 `smart'
" `smart' matcher tries to gues what element is really ment. Additional argument 
" determines whether ambigious match should be accepted (in this case first 
" match in sorted list will be taken)
let s:r.smart={'args': []}
let s:smartfilters=[
            \'v:val==?str',
            \'v:val[:(lstr)] is# str',
            \'v:val[:(lstr)]==?str',
            \'stridx(v:val, str)!=-1',
            \'stridx(tolower(v:val), lowstr)!=-1',
            \'v:val=~#reg',
            \'v:val=~?reg',
            \'v:val=~#reg2',
            \'v:val=~?reg2',
            \]
function s:r.smart.matcher(ld, str, acceptfirst)
    if type(a:ld)==type({})
        if has_key(a:ld, a:str)
            return ((a:acceptfirst is 2)?([a:str]):(a:str))
        endif
        let list=sort(keys(a:ld))
    else
        if index(a:ld, a:str)!=-1
            return ((a:acceptfirst is 2)?([a:str]):(a:str))
        endif
        let list=filter(copy(a:ld), 'type(v:val)=='.type(''))
    endif
    let lowstr=tolower(a:str)
    let str=a:str
    let lstr=len(a:str)-1
    let estr=escape(a:str, '\')
    let reg='\V'.join(split(estr, '\v[[:punct:]]@<=|[[:punct:]]@='), '\.\*')
    let reg2='\V'.join(map(split(a:str,'\v\_.@='),'escape(v:val,"\\")'), '\.\*')
    for filter in s:smartfilters
        let r=filter(copy(list), filter)
        if !empty(r)
            if a:acceptfirst is 2
                return r
            elseif a:acceptfirst || len(r)==1
                return r[0]
            else
                return ((a:acceptfirst is 2)?([]):(0))
            endif
        endif
    endfor
    return ((a:acceptfirst is 2)?([]):(0))
endfunction
"▶1 Register resource
call s:_f.postresource('FWC_intfuncs', s:r, 1)
"▶1
call frawor#Lockvar(s:, '')
" vim: fmr=▶,▲ sw=4 ts=4 sts=4 et tw=80
