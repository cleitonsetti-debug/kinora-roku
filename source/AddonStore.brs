' =============================================================================
' Addons estilo Stremio: configuracao salva + consulta de manifest/catalogos
' Um addon em memoria: { url, enabled, name, manifest, ok }
' =============================================================================

function loadAddonConfig() as Object
    d = regRead("addons")
    if d = invalid then return defaultAddonConfig()
    if Type(d) <> "roArray" then return defaultAddonConfig()
    if d.count() = 0 then return defaultAddonConfig()
    return d
end function

function defaultAddonConfig() as Object
    return [{ url: "https://v3-cinemeta.strem.io", enabled: true }]
end function

sub saveAddonConfig(addons as Object)
    out = []
    for each a in addons
        out.push({ url: a.url, enabled: (a.enabled = true) })
    end for
    regWrite("addons", out)
end sub

function countEnabled(addons as Object) as Integer
    n = 0
    for each a in addons
        if a.enabled = true then n = n + 1
    end for
    return n
end function

function anyAddonFailed(addons as Object) as Boolean
    for each a in addons
        if a.ok <> true then return true
    end for
    return false
end function

function requiredExtras(cat as Object) as Object
    names = []
    extra = cat.extra
    if Type(extra) = "roArray" then
        for each e in extra
            if Type(e) = "roAssociativeArray" then
                if e.isRequired = true then names.push(asStr(e.name))
            end if
        end for
    end if
    req = cat.extraRequired
    if Type(req) = "roArray" then
        for each r in req
            names.push(asStr(r))
        end for
    end if
    return names
end function

function catalogHasExtra(cat as Object, name as String) as Boolean
    extra = cat.extra
    if Type(extra) = "roArray" then
        for each e in extra
            if Type(e) = "roAssociativeArray" then
                if asStr(e.name) = name then return true
            end if
        end for
    end if
    sup = cat.extraSupported
    if Type(sup) = "roArray" then
        for each s in sup
            if asStr(s) = name then return true
        end for
    end if
    return false
end function

' Lista catalogos utilizaveis.
'  needSearch=false -> catalogos sem extras obrigatorios (linhas da tela inicial)
'  needSearch=true  -> catalogos que aceitam busca
function listCatalogs(addons as Object, kindFilter as String, needSearch as Boolean, maxItems as Integer) as Object
    out = []
    multi = countEnabled(addons) > 1
    for each addon in addons
        if addon.enabled = true and addon.ok = true then
            cats = addon.manifest.catalogs
            if Type(cats) = "roArray" then
                for each cat in cats
                    if Type(cat) = "roAssociativeArray" then
                        kind = asStr(cat["type"])
                        cid = asStr(cat.id)
                        usable = (kind <> "" and cid <> "")
                        if usable and kindFilter <> "" and kind <> kindFilter then usable = false
                        if usable then
                            req = requiredExtras(cat)
                            if needSearch then
                                if not catalogHasExtra(cat, "search") then usable = false
                                for each rn in req
                                    if rn <> "search" then usable = false
                                end for
                            else
                                if req.count() > 0 then usable = false
                            end if
                        end if
                        if usable and out.count() < maxItems then
                            nm = asStr(cat.name)
                            if nm = "" then nm = cid
                            title = kindLabel(kind) + " - " + nm
                            if multi then title = title + " (" + addon.name + ")"
                            out.push({ base: addon.url, kind: kind, id: cid, title: title, hasGenre: catalogHasExtra(cat, "genre") })
                        end if
                    end if
                end for
            end if
        end if
    end for
    return out
end function

function typeListHas(list as Dynamic, kind as String) as Boolean
    if Type(list) <> "roArray" then return true
    if list.count() = 0 then return true
    for each t in list
        if asStr(t) = kind then return true
    end for
    return false
end function

function prefixMatches(list as Dynamic, id as String) as Boolean
    if Type(list) <> "roArray" then return true
    if list.count() = 0 then return true
    for each p in list
        if startsWith(id, asStr(p)) then return true
    end for
    return false
end function

' O addon oferece o recurso (stream/meta/...) para esse tipo e id?
function addonSupportsResource(addon as Object, resName as String, kind as String, id as String) as Boolean
    if addon.enabled <> true then return false
    if addon.ok <> true then return false
    mf = addon.manifest
    resources = mf.resources
    if Type(resources) <> "roArray" then return false
    for each r in resources
        rname = ""
        rtypes = mf.types
        rprefixes = mf.idPrefixes
        if Type(r) = "roString" or Type(r) = "String" then
            rname = "" + r
        else if Type(r) = "roAssociativeArray" then
            rname = asStr(r.name)
            if r.types <> invalid then rtypes = r.types
            if r.idPrefixes <> invalid then rprefixes = r.idPrefixes
        end if
        if rname = resName then
            if typeListHas(rtypes, kind) and prefixMatches(rprefixes, id) then return true
        end if
    end for
    return false
end function

function findMetaBase(addons as Object, kind as String, id as String, preferred as String) as String
    for each a in addons
        if a.url = preferred then
            if addonSupportsResource(a, "meta", kind, id) then return a.url
        end if
    end for
    for each a in addons
        if addonSupportsResource(a, "meta", kind, id) then return a.url
    end for
    return ""
end function

' Opcoes do filtro "genero" declaradas no manifest do catalogo
function genreOptions(cat as Object) as Object
    out = []
    extra = cat.extra
    if Type(extra) = "roArray" then
        for each e in extra
            if Type(e) = "roAssociativeArray" then
                if asStr(e.name) = "genre" and Type(e.options) = "roArray" then
                    for each o in e.options
                        s = asStr(o)
                        if s <> "" then out.push(s)
                    end for
                end if
            end if
        end for
    end if
    return out
end function

' Catalogos de um tipo (movie/series) que podem ser usados no filtro:
' sem extras obrigatorios, exceto "genre" (ex.: o catalogo por ano do Cinemeta)
function listFilterCatalogs(addons as Object, kind as String) as Object
    out = []
    multi = countEnabled(addons) > 1
    for each addon in addons
        if addon.enabled = true and addon.ok = true then
            cats = addon.manifest.catalogs
            if Type(cats) = "roArray" then
                for each cat in cats
                    if Type(cat) = "roAssociativeArray" then
                        if asStr(cat["type"]) = kind and asStr(cat.id) <> "" then
                            usable = true
                            genreReq = false
                            for each rn in requiredExtras(cat)
                                if rn = "genre" then
                                    genreReq = true
                                else
                                    usable = false
                                end if
                            end for
                            if usable then
                                nm = asStr(cat.name)
                                if nm = "" then nm = asStr(cat.id)
                                if multi then nm = nm + " (" + addon.name + ")"
                                out.push({ base: addon.url, kind: kind, id: asStr(cat.id), name: nm, genres: genreOptions(cat), hasGenre: catalogHasExtra(cat, "genre"), genreReq: genreReq })
                            end if
                        end if
                    end if
                end for
            end if
        end if
    end for
    return out
end function
