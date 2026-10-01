' =============================================================================
' PlayerView: toca o stream escolhido e mantem o "Continuar assistindo":
'  - salva o progresso a cada 15 s e ao sair
'  - ao terminar um episodio, a serie continua na lista apontando para o PROXIMO
'    episodio; ao terminar um filme (ou o ultimo episodio), sai da lista
' =============================================================================

sub init()
    m.video = m.top.findNode("video")
    m.timer = m.top.findNode("saveTimer")
    m.req = invalid
    m.done = false
    m.video.observeField("state", "onState")
    m.timer.observeField("fire", "onTimer")
end sub

sub focusView()
    m.video.setFocus(true)
end sub

sub onRequest()
    r = m.top.request
    if r = invalid then return
    m.req = r

    content = CreateObject("roSGNode", "ContentNode")
    content.url = r.url
    content.title = r.title
    if r.format <> "" then content.streamFormat = r.format

    if m.global.optResume = true then
        posSec = getSavedPosition(r.videoId)
        if posSec > 0 then content.playStart = posSec
    end if

    if Type(r.headers) = "roArray" then
        if r.headers.count() > 0 then content.httpHeaders = r.headers
    end if

    m.video.content = content
    m.video.control = "play"
end sub

sub onState()
    st = m.video.state
    if st = "playing" then
        m.timer.control = "start"
    else if st = "finished" then
        m.timer.control = "stop"
        finishEpisode()
        closePlayer()
    else if st = "error" then
        m.timer.control = "stop"
        msg = m.video.errorMsg
        code = m.video.errorCode
        saveNow()
        closePlayer()
        showMessage(i18n("play_error_title"), trf2("play_error_body", msg, Str(code).trim()))
    end if
end sub

sub onTimer()
    saveNow()
end sub

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
    nxt = m.req.nextEp
    if Type(nxt) = "roAssociativeArray" then
        upsertHistory(buildEntry(nxt.id, nxt.season, nxt.episode, 0, 0))
    end if
    m.global.historyRev = m.global.historyRev + 1
end sub

sub saveNow()
    if m.req = invalid then return
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
    if press and key = "back" then
        m.timer.control = "stop"
        saveNow()
        closePlayer()
        return true
    end if
    return false
end function
