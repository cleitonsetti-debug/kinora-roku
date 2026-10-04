' =============================================================================
' MainScene: carrega os addons, gerencia a pilha de telas e a navegacao
' Telas: HomeView, SearchView, AddonsView, DetailsView, PlayerView
' =============================================================================

sub init()
    st = loadSettings()
    m.global.addFields({ addons: [], addonsRev: 0, historyRev: 0, lang: st.lang, optResume: st.resume, optAutoPick: st.autoPick, optSubLang: st.subLang, optAudioLang: st.audioLang, optAutoNext: st.autoNext, optIntro: st.intro, optQuality: st.quality, optHideAdult: st.hideAdult, pinHash: st.pin, favRev: 0, netLog: [], optJump: st.jump, optZoom: st.zoom, optAmbient: st.ambient, optCarousel: st.carousel, profileId: "main", profileName: "", profileColor: 0, profileKids: false })
    m.stack = []
    m.tasks = []
    m.started = false
    m.updManual = false
    m.pendingAdd = ""
    m.gateAction = ""
    m.remoteBase = ""
    m.status = m.top.findNode("statusLabel")
    m.status.text = i18n("loading")
    loadAddons()
end sub

' ---------------------------------------------------------------------------
' Addons: le a configuracao salva e busca o manifest de cada um
' ---------------------------------------------------------------------------
sub loadAddons()
    cfg = loadAddonConfig()
    m.cfg = cfg
    m.mf = {}
    m.mfPending = cfg.count()
    m.status.text = i18n("loading_addons")
    if m.started = false then m.status.visible = true
    for i = 0 to cfg.count() - 1
        startJson(cfg[i].url + "/manifest.json", "onManifest", { index: i })
    end for
end sub

sub onManifest(event as Object)
    task = event.getRoSGNode()
    ctx = task.context
    res = event.getData()
    releaseTask(task)
    m.mf[Str(ctx.index).trim()] = res
    m.mfPending = m.mfPending - 1
    if m.mfPending <= 0 then finishAddons()
end sub

sub finishAddons()
    list = []
    for i = 0 to m.cfg.count() - 1
        c = m.cfg[i]
        res = m.mf[Str(i).trim()]
        entry = { url: c.url, enabled: (c.enabled = true), name: c.url, manifest: invalid, ok: false }
        if res <> invalid then
            if res.ok = true and Type(res.data) = "roAssociativeArray" then
                entry.manifest = res.data
                entry.ok = true
                nm = asStr(res.data.name)
                if nm <> "" then entry.name = nm
            end if
        end if
        list.push(entry)
    end for
    m.global.addons = list
    m.global.addonsRev = m.global.addonsRev + 1
    m.status.visible = false
    if m.started = false then startAfterAddons()
end sub

' ---------------------------------------------------------------------------
' Perfis: "Quem esta assistindo?" na abertura (se houver mais de um) e troca pelo menu
' ---------------------------------------------------------------------------
sub startAfterAddons()
    profs = loadProfiles()
    lastId = ""
    lp = regRead("lastprofile")
    if Type(lp) = "roAssociativeArray" then lastId = asStr(lp.id)
    if profs.count() > 1 then
        showProfiles("select")
    else
        activateProfile(asStr(profs[0].id), false)
        showHome()
    end if
end sub

sub showProfiles(mode as String)
    pv = CreateObject("roSGNode", "ProfileView")
    pv.mode = mode
    pv.observeField("chosen", "onProfileChosen")
    pushView(pv)
end sub

sub onProfileChosen(event as Object)
    id = event.getData()
    if id = "" then return
    ' sair de um perfil infantil para um perfil de adulto exige o PIN (se houver um)
    target = findProfile(id)
    if m.started and m.global.profileKids = true and m.global.pinHash <> "" and id <> m.global.profileId then
        if target <> invalid then
            if target.kids <> true then
                askPin("profile:" + id)
                return
            end if
        end if
    end if
    chooseProfile(id)
end sub

sub chooseProfile(id as String)
    activateProfile(id, true)
    if not m.started then
        v = m.stack.pop()
        m.top.removeChild(v)
        showHome()
    else
        popView()
    end if
end sub

sub activateProfile(id as String, bump as Boolean)
    prof = findProfile(id)
    if prof = invalid then prof = loadProfiles()[0]
    m.global.profileId = asStr(prof.id)
    m.global.profileName = asStr(prof.name)
    m.global.profileColor = toInt(prof.color)
    m.global.profileKids = (prof.kids = true)
    applySettings(loadSettings())
    regWrite("lastprofile", { id: asStr(prof.id) })
    if bump then
        m.global.historyRev = m.global.historyRev + 1
        m.global.favRev = m.global.favRev + 1
        m.global.addonsRev = m.global.addonsRev + 1
    end if
end sub

' ---------------------------------------------------------------------------
' Pilha de telas
' ---------------------------------------------------------------------------
sub pushView(view as Object)
    if m.stack.count() > 0 then
        m.stack[m.stack.count() - 1].visible = false
    end if
    m.top.appendChild(view)
    m.stack.push(view)
    view.callFunc("focusView")
end sub

sub popView()
    if m.stack.count() <= 1 then return
    v = m.stack.pop()
    m.top.removeChild(v)
    prev = m.stack[m.stack.count() - 1]
    prev.visible = true
    prev.callFunc("focusView")
end sub

sub showHome()
    m.started = true
    home = CreateObject("roSGNode", "HomeView")
    home.observeField("itemSelected", "onItemSelected")
    home.observeField("menuAction", "onMenuAction")
    pushView(home)
    checkUpdate(false)
    if m.pendingAdd <> "" then
        b = m.pendingAdd
        m.pendingAdd = ""
        confirmRemoteAdd(b)
    end if
end sub

sub onMenuAction(event as Object)
    action = event.getData()
    if action = "settings" or action = "addons" then
        if m.global.profileKids = true then
            if m.global.pinHash <> "" then
                askPin(action)
            else
                showMessage(i18n("settings_title"), i18n("kids_locked"))
            end if
        else if m.global.pinHash <> "" then
            askPin(action)
        else
            openAction(action)
        end if
    else
        openAction(action)
    end if
end sub

sub openAction(action as String)
    if action = "search" then
        s = CreateObject("roSGNode", "SearchView")
        s.observeField("itemSelected", "onItemSelected")
        pushView(s)
    else if action = "addons" then
        pushView(CreateObject("roSGNode", "AddonsView"))
    else if action = "settings" then
        st = CreateObject("roSGNode", "SettingsView")
        st.observeField("action", "onSettingsAction")
        pushView(st)
    else if action = "profiles" then
        showProfiles("select")
    else if action = "profiles_manage" then
        showProfiles("manage")
    else if action = "reload" then
        loadAddons()
    end if
end sub

' ---------------------------------------------------------------------------
' Bloqueio por PIN (Ajustes e Addons)
' ---------------------------------------------------------------------------
sub askPin(action as String)
    dlg = CreateObject("roSGNode", "StandardPinPadDialog")
    if dlg = invalid then
        openAction(action)
        return
    end if
    dlg.title = i18n("pin_current")
    dlg.buttons = [i18n("btn_confirm"), i18n("btn_cancel")]
    dlg.observeField("buttonSelected", "onGatePin")
    m.gateAction = action
    m.gateDlg = dlg
    m.top.dialog = dlg
end sub

sub onGatePin(event as Object)
    idx = event.getData()
    pin = asStr(m.gateDlg.pin)
    m.gateDlg.close = true
    m.gateDlg = invalid
    if idx <> 0 then return
    if pinHash(pin) = m.global.pinHash then
        if startsWith(m.gateAction, "profile:") then
            chooseProfile(Mid(m.gateAction, 9))
        else
            openAction(m.gateAction)
        end if
    else
        showMessage(i18n("settings_title"), i18n("pin_wrong"))
    end if
end sub

' ---------------------------------------------------------------------------
' Entrada por fora (ECP): tools/add-addon.sh ou tools/add-addon.html mandam
' "addon=<url do manifest>"; a TV pede confirmacao antes de adicionar.
' ---------------------------------------------------------------------------
sub onInputArgs()
    a = m.top.inputArgs
    if Type(a) <> "roAssociativeArray" then return
    u = asStr(a.addon)
    if u = "" then return
    base = normalizeAddonUrl(u)
    if base = "" then return
    if m.global.pinHash <> "" then
        showMessage(i18n("addons_title"), i18n("pin_locked_remote"))
        return
    end if
    if not m.started then
        m.pendingAdd = base
        return
    end if
    confirmRemoteAdd(base)
end sub

sub confirmRemoteAdd(base as String)
    dlg = CreateObject("roSGNode", "StandardMessageDialog")
    dlg.title = i18n("remote_add_title")
    dlg.message = [trf("remote_add_body", hostOf(base))]
    dlg.buttons = [i18n("btn_add"), i18n("btn_cancel")]
    dlg.observeField("buttonSelected", "onRemoteAddButton")
    m.remoteBase = base
    m.remoteDlg = dlg
    m.top.dialog = dlg
end sub

sub onRemoteAddButton(event as Object)
    idx = event.getData()
    m.remoteDlg.close = true
    m.remoteDlg = invalid
    if idx <> 0 then return
    for each a in m.global.addons
        if a.url = m.remoteBase then
            showMessage(i18n("addon_dup_t"), hostOf(m.remoteBase))
            return
        end if
    end for
    startJson(m.remoteBase + "/manifest.json", "onRemoteManifest", { url: m.remoteBase })
end sub

sub onRemoteManifest(event as Object)
    task = event.getRoSGNode()
    ctx = task.context
    res = event.getData()
    releaseTask(task)

    valid = false
    if res.ok = true and Type(res.data) = "roAssociativeArray" then
        if res.data.id <> invalid and Type(res.data.resources) = "roArray" then valid = true
    end if
    if not valid then
        showMessage(i18n("addon_bad_t"), trf("addon_bad_b", hostOf(ctx.url)))
        return
    end if

    nm = asStr(res.data.name)
    if nm = "" then nm = ctx.url
    list = m.global.addons
    list.push({ url: ctx.url, enabled: true, name: nm, manifest: res.data, ok: true })
    m.global.addons = list
    m.global.addonsRev = m.global.addonsRev + 1
    saveAddonConfig(list)
    showMessage(i18n("addon_added_t"), nm)
end sub

sub onSettingsAction(event as Object)
    act = event.getData()
    if act = "reload" then
        loadAddons()
    else if act = "diag" then
        pushView(CreateObject("roSGNode", "DiagView"))
    else if act = "update_check" then
        checkUpdate(true)
    else if act = "profiles" or act = "profiles_manage" then
        openAction(act)
    end if
end sub

sub onItemSelected(event as Object)
    info = event.getData()
    if info = invalid then return
    d = CreateObject("roSGNode", "DetailsView")
    d.item = info
    d.observeField("playRequest", "onPlayRequest")
    pushView(d)
end sub

sub onPlayRequest(event as Object)
    req = event.getData()
    if req = invalid then return
    p = CreateObject("roSGNode", "PlayerView")
    p.request = req
    p.observeField("finished", "onPlayerFinished")
    pushView(p)
end sub

sub onPlayerFinished()
    if m.stack.count() < 2 then return
    top = m.stack[m.stack.count() - 1]
    if top.subtype() = "PlayerView" then popView()
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if press and key = "back" then
        if m.stack.count() > 1 then
            popView()
            return true
        end if
    end if
    return false
end function

' ---------------------------------------------------------------------------
' Aviso de versao nova (consulta as releases do GitHub; nao instala nada sozinho)
' ---------------------------------------------------------------------------
sub checkUpdate(manual as Boolean)
    m.updManual = manual
    startJson("https://api.github.com/repos/cleitonsetti-debug/kinora-roku/releases?per_page=5", "onUpdateInfo", {})
end sub

sub onUpdateInfo(event as Object)
    task = event.getRoSGNode()
    res = event.getData()
    releaseTask(task)

    tag = ""
    if res.ok = true and Type(res.data) = "roArray" then
        for each r in res.data
            if Type(r) = "roAssociativeArray" and tag = "" then
                if r.draft <> true then tag = asStr(r.tag_name)
            end if
        end for
    end if
    if tag = "" then
        if m.updManual then showMessage(i18n("st_update"), i18n("upd_failed"))
        return
    end if

    latest = tag
    if Left(latest, 1) = "v" or Left(latest, 1) = "V" then latest = Mid(latest, 2)
    cur = currentRelease()
    if versionNewer(latest, cur) then
        seen = ""
        d = regRead("update")
        if Type(d) = "roAssociativeArray" then seen = asStr(d.seen)
        if m.updManual or seen <> latest then
            regWrite("update", { seen: latest })
            showMessage(i18n("upd_new_title"), trf2("upd_new_body", latest, cur))
        end if
    else if m.updManual then
        showMessage(i18n("st_update"), trf("upd_latest", cur))
    end if
end sub
