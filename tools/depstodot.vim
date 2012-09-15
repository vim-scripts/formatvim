execute frawor#Setup('0.0', {})
let s:deps={}
let s:rtppls={}
let s:plrtps={}
let s:dtd={'ignoredeps': 1}
function s:dtd.register(plugdict, fdict)
    let s:deps[a:plugdict.id]=a:plugdict.dependencies
    let rtp=a:plugdict.runtimepath
    if empty(rtp)
        let rtp='NA'
    endif
    if has_key(s:rtppls, rtp)
        let s:rtppls[rtp]+=[a:plugdict.id]
    else
        let s:rtppls[rtp]=[a:plugdict.id]
    endif
    if a:plugdict.id is# 'plugin/frawor'
        let s:deplen=a:plugdict.g.deplen
        let s:dependents=a:plugdict.g.dependents
    endif
endfunction
call s:_f.newfeature('depstodot', s:dtd)
let g:dtd={}
let s:colors=[
            \'aliceblue',
            \'antiquewhite4',
            \'aquamarine4',
            \'azure4',
            \'bisque3',
            \'blue1',
            \'brown',
            \'burlywood',
            \'cadetblue',
            \'chartreuse',
            \'chocolate',
            \'coral',
            \'cornflowerblue',
            \'cornsilk4',
            \'cyan3',
            \'darkgoldenrod3',
            \'darkolivegreen1',
            \'darkorange1',
            \'darkorchid1',
            \'darkseagreen',
            \'darkslateblue',
            \'darkslategray4',
            \'deeppink1',
            \'deepskyblue1',
            \'dimgrey',
            \'dodgerblue4',
            \'firebrick4',
            \'gold',
            \'goldenrod',
            \]
function g:dtd.write(file)
    let ranks=map(repeat([[]], max(values(s:deplen))+1), 'copy(v:val)')
    call map(copy(s:deplen), 'add(ranks[v:val], v:key)')
    let lines=['digraph G {']
    let lines+=['    concentrate = true;']
    let lines+=['    {']
    let lines+=['        node [shape=plaintext]']
    let lines+=['        '.join(range(1, len(ranks)-1), ' -> ').';']
    let lines+=['    }']
    let lines+=['    node [shape=box];']
    let i=0
    for nodes in ranks[1:]
        let i+=1
        let lines+=['    { node [fontcolor='.s:colors[i].']; rank = same; '.i.'; "'.join(nodes, '"; "').'"; }']
    endfor
    for [rtp, nodes] in sort(items(s:rtppls))
        let lines+=['    subgraph "'.rtp.'" {']
        let lines+=['        label = "'.fnamemodify(rtp, ':t').'";']
        let lines+=['        "'.join(nodes, '"; "').'";']
        let lines+=['    }']
    endfor
    for [plid, dependencies] in sort(items(s:deps))
        for dplid in sort(keys(dependencies))
            let lines+=['    edge [color='.s:colors[s:deplen[plid]].'];']
            let lines+=['    "'.plid.'" -> "'.dplid.'";']
        endfor
    endfor
    let lines+=['}', '']
    call writefile(lines, a:file, 'b')
endfunction
