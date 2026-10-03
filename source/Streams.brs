' =============================================================================
' Resolucao de fontes de video nos addons (usada pela DetailsView e pela PlayerView)
' Estado esperado em m: streamGen (integer), streamPending, found (array), unsupported
' O componente que incluir este arquivo precisa definir: sub onStreamsReady()
' =============================================================================

sub streamsBegin(kind as String, videoId as String)
    m.streamGen = m.streamGen + 1
    m.found = []
    m.unsupported = 0
    sources = []
    for each a in m.global.addons
        if addonSupportsResource(a, "stream", kind, videoId) then sources.push(a)
    end for

    m.streamPending = sources.count()
    if m.streamPending = 0 then
        onStreamsReady()
        return
    end if

    for each a in sources
        url = a.url + "/stream/" + urlEncode(kind) + "/" + urlEncode(videoId) + ".json"
        startJson(url, "onStreamResult", { gen: m.streamGen, addon: a.name, addonUrl: a.url })
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

sub addStream(s as Object, addonName as String, addonUrl as String)
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

        subs = []
        if Type(s.subtitles) = "roArray" then
            for each sb in s.subtitles
                if Type(sb) = "roAssociativeArray" then
                    su = asStr(sb.url)
                    if su <> "" then subs.push({ url: su, lang: asStr(sb.lang), label: addonName })
                end if
            end for
        end if

        m.found.push({ url: url, title: label, headers: streamHeaders(s), addonName: addonName, addonUrl: addonUrl, subs: subs })
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
                if Type(s) = "roAssociativeArray" then addStream(s, ctx.addon, ctx.addonUrl)
            end for
        end if
    end if

    m.streamPending = m.streamPending - 1
    if m.streamPending <= 0 then onStreamsReady()
end sub
