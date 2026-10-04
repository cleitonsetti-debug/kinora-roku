' =============================================================================
' HomeHero: banner (hero) da tela inicial - fundo com fade, carrossel de destaques,
' pontinhos, sinopse sob demanda. Incluido pela HomeView (usa o m dela).
' =============================================================================

sub setupHeroBtn()
    m.heroBtn.text = i18n("hero_details")
    m.heroBtn.icon = "ic_info"
    m.heroBtn2.icon = "ic_play"
    updateHero2Text()
end sub

sub updateHero2Text()
    if m.heroInfo <> invalid and asStr(m.heroInfo.videoId) <> "" then
        m.heroBtn2.text = i18n("hero_continue")
    else
        m.heroBtn2.text = i18n("details_watch")
    end if
end sub

' Copia do destaque para "Assistir/Continuar": abre a ficha e ja procura a fonte
function heroPlayInfo() as Object
    info = m.featured[m.fIdx]
    p = {}
    for each k in info
        p[k] = info[k]
    end for
    p.autoplay = true
    if asStr(p.videoId) = "" then
        p.videoId = asStr(p.id)
        p.season = 0
        p.episode = 0
    end if
    return p
end function

sub focusHeroBtn()
    if m.heroIdx = 1 and m.heroBtn2.visible then
        m.heroBtn2.setFocus(true)
    else
        m.heroIdx = 0
        m.heroBtn.setFocus(true)
    end if
end sub

' Brilho colorido do titulo em foco + zoom lento do fundo
sub applyAccent(info as Object)
    col = accentFor(asStr(info.id))
    m.glow.blendColor = col
    m.navIndicator.blendColor = col
    m.glow.visible = (m.global.optAmbient = true)
end sub

sub startZoom()
    m.zoomAnim.control = "stop"
    if m.global.optZoom = true then
        m.zoomAnim.control = "start"
    else
        m.heroZoom.scale = [1.0, 1.0]
    end if
end sub

' Foco voltou para a barra/filtros: retoma o carrossel de destaques
sub onTopFocus()
    refreshHeroChrome()
    if m.featured.count() > 0 then setHero(m.featured[m.fIdx], true)
end sub

sub refreshHeroChrome()
    carousel = (m.focusArea <> "rows")
    m.dots.visible = (m.featured.count() > 1 and carousel)
    m.heroBtn.visible = (m.featured.count() > 0 and carousel)
    playable = false
    if m.heroInfo <> invalid then
        playable = (asStr(m.heroInfo.videoId) <> "" or asStr(m.heroInfo.kind) = "movie")
    end if
    m.heroBtn2.visible = (m.heroBtn.visible and playable)
    if m.heroIdx = 1 and not m.heroBtn2.visible then m.heroIdx = 0
    m.heroBtn.active = (m.focusArea = "hero" and m.heroIdx = 0)
    m.heroBtn2.active = (m.focusArea = "hero" and m.heroIdx = 1)
end sub

' ---------------------------------------------------------------------------
' Banner (hero) do item em foco
' ---------------------------------------------------------------------------
sub setHero(info as Object, animate as Boolean)
    bg = asStr(info.background)
    m.heroBgNeeded = (bg = "")
    if bg = "" then bg = asStr(info.poster)
    setBackdrop(bg, animate)
    m.heroInfo = info
    applyAccent(info)
    startZoom()
    updateHero2Text()
    applyHeroInfo(info)
    refreshHeroChrome()
end sub

' Selo arredondado (fundo + texto) na posicao x; devolve o proximo x livre
function heroChip(bg as Object, lbl as Object, text as String, x as Integer) as Integer
    lbl.text = text
    textW = lbl.boundingRect().width
    if textW <= 0 then textW = Len(text) * 12
    w = textW + 30
    bg.width = w
    bg.translation = [x, 228]
    lbl.translation = [x + 15, 228]
    bg.visible = true
    lbl.visible = true
    return x + w + 14
end function

sub applyHeroInfo(info as Object)
    m.heroTitle.text = asStr(info.name)

    x = 80
    k = kindSingular(asStr(info.kind))
    sn = toInt(info.season)
    ep = toInt(info.episode)
    if sn > 0 or ep > 0 then k = k + " " + epCode(sn, ep)
    if k <> "" then
        x = heroChip(m.kindBg, m.kindLabel, UCase(k), x)
    else
        m.kindBg.visible = false
        m.kindLabel.visible = false
    end if
    r = asStr(info.rating)
    if r <> "" then
        x = heroChip(m.imdbBg, m.imdbLabel, "IMDb " + r, x)
    else
        m.imdbBg.visible = false
        m.imdbLabel.visible = false
    end if
    parts = []
    y = asStr(info.year)
    if y <> "" then parts.push(y)
    g = asStr(info.genres)
    if g <> "" then parts.push(g)
    m.heroMeta.translation = [x, 228]
    m.heroMeta.width = 1900 - x
    m.heroMeta.text = joinWith(parts, "  •  ")
    m.heroDesc.text = asStr(info.description)

    ' Sinopse ausente (ou cortada, no caso do historico): busca o meta completo
    m.heroId = asStr(info.id)
    if asStr(info.description) = "" or asStr(info.videoId) <> "" then requestHeroMeta(info)
end sub

' ---------------------------------------------------------------------------
' Fundo do banner: troca direta ou com fade (camada B sobre a A)
' ---------------------------------------------------------------------------
sub setBackdrop(url as String, animate as Boolean)
    if url = m.curBackdrop then return
    if url = "" or not animate then
        setBackdropInstant(url)
        return
    end if
    if m.fading then
        m.queuedBackdrop = url
        return
    end if
    startFade(url)
end sub

sub setBackdropInstant(url as String)
    m.fading = false
    m.queuedBackdrop = ""
    m.fadeIn.control = "stop"
    m.fadeOut.control = "stop"
    m.heroBackdrop.uri = url
    m.heroBackdropB.opacity = 0.0
    m.frontIsB = false
    m.curBackdrop = url
end sub

sub startFade(url as String)
    m.fading = true
    m.curBackdrop = url
    if m.frontIsB then
        m.fadeTarget = m.heroBackdrop
    else
        m.fadeTarget = m.heroBackdropB
    end if
    if asStr(m.fadeTarget.uri) = url then
        runFade()
    else
        m.fadeTarget.uri = url
    end if
end sub

sub runFade()
    if m.frontIsB then
        m.fadeOut.control = "start"
    else
        m.fadeIn.control = "start"
    end if
end sub

sub onBackdropLoaded(event as Object)
    if not m.fading then return
    node = event.getRoSGNode()
    if not node.isSameNode(m.fadeTarget) then return
    st = node.loadStatus
    if st = "ready" then
        runFade()
    else if st = "failed" then
        m.fading = false
        m.curBackdrop = ""
    end if
end sub

sub onFadeState(event as Object)
    if not m.fading then return
    if event.getData() <> "stopped" then return
    m.frontIsB = not m.frontIsB
    m.fading = false
    if m.queuedBackdrop <> "" then
        q = m.queuedBackdrop
        m.queuedBackdrop = ""
        setBackdrop(q, true)
    end if
end sub

' ---------------------------------------------------------------------------
' Carrossel de destaques (gira sozinho enquanto o foco esta na barra ou nos filtros)
' ---------------------------------------------------------------------------
sub onCarousel()
    if m.fading then
        m.fadeStall = m.fadeStall + 1
        if m.fadeStall >= 2 then
            m.fadeStall = 0
            setBackdropInstant(m.curBackdrop)
        end if
        return
    end if
    m.fadeStall = 0
    if m.global.optCarousel <> true then return
    if m.focusArea = "rows" or m.panelOpen then return
    if m.featured.count() < 2 then return
    m.fIdx = (m.fIdx + 1) mod m.featured.count()
    setHero(m.featured[m.fIdx], true)
    updateDots()
end sub

sub rebuildDots()
    while m.dots.getChildCount() > 0
        m.dots.removeChildIndex(0)
    end while
    for i = 0 to m.featured.count() - 1
        r = CreateObject("roSGNode", "Rectangle")
        r.height = 6
        m.dots.appendChild(r)
    end for
    updateDots()
end sub

sub updateDots()
    x = 0
    for i = 0 to m.dots.getChildCount() - 1
        r = m.dots.getChild(i)
        w = 12
        r.color = "0x6A6A75FF"
        if i = m.fIdx then
            w = 34
            r.color = "0xFFFFFFFF"
        end if
        r.width = w
        r.translation = [x, 0]
        x = x + w + 8
    end for
end sub

sub requestHeroMeta(info as Object)
    id = asStr(info.id)
    if id = "" then return
    cached = m.metaCache[id]
    if cached <> invalid then
        applyHeroMeta(cached)
        return
    end if
    if m.metaPending[id] <> invalid then return
    base = findMetaBase(m.global.addons, asStr(info.kind), id, asStr(info.addon))
    if base = "" then return
    m.metaPending[id] = true
    startJson(base + "/meta/" + urlEncode(asStr(info.kind)) + "/" + urlEncode(id) + ".json", "onHeroMeta", { id: id })
end sub

sub onHeroMeta(event as Object)
    task = event.getRoSGNode()
    ctx = task.context
    res = event.getData()
    releaseTask(task)
    m.metaPending.delete(ctx.id)

    entry = { description: "", background: "" }
    if res.ok = true and Type(res.data) = "roAssociativeArray" then
        meta = res.data.meta
        if Type(meta) = "roAssociativeArray" then
            entry.description = asStr(meta.description)
            entry.background = asStr(meta.background)
        end if
    end if
    m.metaCache[ctx.id] = entry
    if ctx.id = m.heroId then applyHeroMeta(entry)
end sub

sub applyHeroMeta(entry as Object)
    d = asStr(entry.description)
    if d = "" then d = i18n("no_synopsis")
    m.heroDesc.text = d
    if m.heroBgNeeded and asStr(entry.background) <> "" then
        m.heroBgNeeded = false
        setBackdrop(asStr(entry.background), true)
    end if
end sub

sub clearHero()
    m.heroId = ""
    m.kindBg.visible = false
    m.kindLabel.visible = false
    m.imdbBg.visible = false
    m.imdbLabel.visible = false
    setBackdropInstant("")
    m.heroTitle.text = ""
    m.heroMeta.text = ""
    m.heroDesc.text = ""
end sub

sub onHeroTimer()
    if m.pendingHero <> invalid then setHero(m.pendingHero, false)
end sub
