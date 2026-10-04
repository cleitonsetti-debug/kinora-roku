' Botao em pilula (290x64) com icone: vidro em repouso; branco com texto escuro quando ativo.
' Icone e texto ficam centralizados. O estado (active) e controlado por quem recebe as teclas.
sub init()
    m.bg = m.top.findNode("bg")
    m.iconImg = m.top.findNode("iconImg")
    m.label = m.top.findNode("label")
end sub

sub refresh()
    m.label.text = m.top.text

    textW = m.label.boundingRect().width
    if textW <= 0 then textW = Len(m.top.text) * 14
    total = 32 + 14 + textW
    startX = (290 - total) / 2
    if startX < 14 then startX = 14
    m.iconImg.translation = [startX, 16]
    m.label.translation = [startX + 46, 0]

    base = m.top.icon
    if m.top.active then
        m.bg.uri = "pkg:/images/pillbtn_white.png"
        if base <> "" then m.iconImg.uri = "pkg:/images/" + base + "_dark.png"
        m.label.color = "0x0A0A0DFF"
    else
        m.bg.uri = "pkg:/images/pillbtn_glass.png"
        if base <> "" then m.iconImg.uri = "pkg:/images/" + base + ".png"
        m.label.color = "0xFFFFFFFF"
    end if
end sub
