"▶1 Header
scriptencoding utf-8
execute frawor#Setup('0.4', {'@/resources': '0.0',
            \                '@/os':        '0.0',
            \                '@/signs':     '0.0',}, 1)
let s:r={}
let s:cf='CHECKFAILED'
let s:cfstr=string(s:cf)
let s:cfreg='\v^'.s:cf.'$'
let s:strfuncregstr='''\v^%([sla]@!\w:%(\w|\.)+|%(\V<SNR>\v|s@!\w:)?\w+)$'''
"▲1
"Completion  -------------------------------------------------------------------
"▶1 Path
"▶2 getfiles
function s:F.getfiles(arglead, filter, forcefilter)
    let path=expand(escape(a:arglead, '\[]*?'), 1)
    let fragments=s:_r.os.path.split(path)
    let globstart=''
    if path[0] is# s:_r.os.sep
        let globstart=s:_r.os.sep
    endif
    if path[-1:] is# s:_r.os.sep && get(fragments, -1, 0) isnot# ''
        call add(fragments, '')
    endif
    while len(fragments)>1 && (fragments[0] is# '.' || fragments[0] is# '..')
        let globstart.=remove(fragments, 0).s:_r.os.sep
    endwhile
    let startswithdot = path[0] is# '.'
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
"▶1 getfromhelp :: intvar, helpfroot, sectstr, init, Procline → ? + s:{intvar}
function s:F.getfromhelp(intvar, helpfile, sectstr, init, Procline)
    if has_key(s:, a:intvar)
        return copy(s:{a:intvar})
    endif
    let s:{a:intvar}=a:init
    let helpfile=s:_r.os.path.join($VIMRUNTIME, 'doc', a:helpfile.'.txt')
    if !filereadable(helpfile)
        return a:init
    endif
    let help=readfile(helpfile)
    let ruler=repeat('=', 78)
    let slen=len(a:sectstr)-1
    while !empty(help)
        if remove(help, 0) is# ruler
            if remove(help, 0)[:(slen)] is# a:sectstr
                while !empty(help)
                    let line=remove(help, 0)
                    let r=call(a:Procline, [line, s:{a:intvar}], {})
                    if r is 0
                        break
                    endif
                endwhile
                break
            endif
        endif
    endwhile
    lockvar! s:{a:intvar}
    return copy(s:{a:intvar})
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
function s:F.getintfunc(line, intfuncs)
    if empty(a:line) && !empty(a:intfuncs)
        return 0
    endif
    let match=matchlist(a:line, '\v(\w+)\((.{-})\)')
    if empty(match)
        return -1
    endif
    let fname=match[1]
    if !exists('*'.fname)
        return -1
    endif
    let fargs=substitute(match[2], '\s', '', 'g')
    let lengths=[]
    if stridx(fargs, '...')!=-1
        call add(lengths, -1)
    endif
    let bidx=stridx(fargs, '[')
    if bidx!=-1
        while bidx!=-1
            call add(lengths, len(split(fargs[:(bidx)], ','))+get(lengths,-1,0))
            let fargs=fargs[(bidx+1):]
            let bidx=stridx(fargs, '[')
        endwhile
    else
        call add(lengths, len(split(fargs, ',')))
    endif
    let a:intfuncs[fname]=lengths
    return 1
endfunction
function s:F.getinternalfunctions()
    return s:F.getfromhelp('vimintfuncs', 'eval', '4. Builtin Functions', {},
                \          s:F.getintfunc)
endfunction
"▶1 getusercommands :: () + :command → [String]
function s:F.getusercommands()
    redir => commands
    silent command
    redir END
    return map(split(commands, "\n")[1:], 'matchstr(v:val, "\\v\\w+")')
endfunction
"▶1 getinternalcommands :: () + s:vimintfuncs → [String]
function s:F.getintcmd(line, intcmds)
    if empty(a:line) && !empty(a:intcmds)
        return 0
    elseif a:line[:1] isnot# '|:'
        return -1
    endif
    let cmd=matchstr(a:line, '\v\s\:\S+')[2:]
    if !empty(cmd)
        let cmd=substitute(cmd, '\W', '', 'g')
        if exists(':'.cmd)
            call add(a:intcmds, cmd)
        endif
    endif
    return 1
endfunction
function s:F.getinternalcommands()
    return s:F.getfromhelp('vimintcommands', 'index', '5. EX commands', [],
                \          s:F.getintcmd)
endfunction
"▶1 getevents :: () + s:vimintfuncs → [String]
function s:F.getevent(line, events)
    if a:line[0] isnot# '|'
        return -1
    elseif a:line[-20:] is# '*autocmd-events-abc*'
        return 0
    endif
    let event=matchstr(a:line, '\v^\|\u\w+\|')[1:-2]
    if !empty(event) && exists('##'.event)
        call add(a:events, event)
    endif
    return 1
endfunction
function s:F.getevents()
    return s:F.getfromhelp('vimevents', 'autocmd', '5. Events', [],
                \          s:F.getevent)
endfunction
"▶1 getsigns :: () → [String]
function s:F.getsigns()
    if !has('signs')
        return []
    endif
    redir => signs
    silent sign list
    redir END
    return map(split(signs, "\n"), 'v:val[5:(stridx(v:val, " ", 5)-1)]')
endfunction
"▶1 getaugroups :: () → [String]
function s:F.getaugroups()
    if !has('autocmd')
        return []
    endif
    redir => augroups
    silent augroup
    redir END
    return split(split(augroups, "\n")[0])
endfunction
"▶1 gethighlights :: () → [String]
function s:F.gethighlights()
    if !has('syntax')
        return []
    endif
    redir => hls
    silent hi
    redir END
    return map(filter(split(hls, "\n"), 'v:val[0] isnot# " "'),
                \'v:val[:(stridx(v:val, " ")-1)]')
endfunction
"▶1 getoptions :: () + :set → [(String, 0|1|2)]
" 0: Boolean option
" 1: Number option
" 2: String option
function s:F.getoptions()
    if exists('s:vimoptions')
        return copy(s:vimoptions)
    endif
    redir => options
    silent set all
    redir END
    let s:vimoptions=[]
    let ismanyoptline=1
    for line in split(options, "\n")[1:]
        if ismanyoptline
            let addedoptions=0
            while !empty(line)
                let line=substitute(line, '\v^\s+', '', '')
                let option=''
                if line=~#'\v\l+\='
                    let option=line[:(stridx(line, '=')-1)]
                    let bool=0
                else
                    let option=matchstr(line, '\v^\l+')
                    if option[:1] is# 'no' && !exists('&'.option)
                        let option=option[2:]
                    endif
                    let bool=1
                endif
                if exists('+'.option)
                    let type=((bool)?(0):
                                \    ((type(eval('&'.option))==type(0))?(1):
                                \                                       (2)))
                    call add(s:vimoptions, [option, type])
                endif
                let line=substitute(line, '\v^\S+', '', '')
                let addedoptions+=1
            endwhile
            if addedoptions==1
                let ismanyoptline=0
            endif
        else
            let option=matchstr(line, '\v\l+')
            if exists('+'.option)
                let type=((type(eval('&'.option))==type(0))?(1):(2))
                call add(s:vimoptions, [option, type])
            endif
        endif
    endfor
    lockvar! s:vimoptions
    return copy(s:vimoptions)
endfunction
"▶1 compexpr :: () + ? → [String]
" TODO
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
    call        self.pushms('throwignore')
    call        self.compilearg(a:desc[1], a:idx.'(cond)', 'check')
    call        self.popms()
    call        self.let(condstr, 1)
    call    self._up()
    call    self.catch(s:cfreg)
    call        self.let(condstr, 0)
    call    self._up()
    if len(a:desc[2])>1
        call self.addif(condstr)
        call    self.compilearg(a:desc[2], a:idx.'(if)', a:type)
        call self._up()
        if len(a:desc[3])>1
            call self.addelse()
            call        self.compilearg(a:desc[3], a:idx.'(else)', a:type)
            call        self._up()
        endif
    else
        call self.addif('!'.condstr)
        call        self.compilearg(a:desc[3], a:idx.'(else)', a:type)
        call        self._up()
    endif
    return self._up()
endfunction
let s:r.if.complete=s:r.if.pipe
"▶1 `run'
" Replaces {argument} with the result of calling itself with {var} as argument 
" list
let s:r.run={'args': ['var']}
function s:r.run.pipe(desc, idx, type)
    let curargstr=self.argstr()
    call call(s:r.isfunc.check, [['isfunc', 0], a:idx, 'check'], self)
    call    self.try()
    call        self.let(curargstr, 'call('.curargstr.', '.
                \                                self.getvar(a:desc[1]).', {})')
    call    self._up()
    call    self.catch()
    call        self.addthrow('runfail', 1, a:idx, 'v:exception')
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
        return self.setmatches('map(filter('.getuserfunctionsstr.
                    \          ', "len(v:val)=='.ldescr.' || '.
                    \             '(len(v:val)<='.(ldescr+1).' && '.
                    \              'v:val[-1] is# ''...'')"), "v:val[0]")+'.
                    \          'sort(keys(filter('.getintfuncsstr.', '.
                    \                      '"index(v:val, '.(ldescr-1).')!=-1 '.
                    \                      '|| (v:val[0]==-1 && '.
                    \                          'v:val[-1]<='.(ldescr).')")))',
                    \          type([]), 1)
    endif
    return self.setmatches('map('.getuserfunctionsstr.', "v:val[0]")', type([]),
                \          1)
endfunction
"▶1 `earg'
" Replaces {argument} with the result of evaluating itself
" TODO completion
let s:r.earg={'args': []}
function s:r.earg.pipe(desc, idx, type)
    let curargstr=self.argstr()
    call self.addtypecond([type('')], a:idx)
    call self.try()
    call     self.let(curargstr, 'eval('.curargstr.')')
    call self._up()
    call self.catch()
    call     self.addthrow('evalfail', 1, a:idx, 'v:exception')
    let self.typechanged=1
    return self
endfunction
"▶1 `not'
let s:r.not={'args': ['arg'], 'breakscomp': 1}
"▶2 optimize
" XXX low-level hacks here
function s:r.not.optimize(idx, type)
    call self._down(self._l[1])
    let conditions=self.optgetconds()
    call self._up()
    if type(conditions)==type([])
        call remove(self._l, 0, -1)
        call self._add('if', 0, [])
        call self.nextthrow('!('.join(conditions, ' || ').')', 'notfail', a:idx)
        call remove(self._l, 1, 3)
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
            \.catch(s:cfreg)._up()
            \.catch('\v^NOTFAIL$')
                \.addthrow('notfail', 1, a:idx)
endfunction
"▶1 `either'
" Checks whether {argument} matches one of given specifications
let s:r.either={'args': ['*arg']}
function s:r.either.check(desc, idx, type)
    let sucstr=self.getlvarid('succeeded')
    call self.let(sucstr, 1)
    call self.addsavemsgs()
    call self.pushms('throw')
    if !empty(a:desc[1])
        call self.try()
        call        self.compilearg(a:desc[1][0], a:idx.'(either).0', 'check')
        call self._up()
        call self.catch(s:cfreg)
        call        self.let(sucstr, 0)
        call self._up()
    endif
    let i=1
    for arg in a:desc[1][1:]
        call self.addif('!'.sucstr)
        call        self.let(sucstr, 1)
        call        self.try()
        call            self.compilearg(arg, a:idx.'(either).'.i, 'check')
        call        self._up()
        call        self.catch(s:cfreg)
        call            self.let(sucstr, 0)
        call        self._up()
        call    self._up()
        let i+=1
    endfor
    call self.addif(sucstr)
    call self.addrestmsgs()
    call self._up()
    call self.popms()
    call self.addelse()
    call self.addthrow('eitherfail', 1, a:idx)
    call self._up()
    call self._up()
    return self
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
        call self.if('empty('.self.vstrs[-1].')')
        call        self.compilearg(arg, a:idx.'(either).'.i, 'complete')
        call self._up()
        call self.endif()
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
    call self.nextthrow('len('.curargstr.')!='.len(a:desc[1]),
                \       'invlstlen', a:idx, len(a:desc[1]),
                \                    'len('.curargstr.')')
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
    call self.let(largstr, 'len('.lststr.')')
    call self.let(istr, 0)
    call self.while(istr.'<'.largstr)
    call            self.compilearg(a:list[1], a:idx.'(list)', a:type)
    call            self.increment(istr)
    call self._up()
    call self._up()
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
    let hasany=0
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
            let hasany=1
            call self.compilearg(check[1], a:idx.'.'.i.'(val)', a:type)
            call self.continue()
            break
        elseif check[0] is# 'check'
            if !hascheck
                call self.addsavemsgs()
            endif
            let hascheck=1
            call self.try()
            call        self.pushms('throw')
            call        self.let(foundstr, 0)
            call        self.witharg([keystr])
            call        self.compilearg(check[1], a:idx.'.'.i.'(key)', 'check')
            call        self.without()
            call        self.let(foundstr, 1)
            call        self.compilearg(check[2], a:idx.'.'.i.'(val)', a:type)
            call        self.popms()
            call self._up()
            call self.catch(s:cfreg)
            call        self.addif(foundstr)
            call            self.fail()
            call        self.addrestmsgs(1)
            call self._up()
            call self.addif(foundstr)
            call        self.continue()
            continue
        endif
        call self.compilearg(check[2], a:idx.'.'.i.'(val)', a:type)
        call self.continue()
    endfor
    if hascheck
        call remove(self.msgs.savevars, -1)
    endif
    if !hasany
        call self.addthrow('keynmatch', 1, a:idx, keystr)
    endif
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
    return self.setmatches(self.getvar(a:desc[1]), type([]), 1)
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
    return self.setmatches(self.getvar(a:desc[1]), type({}), 1)
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
    call self.let(matchstr, self.getmatcher(a:desc[2], varstr, curargstr, 0))
    call self.nextthrow(matchstr.' is 0', 'nmatch', a:idx, curargstr)
    call self.let(curargstr, varstr.'['.matchstr.']')
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
"▶1 `idof'
" Check whether argument is an identifier
let s:r.idof={'args': ['get']}
let s:idab={
            \ 'var': 'variable',
            \  'hl': 'highlight',
            \ 'cmd': 'command',
            \'func': 'function',
            \ 'opt': 'option',
        \}
let s:ids=values(s:idab)+['event', 'augroup', 'sign']
"▶2 idof.get :: &self!
" Input: "variable"  | "var"
"      | "highlight" | "hl"
"      | "command"   | "cmd"
"      | "function"  | "func"
"      | "option"    | "opt"
"      | "event"
"      | "augroup"
"      | "sign"
" Output: add({idspec})
function s:r.idof.get()
    let c=self.readc()
    if has_key(s:idab, c)
        call self.add(s:idab[c])
    elseif index(s:ids, c)!=-1
        call self.add(c)
    else
        call self.throw('invid', c)
    endif
    return self
endfunction
"▶2 check
function s:r.idof.check(desc, idx, type)
    let curargstr=self.argstr()
    call self.addtypecond([type('')], a:idx)
    let spec=a:desc[1]
    if spec is# 'highlight'
        call self.nextthrow('!hlexists('.curargstr.')',
                    \       'nohl', a:idx, curargstr)
    elseif spec is# 'command'
        call self.nextthrow('!exists(":".'.curargstr.')',
                    \       'nocmd', a:idx, curargstr)
    elseif spec is# 'function'
        call self.nextthrow('!('.curargstr.'=~#'.s:strfuncregstr.
                    \        ' && exists("*".'.curargstr.'))',
                    \       'nofunc', a:idx, curargstr)
    elseif spec is# 'option'
        call self.nextthrow('!exists("+".'.curargstr.')',
                    \       'noopt', a:idx, curargstr)
    elseif spec is# 'event'
        call self.nextthrow('!exists("##".'.curargstr.')',
                    \       'noevent', a:idx, curargstr)
    elseif spec is# 'augroup'
        call self.nextthrow('stridx('.curargstr.', "#")!=-1 || '.
                    \       '!exists("#".'.curargstr.')',
                    \       'noaug', a:idx, curargstr)
    elseif spec is# 'sign'
        let signexistsstr=self.getfunstatvar('sign', s:_r.sign.exists, 'exists')
        call self.nextthrow('!'.signexistsstr.'('.curargstr.')',
                    \       'nosign', a:idx, curargstr)
    elseif spec is# 'variable'
        call self.nextthrow(curargstr.'!~#''\v^[als]@!\l\:\w*$'' || '.
                    \       '!exists('.curargstr.')',
                    \       'novar', a:idx, curargstr)
    endif
    return self
endfunction
"▶2 complete
let s:varsstr=join(map(split('vgbwt', '\v.@='),
            \          '"map(keys(".v:val.":), \"''".v:val.":''.v:val\")"'),
            \      '+')
let s:idofcompletes={'highlight': 1, 'event': 1, 'augroup': 1, 'sign': 1}
function s:r.idof.complete(desc, idx, type)
    let spec=a:desc[1]
    if has_key(s:idofcompletes, spec)
        let getvariantsstr=self.getfunstatvar('completers', s:F['get'.spec.'s'],
                    \                         spec.'s').'()'
        return self.setmatches(getvariantsstr, type([]), 1)
    elseif spec is# 'command'
        let intcmdsstr=self.getfunstatvar('completers', s:F.getinternalcommands,
                    \                     'commands').'()'
        let usercmdsstr=self.getfunstatvar('completers', s:F.getusercommands,
                    \                      'ucommands').'()'
        return self.setmatches(intcmdsstr.'+'.usercmdsstr, type([]), 1)
    elseif spec is# 'function'
        let userfunctionsstr='map('.self.getfunstatvar('completers',
                    \                                  s:F.getuserfunctions,
                    \                                  'userfunctions').'(), '.
                    \            '"v:val[0]")'
        let intfuncsstr='keys('.self.getfunstatvar('completers',
                    \                              s:F.getinternalfunctions,
                    \                              'vimfunctions').'())'
        return self.setmatches(userfunctionsstr.'+'.intfuncsstr, type([]), 1)
    elseif spec is# 'option'
        let intoptsstr='map('.self.getfunstatvar('completers', s:F.getoptions,
                    \                            'options').'(), "v:val[0]")'
        return self.setmatches(intoptsstr, type([]), 1)
    elseif spec is# 'variable'
        return self.setmatches(s:varsstr, type([]), 1)
    endif
endfunction
"▲2
"▶1 `range'
" Checks whether {argument} is in given range
let s:r.range={'args': ['number', 'number', '?one']}
function s:r.range.check(desc, idx, type)
    let curargstr=self.argstr()
    "▶2 Determine whether we accept floating-point values
    let acceptfloat=has('float') &&
                \(a:desc[3] || a:desc[1][0] is# 'float'
                \           || a:desc[2][0] is# 'float')
    if self.o.onlystrings
        if acceptfloat
            let astr='((stridx('.curargstr.', ".")==-1)?'.
                        \'(str2float('.curargstr.'):'.
                        \'(+('.   curargstr.'))))'
        else
            let astr='str2nr('.curargstr.')'
        endif
        if a:type is# 'pipe'
            call self.let(curargstr, astr)
        else
            let curargstr=astr
        endif
    else
        if acceptfloat
            call self.addtypecond([type(0), type(0.0)], a:idx)
        else
            call self.addtypecond([type(0)], a:idx)
        endif
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
        let r0=((range[0] is# '')?('"inf"'):(string(range[0])))
        let r1=((range[1] is# '')?('"inf"'):(string(range[1])))
        call self.nextthrow(cond, 'nrange', a:idx,
                    \                       'string('.curargstr.')',
                    \                       'string('.r0.')',
                    \                       'string('.r1.')')
    endif
    "▲2
    return self
endfunction
let s:r.range.pipe=s:r.range.check
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
    call        self.let(dirnamestr, normpathstr.'('.curargstr.')')
    call        self.let(prevdirstr, '""')
    call        self.let(foundstr, 0)
    call        self.while(dirnamestr.' isnot# '.prevdirstr)
    call            self.addif('filewritable('.dirnamestr.')==2')
    call                self.let(foundstr, 1)
    call                self.break()
    call            self.addif(existsstr.'('.dirnamestr.')')
    call                self.break()
    call            self.let(prevdirstr, dirnamestr)
    call            self.let(dirnamestr, osdirnamestr.'('.dirnamestr.')')
    call        self._up()
    call        self.nextthrow('!'.foundstr, 'nowrite', a:idx, curargstr)
    call self._up()
    call self._up()
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
        call self.add('r')
        call self.ungetc(c)
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
            call self.nextthrow('!'.isdirstr.'('.curargstr.')',
                        \       'isdir', a:idx, curargstr)
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
"▶2 pipe
function s:r.path.pipe(...)
    let curargstr=self.argstr()
    call self.let(curargstr, 'expand(escape('.curargstr.', "\\[]?*"), 1)')
    return call(s:r.path.check, a:000, self)
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
    return self.setmatches(getfilesstr.'('.self.comparg.', '.
                \                          self.string(filter).', 1)', type([]),
                \          0)
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
                    \            '&& '.curargstr.'=~#'.s:strfuncregstr.
                    \            '&& exists("*".'.curargstr.')))',
                    \       'nsfunc', a:idx, 'string('.curargstr.')')
    endif
    return self
endfunction
function s:r.isfunc.pipe(desc, idx, type)
    call call(s:r.isfunc.check, [a:desc, a:idx, a:type], self)
    if !a:desc[1]
        let curargstr=self.argstr()
        call self.let(curargstr,
                    \ '((type('.curargstr.')==2)?'.
                    \   '('.curargstr.'):'.
                    \ '((exists('.curargstr.'))?'.
                    \    '(eval('.curargstr.'))'.
                    \  ':'.
                    \    '(function('.curargstr.'))))')
    endif
    return self
endfunction
"▶1 `isreg'
" Checks whether {argument} is a valid regular expression
let s:r.isreg={'args': []}
function s:r.isreg.check(desc, idx, type)
    let curargstr=self.argstr()
    return self.addtypecond([type('')], a:idx)
                \.try().call('matchstr("", '.curargstr.')')._up()
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
    return self.witharg(self.getvar(a:desc[1], 1))
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
    if empty(a:ld)
        return []
    elseif type(a:ld)==type({})
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
