' =============================================================================
' MainScene: carrega os addons, gerencia a pilha de telas e a navegacao
' Telas: HomeView, SearchView, AddonsView, DetailsView, PlayerView
' =============================================================================

sub init()
    st = loadSettings()
    m.global.addFields({ addons: [], addonsRev: 0, historyRev: 0, lang: st.lang, optResume: st.resume, optAutoPick: st.autoPick, optSubLang: st.subLang, optAudioLang: st.audioLang, optAutoNext: st.autoNext, optIntro: st.intro })
    m.stack = []
    m.tasks = []
    m.started = false
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
    if m.started = false then showHome()
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
end sub

sub onMenuAction(event as Object)
    action = event.getData()
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
    else if action = "reload" then
        loadAddons()
    end if
end sub

sub onSettingsAction(event as Object)
    if event.getData() = "reload" then loadAddons()
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
