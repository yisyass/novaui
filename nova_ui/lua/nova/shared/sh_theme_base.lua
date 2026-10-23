return {
    colors = {background = Color(11,15,23), surface = Color(21,27,39), elevated = Color(32,40,56),
        border = Color(58,66,84), accent = Color(167,139,250), accentHover = Color(189,169,255),
        text = Color(245,246,250), muted = Color(154,166,185), success = Color(74,222,165),
        danger = Color(251,113,133), warning = Color(251,191,36), overlay = Color(0,0,0,180),
        accentText = Color(11,15,23), dangerText = Color(11,15,23), disabled = Color(51,59,75), disabledText = Color(186,195,210)},
    typography = {family = 'Roboto', body = {size=17,weight=500}, small = {size=13,weight=500},
        label = {size=14,weight=700}, title = {size=29,weight=750}, heading = {size=21,weight=700}},
    radius = {sm=6, md=10, lg=14}, spacing = {xs=4, sm=8, md=12, lg=20, xl=28},
    border = {width=1}, surfaces = {base='background', raised='surface', floating='elevated'},
    animation = {duration=0.18},
    components = {button={radius='md',primary='accent',secondary='elevated',danger='danger'},
        panel={radius='lg',background='surface'}, card={radius='lg',background='surface',padding=20},
        nav={radius='sm'}, tile={radius='md'}, overlay={radius='md'}, menu={radius='md'}, modal={radius='lg'}}

}
