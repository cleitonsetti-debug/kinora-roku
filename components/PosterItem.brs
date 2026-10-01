' Item de poster com cantos arredondados. Mostra o titulo abaixo quando o
' ContentNode tem title; mostra barra de progresso em itens de "continuar assistindo".
' Se a imagem falhar ao carregar, tenta de novo algumas vezes.
sub init()
    m.placeholder = m.top.findNode("placeholder")
    m.poster = m.top.findNode("poster")
    m.mask = m.top.findNode("mask")
    m.progressBg = m.top.findNode("progressBg")
    m.progressFg = m.top.findNode("progressFg")
    m.titleLabel = m.top.findNode("titleLabel")
    m.retryTimer = m.top.findNode("retryTimer")
    m.ratio = 0.0
    m.hasTitle = false
    m.url = ""
    m.retries = 0
    m.poster.observeField("loadStatus", "onPosterStatus")
    m.retryTimer.observeField("fire", "onRetry")
end sub

sub onLayout()
    w = m.top.width
    h = m.top.height
    if w <= 0 or h <= 0 then return
    ph = h
    if m.hasTitle then ph = h - 66
    m.placeholder.width = w
    m.placeholder.height = ph
    m.poster.width = w
    m.poster.height = ph
    m.mask.width = w
    m.mask.height = ph
    m.progressBg.width = w
    m.progressBg.translation = [0, ph - 6]
    m.progressFg.translation = [0, ph - 6]
    m.progressFg.width = Int(w * m.ratio)
    m.titleLabel.translation = [2, ph + 6]
    m.titleLabel.width = w - 4
end sub

sub onContentChange()
    c = m.top.itemContent
    if c = invalid then return
    t = c.title
    m.hasTitle = (t <> "")
    m.titleLabel.text = t
    m.titleLabel.visible = m.hasTitle

    m.retryTimer.control = "stop"
    m.retries = 0
    m.url = c.hdPosterUrl
    m.poster.uri = m.url

    m.ratio = 0.0
    if c.hasField("info") then
        info = c.info
        if info <> invalid then
            posSec = toInt(info.position)
            dur = toInt(info.duration)
            if dur > 0 and posSec > 0 then m.ratio = posSec / dur
            if m.ratio > 1.0 then m.ratio = 1.0
        end if
    end if
    m.progressBg.visible = (m.ratio > 0)
    m.progressFg.visible = (m.ratio > 0)
    onLayout()
end sub

sub onPosterStatus()
    if m.poster.loadStatus = "failed" and m.url <> "" and m.retries < 3 then
        m.retries = m.retries + 1
        m.retryTimer.control = "stop"
        m.retryTimer.control = "start"
    end if
end sub

sub onRetry()
    if m.url = "" then return
    m.poster.uri = ""
    m.poster.uri = m.url
end sub
