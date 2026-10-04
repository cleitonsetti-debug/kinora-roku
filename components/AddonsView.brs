' =============================================================================
' AddonsView: cartoes com icone, painel de detalhes e botoes (ativar/desativar,
' atualizar, configurar, remover). Itens fixos no topo: adicionar e atualizar todos.
' =============================================================================

sub init()
    m.list = m.top.findNode("list")
    m.actions = m.top.findNode("actions")
    m.hint = m.top.findNode("hintLabel")
    m.tasks = []
    m.dlg = invalid
    m.area = "list"
    m.addonIdx = -1
    m.pendingRemove = -1
    m.bulkTotal = 0
    m.bulkDone = 0
    m.bulkChanged = 0

    m.top.findNode("titleLabel").text = i18n("addons_title")
    m.list.observeField("itemSelected", "onListSelected")
    m.list.observeField("itemFocused", "onItemFocused")
    m.actions.observeField("itemSelected", "onActionSelected")
    renderList()
end sub

sub focusView()
    renderList()
    if m.area = "actions" and m.addonIdx >= 0 then
        m.actions.setFocus(true)
    else
        m.area = "list"
        m.list.setFocus(true)
    end if
end sub

' ---------------------------------------------------------------------------
' Lista
' ---------------------------------------------------------------------------
sub renderList()
    addons = m.global.addons
    m.top.findNode("countLabel").text = trf("ad_count", Str(addons.count()).trim())
    content = CreateObject("roSGNode", "ContentNode")

    c = content.createChild("ContentNode")
    c.title = i18n("ad_add_short")
    c.shortDescriptionLine1 = i18n("ad_add_hint")
    c.shortDescriptionLine2 = "special"
    c.hdPosterUrl = "pkg:/images/ic_plus.png"

    c = content.createChild("ContentNode")
    c.title = i18n("ad_update_all")
    c.shortDescriptionLine1 = i18n("ad_update_all_hint")
    c.shortDescriptionLine2 = "special"
    c.hdPosterUrl = "pkg:/images/ic_refresh.png"

    for each a in addons
        c = content.createChild("ContentNode")
        c.title = a.name
        c.description = accentFor(a.url)
        state = "on"
        label = i18n("ad_state_on")
        if a.ok <> true then
            state = "err"
            label = i18n("ad_state_err")
        else if a.enabled <> true then
            state = "off"
            label = i18n("ad_state_off")
        end if
        c.shortDescriptionLine2 = state
        subtitle = label
        if a.ok = true then
            v = asStr(a.manifest.version)
            if v <> "" then subtitle = "v" + v + "   •   " + label
            c.hdPosterUrl = asStr(a.manifest.logo)
        end if
        c.shortDescriptionLine1 = subtitle
    end for

    idx = m.list.itemFocused
    m.list.content = content
    if idx > 0 and idx < content.getChildCount() then m.list.jumpToItem = idx
    renderDetail()
end sub

sub onItemFocused()
    renderDetail()
end sub

' Painel da direita: addon em foco
sub renderDetail()
    idx = m.list.itemFocused - 2
    addons = m.global.addons
    detInitial = m.top.findNode("detInitial")
    if idx < 0 or idx >= addons.count() then
        m.addonIdx = -1
        m.actions.visible = false
        m.top.findNode("detName").text = ""
        m.top.findNode("detState").text = ""
        m.top.findNode("detText").text = i18n("ad_help")
        m.top.findNode("detLogo").uri = ""
        detInitial.text = ""
        m.top.findNode("detCircle").blendColor = "0x3A3A46FF"
        return
    end if

    a = addons[idx]
    m.addonIdx = idx
    col = accentFor(a.url)
    m.top.findNode("glow").blendColor = col
    m.top.findNode("detCircle").blendColor = col
    detInitial.text = initialOf(a.name)
    m.top.findNode("detName").text = a.name

    state = i18n("ad_state_on")
    if a.ok <> true then
        state = i18n("ad_state_err")
    else if a.enabled <> true then
        state = i18n("ad_state_off")
    end if
    if a.ok = true and asStr(a.manifest.version) <> "" then state = "v" + asStr(a.manifest.version) + "   •   " + state
    m.top.findNode("detState").text = state

    if a.ok = true then
        m.top.findNode("detLogo").uri = asStr(a.manifest.logo)
    else
        m.top.findNode("detLogo").uri = ""
    end if
    m.top.findNode("detText").text = addonBody(a)
    buildActions(a)
end sub

sub buildActions(a as Object)
    content = CreateObject("roSGNode", "ContentNode")
    c = content.createChild("ContentNode")
    if a.enabled = true then
        c.title = i18n("ad_act_disable")
    else
        c.title = i18n("ad_act_enable")
    end if
    c.hdPosterUrl = "pkg:/images/ic_power.png"
    c = content.createChild("ContentNode")
    c.title = i18n("ad_act_update")
    c.hdPosterUrl = "pkg:/images/ic_refresh.png"
    c = content.createChild("ContentNode")
    c.title = i18n("ad_act_config")
    c.hdPosterUrl = "pkg:/images/ic_gear.png"
    c = content.createChild("ContentNode")
    c.title = i18n("ad_act_remove")
    c.hdPosterUrl = "pkg:/images/ic_trash.png"
    idx = m.actions.itemFocused
    m.actions.content = content
    if idx > 0 and idx < 4 then m.actions.jumpToItem = idx
    m.actions.visible = true
end sub

sub onListSelected()
    idx = m.list.itemSelected
    if idx = 0 then
        showAddDialog()
    else if idx = 1 then
        updateAll()
    else if m.addonIdx >= 0 then
        m.area = "actions"
        m.actions.setFocus(true)
    end if
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false
    if m.area = "actions" then
        if key = "left" or key = "back" or key = "up" then
            m.area = "list"
            m.list.setFocus(true)
            return true
        end if
        return false
    end if
    if key = "right" and m.addonIdx >= 0 then
        m.area = "actions"
        m.actions.setFocus(true)
        return true
    else if key = "options" and m.addonIdx >= 0 then
        askRemove(m.addonIdx)
        return true
    end if
    return false
end function

' ---------------------------------------------------------------------------
' Acoes do addon
' ---------------------------------------------------------------------------
sub commitAddons(list as Object)
    m.global.addons = list
    m.global.addonsRev = m.global.addonsRev + 1
    saveAddonConfig(list)
    renderList()
end sub

sub onActionSelected()
    idx = m.actions.itemSelected
    if m.addonIdx < 0 then return
    if idx = 0 then
        toggleAddon(m.addonIdx)
    else if idx = 1 then
        updateOne(m.addonIdx)
    else if idx = 2 then
        configureAddon(m.addonIdx)
    else if idx = 3 then
        askRemove(m.addonIdx)
    end if
end sub

sub toggleAddon(i as Integer)
    list = m.global.addons
    if i < 0 or i >= list.count() then return
    list[i].enabled = not (list[i].enabled = true)
    commitAddons(list)
end sub

sub askRemove(i as Integer)
    list = m.global.addons
    if i < 0 or i >= list.count() then return
    dlg = CreateObject("roSGNode", "StandardMessageDialog")
    dlg.title = i18n("addons_title")
    dlg.message = [trf("ad_remove_confirm", list[i].name)]
    dlg.buttons = [i18n("btn_confirm"), i18n("btn_cancel")]
    dlg.observeField("buttonSelected", "onRemoveButton")
    m.pendingRemove = i
    m.dlg = dlg
    m.top.getScene().dialog = dlg
end sub

sub onRemoveButton(event as Object)
    idx = event.getData()
    m.dlg.close = true
    m.dlg = invalid
    if idx <> 0 then return
    list = m.global.addons
    i = m.pendingRemove
    if i < 0 or i >= list.count() then return
    list.delete(i)
    m.area = "list"
    commitAddons(list)
    m.list.setFocus(true)
end sub

sub configureAddon(i as Integer)
    list = m.global.addons
    if i < 0 or i >= list.count() then return
    url = addonConfigUrl(list[i])
    if url = "" then
        showMessage(i18n("ad_cfg_title"), i18n("ad_cfg_none"))
        return
    end if
    dlg = CreateObject("roSGNode", "StandardMessageDialog")
    dlg.title = list[i].name
    dlg.message = [i18n("ad_cfg_body"), url]
    dlg.buttons = ["OK"]
    dlg.observeField("buttonSelected", "onMessageClosed")
    m.top.getScene().dialog = dlg
end sub

' ---------------------------------------------------------------------------
' Atualizar (busca o manifest de novo e compara a versao)
' ---------------------------------------------------------------------------
sub updateOne(i as Integer)
    list = m.global.addons
    if i < 0 or i >= list.count() then return
    m.hint.text = i18n("ad_checking")
    startJson(list[i].url + "/manifest.json", "onUpdateResult", { url: list[i].url, bulk: false })
end sub

sub updateAll()
    list = m.global.addons
    if list.count() = 0 then return
    m.bulkTotal = list.count()
    m.bulkDone = 0
    m.bulkChanged = 0
    m.hint.text = i18n("ad_checking")
    for each a in list
        startJson(a.url + "/manifest.json", "onUpdateResult", { url: a.url, bulk: true })
    end for
end sub

' 0 = falhou, 1 = igual, 2 = atualizado
function applyUpdate(url as String, res as Object) as Integer
    list = m.global.addons
    idx = -1
    for i = 0 to list.count() - 1
        if list[i].url = url then idx = i
    end for
    if idx < 0 then return 0
    if res.ok <> true or Type(res.data) <> "roAssociativeArray" then return 0
    if res.data.id = invalid then return 0

    oldV = ""
    if list[idx].manifest <> invalid then oldV = asStr(list[idx].manifest.version)
    newV = asStr(res.data.version)
    list[idx].manifest = res.data
    list[idx].ok = true
    nm = asStr(res.data.name)
    if nm <> "" then list[idx].name = nm
    m.global.addons = list
    m.updOld = oldV
    m.updNew = newV
    if oldV <> newV then return 2
    return 1
end function

sub onUpdateResult(event as Object)
    task = event.getRoSGNode()
    ctx = task.context
    res = event.getData()
    releaseTask(task)

    r = applyUpdate(ctx.url, res)
    if ctx.bulk = true then
        m.bulkDone = m.bulkDone + 1
        if r = 2 then m.bulkChanged = m.bulkChanged + 1
        if m.bulkDone >= m.bulkTotal then
            m.hint.text = ""
            commitAddons(m.global.addons)
            showMessage(i18n("ad_title_updated"), trf2("ad_updated_all", Str(m.bulkTotal).trim(), Str(m.bulkChanged).trim()))
        end if
        return
    end if

    m.hint.text = ""
    name = ctx.url
    for each a in m.global.addons
        if a.url = ctx.url then name = a.name
    end for
    if r = 0 then
        showMessage(i18n("ad_act_update"), trf("ad_update_failed", name))
    else if r = 2 then
        commitAddons(m.global.addons)
        showMessage(name, trf2("ad_updated", asStr(m.updOld), asStr(m.updNew)))
    else
        commitAddons(m.global.addons)
        showMessage(name, trf("ad_uptodate", name))
    end if
end sub

' ---------------------------------------------------------------------------
' Adicionar addon
' ---------------------------------------------------------------------------
sub showAddDialog()
    dlg = CreateObject("roSGNode", "StandardKeyboardDialog")
    dlg.title = i18n("addon_dlg_title")
    dlg.message = [i18n("addon_dlg_msg")]
    dlg.text = "https://"
    dlg.buttons = [i18n("btn_add"), i18n("btn_cancel")]
    dlg.observeField("buttonSelected", "onDialogButton")
    m.dlg = dlg
    m.top.getScene().dialog = dlg
end sub

sub onDialogButton(event as Object)
    idx = event.getData()
    url = m.dlg.text
    m.dlg.close = true
    m.dlg = invalid
    if idx = 0 then addAddonFromUrl(url)
end sub

sub addAddonFromUrl(raw as String)
    base = normalizeAddonUrl(raw)
    if base = "" then
        showMessage(i18n("addon_url_bad_t"), i18n("addon_url_bad_b"))
        return
    end if
    for each a in m.global.addons
        if a.url = base then
            showMessage(i18n("addon_dup_t"), base)
            return
        end if
    end for
    m.hint.text = i18n("addons_checking")
    startJson(base + "/manifest.json", "onManifestResult", { url: base })
end sub

sub onManifestResult(event as Object)
    task = event.getRoSGNode()
    ctx = task.context
    res = event.getData()
    releaseTask(task)
    m.hint.text = ""

    valid = false
    if res.ok = true and Type(res.data) = "roAssociativeArray" then
        if res.data.id <> invalid and Type(res.data.resources) = "roArray" then valid = true
    end if

    if not valid then
        showMessage(i18n("addon_bad_t"), trf("addon_bad_b", ctx.url))
        return
    end if

    nm = asStr(res.data.name)
    if nm = "" then nm = ctx.url
    list = m.global.addons
    list.push({ url: ctx.url, enabled: true, name: nm, manifest: res.data, ok: true })
    commitAddons(list)
    showMessage(i18n("addon_added_t"), nm)
end sub
