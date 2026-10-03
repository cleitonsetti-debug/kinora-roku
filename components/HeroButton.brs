' Botao do banner (320x72): "vidro" com texto branco; ativo = branco com texto escuro.
' Icone + texto ficam centralizados medindo a largura real do texto.
' O estado (active) e controlado pela HomeView, que e quem recebe as teclas.
sub init()
    m.bg = m.top.findNode("bg")
    m.icon = m.top.findNode("icon")
    m.label = m.top.findNode("label")
end sub

sub refresh()
    m.label.text = m.top.text

    textW = m.label.boundingRect().width
    if textW <= 0 then textW = Len(m.top.text) * 15
    total = 34 + 16 + textW
    startX = (320 - total) / 2
    if startX < 16 then startX = 16
    m.icon.translation = [startX, 19]
    m.label.translation = [startX + 50, 0]

    if m.top.active then
        m.bg.uri = "pkg:/images/herobtn_white.png"
        m.icon.uri = "pkg:/images/ic_info_dark.png"
        m.label.color = "0x0A0A0DFF"
    else
        m.bg.uri = "pkg:/images/herobtn_glass.png"
        m.icon.uri = "pkg:/images/ic_info.png"
        m.label.color = "0xFFFFFFFF"
    end if
end sub
