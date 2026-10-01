' =============================================================================
' Persistencia local (registry do Roku): addons, ajustes e historico "continuar assistindo"
' =============================================================================

function regRead(key as String) as Dynamic
    ' secao atual primeiro; depois secoes de versoes antigas (compatibilidade)
    sections = ["kinora", "vitrine", "brightscript"]
    for each name in sections
        sec = CreateObject("roRegistrySection", name)
        if sec.Exists(key) then
            raw = sec.Read(key)
            if raw <> "" then return ParseJson(raw)
        end if
    end for
    return invalid
end function

sub regWrite(key as String, value as Object)
    txt = FormatJson(value)
    if txt = "" then return
    sec = CreateObject("roRegistrySection", "kinora")
    sec.Write(key, txt)
    sec.Flush()
end sub

function loadHistory() as Object
    d = regRead("history")
    if d = invalid then return []
    if Type(d) <> "roArray" then return []
    return d
end function

sub upsertHistory(entry as Object)
    list = loadHistory()
    out = [entry]
    for each h in list
        if asStr(h.videoId) <> asStr(entry.videoId) then out.push(h)
        if out.count() >= 20 then exit for
    end for
    regWrite("history", out)
end sub

sub removeHistory(videoId as String)
    list = loadHistory()
    out = []
    for each h in list
        if asStr(h.videoId) <> videoId then out.push(h)
    end for
    regWrite("history", out)
end sub

function getSavedPosition(videoId as String) as Integer
    list = loadHistory()
    for each h in list
        if asStr(h.videoId) = videoId then return toInt(h.position)
    end for
    return 0
end function
