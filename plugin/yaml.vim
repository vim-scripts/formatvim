"{{{1 Начало
scriptencoding utf-8
if (exists("s:g.pluginloaded") && s:g.pluginloaded) ||
            \exists("g:yamlOptions.DoNotLoad")
    finish
"{{{1 Первая загрузка
elseif !exists("s:g.pluginloaded")
    "{{{2 Объявление переменных
    "{{{3 Словари с функциями
    " Функции для внутреннего использования
    let s:F={
                \"plug": {},
                \"main": {},
                \ "mng": {},
                \"comm": {},
                \"yaml": {},
                \"load": {},
                \"dump": {},
            \}
    lockvar 1 s:F
    "{{{3 Глобальная переменная
    let s:g={}
    let s:g.load={}
    let s:g.pluginloaded=0
    let s:g.constructors=[{}, {}]
    let s:g.c={}
    let s:g.load.scriptfile=expand("<sfile>")
    "{{{3 Словарные функции
    let s:g.load.dumps_opts=[
                \["dict", [[["equal", "preserve_locks"], ["bool", ""]],
                \          [["equal", "key_sort"], ["or", [["bool", ""],
                \                                          ["isfunc", 1]]]],
                \          [["equal", "all_flow"], ["bool", ""]],
                \          [["equal", "custom_tags"],
                \           ["allst", ["isfunc", 1]]]]],
                \{}, {}]
    let s:g.load.f=[["loads", "load.loads", {  "model": "simple",
                \                           "required": [["type", type("")]]}],
                \   ["load_all", "load.load_all",
                \                           {  "model": "simple",
                \                           "required": [["type", type("")]]}],
                \   ["dumps", "dump.dumps", {  "model": "optional",
                \                           "required": [["any", ""]],
                \                           "optional": [[["bool", ""],{},1],
                \                                        s:g.load.dumps_opts]}],
                \   ["add_constructor", "load.add_constructor",
                \                           {  "model": "simple",
                \                           "required": [["and",
                \                                         [["type", type("")],
                \                                          ["not",
                \                                           ["keyof",
                \                                            s:g.constructors[0]
                \                                                          ]]]],
                \                                        ["isfunc", 0]]}],
                \   ["add_multi_constructor", "load.add_multi_constructor",
                \                           {  "model": "simple",
                \                           "required": [["and",
                \                                         [["type", type("")],
                \                                          ["not",
                \                                           ["keyof",
                \                                            s:g.constructors[1]
                \                                                          ]]]],
                \                                        ["isfunc", 0]]}],
                \   ["del_constructor", "load.del_constructor",
                \                           {  "model": "simple",
                \                           "required": [["and",
                \                                         [["type", type("")],
                \                                          ["keyof",
                \                                           s:g.constructors[0]
                \                                                          ]]]]
                \                           }],
                \   ["del_multi_constructor", "load.del_multi_constructor",
                \                           {  "model": "simple",
                \                           "required": [["and",
                \                                         [["type", type("")],
                \                                          ["keyof",
                \                                           s:g.constructors[1]
                \                                                          ]]]]
                \                           }],
            \]
    "{{{3 Команды
    let s:g.load.commands={
                \"Command": {
                \      "nargs": '1',
                \       "func": "mng.main",
                \},
            \}
                " \   "complete": "customlist,s:_complete",
    "{{{3 sid
    function s:SID()
        return matchstr(expand('<sfile>'), '\d\+\ze_SID$')
    endfun
    let s:g.scriptid=s:SID()
    delfunction s:SID
    "{{{2 Регистрация дополнения
    let s:F.plug.load=load#LoadFuncdict()
    let s:g.reginfo=s:F.plug.load.registerplugin({
                \"apiversion": "0.1",
                \"sid": s:g.scriptid,
                \"funcdict": s:F,
                \"globdict": s:g,
                \"scriptfile": s:g.load.scriptfile,
                \"oprefix": "yaml",
                \"cprefix": "YAML",
                \"commands": s:g.load.commands,
                \"dictfunctions": s:g.load.f,
                \"requires": [["load", '0.0'],
                \             ["stuf", '0.5'],
                \             ["oop",  '0.1']],
            \})
    let s:F.main.eerror=s:g.reginfo.functions.eerror
    let s:F.main.option=s:g.reginfo.functions.option
    finish
    "}}}2
endif
"{{{1 Вторая загрузка
let s:g.pluginloaded=1
"{{{2 Настройки
let s:g.defaultOptions={
            \"UsePython": 1,
        \}
let s:g.c.options={
            \"UsePython": ["bool", ""],
        \}
"{{{2 s:g.yaml
let s:g.yaml={}
let s:g.yaml._undef=""
let s:g.yaml._true=1
let s:g.yaml._false=0
let s:g.yaml._null=s:g.yaml._undef
" http://www.yaml.org/spec/1.2/spec.html#c-printable
let s:g.yaml.printable='\x09\x0A\x0D\x20-\x7E'.
            \'\u0085\u00A0-\uD7FF\uE000-\uFFFD'.
            \'\U10000-\U10FFFF'
let s:g.yaml.printchar='['.s:g.yaml.printable.']'
" Vim does not support too wide unicode character ranges, waiting for a patch
if 1
    let s:g.yaml.printable='\x09\x0A\x0D\x20-\x7E'
    let s:g.yaml.printchar='\%(\p\|[\x09\x0A\x0D]\|\%u0085\)'
endif
" http://www.yaml.org/spec/1.2/spec.html#c-flow-indicator
let s:g.yaml.flowindicator='\[\]{},'
" http://www.yaml.org/spec/1.2/spec.html#s-white
let s:g.yaml.whitespace='\t '
" http://www.yaml.org/spec/1.2/spec.html#b-char
let s:g.yaml.linebreak='\x0A\x0D'
            " \"SEPREGEX": '^[ \t\r\n\x85\u2028\u2029]\=$',
let s:g.yaml.wslbr=(s:g.yaml.whitespace).(s:g.yaml.linebreak)
" http://www.yaml.org/spec/1.2/spec.html#c-comment
let s:g.yaml.comment='#'
" http://www.yaml.org/spec/1.2/spec.html#ns-word-char
let s:g.yaml.nsword='0-9a-zA-Z\-'

let s:g.yaml.mappingkey='?'
let s:g.yaml.mappingvalue=':'
let s:g.yaml.sequenceentry='\-'
let s:g.yaml.directivestart='%'
let s:g.yaml.aliasstart='*'
let s:g.yaml.anchorstart='&'
" http://www.yaml.org/spec/1.2/spec.html#c-indicator
let s:g.yaml.indicator='\-?:,\[\]{}#&*!|>''"%@`'
" http://www.yaml.org/spec/1.2/spec.html#ns-char
let s:g.yaml.nschar='\%(['.(s:g.yaml.wslbr).']\@!'.
            \(s:g.yaml.printchar).'\)'
" http://www.yaml.org/spec/1.2/spec.html#ns-directive-name
let s:g.yaml.nsdirectivenamereg=s:g.yaml.nschar.'\+'
" http://www.yaml.org/spec/1.2/spec.html#ns-uri-char
let s:g.yaml.nsurichar='\%(%\x\x\|['.s:g.yaml.nsword.
            \                     '#;/?:@&=+$,_.!~*''()\[\]]\)'
" http://www.yaml.org/spec/1.2/spec.html#ns-tag-char
let s:g.yaml.nstagreg='\%(%\x\x\|['.s:g.yaml.nsword.'#;/?:@&=+$,_.~*''()]\)'
let s:g.yaml.nstag=s:g.yaml.nsword.'%#;/?:@&=+$,_.~*''()'
" http://www.yaml.org/spec/1.2/spec.html#ns-anchor-char
let s:g.yaml.anchorchar='\%(['.(s:g.yaml.flowindicator).
            \                  (s:g.yaml.wslbr).']\@!'.
            \           s:g.yaml.printchar.'\)'
" http://www.yaml.org/spec/1.2/spec.html#ns-plain-safe(c)
let s:g.yaml.nsplainsafechar='\%(['.s:g.yaml.flowindicator.']\@!'.
            \                    s:g.yaml.nschar.'\)'
"{{{2 Выводимые сообщения
let s:g.p={
            \"ee": {
            \   "ndocstart": "@|Expected '<document start>', but found %s",
            \    "multYAML": "@|Found multiply YAML directives",
            \      "majmis": "@|Found incompatible YAML document: expected ".
            \                '1.x, but found %u.x',
            \      "duptag": "@|Found duplicate tag handle: %s",
            \      "ukntag": "While parsing a node@|found undefined ".
            \                "tag handle: %s",
            \   "emptblock": "While parsing a block node@|expected the node ".
            \                "content, but found %s",
            \   "emptyflow": "While parsing a flow node@|expected the node ".
            \                "content, but found %s",
            \     "nblkend": "While parsing a block collection@|expected ".
            \                "<block end>, but found %s",
            \    "nblkmend": "While parsing a block mapping@|expected ".
            \                "<block end>, but found %s",
            \     "nflwseq": "While parsing a flow sequence@|expected ".
            \                "',' or ']', but got %s",
            \     "nflwmap": "While parsing a flow sequence@|expected ".
            \                "',' or '}', but got %s",
            \   "nottkstrt": "While scanning for the next token@|found ".
            \                "character “%s” that cannot start any token",
            \        "sknc": "While scanning a simple key@|could not find ".
            \                "expected ':'",
            \     "seqnall": "@|Sequence entries are not allowed here",
            \     "mnotall": "@|Mapping keys are not allowed here",
            \    "ndirname": "While scanning a directive@|expected ".
            \                "non-whitespace non-linebreak printable ".
            \                "character, but found “%s”",
            \     "ndirend": "While scanning a directive@|expected ".
            \                "whitespace or linebreak character, ".
            \                "but found “%s”",
            \   "nYAMLdsep": "While scanning a YAML directive@|expected ".
            \                'a digit or decimal separator (dot), '.
            \                'but found “%s”',
            \     "nYAMLws": "While scanning a YAML directive@|expected ".
            \                'a whitespace or linebreak character, '.
            \                'but found “%s”',
            \      "nYAMLd": "While scanning a YAML directive@|expected ".
            \                'a digit or separator, but found “%s”',
            \     "nTAGsep": "While scanning a TAG directive@|expected a ".
            \                "separator (whitespace), but found “%s”",
            \    "nTAGesep": "While scanning a TAG directive@|expected a ".
            \                "separator (linebreak or whitespace), ".
            \                "but found “%s”",
            \    "ndirlend": "While scanning a directive@|expected a comment ".
            \                "or a line break, but found “%s”",
            \     "nanname": "While scanning an anchor@|expected ".
            \                "printable non-whitespace non-linebreak ".
            \                "character, but found “%s”",
            \     "nalname": "While scanning an alias@|expected ".
            \                "printable non-whitespace non-linebreak ".
            \                "character, but found “%s”",
            \      "nanend": "While scanning an anchor@|expected ".
            \                "its end, but found “%s”",
            \      "nalend": "While scanning an alias@|expected ".
            \                "its end, but found “%s”",
            \   "ntagendgt": "While parsing a tag@|expected '>', ".
            \                "but found “%s”",
            \     "ntagend": "While scanning a tag@|expected linebreak or ".
            \                "whitespace character, but found “%s”",
            \   "nullindnt": "While scanning a block scalar@|expected ".
            \                "indentation indicator in the range 1-9, but ".
            \                "found 0",
            \     "nblkind": "While scanning a block scalar@|expected ".
            \                "indentation or chomping indicators or ".
            \                'a separator (linebreak or whitespace), '.
            \                "but found “%s”",
            \      "nignln": "While scanning a block scalar@|expected ".
            \                'a comment or a line break, but found “%s”',
            \        "ndqs": "While scanning a double-quoted scalar@|".
            \                "expected escape sequence of %u hexadecimal ".
            \                "numbers, but found “%s”",
            \      "uknesc": "While scanning a double-quoted scalar@|".
            \                "found unknown escape sequence “\\%s”",
            \     "strnull": "@|Unable to embed null (\\x00) character ".
            \                "in string, ignored escape sequence",
            \       "qseos": "While scanning a quoted scalar@|".
            \                "found unexpected end of stream",
            \    "docsepqs": "While scanning a quoted scalar@|".
            \                "found unexpected document separator",
            \    "abmcolon": "While scanning a plain scalar@|".
            \                "found unexpected ':'",
            \    "ntagbang": "While scanning a tag@|".
            \                "expected '!', but found “%s”",
            \    "ndirbang": "While scanning a directive@|".
            \                "expected '!', but found “%s”",
            \     "ntaguri": "While scanning a tag@|".
            \                "expected URI, but found “%s”",
            \     "ndiruri": "While scanning a directive@|".
            \                "expected URI, but found “%s”",
            \    "nturiesc": "While scanning a tag@|expected URI ".
            \                "escaped sequence of 2 hex digits, but found “%s”",
            \    "nduriesc": "While scanning a directive@|expected URI ".
            \                "escaped sequence of 2 hex digits, but found “%s”",
            \   "notsingle": "Expected single document in the stream,@|".
            \                "but found another document",
            \      "dupkey": "While composing a mapping found@|".
            \                "duplicate key: %s",
            \     "alundef": "@|Found undefined alias “%s”",
            \       "dupan": "Overwritten duplicating anchor “%s”; ".
            \                "previous occurence@|next occurence",
            \      "invrec": "@|Found unconstructable recursive node",
            \       "notsc": "@|Expected a scalar node, but found %s",
            \      "notseq": "@|Expected a sequence node, but found %s",
            \      "notmap": "@|Expected a mapping node, but found %s",
            \      "fltstr": "While constructing a mapping node@|".
            \                "converted float to string",
            \      "numstr": "While constructing a mapping node@|".
            \                "converted number to string",
            \     "lsthash": "While constructing a mapping node@|".
            \                "found a list that cannot be used as ".
            \                'a dictionary key',
            \     "dcthash": "While constructing a mapping node@|".
            \                "found a dictionary that cannot be used as ".
            \                'a dictionary key',
            \     "dctfunc": "While constructing a mapping node@|".
            \                "found a function reference that cannot be used ".
            \                "as a dictionary key",
            \    "nullhash": "While constructing a mapping node@|".
            \                "found an empty value that cannot be used as ".
            \                'a dictionary key',
            \     "nmapseq": "While constructing a mapping@|expected ".
            \                'a mapping or list of mappings for merging, '.
            \                'but found %s',
            \    "nseqomap": "While constructing an ordered map@|expected ".
            \                'a sequence, but found %s',
            \    "nmapomap": "While constructing an ordered map@|expected ".
            \                'a mapping, but found %s',
            \   "nmlenomap": "While constructing an ordered map@|expected ".
            \                'a single mapping item, but found %u items',
            \      "nseqpr": "While constructing pairs@|expected ".
            \                'a sequence, but found %s',
            \      "nmappr": "While constructing pairs@|expected ".
            \                'a mapping, but found %s',
            \     "nmlenpr": "While constructing pairs@|expected ".
            \                'a single mapping item, but found %u items',
            \     "unundef": "@|Could not determine a constructor ".
            \                "for the tag %s",
            \     "fscript": "@|Unable to get script function “%s”",
            \      "fundef": "@|Function “%s” does not exist",
            \    "finvname": "@|String “%s” is not a valid function name",
            \        "fnum": "@|Cannot find function with number “%u”",
            \      "ualias": "While constructing a vim list@|".
            \                "found unknown locked alias “%s”",
            \        "ndef": "Variable %s used before defining",
            \    "ambcolon": "While scanning a plain scalar@|".
            \                "found ambigious ':'",
            \},
            \"emsg": {
            \        "spna": "special characters are not allowed",
            \     "cexists": "Constructor for this tag already exists",
            \       "infun": "In function %s:",
            \       "unexc": "Got %sError:",
            \      "btdump": "Failed to construct binary with custom tag",
            \},
            \"etype": {
            \        "notimp": "NotImplemented",
            \       "version": "VersionMismatch",
            \        "syntax": "SyntaxError",
            \           "utf": "InvalidCharacter",
            \},
            \"markmessage": "  in “%s”, line %u, column %u",
            \"remessage": "Unacceptable character #x%04x: “%s” in “%s”, ".
            \             "position %u",
            \"ambcolonnote": "Assuming that it separates key from value",
        \}
call add(s:g.load.f[3][2].required[0][1][1], s:g.p.emsg.cexists)
call add(s:g.load.f[4][2].required[0][1][1], s:g.p.emsg.cexists)
"{{{2 Чистка
unlet s:g.load
"{{{1 Вторая загрузка — функции
"{{{2 Внешние дополнения
let s:F.plug.stuf=s:F.plug.load.getfunctions("stuf")
let s:F.plug.oop =s:F.plug.load.getfunctions("oop")
"{{{2 main: eerror, destruct, option
"{{{3 main.destruct: выгрузить плагин
function s:F.main.destruct()
    for l:Cdf in s:g.load.classdeletes
        call call(l:Cdf, [], {})
        unlet l:Cdf
    endfor
    unlet s:g
    unlet s:F
    return 1
endfunction
"{{{2 comm: is*char, is*nr
"{{{3 comm.isprintnr
function s:F.comm.isprintnr(chnr)
    return (a:chnr==0x09 || a:chnr==0x0A || a:chnr==0x0D || a:chnr==0x85 ||
                \(   0x20<=a:chnr && a:chnr<=0x00007E) ||
                \(   0xA0<=a:chnr && a:chnr<=0x00D7FF) ||
                \( 0xE000<=a:chnr && a:chnr<=0x00FFFD) ||
                \(0x10000<=a:chnr && a:chnr<=0x10FFFF))
endfunction
"{{{3 comm.isprintchar
function s:F.comm.isprintchar(ch)
    let chnr=char2nr(a:ch)
    if nr2char(chnr)!=#a:ch
        return 0
    endif
    return s:F.comm.isprintnr(chnr)
endfunction
"{{{3 comm.is*char
let s:g.comm={}
let s:g.comm.excludeprint=[
            \   ["ns",           s:g.yaml.wslbr],
            \   ["anchor",      (s:g.yaml.flowindicator).(s:g.yaml.wslbr)],
            \   ["nsplainsafe", (s:g.yaml.flowindicator).(s:g.yaml.wslbr)],
            \]
for [s:funcname, s:excluderegex] in s:g.comm.excludeprint
    execute      "function s:F.comm.is".s:funcname."char(ch)\n".
                \"    if a:ch=~#'^[".s:excluderegex."]$'\n".
                \"        return 0\n".
                \"    endif\n".
                \"    return s:F.comm.isprintchar(a:ch)\n".
                \"endfunction"
    unlet s:funcname s:excluderegex
endfor
"{{{2 load: loads
"{{{3 s:F.load
call extend(s:F.load, {"Parser":               {},
            \          "Reader":               {},
            \          "Loader":               {},
            \          "Scanner":              {},
            \          "Composer":             {},
            \          "BaseResolver":         {},
            \          "SafeConstructor":      {},
            \          "BaseConstructor":      {},
            \          "Constructor":          {},
            \          "CollectionNode":       {},
            \          "ScalarNode":           {},
            \          "Node":                 {},
            \          "StreamStartEvent":     {},
            \          "DocumentStartEvent":   {},
            \          "DocumentEndEvent":     {},
            \          "ScalarEvent":          {},
            \          "CollectionStartEvent": {},
            \          "NodeEvent":            {},
            \          "Event":                {},
            \          "Token":                {},
            \          "DirectiveToken":       {},
            \          "StreamStartToken":     {},
            \          "AliasToken":           {},
            \          "AnchorToken":          {},
            \          "TagToken":             {},
            \          "ScalarToken":          {},
            \          "SimpleKey":            {},
            \          "Mark":                 {},
            \          "MarkedYAMLError":      {},
            \          "ReaderError":          {},
            \})
"{{{3 s:g.load
let s:g.load={}
" token: { "encoding": ?, "start_mark": mark, "type": String, "end_mark": mark }
" token.DirectiveToken: +{ "name": String }
" token.DirectiveToken(name=YAML): +{ "value": (major, minor) }
"                                               (major, minor :: Uint)
" token.DirectiveToken(name=TAG): +{ "value": (handle, prefix) }
"                                               (handle :: String)
" token.TagToken: +{ "value": (handle, suffix) }
" token.ScalarToken: +{ "value": ?, "plain": Bool, "style": ? }
" node: { "id": unique+String, "type": ( "Scalar" | "Sequence" | "Mapping") }
" node.Mapping: +{ "value": [ (key, value) ] } (key :: node, value :: node)
" node.Sequence: +{ "value": [ node ] }
" node.Scalar: +{ "value": data }
" document: node
" data: { "type": ( "Generator" | ) }
" generator: { "next": (() -> a), "drop": (() -> ()) }
" NodeConstructor: (self + (node[, tag_suffix])) -> data (node?)
" event: { "type": (...), "implicit": ?, "start_mark": mark, "end_mark": mark }
" event.AliasEvent: +{ "anchor": String }
" event.MappingStart: +{ "flow_style": Bool }
" event.SequenceStart: +{ "flow_style": Bool }
" event.Scalar: +{ "value": ?, "style": ? }
" state: event
" path: [ (node_check, index_check) ]
" node_check: (String | { "__class__": "*Node" })
" index_check: (Bool | String | Int | None): Bool: -1:True, -2:False
"                                            None: -2
" yaml_*constructors must contain function references :: NodeConstructor
" yaml_*constructors _none key is a representation of python None key
" implicit: (Bool, Bool)
let s:g.load.BaseConstructor={
            \"yaml_constructors": s:g.constructors[0],
            \"yaml_multi_constructors": s:g.constructors[1],
        \}
unlet s:g.constructors
let s:g.load.Parser={
            \"DEFAULT_TAGS": {
            \   '!':  '!',
            \   '!!': 'tag:yaml.org,2002:',
            \}
        \}
let s:g.load.BaseResolver={
            \"DEFAULT_SCALAR_TAG":   'tag:yaml.org,2002:str',
            \"DEFAULT_SEQUENCE_TAG": 'tag:yaml.org,2002:seq',
            \"DEFAULT_MAPPING_TAG":  'tag:yaml.org,2002:map',
            \"yaml_implicit_resolvers": {},
            \"yaml_path_resolvers": [],
            \"yaml_path_resolver_ids": [],
        \}
let s:g.load.Scanner={
            \"SEPREGEX": '^['.(s:g.yaml.whitespace).(s:g.yaml.linebreak).']\=$',
            \"FLOWREGEX": '^['.(s:g.yaml.whitespace).(s:g.yaml.linebreak).
            \                  (s:g.yaml.flowindicator).(s:g.yaml.comment).
            \                  (s:g.yaml.mappingkey).(s:g.yaml.mappingvalue).
            \                  (s:g.yaml.sequenceentry).
            \                  (s:g.yaml.directivestart).
            \                  (s:g.yaml.anchorstart).(s:g.yaml.aliasstart).
            \                  '''"`|!>@]\=$',
            \"ANEND": '^['.(s:g.yaml.whitespace).(s:g.yaml.linebreak).
            \              (s:g.yaml.directivestart).(s:g.yaml.mappingkey).
            \              (s:g.yaml.mappingvalue).',\]}@]\=$',
            \"ESCAPE_REPLACEMENTS": {
            \   'a':  "\x07",
            \   'b':  "\x08",
            \   't':  "\x09",
            \   "\t": "\x09",
            \   'n':  "\x0A",
            \   'v':  "\x0B",
            \   'f':  "\x0C",
            \   'r':  "\x0D",
            \   'e':  "\x1B",
            \   ' ':  "\x20",
            \   '"':  '"',
            \   '\':  '\',
            \   'N':  "\x85",
            \   '_':  "\xA0",
            \   'L':  "\u2028",
            \   'P':  "\u2029",
            \},
            \"ESCAPE_CODES": {
            \   'x': 2,
            \   'u': 4,
            \   'U': 8,
            \},
        \}
if has("float")
    let s:g.load.SafeConstructor={
                \"inf_value": 1.0e300,
            \}
    " pow(...) is shorter
    while s:g.load.SafeConstructor.inf_value!=
                \pow(s:g.load.SafeConstructor.inf_value, 2)
        let s:g.load.SafeConstructor.inf_value=
                    \pow(s:g.load.SafeConstructor.inf_value, 2)
    endwhile
    let s:g.load.SafeConstructor.nan_value=
                \-(s:g.load.SafeConstructor.inf_value)/
                \ (s:g.load.SafeConstructor.inf_value)
endif
let s:g.load.DirectiveToken={"id": "<directive>",}
let s:g.load.DocumentStartToken={"id": "<document start>",}
let s:g.load.DocumentEndToken={"id": "<document end>",}
let s:g.load.StreamStartToken={"id": "<stream start>",}
let s:g.load.StreamEndToken={"id": "<stream end>",}
"{{{3 Ошибки
"{{{4 load.MarkedYAMLError
"{{{5 load.MarkedYAMLError.__init__
function s:F.load.MarkedYAMLError.__init__(super, context, context_mark,
            \                              problem, problem_mark, note)
    let self.context=a:context
    let self.context_mark=a:context_mark
    let self.problem=a:problem
    let self.problem_mark=a:problem_mark
    let self.note=a:note
endfunction
"{{{5 load.MarkedYAMLError.__str__
function s:F.load.MarkedYAMLError.__str__()
    let lines=[]
    if type(self.context)==type("")
        call add(lines, self.context)
    endif
    if type(self.context_mark)==type({}) &&
                \(type(self.problem)!=type("") ||
                \ type(self.problem_mark)!=type({}) ||
                \ self.context_mark.line!=self.problem_mark.line ||
                \ self.context_mark.column!=self.problem_mark.column)
        call add(lines, self.context_mark.__str__())
    endif
    if type(self.problem)==type("")
        call add(lines, self.problem)
    endif
    if type(self.problem_mark)==type({})
        call add(lines, self.problem_mark.__str__())
    endif
    if type(self.note)==type("")
        call add(lines, self.note)
    endif
    return join(lines, "\n")
endfunction
"{{{4 load.ReaderError
"{{{5 load.ReaderError.__init__
function s:F.load.ReaderError.__init__(super, name, position, character,
            \                          encoding, reason)
    let self.name=a:name
    let self.position=a:position
    let self.character=a:character
    let self.encoding=a:encoding
    let self.reason=a:reason
endfunction
"{{{5 load.ReaderError.__str__
function s:F.load.ReaderError.__str__()
    return printf(s:g.p.remessage, self.character, self.reason, self.name,
                \                  self.position)
endfunction
"{{{3 События
"{{{4 load.Event.__init__
function s:F.load.Event.__init__(super, start_mark, end_mark)
    let self.start_mark=a:start_mark
    let self.end_mark=a:end_mark
endfunction
"{{{4 load.NodeEvent.__init__
function s:F.load.NodeEvent.__init__(super, anchor, start_mark, end_mark)
    let self.start_mark=a:start_mark
    let self.end_mark=a:end_mark
    let self.anchor=a:anchor
endfunction
"{{{4 load.DocumentStartEvent.__init__
function s:F.load.DocumentStartEvent.__init__(super, start_mark, end_mark,
            \                                 explicit, version, tags)
    call call(a:super.__init__, [0, a:start_mark, a:end_mark], self)
    let self.explicit=a:explicit
    let self.version=a:version
    let self.tags=a:tags
endfunction
"{{{4 load.ScalarEvent.__init__
function s:F.load.ScalarEvent.__init__(super, anchor, tag, implicit, value,
            \                          start_mark, end_mark, style)
    call call(a:super.__init__, [0, a:anchor, a:start_mark, a:end_mark], self)
    let self.tag=a:tag
    let self.implicit=a:implicit
    let self.value=a:value
    let self.style=a:style
endfunction
"{{{4 load.DocumentEndEvent.__init__
function s:F.load.DocumentEndEvent.__init__(super, start_mark, end_mark,
            \                               explicit)
    call call(a:super.__init__, [0, a:start_mark, a:end_mark], self)
    let self.explicit=a:explicit
endfunction
"{{{4 load.StreamStartEvent.__init__
function s:F.load.StreamStartEvent.__init__(super, start_mark, end_mark,
            \                               encoding)
    call call(a:super.__init__, [0, a:start_mark, a:end_mark], self)
    let self.encoding=a:encoding
endfunction
"{{{4 load.CollectionStartEvent.__init__
function s:F.load.CollectionStartEvent.__init__(super, anchor, tag, implicit,
            \                                   start_mark, end_mark,
            \                                   flow_style)
    let self.anchor=a:anchor
    let self.tag=a:tag
    let self.implicit=a:implicit
    let self.start_mark=a:start_mark
    let self.end_mark=a:end_mark
    let self.flow_style=a:flow_style
endfunction
"{{{3 Nodes
"{{{4 load.Node.__init__ :: (tag, a, mark, mark, id) -> node
function s:F.load.Node.__init__(super, tag, value, start_mark, end_mark, id)
    let self.tag=a:tag
    let self.value=a:value
    let self.start_mark=a:start_mark
    let self.end_mark=a:end_mark
    let self.id=a:id
endfunction
"{{{4 load.CollectionNode.__init__ :: (tag, a, mark, mark, Bool) -> node
function s:F.load.CollectionNode.__init__(super, tag, value, start_mark,
            \                             end_mark, flow_style, id)
    call call(s:F.load.Node.__init__, [0, a:tag, a:value, a:start_mark,
                \                      a:end_mark, a:id], self)
    let self.flow_style=a:flow_style
endfunction
"{{{4 load.ScalarNode.__init__
function s:F.load.ScalarNode.__init__(super, tag, value, start_mark, end_mark,
            \                         style, id)
    call call(a:super.__init__, [0, a:tag, a:value, a:start_mark, a:end_mark,
                \                a:id], self)
    let self.style=a:style
endfunction
"{{{3 Tokens
"{{{4 load.Token.__init__
function s:F.load.Token.__init__(super, start_mark, end_mark)
    let self.start_mark=a:start_mark
    let self.end_mark=a:end_mark
endfunction
"{{{4 load.DirectiveToken.__init__
function s:F.load.DirectiveToken.__init__(super, name, value, start_mark,
            \                             end_mark)
    call call(a:super.__init__, [0, a:start_mark, a:end_mark], self)
    let self.name=a:name
    let self.value=a:value
endfunction
"{{{4 load.StreamStartToken.__init__
function s:F.load.StreamStartToken.__init__(super, start_mark, end_mark,
            \                               encoding)
    call call(a:super.__init__, [0, a:start_mark, a:end_mark], self)
    let self.encoding=a:encoding
endfunction
"{{{4 load.AliasToken.__init__
function s:F.load.AliasToken.__init__(super, value, start_mark, end_mark)
    call call(a:super.__init__, [0, a:start_mark, a:end_mark], self)
    let self.value=a:value
endfunction
"{{{4 load.AnchorToken.__init__
function s:F.load.AnchorToken.__init__(super, value, start_mark, end_mark)
    call call(a:super.__init__, [0, a:start_mark, a:end_mark], self)
    let self.value=a:value
endfunction
"{{{4 load.TagToken.__init__
function s:F.load.TagToken.__init__(super, value, start_mark, end_mark)
    call call(a:super.__init__, [0, a:start_mark, a:end_mark], self)
    let self.value=a:value
endfunction
"{{{4 load.ScalarToken.__init__
function s:F.load.ScalarToken.__init__(super, value, plain, start_mark,
            \                          end_mark, style)
    call call(a:super.__init__, [0, a:start_mark, a:end_mark], self)
    let self.value=a:value
    let self.plain=a:plain
    let self.style=a:style
endfunction
"{{{3 load.SimpleKey.__init__
function s:F.load.SimpleKey.__init__(super, token_number, required, index,
            \                        line, column, mark)
    let self.token_number=a:token_number
    let self.required=a:required
    let self.index=a:index
    let self.line=a:line
    let self.column=a:column
    let self.mark=a:mark
endfunction
"{{{3 load.Loader
"{{{4 load.Loader.__init__ :: (stream) -> _
function s:F.load.Loader.__init__(super, stream)
    call call(a:super.Reader.__init__,      [0, a:stream], self)
    call call(a:super.Scanner.__init__,     [0],           self)
    call call(a:super.Parser.__init__,      [0],           self)
    call call(a:super.Composer.__init__,    [0],           self)
    call call(a:super.Resolver.__init__,    [0],           self)
    call call(a:super.Constructor.__init__, [0],           self)
    let self.lastid=-1
endfunction
"{{{4 load.Loader.id :: (self + ()) -> id
function s:F.load.Loader.id()
    let self.lastid+=1
    return self.lastid
endfunction
"{{{4 load.Loader.__geterr
function s:F.load.Loader.__geterr(class, ...)
    let class=a:class."Error"
    return call(s:F.plug.oop.getinstance, [class]+a:000, {})
endfunction
"{{{4 load.Loader.__raise
function s:F.load.Loader.__raise(...)
    return call(self.__geterr, a:000, self).raise()
endfunction
"{{{4 load.Loader.__warn
function s:F.load.Loader.__warn(...)
    return call(self.__geterr, a:000, self).warn()
endfunction
"{{{4 load.Loader.__doerr
function s:F.load.Loader.__doerr(e, selfname, class, msgid, context_mark,
            \                    problem_mark, ...)
    if type(a:msgid)==type([])
        let msg=call(function('printf'),
                    \[get(s:g.p.ee, a:msgid[0], a:msgid[0])]+a:msgid[1:])
    else
        let msg=get(s:g.p.ee, a:msgid, a:msgid[0])
    endif
    let [context, problem]=split(msg, '@|', 1)
    let context=printf(s:g.p.emsg.unexc, a:class)."\n".context
    if type(a:selfname)==type("")
        let context=printf(s:g.p.emsg.infun, a:selfname)."\n".context
    endif
    let context=substitute(context, '\_s\+$', '', '')
    let note=get(a:000, 0, "")
    return call(self[a:e], [a:class, context, a:context_mark, problem,
                \           a:problem_mark, note], self)
endfunction
"{{{4 load.Loader._raise
function s:F.load.Loader._raise(...)
    return call(self.__doerr, ["__raise"]+a:000, self)
endfunction
"{{{4 load.Loader._warn
function s:F.load.Loader._warn(...)
    return call(self.__doerr, ["__warn"]+a:000, self)
endfunction
"{{{3 load.Mark
"{{{4 load.Mark.__init__
function s:F.load.Mark.__init__(super, name, index, line, column, buffer,
            \                   pointer)
    let self.name=a:name
    let self.index=a:index
    let self.line=a:line
    let self.column=a:column
    let self.buffer=copy(a:buffer)
    let self.pointer=a:pointer
endfunction
"{{{4 load.Mark.get_snippet
function s:F.load.Mark.get_snippet(...)
    let indent=get(a:000, 0, 4)
    let max_length=get(a:000, 1, &columns)
    if empty(self.buffer)
        return ""
    endif
    let head=""
    let start=self.pointer
    while start>0 &&
                \get(self.buffer, start-1, "")!~#'^['.s:g.yaml.linebreak.']\=$'
        let start-=1
        if self.pointer-start > max_length/2-1
            let head=' ... '
            let start+=5
            break
        endif
    endwhile
    let tail=''
    let end=self.pointer
    let lbuffer=len(self.buffer)
    while end<lbuffer &&
                \get(self.buffer, end, "")!~#'^['.s:g.yaml.linebreak.']\=$'
        let end+=1
        if end-self.pointer > max_length/2-1
            let tail=' ... '
            let end-=5
            break
        endif
    endwhile
    let snippet=join(self.buffer[(start):(end-1)], "")
    return repeat(" ", indent).head.snippet.tail."\n".
                \repeat(" ", indent+self.pointer-start+len(head)).'^'
endfunction
"{{{4 load.Mark.__str__
function s:F.load.Mark.__str__()
    let snippet=self.get_snippet()
    let where=printf(s:g.p.markmessage, self.name, self.line+1, self.column+1)
    if snippet!=#""
        let where.=":\n".snippet
    endif
    return where
endfunction
"{{{3 load.Reader
"{{{4 load.Reader.__init__ :: (stream) -> _
function s:F.load.Reader.__init__(super, stream)
    let self.name="" " = None
    let self.stream="" " = None
    let self.stream_pointer=0
    let self.eof=1 " :: Bool
    let self.buffer=[]
    let self.pointer=0
    let self.raw_buffer=0 " = None
    " self.raw_decode :: (String, Bool) -> ([ Char ], Maybe UInt)
    " Bool: self.eof (?)
    " String: List of raw characters
    " Maybe UInt: UInt or negative number. -(1+negative number) indicates an
    "                                      index of invalid character
    " Char: List of decoded characters
    let self.raw_decode=0 " = None
    let self.encoding="" " = None
    let self.index=0 " = None
    let self.raw_index=0
    let self.line=0
    let self.column=0

    let self.stream=a:stream
    let self.name="<unicode string>"
    let self.eof=0
    let self.raw_buffer=""
    " self.check_printable(a:stream)
    " let self.buffer=split(a:stream, '\zs')
endfunction
"{{{4 load.Reader.get_mark :: (self + ()) -> mark
function s:F.load.Reader.get_mark()
    if self.stream==#""
        return s:F.plug.oop.getinstance("Mark", self.name, self.index,
                    \                   self.line, self.column,
                    \                   self.buffer, self.pointer)
    else
        return s:F.plug.oop.getinstance("Mark", self.name, self.index,
                    \                   self.line, self.column, self.buffer,
                    \                   self.pointer)
    endif
endfunction
"{{{4 load.Reader.update_raw (self + ([UInt])) -> _
function s:F.load.Reader.update_raw(...)
    let size=128
    if !empty(a:000)
        let size=a:000[0]
    endif
    " self.read(size)
    let data=matchstr(self.stream, '^.\{0,'.size.'}', self.stream_pointer)
    let self.raw_buffer.=data
    let self.stream_pointer+=len(data)
    if data==#""
        let self.eof=1
    endif
endfunction
"{{{4 load.Reader.update (self + (UInt)) -> _
function s:F.load.Reader.update(length)
    let selfname='Reader.update'
    if type(self.raw_buffer)!=type("")
        return
    endif
    let self.buffer=self.buffer[(self.pointer):]
    let self.pointer=0
    while len(self.buffer)<a:length
        if !self.eof
            call self.update_raw()
        endif
        if type(self.raw_decode)==2
            let [data, converted]=call(self.raw_decode, [self.raw_buffer,
                        \                                self.eof], {})
            if converted<0
                let estart=(-(converted+1))
                let character=self.raw_buffer[(estart):]
                if self.stream!=#""
                    " XXX this probably cannot determine true position
                    let position=self.stream_pointer-len(self.raw_buffer)+estart
                else
                    let position=estart
                endif
                call self.__raise("Reader", self.name, position,
                            \     char2nr(character), "utf-8", "")
            endif
        else
            let data=split(self.raw_buffer, '\zs')
            let converted=len(self.raw_buffer)
        endif
        call self.check_printable(data)
        let self.buffer+=data
        let self.raw_buffer=self.raw_buffer[(converted):]
        if self.eof
            call add(self.buffer, "")
            let self.raw_buffer=""
            break
        endif
    endwhile
endfunction
"{{{4 load.Reader.peek :: (self + ([UInt])) -> Maybe Char
function s:F.load.Reader.peek(...)
    if empty(a:000)
        let index=0
    else
        let index=a:000[0]
    endif
    let idx=self.pointer+index
    if idx<len(self.buffer)
        return self.buffer[idx]
    else
        call self.update(index+1)
        return get(self.buffer, self.pointer+index, "")
    endif
endfunction
"{{{4 load.Reader.prefix :: (self + ([UInt])) -> String
function s:F.load.Reader.prefix(...)
    let length=1
    if !empty(a:000)
        let length=a:000[0]
    endif
    if (self.pointer+length)>=len(self.buffer)
        call self.update(length)
    endif
    return join(self.buffer[(self.pointer):(self.pointer+length-1)], "")
endfunction
"{{{4 load.Reader.forward :: (self + ([UInt])) -> _
function s:F.load.Reader.forward(...)
    let length=1
    if !empty(a:000)
        let length=a:000[0]
    endif
    if (self.pointer+length+1)>=len(self.buffer)
        call self.update(length+1)
    endif
    while length
        let ch=self.buffer[self.pointer]
        let self.pointer+=1
        let self.index+=1
        let self.raw_index+=len(ch)
        if ch==#"\n" || (ch==#"\r" && self.buffer[self.pointer]!=#"\n")
            let self.line+=1
            let self.column=0
        elseif ch!=#"\uFEFF" " XXX BOM
            let self.column+=1
        endif
        let length-=1
    endwhile
endfunction
"{{{4 load.Reader.check_printable :: (self + ([ Char ])) -> _
function s:F.load.Reader.check_printable(data)
    let selfname='Reader.check_printable'
    let index=0
    for ch in a:data
        if !empty(ch) && !s:F.comm.isprintchar(ch) && !(self.index==0 &&
                    \                                   index==0 &&
                    \                                   ch==#"\uFEFF")
            let position=self.index+(len(self.buffer)-self.pointer)+index
            call self.__raise("Reader", self.name, position, char2nr(ch),
                        \     "utf-8", s:g.p.emsg.spna)
        endif
        let index+=1
    endfor
endfunction
"{{{3 load.Scanner
"{{{4 load.Scanner.__init__ :: () -> _
function s:F.load.Scanner.__init__(super)
    let self.done=0 " :: Bool
    " Number of unclosed [ and {, flow_level=0 means block context
    let self.flow_level=0 " :: UInt
    " List of processed tokens that are not yet emitted
    let self.tokens=[]
    " Fetch the STREAM-START token
    call self.fetch_stream_start()
    " Number of tokens that were emitted through the `get_token' method
    let self.tokens_taken=0
    " Current indentation level
    let self.indent=-1
    " Past indentation levels
    let self.indents=[]

    " Variables related to simple keys treatment.

    " A simple key is a key that is not denoted by the '?' indicator.
    " Example of simple keys:
    "   ---
    "   block simple key: value
    "   ? not a simple key:
    "   : { flow simple key: value }
    " We emit the KEY token before all keys, so when we find a potential
    " simple key, we try to locate the corresponding ':' indicator.
    " Simple keys should be limited to a single line and 1024 characters.

    " Can a simple key start at the current position? A simple key may
    " start:
    " - at the beginning of the line, not counting indentation spaces
    "       (in block context),
    " - after '{', '[', ',' (in the flow context),
    " - after '?', ':', '-' (in the block context).
    " In the block context, this flag also signifies if a block collection
    " may start at the current position.
    let self.allow_simple_key=1 " :: Bool

    " Keep track of possible simple keys. This is a dictionary. The key
    " is `flow_level`; there can be no more that one possible simple key
    " for each level. The value is a SimpleKey record:
    "   (token_number, required, index, line, column, mark)
    " A simple key may start with ALIAS, ANCHOR, TAG, SCALAR(flow),
    " '[', or '{' tokens.
    let self.possible_simple_keys={}
endfunction
"{{{4 token
"{{{5 load.Scanner.check_token :: (self + (Class*)) -> Bool
function s:F.load.Scanner.check_token(...)
    call self.more_tokens()
    if !empty(self.tokens)
        if empty(a:000)
            return 1
        endif
        for choice in a:000
            if self.tokens[0].__class__==#choice
                return 1
            endif
        endfor
    endif
    return 0
endfunction
"{{{5 load.Scanner.peek_token :: (self + ()) -> token
function s:F.load.Scanner.peek_token()
    call self.more_tokens()
    return get(self.tokens, 0, {})
endfunction
"{{{5 load.Scanner.get_token :: (self + ()) -> token
function s:F.load.Scanner.get_token()
    call self.more_tokens()
    if !empty(self.tokens)
        let self.tokens_taken+=1
        return remove(self.tokens, 0)
    endif
    return 0
endfunction
"{{{5 load.Scanner.need_more_tokens :: (self + ()) -> Bool
function s:F.load.Scanner.need_more_tokens()
    if self.done
        return 0
    endif
    if empty(self.tokens)
        return 1
    endif
    call self.stale_possible_simple_keys()
    if self.next_possible_simple_key()==self.tokens_taken
        return 1
    endif
    return 0
endfunction
"{{{5 load.Scanner.more_tokens :: (self + ()) -> _
function s:F.load.Scanner.more_tokens()
    while self.need_more_tokens()
        call self.fetch_more_tokens()
    endwhile
endfunction
"{{{5 load.Scanner.fetch_more_tokens :: (self + ()) -> _
let s:g.load.scanner={}
let s:g.load.scanner.chtofname={
            \'[': 'fetch_flow_sequence_start',
            \'{': 'fetch_flow_mapping_start',
            \'}': 'fetch_flow_mapping_end',
            \']': 'fetch_flow_sequence_end',
            \',': 'fetch_flow_entry',
            \'*': 'fetch_alias',
            \'&': 'fetch_anchor',
            \'!': 'fetch_tag',
            \"'": 'fetch_single',
            \'"': 'fetch_double',
        \}
function s:F.load.Scanner.fetch_more_tokens()
    let selfname='Scanner.fetch_more_tokens'
    call self.scan_to_next_token()         " Skip ws and comments
    call self.stale_possible_simple_keys() " Remove obsolete simple keys
    call self.unwind_indent(self.column)   " Compare the current indentation and 
                                           " column. It may add some tokens and 
                                           " decrease the current indentation 
                                           " level
    let ch=self.peek()
    if ch==#''
        return self.fetch_stream_end()
    elseif ch==#'%' && self.check_directive()
        return self.fetch_directive()
    elseif ch==#'-' && self.check_document_start()
        return self.fetch_document_start()
    elseif ch==#'.' && self.check_document_end()
        return self.fetch_document_end()
    elseif has_key(s:g.load.scanner.chtofname, ch)
        return self[s:g.load.scanner.chtofname[ch]]()
    elseif ch==#'-' && self.check_block_entry()
        return self.fetch_block_entry()
    elseif ch==#'?' && self.check_key()
        return self.fetch_key()
    elseif ch==#':' && self.check_value()
        return self.fetch_value()
    elseif ch==#'|' && !self.flow_level
        return self.fetch_literal()
    elseif ch==#'>' && !self.flow_level
        return self.fetch_folded()
    elseif self.check_plain()
        return self.fetch_plain()
    endif
    call self._raise(selfname, "Scanner", ["nottkstrt", ch], 0,
                \    self.get_mark())
endfunction
"{{{4 Simple key treatment
"{{{5 load.Scanner.next_possible_simple_key :: (self + ()) -> UInt
function s:F.load.Scanner.next_possible_simple_key()
    let min_token_number=0
    for level in keys(self.possible_simple_keys)
        let key=self.possible_simple_keys[level]
        if !min_token_number || key.token_number<min_token_number
            let min_token_number=key.token_number
        endif
    endfor
    return min_token_number
endfunction
"{{{5 load.Scanner.stale_possible_simple_keys :: (self + ()) -> _
function s:F.load.Scanner.stale_possible_simple_keys()
    let selfname='Scanner.stale_possible_simple_keys'
    " Remove entries that are no longer possible simple keys. According to
    " the YAML specification, simple keys
    " - should be limited to a single line,
    " - should be no longer than 1024 characters.
    " Disabling this procedure will allow simple keys of any length and
    " height (may cause problems if indentation is broken though).
    for [level, key] in items(self.possible_simple_keys)
        if key.line!=self.line || (self.index-key.index)>1024
            if key.required
                call self._raise(selfname, "Scanner", "sknc", key.mark, self.get_mark())
            endif
            unlet self.possible_simple_keys[level]
        endif
    endfor
endfunction
"{{{5 load.Scanner.save_possible_simple_key :: (self + ()) -> _
function s:F.load.Scanner.save_possible_simple_key()
    let required=(!self.flow_level && self.indent==self.column)
    " assert self.allow_simple_key or not required
    if self.allow_simple_key
        call self.remove_possible_simple_key()
        let token_number=self.tokens_taken+len(self.tokens)
        let key=s:F.plug.oop.getinstance("SimpleKey", token_number, required,
                    \                    self.index, self.line, self.column,
                    \                    self.get_mark())
        let self.possible_simple_keys[self.flow_level]=key
    endif
endfunction
"{{{5 load.Scanner.remove_possible_simple_key :: (self + ()) -> _
function s:F.load.Scanner.remove_possible_simple_key()
    let selfname='Scanner.remove_possible_simple_key'
    if has_key(self.possible_simple_keys, self.flow_level)
        let key=self.possible_simple_keys[self.flow_level]
        if key.required
            call self.__raise(selfname, "scanner", "sknc")
        endif
        unlet self.possible_simple_keys[self.flow_level]
    endif
endfunction
"{{{4 indent
"{{{5 load.Scanner.unwind_indent :: (self + (column)) -> _
function s:F.load.Scanner.unwind_indent(column)
    " In the flow context, indentation is ignored. We make the scanner less
    " restrictive then specification requires.
    if self.flow_level
        return 0
    endif

    " In block context, we may need to issue the BLOCK-END tokens.
    while self.indent>a:column
        let mark=self.get_mark()
        let self.indent=remove(self.indents, -1)
        call add(self.tokens, s:F.plug.oop.getinstance("BlockEndToken", mark,
                    \                                  mark))
    endwhile
endfunction
"{{{5 load.Scanner.add_indent :: (self + (column)) -> Bool
function s:F.load.Scanner.add_indent(column)
    if self.indent<a:column
        call add(self.indents, self.indent)
        let self.indent=a:column
        return 1
    endif
    return 0
endfunction
"{{{4 fetchers
"{{{5 load.Scanner.fetch_stream_start :: (self + ()) -> _
function s:F.load.Scanner.fetch_stream_start()
    let mark=self.get_mark()
    call add(self.tokens, s:F.plug.oop.getinstance("StreamStartToken", mark,
                \                                  mark, self.encoding))
endfunction
"{{{5 load.Scanner.fetch_stream_end :: (self + ()) -> _
function s:F.load.Scanner.fetch_stream_end()
    call self.unwind_indent(-1)
    call self.remove_possible_simple_key()
    let self.allow_simple_key=0
    let self.possible_simple_keys={}
    let mark=self.get_mark()
    call add(self.tokens, s:F.plug.oop.getinstance("StreamEndToken", mark,
                \                                  mark))
    let self.done=1
endfunction
"{{{5 load.Scanner.fetch_directive :: (self + ()) -> _
function s:F.load.Scanner.fetch_directive()
    call self.unwind_indent(-1)
    call self.remove_possible_simple_key()
    let self.allow_simple_key=0
    call add(self.tokens, self.scan_directive())
endfunction
"{{{5 load.Scanner.fetch_document_start :: (self + ()) -> _
function s:F.load.Scanner.fetch_document_start()
    call self.fetch_document_indicator("DocumentStartToken")
endfunction
"{{{5 load.Scanner.fetch_document_end :: (self + ()) -> _
function s:F.load.Scanner.fetch_document_end()
    call self.fetch_document_indicator("DocumentEndToken")
endfunction
"{{{5 load.Scanner.fetch_document_indicator :: (self + (Class)) -> _
function s:F.load.Scanner.fetch_document_indicator(tokenclass)
    call self.unwind_indent(-1)
    call self.remove_possible_simple_key()
    let self.allow_simple_key=0
    let start_mark=self.get_mark()
    call self.forward(3)
    let end_mark=self.get_mark()
    call add(self.tokens, s:F.plug.oop.getinstance(a:tokenclass, start_mark,
                \                                  end_mark))
endfunction
"{{{5 load.Scanner.fetch_flow_sequence_start :: (self + ()) -> _
function s:F.load.Scanner.fetch_flow_sequence_start()
    call self.fetch_flow_collection_start("FlowSequenceStartToken")
endfunction
"{{{5 load.Scanner.fetch_flow_mapping_start :: (self + ()) -> _
function s:F.load.Scanner.fetch_flow_mapping_start()
    call self.fetch_flow_collection_start("FlowMappingStartToken")
endfunction
"{{{5 load.Scanner.fetch_flow_collection_start :: (self + (Class)) -> _
function s:F.load.Scanner.fetch_flow_collection_start(tokenclass)
    call self.save_possible_simple_key()
    let self.flow_level+=1
    let self.allow_simple_key=1
    let start_mark=self.get_mark()
    call self.forward()
    let end_mark=self.get_mark()
    call add(self.tokens, s:F.plug.oop.getinstance(a:tokenclass, start_mark,
                \                                  end_mark))
endfunction
"{{{5 load.Scanner.fetch_flow_sequence_end :: (self + ()) -> _
function s:F.load.Scanner.fetch_flow_sequence_end()
    call self.fetch_flow_collection_end("FlowSequenceEndToken")
endfunction
"{{{5 load.Scanner.fetch_flow_mapping_end :: (self + ()) -> _
function s:F.load.Scanner.fetch_flow_mapping_end()
    call self.fetch_flow_collection_end("FlowMappingEndToken")
endfunction
"{{{5 load.Scanner.fetch_flow_collection_end :: (self + (Class)) -> _
function s:F.load.Scanner.fetch_flow_collection_end(tokenclass)
    call self.remove_possible_simple_key()
    let self.flow_level-=1
    let self.allow_simple_key=0
    let start_mark=self.get_mark()
    call self.forward()
    let end_mark=self.get_mark()
    call add(self.tokens, s:F.plug.oop.getinstance(a:tokenclass, start_mark,
                \                                  end_mark))
endfunction
"{{{5 load.Scanner.fetch_flow_entry :: (self + ()) -> _
function s:F.load.Scanner.fetch_flow_entry()
    let self.allow_simple_key=1
    call self.remove_possible_simple_key()
    let start_mark=self.get_mark()
    call self.forward()
    let end_mark=self.get_mark()
    call add(self.tokens, s:F.plug.oop.getinstance("FlowEntryToken", start_mark,
                \                                  end_mark))
endfunction
"{{{5 load.Scanner.fetch_block_entry :: (self + ()) -> _
function s:F.load.Scanner.fetch_block_entry()
    let selfname='Scanner.fetch_block_entry'
    if !self.flow_level
        if !self.allow_simple_key
            call self._raise(selfname, "Scanner", "seqnall", 0, self.get_mark())
        endif
        if self.add_indent(self.column)
            let mark=self.get_mark()
            call add(self.tokens, s:F.plug.oop.getinstance(
                        \"BlockSequenceStartToken", mark, mark))
        endif
    else
        " pass
        return 0
    endif
    let self.allow_simple_key=1
    call self.remove_possible_simple_key()
    let start_mark=self.get_mark()
    call self.forward()
    let end_mark=self.get_mark()
    call add(self.tokens, s:F.plug.oop.getinstance("BlockEntryToken",
                \                                  start_mark, end_mark))
endfunction
"{{{5 load.Scanner.fetch_key :: (self + ()) -> _
function s:F.load.Scanner.fetch_key()
    let selfname='Scanner.fetch_key'
    if !self.flow_level
        if !self.allow_simple_key
            call self._raise(selfname, "Scanner", "mnotall", 0, self.get_mark())
        elseif self.add_indent(self.column)
            let mark=self.get_mark()
            call add(self.tokens, s:F.plug.oop.getinstance(
                        \"BlockMappingStartToken", mark, mark))
        endif
    endif
    " Simple keys are allowed after '?' in the block context
    let self.allow_simple_key=!self.flow_level
    call self.remove_possible_simple_key()
    let start_mark=self.get_mark()
    call self.forward()
    let end_mark=self.get_mark()
    call add(self.tokens, s:F.plug.oop.getinstance("KeyToken", start_mark,
                \                                  end_mark))
endfunction
"{{{5 load.Scanner.fetch_value :: (self + ()) -> _
function s:F.load.Scanner.fetch_value()
    let selfname='Scanner.fetch_value'
    if has_key(self.possible_simple_keys, self.flow_level)
        let key=remove(self.possible_simple_keys, self.flow_level)
        call insert(self.tokens, s:F.plug.oop.getinstance("KeyToken", key.mark,
                    \key.mark), key.token_number-self.tokens_taken)
        if !self.flow_level && self.add_indent(key.column)
            call insert(self.tokens, s:F.plug.oop.getinstance(
                        \"BlockMappingStartToken", key.mark, key.mark),
                        \key.token_number-self.tokens_taken)
        endif
        " There cannot be two simple keys one after another
        let self.allow_simple_key=0
    else
        if !self.flow_level && !self.allow_simple_key
            call self._raise(selfname, "Scanner", "mnotall", 0, self.get_mark())
        endif
        if !self.flow_level
            if self.add_indent(self.column)
                let mark=self.get_mark()
                call add(self.tokens, s:F.plug.oop.getinstance(
                            \"BlockMappingStartToken", mark, mark))
            endif
        endif
        " Simple keys are allowed after ':' in the block context
        let self.allow_simple_key=!self.flow_level
        call self.remove_possible_simple_key()
    endif
    let start_mark=self.get_mark()
    call self.forward()
    let end_mark=self.get_mark()
    call add(self.tokens, s:F.plug.oop.getinstance("ValueToken", start_mark,
                \                                  end_mark))
endfunction
"{{{5 load.Scanner.fetch_alias :: (self + ()) -> _
function s:F.load.Scanner.fetch_alias()
    call self.save_possible_simple_key()
    let self.allow_simple_key=0
    call add(self.tokens, self.scan_anchor("AliasToken"))
endfunction
"{{{5 load.Scanner.fetch_anchor :: (self + ()) -> _
function s:F.load.Scanner.fetch_anchor()
    call self.save_possible_simple_key()
    let self.allow_simple_key=0
    call add(self.tokens, self.scan_anchor("AnchorToken"))
endfunction
"{{{5 load.Scanner.fetch_tag :: (self + ()) -> _
function s:F.load.Scanner.fetch_tag()
    call self.save_possible_simple_key()
    let self.allow_simple_key=0
    call add(self.tokens, self.scan_tag())
endfunction
"{{{5 load.Scanner.fetch_literal :: (self + ()) -> _
function s:F.load.Scanner.fetch_literal()
    call self.fetch_block_scalar('|')
endfunction
"{{{5 load.Scanner.fetch_folded :: (self + ()) -> _
function s:F.load.Scanner.fetch_folded()
    call self.fetch_block_scalar('>')
endfunction
"{{{5 load.Scanner.fetch_block_scalar :: (self + (style)) -> _
function s:F.load.Scanner.fetch_block_scalar(style)
    let self.allow_simple_key=1
    call self.remove_possible_simple_key()
    call add(self.tokens, self.scan_block_scalar(a:style))
endfunction
"{{{5 load.Scanner.fetch_single :: (self + ()) -> _
function s:F.load.Scanner.fetch_single()
    call self.fetch_flow_scalar("'")
endfunction
"{{{5 load.Scanner.fetch_double :: (self + ()) -> _
function s:F.load.Scanner.fetch_double()
    call self.fetch_flow_scalar('"')
endfunction
"{{{5 load.Scanner.fetch_flow_scalar :: (self + (style)) -> _
function s:F.load.Scanner.fetch_flow_scalar(style)
    call self.save_possible_simple_key()
    let self.allow_simple_key=0
    call add(self.tokens, self.scan_flow_scalar(a:style))
endfunction
"{{{5 load.Scanner.fetch_plain :: (self + ()) -> _
function s:F.load.Scanner.fetch_plain()
    call self.save_possible_simple_key()
    let self.allow_simple_key=0
    call add(self.tokens, self.scan_plain())
endfunction
"{{{4 checkers
"{{{5 load.Scanner.check_directive :: (self + ()) -> Bool
function s:F.load.Scanner.check_directive()
    if self.column==0
        return 1
    endif
    return 0
endfunction
"{{{5 load.Scanner.check_document_start :: (self + ()) -> Bool
function s:F.load.Scanner.check_document_start()
    if self.column==0 && self.prefix(3)==#'---' &&
                \self.peek(3)=~#self.SEPREGEX
        return 1
    endif
    return 0
endfunction
"{{{5 load.Scanner.check_document_end :: (self + ()) -> Bool
function s:F.load.Scanner.check_document_end()
    if self.column==0 && self.prefix(3)==#'...' &&
                \self.peek(3)=~#self.SEPREGEX
        return 1
    endif
    return 0
endfunction
"{{{5 load.Scanner.check_block_entry :: (self + ()) -> Bool
function s:F.load.Scanner.check_block_entry()
    return self.peek(1)=~#self.SEPREGEX
endfunction
"{{{5 load.Scanner.check_key :: (self + ()) -> Bool
function s:F.load.Scanner.check_key()
    if self.flow_level
        return 1
    else
        return self.peek(1)=~#self.SEPREGEX
    endif
endfunction
"{{{5 load.Scanner.check_value :: (self + ()) -> Bool
function s:F.load.Scanner.check_value()
    if self.flow_level
        return 1
    else
        return self.peek(1)=~#self.SEPREGEX
    endif
endfunction
"{{{5 load.Scanner.check_plain :: (self + ()) -> Bool
function s:F.load.Scanner.check_plain()
    let ch=self.peek()
    return (ch!~#self.FLOWREGEX || (self.peek(1)!~#self.SEPREGEX &&
                \                   ch==#'-' || (!self.flow_level &&
                \                                (ch==#'?' || ch==#':'))))
endfunction
"{{{4 scanners
"{{{5 load.Scanner.scan_to_next_token :: (self + ()) -> _
function s:F.load.Scanner.scan_to_next_token()
    " We ignore spaces, line breaks and comments.
    " If we find a line break in the block context, we set the flag
    " `allow_simple_key` on.
    " The byte order mark is stripped if it's the first character in the
    " stream. We do not yet support BOM inside the stream as the
    " specification requires. Any such mark will be considered as a part
    " of the document.
    if self.index==0 && self.peek()==#"\uFEFF"
        call self.forward()
    endif
    let found=0
    while !found
        while self.peek()=~#'^['.s:g.yaml.whitespace.']$'
            call self.forward()
        endwhile
        if self.peek()==#s:g.yaml.comment
            while self.peek()!~#'^['.s:g.yaml.linebreak.']\=$'
                call self.forward()
            endwhile
        endif
        if self.scan_line_break()!=#""
            if !self.flow_level
                let self.allow_simple_key=1
            endif
        else
            let found=1
        endif
    endwhile
endfunction
"{{{5 load.Scanner.scan_directive :: (self + ()) -> token
function s:F.load.Scanner.scan_directive()
    let start_mark=self.get_mark()
    call self.forward()
    let name=self.scan_directive_name(start_mark)
    let value="" " = None
    if name==#"YAML"
        unlet value
        let value=self.scan_yaml_directive_value(start_mark)
        let end_mark=self.get_mark()
    elseif name==#"TAG"
        unlet value
        let value=self.scan_tag_directive_value(start_mark)
        let end_mark=self.get_mark()
    else
        let end_mark=self.get_mark()
        while self.peek()!~#self.SEPREGEX
            call self.forward()
        endwhile
    endif
    call self.scan_directive_ignored_line(start_mark)
    return s:F.plug.oop.getinstance("DirectiveToken", name, value,
                \                   start_mark, end_mark)
endfunction
"{{{5 load.Scanner.scan_directive_name :: (self + (mark)) -> String
function s:F.load.Scanner.scan_directive_name(start_mark)
    let selfname='Scanner.scan_directive_name'
    let length=0
    let ch=self.peek(length)
    while s:F.comm.isnschar(ch)
        let length+=1
        let ch=self.peek(length)
    endwhile
    if !length
        call self._raise(selfname, "Scanner", ["ndirname", ch], a:start_mark,
                    \    self.get_mark())
    endif
    let value=self.prefix(length)
    call self.forward(length)
    let ch=self.peek()
    if ch!~#self.SEPREGEX
        call self._raise(selfname, "Scanner", ["ndirend", ch], a:start_mark,
                    \    self.get_mark())
    endif
    return value
endfunction
"{{{5 load.Scanner.scan_yaml_directive_value :: (self + (mark)) -> (UInt,UInt)
function s:F.load.Scanner.scan_yaml_directive_value(start_mark)
    let selfname='Scanner.scan_yaml_directive_value'
    while self.peek()=~#'^['.s:g.yaml.whitespace.']'
        call self.forward()
    endwhile
    let major=self.scan_yaml_directive_number(a:start_mark)
    if self.peek()!=#'.'
        call self._raise(selfname, "Scanner", ["nYAMLdsep", self.peek()],
                    \    a:start_mark, self.get_mark())
    endif
    call self.forward()
    let minor=self.scan_yaml_directive_number(a:start_mark)
    if self.peek()!~#self.SEPREGEX
        call self._raise(selfname, "Scanner", ["nYAMLws", self.peek()],
                    \    a:start_mark, self.get_mark())
    endif
    return [major, minor]
endfunction
"{{{5 load.Scanner.scan_yaml_directive_number :: (self + (mark)) -> UInt
function s:F.load.Scanner.scan_yaml_directive_number(start_mark)
    let selfname='Scanner.scan_yaml_directive_number'
    let ch=self.peek()
    if ch!~#'^\d$'
        call self._raise(selfname, "Scanner", ["nYAMLd", ch], a:start_mark,
                    \    self.get_mark())
    endif
    let length=0
    while self.peek(length)=~#'^\d$'
        let length+=1
    endwhile
    let value=(self.prefix(length))+0
    call self.forward(length)
    return value
endfunction
"{{{5 load.Scanner.scan_tag_directive_value :: (self + (mark)) -> (Str,Str)
function s:F.load.Scanner.scan_tag_directive_value(start_mark)
    while self.peek()=~#'^['.s:g.yaml.whitespace.']$'
        call self.forward()
    endwhile
    let handle=self.scan_tag_directive_handle(a:start_mark)
    while self.peek()=~#'^['.s:g.yaml.whitespace.']$'
        call self.forward()
    endwhile
    let prefix=self.scan_tag_directive_prefix(a:start_mark)
    return [handle, prefix]
endfunction
"{{{5 load.Scanner.scan_tag_directive_handle :: (self + (mark)) -> String
function s:F.load.Scanner.scan_tag_directive_handle(start_mark)
    let selfname='Scanner.scan_tag_directive_handle'
    let value=self.scan_tag_handle("directive", a:start_mark)
    let ch=self.peek()
    if ch!~#'^['.s:g.yaml.whitespace.']$'
        call self._raise(selfname, "Scanner", ["nTAGsep", ch], a:start_mark,
                    \    self.get_mark())
    endif
    return value
endfunction
"{{{5 load.Scanner.scan_tag_directive_prefix :: (self + (mark)) -> String
function s:F.load.Scanner.scan_tag_directive_prefix(start_mark)
    let value=self.scan_tag_uri('directive', a:start_mark)
    let ch=self.peek()
    if ch!~#self.SEPREGEX
        call self._raise(selfname, "Scanner", ["nTAGesep", ch], a:start_mark,
                    \    self.get_mark())
    endif
    return value
endfunction
"{{{5 load.Scanner.scan_directive_ignored_line :: (self + (mark)) -> _
function s:F.load.Scanner.scan_directive_ignored_line(start_mark)
    let selfname='Scanner.scan_directive_ignored_line'
    while self.peek()=~#'^['.s:g.yaml.whitespace.']'
        call self.forward()
    endwhile
    if self.peek()==#s:g.yaml.comment
        while self.peek()!~#'^['.s:g.yaml.linebreak.']\=$'
            call self.forward()
        endwhile
    endif
    let ch=self.peek()
    if ch!~#'^['.s:g.yaml.linebreak.']\=$'
        call self._raise(selfname, "Scanner", ['ndirlend', ch], a:start_mark,
                    \    self.get_mark())
    endif
    call self.scan_line_break()
endfunction
"{{{5 load.Scanner.scan_anchor :: (self + (Class)) -> token
function s:F.load.Scanner.scan_anchor(tokenclass)
    let selfname='Scanner.scan_anchor'
    let start_mark=self.get_mark()
    let indicator=self.peek()
    let isalias=0
    if indicator==#s:g.yaml.anchorstart
        let isalias=1
    endif
    call self.forward()
    let length=0
    let ch=self.peek(length)
    while s:F.comm.isanchorchar(ch)
        let length+=1
        let ch=self.peek(length)
    endwhile
    if !length
        call self._raise(selfname, "Scanner",
                    \    [((isalias)?("nalname"):("nanname")), ch],
                    \    start_mark, self.get_mark())
    endif
    let value=self.prefix(length)
    call self.forward(length)
    let ch=self.peek()
    if ch!~#self.ANEND
        call self._raise(selfname, "Scanner",
                    \    [((isalias)?("nalend"):("nanend")), ch],
                    \    start_mark, self.get_mark())
    endif
    let end_mark=self.get_mark()
    return s:F.plug.oop.getinstance(a:tokenclass, value, start_mark, end_mark)
endfunction
"{{{5 load.Scanner.scan_tag :: (self + ()) -> token
function s:F.load.Scanner.scan_tag()
    let selfname='Scanner.scan_tag'
    let start_mark=self.get_mark()
    let ch=self.peek(1)
    if ch==#'<'
        let handle=""
        call self.forward(2)
        let suffix=self.scan_tag_uri('tag', start_mark)
        if self.peek()!=#'>'
            call self._raise(selfname, "Scanner", ["ntagendgt", self.peek()],
                        \    start_mark, self.get_mark())
        endif
        call self.forward()
    else
        let length=1
        let use_handle=0 " :: Bool
        while ch!~#self.SEPREGEX
            if ch==#'!'
                let use_handle=1
                break
            endif
            let length+=1
            let ch=self.peek(length)
        endwhile
        let handle='!'
        if use_handle
            let handle=self.scan_tag_handle('tag', start_mark)
        else
            call self.forward()
        endif
        let suffix=self.scan_tag_uri('tag', start_mark)
    endif
    let ch=self.peek()
    if ch!~#self.SEPREGEX
        call self._raise(selfname, "Scanner", ["ntagend", ch],
                    \    start_mark, self.get_mark())
    endif
    let value=[handle, suffix]
    let end_mark=self.get_mark()
    return s:F.plug.oop.getinstance("TagToken", value, start_mark, end_mark)
endfunction
"{{{5 load.Scanner.scan_block_scalar :: (self + (style)) -> token
function s:F.load.Scanner.scan_block_scalar(style)
    let folded=(a:style==#'>')
    let chunks=[]
    let start_mark=self.get_mark()
    call self.forward()
    let [chomping, increment]=self.scan_block_scalar_indicators(start_mark)
    call self.scan_block_scalar_ignored_line(start_mark)
    let min_indent=self.indent+1
    if min_indent<1
        let min_indent=1
    endif
    if !increment
        let [breaks, max_indent, end_mark]=self.scan_block_scalar_indentation()
        let indent=max([min_indent, max_indent])
    else
        let indent=min_indent+increment-1
        let [breaks, end_mark]=self.scan_block_scalar_breaks(indent)
    endif
    let line_break=''
    while self.column==indent && self.peek()!=#""
        call extend(chunks, breaks)
        let leading_non_space=(self.peek()!~#'^['.s:g.yaml.whitespace.']$')
        let length=0
        while self.peek(length)!~#'^['.s:g.yaml.linebreak.']\=$'
            let length+=1
        endwhile
        call add(chunks, self.prefix(length))
        call self.forward(length)
        let line_break=self.scan_line_break()
        let [breaks, end_mark]=self.scan_block_scalar_breaks(indent)
        if self.column==indent && self.peek()!=#""
            if folded && line_break==#"\n" && leading_non_space &&
                        \self.peek()!~#'^['.s:g.yaml.whitespace.']$'
                if empty(breaks)
                    call add(chunks, ' ')
                endif
            else
                call add(chunks, line_break)
            endif
        else
            break
        endif
    endwhile
    if chomping!=0
        call add(chunks, line_break)
    endif
    if chomping==1
        call extend(chunks, breaks)
    endif
    return s:F.plug.oop.getinstance("ScalarToken", join(chunks, ""), 0,
                \                   start_mark, end_mark, a:style)
endfunction
"{{{5 load.Scanner.scan_block_scalar_indicators :: (self + (mark)) -> (?, ?)
function s:F.load.Scanner.scan_block_scalar_indicators(start_mark)
    let selfname='Scanner.scan_block_scalar_indicators'
    let chomping=-1 " = None
    let increment=0 " = None
    let ch=self.peek()
    if ch==#'+' || ch==#'-'
        let chomping=(ch==#'+')
        call self.forward()
        let ch=self.peek()
    endif
    if ch=~#'^\d$'
        let increment=ch+0
        if increment==0
            call self._raise(selfname, "Scanner", "nullindnt", a:start_mark,
                        \    self.get_mark())
        endif
        call self.forward()
        let ch=self.peek()
        if chomping==-1 && (ch==#'+' || ch==#'-')
            let chomping=(ch==#'+')
            call self.forward()
        endif
    endif
    if ch!~#self.SEPREGEX
        call self._raise(selfname, "Scanner", ["nblkind", ch], a:start_mark,
                    \    self.get_mark())
    endif
    return [chomping, increment]
endfunction
"{{{5 load.Scanner.scan_block_scalar_ignored_line :: (self + (mark)) -> _
function s:F.load.Scanner.scan_block_scalar_ignored_line(start_mark)
    let selfname='Scanner.scan_block_scalar_ignored_line'
    while self.peek()=~#'^['.s:g.yaml.whitespace.']$'
        call self.forward()
    endwhile
    if self.peek()==#s:g.yaml.comment
        while self.peek()!~#'^['.s:g.yaml.linebreak.']\=$'
            call self.forward()
        endwhile
    endif
    let ch=self.peek()
    if ch!~#'^['.s:g.yaml.linebreak.']\=$'
        call self._raise(selfname, "Scanner", ["nignln", ch], a:start_mark,
                    \    self.get_mark())
    endif
    call self.scan_line_break()
endfunction
"{{{5 load.Scanner.scan_block_scalar_indentation :: (self + ()) -> (?,?,mark)
function s:F.load.Scanner.scan_block_scalar_indentation()
    let chunks=[]
    let max_indent=0
    let end_mark=self.get_mark()
    while self.peek()=~#'^['.(s:g.yaml.whitespace).(s:g.yaml.linebreak).']$'
        if self.peek()!~#'^['.s:g.yaml.whitespace.']$'
            call add(chunks, self.scan_line_break())
            let end_mark=self.get_mark()
        else
            call self.forward()
            if self.column>max_indent
                let max_indent=self.column
            endif
        endif
    endwhile
    return [chunks, max_indent, end_mark]
endfunction
"{{{5 load.Scanner.scan_block_scalar_breaks :: (self + (UInt)) -> (?,mark)
function s:F.load.Scanner.scan_block_scalar_breaks(indent)
    let chunks=[]
    let end_mark=self.get_mark()
    while self.column<a:indent && self.peek()=~#'^['.(s:g.yaml.whitespace).']$'
        call self.forward()
    endwhile
    while self.peek()=~#'^['.(s:g.yaml.linebreak).']$'
        call add(chunks, self.scan_line_break())
        let end_mark=self.get_mark()
        while self.column<a:indent &&
                    \self.peek()=~#'^['.(s:g.yaml.whitespace).']$'
            call self.forward()
        endwhile
    endwhile
    return [chunks, end_mark]
endfunction
"{{{5 load.Scanner.scan_flow_scalar :: (self + (style)) -> token
function s:F.load.Scanner.scan_flow_scalar(style)
    let double=(a:style==#'"')
    let chunks=[]
    let start_mark=self.get_mark()
    let quote=self.peek()
    call self.forward()
    call extend(chunks, self.scan_flow_scalar_non_spaces(double, start_mark))
    while self.peek()!=#quote
        call extend(chunks, self.scan_flow_scalar_spaces(double, start_mark))
        call extend(chunks,
                    \self.scan_flow_scalar_non_spaces(double, start_mark))
    endwhile
    call self.forward()
    let end_mark=self.get_mark()
    return s:F.plug.oop.getinstance("ScalarToken", join(chunks, ""), 0,
                \                   start_mark, end_mark, a:style)
endfunction
"{{{5 load.Scanner.scan_flow_scalar_non_spaces :: (self + (Bool, mark))
"                                                                -> [ String ]
function s:F.load.Scanner.scan_flow_scalar_non_spaces(double, start_mark)
    let selfname='Scanner.scan_flow_scalar_non_spaces'
    let chunks=[]
    while 1
        let length=0
        while self.peek(length)!~#'^['.((a:double)?('"\\'):("'")).
                    \                  (s:g.yaml.whitespace).
                    \                  (s:g.yaml.linebreak).']\=$'
            let length+=1
        endwhile
        if length
            call add(chunks, self.prefix(length))
            call self.forward(length)
        endif
        let ch=self.peek()
        if ch==#"'" && self.peek(1)==#"'"
            call add(chunks, "'")
            call self.forward(2)
        elseif ch==#'\'
            call self.forward()
            let ch=self.peek()
            if has_key(self.ESCAPE_REPLACEMENTS, ch)
                call add(chunks, self.ESCAPE_REPLACEMENTS[ch])
                call self.forward()
            elseif has_key(self.ESCAPE_CODES, ch)
                let length=self.ESCAPE_CODES[ch]
                call self.forward()
                let k=0
                while k<length
                    if self.peek(k)!~#'^\x$'
                        call self._raise(selfname, "Scanner",
                                    \    ["ndqs", length, self.peek()],
                                    \     a:start_mark, self.get_mark())
                    endif
                    let k+=1
                endwhile
                let code=str2nr(self.prefix(length), 16)
                if code==0
                    call self._warn(selfname, "Scanner", "strnull",
                                \   a:start_mark, self.get_mark())
                else
                    call add(chunks, nr2char(code))
                    call self.forward(length)
                endif
            elseif ch=~#'^['.(s:g.yaml.linebreak).']$'
                call self.scan_line_break()
                call extend(chunks, self.scan_flow_scalar_breaks(a:double,
                            \                                    a:start_mark))
            elseif ch==#'0'
                call self._warn(selfname, "Scanner", "strnull", a:start_mark,
                            \   self.get_mark())
            else
                call self._raise(selfname, "Scanner", ["uknesc", ch],
                            \    a:start_mark, self.get_mark())
            endif
        else
            return chunks
        endif
    endwhile
endfunction
"{{{5 load.Scanner.scan_flow_scalar_spaces :: (self+(Bool,mark)) -> [ String ]
function s:F.load.Scanner.scan_flow_scalar_spaces(double, start_mark)
    let selfname='Scanner.scan_flow_scalar_spaces'
    let chunks=[]
    let length=0
    while self.peek(length)=~#'^['.(s:g.yaml.whitespace).']$'
        let length+=1
    endwhile
    let whitespaces=self.prefix(length)
    call self.forward(length)
    let ch=self.peek()
    if ch==#''
        call self._raise(selfname, "Scanner", "qseos", a:start_mark,
                    \    self.get_mark())
    elseif ch=~#'^['.(s:g.yaml.linebreak).']$'
        let line_break=self.scan_line_break()
        let breaks=self.scan_flow_scalar_breaks(a:double, a:start_mark)
        if line_break!=#"\n"
            call add(chunks, line_break)
        elseif empty(breaks)
            call add(chunks, ' ')
        endif
        call extend(chunks, breaks)
    else
        call add(chunks, whitespaces)
    endif
    return chunks
endfunction
"{{{5 load.Scanner.scan_flow_scalar_breaks :: (self+(Bool,mark)) -> [ String ]
function s:F.load.Scanner.scan_flow_scalar_breaks(double, start_mark)
    let selfname='Scanner.scan_flow_scalar_breaks'
    let chunks=[]
    while 1
        let prefix=self.prefix(3)
        if (prefix==#'---' || prefix==#'...') && self.peek(3)=~#self.SEPREGEX
            call self._raise(selfname, "Scanner", "docsepqs", a:start_mark,
                        \    self.get_mark())
        endif
        while self.peek()=~#'^['.s:g.yaml.whitespace.']$'
            call self.forward()
        endwhile
        if self.peek()=~#'^['.s:g.yaml.linebreak.']$'
            call add(chunks, self.scan_line_break())
        else
            return chunks
        endif
    endwhile
endfunction
"{{{5 load.Scanner.scan_plain :: (self + ()) -> token
function s:F.load.Scanner.scan_plain()
    let selfname='Scanner.scan_plain'
    let chunks=[]
    let start_mark=self.get_mark()
    let end_mark=start_mark
    let indent=self.indent+1
    let spaces=[]
    while 1
        let length=0
        if self.peek()==#s:g.yaml.comment
            break
        endif
        while 1
            let ch=self.peek(length)
            if ch=~#self.SEPREGEX ||
                        \(!self.flow_level &&
                        \ ch==#s:g.yaml.mappingvalue &&
                        \ self.peek(length+1)=~#self.SEPREGEX) ||
                        \(self.flow_level &&
                        \ ch=~#'^['.(s:g.yaml.flowindicator).
                        \           (s:g.yaml.mappingvalue).
                        \           (s:g.yaml.mappingkey).']$')
                break
            endif
            let length+=1
        endwhile
        if (self.flow_level && ch==#s:g.yaml.mappingvalue &&
                    \self.peek(length+1)!~#'^['.(s:g.yaml.flowindicator).
                    \                           (s:g.yaml.whitespace).
                    \                           (s:g.yaml.linebreak).']\=$')
            " XXX
            call self._warn(selfname, "Scanner", "ambcolon", start_mark,
                        \   self.get_mark(), s:g.p.ambcolonnote)
        endif
        if length==0
            break
        endif
        let self.allow_simple_key=0
        call extend(chunks, spaces)
        call add(chunks, self.prefix(length))
        call self.forward(length)
        let end_mark=self.get_mark()
        unlet spaces
        let spaces=self.scan_plain_spaces(indent, start_mark)
        if type(spaces)!=type([]) || empty(spaces) || self.peek()==#'#' ||
                    \(!self.flow_level && self.column<indent)
            break
        endif
    endwhile
    return s:F.plug.oop.getinstance("ScalarToken", join(chunks, ""), 1,
                \                   start_mark, end_mark, "")
endfunction
"{{{5 load.Scanner.scan_plain_spaces :: (self + (UInt, mark)) -> [ String ]
function s:F.load.Scanner.scan_plain_spaces(indent, start_mark)
    let chunks=[]
    let length=0
    while self.peek(length)=~#'^['.(s:g.yaml.whitespace).']$'
        let length+=1
    endwhile
    let whitespaces=self.prefix(length)
    call self.forward(length)
    let ch=self.peek()
    if ch=~#'^['.s:g.yaml.linebreak.']$'
        let line_break=self.scan_line_break()
        let self.allow_simple_key=1
        let prefix=self.prefix(3)
        if (prefix==#'---' || prefix==#'...') && self.peek(3)=~#self.SEPREGEX
            return 0
        endif
        let breaks=[]
        while self.peek()=~#'^['.(s:g.yaml.whitespace).(s:g.yaml.linebreak).']$'
            if self.peek()=~#'^['.s:g.yaml.whitespace.']$'
                call self.forward()
            else
                call add(breaks, self.scan_line_break())
                let prefix=self.prefix(3)
                if (prefix==#'---' || prefix==#'...') &&
                            \self.peek(3)=~#self.SEPREGEX
                    return 0
                endif
            endif
        endwhile
        if line_break!=#"\n"
            call add(chunks, line_break)
        elseif empty(breaks)
            call add(chunks, " ")
        endif
        call extend(chunks, breaks)
    elseif whitespaces!=#""
        call add(chunks, whitespaces)
    endif
    return chunks
endfunction
"{{{5 load.Scanner.scan_tag_handle :: (self + (?, mark)) -> String
function s:F.load.Scanner.scan_tag_handle(name, start_mark)
    let selfname='Scanner.scan_tag_handle'
    let istag=(a:name==#'tag')
    let ch=self.peek()
    if ch!=#'!'
        call self._raise(selfname, "Scanner",
                    \[((istag)?("ntagbang"):("ndirbang")), ch],
                    \a:start_mark, self.get_mark())
    endif
    let length=1
    let ch=self.peek(length)
    if ch!~#'^['.s:g.yaml.whitespace.']$'
        while ch=~#'^['.s:g.yaml.nsword.']$'
            let length+=1
            let ch=self.peek(length)
        endwhile
        if ch!~#'!'
            call self.forward(length)
            " XXX different from previous error message
            call self._raise(selfname, "Scanner",
                        \[((istag)?("ntagbang"):("ndirbang")), ch],
                        \a:start_mark, self.get_mark())
        endif
        let length+=1
    endif
    let value=self.prefix(length)
    call self.forward(length)
    return value
endfunction
"{{{5 load.Scanner.scan_tag_uri :: (self + (?, mark)) -> String
function s:F.load.Scanner.scan_tag_uri(name, start_mark)
    let selfname='Scanner.scan_tag_uri'
    let istag=(a:name==#'tag')
    let chunks=[]
    let length=0
    let ch=self.peek(length)
    while ch=~#'^['.s:g.yaml.nstag.']$'
        if ch==#'%'
            call add(chunks, self.prefix(length))
            call self.forward(length)
            let length=0
            call add(chunks, self.scan_uri_escapes(a:name, a:start_mark))
        else
            let length+=1
        endif
        let ch=self.peek(length)
    endwhile
    if length
        call add(chunks, self.prefix(length))
        call self.forward(length)
    endif
    if empty(chunks)
        call self._raise(selfname, "Scanner",
                    \    [((istag)?("ntaguri"):("ndiruri")), ch],
                    \    a:start_mark, self.get_mark())
    endif
    return join(chunks, "")
endfunction
"{{{5 load.Scanner.scan_uri_escapes :: (self + (?, mark)) -> String
function s:F.load.Scanner.scan_uri_escapes(name, start_mark)
    let selfname='Scanner.scan_uri_escapes'
    let istag=(a:name==#'tag')
    let codes=[]
    let mark=self.get_mark()
    while self.peek()=='%'
        call self.forward()
        let k=0
        while k<2
            if self.peek(k)!~#'^\x$'
                call self._raise(selfname, "Scanner",
                            \    [((istag)?("nturiesc"):("nduriesc")),
                            \     self.peek(k)],
                            \    a:start_mark, self.get_mark())
            endif
            let k+=1
        endwhile
        call add(codes, str2nr(self.prefix(2), 16))
        call self.forward(2)
    endwhile
    " FIXME check for valid unicode
    return join(map(codes, 'eval(printf(''"\x%02x"'', v:val))'))
endfunction
"{{{5 load.Scanner.scan_line_break :: (self + ()) -> Bool
function s:F.load.Scanner.scan_line_break()
    let ch=self.peek()
    let r=""
    if ch==#"\r"
        call self.forward()
        let ch=self.peek()
        let r="\n"
    endif
    if ch==#"\n"
        call self.forward()
        let r="\n"
    endif
    return r
endfunction
"{{{3 load.Parser
"{{{4 load.Parser.__init__ :: () -> _
function s:F.load.Parser.__init__(super)
    " let self.current_event={} " = None
    let self.yaml_version=[] " = None
    let self.tag_handles={}
    let self.states=[]
    let self.marks=[]
    let self.state=self.parse_stream_start
endfunction
"{{{4 load.Parser.set_current_event
function s:F.load.Parser.set_current_event()
    if !has_key(self, "current_event")
        if type(self.state)==2
            let self.current_event=self.state()
        else
            let self.current_event=s:F.plug.oop.getinstance("None")
        endif
    endif
endfunction
"{{{4 load.Parser.check_event :: (self + (Class*)) -> Bool
function s:F.load.Parser.check_event(...)
    call self.set_current_event()
    if has_key(self, "current_event") && self.current_event.__class__!=#"None"
        if empty(a:000)
            return 1
        endif
        for choice in a:000
            if self.current_event.__class__==#choice
                return 1
            endif
        endfor
    endif
    return 0
endfunction
"{{{4 load.Parser.peek_event :: (self + ()) -> event
function s:F.load.Parser.peek_event()
    call self.set_current_event()
    return self.current_event
endfunction
"{{{4 load.Parser.get_event :: (self + ()) -> event
function s:F.load.Parser.get_event()
    call self.set_current_event()
    let value=self.current_event
    unlet self.current_event
    return value
endfunction
"{{{4 load.Parser.parse_stream_start :: (self + ()) -> event
function s:F.load.Parser.parse_stream_start()
    let token=self.get_token()
    let event=s:F.plug.oop.getinstance("StreamStartEvent", token.start_mark,
                \                      token.end_mark, token.encoding)
    let self.state=self.parse_implicit_document_start
    return event
endfunction
"{{{4 load.Parser.parse_implicit_document_start :: (self + ()) -> state
function s:F.load.Parser.parse_implicit_document_start()
    if !self.check_token("DirectiveToken", "DocumentStartToken",
                \        "StreamEndToken")
        let self.tag_handles=copy(self.DEFAULT_TAGS)
        let token=self.peek_token()
        let start_mark=token.start_mark
        let end_mark=start_mark
        let event=s:F.plug.oop.getinstance("DocumentStartEvent", start_mark,
                    \                      end_mark, 0, [], [])
        call add(self.states, self.parse_document_end)
        let self.state=self.parse_block_node
        return event
    else
        return self.parse_document_start()
    endif
endfunction
"{{{4 load.Parser.parse_document_start :: (self + ()) -> state
function s:F.load.Parser.parse_document_start()
    let selfname='Parser.parse_document_start'
    while self.check_token("DocumentEndToken")
        call self.get_token()
    endwhile
    if !self.check_token("StreamEndToken")
        let token=self.peek_token()
        let start_mark=token.start_mark
        let [version_, tags]=self.process_directives()
        if !self.check_token("DocumentStartToken")
            call self._raise(selfname, "Parser",
                        \["ndocstart", self.peek_token().__class__], 0,
                        \self.peek_token().start_mark)
        endif
        let token=self.get_token()
        let end_mark=token.end_mark
        let event=s:F.plug.oop.getinstance("DocumentStartEvent", start_mark,
                    \                      end_mark, 1, version_, tags)
        call add(self.states, self.parse_document_end)
        let self.state=self.parse_document_content
    else
        let token=self.get_token()
        let event=s:F.plug.oop.getinstance("StreamEndEvent", token.start_mark,
                    \                      token.end_mark)
        " assert not self.states
        " assert not self.marks
        let self.state=0
    endif
    return event
endfunction
"{{{4 load.Parser.parse_document_end :: (self + ()) -> state
function s:F.load.Parser.parse_document_end()
    let token=self.peek_token()
    let start_mark=token.start_mark
    let end_mark=start_mark
    let explicit=0
    if self.check_token("DocumentEndToken")
        let token=self.get_token()
        let end_mark=token.end_mark
        let explicit=1
    endif
    let event=s:F.plug.oop.getinstance("DocumentEndEvent", start_mark, end_mark,
                \                      explicit)
    let self.state=self.parse_document_start
    return event
endfunction
"{{{4 load.Parser.parse_document_content :: (self + ()) -> state
function s:F.load.Parser.parse_document_content()
    let selfname='Parser.parse_document_content'
    if self.check_token("DirectiveToken", "DocumentStartToken",
                \       "DocumentEndToken", "StreamEndToken")
        let event=self.process_empty_scalar(self.peek_token().start_mark)
        let self.state=remove(self.states, -1)
        return event
    else
        return self.parse_block_node()
    endif
endfunction
"{{{4 load.Parser.process_directives :: (self + ()) -> (version, tags)
function s:F.load.Parser.process_directives()
    let selfname='Parser.process_directives'
    let self.yaml_version=[] " = None
    let self.tag_handles={}
    while self.check_token("DirectiveToken")
        let token=self.get_token()
        if token.name==#"YAML"
            if !empty(self.yaml_version)
                call self._raise(selfname, "Parser", "multYAML", 0,
                            \    token.start_mark)
            endif
            let [major, minor]=token.value
            if major!=1
                call self._raise(selfname, "Parser", ["majmis", major], 0,
                            \    token.start_mark)
            endif
            let self.yaml_version=token.value
        elseif token.name==#"TAG"
            let [handle, prefix]=token.value
            if has_key(self.tag_handles, handle)
                call self._raise(selfname, "Parser", ["duptag", handle], 0,
                            \    token.start_mark)
            endif
            let self.tag_handles[handle]=prefix
        endif
    endwhile
    let value=[self.yaml_version, copy(self.tag_handles)]
    call extend(self.tag_handles, self.DEFAULT_TAGS, "keep")
    return value
endfunction
"{{{4 load.Parser.parse_block_node :: (self + ()) -> state
function s:F.load.Parser.parse_block_node()
    return self.parse_node(1, 0)
endfunction
"{{{4 load.Parser.parse_flow_node
function s:F.load.Parser.parse_flow_node()
    return self.parse_node(0, 0)
endfunction
"{{{4 load.Parser.parse_block_node_or_indentless_sequence
function s:F.load.Parser.parse_block_node_or_indentless_sequence()
    return self.parse_node(1, 1)
endfunction
"{{{4 load.Parser.parse_node :: (self + (Bool, Bool)) -> state
function s:F.load.Parser.parse_node(block, indentless_sequence)
    let selfname='Parser.parse_node'
    if self.check_token("AliasToken")
        let token=self.get_token()
        let event=s:F.plug.oop.getinstance("AliasEvent", token.value,
                    \                      token.start_mark, token.end_mark)
        let self.state=remove(self.states, -1)
    else
        let anchor=""     " = None
        let tag=[]        " = None
        let start_mark={} " = None
        let end_mark={}   " = None
        let tag_mark={}   " = None
        if self.check_token("AnchorToken")
            let token=self.get_token()
            let start_mark=token.start_mark
            let end_mark=token.end_mark
            let anchor=token.value
            if self.check_token("TagToken")
                let token=self.get_token()
                let tag_mark=token.start_mark
                let end_mark=token.end_mark
                let tag=token.value
            endif
        elseif self.check_token("TagToken")
            let token=self.get_token()
            let start_mark=token.start_mark
            let end_mark=token.end_mark
            let tag=token.value
            if self.check_token("AnchorToken")
                let token=self.get_token()
                let end_mark=token.end_mark
                let anchor=token.value
            endif
        endif
        if !empty(tag)
            let [handle, suffix]=tag
            unlet tag
            if handle!=#""
                if !has_key(self.tag_handles, handle)
                    call self._raise(selfname, "Parser", ["ukntag", handle],
                                \    start_mark, tag_mark)
                endif
                let tag=(self.tag_handles[handle]).suffix
            else
                let tag=suffix
            endif
        else
            unlet tag
            let tag=""
        endif
        if start_mark=={}
            let start_mark=self.peek_token().start_mark
            let end_mark=start_mark
        endif
        let event={} " = None
        let implicit=((tag==#"")||(tag==#"!"))
        if a:indentless_sequence && self.check_token("BlockEntryToken")
            let end_mark=self.peek_token().end_mark
            let event=s:F.plug.oop.getinstance("SequenceStartEvent", anchor,
                        \                      tag, implicit, start_mark,
                        \                      end_mark, 0)
            let self.state=self.parse_indentless_sequence_entry
        else
            if self.check_token("ScalarToken")
                let token=self.get_token()
                let end_mark=token.end_mark
                unlet implicit
                if (token.plain && tag==#"") || tag==#"!"
                    let implicit=[1, 0]
                elseif tag==#""
                    let implicit=[0, 1]
                else
                    let implicit=[0, 0]
                endif
                let event=s:F.plug.oop.getinstance("ScalarEvent", anchor, tag,
                            \                      implicit, token.value,
                            \                      start_mark, end_mark,
                            \                      token.style)
                let self.state=remove(self.states, -1)
            elseif self.check_token("FlowSequenceStartToken")
                let end_mark=self.peek_token().end_mark
                let event=s:F.plug.oop.getinstance("SequenceStartEvent", anchor,
                            \                      tag, implicit, start_mark,
                            \                      end_mark, 1)
                let self.state=self.parse_flow_sequence_first_entry
            elseif self.check_token("FlowMappingStartToken")
                let end_mark=self.peek_token().end_mark
                let event=s:F.plug.oop.getinstance("MappingStartEvent", anchor,
                            \                      tag, implicit, start_mark,
                            \                      end_mark, 1)
                let self.state=self.parse_flow_mapping_first_key
            elseif a:block && self.check_token("BlockSequenceStartToken")
                let end_mark=self.peek_token().end_mark
                let event=s:F.plug.oop.getinstance("SequenceStartEvent", anchor,
                            \                      tag, implicit, start_mark,
                            \                      end_mark, 0)
                let self.state=self.parse_block_sequence_first_entry
            elseif a:block && self.check_token("BlockMappingStartToken")
                let end_mark=self.peek_token().end_mark
                let event=s:F.plug.oop.getinstance("MappingStartEvent", anchor,
                            \                      tag, implicit, start_mark,
                            \                      end_mark, 0)
                let self.state=self.parse_block_mapping_first_key
            elseif anchor!=#"" || tag!=#""
                let event=s:F.plug.oop.getinstance("ScalarEvent", anchor, tag,
                            \                      [implicit, 0], "",
                            \                      start_mark, end_mark, "")
                let self.state=remove(self.states, -1)
            else
                let token=self.peek_token()
                if a:block
                    call self._raise(selfname, "Parser",
                                \    ["emptblock", token.__class__], 0,
                                \    token.start_mark)
                else
                    call self._raise(selfname, "Parser",
                                \    ["emptyflow", token.__class__], 0,
                                \    token.start_mark)
                endif
            endif
        endif
    endif
    return event
endfunction
"{{{4 load.Parser.parse_indentless_sequence_entry
function s:F.load.Parser.parse_indentless_sequence_entry()
    if self.check_token("BlockEntryToken")
        let token=self.get_token()
        if !self.check_token("BlockEntryToken", "KeyToken", "ValueToken",
                    \        "BlockEndToken")
            call add(self.states, self.parse_indentless_sequence_entry)
            return self.parse_block_node()
        else
            let self.state=self.parse_indentless_sequence_entry
            return self.process_empty_scalar(token.end_mark)
        endif
    endif
    let token=self.peek_token()
    let event=s:F.plug.oop.getinstance("SequenceEndEvent", token.start_mark,
                \                      token.end_mark)
    let self.state=remove(self.states, -1)
    return event
endfunction
"{{{4 load.Parser.parse_block_sequence_entry
function s:F.load.Parser.parse_block_sequence_entry()
    let selfname='Parser.parse_block_sequence_entry'
    if self.check_token("BlockEntryToken")
        let token=self.get_token()
        if !self.check_token("BlockEntryToken", "BlockEndToken")
            call add(self.states, self.parse_block_sequence_entry)
            return self.parse_block_node()
        else
            let self.state=self.parse_block_sequence_entry
            return self.process_empty_scalar(token.end_mark)
        endif
    endif
    if !self.check_token("BlockEndToken")
        let token=self.peek_token()
        call self._raise(selfname, "Parser", ["nblkend", token.__class__],
                    \    self.marks[-1], token.start_mark)
    endif
    let token=self.get_token()
    let event=s:F.plug.oop.getinstance("SequenceEndEvent", token.start_mark,
                \                      token.end_mark)
    let self.state=remove(self.states, -1)
    call remove(self.marks, -1)
    return event
endfunction
"{{{4 load.Parser.parse_block_sequence_first_entry
function s:F.load.Parser.parse_block_sequence_first_entry()
    let token=self.get_token()
    call add(self.marks, token.start_mark)
    return self.parse_block_sequence_entry()
endfunction
"{{{4 load.Parser.parse_block_mapping_key
function s:F.load.Parser.parse_block_mapping_key()
    let selfname='Parser.parse_block_mapping_key'
    if self.check_token("KeyToken")
        let token=self.get_token()
        if !self.check_token("KeyToken", "ValueToken", "BlockEndToken")
            call add(self.states, self.parse_block_mapping_value)
            return self.parse_block_node_or_indentless_sequence()
        else
            let self.state=self.parse_block_mapping_value
            return self.process_empty_scalar(token.end_mark)
        endif
    endif
    if !self.check_token("BlockEndToken")
        let token=self.peek_token()
        call self._raise(selfname, "Parser", ["nblkmend", token.__class__],
                    \    self.marks[-1], token.start_mark)
    endif
    let token=self.get_token()
    let event=s:F.plug.oop.getinstance("MappingEndEvent", token.start_mark,
                \                      token.end_mark)
    let self.state=remove(self.states, -1)
    call remove(self.marks, -1)
    return event
endfunction
"{{{4 load.Parser.parse_block_mapping_value
function s:F.load.Parser.parse_block_mapping_value()
    if self.check_token("ValueToken")
        let token=self.get_token()
        if !self.check_token("KeyToken", "ValueToken", "BlockEndToken")
            call add(self.states, self.parse_block_mapping_key)
            return self.parse_block_node_or_indentless_sequence()
        else
            let self.state=self.parse_block_mapping_key
            return self.process_empty_scalar(token.end_mark)
        endif
    else
        let self.state=self.parse_block_mapping_key
        let token=self.peek_token()
        return self.process_empty_scalar(token.start_mark)
    endif
endfunction
"{{{4 load.Parser.parse_block_mapping_first_key
function s:F.load.Parser.parse_block_mapping_first_key()
    let token=self.get_token()
    call add(self.marks, token.start_mark)
    return self.parse_block_mapping_key()
endfunction
"{{{4 load.Parser.parse_flow_sequence_first_entry
function s:F.load.Parser.parse_flow_sequence_first_entry()
    let token=self.get_token()
    call add(self.marks, token.start_mark)
    return self.parse_flow_sequence_entry(1)
endfunction
"{{{4 load.Parser.parse_flow_sequence_entry (self + ([Bool])) -> state
function s:F.load.Parser.parse_flow_sequence_entry(...)
    let selfname='Parser.parse_flow_sequence_entry'
    let first=get(a:000, 0, 0)
    if !self.check_token("FlowSequenceEndToken")
        if !first
            if self.check_token("FlowEntryToken")
                call self.get_token()
            else
                let token=self.peek_token()
                call self._raise(selfname, "Parser",
                            \    ["nflwseq", token.__class__],
                            \    self.marks[-1], token.start_mark)
            endif
        endif
        if self.check_token("KeyToken")
            let token=self.peek_token()
            let event=s:F.plug.oop.getinstance("MappingStartEvent", 0, 0, 1,
                        \                      token.start_mark,
                        \                      token.end_mark, 1)
            let self.state=self.parse_flow_sequence_entry_mapping_key
            return event
        elseif !self.check_token("FlowSequenceEndToken")
            call add(self.states, self.parse_flow_sequence_entry)
            return self.parse_flow_node()
        endif
    endif
    let token=self.get_token()
    let event=s:F.plug.oop.getinstance("SequenceEndEvent", token.start_mark,
                \                      token.end_mark)
    let self.state=remove(self.states, -1)
    call remove(self.marks, -1)
    return event
endfunction
"{{{4 load.Parser.parse_flow_sequence_entry_mapping_key
function s:F.load.Parser.parse_flow_sequence_entry_mapping_key()
    let token=self.get_token()
    if !self.check_token("ValueToken", "FlowEntryToken", "FlowSequenceEndToken")
        call add(self.states, self.parse_flow_sequence_entry_mapping_value)
        return self.parse_flow_node()
    else
        let self.state=self.parse_flow_sequence_entry_mapping_value
        return self.process_empty_scalar(token.end_mark)
    endif
endfunction
"{{{4 load.Parser.parse_flow_sequence_entry_mapping_value
function s:F.load.Parser.parse_flow_sequence_entry_mapping_value()
    if self.check_token("ValueToken")
        let token=self.get_token()
        if !self.check_token("FlowEntryToken", "FlowSequenceEndToken")
            call add(self.states, self.parse_flow_sequence_entry_mapping_end)
            return self.parse_flow_node()
        else
            let self.state=self.parse_flow_sequence_entry_mapping_end
            return self.process_empty_scalar(token.end_mark)
        endif
    else
        let self.state=self.parse_flow_sequence_entry_mapping_end
        let token=self.peek_token()
        return self.process_empty_scalar(token.start_mark)
    endif
endfunction
"{{{4 load.Parser.parse_flow_sequence_entry_mapping_end
function s:F.load.Parser.parse_flow_sequence_entry_mapping_end()
    let self.state=self.parse_flow_sequence_entry
    let token=self.peek_token()
    return s:F.plug.oop.getinstance("MappingEndEvent", token.start_mark,
                \                   token.end_mark)
endfunction
"{{{4 load.Parser.parse_flow_mapping_first_key
function s:F.load.Parser.parse_flow_mapping_first_key()
    let token=self.get_token()
    call add(self.marks, token.start_mark)
    return self.parse_flow_mapping_key(1)
endfunction
"{{{4 load.Parser.parse_flow_mapping_key (self + ([Bool])) -> state
function s:F.load.Parser.parse_flow_mapping_key(...)
    let selfname='Parser.parse_flow_mapping_key'
    let first=get(a:000, 0, 0)
    if !self.check_token("FlowMappingEndToken")
        if !first
            if self.check_token("FlowEntryToken")
                call self.get_token()
            else
                let token=self.peek_token()
                call self._raise(selfname, "Parser",
                            \    ["nflwmap", token.__class__], self.marks[-1],
                            \    token.start_mark)
            endif
        endif
        if self.check_token("KeyToken")
            let token=self.get_token()
            if !self.check_token("ValueToken", "FlowEntryToken",
                        \        "FlowMappingEndToken")
                call add(self.states, self.parse_flow_mapping_value)
                return self.parse_flow_node()
            else
                let self.state=self.parse_flow_mapping_value
                return self.process_empty_scalar(token.end_mark)
            endif
        elseif !self.check_token("FlowMappingEndToken")
            call add(self.states, self.parse_flow_mapping_empty_value)
            return self.parse_flow_node()
        endif
    endif
    let token=self.get_token()
    let event=s:F.plug.oop.getinstance("MappingEndEvent", token.start_mark,
                \                      token.end_mark)
    let self.state=remove(self.states, -1)
    call remove(self.marks, -1)
    return event
endfunction
"{{{4 load.Parser.parse_flow_mapping_value
function s:F.load.Parser.parse_flow_mapping_value()
    if self.check_token("ValueToken")
        let token=self.get_token()
        if !self.check_token("FlowEntryToken", "FlowMappingEndToken")
            call add(self.states, self.parse_flow_mapping_key)
            return self.parse_flow_node()
        else
            let self.state=self.parse_flow_mapping_key
            return self.process_empty_scalar(token.end_mark)
        endif
    else
        let self.state=self.parse_flow_mapping_key
        let token=self.peek_token()
        return self.process_empty_scalar(token.start_mark)
    endif
endfunction
"{{{4 load.Parser.parse_flow_mapping_empty_value
function s:F.load.Parser.parse_flow_mapping_empty_value()
    let self.state=self.parse_flow_mapping_key
    return self.process_empty_scalar(self.peek_token().start_mark)
endfunction
"{{{4 load.Parser.process_empty_scalar :: (self + (mark)) -> event
function s:F.load.Parser.process_empty_scalar(mark)
    return s:F.plug.oop.getinstance("ScalarEvent", "", "", [0, 1], "", a:mark,
                \                   a:mark, "")
endfunction
"{{{3 load.BaseResolver
"{{{4 load.BaseResolver.__init__ :: () -> _
function s:F.load.BaseResolver.__init__(super)
    let self.resolver_exact_paths=[]
    let self.resolver_prefix_paths=[]
endfunction
"{{{4 load.BaseResolver.set_yaml_path_resolver
function s:F.load.BaseResolver.set_yaml_path_resolver(path, kind, value)
    let idx=index(self.yaml_path_resolver_ids, [a:path, a:kind])
    if idx==-1
        call add(self.yaml_path_resolver_ids, [a:path, a:kind])
        call add(self.yaml_path_resolvers, 0)
        let idx=len(self.yaml_path_resolver_ids)
    endif
    let self.yaml_path_resolvers[idx]=a:value
endfunction
"{{{4 load.BaseResolver.get_yaml_path_resolver
function s:F.load.BaseResolver.get_yaml_path_resolver(path, kind)
    let idx=index(self.yaml_path_resolver_ids, [a:path, a:kind])
    if idx==-1
        return 0
    endif
    return self.yaml_path_resolvers[idx]
endfunction
"{{{4 load.BaseResolver.check_resolver_prefix ::
"       (self + (depth::Uint, path, kind, node, index)) -> Bool
function s:F.load.BaseResolver.check_resolver_prefix(depth, path, kind,
            \                                        current_node,
            \                                        current_index)
    let [node_check, index_check]=a:path[a:depth-1]
    if type(node_check)==type("")
        if a:current_node.tag!=#node_check
            return 0
        endif
    elseif node_check!={}
        if a:current_node.__class__!=#node_check.__class__
            return 0
        endif
    endif
    if type(index_check)==type(0) && index_check<0
        let index_check=(index_check==-1)
        let cinone=(type(a:current_index)==type(0) && a:current_index==-1)
        if index_check && !cinone
            return 0
        elseif !index_check && cinone
            return 0
        endif
    elseif type(index_check)==type("")
        if !((type(a:current_index)==type({}) &&
                    \   a:current_index.__class__==#"ScalarNode") &&
                    \index_check==#a:current_index.value)
            return 0
        endif
    elseif type(index_check)==type(0) && index_check>=0
        if !(type(a:current_index)==type(0) && a:current_index==index_check)
            return 0
        endif
    endif
    return 1
endfunction
"{{{4 load.BaseResolver.descent_resolver :: (self + (node, index)) -> _
function s:F.load.BaseResolver.descent_resolver(current_node, current_index)
    if empty(self.yaml_path_resolvers)
        return 0
    endif
    let exact_paths={}
    let prefix_paths=[]
    if a:current_node!={}
        let depth=len(self.resolver_prefix_paths)
        for [path, kind] in self.resolver_prefix_paths[-1]
            if self.check_resolver_prefix(depth, path, kind, a:current_node,
                        \                 a:current_index)
                if len(path)>depth
                    call add(prefix_paths, [path, kind])
                else
                    let exact_paths[kind]=self.get_yaml_path_resolver(path,
                                \                                     kind)
                endif
            endif
        endfor
    else
        let idx=0
        for [path, kind] in self.yaml_path_resolver_ids
            if empty(path)
                let exact_paths[kind]=self.yaml_path_resolvers[idx]
            else
                call add(prefix_paths, [path, kind])
            endif
            let idx+=1
        endfor
    endif
    call add(self.resolver_exact_paths, exact_paths)
    call add(self.resolver_prefix_paths, prefix_paths)
endfunction
"{{{4 load.BaseResolver.ascent_resolver :: (self + ()) -> _
function s:F.load.BaseResolver.ascent_resolver()
    if empty(self.resolver_exact_paths)
        return 0
    endif
    call remove(self.resolver_exact_paths, -1)
    call remove(self.resolver_prefix_paths, -1)
endfunction
"{{{4 load.BaseResolver.resolve :: (self + (String, ?, implicit)) -> tag
function s:F.load.BaseResolver.resolve(kind, value, implicit)
    if a:kind==#"ScalarNode" && a:implicit[0]
        if a:value==#""
            let resolvers=get(self.yaml_implicit_resolvers, "_none", [])
        else
            let resolvers=copy(get(self.yaml_implicit_resolvers,
                        \a:value[0], []))
            call extend(resolvers, get(self.yaml_implicit_resolvers,
                        \"_none", []))
        endif
        for [tag, regex] in resolvers
            if a:value=~#regex
                return tag
            endif
        endfor
        let implicit=a:implicit[1]
    endif
    if self.yaml_path_resolvers!=#[]
        let exact_paths=self.resolver_exact_paths[-1]
        if has_key(exact_paths, a:kind)
            return exact_paths[a:kind]
        endif
        if has_key(exact_paths, "_none")
            return exact_paths._none
        endif
    endif
    if a:kind==#"ScalarNode"
        return self.DEFAULT_SCALAR_TAG
    elseif a:kind==#"SequenceNode"
        return self.DEFAULT_SEQUENCE_TAG
    elseif a:kind==#"MappingNode"
        return self.DEFAULT_MAPPING_TAG
    endif
endfunction
"{{{4 load.BaseResolver.add_implicit_resolver
function s:F.load.BaseResolver.add_implicit_resolver(tag, regex, first)
    if type(a:first)!=type([])
        let first=[0]
    else
        let first=a:first
    endif
    for ch in first
        if ch==#''
            let ch="_none"
        endif
        if !has_key(self.__variables__.yaml_implicit_resolvers, ch)
            let self.__variables__.yaml_implicit_resolvers[ch]=
                        \[[a:tag, a:regex]]
        else
            call add(self.__variables__.yaml_implicit_resolvers[ch],
                        \[a:tag, a:regex])
        endif
    endfor
endfunction
"{{{3 load.Composer
"{{{4 load.Composer.__init__ :: () -> _
function s:F.load.Composer.__init__(super)
    let self.anchors={}
endfunction
"{{{4 load.Composer.check_node
function s:F.load.Composer.check_node()
    if self.check_event("StreamStartEvent")
        call self.get_event()
    endif
    return !self.check_event("StreamEndEvent")
endfunction
"{{{4 load.Composer.get_node
function s:F.load.Composer.get_node()
    if !self.check_event("StreamEndEvent")
        return self.compose_document()
    endif
endfunction
"{{{4 load.Composer.get_single_node -> document
function s:F.load.Composer.get_single_node()
    let selfname='Composer.get_single_node'
    call self.get_event()
    let document={} " = None
    if !self.check_event("StreamEndEvent")
        let document=self.compose_document()
    endif
    if !self.check_event("StreamEndEvent")
        let event=self.get_event()
        call self._warn(selfname, "Composer", "notsingle",
                    \   document.start_mark, event.start_mark)
    endif
    call self.get_event()
    return document
endfunction
"{{{4 load.Composer.compose_document :: (self + ()) -> document
function s:F.load.Composer.compose_document()
    call self.get_event()
    let self.anchors={}
    let node=self.compose_node({}, -1)
    call self.get_event()
    return node
endfunction
"{{{4 load.Composer.compose_node :: (self + (node, index)) -> node
function s:F.load.Composer.compose_node(parent, index)
    let selfname='Composer.compose_node'
    if self.check_event("AliasEvent")
        let event=self.get_event()
        let anchor=event.anchor
        if !has_key(self.anchors, anchor)
            call self._raise(selfname, "Composer", ["alundef", anchor],
                        \    0, event.start_mark)
        endif
        return self.anchors[anchor]
    endif
    let event=self.peek_event()
    if has_key(event, "anchor")
        let anchor=event.anchor
        if has_key(self.anchors, anchor)
            call self._warn(selfname, "Composer", ["dupan", anchor],
                        \   self.anchors[anchor].start_mark,
                        \   event.start_mark)
        endif
    else
        let anchor=""
    endif
    call self.descent_resolver(a:parent, a:index)
    if self.check_event("ScalarEvent")
        let node=self.compose_scalar_node(anchor)
    elseif self.check_event("SequenceStartEvent")
        let node=self.compose_sequence_node(anchor)
    elseif self.check_event("MappingStartEvent")
        let node=self.compose_mapping_node(anchor)
    endif
    call self.ascent_resolver()
    if !exists("l:node")
        call self._raise(selfname, "Internal", ["ndef", "node"],
                    \    0, 0)
    endif
    return node
endfunction
"{{{4 load.Composer.compose_scalar_node :: (self + (anchor)) -> node
function s:F.load.Composer.compose_scalar_node(anchor)
    let selfname='Composer.compose_scalar_node'
    let event=self.get_event()
    let tag=""
    if has_key(event, "tag")
        let tag=event.tag
    endif
    if tag==#"" || tag==#"!"
        let tag=self.resolve("ScalarNode", event.value, event.implicit)
    endif
    let node=s:F.plug.oop.getinstance("ScalarNode", tag, event.value,
                \                     event.start_mark, event.end_mark,
                \                     event.style, self.id())
    if a:anchor!=#""
        let self.anchors[a:anchor]=node
    endif
    return node
endfunction
"{{{4 load.Composer.compose_sequence_node :: (self + (anchor)) -> node
function s:F.load.Composer.compose_sequence_node(anchor)
    let selfname='Composer.compose_sequence_node'
    let start_event=self.get_event()
    let tag=""
    if has_key(start_event, "tag")
        let tag=start_event.tag
    endif
    if tag==#"" || tag==#"!"
        let tag=self.resolve("SequenceNode", 0, start_event.implicit)
    endif
    let node=s:F.plug.oop.getinstance("SequenceNode", tag, [],
                \                     start_event.start_mark, 0,
                \                     start_event.flow_style, self.id())
    if a:anchor!=#""
        let self.anchors[a:anchor]=node
    endif
    let index=0
    while !self.check_event("SequenceEndEvent")
        call add(node.value, self.compose_node(node, index))
        let index+=1
    endwhile
    let end_event=self.get_event()
    let node.end_mark=end_event.end_mark
    return node
endfunction
"{{{4 load.Composer.compose_mapping_node :: (self + (anchor)) -> node
function s:F.load.Composer.compose_mapping_node(anchor)
    let selfname='Composer.compose_mapping_node'
    let start_event=self.get_event()
    let tag=""
    if has_key(start_event, "tag")
        let tag=start_event.tag
    endif
    if tag==#"" || tag==#"!"
        let tag=self.resolve("MappingNode", 0, start_event.implicit)
    endif
    let node=s:F.plug.oop.getinstance("MappingNode", tag, [],
                \                     start_event.start_mark, 0,
                \                     start_event.flow_style, self.id())
    if a:anchor!=#""
        let self.anchors[a:anchor]=node
    endif
    while !self.check_event("MappingEndEvent")
        " key_event=self.peek_event()
        let item_key=self.compose_node(node, -1)
        " if " has_key(node.value, item_key)
            " call self._warn(selfname, "Composer", ["dupkey", item_key],
                        " \   node.start_mark, item_key.start_mark)
        " endif
        let item_value=self.compose_node(node, item_key)
        call add(node.value, [item_key, item_value])
    endwhile
    let end_event=self.get_event()
    let node.end_mark=end_event.end_mark
    return node
endfunction
"{{{3 load.BaseConstructor
"{{{4 load.BaseConstructor.__init__
function s:F.load.BaseConstructor.__init__(super)
    let self.constructed_objects={}
    let self.recursive_objects={}
endfunction
"{{{4 load.BaseConstructor.check_data
function s:F.load.BaseConstructor.check_data()
    return self.check_node()
endfunction
"{{{4 load.BaseConstructor.get_data
function s:F.load.BaseConstructor.get_data()
    if self.check_node()
        return self.construct_document(self.get_node())
    endif
endfunction
"{{{4 load.BaseConstructor.get_single_data
function s:F.load.BaseConstructor.get_single_data()
    let node=self.get_single_node()
    if node!={}
        return self.construct_document(node)
    endif
    return {}
endfunction
"{{{4 load.BaseConstructor.construct_document
function s:F.load.BaseConstructor.construct_document(node)
    return self.construct_object(a:node)
endfunction
"{{{4 load.BaseConstructor.construct_object
function s:F.load.BaseConstructor.construct_object(node)
    let selfname='BaseConstructor.construct_object'
    if has_key(self.constructed_objects, a:node.id)
        return self.constructed_objects[a:node.id]
    elseif has_key(self.recursive_objects, a:node.id)
        call self._raise(selfname, "Constructor", "invrec", 0,
                    \    a:node.start_mark)
    endif
    " self.recursive_objects[a:node]=None
    let self.recursive_objects[a:node.id]=0
    let constructor={}
    let tag_suffix=0
    if has_key(self.yaml_constructors, a:node.tag)
        let constructor.f=self.yaml_constructors[a:node.tag]
    else
        for tag_prefix in keys(self.yaml_multi_constructors)
            if a:node.tag=~#'^'.s:F.plug.stuf.regescape(tag_prefix)
                let tag_suffix=a:node.tag[len(tag_prefix):]
                let constructor.f=self.yaml_multi_constructors[tag_prefix]
            endif
        endfor
        if !has_key(constructor, 'f')
            if has_key(self.yaml_multi_constructors, '_none')
                let tag_suffix=a:node.tag
                let constructor.f=self.yaml_multi_constructors._none
            elseif has_key(self.yaml_constructors, '_none')
                let constructor.f=self.yaml_constructors._none
            elseif a:node.__class__==#"ScalarNode"
                let constructor.f=self.construct_scalar
            elseif a:node.__class__==#"SequenceNode"
                let constructor.f=self.construct_sequence
            elseif a:node.__class__==#"MappingNode"
                let constructor.f=self.construct_mapping
            endif
        endif
    endif
    if tag_suffix is 0
        let l:Data=call(constructor.f, [a:node], self)
    else
        let l:Data=call(constructor.f, [a:node, tag_suffix], self)
    endif
    let self.constructed_objects[a:node.id]=l:Data
    silent! unlet self.recursive_objects[a:node.id]
    return l:Data
endfunction
"{{{4 load.BaseConstructor.construct_scalar :: NodeConstructor
function s:F.load.BaseConstructor.construct_scalar(node, ...)
    let selfname='BaseConstructor.construct_scalar'
    if a:node.__class__!=#"ScalarNode"
        call self._raise(selfname, "Constructor", ["notsc", a:node.__class__],
                    \    a:node.start_mark)
    endif
    return a:node.value
endfunction
"{{{4 load.BaseConstructor.construct_sequence :: NodeConstructor
function s:F.load.BaseConstructor.construct_sequence(node)
    let selfname='BaseConstructor.construct_sequence'
    if a:node.__class__!=#"SequenceNode"
        call self._raise(selfname, "Constructor", ["notseq", a:node.__class__],
                    \    0, a:node.start_mark)
    endif
    let sequence=[]
    let self.constructed_objects[a:node.id]=sequence
    for value_node in a:node.value
        call add(sequence, self.construct_object(value_node))
    endfor
    return sequence
endfunction
"{{{4 load.BaseConstructor.construct_mapping :: NodeConstructor
function s:F.load.BaseConstructor.construct_mapping(node)
    let selfname='BaseConstructor.construct_mapping'
    if a:node.__class__!=#"MappingNode"
        call self._raise(selfname, "Constructor", ["notmap", a:node.__class__],
                    \    0, a:node.start_mark)
    endif
    let mapping={}
    let self.constructed_objects[a:node.id]=mapping
    for [key_node, value_node] in a:node.value
        let l:Key=self.construct_object(key_node)
        let tkey=type(l:Key)
        if tkey!=type("")
            if tkey==type(0)
                let l:Key=string(l:Key)
                call self._warn(selfname, "Constructor", "numstr",
                            \   a:node.start_mark, key_node.start_mark)
            elseif tkey==type(0.0)
                let tmp=string(l:Key)
                unlet l:Key
                let l:Key=tmp
                call self._warn(selfname, "Constructor", "fltstr",
                            \   a:node.start_mark, key_node.start_mark)
            elseif tkey==type([])
                call self._raise(selfname, "Constructor", "lsthash",
                            \    a:node.start_mark, key_node.start_mark)
            elseif tkey==type({})
                call self._raise(selfname, "Constructor", "dcthash"
                            \    a:node.start_mark, key_node.start_mark)
            elseif tkey==2
                call self._raise(selfname, "Constructor", "dctfunc"
                            \    a:node.start_mark, key_node.start_mark)
            endif
        elseif l:Key==#""
            call self._raise(selfname, "Constructor", "nullhash",
                        \    a:node.start_mark, key_node.start_mark)
        endif
        let l:Value=self.construct_object(value_node)
        let mapping[l:Key]=l:Value
        unlet l:Key
        unlet l:Value
    endfor
    return mapping
endfunction
"{{{4 load.BaseConstructor.add_constructor
function s:F.load.BaseConstructor.add_constructor(tag, Constructor)
    let self.__variables__.yaml_constructors[a:tag]=a:Constructor
endfunction
"{{{4 load.BaseConstructor.add_multi_constructor
function s:F.load.BaseConstructor.add_multi_constructor(tag, Constructor)
    let self.__variables__.yaml_multi_constructors[a:tag]=a:Constructor
endfunction
"{{{3 load.SafeConstructor
let s:g.load.safeconstructor={}
"{{{4 load.SafeConstructor.construct_scalar
function s:F.load.SafeConstructor.construct_scalar(node)
    if a:node.__class__==#"MappingNode"
        for [key_node, value_node] in a:node.value
            if key_node.tag==#'tag:yaml.org,2002:value'
                return self.construct_scalar(value_node)
            endif
        endfor
    endif
    return call(s:F.load.BaseConstructor.construct_scalar, [a:node], self)
endfunction
"{{{4 load.SafeConstructor.flatten_mapping :: (self + (node)) -> _
function s:F.load.SafeConstructor.flatten_mapping(node)
    let selfname='SafeConstructor.flatten_mapping'
    let merge=[]
    let index=0
    while index<len(a:node.value)
        let [key_node, value_node]=a:node.value[index]
        if key_node.tag==#'tag:yaml.org,2002:merge'
            call remove(a:node.value, index)
            if value_node.__class__==#"MappingNode"
                call self.flatten_mapping(value_node)
                call extend(merge, value_node.value)
            elseif value_node.__class__==#"SequenceNode"
                let submerge=[]
                for subnode in value_node.value
                    if subnode.__class__!=#"MappingNode"
                        call self._raise(selfname, "Constructor",
                                    \    ["nmapseq", subnode.__class__],
                                    \    a:node.start_mark, subnode.start_mark)
                    endif
                    call self.flatten_mapping(subnode)
                    call add(submerge, subnode.value)
                endfor
                call reverse(submerge)
                for value in submerge
                    call extend(merge, value)
                endfor
            else
                call self._raise(selfname, "Constructor",
                            \    ["nmapseq", value_node.__class__],
                            \    a:node.start_mark, value_node.start_mark)
            endif
        elseif key_node.tag==#'tag:yaml.org,2002:value'
            let key_node.tag='tag:yaml.org,2002:str'
            let index+=1
        else
            let index+=1
        endif
    endwhile
    if !empty(merge)
        let a:node.value=merge+a:node.value
    endif
endfunction
"{{{4 load.SafeConstructor.construct_mapping
function s:F.load.SafeConstructor.construct_mapping(node)
    if a:node.__class__==#"MappingNode"
        call self.flatten_mapping(a:node)
    endif
    return call(s:F.load.BaseConstructor.construct_mapping, [a:node], self)
endfunction
"{{{4 load.SafeConstructor.construct_yaml_null
function s:F.load.SafeConstructor.construct_yaml_null(node)
    call self.construct_scalar(a:node)
    return s:g.yaml._undef
endfunction
"{{{4 load.SafeConstructor.construct_yaml_bool
function s:F.load.SafeConstructor.construct_yaml_bool(node)
    let value=self.construct_scalar(a:node)
    return ((value=~?'true')?(s:g.yaml._true):(s:g.yaml._false))
endfunction
"{{{4 load.SafeConstructor.construct_yaml_int
function s:F.load.SafeConstructor.construct_yaml_int(node)
    let value=self.construct_scalar(a:node)
    let value=tolower(substitute(value, '_', '', 'g'))
    let sign=1
    if value[0]==#'-'
        let sign=-1
    endif
    if value[0]==#'+' || value[0]==#'-'
        let value=value[1:]
    endif
    if value=='0'
        return 0
    elseif value[0:1]==#'0b'
        let r=0
        let value=value[2:]
        for digit in split(value, '\zs')
            let r=r*2+digit
        endfor
        return sign*r
    elseif value[0:1]==#'0x'
        return sign*str2nr(value, 16)
    elseif value[0]==#'0'
        return sign*str2nr(value, 8)
    elseif value=~#':'
        let digits=reverse(map(split(value, ':'), 'str2nr(v:val)'))
        let base=1
        let value=0
        for digit in digits
            let value+=digit*base
            let base=60*base
        endfor
        return sign*value
    else
        return sign*str2nr(value)
    endif
endfunction
"{{{4 load.SafeConstructor.construct_yaml_float
if has("float")
    function s:F.load.SafeConstructor.construct_yaml_float(node)
        let value=self.construct_scalar(a:node)
        let value=tolower(substitute(value, '_', '', 'g'))
        let sign=1
        if value[0]==#'-'
            let sign=-1
        endif
        if value[0]==#'-' || value[0]==#'+'
            let value=value[1:]
        endif
        if value==#'.inf'
            return sign*self.inf_value
        elseif value==#'.nan'
            return self.nan_value
        elseif value=~#':'
            let digits=reverse(map(split(value, ':'), 'str2float(v:val)'))
            let base=1
            unlet value
            let value=0.0
            for digit in digits
                let value+=digit*base
                let base=60*base
            endfor
            return sign*value
        else
            return sign*str2float(value)
        endif
    endfunction
endif
"{{{4 load.SafeConstructor.construct_yaml_binary
function s:F.load.SafeConstructor.construct_yaml_binary(node)
    let value=self.construct_scalar(a:node)
    let value=iconv(value, "utf-8", "latin1") " This should succeed even if 
                                              " !has("iconv")
    return s:F.plug.stuf.base64decode(value)
endfunction
"{{{4 load.SafeConstructor.construct_yaml_timestamp
let s:g.load.safeconstructor.timestampregex=
            \'^\d\d\d\d'.
            \'-\d\d\='.
            \'-\d\d\='.
            \'\%(\%([Tt]\|['.s:g.yaml.whitespace.']\+\)'.
            \   '\(\d\d\=\)'.
            \   ':\(\d\d\)'.
            \   ':\(\d\d\)'.
            \   '\%(\.\(\d*\)\)\='.
            \   '\%(['.s:g.yaml.whitespace.']*\(Z\|\([+-]\)\(\d\d\=\)'.
            \                                  '\%(:\(\d\d\)\)\=\)\)\=\)\=$'
let s:g.load.safeconstructor.tsstartregex=
            \'^\(\d\d\d\d\)'.
            \'-\(\d\d\=\)'.
            \'-\(\d\d\=\)'
function s:F.load.SafeConstructor.construct_yaml_timestamp(node)
    let value=self.construct_scalar(a:node)
    let matches=matchlist(value, s:g.load.safeconstructor.timestampregex)
    let matches0=matchlist(value, s:g.load.safeconstructor.tsstartregex)
    call insert(matches, matches0[1], 1)
    call insert(matches, matches0[2], 2)
    call insert(matches, matches0[3], 3)
    let year   = str2nr(matches[1])
    let month  = str2nr(matches[2])
    let day    = str2nr(matches[3])
    if matches[4]==#""
        return value
        " return datetime.date(year, month, day)
    endif
    let hour   = str2nr(matches[4])
    let minute = str2nr(matches[5])
    let second = str2nr(matches[6])
    let fraction=""
    if matches[7]!=#""
        let fraction=matches[7][:6]
        let fraction.=repeat('0', 6-len(fraction))
        let fraction=str2nr(fraction)
    endif
    let delta=0 " = None
    if matches[9]!=#""
        let tz_hour   = str2nr(matches[10])
        let tz_minute = str2nr(matches[11])
        " delta=datetime.timedelta(hours=tz_hours, minutes=tz_minutes)
        if matches[9]==#"-"
            let delta=-delta
        endif
    endif
    " data=datetime.datetime(year, month, day, hour, minute, second, fraction)
    if delta
        " data-=delta
    endif
    return value
endfunction
"{{{4 load.SafeConstructor.construct_yaml_omap
function s:F.load.SafeConstructor.construct_yaml_omap(node)
    let selfname='SafeConstructor.construct_yaml_omap'
    let omap=[]
    let self.constructed_objects[a:node.id]=omap
    if a:node.__class__!=#"SequenceNode"
        call self._raise(selfname, "Constructor",
                    \    ["nseqomap", a:node.__class__],
                    \    a:node.start_mark, a:node.start_mark)
    endif
    for subnode in a:node.value
        if subnode.__class__!=#"MappingNode"
            call self._raise(selfname, "Constructor",
                        \    ["nmapomap", a:node.__class__],
                        \    a:node.start_mark, subnode.start_mark)
        endif
        if len(subnode.value)!=1
            call self._raise(selfname, "Constructor",
                        \    ["nmlenomap", len(a:node.value)],
                        \    a:node.start_mark, subnode.start_mark)
        endif
        let [key_node, value_node]=subnode.value[0]
        let l:Key=self.construct_object(key_node)
        let value=self.construct_object(value_node)
        call add(omap, [l:Key, value])
        unlet l:Key
        unlet value
    endfor
    return omap
endfunction
"{{{4 load.SafeConstructor.construct_yaml_pairs
function s:F.load.SafeConstructor.construct_yaml_pairs(node)
    let selfname='SafeConstructor.construct_yaml_pairs'
    let pairs=[]
    let self.constructed_objects[a:node.id]=pairs
    if a:node.__class__!=#"SequenceNode"
        call self._raise(selfname, "Constructor",
                    \    ["nseqpr", a:node.__class__],
                    \    a:node.start_mark, a:node.start_mark)
    endif
    for subnode in a:node.value
        if subnode.__class__!=#"MappingNode"
            call self._raise(selfname, "Constructor",
                        \    ["nmappr", a:node.__class__],
                        \    a:node.start_mark, subnode.start_mark)
        endif
        if len(subnode.value)!=1
            call self._raise(selfname, "Constructor",
                        \    ["nmlenpr", len(a:node.value)],
                        \    a:node.start_mark, subnode.start_mark)
        endif
        let [key_node, value_node]=subnode.value[0]
        let l:Key=self.construct_object(key_node)
        let l:Value=self.construct_object(value_node)
        call add(pairs, [l:Key, l:Value])
        unlet l:Key
        unlet l:Value
    endfor
    return pairs
endfunction
"{{{4 load.SafeConstructor.construct_yaml_set
function s:F.load.SafeConstructor.construct_yaml_set(node)
    let value=self.construct_mapping(a:node)
    let data=sort(keys(value))
    let self.constructed_objects[a:node.id]=data
    return data
endfunction
"{{{4 load.SafeConstructor.construct_yaml_str
function s:F.load.SafeConstructor.construct_yaml_str(node)
    return self.construct_scalar(a:node)
endfunction
"{{{4 load.SafeConstructor.construct_yaml_seq
function s:F.load.SafeConstructor.construct_yaml_seq(node)
    return self.construct_sequence(a:node)
endfunction
"{{{4 load.SafeConstructor.construct_yaml_map
function s:F.load.SafeConstructor.construct_yaml_map(node)
    return self.construct_mapping(a:node)
endfunction
"{{{4 load.SafeConstructor.construct_undefined
function s:F.load.SafeConstructor.construct_undefined(node)
    let selfname='SafeConstructor.construct_undefined'
    call self._raise(selfname, "Constructor", ["unundef", a:node.tag],
                \    0, a:node.start_mark)
endfunction
"{{{3 load.Constructor
"{{{4 load.Constructor.construct_vim_function
function s:F.load.Constructor.construct_vim_function(node)
    let selfname='Constructor.construct_vim_function'
    let value=self.construct_scalar(a:node)
    if value!~#'^\d*$'
        if value[0:1]==#'s:'
            call self._raise(selfname, "Constructor", ["fscript", value],
                        \    0, a:node.start_mark)
        endif
        try
            let fex=exists('*'.value)
        catch /^Vim\%((\a\+)\)\=:E129/
            call self._raise(selfname, "Constructor", ["finvname", value],
                        \    0, a:node.start_mark)
        endtry
        if exists('fex') && fex
            return function(value)
        else
            call self._raise(selfname, "Constructor", ["fundef", value],
                        \    0, a:node.start_mark)
        endif
    else
        call self._raise(selfname, "Constructor", ["fnum", str2nr(value)],
                    \    0, a:node.start_mark)
    endif
endfunction
"{{{4 load.Constructor.construct_vim_locked
function s:F.load.Constructor.construct_vim_locked(node, tag_suffix)
    let tag='tag:yaml.org,2002:vim/'.a:tag_suffix
    if has_key(self.yaml_constructors, tag)
        let l:Data=call(self.yaml_constructors[tag], [a:node], self)
    else
        let a:node.tag=tag
        unlet self.recursive_objects[a:node.id]
        let l:Data=self.construct_object(a:node)
    endif
    lockvar 1 l:Data
    return l:Data
endfunction
"{{{4 load.Constructor.construct_vim_dictionary
function s:F.load.Constructor.construct_vim_dictionary(node)
    let selfname='Constructor.construct_vim_dictionary'
    if a:node.__class__!=#"MappingNode"
        call self._raise(selfname, "Constructor", ["notmap", a:node.__class__],
                    \    0, a:node.start_mark)
    endif
    let mapping={}
    let maplocked=0
    let self.constructed_objects[a:node.id]=mapping
    for [key_node, value_node] in a:node.value
        let locked=0
        let binary=0
        if key_node.tag==#'tag:yaml.org,2002:vim/Locked'
            let locked=1
            let key_node.tag='tag:yaml.org,2002:vim/String'
        elseif key_node.tag==#'tag:yaml.org,2002:Binary/vim/Locked'
            let locked=1
            let binary=1
            let key_node.tag='tag:yaml.org,2002:vim/String'
        endif
        let l:Key=self.construct_object(key_node)
        let tkey=type(l:Key)
        if tkey!=type("")
            if tkey==type(0)
                let l:Key=string(l:Key)
                call self._warn(selfname, "Constructor", "numstr",
                            \   a:node.start_mark, key_node.start_mark)
            elseif tkey==type(0.0)
                let tmp=string(l:Key)
                unlet l:Key
                let l:Key=tmp
                call self._warn(selfname, "Constructor", "fltstr",
                            \   a:node.start_mark, key_node.start_mark)
            elseif tkey==type([])
                call self._raise(selfname, "Constructor", "lsthash",
                            \    a:node.start_mark, key_node.start_mark)
            elseif tkey==type({})
                call self._raise(selfname, "Constructor", "dcthash"
                            \    a:node.start_mark, key_node.start_mark)
            elseif tkey==2
                call self._raise(selfname, "Constructor", "dctfunc"
                            \    a:node.start_mark, key_node.start_mark)
            endif
        elseif l:Key==#""
            call self._raise(selfname, "Constructor", "nullhash",
                        \    a:node.start_mark, key_node.start_mark)
        endif
        if binary
            let l:Key=s:F.plug.stuf.base64decode(l:Key)
        endif
        let l:Value=self.construct_object(value_node)
        if islocked('mapping')
            let maplocked=1
            unlockvar 1 mapping
        endif
        if has_key(mapping, l:Key) && islocked('mapping[l:Key]')
            unlockvar 1 mapping[l:Key]
        endif
        let mapping[l:Key]=l:Value
        if locked
            lockvar 1 mapping[l:Key]
        endif
        unlet l:Key
        unlet l:Value
    endfor
    if maplocked
        lockvar 1 mapping
    endif
    return mapping
endfunction
"{{{4 load.Constructor.construct_vim_list :: NodeConstructor
function s:F.load.Constructor.construct_vim_list(node)
    let selfname='Constructor.construct_vim_list'
    if a:node.__class__!=#"SequenceNode"
        call self._raise(selfname, "Constructor", ["notseq", a:node.__class__],
                    \    0, a:node.start_mark)
    endif
    let sequence=[]
    let seqlocked=0
    let self.constructed_objects[a:node.id]=sequence
    for value_node in a:node.value
        if value_node.tag[:32]==#'tag:yaml.org,2002:vim/LockedItem/'
            let locked=1
            let value_node.tag=substitute(value_node.tag, 'LockedItem/', '', '')
        elseif value_node.tag[:32]==#'tag:yaml.org,2002:vim/LockedAlias'
            let anchor=self.construct_scalar(value_node)
            if has_key(self.anchors, anchor)
                if islocked('sequence')
                    let seqlocked=1
                    unlockvar 1 sequence
                endif
                call add(sequence, self.construct_object(self.anchors[anchor]))
            else
                call self._raise(selfname, "Constructor", ['ualias', anchor],
                            \    a:node.start_mark, value_node.start_mark)
            endif
            lockvar 1 sequence[-1]
            continue
        else
            let locked=0
        endif
        if islocked('sequence')
            let seqlocked=1
            unlockvar 1 sequence
        endif
        call add(sequence, self.construct_object(value_node))
        if locked
            lockvar 1 sequence[-1]
        endif
    endfor
    if seqlocked
        lockvar 1 seqlocked
    endif
    return sequence
endfunction
"{{{4 load.Constructor.construct_custom_binary
function s:F.load.Constructor.construct_custom_binary(node, tag_suffix)
    let selfname='Constructor.construct_custom_binary'
    if a:node.__class__!=#"ScalarNode"
        call self._raise(selfname, "Constructor", ["notsc", a:node.__class__],
                    \    0, a:node.start_mark)
    endif
    let tag='tag:yaml.org,2002:'.a:tag_suffix
    let a:node.value=s:F.plug.stuf.base64decode(
                \iconv(self.construct_scalar(a:node), "utf-8", 'latin1'))
    if has_key(self.yaml_constructors, tag)
        let l:Data=call(self.yaml_constructors[tag], [a:node], self)
    else
        let a:node.tag=tag
        unlet self.recursive_objects[a:node.id]
        let l:Data=self.construct_object(a:node)
    endif
    return l:Data
endfunction
"{{{4 load.Constructor.construct_vim_buffer  XXX |
"{{{4 load.Constructor.construct_vim_window  XXX |
"{{{4 load.Constructor.construct_vim_tag     XXX |
"{{{4 load.Constructor.construct_vim_session XXX +-> to load.vim
"{{{4 load.Constructor.construct_vim_object (oop.vim support) XXX -> to oop.vim
"{{{3 load.loads
function s:F.load.loads(stream)
    let loader=s:F.plug.oop.getinstance("Loader", a:stream)
    return loader.get_single_data()
endfunction
"{{{3 load.load_all
function s:F.load.load_all(stream)
    let loader=s:F.plug.oop.getinstance("Loader", a:stream)
    let r=[]
    while loader.check_data()
        call add(r, loader.get_data())
    endwhile
    return r
endfunction
"{{{3 load.add_constructor
function s:F.load.add_constructor(tag, Constructor)
    let cobj=s:F.plug.oop.getinstance("BaseConstructor")
    call cobj.add_constructor(a:tag, a:Constructor)
endfunction
"{{{3 load.add_multi_constructor
function s:F.load.add_multi_constructor(tag, Constructor)
    let cobj=s:F.plug.oop.getinstance("BaseConstructor")
    call cobj.add_multi_constructor(a:tag, a:Constructor)
endfunction
"{{{3 load.del_constructor
function s:F.load.del_constructor(tag)
    unlet s:g.load.BaseConstructor.yaml_constructors[a:tag]
endfunction
"{{{3 load.del_multi_constructor
function s:F.load.del_multi_constructor(tag)
    unlet s:g.load.BaseConstructor.yaml_multi_constructors[a:tag]
endfunction
"{{{3 load.prepare_cls_list
function s:F.load.prepare_cls_list(name, ...)
    let r=[a:name]
    if has_key(s:F.load, a:name)
        call s:F.plug.stuf.let(r, 1, s:F.load[a:name], {})
    endif
    if has_key(s:g.load, a:name)
        call s:F.plug.stuf.let(r, 2, s:g.load[a:name], {})
    endif
    if !empty(a:000)
        call s:F.plug.stuf.let(r, 3, a:000, {})
    endif
    return r
endfunction
"{{{3 load.setclass
let s:g.load.classdeletes=[]
function s:F.load.setclass(...)
    call add(s:g.load.classdeletes,
                \call(s:F.plug.oop.registerclass,
                \     call(s:F.load.prepare_cls_list, a:000, {}),
                \     {}))
endfunction
"{{{3 Создание классов
call s:F.load.setclass("Token")
call s:F.load.setclass("DirectiveToken",          "Token")
call s:F.load.setclass("DocumentStartToken",      "Token")
call s:F.load.setclass("DocumentEndToken",        "Token")
call s:F.load.setclass("StreamStartToken",        "Token")
call s:F.load.setclass("StreamEndToken",          "Token")
call s:F.load.setclass("BlockSequenceStartToken", "Token")
call s:F.load.setclass("BlockMappingStartToken",  "Token")
call s:F.load.setclass("BlockEndToken",           "Token")
call s:F.load.setclass("FlowSequenceStartToken",  "Token")
call s:F.load.setclass("FlowMappingStartToken",   "Token")
call s:F.load.setclass("FlowSequenceEndToken",    "Token")
call s:F.load.setclass("FlowMappingEndToken",     "Token")
call s:F.load.setclass("KeyToken",                "Token")
call s:F.load.setclass("ValueToken",              "Token")
call s:F.load.setclass("BlockEntryToken",         "Token")
call s:F.load.setclass("FlowEntryToken",          "Token")
call s:F.load.setclass("AliasToken",              "Token")
call s:F.load.setclass("AnchorToken",             "Token")
call s:F.load.setclass("TagToken",                "Token")
call s:F.load.setclass("ScalarToken",             "Token")

call s:F.load.setclass("Event")
call s:F.load.setclass("DocumentStartEvent", "Event")
call s:F.load.setclass("DocumentEndEvent",   "Event")
call s:F.load.setclass("StreamStartEvent",   "Event")
call s:F.load.setclass("StreamEndEvent",     "Event")
call s:F.load.setclass("CollectionEndEvent", "Event")
call s:F.load.setclass("NodeEvent",          "Event")
call s:F.load.setclass("AliasEvent",           "NodeEvent")
call s:F.load.setclass("ScalarEvent",          "NodeEvent")
call s:F.load.setclass("CollectionStartEvent", "NodeEvent")
call s:F.load.setclass("SequenceStartEvent", "CollectionStartEvent")
call s:F.load.setclass("SequenceEndEvent",   "CollectionEndEvent")
call s:F.load.setclass("MappingStartEvent",  "CollectionStartEvent")
call s:F.load.setclass("MappingEndEvent",    "CollectionEndEvent")

call s:F.load.setclass("Node")
call s:F.load.setclass("ScalarNode",     "Node")
call s:F.load.setclass("CollectionNode", "Node")
call s:F.load.setclass("SequenceNode", "CollectionNode")
call s:F.load.setclass("MappingNode",  "CollectionNode")

call s:F.load.setclass("YAMLError", "Exception")
call s:F.load.setclass("ReaderError", "YAMLError")
call s:F.load.setclass("MarkedYAMLError", "YAMLError")
call s:F.load.setclass("ScannerError", "MarkedYAMLError")
call s:F.load.setclass("ParserError", "MarkedYAMLError")
call s:F.load.setclass("ComposerError", "MarkedYAMLError")
call s:F.load.setclass("ConstructorError", "MarkedYAMLError")
call s:F.load.setclass("InternalError", "MarkedYAMLError")

call s:F.load.setclass("SimpleKey")
call s:F.load.setclass("Mark")
call s:F.load.setclass("None")

call s:F.load.setclass("BaseConstructor")
call s:F.load.setclass("SafeConstructor", "BaseConstructor")
call s:F.load.setclass("Constructor",     "SafeConstructor")
call s:F.load.setclass("BaseResolver")
call s:F.load.setclass("Resolver", "BaseResolver")
call s:F.load.setclass("Composer")
call s:F.load.setclass("Parser")
call s:F.load.setclass("Scanner")
call s:F.load.setclass("Reader")
call s:F.load.setclass("Loader", "Reader", "Scanner", "Parser", "Composer",
            \                    "Constructor", "Resolver")
"{{{3 BaseResolver.add_implicit_resolver
let s:resolver=s:F.plug.oop.getinstance("BaseResolver")
call s:resolver.add_implicit_resolver('tag:yaml.org,2002:bool',
            \'^\%(true\|True\|TRUE'.
            \'\|false\|False\|FALSE\)$',
            \split("tTfF", '\zs'))
" call s:resolver.add_implicit_resolver('tag:yaml.org,2002:bool',
            " \'^\%(yes\|Yes\|YES\|no\|No\|NO\|true\|True\|TRUE\|false'.
            " \'\|False\|FALSE\|on\|On\|ON\|off\|Off\|OFF\)$',
            " \split("yYnNtTfFoO", '\zs'))
call s:resolver.add_implicit_resolver('tag:yaml.org,2002:float',
            \'^\%([+-]\=\%([0-9][0-9_]*\)\.[0-9_]*\%([eE][-+][0-9]\+\)\='.
            \'\|\.[0-9_]\+\%([eE][-+][0-9]\+\)\='.
            \'\|[-+]\=[0-9][0-9_]*\%(:[0-5]\=[0-9]\)\+\.[0-9_]*'.
            \'\|[-+]\=\.\%(inf\|Inf\|INF\)'.
            \'\|\.\%(nan\|NaN\|NAN\)\)$',
            \split('-+0123456789.', '\zs'))
call s:resolver.add_implicit_resolver('tag:yaml.org,2002:int',
            \'^\%([-+]\=0b[0-1_]\+'.
            \'\|[-+]\=0[0-7_]\+'.
            \'\|[-+]\=\%(0\|[1-9][0-9_]*\)'.
            \'\|[-+]\=0x[0-9a-fA-F_]\+'.
            \'\|[-+]\=[1-9][0-9_]*\%(:[0-5]\=[0-9]\)\+\)$',
            \split('-+0123456789', '\zs'))
call s:resolver.add_implicit_resolver('tag:yaml.org,2002:merge', '^<<$', ['<'])
call s:resolver.add_implicit_resolver('tag:yaml.org,2002:null',
            \'^\%(\~\|null\|Null\|NULL\|\)$', ['~', 'n', 'N', ''])
call s:resolver.add_implicit_resolver('tag:yaml.org,2002:timestamp',
            \'^\%(\d\d\d\d-\d\d-\d\d'.
            \'\|\d\d\d\d-\d\d\=-\d\d\=\%([Tt]\|\s\+\)\d\d\=:\d\d:\d\d'.
            \                       '\%(\.\d*\)\='.
            \               '\%(\s*\%(Z\|[-+]\d\d\=\%(:\d\d\)\=\)\)\=\)$',
            \split('0123456789', '\zs'))
call s:resolver.add_implicit_resolver('tag:yaml.org,2002:value', '^=$', ['='])
unlet s:resolver
"{{{3 Constructor.add_constructor
let s:constructor=s:F.plug.oop.getinstance("BaseConstructor")
call s:constructor.add_constructor('tag:yaml.org,2002:vim/String',
            \s:F.load.SafeConstructor.construct_yaml_str)
call s:constructor.add_constructor('tag:yaml.org,2002:vim/List',
            \s:F.load.Constructor.construct_vim_list)
call s:constructor.add_constructor('tag:yaml.org,2002:vim/Float',
            \s:F.load.SafeConstructor.construct_yaml_float)
call s:constructor.add_constructor('tag:yaml.org,2002:vim/Number',
            \s:F.load.SafeConstructor.construct_yaml_int)
call s:constructor.add_constructor('tag:yaml.org,2002:vim/Dictionary',
            \s:F.load.Constructor.construct_vim_dictionary)
call s:constructor.add_constructor('tag:yaml.org,2002:vim/Funcref',
            \s:F.load.Constructor.construct_vim_function)
call s:constructor.add_multi_constructor('tag:yaml.org,2002:vim/Locked',
            \s:F.load.Constructor.construct_vim_locked)
call s:constructor.add_multi_constructor('tag:yaml.org,2002:Binary/',
            \s:F.load.Constructor.construct_custom_binary)
unlet s:constructor
"{{{3 SafeConstructor.add_constructor
let s:constructor=s:F.plug.oop.getinstance("BaseConstructor")
call s:constructor.add_constructor('tag:yaml.org,2002:null',
            \s:F.load.SafeConstructor.construct_yaml_null)
call s:constructor.add_constructor('tag:yaml.org,2002:bool',
            \s:F.load.SafeConstructor.construct_yaml_bool)
call s:constructor.add_constructor('tag:yaml.org,2002:int',
            \s:F.load.SafeConstructor.construct_yaml_int)
if has("float")
    call s:constructor.add_constructor('tag:yaml.org,2002:float',
                \s:F.load.SafeConstructor.construct_yaml_float)
endif
call s:constructor.add_constructor('tag:yaml.org,2002:binary',
            \s:F.load.SafeConstructor.construct_yaml_binary)
call s:constructor.add_constructor('tag:yaml.org,2002:timestamp',
            \s:F.load.SafeConstructor.construct_yaml_timestamp)
call s:constructor.add_constructor('tag:yaml.org,2002:omap',
            \s:F.load.SafeConstructor.construct_yaml_omap)
call s:constructor.add_constructor('tag:yaml.org,2002:pairs',
            \s:F.load.SafeConstructor.construct_yaml_pairs)
call s:constructor.add_constructor('tag:yaml.org,2002:set',
            \s:F.load.SafeConstructor.construct_yaml_set)
call s:constructor.add_constructor('tag:yaml.org,2002:str',
            \s:F.load.SafeConstructor.construct_yaml_str)
call s:constructor.add_constructor('tag:yaml.org,2002:seq',
            \s:F.load.SafeConstructor.construct_yaml_seq)
call s:constructor.add_constructor('tag:yaml.org,2002:map',
            \s:F.load.SafeConstructor.construct_yaml_map)
call s:constructor.add_constructor('_none',
            \s:F.load.SafeConstructor.construct_undefined)
unlet s:constructor
"{{{2 dump: dumps
let s:g.dump={}
let s:g.dump.typenames=["Number", "String", "Funcref", "List", "Dictionary",
            \           "Float"]
"{{{3 dump.findobj
function s:F.dump.findobj(obj, r, dumped, opts)
    if type(a:obj)!=type({}) && type(a:obj)!=type([])
        return ""
    endif
    for [line, info] in items(a:dumped)
        if a:obj is info[0]
            if info[1]==#""
                let info[1]="l".line
                let a:r[line-1].=" &".info[1]
            endif
            return info[1]
        endif
    endfor
    let a:dumped[len(a:r)]=[a:obj, ""]
    return ""
endfunction
"{{{3 dump.dumpnum
function s:F.dump.dumpnum(obj, r, dumped, opts)
    let a:r[-1].=" ".a:obj
    return a:r
endfunction
"{{{3 dump.choose_scalar_style
"{{{4 Стили скаляров:
"   Неблочные:
"       Простой:
"           - "ns-char - c-indicator | [?:-] ns-plain-safe(c)"
"           - "ns-char = nb-char - s-white"
"           - "nb-char = c-printable - b-char - c-byte-order-mark"
"           - "c-printable=x09|x0A|x0D|x20-x7E|x85|xA0-xD7FF|xE000-xFFFD|
"                          x10000-x10FFFF"
"           - "b-char = \r|\n"
"           - "c-byte-order-mark = xFEFF"
"           - "s-white = \t|<SPACE>"
"           - "ns-plain-safe(c) =
"                   c=(flow-out|block-key) => ns-plain-safe-out
"                   c=(flow-in|flow-key)   => ns-plain-safe-in"
"           - "ns-plain-safe-in  = ns-char - c-flow-indicator"
"           - "ns-plain-safe-out = ns-char"
"           - "c-flow-indicator = ,|[|]|{|}"
"           - "ns-plain-char(c) = (ns-plain-safe(c) - : - #) |
"                                 (ns-char #) |
"                                 (: ns-plain-safe(c))"
"       С одинарными кавычками:
"           - "nb-single-char = ''|(nb-json - ')"
"           - "ns-single-char = nb-single-char - s-white"
"           - "nb-json = x09|x20-x10FFFF"
"           - "c-single-quoted(n,c) = ' nb-single-text(n,c) '"
"           - "nb-single-text(n,c) =
"                   c=(flow-out|flow-in)   => nb-single-multi-line(n)
"                   c=(block-key|flow-key) => nb-single-one-line"
"           - "nb-single-one-line = nb-single-char*"
"           - "nb-single-multi-line(n) = nb-ns-single-in-line
"                                        (s-single-next-line(n) | s-white*)"
"           - "nb-ns-single-in-line = (s-white* ns-single-char)*"
"           - "s-single-next-line(n) = s-flow-folded(n)
"                                      (ns-single-char nb-ns-single-in-line
"                                       (s-single-next-line(n) | s-white*))?"
"       С двойными кавычками:
"           - "nb-double-char = c-ns-esc-char | (nb-json - \ - ")"
"           - "ns-double-char = nb-double-char - s-white"
"           - "c-double-quoted(n,c) = " nb-double-text(n,c) ""
"           - "nb-double-text(n,c) =
"                   c=(flow-out|flow-in)   => nb-double-multi-line(n)
"                   c=(block-key|flow-key) => nb-double-one-line"
"           - "nb-double-one-line = nb-double-char*"
"       ...
"}}}4
function s:F.dump.choose_scalar_style(scalar, opts, iskey)
    "{{{4 Пустой скаляр
    if empty(a:scalar)
        " Данный выбор не влияет на читабельность и совместим с 'all_flow'
        return 'double'
    endif
    "{{{4 Объявление переменных
    "{{{5 Возможные стили
    let plain=1
    let double=1
    let single=1
    let literal=1
    let folded=1
    let binary=1
    "{{{5 Запреты на стили
    if get(a:opts, 'all_flow', 0)
        let plain=0
        let single=0
        let literal=0
        let folded=0
    elseif a:iskey
        let literal=0
        let folded=0
    elseif a:scalar=~#'^['.s:g.yaml.wslbr.']'
        " В соотвестствии со спецификацией, строки, которые начинаются с лишних 
        " пробельных символов, не подвергаются line folding. Запрещаем иметь 
        " folded скаляры, в начале которых находятся пробельные символы, чтобы 
        " не разбираться с возможными проблемами.
        let folded=0
        " Также запрещено в цикле
        let plain=0
    endif
    if a:scalar=~?'\V\^\%(=\|<<\|true\|false\|null\|yes\|no\|on\|off\|~\)\$' ||
                \a:scalar=~#'['.s:g.yaml.wslbr.']$'
        let plain=0
    endif
    "{{{5 Переменные для цикла
    let i=0                " Смещение текущего символа
    let slen=len(a:scalar) " Длина скаляра
    let prevchar=""        " Предыдущий символ
    let linelen=0          " Длина текущей строки внутри скаляра
    let maxlinelen=0       " Максимальная длина строки внутри скаляра
    let wordlen=0          " Длина текущего слова внутри скаляра
    let maxwordlen=0       " Максимальная длина слова внутри скаляра
    " Следующие переменные нужны для принятие решения о выборе между "scalar" 
    " и 'scalar'
    let numsquote=0        " Количество символов одинарного штриха
    let numbsdq=0          " Количество обратных косых черт и двойных штрихов
    "{{{4 Основной цикл
    while i<slen
        "{{{5 Объявление переменных
        let char=matchstr(a:scalar, '.', i) " Текущий символ
        let lchar=len(char)                 " Его длина в байтах
        "{{{5 Символ является непечатным
        if !s:F.comm.isprintchar(char) || (char==#"\u2029" || char==#"\u2028")
            let plain=0
            let single=0
            let literal=0
            let folded=0
            " Байт не является представлением UTF-8 символа
            if nr2char(char2nr(char))!=#char
                return 'binary'
            endif
        endif
        "{{{5 Допустим «простой» скаляр
        if plain
            " В качестве первого символа простого скаляра недопустимы 
            " символы-индикаторы (за исключением знака вопроса, двоеточия 
            " и дефиса, за которыми не следует пробел). Также запрещаем простому 
            " скаляру начинаться с цифры или точки чтобы не проверять, может ли 
            " он быть прочитан как число
            if i==0
                if ((char=~#'^['.s:g.yaml.indicator.']$' &&
                            \!(char=~#'^[?:\-]$' &&
                            \  slen>=2 &&
                            \  s:F.comm.isnsplainsafechar(
                            \       matchstr(a:scalar, '.', 1)))) ||
                            \!s:F.comm.isnsplainsafechar(char)) ||
                            \a:scalar=~#'^[+-]\=[0-9.]'
                    let plain=0
                endif
            " После двоеточия не должен идти пробельный символ
            elseif char==#":"
                if !s:F.comm.isnsplainsafechar(matchstr(a:scalar, '.', i+lchar))
                    let plain=0
                endif
            " Также запретим пробельные символы, за которыми не следуют 
            " непробельные
            elseif !s:F.comm.isnsplainsafechar(char) &&
                        \!(char=~#'^['.s:g.yaml.whitespace.']$' &&
                        \  s:F.comm.isnsplainsafechar(
                        \       matchstr(a:scalar,
                        \           '^['.s:g.yaml.whitespace.']*\zs.',
                        \           i+lchar)))
                let plain=0
            endif
        endif
        "{{{5 Незакавыченные скаляры: простой скаляр и два блочных
        if plain || literal || folded
            " Если есть последовательность, похожая на комментарий, уберём 
            " незакавыченные скаляры
            if char==#"#"
                if prevchar=~#'^['.s:g.yaml.wslbr.']$'
                    let plain=0
                    let literal=0
                    let folded=0
                endif
            " На всякий случай запретим CR: его могут посчитать новой строкой
            elseif char==#"\r"
                let plain=0
                let literal=0
                let folded=0
            endif
        endif
        "{{{5 'scalar'
        if single
            " Запрещаем символы новой строки: мне неохота возиться с line 
            " folding для этого стиля
            if char=~#'^['.s:g.yaml.linebreak.']$'
                let single=0
            " Подсчитываем символы «"», «\» и «'»: на основе их количества будет 
            " делаться выбор между 'scalar' и "scalar"
            elseif char==#'"' || char==#'\'
                let numbsdq+=1
            elseif char==#''''
                let numsquote+=1
            endif
        endif
        "{{{5 Обрабатываем конец строки
        if char!=#"\n"
            let linelen+=1
        else
            if linelen>maxlinelen
                let maxlinelen=linelen
            endif
            let linelen=0
        endif
        "{{{5 Обрабатываем конец слова
        if !(char==#' ' || char==#"\n")
            let wordlen+=1
        else
            if wordlen>maxwordlen
                let maxwordlen=wordlen
            endif
            let wordlen=0
        endif
        "{{{5 Завершение цикла
        let prevchar=char
        let i+=len(char)
    endwhile
    "{{{4 Проверяем длину последей строки и последнего слова
    if linelen>maxlinelen
        let maxlinelen=linelen
    endif
    if wordlen>maxwordlen
        let maxwordlen=wordlen
    endif
    "{{{4 Выбираем стиль на основе собранных данных
    if slen>=80 && literal && maxlinelen<=80 && maxlinelen>=20
        return 'literal'
    elseif slen>=80 && folded && maxwordlen<=80 && maxlinelen>=20
        return 'folded'
    elseif plain && match(a:scalar, '['.s:g.yaml.whitespace.']$')==-1
        return 'plain'
    elseif single && numbsdq>=numsquote
        return 'single'
    elseif double
        return 'double'
    endif
    return 'binary'
endfunction
"{{{3 dump.str
let s:F.dump.str={}
"{{{4 dump.str.literal
function s:F.dump.str.literal(obj, r, dumped, opts, iskey)
    let indent=matchstr(a:r[-1], '^ *')."  "
    let chomp='+'
    if a:obj!~#'\n$'
        let chomp='-'
    endif
    let iindent=""
    if a:obj=~#'^['.s:g.yaml.whitespace.']'
        let iindent='2'
    endif
    let a:r[-1].=' |'.chomp.iindent
    let lines=split(a:obj, "\n", 1)
    let last=0
    while empty(lines[-1])
        call remove(lines, -1)
        let last+=1
    endwhile
    call extend(a:r, map(lines, '((empty(v:val))?(""):("'.indent.'")).v:val'))
    call extend(a:r, repeat([""], last-1))
    return a:r
endfunction
"{{{4 dump.str.folded
function s:F.dump.str.folded(obj, r, dumped, opts, iskey)
    let indent=matchstr(a:r[-1], '^ *')."  "
    let chomp='+'
    if a:obj!~#'\n$'
        let chomp='-'
    endif
    let iindent=""
    if a:obj=~#'^['.s:g.yaml.whitespace.']'
        let iindent='2'
    endif
    let a:r[-1].=' >'.chomp.iindent
    let lines=split(a:obj, "\n", 1)
    let last=0
    while empty(lines[-1])
        call remove(lines, -1)
        let last+=1
    endwhile
    for line in lines
        let llen=len(line)
        if llen>80
            let words=split(line, " ", 1)
            let line=""
            let llen=0
            let prevempty=0
            for word in words
                let wlen=len(word)
                let llen+=wlen
                if llen>80 && wlen && word[0]!=#"\t"
                    call add(a:r, indent.line)
                    let line=word
                    let llen=wlen
                else
                    let line.=((empty(line))?(""):(" ")).word
                    let llen+=!empty(line)
                endif
            endfor
            call add(a:r, indent.line)
        else
            call add(a:r, indent.line)
        endif
        call add(a:r, "")
    endfor
    call remove(a:r, -1)
    call extend(a:r, repeat([""], last-1))
    return a:r
endfunction
"{{{4 dump.str.plain
function s:F.dump.str.plain(obj, r, dumped, opts, iskey)
    let a:r[-1].=((a:iskey)?(""):(" ")).a:obj
    return a:r
endfunction
"{{{4 dump.str.single
function s:F.dump.str.single(obj, r, dumped, opts, iskey)
    let a:r[-1].=((a:iskey)?(""):(" ")).string(a:obj)
    return a:r
endfunction
"{{{4 dump.str.double
function s:F.dump.str.double(obj, r, dumped, opts, iskey)
    "{{{5 Объявление переменных
    let a:r[-1].=((a:iskey)?(""):(" ")).'"'
    let indent=substitute(a:r[-1], '.', ' ', 'g')
    let idx=0
    let slen=len(a:obj)
    let curword=""
    let wordlen=0
    let linelen=0
    let prevspace=0
    "{{{5 Представление
    while idx<slen
        " Так мы получим следующий символ без диакритики (а на следующей 
        " итерации получим диакритику без символа).
        let chnr=char2nr(a:obj[(idx):])
        let char=nr2char(chnr)
        let clen=len(char)
        let chkchar=a:obj[(idx):(idx+clen-1)]
        let idx+=clen
        if has_key(s:g.dump.escrev, char)
            " Экранирование
            let curword.=s:g.dump.escrev[char]
            let wordlen+=2
        elseif s:F.comm.isprintnr(chnr) && !(chnr==0x2029 || chnr==0x2028)
            let curword.=char
            let wordlen+=1
        else
            if chnr<0x100
                let curword.=printf('\x%0.2x', chnr)
                let wordlen+=4
            elseif chnr<0x10000
                let curword.=printf('\u%0.4x', chnr)
                let wordlen+=6
            elseif chnr<0x100000000
                let curword.=printf('\U%0.8x', chnr)
                let wordlen+=10
            else
                let curword.=char
                let wordlen+=1
            endif
        endif
    endwhile
    let a:r[-1].=curword
    let a:r[-1].='"'
    "}}}5
    return a:r
endfunction
"{{{4 dump.str.binary
function s:F.dump.str.binary(obj, r, dumped, opts, iskey)
    let selfname='dump.str.binary'
    if a:r[-1]=~#'!\S*$'
        if a:r[-1]=~#'!!LockedString$'
            let a:r[-1]=substitute(a:r[-1], '!!Locked\zsString$', 'binary', '')
        elseif a:r[-1]=~#'!!\S*$'
            let a:r[-1]=substitute(a:r[-1], '!!\zs\ze\S*$', 'Binary/', '')
        else
            call s:F.main.eerror(selfname, 'notimp', ["btdump"])
        endif
    else
        let a:r[-1].=((a:iskey)?(""):(" "))."!!binary"
    endif
    let a:r[-1].=" ".s:F.plug.stuf.base64encode(a:obj)
    return a:r
endfunction
"{{{3 dump.dumpstr
"{{{4 s:g.dump
let s:g.dump.escrev={
            \"\n": '\n',
            \"\\": '\\',
            \"\b": '\b',
            \"\f": '\f',
            \"\r": '\r',
            \"\"": '\"',
        \}
" According to http://www.yaml.org/spec/1.2/spec.html#id2770814, tab is allowed 
" inside quoted strings
            " \"\t": '\t',
"}}}4
function s:F.dump.dumpstr(obj, r, dumped, opts, ...)
    let selfname='dump.dumpstr'
    let iskey=!empty(a:000)
    let style=s:F.dump.choose_scalar_style(a:obj, a:opts, iskey)
    return s:F.dump.str[style](a:obj, a:r, a:dumped, a:opts, iskey)
endfunction
"{{{3 dump.dumpfun
function s:F.dump.dumpfun(obj, r, dumped, opts)
    let a:r[-1].=' !!vim/Funcref '.substitute(string(a:obj), 'function(\(.*\))',
                \                             '\1', '')
    return a:r
endfunction
"{{{3 dump.dumplst
function s:F.dump.dumplst(obj, r, dumped, opts)
    if empty(a:obj)
        let a:r[-1].=" []"
        return a:r
    endif
    let indent=matchstr(a:r[-1], '^ *')
    let i=0
    if get(a:opts, 'all_flow', 0)
        call add(a:r, indent.'  [')
    endif
    for l:Item in a:obj
        if get(a:opts, 'all_flow', 0)
            call add(a:r, indent.'    ')
        else
            call add(a:r, indent.'  -')
        endif
        let tobji=type(a:obj[i])
        let islocked=0
        if islocked('a:obj[i]') && get(a:opts, "preserve_locks", 0)
            let a:r[-1].=' !!vim/LockedItem/'
            let islocked=1
        endif
        call s:F.dump.dump(l:Item, a:r, a:dumped, a:opts, islocked)
        unlet l:Item
        if get(a:opts, 'all_flow', 0)
            let a:r[-1].=','
        endif
        let i+=1
    endfor
    if get(a:opts, 'all_flow', 0)
        call add(a:r, indent.'  ]')
    endif
    return a:r
endfunction
"{{{3 dump.dumpdct
function s:F.dump.dumpdct(obj, r, dumped, opts)
    if a:obj=={}
        let a:r[-1].=" {}"
        return a:r
    endif
    let indent=matchstr(a:r[-1], '^ *')
    let keylist=keys(a:obj)
    let l:Sortarg=get(a:opts, "key_sort", 0)
    if !(type(l:Sortarg)==type(0) && l:Sortarg==0)
        if type(l:Sortarg)==2
            call sort(keylist, l:Sortarg)
        else
            call sort(keylist)
        endif
    endif
    if get(a:opts, 'all_flow', 0)
        call add(a:r, indent.'  {')
    endif
    for key in keylist
        let l:Value=get(a:obj, key)
        if get(a:opts, 'all_flow', 0)
            call add(a:r, indent.'    ')
        else
            call add(a:r, indent.'  ')
        endif
        if islocked('a:obj[key]') && get(a:opts, "preserve_locks", 0)
            let a:r[-1].='!!vim/Locked '
        endif
        call s:F.dump.dump(key, a:r, a:dumped, a:opts, -1, 0)
        let a:r[-1].=":"
        call s:F.dump.dump(l:Value, a:r, a:dumped, a:opts, 0)
        unlet l:Value
        if get(a:opts, 'all_flow', 0)
            let a:r[-1].=','
        endif
    endfor
    if get(a:opts, 'all_flow', 0)
        call add(a:r, indent.'  }')
    endif
    return a:r
endfunction
"{{{3 dump.dumpflt
function s:F.dump.dumpflt(obj, r, dumped, opts)
    let a:r[-1].=' '.substitute(substitute(string(a:obj), 'e\zs\ze\d', '+', ''),
                \               '\ze\(inf\|nan\)', '.', '')
    return a:r
endfunction
"{{{3 dump.dump
function s:F.dump.dump(obj, r, dumped, opts, islocked, ...)
    let anchor=s:F.dump.findobj(a:obj, a:r, a:dumped, a:opts)
    let iskey=!empty(a:000)
    if anchor!=#""
        if get(a:opts, 'preserve_locks', 0) && a:r[-1]=~#' !!vim/LockedItem/$'
            let a:r[-1]=substitute(a:r[-1], ' !!vim/LockedItem/$',
                        \' !!vim/LockedAlias '.anchor, '')
            return a:r
        endif
        let a:r[-1].=" *".anchor
        return a:r
    endif
    let l:Obj=a:obj
    if a:islocked==1
        if islocked('l:Obj')
            let a:r[-1].='Locked'
        endif
        let a:r[-1].=s:g.dump.typenames[type(l:Obj)]
    elseif a:islocked==0
        let tag=""
        for l:Function in a:opts.custom_tags
            let result=call(l:Function, [l:Obj], {})
            if type(result)==type([]) && len(result)==2 &&
                        \type(result[0])==type("")
                let [tag, l:Obj]=result
                break
            endif
            unlet l:Function result
        endfor
        if tag==#""
            if get(a:opts, 'preserve_locks', 0)
                let tobj=type(l:Obj)
                if tobj==type([]) || tobj==type({})
                    let a:r[-1].=' !!vim/'.((islocked('l:Obj'))?
                                \               ("Locked"):
                                \               ("")).
                                \s:g.dump.typenames[tobj]
                endif
            endif
        else
            let a:r[-1].=((iskey)?(" "):("")).tag.
                        \((iskey)?(""):(" "))
        endif
    endif
    call call(s:g.dump.types[type(l:Obj)],
                \[l:Obj, a:r, a:dumped, a:opts]+a:000,
                \{})
    return a:r
endfunction
"{{{3 dump.dumps
"{{{4 s:g.dump
let s:g.dump.types=[s:F.dump.dumpnum, s:F.dump.dumpstr, s:F.dump.dumpfun,
            \       s:F.dump.dumplst, s:F.dump.dumpdct, s:F.dump.dumpflt]
"}}}4
function s:F.dump.dumps(obj, join, opts)
    let r=['%YAML 1.2', '---']
    if !has_key(a:opts, "custom_tags")
        let a:opts.custom_tags=[]
    endif
    call s:F.dump.dump(a:obj, r, {}, a:opts, 0)
    if get(a:opts, 'all_flow', 0)
        call filter(r, 'v:val[-1:]!=#" "')
    else
        call add(r, '...')
    endif
    return a:join ? join(r, "\n") : r
endfunction
"{{{2 mng: main
"{{{3 mng.main
function s:F.mng.main(action)
    let action=tolower(a:action)
    "{{{4 Действия
    " %-ACTIONS-%
    "}}}4
endfunction
"{{{1
lockvar! s:F
lockvar! s:g
unlockvar s:g.load.BaseResolver.yaml_implicit_resolvers
unlockvar s:g.load.BaseConstructor.yaml_constructors
unlockvar s:g.load.BaseConstructor.yaml_multi_constructors
" vim: ft=vim:ts=8:fdm=marker:fenc=utf-8

