' Categoria dos Ajustes: icone + nome. ContentNode: title, hdPosterUrl (icone)
sub init()
    m.card = m.top.findNode("card")
    m.icon = m.top.findNode("icon")
    m.name = m.top.findNode("name")
end sub

sub onLayout()
    w = m.top.width
    if w <= 0 then return
    m.card.width = w
    m.name.width = w - 110
end sub

sub onContentChange()
    c = m.top.itemContent
    if c = invalid then return
    m.name.text = c.title
    m.icon.uri = c.hdPosterUrl
end sub
