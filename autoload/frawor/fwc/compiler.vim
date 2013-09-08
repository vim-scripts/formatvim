"▶1 Header
scriptencoding utf-8
execute frawor#Setup('0.0', {'@/fwc/parser'       : '0.0',
            \                '@/fwc/constructor'  : '4.0',
            \                '@/fwc/intfuncs'     : '0.0',
            \                '@/fwc/topconstructs': '0.0',
            \                '@/resources'        : '0.0',})
let s:compiler={}
let s:cf='CHECKFAILED'
let s:cfstr=string(s:cf)
let s:cfreg='\v^'.s:cf.'$'
"▶1 Messages
let s:_messages={
            \   'notypes': 'Expected at least one type specification',
            \  'tooshort': 'Argument list is too short: '.
            \              'expected at least %u, but got %u',
            \   'toolong': 'Argument list is too long: '.
            \              'expected at most %u, but got %u',
            \    'invlen': 'Invalid arguments length: expected %u, but got %u',
            \ 'lennmatch': 'Failed to process all arguments: '.
            \              'processed %u out of %u',
            \   'FWCfail': 'Error while processing arguments of function %s '.
            \              'for plugin %s',
            \ 'ambprefix': 'Error while compiling FWC string: prefix `%s'' '.
            \              'already defined',
            \  'umatcher': 'Unknown matcher: %s',
            \    'ucheck': 'Unknown check: %s',
            \  'onlyforb': 'Cannot use {%s} section '.
            \              'when option `only'' is active',
        \}
call extend(s:_messages, map({
            \  'funcfail': 'custom function returned 0',
            \  'exprfail': 'custom expression returned 0',
            \ 'nostrings': 'strings are not allowed here',
            \ 'typesfail': 'invalid type: expected one of %s, but got %s',
            \  'typefail': 'invalid type: expected %s, but got %s',
            \     'nbool': 'invalid value: expected either 0 or 1, but got %s',
            \     'nfunc': 'function %s is not callable',
            \    'nsfunc': 'expected function name or '.
            \              'callable function reference, but got %s',
            \      'nreg': "string `%s' is not a valid regular expression (%s)",
            \ 'nregmatch': "string `%s' does not match regular expression `%s'",
            \   'keysmis': 'the following required keys are missing: %s',
            \    'keymis': 'key `%s'' is missing',
            \   'runfail': 'running argument failed with exception %s',
            \  'evalfail': 'evaluating argument failed with exception %s',
            \    'nrange': '%s is not in range [%s, %s]',
            \   'nindict': '%s is not in dictionary',
            \   'ninlist': 'argument is not in list',
            \ 'invlstlen': 'invalid list length: expected %u, but got %u',
            \'eitherfail': 'all alternatives failed',
            \      'nohl': 'unknown highlight group: %s',
            \     'nocmd': 'no such command: %s',
            \    'nofunc': 'no such function: %s',
            \     'noopt': 'no such option: %s',
            \   'noevent': 'event %s is not supported',
            \     'noaug': 'autocmd group %s is not defined',
            \    'nosign': 'unknown sign: %s',
            \     'novar': 'no such variable: %s',
            \     'isdir': 'not a directory: %s',
            \    'isfile': 'directories are not accepted: %s',
            \    'nwrite': '%s is not writable',
            \   'nowrite': '%s is neither writable nor '.
            \              'contained in a writable directory',
            \     'nread': '%s is not readable',
            \ 'nexecable': '%s is not executable',
            \ 'keynmatch': 'key `%s'' does not match any specification',
            \    'nmatch': 'no matches found for %s',
            \   'notfail': '`not'' check failed',
            \     'isnot': 'expected %s, but got %s',
            \       'anf': '`%s'' is not a valid action',
            \       'pnf': '`%s'' is not a valid prefix',
            \ 'noprefarg': 'missing %u prefix arguments',
            \ 'noreqpref': 'some required prefixes are missing',
        \}, '"Error while processing check %s for %s: ".v:val'))
let s:_messages._types=['number', 'string', 'function reference', 'list',
            \           'dictionary']
if has('float')
    call add(s:_messages._types, 'float')
endif
"▶1 cleanup         :: list::[_, {arg}*] → + list
function s:F.cleanup(list)
    if len(a:list)>1
        let args=remove(a:list, 1, -1)
        let sq={}
        call add(a:list, sq)
        for arg in args
            if !has_key(sq, arg[0])
                let sq[arg[0]]=[]
            endif
            if arg[0] is# 'actions' || arg[0] is# 'prefixes'
                if get(get(arg, 1, []), 0, '') is# 'matcher'
                    let sq[arg[0].'matcher']=remove(arg, 1)
                endif
                call extend(sq[arg[0]], filter(map(arg[1:], 'v:val[1:]'),
                            \                  '!empty(v:val)'))
            elseif arg[0] is# 'next'
                if len(arg[1:][0])>1
                    call add(sq[arg[0]], arg[1:][0][1:])
                endif
            elseif arg[0] is# 'optional'
                if len(arg)>1
                    call add(sq[arg[0]], arg)
                endif
            else
                if len(arg)>1
                    call add(sq[arg[0]], arg[1:])
                endif
            endif
        endfor
        call filter(sq, '!empty(v:val)')
        for key in filter(['actions', 'optional'], 'has_key(sq, v:val)')
            call map(sq[key], 's:F.cleanup(v:val)')
            call filter(sq[key], '!empty(v:val)')
            if empty(sq[key])
                call remove(sq, key)
            endif
        endfor
        if has_key(sq, 'optional')
            call map(sq.optional, 'v:val[1]')
        endif
    endif
    return a:list
endfunction
"▶1 getlenrange     :: adescr → (minlen, maxlen) + adescr
function s:F.getlenrange(adescr)
    let minimum=0
    let maximum=0
    "▶2 “arg” key
    if has_key(a:adescr, 'arg')
        let minimum=len(a:adescr.arg)
        let maximum=minimum
    endif
    "▶2 “optional” key
    if has_key(a:adescr, 'optional')
        let lenlist=map(copy(a:adescr.optional), 's:F.getlenrange(v:val)[1]')
        if index(lenlist, -1)!=-1
            let maximum=-1
        else
            let maximum+=max(lenlist)
        endif
    endif
    "▶2 “actions” key
    if has_key(a:adescr, 'actions')
        let minset=0
        let amin=0
        let amax=0
        let has0=0
        let hasa=0
        for action in a:adescr.actions
            if action[0] is 0
                let has0=1
            else
                let hasa=1
            endif
            if len(action)>1
                let [namin, namax]=s:F.getlenrange(action[-1])
                if namin<amin || !minset
                    let minset=1
                    let amin=namin
                endif
                if namax==-1
                    let maximum=-1
                elseif namax>amax
                    let amax=namax
                endif
            endif
        endfor
        let minimum+=((has0)?(0):(hasa))+amin
        if maximum!=-1
            let maximum+=hasa+amax
        endif
    endif
    "▶2 “prefixes” key
    if has_key(a:adescr, 'prefixes')
        let maximum=-1
        for prefopts in map(copy(a:adescr.prefixes), 'v:val[1]')
            let minimum+=((prefopts.opt)?
                        \   (0):
                        \   ((prefopts.list)?
                        \       (2):
                        \       (1+((prefopts.alt)?
                        \               (0):
                        \               (prefopts.argnum)))))
        endfor
    endif
    "▶2 “next” key
    if has_key(a:adescr, 'next')
        let maximum=-1
    endif
    "▲2
    let a:adescr.minimum=minimum
    let a:adescr.maximum=maximum
    return [minimum, maximum]
endfunction
"▶1 fail            :: &self
function s:compiler.fail()
    let msgstatus=self.msgs.statuses[-1]
    if msgstatus is# 'return'
        return self[self.failcal[0]](self.failcal[1])._up()
    else
        return self.throw(s:cfstr)
    endif
endfunction
"▶1 pushms          :: &self(msgstatus)
function s:compiler.pushms(status)
    call add(self.msgs.statuses, a:status)
    return self
endfunction
"▶1 popms           :: &self
function s:compiler.popms()
    call remove(self.msgs.statuses, -1)
    return self
endfunction
"▶1 witharg         :: &self((argbase[, [subscript]]))
function s:compiler.witharg(newarg)
    call add(self.preva, [self.argbase, self.subs])
    let self.argbase=a:newarg[0]
    let self.subs=get(a:newarg, 1, [])
    return self
endfunction
"▶1 without         :: &self
function s:compiler.without()
    let [self.argbase, self.subs]=remove(self.preva, -1)
    return self
endfunction
"▶1 incrementsub    :: subscript, incby → subscript
function s:F.incrementsub(sub, incby)
    if type(a:sub)==type(0)
        return a:sub+a:incby
    elseif type(a:sub)==type([]) && len(a:sub)==1
        let num=matchstr(a:sub[0], '[+-]\d\+$')
        return [printf('%s%+i', a:sub[0][:-1-len(num)],
                    \           str2nr(num)+a:incby)]
    endif
endfunction
"▶1 incsub          :: &self([incby])
function s:compiler.incsub(...)
    if empty(self.subs)
        return self
    else
        let self.subs[-1]=s:F.incrementsub(self.subs[-1], get(a:000, 0, 1))
    endif
    return self
endfunction
"▶1 argstr          :: [genString::Bool, [subscript]] + self → String
"▶2 addargchunk     :: chunks, chunk::String, literal::Bool → _ + chunks
function s:F.addargchunk(chunks, chunk, literal)
    if a:literal==(len(a:chunks)%2)
        call add(a:chunks, a:chunk)
    else
        let a:chunks[-1].=a:chunk
    endif
endfunction
"▶2 addstrsub       :: chunks, sub, self → _ + chunks
function s:F.addstrsub(chunks, sub, self)
    if type(a:sub)==type([])
        call s:F.addargchunk(a:chunks, 'string('.a:self.getvar(a:sub).')', 1)
    elseif type(a:sub)==type('')
        call s:F.addargchunk(a:chunks, 'string('.a:sub.')', 1)
    else
        call s:F.addargchunk(a:chunks, a:sub, 0)
    endif
endfunction
"▲2
function s:compiler.argstr(...)
    if get(a:000, 0, 0)
        let chunks=[self.argbase]
        for sub in get(a:000, 1, self.subs)
            let tsub=type(sub)
            if tsub==type('')
                if sub=~#'^\w\+$'
                    call s:F.addargchunk(chunks, '.'.sub, 0)
                else
                    call s:F.addargchunk(chunks, '['.self.string(sub).']', 0)
                endif
            elseif tsub==type(0)
                call s:F.addargchunk(chunks, '['.sub.']', 0)
            else
                call s:F.addargchunk(chunks, '[', 0)
                call s:F.addstrsub(chunks, sub[0], self)
                if len(sub)>1
                    call s:F.addargchunk(chunks, ':', 0)
                    call s:F.addstrsub(chunks, sub[1], self)
                endif
                call s:F.addargchunk(chunks, ']', 0)
            endif
            unlet sub
        endfor
        return join(map(chunks, 'v:key%2 ? v:val : self.string(v:val)'), '.')
    else
        return self.argbase.(self.getsubs(get(a:000, 1, self.subs)))
    endif
endfunction
"▶1 getsub          :: subscript → string
function s:compiler.getsub(subscript)
    return ((type(a:subscript)==type([]))?(a:subscript[0]):(a:subscript))
endfunction
"▶1 getsubs         :: [subscript] + self → String
function s:compiler.getsubs(subscripts)
    let r=''
    for sub in a:subscripts
        let tsub=type(sub)
        if tsub==type('')
            let r.=((sub=~#'\W')?('['.self.string(sub).']'):
                        \        ('.'.sub))
        elseif tsub==type(0)
            let r.='['.sub.']'
        elseif tsub==type([])
            let r.='['.join(map(copy(sub), 'type(v:val)=='.type([]).'?'.
                        \                       'self.getvar(v:val):'.
                        \                       'v:val'), ':').']'
        endif
        unlet sub
    endfor
    return r
endfunction
"▶1 getlastsub      :: () + self → String
function s:compiler.getlastsub()
    return self.getsub(self.subs[-1])
endfunction
"▶1 getfunstatvar   :: varname, varinit[, id] + self → varstr + self
function s:compiler.getfunstatvar(name, init, ...)
    if !has_key(self.vids, a:name)
        let self.vids[a:name]=0
        let self.vars[a:name]={}
    endif
    if a:0 && a:1!~#'\v^\x*$' && ((has_key(self.vars[a:name], a:1))?
                \                   (self.vars[a:name][a:1] is# a:init):
                \                   (1))
        let id=a:1
    else
        let id=printf('%x', self.vids[a:name])
        let self.vids[a:name]+=1
    endif
    let self.vars[a:name][id]=a:init
    return '@%@'.self.getsubs([a:name, id])
endfunction
"▶1 getfunc         :: funccontext, split[, addarg, ...] + self → String
function s:compiler.getfunc(func, split, ...)
    if a:split
        let r=[self.getvar(a:func[1])]
    else
        let r=self.getvar(a:func[1]).'('
    endif
    let args=[]
    let added000=0
    for arg in a:func[2:]
        if a:0 && arg[0] is# 'this'
            let args+=a:000
            let added000=1
        else
            call add(args, self.getvar(arg))
        endif
    endfor
    if a:0 && !added000
        let args+=a:000
    endif
    if a:split
        let r+=args
    else
        let r.=join(args, ', ').')'
    endif
    return r
endfunction
"▶1 getmatcher      :: matchercontext, ldstr, strstr, iscomp + self → String
function s:compiler.getmatcher(matcher, ldstr, strstr, iscomp)
    let mname=a:matcher[1][1]
    if !has_key(s:_r.FWC_intfuncs[mname], 'matcher')
        call s:_f.throw('umatcher', mname)
    endif
    let r=self.getfunstatvar('matchers', s:_r.FWC_intfuncs[mname].matcher,mname)
                \.'('.a:ldstr.', '.a:strstr
    if len(a:matcher[1])>3
        let curargstr=self.argstr()
        let r.=', '.join(map(a:matcher[1][2:-2],
                    \        'type(v:val)=='.type([]).'?'.
                    \           'self.getvar(v:val, 0, a:ldstr, a:strstr):'.
                    \           'self.string(v:val)'),
                    \    ', ')
    endif
    if a:iscomp
        let r.=', 2)'
    else
        let r.=', '.a:matcher[1][-1].')'
    endif
    return r
endfunction
"▶1 getexpr         :: exprcontext[, curstr] + self → String
function s:compiler.getexpr(expr, ...)
    let curargstr=self.argstr()
    let this=get(a:000, 0, curargstr)
    return substitute(substitute(substitute(a:expr[1],
                \'\V@@@', escape(self.argbase, '&~\'), 'g'),
                \'\V@.@', escape(this,         '&~\'), 'g'),
                \'\V@:@', escape(curargstr,    '&~\'), 'g')
endfunction
"▶1 getvar          :: varcontext[, splitsubs[, dotarg]] + self → String
function s:compiler.getvar(var, ...)
    let r=[]
    let splitsubs=get(a:000, 0, 0)
    if a:var[0] is# 'plugvar'
        let r=['@%@.p.'.a:var[1], a:var[2:]]
    elseif a:var[0] is# 'expr'
        let r=[self.getexpr(a:var)]
    elseif a:var[0] is# 'string'
        let r=[self.string(a:var[1])]
    elseif a:var[0] is# 'number'
        let r=[''.a:var[1]]
    elseif a:var[0] is# 'float'
        let r=[string(a:var[1])]
    elseif a:var[0] is# 'argument'
        let r=[self.argbase, [s:F.incrementsub(self.subs[0], a:var[1])]+
                    \        a:var[2:]]
    elseif a:var[0] is# 'cur'
        let r=[self.argbase, self.subs[:-1-a:var[1]]+a:var[2:]]
    elseif a:var[0] is# 'list'
        let r=['['.join(map(a:var[1:], 'type(v:val)=='.type('').'?'.
                    \                       'self.string(v:val):'.
                    \                       'self.getvar(v:val)'), ', ').']']
    elseif a:var[0] is# 'evaluate'
        let r=[eval(substitute(self.getvar(a:var[1]), '@%@', 'self.vars', 'g'))]
        if type(r[0])!=type('')
            let r[0]=self.string(r[0])
        endif
    elseif a:var[0] is# 'func'
        let r=[call(self.getfunc, [a:var, 0]+a:000[1:], self)]
    elseif a:var[0] is# 'this'
        let r=[self.argbase, self.subs]
    endif
    return ((splitsubs)?(r):(r[0].((len(r)>1)?(self.getsubs(r[1])):(''))))
endfunction
"▶1 getlvarid       :: varname + self → varname
function s:compiler.getlvarid(v)
    return printf('@$@%s%X', a:v, len(self._stack))
endfunction
"▶1 getulvarid      :: varname + self → varname
function s:compiler.getulvarid(v)
    let lvarid=printf('@$@%s%X', a:v, len(self._stack))
    let i=0
    while has_key(self.lvars, printf('%s_%X', lvarid, i))
        let i+=1
    endwhile
    let lvarid=printf('%s_%X', lvarid, i)
    let self.lvars[lvarid]=1
    return lvarid
endfunction
"▶1 getd            :: varname + self → varname + self
function s:compiler.getd(var)
    if !has_key(self.o, 'requiresd')
        let self.o.requiresd=1
    endif
    return self.getlvarid('d.'.a:var)
endfunction
"▶1 getlargsstr     :: () + self → varname + self
function s:compiler.getlargsstr()
    let key=string([self.argbase]+self.subs[:-2])[1:-2]
    if has_key(self.lavars, key)
        return self.lavars[key]
    else
        let largsstr=self.getlvarid('largs')
        call self.let(largsstr, 'len('.self.argstr(0, self.subs[:-2]).')')
        let self.lavars[key]=largsstr
        return largsstr
    endif
endfunction
"▶1 getstring       :: &self({string})
function s:compiler.getstring(str)
    if type(a:str)==type('')
        return self.string(a:str)
    endif
    return self.getvar(a:str)
endfunction
"▶1 getmatchstr     :: ldstr, exptype, varname + self → vimlexpr + self
function s:compiler.getmatchstr(ldstr, exptype, ldtmp)
    if a:exptype==type([])
        return 'copy('.a:ldstr.')'
    elseif a:exptype==type({})
        return 'sort(keys('.a:ldstr.'))'
    else
        call self.let(a:ldtmp, a:ldstr)
        return '((type('.a:ldtmp.')=='.type([]).')?'.
                    \'('.a:ldtmp.'):'.
                    \'(sort(keys('.a:ldtmp.'))))'
    endif
endfunction
"▶1 setmatches      :: &self(ldstr, exptype, filter)
function s:compiler.setmatches(ldstr, exptype, filter)
    if self.joinlists
        call add(self.ldstrs, [a:ldstr, a:exptype, a:filter])
        return self
    else
        let vstr=self.vstrs[-1]
        call add(self.vstinf[vstr], ['let', a:ldstr])
        call filter(self._l, '!(v:val[0] is# "let" && v:val[1] is# vstr)')
        if a:filter
            return self.let(vstr, self.getmatcher(self.matcher, a:ldstr,
                        \                         self.comparg, 1))
        else
            return self.let(vstr, self.getmatchstr(a:ldstr, a:exptype,
                        \                          self.getlvarid('curld')))
        endif
    endif
endfunction
"▶1 newvstr         :: idx + self → varname + self
function s:compiler.newvstr(idx)
    let vstr=self.getulvarid('matches_'.matchstr(a:idx, '\v\w+$'))
    call add(self.vstrs, vstr)
    call self.let(vstr, '[]')
    let self.vstinf[vstr]=[]
    return vstr
endfunction
"▶1 popvstr         :: &self
function s:compiler.popvstr()
    let vstr=self.vstrs[-1]
    call remove(self.vstrs, -1)
    if !empty(self.vstinf[vstr])
        call self.increment(self.vstrs[-1], vstr)
        call add(self.vstinf[self.vstrs[-1]], ['inc', vstr])
    endif
    unlet self.vstinf[vstr]
    return self
endfunction
"▶1 addjoinedmtchs  :: &self
function s:compiler.addjoinedmtchs()
    if !self.joinlists && !empty(self.ldstrs)
        let curldbase=self.getlvarid('curld').'_'
        let lststrs=map(remove(self.ldstrs, 0, -1),
                    \   'self.getmatchstr(v:val[0], v:val[1], curldbase.v:key)')
        call self.setmatches(join(lststrs, '+'), type([]), 1)
    endif
    return self
endfunction
"▶1 joinmatches     :: &self(idx, varname)
function s:compiler.joinmatches(jstart, matchesstr)
    if len(self.ldstrs)<=a:jstart
        return self
    endif
    let curldbase=self.getlvarid('curld').'_'
    call self.let(a:matchesstr,
                \ join(map(remove(self.ldstrs, a:jstart, -1),
                \          'self.getmatchstr(v:val[0], v:val[1], '.
                \                           'curldbase.v:key)'),
                \      '+'))
    call add(self.ldstrs, [a:matchesstr, type([])])
    return self
endfunction
"▶1 addthrow        :: &self(msg::String, msgarg, needcurarg, ...)
function s:compiler.addthrow(msg, needcurarg, ...)
    let args=self.string(a:msg).', '
    if a:needcurarg
        let args.=self.string(a:1).', '.self.argstr(1).', '.
                    \join(a:000[1:], ', ')
    else
        let args.=join(a:000, ', ')
    endif
    if !empty(self.msgs.own) && !empty(self.msgs.own[-1])
        let pargs=self.msgs.own[-1]
    endif
    let msgstatus=self.msgs.statuses[-1]
    if msgstatus is# 'return'
        if exists('pargs')
            call self.call('@%@.p._f.warn('.pargs.')')
        endif
        call self.call('@%@.F.warn('.args.')')
    elseif msgstatus is# 'throwignore' || self.type is# 'complete'
        " Ignore and fail
    elseif msgstatus is# 'throw'
        if exists('pargs')
            call self.call('add(@$@pmessages, ['.pargs.'])')
        endif
        call self.call('add(@$@messages, ['.args.'])')
    endif
    return self.fail()
endfunction
"▶1 nextthrow       :: &self(condition::expr, throwargs)
function s:compiler.nextthrow(cond, ...)
    return call(self.addif(a:cond).addthrow, [a:1, 1]+a:000[1:], self)
endfunction
"▶1 addsavemsgs     :: &self
function s:compiler.addsavemsgs()
    if self.msgs.statuses[-1] is# 'return' || self.type is# 'complete'
        call add(self.msgs.savevars, [0, 0])
        return self
    else
        let msglenstr=self.getlvarid('msglen')
        let pmsglenstr=self.getlvarid('pmsglen')
        call add(self.msgs.savevars, [msglenstr, pmsglenstr])
        return   self.let(msglenstr,  'len(@$@messages)')
                    \.let(pmsglenstr, 'len(@$@pmessages)')
    endif
endfunction
"▶1 addrestmsgs     :: &self(a:0::Bool)
function s:compiler.addrestmsgs(...)
    let [msglenstr, pmsglenstr]=self.msgs.savevars[-1]
    if !a:0
        call remove(self.msgs.savevars, -1)
    endif
    if self.type is# 'complete'
        return self
    endif
    return   self.if('len(@$@messages)>'.msglenstr)
                    \.call('remove(@$@messages, '.msglenstr.', -1)')
                \._up().if('len(@$@pmessages)>'.pmsglenstr)
                    \.call('remove(@$@pmessages, '.pmsglenstr.', -1)')
                \.endif()
endfunction
"▶1 addtypecond     :: &self(types, idx)
function s:compiler.addtypecond(types, idx)
    if self.o.onlystrings && self.argbase is# '@@@' && len(self.subs)==1
        if index(a:types, type(''))==-1
            call self.nextthrow(1, 'nostrings', a:idx)
        endif
        return self
    endif
    let curargstr=self.argstr()
    let typenames=map(copy(a:types), 's:_messages._types[v:val]')
    if len(a:types)>=2
        call self.nextthrow('index('.string(a:types).', '.
                    \            'type('.curargstr.'))==-1',
                    \       'typesfail', a:idx, string(join(typenames, '/')),
                    \                    '@%@.m.types[type('.curargstr.')]')
    elseif len(a:types)==1
        call self.nextthrow('type('.curargstr.')!='.a:types[0],
                    \       'typefail', a:idx, string(typenames[0]),
                    \                   '@%@.m.types[type('.curargstr.')]')
    else
        call s:_f.throw('notypes')
    endif
    return self
endfunction
"▶1 addlencheck     :: &self(minlen, maxlen)
function s:compiler.addlencheck(minimum, maximum)
    let largsstr=self.getlargsstr()
    let minimum=self.getsub(s:F.incrementsub(self.subs[-1], a:minimum))
    let maximum=self.getsub(s:F.incrementsub(self.subs[-1], a:maximum))
    if a:maximum==a:minimum
        call self.addif(largsstr.' isnot '.maximum)
        call        self.addthrow('invlen', 0, minimum, largsstr)
    else
        if a:minimum>0
            call self.addif(largsstr.'<'.minimum)
            call        self.addthrow('tooshort', 0, minimum, largsstr)
        endif
        if a:maximum!=-1
            call self.addif(largsstr.'>'.maximum)
            call        self.addthrow('toolong', 0,  maximum, largsstr)
        endif
    endif
    return self
endfunction
"▶1 optgetconds     :: () + self → Maybe [vimlexpr]
" Get a list of conditions from syntax tree that looks like this:
" {
"   {if cond1
"       throw 'CHECKFAILED'
"   elseif cond2
"       throw 'CHECKFAILED'
"   endif}
"   { XXX exactly one additional block here. It will be ignored }
" }
" For other syntax trees it will return 0.
function s:compiler.optgetconds()
    if len(self._l)==2
                \&& len(self._l[0])>2
                \&& self._l[0][0] is# 'if'
                \&& ((self._l[0][-1] is# 'endif'
                \  && self._l[0][-3] isnot# 'else')
                \ || (self._l[0][-2] isnot# 'else'))
        let conditions=[]
        let iftree=copy(self._l[0])
        while !empty(iftree)
            let type=remove(iftree, 0)
            if type is# 'if' || type is# 'elseif'
                let [condition, block]=remove(iftree, 0, 1)
                if block!=#[['throw', s:cfstr]]
                    return 0
                endif
                call add(conditions, condition)
            elseif type is# 'endif'
                break
            else
                return 0
            endif
        endwhile
        return conditions
    endif
    return 0
endfunction
"▶1 optimizecompf   :: &self(varname)
" XXX low-level hacks here
function s:compiler.optimizecompf(vstr)
    call self._down(self._l[2][-1][1])
    let conditions=self.optgetconds()
    call self._up()
    if type(conditions)==type([])
        call self._down(self._l[2])
        let argidxstr=self._l[-1][1][-1][1]
        let removestr=self._l[-1][-1][0][1]
        let condition=join(conditions, ' || ')
        let chargstr=a:vstr.'['.argidxstr.']'
        if condition=~#'\v^%([^@]|\V'.chargstr.'\v)+$'
            call self._up()
            call self._up()
            call remove(self._l, -2, -1)
            let condition=substitute(condition, '\V'.chargstr, 'v:val', 'g')
            call self.call('filter('.a:vstr.', '.string('!('.condition.')').')')
        else
            call remove(self._l, -1)
            call self.if(condition)
            call         self.call(removestr)
            call     self._up()
            call self.addelse()
            call         self.increment(argidxstr)
            call     self._up()
            call self._up()
            call self._up()
        endif
    endif
    return self
endfunction
"▶1 compilemsg      :: &self(msgcontext, idx, type)
function s:compiler.compilemsg(msg, idx, type)
    if a:type is# 'complete'
        return self
    endif
    if a:msg[1] is 0
        call add(self.msgs.own, '')
        return self
    elseif a:msg[1] is 1
        if !empty(self.msgs.own)
            call remove(self.msgs.own, -1)
        endif
        return self
    endif
    let msg=[]
    let curargstrstr=self.argstr(1)
    for msgarg in a:msg[2:]
        if msgarg[0] is# 'curval'
            call add(msg, self.argstr())
        elseif msgarg[0] is# 'curarg'
            call add(msg, curargstrstr)
        elseif msgarg[0] is# 'curidx'
            call add(msg, self.string(idx))
        else
            call add(msg, substitute(self.getvar(msgarg), '@#@',
                        \            escape(curargstrstr, '\&~'), 'g'))
        endif
    endfor
    let msgstr=self.string(a:msg[1]).', '.join(msg, ', ')
    call add(self.msgs.own, msgstr)
    return self
endfunction
"▶1 compilepipe     :: &self(pipecontext, idx, type)
function s:compiler.compilepipe(pipe, idx, type)
    "▶2 `func' pipe
    if a:pipe[1][0] is# 'func'
        let curargstr=self.argstr()
        if a:type is# 'check' || a:type is# 'pipe'
            call self.let(curargstr, self.getfunc(a:pipe[1],0, curargstr))
            let self.typechanged=1
        endif
    "▶2 `expr' pipe
    elseif a:pipe[1][0] is# 'expr'
        let curargstr=self.argstr()
        if a:type is# 'check' || a:type is# 'pipe'
            call self.let(curargstr, self.getexpr(a:pipe[1], curargstr))
            let self.typechanged=1
        endif
    "▶2 Built-in pipes
    elseif a:pipe[1][0] is# 'intfunc'
        let desc=a:pipe[1][1:]
        let dname=desc[0]
        if a:type is# 'check' || a:type is# 'pipe'
            if has_key(s:_r.FWC_intfuncs[dname], 'pipe')
                call call(s:_r.FWC_intfuncs[dname].pipe,  [desc,a:idx, 'pipe'],
                            \self)
            else
                call call(s:_r.FWC_intfuncs[dname].check, [desc,a:idx, 'pipe'],
                            \self)
            endif
        elseif has_key(s:_r.FWC_intfuncs[dname], 'complete')
            call call(s:_r.FWC_intfuncs[dname].complete, [desc, a:idx, 'pipe'],
                        \self)
        else
            return self
        endif
        if has_key(s:_r.FWC_intfuncs[dname], 'optimize')
            call call(s:_r.FWC_intfuncs[dname].optimize, [a:idx, a:type], self)
        endif
    endif
    "▲2
    return self
endfunction
"▶1 compilecheck    :: &self(checkcontext, idx, type)
function s:compiler.compilecheck(check, idx, type)
    "▶2 `func' check
    if a:check[1][0] is# 'func'
        if a:type is# 'check' || a:type is# 'pipe'
            call self.nextthrow(self.getfunc(a:check[1], 0, self.argstr()).
                        \                                               ' is 0',
                        \       'funcfail', a:idx)
        endif
    "▶2 `expr' check
    elseif a:check[1][0] is# 'expr'
        if a:type is# 'check' || a:type is# 'pipe'
            call self.nextthrow(self.getexpr(a:check[1], self.argstr()).' is 0',
                        \       'exprfail', a:idx)
        endif
    "▶2 Built-in checks
    else
        let desc=a:check[1][1:]
        let dname=desc[0]
        if a:type is# 'check' || a:type is# 'pipe'
            if !has_key(s:_r.FWC_intfuncs[dname], 'check')
                call s:_f.throw('ucheck', dname)
            endif
            call call(s:_r.FWC_intfuncs[dname].check, [desc, a:idx, 'check'],
                        \self)
        elseif has_key(s:_r.FWC_intfuncs[dname], 'complete')
            call call(s:_r.FWC_intfuncs[dname].complete, [desc, a:idx, 'check'],
                        \self)
        else
            return self
        endif
        if has_key(s:_r.FWC_intfuncs[dname], 'optimize')
            call call(s:_r.FWC_intfuncs[dname].optimize, [a:idx, a:type], self)
        endif
    endif
    "▲2
    return self
endfunction
"▶1 compilecomplete :: &self(completecontext, idx, type)
function s:compiler.compilecomplete(complete, idx, type)
    if a:type is# 'complete' && !(a:complete[1][0] is# 'func' ||
                \                 a:complete[1][0] is# 'expr')
        let desc=a:complete[1][1:]
        let dname=desc[0]
        if has_key(s:_r.FWC_intfuncs[dname], 'complete')
            call call(s:_r.FWC_intfuncs[dname].complete,
                        \[desc, a:idx, 'complete'], self)
        endif
    endif
    return self
endfunction
"▶1 compilearg      :: &self(argcontext, idx, type)
function s:compiler.compilearg(argcon, idx, type)
    "▶2 Define variables
    if a:argcon[0] is# 'arg'
        let arg=a:argcon[1:]
    else
        let arg=a:argcon
    endif
    let pmsgnum=len(self.msgs.own)
    let msg=[]
    let savedonlystrings=self.o.onlystrings
    "▶3 Variables useful only for completion
    if a:type is# 'complete'
        let addedcompletion=0
        let addedcycle=0
        let argidxstr=self.getlvarid('argidx')
        " Name of variable containing current matches
        let vstr=self.newvstr(a:idx)
        let jstart=len(self.ldstrs)
    endif
    "▲2
    let i=0
    for proc in arg
        let i+=1
        let compargs=[proc, a:idx.'.'.i, a:type]
        let comptype=proc[0]
        if comptype is# 'intfunc'
            let comptype=a:type
            let compargs[0]=[comptype, compargs[0]]
        elseif comptype is# 'defval'
            continue
        endif
        if a:type is# 'complete'
            if comptype is# 'msg'
                continue
            endif
            if addedcompletion
                if !addedcycle
                    let addedcycle=1
                    if self.joinlists
                        call self.joinmatches(jstart, vstr)
                    endif
                    call self.let(argidxstr, 0)
                    call        self.while(argidxstr.'<len('.vstr.')')
                    call            self.try()
                    call                self.pushms('throwignore')
                    call                self.witharg([vstr, [[argidxstr]]])
                endif
            elseif compargs[0][1][0] is# 'intfunc' &&
                        \has_key(s:_r.FWC_intfuncs[compargs[0][1][1]],
                        \        'breakscomp')
                break
            endif
            if addedcycle
                let comptype='check'
                let compargs[2]=comptype
            endif
        endif
        call call(self['compile'.comptype], compargs, self)
        if self.typechanged
            let self.o.onlystrings=0
            let self.typechanged=0
        endif
        if comptype is# 'complete'
            if compargs[0][1][0] is# 'intfunc' &&
                        \has_key(s:_r.FWC_intfuncs[compargs[0][1][1]],
                        \        'stopscomp')
                break
            endif
            let addedcompletion=1
        endif
    endfor
    let self.o.onlystrings=savedonlystrings
    if len(self.msgs.own)>pmsgnum
        call remove(self.msgs.own, pmsgnum, -1)
    endif
    if a:type is# 'complete'
        if addedcycle
            call self.without()
            call self.popms()
            call         self.increment(argidxstr)
            call     self._up()
            call self.catch(s:cfreg)
            call         self.call('remove('.vstr.', '.argidxstr.')')
            call self._up()
            call self._up()
            call self._up()
            call self.optimizecompf(vstr)
        endif
        call self.popvstr()
    endif
    return self
endfunction
"▶1 compadescr      :: &self(adescr, idx, type[, purgemax]])
function s:compiler.compadescr(adescr, idx, type, ...)
    let purgemax=get(a:000, 0, 0)
    if a:type is# 'complete'
        call self.newvstr(a:idx)
    endif
    try
        "▶2 Length checks, lagsstr and nextsub variables
        if !empty(self.subs)
            let largsstr=self.getlargsstr()
            if a:type is# 'check' || a:type is# 'pipe'
                if !has_key(a:adescr, 'minimum')
                    call s:F.getlenrange(a:adescr)
                endif
                if !has_key(a:adescr, 'checkedfor')
                    call self.addlencheck(a:adescr.minimum,
                                \         ((purgemax)?(-1):(a:adescr.maximum)))
                    let a:adescr.checkedfor=1
                endif
            endif
            let nextsub=copy(self.subs[-1])
        endif
        "▶2 `arg' key
        if has_key(a:adescr, 'arg')
            let i=0
            for arg in a:adescr.arg
                let i+=1
                if self.o.only
                    let idx=a:idx
                else
                    let idx=a:idx.'.'.i
                endif
                if a:type is# 'complete' && !self.o.only
                    call self.addif(largsstr.'-1 == '.self.getlastsub())
                endif
                call self.compilearg(arg, idx, a:type)
                call self.incsub()
                if a:type is# 'complete' && !self.o.only
                    call self._up()
                endif
                if self.onlyfirst
                    return self
                endif
            endfor
            if !empty(self.subs)
                unlet nextsub
                let nextsub=copy(self.subs[-1])
            endif
        endif
        "▶2 Quit if no more keys are present or if we are checking the only argument
        if empty(self.subs) || empty(a:adescr)
                    \|| empty(filter(copy(s:_r.FWC_topconstructs._order),
                    \         'has_key(a:adescr, v:val)'))
            return self
        endif
        "▲2
        let addedsavemsgs=0
        let caidxstr=self.getlvarid('caidx')
        let oldsub=self.getsub(nextsub)
        if oldsub isnot caidxstr
            call self.let(caidxstr, oldsub)
        endif
        let self.subs[-1]=[caidxstr]
        "▶2 Following keys (optional, prefixes, next, actions)
        for key in s:_r.FWC_topconstructs._order
            if has_key(a:adescr, key)
                if self.o.only && !get(s:_r.FWC_topconstructs[key], 'allowonly',
                            \          0)
                    call s:_f.throw('onlyforb', key)
                endif
                if a:type is# 'complete'
                    call self.newvstr(a:idx)
                endif
                let [newnextsub, addedsavemsgs]=
                            \call(s:_r.FWC_topconstructs[key].compile,
                            \     [a:adescr, a:idx, caidxstr, largsstr,
                            \      purgemax, a:type, nextsub, addedsavemsgs],
                            \     self)
                unlet nextsub
                let nextsub=newnextsub
                unlet newnextsub
                if a:type is# 'complete'
                    call self.popvstr()
                endif
            endif
        endfor
        "▶2 Check for processed argument length
        " XXX a:0 is checked here
        if !a:0 && type(self.subs[-1])==type([]) && a:type isnot 'complete'
            let largsstr=self.getlargsstr()
            let proclen=self.getlastsub()
            call self.addif(proclen.' isnot '.largsstr)
            call        self.addthrow('lennmatch', 0, proclen, largsstr)
        endif
        "▶2 addrestmsgs
        if addedsavemsgs
            call self.addrestmsgs()
        endif
        "▲2
        return self
    "▶2 popvstr
    finally
        if a:type is# 'complete'
            call self.popvstr()
        endif
    endtry
    "▲2
endfunction
"▶1 compstr         :: vars, String, type, doreturn → [String]
let s:defcompletematcher=['matcher', ['intfunc', 'smart', 2]]
function s:F.compstr(vars, string, type, doreturn)
    "▶2 Setup self
    let t=extend(s:_r.new_constructor(), {
                \   'type': a:type,
                \   'subs': [],
                \   'vars': a:vars,
                \  'lvars': {},
                \   'vids': {},
                \'argbase': '@@@',
                \  'preva': [],
                \   'msgs': {'savevars': [],
                \            'statuses': ['return'],
                \                 'own': [],
                \           },
                \'failcal': [],
                \ 'lavars': {},
                \'defvals': [],
                \'optdepth': 0,
                \'typechanged': 0,
                \'onlyfirst': 0,
            \})
    if t.type is# 'filter'
        let t.type='pipe'
    endif
    call extend(t, s:compiler, 'error')
    if !(t.type is# 'check' || t.type is# 'pipe')
        let t.matcher=s:defcompletematcher
        let t.comparg=t.argbase.t.getsubs([-1])
        let t.joinlists=0
        let t.ldstrs=[]
        let t.vstrs=['@-@']
        let t.vstinf={'@-@': []}
    endif
    "▲2
    let a:vars.F={'warn': s:_f.warn, 'throw': s:_f.throw}
    let a:vars.m={'types': s:_messages._types}
    let [t.o, tree]=s:F.cleanup(s:_r.fwc_parser(a:string)[1:])
    if a:doreturn is# 1
        let t.failcal=['return', 0]
    else
        let t.failcal=['call', '@%@.F.throw('.join(map(a:doreturn,
                    \                                  't.string(v:val)'),', ').
                    \                     ')']
    endif
    if !t.o.only
        call add(t.subs, 0)
    endif
    if t.type is# 'check' || t.type is# 'pipe'
        call t.let('@$@messages',  '[]')
        call t.let('@$@pmessages', '[]')
        call t.try()
        call t.compadescr(tree, '', t.type)
        call t._up()
        call t.finally()
        call     t.for('@$@targs', '@$@messages')
        call         t.call('call(@%@.F.warn, @$@targs, {})')
        call     t._up()
        call     t.for('@$@targs', '@$@pmessages')
        call         t.call('call(@%@.p._f.warn, @$@targs, {})')
        call     t._up()
        call t._up()
        call t._up()
    else
        call t.let('@-@', '[]')
        call t.compadescr(tree, '', t.type)
    endif
    if a:doreturn is# 1
        if t.type is# 'check'
            call t.return(1)
        elseif t.type is# 'pipe'
            call t.return('@@@')
        else
            call t.return('@-@')
        endif
    endif
    return [t.o, t._tolist()]
endfunction
"▶1 Register fwc_compile resource
call s:_f.postresource('fwc_compile', s:F.compstr)
"▶1
" TODO implement recursive structures checking
" TODO cache compilation results
call frawor#Lockvar(s:, '')
" vim: fmr=▶,▲ sw=4 ts=4 sts=4 et tw=80
