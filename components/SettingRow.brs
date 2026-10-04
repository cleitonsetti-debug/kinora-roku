' Linha dos Ajustes: titulo + dica a esquerda, "pilula" com o valor a direita.
' ContentNode: title, description (dica), shortDescriptionLine1 (valor),
' shortDescriptionLine2 (tom da pilula: on | off | action | locked)
sub init()
    m.card = m.top.findNode("card")
    m.title = m.top.findNode("title")
    m.hint = m.top.findNode("hint")
    m.chip = m.top.findNode("chip")
    m.value = m.top.findNode("value")
    m.w = 1180
end sub

sub onLayout()
    w = m.top.width
    if w <= 0 then return
    m.w = w
    m.card.width = w
    m.title.width = w - 380
    m.hint.width = w - 380
    placeChip()
end sub

sub placeChip()
    txt = m.value.text
    textW = m.value.boundingRect().width
    if textW <= 0 then textW = Len(txt) * 13
    cw = textW + 44
    if cw < 120 then cw = 120
    if cw > 330 then cw = 330
    x = m.w - cw - 30
    m.chip.width = cw
    m.chip.translation = [x, 26]
    m.value.width = cw
    m.value.translation = [x, 26]
end sub

sub onContentChange()
    c = m.top.itemContent
    if c = invalid then return
    m.title.text = c.title
    m.hint.text = c.description
    m.value.text = c.shortDescriptionLine1
    tone = c.shortDescriptionLine2
    if tone = "on" then
        m.chip.blendColor = "0x2ECC71FF"
        m.value.color = "0xFFFFFFFF"
    else if tone = "off" then
        m.chip.blendColor = "0x6A6A75FF"
        m.value.color = "0xE6E6EEFF"
    else if tone = "locked" then
        m.chip.blendColor = "0xFF7A29FF"
        m.value.color = "0xFFFFFFFF"
    else
        m.chip.blendColor = "0xFFFFFFFF"
        m.value.color = "0xFFFFFFFF"
    end if
    placeChip()
end sub
