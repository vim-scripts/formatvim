"▶1 Header
scriptencoding utf-8
execute frawor#Setup('0.0', {'@/resources': '0.0'}, 1)
let s:constructor={}
"▶1 string     :: a → String
function s:constructor.string(val)
    if type(a:val)==type('') && a:val=~#"[\r\n@]"
        return ('"'.substitute(substitute(substitute(escape(a:val, '\"'),
                    \          "@",  '\\x40', 'g'),
                    \          "\n", '\\n',   'g'),
                    \          "\r", '\\r',   'g')
                    \.'"')
    endif
    return substitute(substitute(substitute(string(a:val),
                \"@",      '''."\\x40".''', 'g'),
                \"\n",     '''."\\n".''',   'g'),
                \"\r",     '''."\\r".''',   'g')
endfunction
"▶1 add        :: item, ... + self → self + self
function s:constructor.add(...)
    let self.l+=a:000
    return self
endfunction
"▶1 up         :: &self
function s:constructor.up()
    call remove(self.stack, -1)
    let self.l=self.stack[-1]
    return self
endfunction
"▶1 down       :: &self(list)
function s:constructor.down(list)
    call add(self.stack, a:list)
    let self.l=a:list
    return self
endfunction
"▶1 deeper     :: ()[, conelement1[, ...]] + self → self + self
function s:constructor.deeper(...)
    let con=copy(a:000)
    call self.add(con)
    return self.down(con)
endfunction
"▶1 out        :: &self
function s:constructor.out()
    if type(get(self.l, 0))==type('')
        return self.up()
    endif
    return self
endfunction
"▶1 toblock
function s:constructor.toblock(block)
    while get(self.l, 0) isnot a:block
        call self.up()
    endwhile
    return self
endfunction
"▶1 if         :: &self(condition)
function s:constructor.if(condition)
    return self.out().deeper('if', a:condition).deeper()
endfunction
"▶1 else       :: &self
function s:constructor.else()
    return self.toblock('if').add('else').deeper()
endfunction
"▶1 elseif     :: &self(condition)
function s:constructor.elseif(condition)
    return self.toblock('if').add('elseif', a:condition).deeper()
endfunction
"▶1 endif      :: &self
function s:constructor.endif()
    return self.toblock('if').add('endif').up()
endfunction
"▶1 addif      :: &self(condition?)
function s:constructor.addif(...)
    if a:0
        if get(self.l, 0) is# 'if' && get(self.l, -2) isnot# 'else' &&
                    \                 get(self.l, -1) isnot# 'endif'
            return self.elseif(a:1)
        else
            return self.if(a:1)
        endif
    else
        if get(self.l, 0) is# 'if'
            return self.else()
        else
            return self
        endif
    endif
endfunction
"▶1 try        :: &self()
function s:constructor.try()
    return self.out().deeper('try').deeper()
endfunction
"▶1 catch      :: &self(regex?)
function s:constructor.catch(...)
    return self.toblock('try')
                \.add('catch', '/'.escape(get(a:000,0,'.*'), '/').'/').deeper()
endfunction
"▶1 finally    :: &self
function s:constructor.finally()
    return self.toblock('try').add('finally').deeper()
endfunction
"▶1 while      :: &self(condition)
function s:constructor.while(condition)
    return self.out().deeper('while', a:condition).deeper()
endfunction
"▶1 for        :: &self(vars, list)
function s:constructor.for(vars, list)
    return self.out().deeper('for', a:vars, a:list).deeper()
endfunction
"▶1 continue   :: &self
function s:constructor.continue()
    return self.out().deeper('continue').up()
endfunction
"▶1 break      :: &self
function s:constructor.break()
    return self.out().deeper('break').up()
endfunction
"▶1 return     :: &self(expr)
function s:constructor.return(expr)
    return self.out().deeper('return', a:expr).up()
endfunction
"▶1 let        :: &self(var, val)
function s:constructor.let(var, val)
    return self.out().deeper('let', a:var, a:val).up()
endfunction
"▶1 strappend  :: &self(var, val)
function s:constructor.strappend(var, val)
    return self.out().deeper('append', a:var, a:val).up()
endfunction
"▶1 unlet      :: &self(var)
function s:constructor.unlet(var)
    return self.out().deeper('unlet', type(a:var)==type('')?[a:var]:a:var).up()
endfunction
"▶1 increment  :: &self(var[, val])
function s:constructor.increment(var, ...)
    return self.out().deeper('inc', a:var, get(a:000, 0, 1)).up()
endfunction
"▶1 decrement  :: &self(var, val)
function s:constructor.decrement(var, val)
    return self.out().deeper('dec', a:var, get(a:000, 0, 1)).up()
endfunction
"▶1 call       :: &self(expr)
function s:constructor.call(expr)
    return self.out().deeper('call', a:expr).up()
endfunction
"▶1 throw      :: &self(expr)
function s:constructor.throw(expr)
    return self.out().deeper('throw', a:expr).up().up()
endfunction
"▶1 do         :: &self(vimLstr)
function s:constructor.do(str)
    return self.out().deeper('do', a:str).up()
endfunction
"▶1 tolist     :: () + self → [String]
function s:constructor.tolist()
    let r=[]
    let items=map(deepcopy(self.tree), '[0, v:val]')
    let toextend=[]
    while !empty(items)
        let [indent, item]=remove(items, 0)
        let istr=repeat('    ', indent)
        if type(item)==type('')
            call add(r, istr.item)
        else
            let type=remove(item, 0)
            if type is# 'if'
                call add(r, istr.'if '.remove(item, 0))
                if !empty(item)
                    let toextend+=map(remove(item, 0),'['.(indent+1).', v:val]')
                endif
                while !empty(item)
                    let type=remove(item, 0)
                    if type is# 'elseif'
                        call add(toextend, [indent, 'elseif '.remove(item, 0)])
                    elseif type is# 'else'
                        call add(toextend, [indent, 'else'])
                    elseif type is# 'endif'
                        break
                    endif
                    let toextend+=map(remove(item, 0),'['.(indent+1).', v:val]')
                endwhile
                call add(toextend, [indent, 'endif'])
            elseif type is# 'try'
                call add(r, istr.'try')
                if !empty(item)
                    let toextend+=map(remove(item, 0),'['.(indent+1).', v:val]')
                endif
                while !empty(item)
                    let type=remove(item, 0)
                    if type is# 'catch'
                        call add(toextend, [indent, 'catch '.remove(item, 0)])
                    elseif type is# 'finally'
                        call add(toextend, [indent, 'finally'])
                    elseif type is# 'endtry'
                        break
                    endif
                    let toextend+=map(remove(item, 0),'['.(indent+1).', v:val]')
                endwhile
                call add(toextend, [indent, 'endtry'])
            elseif type is# 'while'
                call add(r, istr.'while '.remove(item, 0))
                let toextend+=map(remove(item, 0),'['.(indent+1).', v:val]')
                call add(toextend, [indent, 'endwhile'])
            elseif type is# 'for'
                call add(r, istr.'for '.remove(item, 0).' in '.remove(item, 0))
                let toextend+=map(remove(item, 0),'['.(indent+1).', v:val]')
                call add(toextend, [indent, 'endfor'])
            elseif type is# 'let'
                call add(r, istr.'let '.remove(item, 0).'='.remove(item, 0))
            elseif type is# 'append'
                call add(r, istr.'let '.remove(item, 0).'.='.remove(item, 0))
            elseif type is# 'inc'
                let lhs=remove(item, 0)
                let assign='+='
                let shift=remove(item, 0)
                if type(shift)==type(0) && shift<0
                    let assign='-='
                    let shift=-shift
                endif
                call add(r, istr.'let '.lhs.assign.shift)
            elseif type is# 'dec'
                call add(r, istr.'let '.remove(item, 0).'-='.remove(item, 0))
            elseif       type is# 'call'   ||
                        \type is# 'throw'  ||
                        \type is# 'return'
                call add(r, istr.type.' '.remove(item, 0))
            elseif type is# 'unlet'
                call add(r, istr.type.' '.join(remove(item, 0)))
            elseif type is# 'continue' || type is# 'break'
                call add(r, istr.type)
            elseif type is# 'do'
                call add(r, remove(item, 0))
            endif
            if !empty(toextend)
                call extend(items, remove(toextend, 0, -1), 0)
            endif
        endif
        unlet item
    endwhile
    return r
endfunction
"▶1 new
call extend(s:constructor, {'tree': [], 'stack': [],})
function s:F.new()
    let r=deepcopy(s:constructor)
    call add(r.stack, r.tree)
    let r.l=r.stack[-1]
    return r
endfunction
call s:_f.postresource('new_constructor', s:F.new)
"▶1
call frawor#Lockvar(s:, '')
" vim: fmr=▶,▲ sw=4 ts=4 sts=4 et tw=80
