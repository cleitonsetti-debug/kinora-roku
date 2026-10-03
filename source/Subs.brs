' =============================================================================
' Legendas vindas de addons com o recurso "subtitles" (ex.: addons de legendas)
' Estado esperado em m: subsGen (integer), subsPending, subsList (array)
' O componente que incluir este arquivo precisa definir: sub onSubsReady()
' =============================================================================

sub subsBegin(kind as String, videoId as String)
    m.subsGen = m.subsGen + 1
    m.subsList = []
    sources = []
    for each a in m.global.addons
        if addonSupportsResource(a, "subtitles", kind, videoId) then sources.push(a)
    end for

    m.subsPending = sources.count()
    if m.subsPending = 0 then
        onSubsReady()
        return
    end if

    for each a in sources
        url = a.url + "/subtitles/" + urlEncode(kind) + "/" + urlEncode(videoId) + ".json"
        startJsonT(url, "onSubsResult", { gen: m.subsGen, addon: a.name }, 6000)
    end for
end sub

sub onSubsResult(event as Object)
    task = event.getRoSGNode()
    ctx = task.context
    res = event.getData()
    releaseTask(task)
    if ctx.gen <> m.subsGen then return

    if res.ok = true and Type(res.data) = "roAssociativeArray" then
        list = res.data.subtitles
        if Type(list) = "roArray" then
            for each sb in list
                if Type(sb) = "roAssociativeArray" then
                    su = asStr(sb.url)
                    if su <> "" and m.subsList.count() < 60 then m.subsList.push({ url: su, lang: asStr(sb.lang), label: ctx.addon })
                end if
            end for
        end if
    end if

    m.subsPending = m.subsPending - 1
    if m.subsPending <= 0 then onSubsReady()
end sub
