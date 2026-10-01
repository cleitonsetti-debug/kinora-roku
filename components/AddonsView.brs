' =============================================================================
' AddonsView: lista, ativa/desativa, remove e adiciona addons por URL
' =============================================================================

sub init()
    m.list = m.top.findNode("list")
    m.hint = m.top.findNode("hintLabel")
    m.tasks = []
    m.dlg = invalid
    m.list.observeField("itemSelected", "onListSelected")
    renderList()
end sub

sub focusView()
    renderList()
    m.list.setFocus(true)
end sub

function addonLine(a as Object) as String
    st = tr("state_on")
    if a.ok <> true then
        st = tr("state_err")
    else if a.enabled <> true then
        st = tr("state_off")
    end if
    return "[" + st + "]  " + a.name + "     " + a.url
end function

sub renderList()
    m.top.findNode("titleLabel").text = tr("addons_title")
    m.top.findNode("topHint").text = tr("addons_hint")
    addons = m.global.addons
    content = CreateObject("roSGNode", "ContentNode")
    c = content.createChild("ContentNode")
    c.title = tr("addons_add")
    for each a in addons
        c = content.createChild("ContentNode")
        c.title = addonLine(a)
    end for
    idx = m.list.itemFocused
    m.list.content = content
    if idx > 0 and idx <= addons.count() then m.list.jumpToItem = idx
end sub

sub onListSelected()
    idx = m.list.itemSelected
    if idx = 0 then
        showAddDialog()
    else
        toggleAddon(idx - 1)
    end if
end sub

sub commitAddons(list as Object)
    m.global.addons = list
    m.global.addonsRev = m.global.addonsRev + 1
    saveAddonConfig(list)
    renderList()
end sub

sub toggleAddon(i as Integer)
    list = m.global.addons
    if i < 0 or i >= list.count() then return
    list[i].enabled = not (list[i].enabled = true)
    commitAddons(list)
end sub

sub removeAddon(i as Integer)
    list = m.global.addons
    if i < 0 or i >= list.count() then return
    list.delete(i)
    commitAddons(list)
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if press and key = "options" then
        idx = m.list.itemFocused
        if idx > 0 then
            removeAddon(idx - 1)
            return true
        end if
    end if
    return false
end function

' ---------------------------------------------------------------------------
' Adicionar addon
' ---------------------------------------------------------------------------
sub showAddDialog()
    dlg = CreateObject("roSGNode", "StandardKeyboardDialog")
    dlg.title = tr("addon_dlg_title")
    dlg.message = [tr("addon_dlg_msg")]
    dlg.text = "https://"
    dlg.buttons = [tr("btn_add"), tr("btn_cancel")]
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
        showMessage(tr("addon_url_bad_t"), tr("addon_url_bad_b"))
        return
    end if
    for each a in m.global.addons
        if a.url = base then
            showMessage(tr("addon_dup_t"), base)
            return
        end if
    end for
    m.hint.text = tr("addons_checking")
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
        showMessage(tr("addon_bad_t"), trf("addon_bad_b", ctx.url))
        return
    end if

    nm = asStr(res.data.name)
    if nm = "" then nm = ctx.url
    list = m.global.addons
    list.push({ url: ctx.url, enabled: true, name: nm, manifest: res.data, ok: true })
    commitAddons(list)
    showMessage(tr("addon_added_t"), nm)
end sub
