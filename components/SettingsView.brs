' =============================================================================
' SettingsView: categorias a esquerda, linhas com valor a direita. Tudo guiado por dados:
' cada linha tem uma chave (key) e um tipo (toggle, cycle ou action).
' =============================================================================

sub init()
    m.cats = m.top.findNode("cats")
    m.rows = m.top.findNode("rows")
    m.pinTimer = m.top.findNode("pinTimer")
    m.area = "cats"
    m.catDefs = []
    m.rowDefs = []
    m.confirmAction = ""
    m.confirmDlg = invalid
    m.pinDlg = invalid
    m.pinPurpose = ""
    m.pinNext = ""
    m.pendingPin = ""

    m.cats.observeField("itemFocused", "onCatFocused")
    m.cats.observeField("itemSelected", "onCatSelected")
    m.rows.observeField("itemSelected", "onRowSelected")
    m.pinTimer.observeField("fire", "onPinTimer")
    renderAll()
end sub

sub focusView()
    renderAll()
    if m.area = "rows" and m.rowDefs.count() > 0 then
        m.rows.setFocus(true)
    else
        m.area = "cats"
        m.cats.setFocus(true)
    end if
end sub

' ---------------------------------------------------------------------------
' Dados: categorias e linhas
' ---------------------------------------------------------------------------
function catList() as Object
    return [
        { id: "general", title: i18n("cat_general"), icon: "ic_sliders" }
        { id: "playback", title: i18n("cat_playback"), icon: "ic_play" }
        { id: "subs", title: i18n("cat_subs"), icon: "ic_subs" }
        { id: "safety", title: i18n("cat_safety"), icon: "ic_shield" }
        { id: "profiles", title: i18n("cat_profiles"), icon: "ic_user" }
        { id: "data", title: i18n("cat_data"), icon: "ic_data" }
        { id: "about", title: i18n("cat_about"), icon: "ic_info" }
    ]
end function

function row(key as String, kind as String) as Object
    return { key: key, kind: kind, title: i18n("st_" + key), hint: i18n("st_" + key + "_h") }
end function

function rowDefsFor(catId as String) as Object
    out = []
    if catId = "general" then
        out.push(row("lang", "cycle"))
        out.push(row("carousel", "toggle"))
        out.push(row("zoom", "toggle"))
        out.push(row("ambient", "toggle"))
    else if catId = "playback" then
        out.push(row("resume", "toggle"))
        out.push(row("autopick", "toggle"))
        out.push(row("quality", "cycle"))
        out.push(row("autonext", "toggle"))
        out.push(row("intro", "toggle"))
        out.push(row("jump", "cycle"))
    else if catId = "subs" then
        out.push(row("sublang", "cycle"))
        out.push(row("audiolang", "cycle"))
    else if catId = "safety" then
        out.push(row("hideadult", "toggle"))
        out.push(row("pin", "action"))
    else if catId = "profiles" then
        r = row("profile_switch", "action")
        r.title = i18n("st_profile_now") + ": " + asStr(m.global.profileName)
        out.push(r)
        out.push(row("profile_manage", "action"))
    else if catId = "data" then
        out.push(row("clear_history", "action"))
        out.push(row("clear_favs", "action"))
        out.push(row("clear_searches", "action"))
        out.push(row("clear_watched", "action"))
        out.push(row("reset_addons", "action"))
        out.push(row("reset_settings", "action"))
    else if catId = "about" then
        out.push(row("update", "action"))
        out.push(row("diag", "action"))
        out.push(row("shortcuts", "action"))
        out.push(row("about", "action"))
    end if
    return out
end function

function yesNo(v as Dynamic) as String
    if v = true then return i18n("yes")
    return i18n("no")
end function

function toneOf(v as Dynamic) as String
    if v = true then return "on"
    return "off"
end function

function langLabelOf(v as String, offKey as String) as String
    if v = "off" or v = "auto" then return i18n(offKey)
    return i18n("lang_opt_" + v)
end function

' Valor mostrado na "pilula": { t: texto, tone: on|off|action|locked }
function valueFor(key as String) as Object
    g = m.global
    if key = "lang" then return { t: i18n("lang_name"), tone: "action" }
    if key = "carousel" then return { t: yesNo(g.optCarousel), tone: toneOf(g.optCarousel) }
    if key = "zoom" then return { t: yesNo(g.optZoom), tone: toneOf(g.optZoom) }
    if key = "ambient" then return { t: yesNo(g.optAmbient), tone: toneOf(g.optAmbient) }
    if key = "resume" then return { t: yesNo(g.optResume), tone: toneOf(g.optResume) }
    if key = "autopick" then return { t: yesNo(g.optAutoPick), tone: toneOf(g.optAutoPick) }
    if key = "quality" then
        if g.optQuality = "auto" then return { t: i18n("opt_auto"), tone: "action" }
        return { t: g.optQuality + "p", tone: "action" }
    end if
    if key = "autonext" then return { t: yesNo(g.optAutoNext), tone: toneOf(g.optAutoNext) }
    if key = "intro" then return { t: yesNo(g.optIntro), tone: toneOf(g.optIntro) }
    if key = "jump" then return { t: Str(g.optJump).trim() + " s", tone: "action" }
    if key = "sublang" then return { t: langLabelOf(g.optSubLang, "opt_off"), tone: "action" }
    if key = "audiolang" then return { t: langLabelOf(g.optAudioLang, "opt_auto"), tone: "action" }
    if key = "hideadult" then
        if g.profileKids = true then return { t: i18n("v_locked"), tone: "locked" }
        return { t: yesNo(g.optHideAdult), tone: toneOf(g.optHideAdult) }
    end if
    if key = "pin" then return { t: yesNo(g.pinHash <> ""), tone: toneOf(g.pinHash <> "") }
    if key = "profile_switch" then return { t: i18n("v_switch"), tone: "action" }
    if key = "profile_manage" then return { t: i18n("v_open"), tone: "action" }
    if key = "clear_history" or key = "clear_favs" or key = "clear_searches" or key = "clear_watched" then return { t: i18n("v_clear"), tone: "action" }
    if key = "reset_addons" or key = "reset_settings" then return { t: i18n("v_restore"), tone: "action" }
    if key = "update" then return { t: currentRelease(), tone: "action" }
    if key = "diag" then return { t: i18n("v_open"), tone: "action" }
    if key = "shortcuts" then return { t: i18n("v_view"), tone: "action" }
    if key = "about" then
        ai = CreateObject("roAppInfo")
        return { t: ai.GetVersion(), tone: "action" }
    end if
    return { t: "", tone: "action" }
end function

' ---------------------------------------------------------------------------
' Desenho
' ---------------------------------------------------------------------------
sub renderAll()
    m.top.findNode("titleLabel").text = i18n("settings_title")
    m.top.findNode("subLabel").text = i18n("st_profile_now") + ": " + asStr(m.global.profileName)
    m.top.findNode("hintLabel").text = i18n("settings_hint")
    m.top.findNode("glow").blendColor = accentByIndex(toInt(m.global.profileColor))

    m.catDefs = catList()
    content = CreateObject("roSGNode", "ContentNode")
    for each c in m.catDefs
        n = content.createChild("ContentNode")
        n.title = c.title
        n.hdPosterUrl = "pkg:/images/" + c.icon + ".png"
    end for
    idx = m.cats.itemFocused
    m.cats.content = content
    if idx > 0 and idx < m.catDefs.count() then m.cats.jumpToItem = idx
    renderRows()
end sub

sub renderRows()
    idx = m.cats.itemFocused
    if idx < 0 or idx >= m.catDefs.count() then idx = 0
    m.rowDefs = rowDefsFor(m.catDefs[idx].id)
    content = CreateObject("roSGNode", "ContentNode")
    for each r in m.rowDefs
        v = valueFor(r.key)
        n = content.createChild("ContentNode")
        n.title = r.title
        n.description = r.hint
        n.shortDescriptionLine1 = v.t
        n.shortDescriptionLine2 = v.tone
    end for
    rowIdx = m.rows.itemFocused
    m.rows.content = content
    if rowIdx > 0 and rowIdx < m.rowDefs.count() and m.area = "rows" then m.rows.jumpToItem = rowIdx
end sub

sub onCatFocused()
    renderRows()
end sub

sub onCatSelected()
    if m.rowDefs.count() > 0 then focusRows()
end sub

sub focusRows()
    m.area = "rows"
    m.rows.jumpToItem = 0
    m.rows.setFocus(true)
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false
    if m.area = "rows" then
        if key = "left" or key = "back" then
            m.area = "cats"
            m.cats.setFocus(true)
            return true
        end if
        return false
    end if
    if key = "right" and m.rowDefs.count() > 0 then
        focusRows()
        return true
    end if
    return false
end function

' ---------------------------------------------------------------------------
' Acoes
' ---------------------------------------------------------------------------
sub onRowSelected()
    idx = m.rows.itemSelected
    if idx < 0 or idx >= m.rowDefs.count() then return
    activate(m.rowDefs[idx].key)
end sub

' Proximo valor de uma lista de opcoes (volta ao inicio no fim)
function nextOption(current as String, options as Object) as String
    for i = 0 to options.count() - 1
        if options[i] = current then return options[(i + 1) mod options.count()]
    end for
    return options[0]
end function

sub saveAndRender()
    persistSettings()
    renderAll()
end sub

sub activate(key as String)
    g = m.global
    if key = "lang" then
        codes = langCodes()
        cur = 0
        for i = 0 to codes.count() - 1
            if codes[i] = g.lang then cur = i
        end for
        g.lang = codes[(cur + 1) mod codes.count()]
        saveAndRender()
    else if key = "carousel" then
        g.optCarousel = not (g.optCarousel = true)
        saveAndRender()
    else if key = "zoom" then
        g.optZoom = not (g.optZoom = true)
        saveAndRender()
    else if key = "ambient" then
        g.optAmbient = not (g.optAmbient = true)
        saveAndRender()
    else if key = "resume" then
        g.optResume = not (g.optResume = true)
        saveAndRender()
    else if key = "autopick" then
        g.optAutoPick = not (g.optAutoPick = true)
        saveAndRender()
    else if key = "quality" then
        g.optQuality = nextOption(g.optQuality, ["auto", "1080", "720", "480"])
        saveAndRender()
    else if key = "autonext" then
        g.optAutoNext = not (g.optAutoNext = true)
        saveAndRender()
    else if key = "intro" then
        g.optIntro = not (g.optIntro = true)
        saveAndRender()
    else if key = "jump" then
        g.optJump = Int(Val(nextOption(Str(g.optJump).trim(), ["10", "15", "30"])))
        saveAndRender()
    else if key = "sublang" then
        g.optSubLang = nextOption(g.optSubLang, ["off", "pt", "en", "es"])
        saveAndRender()
    else if key = "audiolang" then
        g.optAudioLang = nextOption(g.optAudioLang, ["auto", "pt", "en", "es"])
        saveAndRender()
    else if key = "hideadult" then
        if g.profileKids = true then return
        g.optHideAdult = not (g.optHideAdult = true)
        g.addonsRev = g.addonsRev + 1
        saveAndRender()
    else if key = "pin" then
        if g.pinHash = "" then
            showPin("new", i18n("pin_new"))
        else
            showPin("disable", i18n("pin_current"))
        end if
    else if key = "profile_switch" then
        m.top.action = "profiles"
    else if key = "profile_manage" then
        m.top.action = "profiles_manage"
    else if key = "clear_history" then
        askConfirm("history", i18n("confirm_clear_history"))
    else if key = "clear_favs" then
        askConfirm("favs", i18n("confirm_clear_favs"))
    else if key = "clear_searches" then
        askConfirm("searches", i18n("confirm_clear_searches"))
    else if key = "clear_watched" then
        askConfirm("watched", i18n("confirm_clear_watched"))
    else if key = "reset_addons" then
        askConfirm("addons", i18n("confirm_reset_addons"))
    else if key = "reset_settings" then
        askConfirm("settings", i18n("confirm_reset_settings"))
    else if key = "update" then
        m.top.action = "update_check"
    else if key = "diag" then
        m.top.action = "diag"
    else if key = "shortcuts" then
        dlg = CreateObject("roSGNode", "StandardMessageDialog")
        dlg.title = i18n("st_shortcuts")
        dlg.message = splitText(i18n("shortcuts_body"), "|")
        dlg.buttons = ["OK"]
        dlg.observeField("buttonSelected", "onMessageClosed")
        m.top.getScene().dialog = dlg
    else if key = "about" then
        ai = CreateObject("roAppInfo")
        showMessage(i18n("about_title"), i18n("about_body") + "  [" + ai.GetVersion() + "]")
    end if
end sub

' ---------------------------------------------------------------------------
' Confirmacoes
' ---------------------------------------------------------------------------
sub askConfirm(action as String, text as String)
    dlg = CreateObject("roSGNode", "StandardMessageDialog")
    dlg.title = i18n("settings_title")
    dlg.message = [text]
    dlg.buttons = [i18n("btn_confirm"), i18n("btn_cancel")]
    dlg.observeField("buttonSelected", "onConfirmButton")
    m.confirmAction = action
    m.confirmDlg = dlg
    m.top.getScene().dialog = dlg
end sub

sub onConfirmButton(event as Object)
    idx = event.getData()
    m.confirmDlg.close = true
    m.confirmDlg = invalid
    if idx <> 0 then return

    act = m.confirmAction
    if act = "history" then
        regWrite("history", [])
        m.global.historyRev = m.global.historyRev + 1
        showMessage(i18n("settings_title"), i18n("history_cleared"))
    else if act = "favs" then
        regWrite("favorites", [])
        m.global.favRev = m.global.favRev + 1
        showMessage(i18n("settings_title"), i18n("done_ok"))
    else if act = "searches" then
        regWrite("searches", [])
        showMessage(i18n("settings_title"), i18n("done_ok"))
    else if act = "watched" then
        regWrite("watched", [])
        showMessage(i18n("settings_title"), i18n("done_ok"))
    else if act = "addons" then
        regWrite("addons", defaultAddonConfig())
        m.top.action = "reload"
        showMessage(i18n("settings_title"), i18n("addons_reset"))
    else if act = "settings" then
        st = defaultSettings()
        st.pin = m.global.pinHash
        applySettings(st)
        saveAndRender()
        showMessage(i18n("settings_title"), i18n("settings_reset"))
    end if
end sub

' ---------------------------------------------------------------------------
' PIN (tela nativa de PIN do Roku)
' ---------------------------------------------------------------------------
sub showPin(purpose as String, title as String)
    dlg = CreateObject("roSGNode", "StandardPinPadDialog")
    if dlg = invalid then
        showMessage(i18n("settings_title"), i18n("pin_unavailable"))
        return
    end if
    dlg.title = title
    dlg.buttons = [i18n("btn_confirm"), i18n("btn_cancel")]
    dlg.observeField("buttonSelected", "onPinButton")
    m.pinPurpose = purpose
    m.pinDlg = dlg
    m.top.getScene().dialog = dlg
end sub

sub onPinButton(event as Object)
    idx = event.getData()
    pin = asStr(m.pinDlg.pin)
    m.pinDlg.close = true
    m.pinDlg = invalid
    if idx <> 0 then return

    if m.pinPurpose = "new" then
        m.pendingPin = pin
        m.pinNext = "repeat"
        m.pinTimer.control = "start"
    else if m.pinPurpose = "repeat" then
        if pin = m.pendingPin and Len(pin) > 0 then
            m.global.pinHash = pinHash(pin)
            saveAndRender()
        else
            showMessage(i18n("settings_title"), i18n("pin_mismatch"))
        end if
        m.pendingPin = ""
    else if m.pinPurpose = "disable" then
        if pinHash(pin) = m.global.pinHash then
            m.global.pinHash = ""
            saveAndRender()
        else
            showMessage(i18n("settings_title"), i18n("pin_wrong"))
        end if
    end if
end sub

' Abre o segundo dialogo de PIN depois de o primeiro fechar de vez
sub onPinTimer()
    if m.pinNext = "repeat" then showPin("repeat", i18n("pin_repeat"))
    m.pinNext = ""
end sub
