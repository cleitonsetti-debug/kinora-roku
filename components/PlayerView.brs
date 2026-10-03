' =============================================================================
' PlayerView: player proprio. A propria PlayerView recebe as teclas do controle
' (o Video fica sem a interface nativa), entao os controles aparecem com certeza.
'
'  Controles escondidos:  Baixo/Cima/* = mostrar controles   OK = pausar/continuar
'                         Esquerda/Direita = abre a barra de tempo   Voltar = sair
'  Controles visiveis:    Esquerda/Direita escolhem o botao, OK ativa
'                         (-10 s, pausar, +10 s, legendas, audio, proximo ep., fonte)
'                         Cima = barra de tempo; Voltar = esconder
'  Barra de tempo: Esquerda/Direita (com os controles escondidos tambem) movem o ponto,
'                  OK confirma; sem mexer por 3 s ele confirma sozinho; Voltar cancela
'  Tambem: Play = pausar, voltar-rapido/avancar-rapido = +-30 s
'
'  Alem disso: legendas (stream + addons "subtitles"), faixas de audio com idioma
'  preferido, episodios seguintes (cartao + reproducao automatica) e "Continuar assistindo".
' =============================================================================

sub init()
    m.video = m.top.findNode("video")
    m.timer = m.top.findNode("saveTimer")
    m.tickTimer = m.top.findNode("tickTimer")
    m.hintTimer = m.top.findNode("hintTimer")
    m.hideTimer = m.top.findNode("hideTimer")
    m.toastTimer = m.top.findNode("toastTimer")
    m.hintLabel = m.top.findNode("hintLabel")
    m.loadingLabel = m.top.findNode("loadingLabel")
    m.toast = m.top.findNode("toast")
    m.nextCard = m.top.findNode("nextCard")
    m.controls = m.top.findNode("controls")
    m.ctlTitle = m.top.findNode("ctlTitle")
    m.ctlInfo = m.top.findNode("ctlInfo")
    m.barFill = m.top.findNode("barFill")
    m.barKnob = m.top.findNode("barKnob")
    m.intro = m.top.findNode("intro")
    m.introTitle = m.top.findNode("introTitle")
    m.imdbBg = m.top.findNode("imdbBg")
    m.imdbLabel = m.top.findNode("imdbLabel")
    m.certBg = m.top.findNode("certBg")
    m.certLabel = m.top.findNode("certLabel")
    m.metaText = m.top.findNode("metaText")
    m.introTimer = m.top.findNode("introTimer")
    m.scrubTimer = m.top.findNode("scrubTimer")
    m.scrubHint = m.top.findNode("scrubHint")
    m.barTrack = m.top.findNode("barTrack")
    m.scrubTip = m.top.findNode("scrubTip")
    m.scrubTipLabel = m.top.findNode("scrubTipLabel")
    m.centerIcon = m.top.findNode("centerIcon")
    m.iconTimer = m.top.findNode("iconTimer")
    m.timeLeft = m.top.findNode("timeLeft")
    m.timeRight = m.top.findNode("timeRight")
    m.buttons = m.top.findNode("buttons")
    m.panel = m.top.findNode("panel")
    m.panelTitle = m.top.findNode("panelTitle")
    m.panelInfo = m.top.findNode("panelInfo")
    m.menu = m.top.findNode("menu")

    m.tasks = []
    m.req = invalid
    m.done = false
    m.attached = false
    m.playlist = []
    m.nextEp = invalid
    m.streamGen = 0
    m.streamPending = 0
    m.found = []
    m.unsupported = 0
    m.subsGen = 0
    m.subsPending = 0
    m.subsList = []
    m.streamSubs = []
    m.panelOpen = false
    m.panelMode = "subs"
    m.menuActions = []
    m.btnActions = []
    m.ctrlVisible = false
    m.nextVisible = false
    m.switching = false
    m.audioApplied = false
    m.subApplied = false
    m.hintShown = false
    m.preferAddonUrl = ""
    m.introShown = false
    m.scrubOrigin = "buttons"
    m.scrubMoved = false
    m.scrubbing = false
    m.scrubPos = 0.0
    m.scrubIdx = 0
    m.scrubDir = 0
    m.scrubAt = 0
    m.clock = CreateObject("roTimespan")
    m.clock.Mark()

    m.video.observeField("state", "onState")
    m.video.observeField("availableSubtitleTracks", "onTracksChanged")
    m.video.observeField("availableAudioTracks", "onTracksChanged")
    m.timer.observeField("fire", "onTimer")
    m.tickTimer.observeField("fire", "onTick")
    m.hintTimer.observeField("fire", "onHintTimer")
    m.hideTimer.observeField("fire", "onHideTimer")
    m.toastTimer.observeField("fire", "onToastTimer")
    m.iconTimer.observeField("fire", "onIconTimer")
    m.introTimer.observeField("fire", "onIntroTimer")
    m.scrubTimer.observeField("fire", "onScrubTimer")
    m.scrubHint.text = i18n("player_scrub_hint")
    m.menu.observeField("itemSelected", "onMenuSelected")
    m.buttons.observeField("itemSelected", "onButtonSelected")
    m.buttons.observeField("itemFocused", "onButtonFocused")
end sub

' Chamado pela MainScene depois de colocar a tela na arvore
sub focusView()
    m.attached = true
    focusCurrent()
end sub

sub focusCurrent()
    if not m.attached then return
    if m.panelOpen then
        m.menu.setFocus(true)
    else if m.scrubbing then
        m.top.setFocus(true)
    else if m.ctrlVisible then
        m.buttons.setFocus(true)
    else
        m.top.setFocus(true)
    end if
end sub

' ---------------------------------------------------------------------------
' Preparo da reproducao: legendas dos addons -> inicia o video
' ---------------------------------------------------------------------------
sub onRequest()
    r = m.top.request
    if r = invalid then return
    m.req = r
    m.streamSubs = []
    if Type(r.subs) = "roArray" then m.streamSubs = r.subs
    m.playlist = []
    if Type(r.playlist) = "roArray" then m.playlist = r.playlist
    m.preferAddonUrl = ""
    if Type(r.source) = "roAssociativeArray" then m.preferAddonUrl = asStr(r.source.addonUrl)
    computeNext()
    beginPrepare()
end sub

sub computeNext()
    m.nextEp = invalid
    idx = -1
    for i = 0 to m.playlist.count() - 1
        if m.playlist[i].id = m.req.videoId then
            idx = i
            exit for
        end if
    end for
    if idx >= 0 then
        if idx < m.playlist.count() - 1 then m.nextEp = m.playlist[idx + 1]
    else if Type(m.req.nextEp) = "roAssociativeArray" then
        m.nextEp = m.req.nextEp
    end if
end sub

sub beginPrepare()
    showLoading(i18n("player_preparing"))
    m.audioApplied = false
    m.subApplied = false
    subsBegin(asStr(m.req.info.kind), m.req.videoId)
end sub

sub onSubsReady()
    hideLoading()
    startPlayback()
end sub

function buildSubTracks() as Object
    all = []
    for each t in m.streamSubs
        all.push(t)
    end for
    for each t in m.subsList
        all.push(t)
    end for

    pref = m.global.optSubLang
    ordered = []
    if pref <> "off" then
        for each t in all
            if langMatches(asStr(t.lang), pref) then ordered.push(t)
        end for
    end if
    for each t in all
        if pref = "off" or not langMatches(asStr(t.lang), pref) then ordered.push(t)
    end for

    tracks = []
    for each t in ordered
        if tracks.count() >= 12 then exit for
        desc = langName(asStr(t.lang))
        lbl = asStr(t.label)
        if lbl <> "" then desc = desc + " (" + lbl + ")"
        tracks.push({ Language: toLang3(asStr(t.lang)), TrackName: asStr(t.url), Description: desc })
    end for
    return tracks
end function

sub startPlayback()
    r = m.req
    content = CreateObject("roSGNode", "ContentNode")
    content.url = r.url
    content.title = displayTitle()
    if r.format <> "" then content.streamFormat = r.format

    if m.global.optResume = true then
        posSec = getSavedPosition(r.videoId)
        if posSec > 0 then content.playStart = posSec
    end if

    if Type(r.headers) = "roArray" then
        if r.headers.count() > 0 then content.httpHeaders = r.headers
    end if

    tracks = buildSubTracks()
    if tracks.count() > 0 then content.subtitleTracks = tracks

    m.switching = false
    m.introShown = false
    m.intro.visible = false
    m.video.content = content
    m.video.control = "play"
    hideControls()
end sub

function displayTitle() as String
    t = asStr(m.req.info.name)
    sn = toInt(m.req.season)
    ep = toInt(m.req.episode)
    if sn > 0 or ep > 0 then t = t + "  " + epCode(sn, ep)
    return t
end function

' Titulo do episodio atual (da lista de episodios), se houver
function episodeTitle() as String
    for each e in m.playlist
        if e.id = m.req.videoId then return asStr(e.title)
    end for
    return ""
end function

' ---------------------------------------------------------------------------
' Estados do video
' ---------------------------------------------------------------------------
sub onState()
    st = m.video.state
    if st = "playing" then
        hideLoading()
        if m.centerIcon.visible then
            m.centerIcon.uri = "pkg:/images/ic_play_big.png"
            m.iconTimer.control = "stop"
            m.iconTimer.control = "start"
        end if
        m.timer.control = "start"
        m.tickTimer.control = "start"
        applyAudioPref()
        applySubPref()
        if m.ctrlVisible then
            refreshButtons()
            restartHide()
        end if
        if not m.introShown then
            m.introShown = true
            showIntro()
        end if
    else if st = "buffering" then
        if not m.switching then showLoading(i18n("loading"))
    else if st = "paused" then
        m.iconTimer.control = "stop"
        m.centerIcon.uri = "pkg:/images/ic_pause_big.png"
        m.centerIcon.visible = true
        if not m.switching and not m.panelOpen then showControls()
        if m.ctrlVisible then refreshButtons()
    else if st = "finished" then
        m.timer.control = "stop"
        m.tickTimer.control = "stop"
        if m.switching then return
        if m.nextEp <> invalid and m.global.optAutoNext = true then
            playNext()
        else
            finishEpisode()
            closePlayer()
        end if
    else if st = "error" then
        if m.switching then return
        m.timer.control = "stop"
        m.tickTimer.control = "stop"
        msg = m.video.errorMsg
        code = m.video.errorCode
        saveNow()
        closePlayer()
        showMessage(i18n("play_error_title"), trf2("play_error_body", msg, Str(code).trim()))
    end if
end sub

' ---------------------------------------------------------------------------
' Ficha de abertura: titulo, nota do IMDb, classificacao indicativa (se o addon
' fornecer), ano e generos. Aparece por 7 s quando o video comeca.
' ---------------------------------------------------------------------------
sub showHintOnce()
    if m.hintShown then return
    m.hintShown = true
    m.hintLabel.text = i18n("player_hint")
    m.hintLabel.visible = true
    m.hintTimer.control = "start"
end sub

function placeBadge(bg as Object, lbl as Object, text as String, x as Integer) as Integer
    lbl.text = text
    textW = lbl.boundingRect().width
    if textW <= 0 then textW = Len(text) * 13
    bw = textW + 32
    bg.width = bw
    bg.translation = [x, 0]
    lbl.translation = [x + 16, 0]
    bg.visible = true
    lbl.visible = true
    return x + bw + 16
end function

sub showIntro()
    if m.global.optIntro <> true or m.ctrlVisible then
        showHintOnce()
        return
    end if

    info = m.req.info
    m.introTitle.text = asStr(info.name)

    parts = []
    sn = toInt(m.req.season)
    ep = toInt(m.req.episode)
    if sn > 0 or ep > 0 then
        e = epCode(sn, ep)
        et = episodeTitle()
        if et <> "" then e = e + "  " + et
        parts.push(e)
    end if
    y = asStr(info.year)
    if y <> "" then parts.push(y)
    g = asStr(info.genres)
    if g <> "" then parts.push(g)
    m.metaText.text = joinWith(parts, "  •  ")

    x = 0
    rating = asStr(info.rating)
    if rating <> "" then
        x = placeBadge(m.imdbBg, m.imdbLabel, "IMDb " + rating, x)
    else
        m.imdbBg.visible = false
        m.imdbLabel.visible = false
    end if
    cert = asStr(info.cert)
    if cert <> "" then
        x = placeBadge(m.certBg, m.certLabel, UCase(cert), x)
    else
        m.certBg.visible = false
        m.certLabel.visible = false
    end if
    m.metaText.translation = [x, 0]

    m.intro.visible = true
    m.introTimer.control = "stop"
    m.introTimer.control = "start"
end sub

sub onIntroTimer()
    m.intro.visible = false
    showHintOnce()
end sub

sub onHintTimer()
    m.hintLabel.visible = false
end sub

sub onTimer()
    saveNow()
end sub

sub showLoading(text as String)
    m.loadingLabel.text = text
    m.loadingLabel.visible = true
end sub

sub hideLoading()
    m.loadingLabel.visible = false
end sub

sub showToast(text as String)
    m.toast.text = text
    m.toast.visible = true
    m.toastTimer.control = "stop"
    m.toastTimer.control = "start"
end sub

sub onToastTimer()
    m.toast.visible = false
end sub

sub onIconTimer()
    m.centerIcon.visible = false
end sub

' ---------------------------------------------------------------------------
' Controles (barra de progresso + botoes)
' ---------------------------------------------------------------------------
sub updateProgress()
    dur = m.video.duration
    posSec = m.video.position
    if m.scrubbing then posSec = m.scrubPos
    ratio = 0.0
    if dur > 0 then ratio = posSec / dur
    if ratio < 0 then ratio = 0.0
    if ratio > 1 then ratio = 1.0
    fillW = Int(1760 * ratio)

    ' no modo de ajuste a barra fica mais grossa e a bolinha maior
    th = 10
    ks = 28
    if m.scrubbing then
        th = 16
        ks = 40
    end if
    barTop = 795 - (th \ 2)
    m.barTrack.height = th
    m.barTrack.translation = [80, barTop]
    m.barFill.height = th
    m.barFill.translation = [80, barTop]
    if fillW < 12 then
        m.barFill.visible = false
        fillW = 0
    else
        m.barFill.width = fillW
        m.barFill.visible = true
    end if
    m.barKnob.width = ks
    m.barKnob.height = ks
    m.barKnob.translation = [80 + fillW - (ks \ 2), 795 - (ks \ 2)]

    if m.scrubbing then
        txt = formatTime(Int(posSec))
        if dur > 0 then txt = txt + "  /  " + formatTime(Int(dur))
        m.scrubTipLabel.text = txt
        tx = 80 + fillW - 125
        if tx < 80 then tx = 80
        if tx > 1590 then tx = 1590
        m.scrubTip.translation = [tx, 818]
        m.scrubTip.visible = true
        m.timeLeft.visible = false
        m.timeRight.visible = false
    else
        m.scrubTip.visible = false
        m.timeLeft.visible = true
        m.timeRight.visible = true
        m.timeLeft.text = formatTime(Int(posSec))
        if dur > 0 then
            m.timeRight.text = formatTime(Int(dur))
        else
            m.timeRight.text = ""
        end if
    end if
end sub

' ---------------------------------------------------------------------------
' Modo "ir para": mover pela barra de tempo e confirmar com OK
' ---------------------------------------------------------------------------
function enterScrub(origin as String) as Boolean
    if m.video.duration <= 0 then return false
    if not m.ctrlVisible then showControls()
    m.scrubOrigin = origin
    m.scrubMoved = false
    m.scrubbing = true
    m.scrubPos = m.video.position
    m.scrubIdx = 0
    m.scrubDir = 0
    m.hideTimer.control = "stop"
    m.scrubHint.visible = true
    m.scrubTimer.control = "stop"
    m.scrubTimer.control = "start"
    m.top.setFocus(true)
    updateProgress()
    return true
end function

sub exitScrub()
    m.scrubbing = false
    m.scrubTimer.control = "stop"
    m.scrubHint.visible = false
    updateProgress()
    if m.scrubOrigin = "hidden" then
        hideControls()
    else
        focusCurrent()
        restartHide()
    end if
end sub

' Parado por 3 s: confirma o ponto escolhido (ou sai, se nao mexeu)
sub onScrubTimer()
    if not m.scrubbing then return
    if m.scrubMoved then
        commitScrub()
    else
        exitScrub()
    end if
end sub

' Passos de 10, 10, 20, 30, 60, 90 e 120 s: segurar/repetir a tecla acelera
sub moveScrub(dir as Integer)
    steps = [10, 10, 20, 30, 60, 90, 120]
    now = m.clock.TotalMilliseconds()
    if dir = m.scrubDir and (now - m.scrubAt) < 700 then
        if m.scrubIdx < steps.count() - 1 then m.scrubIdx = m.scrubIdx + 1
    else
        m.scrubIdx = 0
    end if
    m.scrubDir = dir
    m.scrubAt = now
    dur = m.video.duration
    t = m.scrubPos + dir * steps[m.scrubIdx]
    if t < 0 then t = 0
    if t > dur - 2 then t = dur - 2
    m.scrubPos = t
    m.scrubMoved = true
    m.scrubTimer.control = "stop"
    m.scrubTimer.control = "start"
    updateProgress()
end sub

sub commitScrub()
    t = m.scrubPos
    m.video.seek = t
    showToast(i18n("player_goto") + "  " + formatTime(Int(t)))
    exitScrub()
end sub

sub addButton(content as Object, labels as Object, actions as Object, label as String, icon as String, action as String)
    c = content.createChild("ContentNode")
    c.title = label
    c.hdPosterUrl = "pkg:/images/" + icon + ".png"
    actions.push(action)
end sub

sub refreshButtons()
    content = CreateObject("roSGNode", "ContentNode")
    actions = []
    pauseLabel = i18n("player_pause")
    pauseIcon = "ic_pause"
    if m.video.state = "paused" then
        pauseLabel = i18n("player_resume")
        pauseIcon = "ic_play"
    end if
    addButton(content, [], actions, "-10 s", "ic_rewind", "back10")
    addButton(content, [], actions, pauseLabel, pauseIcon, "pause")
    addButton(content, [], actions, "+10 s", "ic_forward", "fwd10")
    addButton(content, [], actions, i18n("player_goto"), "ic_scrub", "scrub")
    addButton(content, [], actions, i18n("player_subs"), "ic_subs", "subs")
    addButton(content, [], actions, i18n("player_audio"), "ic_audio", "audio")
    if m.nextEp <> invalid then addButton(content, [], actions, i18n("player_next_short"), "ic_next", "next")
    addButton(content, [], actions, i18n("player_source"), "ic_info", "info")

    idx = m.buttons.itemFocused
    m.btnActions = actions
    m.buttons.content = content
    if idx > 0 and idx < actions.count() then m.buttons.jumpToItem = idx
end sub

sub showControls()
    if m.req = invalid or m.switching then return
    wasVisible = m.ctrlVisible
    m.ctlTitle.text = asStr(m.req.info.name)
    info = ""
    sn = toInt(m.req.season)
    ep = toInt(m.req.episode)
    if sn > 0 or ep > 0 then
        info = epCode(sn, ep)
        et = episodeTitle()
        if et <> "" then info = info + "  " + et
    else
        info = joinWith([asStr(m.req.info.year), asStr(m.req.info.genres)], "  •  ")
    end if
    m.ctlInfo.text = info
    refreshButtons()
    if not wasVisible then m.buttons.jumpToItem = 1
    updateProgress()
    hideNextCard()
    m.hintLabel.visible = false
    m.intro.visible = false
    m.controls.visible = true
    m.ctrlVisible = true
    focusCurrent()
    restartHide()
end sub

sub hideControls()
    m.controls.visible = false
    m.ctrlVisible = false
    m.hideTimer.control = "stop"
    focusCurrent()
end sub

' Some sozinho depois de alguns segundos, exceto se o video estiver pausado
sub restartHide()
    m.hideTimer.control = "stop"
    if m.scrubbing or m.video.state = "paused" then return
    m.hideTimer.control = "start"
end sub

sub onHideTimer()
    if m.panelOpen or m.scrubbing then return
    if m.video.state = "paused" then return
    hideControls()
end sub

sub onButtonFocused()
    if m.ctrlVisible then restartHide()
end sub

sub onButtonSelected()
    idx = m.buttons.itemSelected
    if idx < 0 or idx >= m.btnActions.count() then return
    act = m.btnActions[idx]
    restartHide()
    if act = "back10" then
        seekBy(-10)
    else if act = "fwd10" then
        seekBy(10)
    else if act = "pause" then
        togglePause()
    else if act = "scrub" then
        enterScrub("buttons")
    else if act = "subs" then
        openTrackPanel("subs")
    else if act = "audio" then
        openTrackPanel("audio")
    else if act = "next" then
        hideControls()
        playNext()
    else if act = "info" then
        openInfoPanel()
    end if
end sub

sub togglePause()
    st = m.video.state
    if st = "paused" then
        m.video.control = "resume"
    else if st = "playing" or st = "buffering" then
        m.video.control = "pause"
    end if
end sub

sub seekBy(delta as Integer)
    dur = m.video.duration
    if dur <= 0 then return
    t = m.video.position + delta
    if t < 0 then t = 0
    if t > dur - 2 then t = dur - 2
    m.video.seek = t
    sign = "+"
    if delta < 0 then sign = "-"
    showToast(sign + Str(Abs(delta)).trim() + " s   " + formatTime(Int(t)))
    if m.ctrlVisible then updateProgress()
end sub

' ---------------------------------------------------------------------------
' Faixas preferidas (idioma de audio e de legenda dos Ajustes)
' ---------------------------------------------------------------------------
function trackId(t as Object) as String
    v = asStr(t.TrackName)
    if v = "" then v = asStr(t.Name)
    return v
end function

function trackLabel(t as Object) as String
    d = asStr(t.Description)
    if d = "" then d = langName(asStr(t.Language))
    if d = "?" or d = "" then d = trackId(t)
    return d
end function

sub applyAudioPref()
    if m.audioApplied then return
    pref = m.global.optAudioLang
    if pref = "auto" then
        m.audioApplied = true
        return
    end if
    tracks = m.video.availableAudioTracks
    if Type(tracks) <> "roArray" then return
    if tracks.count() = 0 then return
    m.audioApplied = true
    for each t in tracks
        if langMatches(asStr(t.Language), pref) then
            m.video.audioTrack = trackId(t)
            exit for
        end if
    end for
end sub

sub applySubPref()
    if m.subApplied then return
    pref = m.global.optSubLang
    if pref = "off" then
        m.subApplied = true
        m.video.globalCaptionMode = "Off"
        return
    end if
    tracks = m.video.availableSubtitleTracks
    if Type(tracks) <> "roArray" then return
    if tracks.count() = 0 then return
    m.subApplied = true
    for each t in tracks
        if langMatches(asStr(t.Language), pref) then
            m.video.subtitleTrack = trackId(t)
            m.video.globalCaptionMode = "On"
            exit for
        end if
    end for
end sub

sub onTracksChanged()
    st = m.video.state
    if st = "playing" or st = "paused" then
        applyAudioPref()
        applySubPref()
    end if
end sub

' ---------------------------------------------------------------------------
' Proximo episodio
' ---------------------------------------------------------------------------
sub onTick()
    if m.ctrlVisible then updateProgress()
    if m.panelOpen or m.switching or m.ctrlVisible then return
    if m.nextEp = invalid then return
    st = m.video.state
    if st <> "playing" and st <> "paused" then return
    dur = m.video.duration
    posSec = m.video.position
    if dur < 480 then return
    remain = dur - posSec
    if remain <= 25 and remain > 0 then
        showNextCard(Int(remain))
    else
        hideNextCard()
    end if
end sub

sub showNextCard(seconds as Integer)
    n = m.nextEp
    m.top.findNode("nextTitle").text = i18n("player_next")
    info = epCode(toInt(n.season), toInt(n.episode))
    t = asStr(n.title)
    if t <> "" then info = info + "  " + t
    m.top.findNode("nextInfo").text = info
    hint = i18n("player_next_ok")
    if m.global.optAutoNext = true then hint = trf("player_next_in", Str(seconds).trim()) + "     " + hint
    m.top.findNode("nextHint").text = hint
    m.nextCard.visible = true
    m.nextVisible = true
end sub

sub hideNextCard()
    m.nextCard.visible = false
    m.nextVisible = false
end sub

sub playNext()
    if m.nextEp = invalid then return
    if m.switching then return
    m.switching = true
    m.timer.control = "stop"
    m.tickTimer.control = "stop"
    hideNextCard()
    finishEpisode()

    nxt = m.nextEp
    m.req.videoId = nxt.id
    m.req.season = nxt.season
    m.req.episode = nxt.episode
    m.video.control = "stop"
    computeNext()
    showLoading(i18n("player_loading_next"))
    streamsBegin(asStr(m.req.info.kind), nxt.id)
end sub

' Chamado pela biblioteca de fontes quando termina a busca do proximo episodio
sub onStreamsReady()
    idx = -1
    for i = 0 to m.found.count() - 1
        if m.found[i].addonUrl = m.preferAddonUrl then
            idx = i
            exit for
        end if
    end for
    if idx < 0 and m.found.count() > 0 then idx = 0

    if idx < 0 then
        hideLoading()
        closePlayer()
        showMessage(i18n("play_error_title"), i18n("player_no_next_sources"))
        return
    end if

    s = m.found[idx]
    m.req.url = s.url
    m.req.format = guessStreamFormat(s.url)
    m.req.headers = s.headers
    m.req.source = { addonName: s.addonName, addonUrl: s.addonUrl, label: s.title }
    m.streamSubs = s.subs
    beginPrepare()
end sub

' ---------------------------------------------------------------------------
' Painel lateral: legendas, audio e detalhes do addon/fonte
' ---------------------------------------------------------------------------
function sourceDetails() as String
    if Type(m.req.source) <> "roAssociativeArray" then return ""
    src = m.req.source
    lines = []
    addon = findAddon(asStr(src.addonUrl))
    if addon <> invalid then
        lines.push(addonDetailsText(addon))
    else if asStr(src.addonName) <> "" then
        lines.push(asStr(src.addonName))
    end if
    lbl = asStr(src.label)
    if lbl <> "" then lines.push(i18n("player_source") + ": " + lbl)
    return joinWith(lines, Chr(10) + Chr(10))
end function

sub fillMenu(labels as Object, actions as Object)
    content = CreateObject("roSGNode", "ContentNode")
    for each l in labels
        c = content.createChild("ContentNode")
        c.title = l
    end for
    m.menuActions = actions
    m.menu.content = content
    m.menu.jumpToItem = 0
end sub

sub openPanelNow()
    m.panelOpen = true
    m.panel.visible = true
    m.hideTimer.control = "stop"
    m.menu.setFocus(true)
end sub

sub openTrackPanel(mode as String)
    m.panelMode = mode
    labels = []
    actions = []
    tracks = invalid
    if mode = "subs" then
        m.panelTitle.text = i18n("player_subs")
        labels.push(i18n("opt_off"))
        actions.push("off")
        tracks = m.video.availableSubtitleTracks
    else
        m.panelTitle.text = i18n("player_audio")
        tracks = m.video.availableAudioTracks
    end if
    m.panelInfo.text = ""
    if Type(tracks) = "roArray" then
        for each t in tracks
            labels.push(trackLabel(t))
            actions.push(trackId(t))
        end for
    end if
    if labels.count() = 0 then
        labels.push(i18n("opt_auto"))
        actions.push("none")
    end if
    fillMenu(labels, actions)
    openPanelNow()
end sub

sub openInfoPanel()
    m.panelMode = "info"
    m.panelTitle.text = i18n("player_source")
    m.panelInfo.text = sourceDetails()
    fillMenu([i18n("player_close")], ["close"])
    openPanelNow()
end sub

sub closePanel()
    m.panelOpen = false
    m.panel.visible = false
    focusCurrent()
    if m.ctrlVisible then restartHide()
end sub

sub onMenuSelected()
    idx = m.menu.itemSelected
    if idx < 0 or idx >= m.menuActions.count() then return
    act = m.menuActions[idx]

    if m.panelMode = "subs" then
        if act = "off" then
            m.video.globalCaptionMode = "Off"
        else if act <> "none" then
            m.video.subtitleTrack = act
            m.video.globalCaptionMode = "On"
        end if
    else if m.panelMode = "audio" then
        if act <> "none" then m.video.audioTrack = act
    end if
    closePanel()
end sub

' ---------------------------------------------------------------------------
' Historico ("Continuar assistindo")
' ---------------------------------------------------------------------------
function buildEntry(videoId as String, season as Integer, episode as Integer, posSec as Integer, dur as Integer) as Object
    info = m.req.info
    return {
        videoId: videoId
        id: info.id
        kind: info.kind
        name: info.name
        poster: info.poster
        background: info.background
        description: Left(info.description, 120)
        year: info.year
        rating: info.rating
        genres: info.genres
        addon: info.addon
        season: season
        episode: episode
        position: posSec
        duration: dur
        ts: CreateObject("roDateTime").AsSeconds()
    }
end function

' Terminou: remove o item atual e, se houver proximo episodio, deixa a serie
' na lista apontando para ele (sem progresso)
sub finishEpisode()
    if m.req = invalid then return
    removeHistory(m.req.videoId)
    nxt = m.nextEp
    if Type(nxt) = "roAssociativeArray" then
        upsertHistory(buildEntry(nxt.id, nxt.season, nxt.episode, 0, 0))
    end if
    m.global.historyRev = m.global.historyRev + 1
end sub

sub saveNow()
    if m.req = invalid or m.switching then return
    posSec = Int(m.video.position)
    dur = Int(m.video.duration)
    if dur <= 0 or posSec < 10 then return

    if posSec >= dur * 0.95 then
        finishEpisode()
    else
        upsertHistory(buildEntry(m.req.videoId, m.req.season, m.req.episode, posSec, dur))
        m.global.historyRev = m.global.historyRev + 1
    end if
end sub

sub closePlayer()
    if m.done then return
    m.done = true
    m.video.control = "stop"
    m.top.finished = true
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    if m.panelOpen then
        if key = "back" then
            closePanel()
            return true
        end if
        return false
    end if

    ' ajuste da barra de tempo
    if m.scrubbing then
        if key = "left" then
            moveScrub(-1)
        else if key = "right" then
            moveScrub(1)
        else if key = "rewind" then
            m.scrubPos = m.scrubPos - 30
            if m.scrubPos < 0 then m.scrubPos = 0.0
            updateProgress()
        else if key = "fastforward" then
            m.scrubPos = m.scrubPos + 30
            if m.scrubPos > m.video.duration - 2 then m.scrubPos = m.video.duration - 2
            updateProgress()
        else if key = "OK" or key = "play" then
            commitScrub()
        else if key = "back" or key = "down" or key = "up" then
            exitScrub()
        end if
        return true
    end if

    ' atalhos que valem com ou sem controles na tela
    if key = "play" then
        togglePause()
        return true
    else if key = "rewind" then
        seekBy(-30)
        return true
    else if key = "fastforward" then
        seekBy(30)
        return true
    end if

    if m.ctrlVisible then
        if key = "up" then
            enterScrub("buttons")
            return true
        else if key = "back" then
            hideControls()
            return true
        end if
        return false
    end if

    ' controles escondidos
    if key = "back" then
        m.timer.control = "stop"
        m.tickTimer.control = "stop"
        saveNow()
        closePlayer()
        return true
    else if key = "OK" then
        if m.nextVisible then
            playNext()
        else
            togglePause()
        end if
        return true
    else if key = "down" or key = "up" or key = "options" then
        showControls()
        return true
    else if key = "left" or key = "right" then
        dir = -1
        if key = "right" then dir = 1
        if enterScrub("hidden") then
            moveScrub(dir)
        else
            seekBy(dir * 10)
        end if
        return true
    end if
    return false
end function
