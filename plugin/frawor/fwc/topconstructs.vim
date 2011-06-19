"▶1 Header
scriptencoding utf-8
execute frawor#Setup('0.0', {'@/resources': '0.0'}, 1)
let s:r={}
let s:cf='CHECKFAILED'
let s:cfreg='\v^'.s:cf.'$'
let s:actdefmatcher=['matcher', ['intfunc', 'start', 0, 0]]
let s:prefdefmatcher=s:actdefmatcher
"▶1 addprefix :: preflist, prefix → _ + preflist
function s:F.addprefix(preflist, prefix)
    if index(a:preflist, a:prefix)!=-1
        call self._throw('ambprefix', a:prefix)
    endif
    call add(a:preflist, a:prefix)
endfunction
"▶1 hasnext   :: adescr, cursection → Bool
function s:F.hasnext(adescr, cursection)
    let sectidx=index(s:r._order, a:cursection)
    return !empty(filter(s:r._order[(sectidx+1):], 'has_key(a:adescr, v:val)'))
endfunction
"▶1 optional
let s:r.optional={'char': '['}
"▶2 scan
" Input: {arg}* "]"?
" Output: context(optional, {arg}*)
function s:r.optional.scan()
    call self.addcon('optional')
    let prevlen=-1
    while self.len && self.len!=prevlen
        let prevlen=self.len
        let c=self.readc()
        if c is# ']'
            break
        else
            call self.ungetc(c).scan()
        endif
    endwhile
    return self.conclose()
endfunction
"▶2 compile :: descr, idx, {rolvars}, {lvars} + self → {lvars}
" {rolvars} :: caidxstr, largsstr, purgemax, type
"   {lvars} :: nextsub, addedsavemsgs
function s:r.optional.compile(adescr, idx, caidxstr, largsstr, purgemax, type,
            \                 nextsub, addedsavemsgs)
    if a:type is# 'complete'
        let hasnext=s:F.hasnext(a:adescr, 'optional')
        if !hasnext && len(a:adescr.optional)==1
            call self.compadescr(a:adescr.optional[0], a:idx.'.0(optional)',
                        \        a:type, 0)
            let oldsub=self.getlastsub()
            if oldsub isnot# a:caidxstr
                call self.let(a:caidxstr, oldsub)
            endif
            return [[a:caidxstr], a:addedsavemsgs]
        else
            " XXX This implementation does not cover all cases. I won't fix this 
            " because it is too complicated.
            let failstr=self.getlvarid('fail')
            call self.let(failstr, 1)
            let i=0
            if hasnext
                for opt in a:adescr.optional
                    call self.if(failstr)
                                \.try()
                                    \.pushms('throwignore')
                                    \.compadescr(opt, a:idx.'.'.i.'(optional)',
                                    \            'check', 1)
                                    \.popms()
                                    \.let(failstr, 0)
                                    \.let(a:caidxstr, self.getlastsub())
                                \.catch(s:cfreg)
                            \.endif()
                    let self.subs[-1]=[a:caidxstr]
                    let i+=1
                endfor
                call self.if(failstr)
            endif
            let i=0
            for opt in a:adescr.optional
                let savedcaidxstr=self.getlvarid('savedcaidx')
                call self.let(savedcaidxstr, a:caidxstr)
                        \.compadescr(opt, a:idx.'.'.i.'(optional)', a:type, 0)
                        \.let(a:caidxstr, savedcaidxstr)
                let self.subs[-1]=[a:caidxstr]
                let i+=1
            endfor
            if hasnext
                call self.endif()
            endif
            return [[a:caidxstr], a:addedsavemsgs]
        endif
    endif
    let addedsavemsgs=a:addedsavemsgs
    " XXX nodefs will be still 1 when compiling next adescr. It is intentional.
    let nodefs=empty(self.defvals)
    let self.optdepth+=1
    let lopt=len(a:adescr.optional)
    if lopt>1
        let failstr=self.getlvarid('fail')
        call self.let(failstr, 1)
    endif
    let addedsavemsgs=1
    call self.addsavemsgs()
                \.try()
                    \.pushms('throw')
                    \.compadescr(a:adescr.optional[0], a:idx.'.0(optional)',
                    \            a:type, (a:purgemax || a:adescr.maximum==-1))
                    \.popms()
                    \.addrestmsgs(1)
    if lopt>1
        call self.let(failstr, 0)
    endif
    let newsub=self.getlastsub()
    if newsub isnot# a:caidxstr
        call self.let(a:caidxstr, newsub)
    endif
    call self.catch(s:cfreg)
    if lopt==1 && has_key(a:adescr.optional[0], 'arg')
        let defaults=reverse(map(filter(copy(a:adescr.optional[0].arg),
                    \                   'exists("v:val[0][0]") && '.
                    \                   'v:val[0][0] is# "defval"'),
                    \            'v:val[0][1]'))
        let self.defvals+=defaults
        if !empty(defaults) && nodefs
            let base=self.argstr(0, self.subs[:-2])
            for defvar in self.defvals
                call self.call('insert('.base.', '.self.getvar(defvar).', '.
                            \            a:caidxstr.')')
            endfor
            let ldefaults=len(self.defvals)
            call     self.increment(a:caidxstr, ldefaults)
                        \.increment(a:largsstr, ldefaults)
        endif
    endif
    call self.up()
    let self.subs[-1]=[a:caidxstr]
    if lopt>1
        let i=1
        for opt in a:adescr.optional[1:]
            call self.if(failstr)
                        \.try()
                            \.pushms('throw')
                            \.compadescr(opt,a:idx.'.'.i.'(optional)',a:type,0)
                            \.popms()
                            \.addrestmsgs(1)
                            \.let(failstr, 0)
            let newsub=self.getlastsub()
            if newsub isnot# a:caidxstr
                call self.let(a:caidxstr, newsub)
            endif
            call self.catch(s:cfreg)
                \.endif()
            let self.subs[-1]=[a:caidxstr]
            let i+=1
        endfor
    endif
    let self.optdepth-=1
    if self.optdepth==0 && !empty(self.defvals)
        call remove(self.defvals, 0, -1)
    endif
    return [[a:caidxstr], addedsavemsgs]
endfunction
"▶1 prefixes
let s:r.prefixes={'char': '{'}
"▶2 scan
" Input: {omtchr} ({prefdescr} ( "-" | {arg} )* )* "}"?
"        {prefdescr} :: {prefopts}? ( {str} | {wordchar}+ )
"         {prefopts} :: ( "?" | "!" | "*" | "+" {wordchar}+ )* ( ":" {var} )?
" Output: context(prefixes[, {matcher}], {prefix}*)
"           {prefix} :: context(prefix, String, {prefopts}[, {var}][, {arg}*])
"         {prefopts} :: { "alt": Bool, "list": Bool, "opt": Bool,
"                         "argnum": UInt }
let s:defprefopts={'alt': 0, 'list': 0, 'opt': 0, 'argnum': 1}
function s:r.prefixes.scan()
    call self.addcon('prefixes').getomtchr()
    let prevlen=-1
    while self.len && prevlen!=self.len
        let prevlen=self.len
        let c=self.readc()
        if !exists('pref')
            if !exists('prefopts')
                let prefopts=copy(s:defprefopts)
                let prefopts.argnum=1
            endif
            if c=~#'^\w'
                let pref=c
            elseif c is# '"'
                let c=self.readstr()
                let pref=c
            elseif c is# "'"
                let c=self.readsstr()
                let pref=c
            elseif c is# '+'
                let prefopts.argnum=+self.readc()
            elseif c is# '?'
                let prefopts.opt=1
            elseif c is# '!'
                let prefopts.alt=1
                let prefopts.argnum=0
            elseif c is# '*'
                let prefopts.list=1
            elseif c is# '}'
                break
            else
                call self.ungetc(c)
                break
            endif
        else
            call self.addcon('prefix', pref, prefopts)
            if c is# ':'
                let prefopts.opt=1
                call self.getvar()
                let c=self.readc()
            endif
            if c is# '-'
                let prefopts.argnum=0
            else
                call self.ungetc(c)
            endif
            let argnum=prefopts.argnum
            while argnum
                call self.scan()
                let argnum-=1
            endwhile
            unlet pref prefopts
            call self.conclose()
            let prevlen=-1
        endif
    endwhile
    return self.conclose()
endfunction
"▶2 compile :: descr, idx, {rolvars}, {lvars} + self → {lvars}
function s:r.prefixes.compile(adescr, idx, caidxstr, largsstr, purgemax, type,
            \                 nextsub, addedsavemsgs)
    "▶3 Define variables
    let addedsavemsgs=a:addedsavemsgs
    let nextsub=[a:caidxstr]
    let preflist=[]
    let plstr=self.getfunstatvar('prefixes', preflist)
    let reqpreflist=[]
    let rplstr=self.getfunstatvar('reqprefixes', reqpreflist)
    let prefdictstr=self.getlvarid('prefdict')
    let base=self.argstr(0, self.subs[:-2])
    let astr=self.getlvarid('arg')
    let idx=a:idx.'(prefixes)'
    let defaults=filter(copy(a:adescr.prefixes),
                \       'exists("v:val[2][0]") && v:val[2][0] isnot# "arg"')
    let lists=filter(copy(a:adescr.prefixes), 'v:val[1].list')
    let haslist=!empty(lists)
    let lastliststr=self.getlvarid('lastlist')
    let hasnext=s:F.hasnext(a:adescr, 'prefixes')
    "▲3
    if haslist
        call self.let(lastliststr, 0)
    endif
    if a:type is# 'check' || a:type is# 'pipe'
        "▶3 Add messages saving if required
        if hasnext
            if !addedsavemsgs
                call self.addsavemsgs()
                let addedsavemsgs=1
            endif
            call self.try().pushms('throw')
        endif
        "▶3 Initialize variables inside constructed function
            call self.let(prefdictstr, '{}')
                        \.call('insert('.base.', '.prefdictstr.', '.
                        \                self.getsub(nextsub).')')
                        \.increment(a:caidxstr)
                        \.increment(a:largsstr)
        "▶3 Add default values
        for [prefix, prefopts, defval; dummylist] in defaults
            call self.let(prefdictstr.self.getsubs([prefix]),
                        \ self.getvar(defval))
        endfor
        "▲3
        call self.while('len('.base.')>'.a:caidxstr)
    else
        call self.while(a:caidxstr.'<'.a:largsstr)
    endif
    "▶3 Get `astr' variable
    if a:type is# 'check' || a:type is# 'pipe'
        if !self.o.onlystrings
            if haslist
                call self.if('type('.self.argstr().')=='.type(''))
            else
                call self.addtypecond([type('')], idx)
            endif
        endif
    else
        call self.addif(a:caidxstr.'=='.a:largsstr.'-1')
                    \.addmatches(plstr, type([]))
                    \.break()
                \.up()
    endif
    call self.let(astr, self.getmatcher(get(a:adescr, 'prefixesmatcher',
                \                           s:prefdefmatcher), plstr,
                \                       self.argstr(), 0))
    if a:type is# 'check' || a:type is# 'pipe'
        let removestr='remove('.base.', '.a:caidxstr.')'
        if hasnext
            let argorigstr=self.getd('argorig')
        endif
        if !self.o.onlystrings
            if haslist
                call self.up().else().let(astr, 0).up().endif()
                            \.if(astr.' isnot 0')
            else
                call self.nextthrow(astr.' is 0', 'pnf', idx, self.argstr())
            endif
        elseif haslist
            call self.if(astr.' isnot 0')
        endif
        call self.increment(a:largsstr, -1)
        if hasnext
            call self.let(argorigstr, removestr)
        else
            call self.call(removestr)
        endif
        if haslist
            call self.up().endif()
        endif
    else
        call self.addif(astr.' isnot 0')
                    \.increment(a:caidxstr, 1)
                \.endif()
    endif
    "▲3
    for [prefix, prefopts; args] in a:adescr.prefixes
        "▶3 Add prefix to prefix list
        call s:F.addprefix(preflist, prefix)
        if prefopts.alt
            call s:F.addprefix(preflist, 'no'.prefix)
        endif
        if !prefopts.opt
            call add(reqpreflist, prefix)
        endif
        "▶3 Remove default value specification if any
        let hasdefault=0
        if !empty(args) && args[0][0] isnot# 'arg'
            let hasdefault=1
            call remove(args, 0)
        endif
        "▲3
        let prefstr=prefdictstr.self.getsubs([prefix])
        let prefixstr=self.string(prefix)
        if a:type is# 'complete' && !prefopts.argnum
            continue
        endif
        "▶3 Construct prefix condition
        let cond=astr.' is# '.prefixstr
        if prefopts.list
            let cond.=' || ('.astr.' is 0 && '.
                        \   lastliststr.' is# '.prefixstr.')'
        endif
        call self.addif(cond)
        "▶3 Process prefix arguments
        if a:type is# 'check' || a:type is# 'pipe'
            for i in range(1, prefopts.argnum)
                call self.compilearg(args[i-1], idx.self.string(prefix), a:type)
                            \.incsub()
            endfor
            if prefopts.argnum>0
                call self.increment(a:largsstr, -prefopts.argnum)
            endif
        else
            if haslist
                call self.let(lastliststr, prefopts.list?(prefixstr):0)
            endif
            let idxdiffstr=self.getlvarid('idxdiff')
            call self.if(a:caidxstr.'+'.prefopts.argnum.'<'.a:largsstr)
                        \.increment(a:caidxstr, prefopts.argnum)
                    \.else()
                        \.let(idxdiffstr, a:largsstr.'-'.a:caidxstr)
            for i in range(1, prefopts.argnum)
                call self.addif(idxdiffstr.'=='.i)
                            \.compilearg(args[i-1], idx.self.string(prefix),
                            \            a:type)
                            \.break()
                        \.up()
            endfor
            call self.up().up()
        endif
        "▶3 Move prefix arguments to prefix dictionary
        if a:type is# 'complete'
            call self.up()
        elseif prefopts.list
            let removestr='remove('.base.', '.a:caidxstr.', '.
                        \           a:caidxstr.'+'.(prefopts.argnum-1).')'
            let cond='has_key('.prefdictstr.', '.prefixstr.')'
            if hasdefault
                let cond.=' && type('.prefstr.')=='.type([])
            endif
            call self.if(cond)
                        \.increment(prefstr, removestr)
                    \.else()
                        \.let(prefstr, removestr)
                    \.up()
            call self.let(lastliststr, prefixstr)
        else
            if haslist
                call self.let(lastliststr, 0)
            endif
            if prefopts.argnum==1
                call self.let(prefstr, 'remove('.base.', '.a:caidxstr.')')
            elseif prefopts.argnum>0
                call self.let(prefstr,
                            \'remove('.base.', '.a:caidxstr.', '.
                            \        a:caidxstr.'+'.(prefopts.argnum-1).')')
            else
                call self.let(prefstr, 1)
            endif
        endif
        "▲3
        let self.subs[-1]=[a:caidxstr]
        call self.up()
        "▶3 Process `no{prefix}'
        if a:type is# 'check' || a:type is# 'pipe'
            if prefopts.alt
                call self.addif(astr.' is# '.self.string('no'.prefix))
                            \.let(prefstr, 0)
                            \.up()
            endif
        endif
        "▲3
    endfor
    if a:type is# 'complete'
        call self.addif(astr.' is 0')
                    \.break()
                \.up()
    endif
    call self.up()
    if a:type is# 'check' || a:type is# 'pipe'
        if hasnext
            call self.unlet(argorigstr).up().up().addrestmsgs(1).popms()
                \.catch(s:cfreg)
                    \.if('exists('.string(argorigstr).')')
                        \.call('insert('.base.','.argorigstr.','.a:caidxstr.')')
                        \.increment(a:largsstr)
                    \.up()
                \.up()
        else
            call self.up()
        endif
        if !empty(reqpreflist)
            call self.nextthrow('!empty(filter(copy('.rplstr.'), '.
                        \           '"!has_key('.prefdictstr.', v:val)"))',
                        \       'noreqpref', a:idx)
        endif
    else
        call self.up()
    endif
    return [[a:caidxstr], addedsavemsgs]
endfunction
"▶1 next
let s:r.next={'char': '+'}
"▶2 scan
function s:r.next.scan()
    return self.addcon('next').scan().conclose()
endfunction
"▶2 compile :: descr, idx, {rolvars}, {lvars} + self → {lvars}
function s:r.next.compile(adescr, idx, caidxstr, largsstr, purgemax, type,
            \             nextsub, addedsavemsgs)
    let addedsavemsgs=a:addedsavemsgs
    let hasnext=s:F.hasnext(a:adescr, 'next')
    if a:type is# 'complete'
        let condition=a:largsstr.'>='.self.getlastsub()
        if self.onlyfirst
            let condition=a:largsstr.'-1 == '.self.getlastsub()
        endif
        call self.addif(condition)
                    \.compilearg(a:adescr.next[0], a:idx.'.(next)', a:type)
                \.up()
        if hasnext
            call self.pushms('throwignore')
                        \.try()
                            \.while(a:caidxstr.'<'.a:largsstr.'-1')
                                \.compilearg(a:adescr.next[0], a:idx.'.(next)',
                                \            'check')
                                \.increment(a:caidxstr)
                            \.up()
                        \.catch(s:cfreg)
                            \.call('remove(@$@variants, 0, -1)')
                        \.up()
        endif
    else
        if hasnext
            if !addedsavemsgs
                call self.addsavemsgs()
                let addedsavemsgs=1
            endif
            call self.try().pushms('throw')
        endif
        call self.while(a:caidxstr.'<'.a:largsstr)
                    \.compilearg(a:adescr.next[0], a:idx.'.(next)', a:type)
                    \.increment(a:caidxstr)
                    \.up()
        if hasnext
            call self.addrestmsgs(1).catch(s:cfreg).popms().up()
        endif
    endif
    return [[a:caidxstr], addedsavemsgs]
endfunction
"▶1 actions
let s:r.actions={'char': '<'}
"▶2 scan
" Input: {omtchr} ( {actdescr} ( "-" | "(" {arg}* ")"? | {arg} ) )* ">"?
"        {actdescr} :: {str}
"                    | {wordchar}+
" Output: context(actions[, {matcher}],
"                 (context(action, 0|String|{arg}, {arg}*))*)
function s:r.actions.scan()
    call self.addcon('actions').getomtchr()
    let hasaction=0
    let prevlen=-1
    while self.len && prevlen!=self.len
        let prevlen=self.len
        let c=self.readc()
        if !hasaction
            let hasaction=1
            if c is# '>'
                let hasaction=0
                break
            elseif c is# '"'
                call self.addcon('action', self.readstr())
            elseif c is# "'"
                call self.addcon('action', self.readsstr())
            elseif c is# '-'
                call self.addcon('action', 0)
            elseif c=~#'^\w'
                call self.addcon('action', c)
            else
                call self.throw('invact', c)
            endif
        else
            let hasaction=0
            if c is# '('
                let prevlen2=-1
                while self.len && prevlen2!=self.len
                    let prevlen2=self.len
                    let c=self.readc()
                    if c is# ')'
                        break
                    endif
                    call self.ungetc(c).scan()
                endwhile
            elseif c isnot# '>' && c isnot# '-'
                call self.ungetc(c).scan()
            endif
            call self.conclose()
        endif
    endwhile
    if hasaction
        call self.conclose()
    endif
    return self.conclose()
endfunction
"▶2 optimizenullact :: &self(caidxstr)
" XXX low-level hacks here
function s:r.actions.optimizenullact(caidxstr)
    if len(self.l)==2 && self.l[1][0] is# 'if'
                \&& (len(self.l[1])==3 ||
                \    (len(self.l[1])==4 && self.l[-1] is# 'endif'))
                \&& len(self.stack[-2])==3
                \&& self.stack[-2][0] is# 'if'
                \&& self.l[1][1] is# self.stack[-2][1]
        call extend(self.l, self.l[1][2])
        call remove(self.l, 1)
    elseif len(self.l)==3 && self.l[1][0] is# 'let'
                \&& self.l[1][2] is# a:caidxstr
                \&& self.l[2][0] is# 'if'
                \&& (len(self.l[2])==3 ||
                \    (len(self.l[2])==4 && self.l[-1] is# 'endif'))
                \&& len(self.stack[-2])==3
                \&& self.stack[-2][0] is# 'if'
                \&& self.l[2][1][:(-1-len(self.l[1][1]))] is
                \   self.stack[-2][1][:(-1-len(a:caidxstr))]
        call extend(self.l, self.l[2][2])
        call remove(self.l, 1, 2)
    endif
    return self
endfunction
"▶2 compile :: descr, idx, {rolvars}, {lvars} + self → {lvars}
function s:r.actions.compile(adescr, idx, caidxstr, largsstr, purgemax, type,
            \                nextsub, addedsavemsgs)
    let actionstr=self.getlvarid('action')
    let actions=filter(copy(a:adescr.actions), 'v:val[0] isnot 0')
    let noact=get(filter(copy(a:adescr.actions), 'v:val[0] is 0'), 0, 0)
    let fsastr=self.getfunstatvar('actions', map(copy(actions), 'v:val[0]'))
    if noact isnot 0 && a:type isnot# 'complete'
        call self.try().pushms('throw')
    endif
    let idx=a:idx.'(actions)'
    if !self.o.onlystrings && a:type isnot# 'complete'
        call self.addtypecond([type('')], idx)
    endif
    let curargstr=self.argstr()
    if a:type is# 'complete'
        call self.addif(a:largsstr.'-1 == '.self.getlastsub())
                        \.addmatches(fsastr, type([]))
        let savedsub=copy(self.subs[-1])
        if noact isnot 0 && len(noact)>1
            let self.onlyfirst+=1
            call self.compadescr(noact[1], idx.'.nullact', a:type, 0).out()
            call call(s:r.actions.optimizenullact, [a:caidxstr], self)
            let self.onlyfirst-=1
        endif
        let self.subs[-1]=savedsub
        call self.up()
        if self.onlyfirst
            return [[a:caidxstr], a:addedsavemsgs]
        else
            call self.else()
        endif
    endif
    call self.let(actionstr, self.getmatcher(get(a:adescr, 'actionsmatcher',
                \                                s:actdefmatcher),
                \                            fsastr, curargstr, 0))
    if a:type isnot# 'complete'
        call self.nextthrow(actionstr.' is 0', 'anf', idx, curargstr)
    endif
    if a:type is# 'pipe'
        call self.let(curargstr, actionstr)
    endif
    unlet curargstr
    call self.incsub()
    let astartsub=copy(self.subs[-1])
    for [actstr; actargs] in actions
        call self.addif(actionstr.' is# '.self.string(actstr))
        if !empty(actargs)
            call self.compadescr(actargs[0], idx.'.'.self.string(actstr),
                        \        a:type, 0)
        endif
        call self.let(a:caidxstr, self.getlastsub()).up()
        let self.subs[-1]=copy(astartsub)
    endfor
    if noact isnot 0
        if a:type is# 'complete'
            call self.else()
        else
            call self.popms().catch(s:cfreg)
        endif
        call self.incsub(-1)
        if len(noact)>1
            call self.compadescr(noact[1], idx.'.nullact', a:type, 0)
                        \.let(a:caidxstr, self.getlastsub())
        endif
        let self.subs[-1]=copy(astartsub)
        call self.up().up()
    endif
    let self.subs[-1]=[a:caidxstr]
    if a:type is# 'complete'
        call self.up().up()
    endif
    return [[a:caidxstr], a:addedsavemsgs]
endfunction
"▶1 _order
let s:r._order=['optional', 'prefixes', 'next', 'actions']
let s:r._chars={}
call map(filter(copy(s:r), 'v:key[0] isnot# "_" && has_key(v:val, "char")'),
            \'extend(s:r._chars, {v:val.char : v:key})')
"▶1 Register resource
call s:_f.postresource('FWC_topconstructs', s:r, 1)
"▶1
call frawor#Lockvar(s:, '')
" vim: fmr=▶,▲ sw=4 ts=4 sts=4 et tw=80
