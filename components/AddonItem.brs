' Cartao de addon na lista: icone (logo do manifest ou inicial colorida), nome, subtitulo e status.
' ContentNode: title = nome, shortDescriptionLine1 = subtitulo, shortDescriptionLine2 = on|off|err|special,
' description = cor do acento (0xRRGGBBAA), hdPosterUrl = logo (ou icone, nos itens especiais)
sub init()
    m.circle = m.top.findNode("circle")
    m.initial = m.top.findNode("initial")
    m.logo = m.top.findNode("logo")
    m.name = m.top.findNode("name")
    m.subLabel = m.top.findNode("subLabel")
    m.dot = m.top.findNode("dot")
    m.card = m.top.findNode("card")
end sub

sub onLayout()
    w = m.top.width
    if w <= 0 then return
    m.card.width = w
    m.dot.translation = [w - 46, 41]
    m.name.width = w - 190
    m.subLabel.width = w - 190
end sub

sub onContentChange()
    c = m.top.itemContent
    if c = invalid then return
    m.name.text = c.title
    m.subLabel.text = c.shortDescriptionLine1
    state = c.shortDescriptionLine2
    m.logo.uri = c.hdPosterUrl

    if state = "special" then
        m.initial.visible = false
        m.dot.visible = false
        m.circle.blendColor = "0x3A3A46FF"
    else
        m.initial.visible = true
        m.initial.text = initialOf(c.title)
        if c.description <> "" then m.circle.blendColor = c.description
        m.dot.visible = true
        if state = "on" then
            m.dot.blendColor = "0x2ECC71FF"
        else if state = "err" then
            m.dot.blendColor = "0xFF4D4DFF"
        else
            m.dot.blendColor = "0x6A6A75FF"
        end if
    end if
end sub
