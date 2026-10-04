' =============================================================================
' Ajustes do usuario (por perfil): idioma, reproducao, legenda/audio, aparencia,
' conteudo adulto. O PIN e compartilhado entre os perfis.
' Requer Storage.brs (regRead/regWrite)
' =============================================================================

function defaultSettings() as Object
    return { lang: "pt", resume: true, autoPick: false, subLang: "off", audioLang: "auto", autoNext: true, intro: true, quality: "auto", hideAdult: true, jump: 10, zoom: false, ambient: true, carousel: true, pin: "" }
end function

function loadSettings() as Object
    s = defaultSettings()
    d = regRead("settings")
    legacyPin = ""
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
        q = asStr(d.quality)
        if q = "auto" or q = "1080" or q = "720" or q = "480" then s.quality = q
        if d.hideAdult <> invalid then s.hideAdult = (d.hideAdult = true)
        j = toInt(d.jump)
        if j = 10 or j = 15 or j = 30 then s.jump = j
        if d.zoomV2 <> invalid then s.zoom = (d.zoomV2 = true)
        if d.ambient <> invalid then s.ambient = (d.ambient = true)
        if d.carousel <> invalid then s.carousel = (d.carousel = true)
        legacyPin = asStr(d.pin)
    end if
    pd = regRead("pin")
    if Type(pd) = "roAssociativeArray" then
        s.pin = asStr(pd.h)
    else
        s.pin = legacyPin
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
        quality: m.global.optQuality
        hideAdult: (m.global.optHideAdult = true)
        jump: m.global.optJump
        zoomV2: (m.global.optZoom = true)
        ambient: (m.global.optAmbient = true)
        carousel: (m.global.optCarousel = true)
    })
    regWrite("pin", { h: m.global.pinHash })
end sub

' Copia os ajustes lidos para os campos globais usados pelas telas
sub applySettings(st as Object)
    m.global.lang = st.lang
    m.global.optResume = st.resume
    m.global.optAutoPick = st.autoPick
    m.global.optSubLang = st.subLang
    m.global.optAudioLang = st.audioLang
    m.global.optAutoNext = st.autoNext
    m.global.optIntro = st.intro
    m.global.optQuality = st.quality
    m.global.optHideAdult = st.hideAdult
    m.global.optJump = st.jump
    m.global.optZoom = st.zoom
    m.global.optAmbient = st.ambient
    m.global.optCarousel = st.carousel
    m.global.pinHash = st.pin
    if m.global.profileKids = true then m.global.optHideAdult = true
end sub
