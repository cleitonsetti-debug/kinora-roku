' =============================================================================
' DetailsView: ficha do titulo, episodios (series/animes) e escolha da fonte.
' Se o item vem de "Continuar assistindo" (tem videoId), abre direto a escolha
' da fonte do episodio/filme que estava sendo assistido.
' =============================================================================

sub init()
    m.backdrop = m.top.findNode("backdrop")
    m.backdropUri = ""
    m.top.observeField("visible", "onVisibleChange")
    m.titleLabel = m.top.findNode("titleLabel")
    m.metaLabel = m.top.findNode("metaLabel")
    m.descLabel = m.top.findNode("descLabel")
    m.infoLabel = m.top.findNode("infoLabel")
    m.watchBtn = m.top.findNode("watchBtn")
    m.listBtn = m.top.findNode("listBtn")
    m.glow = m.top.findNode("glow")
    m.forceAuto = false
    m.preferSrc = ""
    m.castLabel = m.top.findNode("castLabel")
    m.seasonRow = m.top.findNode("seasonRow")
    m.episodeRow = m.top.findNode("episodeRow")
    m.panel = m.top.findNode("panel")
    m.panelTitle = m.top.findNode("panelTitle")
    m.streamList = m.top.findNode("streamList")

    m.tasks = []
    m.info = invalid
    m.mode = "loading"
    m.area = "buttons"
    m.btnIdx = 0
    m.realCount = 0
    m.episodes = []
    m.seasons = []
    m.seasonEps = []
    m.singleVideoId = ""
    m.found = []
    m.streams = []
    m.pendingPlay = invalid
    m.streamGen = 0
    m.streamPending = 0
    m.unsupported = 0
    m.panelOpen = false

    m.watchBtn.text = i18n("details_watch")
    m.watchBtn.icon = "ic_play"
    refreshListBtn()

    m.seasonRow.observeField("rowItemFocused", "onSeasonFocused")
    m.seasonRow.observeField("rowItemSelected", "onSeasonSelected")
    m.episodeRow.observeField("rowItemFocused", "onEpisodeFocused")
    m.episodeRow.observeField("rowItemSelected", "onEpisodeSelected")
    m.streamList.observeField("itemSelected", "onStreamSelected")
end sub

sub focusView()
    applyFocus()
end sub

sub applyFocus()
    if m.panelOpen then
        setButtonsActive(false)
        m.streamList.setFocus(true)
    else if m.mode = "episodes" then
        if m.area = "episodes" then
            setButtonsActive(false)
            m.episodeRow.setFocus(true)
        else if m.area = "seasons" then
            setButtonsActive(false)
            m.seasonRow.setFocus(true)
        else
            focusButton(1)
        end if
    else if m.mode = "single" then
        focusButton(m.btnIdx)
    end if
end sub

' Botoes "Assistir" e "Minha lista": o estado visual (ativo) e controlado aqui
sub refreshListBtn()
    fav = false
    if m.info <> invalid then fav = isFavorite(asStr(m.info.id))
    if fav then
        m.listBtn.text = i18n("details_in_list")
        m.listBtn.icon = "ic_check"
    else
        m.listBtn.text = i18n("my_list")
        m.listBtn.icon = "ic_plus"
    end if
end sub

sub setButtonsActive(a as Boolean)
    watchOn = (a and m.btnIdx = 0 and m.watchBtn.visible)
    m.watchBtn.active = watchOn
    m.listBtn.active = (a and not watchOn)
end sub

sub focusButton(idx as Integer)
    if idx = 0 and not m.watchBtn.visible then idx = 1
    m.btnIdx = idx
    m.area = "buttons"
    setButtonsActive(true)
    if idx = 0 then
        m.watchBtn.setFocus(true)
    else
        m.listBtn.setFocus(true)
    end if
end sub

sub toggleList()
    if m.info = invalid then return
    toggleFavorite(m.info)
    m.global.favRev = m.global.favRev + 1
    refreshListBtn()
end sub

' ---------------------------------------------------------------------------
' Dados do titulo
' ---------------------------------------------------------------------------
sub refreshMetaLine()
    parts = []
    k = kindSingular(asStr(m.info.kind))
    if k <> "" then parts.push(k)
    if asStr(m.info.cert) <> "" then parts.push(asStr(m.info.cert))
    if asStr(m.info.year) <> "" then parts.push(asStr(m.info.year))
    if asStr(m.info.runtime) <> "" then parts.push(asStr(m.info.runtime))
    if asStr(m.info.rating) <> "" then parts.push("IMDb " + asStr(m.info.rating))
    if asStr(m.info.genres) <> "" then parts.push(asStr(m.info.genres))
    m.metaLabel.text = joinWith(parts, "  •  ")
end sub

sub onItem()
    it = m.top.item
    if it = invalid then return
    m.info = it
    m.glow.blendColor = accentFor(asStr(it.id))
    m.glow.visible = (m.global.optAmbient = true)
    m.forceAuto = (it.autoplay = true)
    m.preferSrc = asStr(it.src)
    m.area = "buttons"
    m.btnIdx = 0
    m.castLabel.text = ""
    refreshListBtn()
    m.titleLabel.text = asStr(it.name)
    m.descLabel.text = asStr(it.description)
    bg = asStr(it.background)
    if bg = "" then bg = asStr(it.poster)
    m.backdropUri = bg
    m.backdrop.uri = bg
    refreshMetaLine()

    autoVid = asStr(it.videoId)
    autoSeason = toInt(it.season)
    autoEpisode = toInt(it.episode)

    if asStr(it.kind) = "movie" then
        showSingle()
        loadMeta()
    else
        m.mode = "loading"
        m.watchBtn.visible = false
        m.infoLabel.text = i18n("loading_episodes")
        m.infoLabel.visible = true
        loadMeta()
    end if

    ' Veio de "Continuar assistindo": ja abre a escolha da fonte do episodio
    if autoVid <> "" then
        label = ""
        if autoSeason > 0 or autoEpisode > 0 then label = epCode(autoSeason, autoEpisode)
        startStreams(autoVid, label, autoSeason, autoEpisode)
    end if
end sub

sub showSingle()
    m.mode = "single"
    m.infoLabel.visible = false
    m.seasonRow.visible = false
    m.episodeRow.visible = false
    m.watchBtn.visible = true
    m.listBtn.visible = true
    if m.area <> "buttons" then m.area = "buttons"
    if m.top.visible then applyFocus()
end sub

sub loadMeta()
    base = findMetaBase(m.global.addons, asStr(m.info.kind), asStr(m.info.id), asStr(m.info.addon))
    if base = "" then
        showSingle()
        if asStr(m.info.description) = "" then m.descLabel.text = i18n("no_synopsis")
        return
    end if
    url = base + "/meta/" + urlEncode(asStr(m.info.kind)) + "/" + urlEncode(asStr(m.info.id)) + ".json"
    startJson(url, "onMetaResult", {})
end sub

sub onMetaResult(event as Object)
    task = event.getRoSGNode()
    res = event.getData()
    releaseTask(task)

    m.episodes = []
    if res.ok = true and Type(res.data) = "roAssociativeArray" then
        meta = res.data.meta
        if Type(meta) = "roAssociativeArray" then
            updateFromMeta(meta)
            parseEpisodes(meta.videos)
        end if
    end if

    if m.episodes.count() > 0 and asStr(m.info.kind) <> "movie" then
        showEpisodes()
    else
        showSingle()
    end if

    if asStr(m.info.description) = "" then m.descLabel.text = i18n("no_synopsis")
end sub

' Classificacao indicativa, quando o addon a fornece (Cinemeta nao traz)
function metaCertification(meta as Object) as String
    for each k in ["certification", "contentRating", "ageRating", "rated", "mpaa", "classification"]
        v = asStr(meta[k])
        if v <> "" then return v
    end for
    return ""
end function

sub updateFromMeta(meta as Object)
    cert = metaCertification(meta)
    if cert <> "" then m.info.cert = cert
    rt = asStr(meta.runtime)
    if rt <> "" then m.info.runtime = rt
    castText = joinList(meta.cast, 4)
    directors = joinList(meta.director, 2)
    extra = []
    if castText <> "" then extra.push(i18n("details_cast") + ": " + castText)
    if directors <> "" then extra.push(i18n("details_director") + ": " + directors)
    m.castLabel.text = joinWith(extra, "     |     ")
    d = asStr(meta.description)
    if d <> "" then
        m.info.description = d
        m.descLabel.text = d
    end if
    ri = asStr(meta.releaseInfo)
    if ri <> "" then m.info.year = ri
    g = joinList(meta.genres, 3)
    if g <> "" then m.info.genres = g
    r = asStr(meta.imdbRating)
    if r <> "" then m.info.rating = r
    bg = asStr(meta.background)
    if bg <> "" then
        m.info.background = bg
        m.backdropUri = bg
        m.backdrop.uri = bg
    end if
    refreshMetaLine()
end sub

sub parseEpisodes(videos as Dynamic)
    m.episodes = []
    m.singleVideoId = ""
    if Type(videos) <> "roArray" then return
    for each v in videos
        if Type(v) = "roAssociativeArray" then
            vid = asStr(v.id)
            if vid <> "" then
                epn = toInt(v.episode)
                if epn = 0 then epn = toInt(v.number)
                title = asStr(v.title)
                if title = "" then title = asStr(v.name)
                ov = asStr(v.overview)
                if ov = "" then ov = asStr(v.description)
                m.episodes.push({ id: vid, season: toInt(v.season), episode: epn, title: title, thumb: asStr(v.thumbnail), overview: ov })
            end if
        end if
    end for
    ' Um unico video (ex.: filme de anime): trata como titulo simples
    if m.episodes.count() = 1 then
        m.singleVideoId = m.episodes[0].id
        m.episodes = []
    end if
end sub

' Episodios em ordem temporada/episodio, sem especiais
function orderedEpisodes() as Object
    ordered = []
    for each ep in m.episodes
        if ep.season > 0 then ordered.push({ id: ep.id, season: ep.season, episode: ep.episode, title: ep.title, ord: ep.season * 100000 + ep.episode })
    end for
    sortByNumber(ordered, "ord")
    return ordered
end function

function findNextEpisode(videoId as String) as Dynamic
    ordered = orderedEpisodes()
    found = -1
    for i = 0 to ordered.count() - 1
        if ordered[i].id = videoId then
            found = i
            exit for
        end if
    end for
    if found < 0 then return invalid
    if found + 1 < ordered.count() then return ordered[found + 1]
    return invalid
end function

' ---------------------------------------------------------------------------
' Temporadas e episodios
' ---------------------------------------------------------------------------
sub showEpisodes()
    m.mode = "episodes"
    m.infoLabel.visible = false
    m.watchBtn.visible = false
    m.listBtn.visible = true
    m.area = "seasons"

    sortByNumber(m.episodes, "episode")
    seen = {}
    m.seasons = []
    for each ep in m.episodes
        k = Str(ep.season).trim()
        if not seen.doesExist(k) then
            seen[k] = true
            m.seasons.push({ season: ep.season })
        end if
    end for
    sortByNumber(m.seasons, "season")

    root = CreateObject("roSGNode", "ContentNode")
    row = root.createChild("ContentNode")
    for each s in m.seasons
        c = row.createChild("ContentNode")
        if s.season = 0 then
            c.title = i18n("specials")
        else
            c.title = trf("season_n", Str(s.season).trim())
        end if
    end for
    m.seasonRow.content = root

    first = 0
    if m.seasons.count() > 1 and m.seasons[0].season = 0 then first = 1
    m.seasonRow.jumpToRowItem = [0, first]
    fillEpisodes(first)

    m.seasonRow.visible = true
    m.episodeRow.visible = true
    if m.top.visible then applyFocus()
end sub

sub fillEpisodes(seasonIdx as Integer)
    m.seasonEps = []
    if seasonIdx < 0 or seasonIdx >= m.seasons.count() then return
    sn = m.seasons[seasonIdx].season
    watched = loadWatched()
    prog = {}
    for each h in loadHistory()
        hv = asStr(h.videoId)
        if hv <> "" then prog[hv] = { position: toInt(h.position), duration: toInt(h.duration) }
    end for

    root = CreateObject("roSGNode", "ContentNode")
    row = root.createChild("ContentNode")
    for each ep in m.episodes
        if ep.season = sn then
            m.seasonEps.push(ep)
            label = "E" + Str(ep.episode).trim()
            if ep.title <> "" then label = label + "  " + ep.title
            c = row.createChild("ContentNode")
            c.title = label
            c.hdPosterUrl = ep.thumb
            ' barra cheia = assistido; barra parcial = em andamento
            if watched.doesExist(ep.id) then
                c.addFields({ info: { position: 1, duration: 1 } })
            else if prog.doesExist(ep.id) then
                c.addFields({ info: prog[ep.id] })
            end if
        end if
    end for
    m.episodeRow.content = root
end sub

sub onSeasonFocused()
    sel = m.seasonRow.rowItemFocused
    fillEpisodes(sel[1])
    m.descLabel.text = asStr(m.info.description)
end sub

sub onSeasonSelected()
    m.area = "episodes"
    m.episodeRow.setFocus(true)
end sub

sub onEpisodeFocused()
    sel = m.episodeRow.rowItemFocused
    idx = sel[1]
    if idx < 0 or idx >= m.seasonEps.count() then return
    ov = m.seasonEps[idx].overview
    if ov = "" then ov = asStr(m.info.description)
    m.descLabel.text = ov
end sub

sub onEpisodeSelected()
    sel = m.episodeRow.rowItemSelected
    idx = sel[1]
    if idx < 0 or idx >= m.seasonEps.count() then return
    ep = m.seasonEps[idx]
    m.area = "episodes"
    startStreams(ep.id, epCode(ep.season, ep.episode), ep.season, ep.episode)
end sub

sub onWatchPressed()
    vid = m.singleVideoId
    if vid = "" then vid = asStr(m.info.id)
    startStreams(vid, "", 0, 0)
end sub

' ---------------------------------------------------------------------------
' Fontes de video (addons com o recurso "stream") - ver source/Streams.brs
' ---------------------------------------------------------------------------
sub startStreams(videoId as String, epLabel as String, season as Integer, episode as Integer)
    m.pendingPlay = { videoId: videoId, label: epLabel, season: season, episode: episode }
    m.streams = []
    m.panelOpen = true
    m.panel.visible = true
    m.panelTitle.text = i18n("panel_searching")
    m.streamList.content = CreateObject("roSGNode", "ContentNode")
    m.streamList.setFocus(true)
    streamsBegin(asStr(m.info.kind), videoId)
end sub

' Chamado pela biblioteca quando termina a busca de fontes
sub onStreamsReady()
    realCount = m.found.count()
    m.realCount = realCount
    m.streams = m.found
    ' Video de teste sempre no fim da lista, para validar o player
    m.streams.push({ url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4", title: i18n("demo_title"), headers: [], demo: true, addonName: i18n("demo_addon"), addonUrl: "", subs: [] })

    content = CreateObject("roSGNode", "ContentNode")
    for each s in m.streams
        c = content.createChild("ContentNode")
        c.title = s.title
    end for
    m.streamList.content = content

    if realCount > 0 then
        m.panelTitle.text = trf("panel_choose", Str(realCount).trim())
    else
        t = i18n("panel_none")
        if m.unsupported > 0 then t = t + trf("panel_unsupported", Str(m.unsupported).trim())
        m.panelTitle.text = t
    end if
    m.streamList.setFocus(true)

    ' "Continuar/Assistir" do banner ou ajuste "escolher a fonte automaticamente":
    ' toca a fonte do mesmo addon de antes (se houver) ou a primeira
    if realCount > 0 and (m.global.optAutoPick = true or m.forceAuto) then
        pick = 0
        if m.preferSrc <> "" then
            for i = 0 to realCount - 1
                if m.streams[i].addonUrl = m.preferSrc then
                    pick = i
                    exit for
                end if
            end for
        end if
        m.forceAuto = false
        playStreamAt(pick)
    end if
end sub

sub onStreamSelected()
    playStreamAt(m.streamList.itemSelected)
end sub

sub playStreamAt(idx as Integer)
    if idx < 0 or idx >= m.streams.count() then return
    s = m.streams[idx]
    title = asStr(m.info.name)
    if m.pendingPlay.label <> "" then title = title + "  " + m.pendingPlay.label

    vid = m.pendingPlay.videoId

    ' outras fontes reais da lista: o player tenta a proxima se esta falhar
    alts = []
    for i = 0 to m.realCount - 1
        alts.push(m.streams[i])
    end for
    altIdx = -1
    if idx < m.realCount then altIdx = idx

    m.top.playRequest = {
        url: s.url
        format: guessStreamFormat(s.url)
        title: title
        headers: s.headers
        videoId: vid
        info: m.info
        season: m.pendingPlay.season
        episode: m.pendingPlay.episode
        nextEp: findNextEpisode(m.pendingPlay.videoId)
        playlist: orderedEpisodes()
        source: { addonName: s.addonName, addonUrl: s.addonUrl, label: s.title }
        subs: s.subs
        alts: alts
        altIdx: altIdx
    }
end sub

sub closePanel()
    m.streamGen = m.streamGen + 1
    m.panelOpen = false
    m.panel.visible = false
    applyFocus()
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

    ' botoes Assistir / Minha lista
    if m.area = "buttons" and (m.mode = "single" or m.mode = "episodes") then
        if key = "left" then
            if m.btnIdx = 1 and m.watchBtn.visible then focusButton(0)
            return true
        else if key = "right" then
            if m.btnIdx = 0 and m.watchBtn.visible then focusButton(1)
            return true
        else if key = "OK" then
            if m.btnIdx = 0 and m.watchBtn.visible then
                onWatchPressed()
            else
                toggleList()
            end if
            return true
        else if key = "down" and m.mode = "episodes" then
            m.area = "seasons"
            setButtonsActive(false)
            m.seasonRow.setFocus(true)
            return true
        end if
        return false
    end if

    if key = "down" and m.seasonRow.hasFocus() then
        m.area = "episodes"
        m.episodeRow.setFocus(true)
        return true
    else if key = "up" and m.episodeRow.hasFocus() then
        m.area = "seasons"
        m.seasonRow.setFocus(true)
        return true
    else if key = "up" and m.seasonRow.hasFocus() then
        focusButton(1)
        return true
    end if
    return false
end function

' Escondida (ex.: durante o video): solta a imagem de fundo para liberar memoria de video
sub onVisibleChange()
    if m.top.visible then
        m.backdrop.uri = m.backdropUri
    else
        m.backdrop.uri = ""
    end if
end sub
