"▶1 Header
scriptencoding utf-8
execute frawor#Setup('1.0', {'@/resources': '0.0'}, 1)
let s:constructor={}
let s:comp={}
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
"▶1 _add       :: item, ... + self → self + self
function s:constructor._add(...)
    let self.l+=a:000
    return self
endfunction
"▶1 _up        :: &self
function s:constructor._up()
    call remove(self.stack, -1)
    let self.l=self.stack[-1]
    return self
endfunction
"▶1 _down      :: &self(list)
function s:constructor._down(list)
    call add(self.stack, a:list)
    let self.l=a:list
    return self
endfunction
"▶1 _deeper    :: ()[, conelement1[, ...]] + self → self + self
function s:constructor._deeper(...)
    let con=copy(a:000)
    call self._add(con)
    return self._down(con)
endfunction
"▶1 _out       :: &self
function s:constructor._out()
    if type(get(self.l, 0))==type('')
        return self._up()
    endif
    return self
endfunction
"▶1 _toblock
function s:constructor._toblock(block)
    while get(self.l, 0) isnot a:block
        call self._up()
    endwhile
    return self
endfunction
"▶1 do: do, continue, break
"▶2 comp.do
function s:comp.do(r, toextend, indent, item)
    call add(a:r, repeat(' ', &sw*a:indent).remove(a:item, 0))
endfunction
"▶2 continue   :: &self
function s:constructor.continue()
    return self._out()._deeper('do', 'continue')._up()
endfunction
"▶2 break      :: &self
function s:constructor.break()
    return self._out()._deeper('do', 'break')._up()
endfunction
"▶2 do         :: &self(vimLstr)
function s:constructor.do(str)
    return self._out()._deeper('do', a:str)._up()
endfunction
"▶1 if block
"▶2 comp.if
function s:comp.if(r, toextend, indent, item)
    call add(a:r, repeat(' ', &sw*a:indent).'if '.remove(a:item, 0))
    if !empty(a:item)
        call extend(a:toextend,map(remove(a:item,0),'['.(a:indent+1).',v:val]'))
    endif
    while !empty(a:item)
        let type=remove(a:item, 0)
        if type is# 'elseif'
            call add(a:toextend, [a:indent, 'elseif '.remove(a:item, 0)])
        elseif type is# 'else'
            call add(a:toextend, [a:indent, 'else'])
        elseif type is# 'endif'
            break
        endif
        call extend(a:toextend,map(remove(a:item,0),'['.(a:indent+1).',v:val]'))
    endwhile
    call add(a:toextend, [a:indent, 'endif'])
endfunction
"▶2 if         :: &self(expr)
function s:constructor.if(expr)
    return self._out()._deeper('if', a:expr)._deeper()
endfunction
"▶2 elseif     :: &self(expr)
function s:constructor.elseif(expr)
    return self._toblock('if')._add('elseif', a:expr)._deeper()
endfunction
"▶2 else       :: &self
function s:constructor.else()
    return self._toblock('if')._add('else')._deeper()
endfunction
"▶2 endif      :: &self
function s:constructor.endif()
    return self._toblock('if')._add('endif')._up()
endfunction
"▶2 addif      :: &self(expr?)
function s:constructor.addif(...)
    if a:0
        if get(self.l, 0) is# 'if' && get(self.l, -2) isnot# 'else' &&
                    \                 get(self.l, -1) isnot# 'endif'
            return call(self.elseif, a:000, self)
        else
            return call(self.if, a:000, self)
        endif
    else
        if get(self.l, 0) is# 'if'
            return self.else()
        else
            return self
        endif
    endif
endfunction
"▶1 try block
"▶2 comp.try
function s:comp.try(r, toextend, indent, item)
    call add(a:r, repeat(' ', &sw*a:indent).'try')
    if !empty(a:item)
        call extend(a:toextend,map(remove(a:item,0),'['.(a:indent+1).',v:val]'))
    endif
    while !empty(a:item)
        let type=remove(a:item, 0)
        if type is# 'catch'
            call add(a:toextend, [a:indent, 'catch '.remove(a:item, 0)])
        elseif type is# 'finally'
            call add(a:toextend, [a:indent, 'finally'])
        elseif type is# 'endtry'
            break
        endif
        call extend(a:toextend,map(remove(a:item,0),'['.(a:indent+1).',v:val]'))
    endwhile
    call add(a:toextend, [a:indent, 'endtry'])
endfunction
"▶2 try        :: &self()
function s:constructor.try()
    return self._out()._deeper('try')._deeper()
endfunction
"▶2 catch      :: &self(regex?)
function s:constructor.catch(...)
    return self._toblock('try')
                \._add('catch', '/'.escape(get(a:000,0,'.*'),'/').'/')._deeper()
endfunction
"▶2 finally    :: &self
function s:constructor.finally()
    return self._toblock('try')._add('finally')._deeper()
endfunction
"▶1 cycles: while, for; continue, break
"▶2 comp.while
function s:comp.while(r, toextend, indent, item)
    call add(a:r, repeat(' ', &sw*a:indent).'while '.remove(a:item, 0))
    call extend(a:toextend, map(remove(a:item, 0), '['.(a:indent+1).', v:val]'))
    call add(a:toextend, [a:indent, 'endwhile'])
endfunction
"▶2 while      :: &self(expr)
function s:constructor.while(expr)
    return self._out()._deeper('while', a:expr)._deeper()
endfunction
"▶2 comp.for
function s:comp.for(r, toextend, indent, item)
    call add(a:r, repeat(' ', &sw*a:indent).'for '.remove(a:item, 0).' in '.
                \                                             remove(a:item, 0))
    call extend(a:toextend, map(remove(a:item, 0), '['.(a:indent+1).', v:val]'))
    call add(a:toextend, [a:indent, 'endfor'])
endfunction
"▶2 for        :: &self(vars, expr)
function s:constructor.for(vars, expr)
    return self._out()._deeper('for', a:vars, a:expr)._deeper()
endfunction
"▶1 execute: call, throw, return
"▶2 comp.execute
function s:comp.execute(r, toextend, indent, item)
    call add(a:r,repeat(' ',&sw*a:indent).remove(a:item,0).' '.remove(a:item,0))
endfunction
"▶2 return, call, execute, echo, echomsg, echon
for s:type in ['return', 'call', 'execute', 'echo', 'echomsg', 'echon']
    execute      "function s:constructor.".s:type."(expr)\n".
                \"    return self._out()".
                \                "._deeper('execute', '".s:type."', a:expr)".
                \                "._up()\n".
                \"endfunction"
endfor
unlet s:type
"▶2 throw      :: &self(expr)
function s:constructor.throw(expr)
    return self._out()._deeper('execute', 'throw', a:expr)
                \._up()._up()
endfunction
"▶1 let: let, strappend, increment, decrement
"▶2 comp.let
function s:comp.let(r, toextend, indent, item)
    call add(a:r, repeat(' ', &sw*a:indent).'let '.remove(a:item, 0).
                \                               remove(a:item, 0).'='.
                \                                  remove(a:item, 0))
endfunction
"▶2 let, strappend
for [s:type, s:s] in [['let', ''], ['strappend', '.']]
    execute      "function s:constructor.".s:type."(var, expr)\n".
                \"    return self._out()".
                \                "._deeper('let', a:var, '".s:s."', a:expr)".
                \                "._up()\n".
                \"endfunction"
endfor
unlet s:type s:s
"▶2 increment  :: &self(var[, expr])
function s:constructor.increment(var, ...)
    let incval=get(a:000, 0, 1)
    call self._out()
    if type(incval)==type(0) && incval<0
        call self._deeper('let', a:var, '-', -incval)
    else
        call self._deeper('let', a:var, '+',  incval)
    endif
    return self._up()
endfunction
"▶2 decrement  :: &self(var[, expr])
function s:constructor.decrement(var, ...)
    let incval=get(a:000, 0, 1)
    call self._out()
    if type(incval)==type(0) && incval<0
        call self._deeper('let', a:var, '+', -incval)
    else
        call self._deeper('let', a:var, '-',  incval)
    endif
    return self._up()
endfunction
"▶1 unlet      :: &self(var|[var])
function s:comp.unlet(r, toextend, indent, item)
    call add(a:r, repeat(' ', &sw*a:indent).'unlet '.join(remove(a:item, 0)))
endfunction
function s:constructor.unlet(var)
    return self._out()._deeper('unlet', type(a:var)==type('')?[a:var]:a:var)
                \._up()
endfunction
"▶1 _tolist    :: () + self → [String]
function s:constructor._tolist()
    let r=[]
    let items=map(deepcopy(self.tree), '[0, v:val]')
    let toextend=[]
    while !empty(items)
        let [indent, item]=remove(items, 0)
        if type(item)==type('')
            call add(r, repeat(' ', &sw*indent).item)
        else
            let type=remove(item, 0)
            if has_key(s:comp, type)
                call call(s:comp[type], [r, toextend, indent, item], {})
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
