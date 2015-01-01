import vim
import json

if False and hasattr(vim, 'bindeval'):
    def vim_get_func(f, rettype=None):
        '''Return a vim function binding.'''
        return vim.bindeval('function('+json.dumps(f)+')')
else:
    class VimFunc(object):
        __slots__ = ('f',)

        def __init__(self, f):
            self.f = vim_dumps(f)

        def __call__(self, *args, **kwargs):
            vim_args = [self.f, vim_dumps(args)]
            if 'self' in kwargs:
                vim_args.append(vim_dumps(kwargs['self']))
            types, r = vim.eval(_ftc_name+'('+','.join(vim_args)+')')
            return _type_returned_value(types, r)

        def __repr__(self):
            return self.__class__.__name__+'('+self.f+')'

    vim_get_func = VimFunc

    TYPES = {
        '0': int,
        '2': VimFunc,
        '5': float,
    }
    def _type_returned_value(types, r):
        if type(types) is dict:
            for k in types:
                r[k] = _type_returned_value(types[k], r[k])
        elif type(types) is list:
            for i in range(len(types)):
                r[i] = _type_returned_value(types[i], r[i])
        elif types in TYPES:
            r=TYPES[types](r)
        return r

    def nonutf_dumps(obj):
        todump=[('dump', obj)]
        r=''
        while todump:
            t, obj = todump.pop(0)
            if t == 'inject':
                r+=obj
            else:
                tobj=type(obj)
                if tobj is int:
                    r+=str(obj)
                elif tobj is float:
                    r += "%1.1e" % obj
                elif tobj is list or tobj is tuple:
                    r+='['
                    todump.insert(0, ('inject', ']'))
                    for value in reversed(obj):
                        todump[:0]=[('dump', value), ('inject', ',')]
                elif tobj is dict:
                    r+='{'
                    todump.insert(0, ('inject', '}'))
                    for key, value in obj.items():
                        todump[:0]=[('dump', key),
                                    ('inject', ':'),
                                    ('dump', value),
                                    ('inject', ',')]
                elif tobj is VimFunc:
                    r+='function('+obj.f+')'
                elif tobj is unicode:
                    todump.insert(0, ('dump', tobj.encode(vim.eval('&encoding'))))
                elif tobj is str  or  tobj is bytes:
                    r+='"'+obj.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n')+'"'
                else:
                    raise TypeError('nonutf_dumps cannot serialize `'+tobj.__name__+'\'')
        return r

    utf_dumps = json.dumps

    def vim_dumps(obj):
        try:
            return utf_dumps(obj)
        except (UnicodeDecodeError, TypeError):
            return _nonutf_dumps(obj)
