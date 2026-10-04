' Cartao de perfil: avatar colorido com a inicial, nome e etiqueta "Infantil".
' ContentNode: title = nome, shortDescriptionLine1 = inicial, shortDescriptionLine2 = cor (0xRRGGBBAA),
' description = etiqueta (ex.: Infantil)
sub init()
    m.avatar = m.top.findNode("avatar")
    m.initial = m.top.findNode("initial")
    m.name = m.top.findNode("name")
    m.kids = m.top.findNode("kids")
end sub

sub onLayout()
    w = m.top.width
    if w <= 0 then return
    x = (w - 160) / 2
    m.avatar.translation = [x, 20]
    m.initial.translation = [x, 20]
    m.name.width = w
    m.kids.width = w
end sub

sub onContentChange()
    c = m.top.itemContent
    if c = invalid then return
    m.name.text = c.title
    m.initial.text = c.shortDescriptionLine1
    col = c.shortDescriptionLine2
    if col <> "" then m.avatar.blendColor = col
    m.kids.text = c.description
end sub
