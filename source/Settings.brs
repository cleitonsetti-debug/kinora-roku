' =============================================================================
' Ajustes do usuario: idioma da interface, retomar, escolha automatica de fonte,
' idioma preferido de legenda e de audio, proximo episodio automatico
' Requer Storage.brs (regRead/regWrite)
' =============================================================================

function loadSettings() as Object
    s = { lang: "pt", resume: true, autoPick: false, subLang: "off", audioLang: "auto", autoNext: true, intro: true }
    d = regRead("settings")
    if Type(d) = "roAssociativeArray" then
        lang = asStr(d.lang)
        if lang = "pt" or lang = "en" or lang = "es" then s.lang = lang
        if d.resume <> invalid then s.resume = (d.resume = true)
        if d.autoPick <> invalid then s.autoPick = (d.autoPick = true)
        sl = asStr(d.subLang)
        if sl = "off" or sl = "pt" or sl = "en" or sl = "es" then s.subLang = sl
        al = asStr(d.audioLang)
        if al = "auto" or al = "pt" or al = "en" or al = "es" then s.audioLang = al
        if d.autoNext <> invalid then s.autoNext = (d.autoNext = true)
        if d.intro <> invalid then s.intro = (d.intro = true)
    end if
    return s
end function

sub persistSettings()
    regWrite("settings", {
        lang: m.global.lang
        resume: (m.global.optResume = true)
        autoPick: (m.global.optAutoPick = true)
        subLang: m.global.optSubLang
        audioLang: m.global.optAudioLang
        autoNext: (m.global.optAutoNext = true)
        intro: (m.global.optIntro = true)
    })
end sub
