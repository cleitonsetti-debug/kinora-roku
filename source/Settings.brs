' =============================================================================
' Ajustes do usuario (idioma, retomar, escolha automatica de fonte)
' Requer Storage.brs (regRead/regWrite)
' =============================================================================

function loadSettings() as Object
    s = { lang: "pt", resume: true, autoPick: false }
    d = regRead("settings")
    if Type(d) = "roAssociativeArray" then
        lang = asStr(d.lang)
        if lang = "pt" or lang = "en" or lang = "es" then s.lang = lang
        if d.resume <> invalid then s.resume = (d.resume = true)
        if d.autoPick <> invalid then s.autoPick = (d.autoPick = true)
    end if
    return s
end function

sub persistSettings()
    regWrite("settings", { lang: m.global.lang, resume: (m.global.optResume = true), autoPick: (m.global.optAutoPick = true) })
end sub
