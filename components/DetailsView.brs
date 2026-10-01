' =============================================================================
' DetailsView: ficha do titulo, episodios (series/animes) e escolha da fonte.
' Se o item vem de "Continuar assistindo" (tem videoId), abre direto a escolha
' da fonte do episodio/filme que estava sendo assistido.
' =============================================================================

sub init()
    m.backdrop = m.top.findNode("backdrop")
    m.titleLabel = m.top.findNode("titleLabel")
    m.metaLabel = m.top.findNode("metaLabel")
    m.descLabel = m.top.findNode("descLabel")
    m.infoLabel = m.top.findNode("infoLabel")
    m.watchBtn = m.top.findNode("watchBtn")
    m.seasonRow = m.top.findNode("seasonRow")
    m.episodeRow = m.top.findNode("episodeRow")
    m.panel = m.top.findNode("panel")
    m.panelTitle = m.top.findNode("panelTitle")
    m.streamList = m.top.findNode("streamList")

    m.tasks = []
    m.info = invalid
    m.mode = "loading"
    m.lastList = "seasons"
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

    btn = CreateObject("roSGNode", "ContentNode")
    b = btn.createChild("ContentNode")
    b.title = tr("details_watch")
    m.watchBtn.content = btn

    m.watchBtn.observeField("itemSelected", "onWatchPressed")
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
        m.streamList.setFocus(true)
    else if m.mode = "episodes" then
        if m.lastList = "episodes" then
            m.episodeRow.setFocus(true)
        else
            m.seasonRow.setFocus(true)
        end if
    else if m.mode = "single" then
        m.watchBtn.setFocus(true)
    end if
end sub

' ---------------------------------------------------------------------------
' Dados do titulo
' ---------------------------------------------------------------------------
sub refreshMetaLine()
    parts = []
    k = kindSingular(asStr(m.info.kind))
    if k <> "" then parts.push(k)
    if asStr(m.info.year) <> "" then parts.push(asStr(m.info.year))
    if asStr(m.info.rating) <> "" then parts.push("IMDb " + asStr(m.info.rating))
    if asStr(m.info.genres) <> "" then parts.push(asStr(m.info.genres))
    m.metaLabel.text = joinWith(parts, "  •  ")
end sub

sub onItem()
    it = m.top.item
    if it = invalid then return
    m.info = it
    m.titleLabel.text = asStr(it.name)
    m.descLabel.text = asStr(it.description)
    bg = asStr(it.background)
    if bg = "" then bg = asStr(it.poster)
    m.backdrop.uri = bg
    refreshMetaLine()

    autoVid = asStr(it.videoId)
    autoSeason = toInt(it.season)
    autoEpisode = toInt(it.episode)

    if asStr(it.kind) = "movie" then
        showSingle()
    else
        m.mode = "loading"
        m.watchBtn.visible = false
        m.infoLabel.text = tr("loading_episodes")
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
    if m.top.visible then applyFocus()
end sub

sub loadMeta()
    base = findMetaBase(m.global.addons, asStr(m.info.kind), asStr(m.info.id), asStr(m.info.addon))
    if base = "" then
        showSingle()
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

    if m.episodes.count() > 0 then
        showEpisodes()
    else
        showSingle()
    end if
end sub

sub updateFromMeta(meta as Object)
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

' Proximo episodio (ordem temporada/episodio, ignorando especiais)
function findNextEpisode(videoId as String) as Dynamic
    if m.episodes.count() = 0 then return invalid
    ordered = []
    for each ep in m.episodes
        ordered.push({ id: ep.id, season: ep.season, episode: ep.episode, ord: ep.season * 100000 + ep.episode })
    end for
    sortByNumber(ordered, "ord")
    found = -1
    for i = 0 to ordered.count() - 1
        if ordered[i].id = videoId then
            found = i
            exit for
        end if
    end for
    if found < 0 then return invalid
    for j = found + 1 to ordered.count() - 1
        if ordered[j].season > 0 then return ordered[j]
    end for
    return invalid
end function

' ---------------------------------------------------------------------------
' Temporadas e episodios
' ---------------------------------------------------------------------------
sub showEpisodes()
    m.mode = "episodes"
    m.infoLabel.visible = false
    m.watchBtn.visible = false

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
            c.title = tr("specials")
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
    m.lastList = "episodes"
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
    m.lastList = "episodes"
    startStreams(ep.id, epCode(ep.season, ep.episode), ep.season, ep.episode)
end sub

sub onWatchPressed()
    vid = m.singleVideoId
    if vid = "" then vid = asStr(m.info.id)
    startStreams(vid, "", 0, 0)
end sub

' ---------------------------------------------------------------------------
' Fontes de video (addons com o recurso "stream")
' ---------------------------------------------------------------------------
sub startStreams(videoId as String, epLabel as String, season as Integer, episode as Integer)
    m.pendingPlay = { videoId: videoId, label: epLabel, season: season, episode: episode }
    m.streamGen = m.streamGen + 1
    m.found = []
    m.streams = []
    m.unsupported = 0
    m.panelOpen = true
    m.panel.visible = true
    m.panelTitle.text = tr("panel_searching")
    m.streamList.content = CreateObject("roSGNode", "ContentNode")
    m.streamList.setFocus(true)

    kind = asStr(m.info.kind)
    sources = []
    for each a in m.global.addons
        if addonSupportsResource(a, "stream", kind, videoId) then sources.push(a)
    end for

    m.streamPending = sources.count()
    if m.streamPending = 0 then
        finishStreams()
        return
    end if

    for each a in sources
        url = a.url + "/stream/" + urlEncode(kind) + "/" + urlEncode(videoId) + ".json"
        startJson(url, "onStreamResult", { gen: m.streamGen, addon: a.name })
    end for
end sub

function streamHeaders(s as Object) as Object
    out = []
    bh = s.behaviorHints
    if Type(bh) = "roAssociativeArray" then
        ph = bh.proxyHeaders
        if Type(ph) = "roAssociativeArray" then
            rq = ph.request
            if Type(rq) = "roAssociativeArray" then
                for each k in rq
                    out.push(k + ": " + asStr(rq[k]))
                end for
            end if
        end if
    end if
    return out
end function

sub addStream(s as Object, addonName as String)
    url = asStr(s.url)
    if url <> "" and startsWith(LCase(url), "http") then
        nm = replaceAll(asStr(s.name), Chr(10), " ")
        tt = asStr(s.title)
        if tt = "" then tt = asStr(s.description)
        tt = replaceAll(tt, Chr(10), " | ")
        label = "[" + addonName + "] "
        if nm <> "" then label = label + nm + "  "
        label = label + tt
        if Len(label) > 120 then label = Left(label, 117) + "..."
        m.found.push({ url: url, title: label, headers: streamHeaders(s) })
    else
        m.unsupported = m.unsupported + 1
    end if
end sub

sub onStreamResult(event as Object)
    task = event.getRoSGNode()
    ctx = task.context
    res = event.getData()
    releaseTask(task)
    if ctx.gen <> m.streamGen then return

    if res.ok = true and Type(res.data) = "roAssociativeArray" then
        list = res.data.streams
        if Type(list) = "roArray" then
            for each s in list
                if Type(s) = "roAssociativeArray" then addStream(s, ctx.addon)
            end for
        end if
    end if

    m.streamPending = m.streamPending - 1
    if m.streamPending <= 0 then finishStreams()
end sub

sub finishStreams()
    realCount = m.found.count()
    m.streams = m.found
    ' Video de teste sempre no fim da lista, para validar o player
    m.streams.push({ url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4", title: tr("demo_title"), headers: [], demo: true })

    content = CreateObject("roSGNode", "ContentNode")
    for each s in m.streams
        c = content.createChild("ContentNode")
        c.title = s.title
    end for
    m.streamList.content = content

    if realCount > 0 then
        m.panelTitle.text = trf("panel_choose", Str(realCount).trim())
    else
        t = tr("panel_none")
        if m.unsupported > 0 then t = t + trf("panel_unsupported", Str(m.unsupported).trim())
        m.panelTitle.text = t
    end if
    m.streamList.setFocus(true)

    ' Ajuste "escolher a fonte automaticamente": toca a primeira fonte real
    if m.global.optAutoPick = true and realCount > 0 then playStreamAt(0)
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
    if key = "down" and m.seasonRow.hasFocus() then
        m.lastList = "episodes"
        m.episodeRow.setFocus(true)
        return true
    else if key = "up" and m.episodeRow.hasFocus() then
        m.lastList = "seasons"
        m.seasonRow.setFocus(true)
        return true
    end if
    return false
end function
