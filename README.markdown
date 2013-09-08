Frawor is a modular vim framework designed to collect some commonly needed 
functions.

To start using the only thing you should do is to add

    execute frawor#Setup('0.0', {})

where '0.0' is your plugin version and {} is a dictionary containing plugin 
dependencies (the core frawor module is added to dependencies automatically). 
There are additional rules you should follow:

1. All script-local functions should be anonymous functions:

        function s:F.somefunc(args)

    In some plugins you may even end with having no non-anonymous function 
    definitions.

2. If function cannot be anonymous (because it is is to be used by `sort()`, for 
    example), then its name should be added to `s:_functions` list.

3. If you define a command, its name should go to `s:_commands` list, same for 
    autocommand groups (`s:_augroups`).

4. All script-local variables whose name starts with `s:_` are reserved and 
    should be used only in a way described in documentation.

Advantages
==========

1. Plugin reloading for easier development and updates without vim restart:

        call frawor#Reload('plugin/frawor')

    or (shorter)

        call frawor#Reload('@frawor')

    to reload all plugins (as they all depend on core frawor module).

2. Frawor provides an easier way to mappings customization:

        execute frawor#Setup('0.0', {'@/mappings': '0.0'})
        <...>
        call s:_f.mapgroup.add('Foo',
                \{'bar': {'lhs': 't', 'rhs': ':Bar<CR>'},
                \ 'baz': {'lhs': 'T', 'rhs': s:F.baz}},
            \{'leader': '<leader>', 'silent': 1})
    will define two mappings: `<leader>t` which will call command `:Bar` and 
    `<leader>T` which will run `s:F.baz` function. Both mappings are silent. Now 
    pretend that you are the user who does not need to run `s:F.baz` and wants to 
    launch `:Bar` using `,t`. In this case all he needs is to add the following 
    lines to the vimrc:

        let g:frawormap_Foo=','

        let g:frawormap_Foo_bar='t'
        let g:frawormap_Foo_baz=0

    Replacing `','` with `0` here will lead to disabling the whole mapping 
    group.

3. Options:

        "plugin/foo.vim:
        execute frawor#Setup('0.0', {'@/options': '0.0'})
        let s:_options={'columns': {'default': 80, 'checker': 'range 0 inf'}}
        <...>
                    let columns=s:_f.getoption('columns')
        <...>

        "vimrc:
        let g:foo_columns=78
        autocmd FileType vim  let b:foo_columns=78
    If you don't want to prefix your options with `foo` (second component after 
    runtimepath of a path to your plugin), define `s:_oprefix`. Note the 
    `checker` key: it saves you from writing code for checking user input (but 
    will instead generate an exception for invalid value).

4. Function argument checks:

        execute frawor#Setup('0.0', {'@/functions': '0.0'})
        let s:formats={'html': ...,
                      \'markdown': ...}
        function s:F.checkedfunc(format, columns)
            <...>
        endfunction
        let s:F.checkedfunc=s:_f.wrapfunc({'function': s:F.checkedfunc,
                                          \'@FWC': ['key formats  '.
                                          \         'range 0 inf', 'check'],})

    Here you can see FWC decorator which uses FWC-to-vimscript compiler where FWC 
    is a name of the domain-specific language written exclusively for frawor.

5. Complicated command-line arguments handling:

        execute frawor#Setup('0.0', {'@/commands': '0.0'})
        let s:formats={'html': ...,
                      \'markdown': ...,}
        function s:F.run_foo(options)
            " Here a:options is dictionary containing all prefixed options user
            " have given on the command-line
            let format=a:options.format
            let columns=a:options.columns
            if a:options.beatify
                <...>
            endif
        endfunction
        "                Prefix  default  Description of
        "                         value   the prefix argument
        let s:foo_args='{columns :=(80)   |earg range 0 inf '.
                      \'  format          key formats '.
                      \'!beatify :=(0)'}'
        " Define a :Foo command
        call s:_f.command.add('Foo', {'function': s:F.run_foo,
                                     \    '@FWC': [s:foo_args, 'filter'],}
                             \{'complete': [s:foo_args], 'nargs': '+'})
        " " Example usage:
        " Foo col 78 f markdown
        " Foo nobeatify f html
        " Foo format html beatify c 78

    Note that while command accepts short versions of prefixes, `s:F.run_foo` 
    function will get dictionary with only full names.

6. Portable versions of OS-specific functions: vimscript implementation of some 
    functions from python os module.

7. Vimscript base64 encoder/decoder, fancy table echoing, maparg that returns 
    dictionary for old vim's and more.
