' Botao do player: icone em cima e rotulo pequeno embaixo
sub init()
    m.icon = m.top.findNode("icon")
    m.label = m.top.findNode("label")
end sub

sub onLayout()
    w = m.top.width
    if w <= 0 then return
    m.icon.translation = [(w - 56) / 2, 12]
    m.label.width = w
end sub

sub onContentChange()
    c = m.top.itemContent
    if c = invalid then return
    m.label.text = c.title
    m.icon.uri = c.hdPosterUrl
end sub
