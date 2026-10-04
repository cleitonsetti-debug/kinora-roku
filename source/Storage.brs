' =============================================================================
' Persistencia local (registry do Roku): addons, ajustes e historico "continuar assistindo"
' =============================================================================

' Chaves compartilhadas entre todos os perfis; as demais ganham o prefixo do perfil
' (o perfil "main" usa as chaves sem prefixo, entao os dados antigos viram o perfil Principal)
function regKey(key as String) as String
    if key = "addons" or key = "profiles" or key = "pin" or key = "lastprofile" or key = "update" then return key
    pid = m.global.profileId
    if pid = invalid then return key
    if pid = "" or pid = "main" then return key
    return pid + "_" + key
end function

function regRead(key as String) as Dynamic
    k = regKey(key)
    ' secao atual primeiro; depois secoes de versoes antigas (compatibilidade)
    sections = ["kinora", "vitrine", "brightscript"]
    for each name in sections
        sec = CreateObject("roRegistrySection", name)
        if sec.Exists(k) then
            raw = sec.Read(k)
            if raw <> "" then return ParseJson(raw)
        end if
    end for
    return invalid
end function

sub regWrite(key as String, value as Object)
    txt = FormatJson(value)
    if txt = "" then return
    sec = CreateObject("roRegistrySection", "kinora")
    sec.Write(regKey(key), txt)
    sec.Flush()
end sub

' Apaga so uma chave do perfil atual (ex.: favoritos)
sub regDelete(key as String)
    sec = CreateObject("roRegistrySection", "kinora")
    sec.Delete(regKey(key))
    sec.Flush()
end sub

' ---------------------------------------------------------------------------
' Perfis ("Quem esta assistindo?")
' ---------------------------------------------------------------------------
function defaultProfiles() as Object
    return [{ id: "main", name: "Principal", color: 0, kids: false }]
end function

function loadProfiles() as Object
    d = regRead("profiles")
    if Type(d) = "roArray" then
        if d.count() > 0 then return d
    end if
    return defaultProfiles()
end function

sub saveProfiles(list as Object)
    regWrite("profiles", list)
end sub

function findProfile(id as String) as Dynamic
    for each p in loadProfiles()
        if asStr(p.id) = id then return p
    end for
    return invalid
end function

' Apaga os dados de um perfil (todas as chaves com o prefixo dele)
sub deleteProfileData(id as String)
    if id = "" or id = "main" then return
    sec = CreateObject("roRegistrySection", "kinora")
    for each k in sec.GetKeyList()
        if startsWith(k, id + "_") then sec.Delete(k)
    end for
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

' ---------------------------------------------------------------------------
' Minha lista (favoritos, entradas enxutas por causa do limite do registry)
' ---------------------------------------------------------------------------
function loadFavorites() as Object
    d = regRead("favorites")
    if Type(d) <> "roArray" then return []
    return d
end function

function isFavorite(id as String) as Boolean
    for each f in loadFavorites()
        if asStr(f.id) = id then return true
    end for
    return false
end function

' Adiciona/remove; devolve true se ficou na lista
function toggleFavorite(info as Object) as Boolean
    id = asStr(info.id)
    out = []
    found = false
    for each f in loadFavorites()
        if asStr(f.id) = id then
            found = true
        else
            out.push(f)
        end if
    end for
    if not found then
        out.unshift({ id: id, kind: asStr(info.kind), name: asStr(info.name), poster: asStr(info.poster), year: asStr(info.year), rating: asStr(info.rating), addon: asStr(info.addon) })
        while out.count() > 30
            out.pop()
        end while
    end if
    regWrite("favorites", out)
    return not found
end function

' ---------------------------------------------------------------------------
' Episodios assistidos
' ---------------------------------------------------------------------------
function loadWatched() as Object
    d = regRead("watched")
    ids = {}
    if Type(d) = "roArray" then
        for each x in d
            ids[asStr(x)] = true
        end for
    end if
    return ids
end function

sub markWatched(videoId as String)
    if videoId = "" then return
    d = regRead("watched")
    if Type(d) <> "roArray" then d = []
    for each x in d
        if asStr(x) = videoId then return
    end for
    d.push(videoId)
    while d.count() > 300
        d.shift()
    end while
    regWrite("watched", d)
end sub

' ---------------------------------------------------------------------------
' Pesquisas recentes
' ---------------------------------------------------------------------------
function loadSearches() as Object
    d = regRead("searches")
    if Type(d) <> "roArray" then return []
    return d
end function

sub addSearch(q as String)
    if Len(q) < 2 then return
    out = [q]
    for each x in loadSearches()
        if LCase(asStr(x)) <> LCase(q) and out.count() < 8 then out.push(asStr(x))
    end for
    regWrite("searches", out)
end sub

' ---------------------------------------------------------------------------
' Legenda/audio escolhidos por titulo
' ---------------------------------------------------------------------------
function loadTrackPrefs(id as String) as Object
    d = regRead("trackprefs")
    if Type(d) = "roAssociativeArray" then
        v = d[id]
        if Type(v) = "roAssociativeArray" then return v
    end if
    return {}
end function

sub saveTrackPref(id as String, key as String, value as String)
    if id = "" then return
    d = regRead("trackprefs")
    if Type(d) <> "roAssociativeArray" then d = {}
    entry = d[id]
    if Type(entry) <> "roAssociativeArray" then entry = {}
    entry[key] = value
    d[id] = entry
    if d.count() > 60 then
        for each k in d
            if k <> LCase(id) then
                d.delete(k)
                exit for
            end if
        end for
    end if
    regWrite("trackprefs", d)
end sub
