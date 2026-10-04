' =============================================================================
' ProfileView: "Quem esta assistindo?" - escolher, criar, renomear, marcar como
' infantil e excluir perfis. Cada perfil tem historico, lista e ajustes proprios.
'   mode = "select": OK entra no perfil; * abre o menu do perfil
'   mode = "manage": OK abre o menu do perfil (vindo de Ajustes), que tambem tem "Entrar"
' O menu e do proprio app (sem encadear dialogos), com 3 modos: acoes, tipo e confirmar.
' =============================================================================

sub init()
    m.tiles = m.top.findNode("tiles")
    m.menuPanel = m.top.findNode("menuPanel")
    m.menu = m.top.findNode("menu")
    m.dlgTimer = m.top.findNode("dlgTimer")
    m.profiles = []
    m.menuIdx = -1
    m.menuMode = "actions"
    m.menuActions = []
    m.pendingName = ""
    m.dlgPurpose = ""
    m.nextStep = ""
    m.dlg = invalid

    m.top.findNode("title").text = i18n("pf_title")
    m.tiles.observeField("itemSelected", "onTileSelected")
    m.menu.observeField("itemSelected", "onMenuSelected")
    m.dlgTimer.observeField("fire", "onDlgTimer")
    render()
end sub

sub focusView()
    render()
    if m.menuPanel.visible then
        m.menu.setFocus(true)
    else
        m.tiles.setFocus(true)
    end if
end sub

sub render()
    m.profiles = loadProfiles()
    content = CreateObject("roSGNode", "ContentNode")
    for each p in m.profiles
        c = content.createChild("ContentNode")
        c.title = asStr(p.name)
        c.shortDescriptionLine1 = initialOf(asStr(p.name))
        c.shortDescriptionLine2 = accentByIndex(toInt(p.color))
        if p.kids = true then c.description = i18n("pf_kids_badge")
    end for
    n = m.profiles.count()
    if n < 6 then
        c = content.createChild("ContentNode")
        c.title = i18n("pf_new")
        c.shortDescriptionLine1 = "+"
        c.shortDescriptionLine2 = "0x3A3A46FF"
        n = n + 1
    end if
    ' grade fixa de 6 colunas; so o deslocamento muda para centralizar os cartoes
    m.tiles.translation = [(1920 - n * 280 + 20) / 2, 330]
    idx = m.tiles.itemFocused
    m.tiles.content = content
    if idx > 0 and idx < n then m.tiles.jumpToItem = idx

    if m.top.mode = "manage" then
        m.top.findNode("hint").text = i18n("pf_manage_hint")
    else
        m.top.findNode("hint").text = i18n("pf_hint")
    end if
end sub

sub onTileSelected()
    idx = m.tiles.itemSelected
    if idx < 0 then return
    if idx >= m.profiles.count() then
        startNewProfile()
    else if m.top.mode = "manage" then
        openMenu(idx)
    else
        m.top.chosen = asStr(m.profiles[idx].id)
    end if
end sub

' ---------------------------------------------------------------------------
' Painel de menu (acoes / tipo do perfil novo / confirmar exclusao)
' ---------------------------------------------------------------------------
sub fillMenu(title as String, labels as Object, actions as Object, mode as String)
    m.top.findNode("menuTitle").text = title
    content = CreateObject("roSGNode", "ContentNode")
    for each l in labels
        c = content.createChild("ContentNode")
        c.title = l
    end for
    m.menuActions = actions
    m.menuMode = mode
    m.menu.content = content
    m.menu.jumpToItem = 0
    m.menuPanel.visible = true
    m.menu.setFocus(true)
end sub

sub openMenu(idx as Integer)
    if idx < 0 or idx >= m.profiles.count() then return
    m.menuIdx = idx
    labels = [i18n("pf_enter"), i18n("pf_rename"), i18n("pf_toggle_kids"), i18n("pf_delete"), i18n("player_close")]
    fillMenu(asStr(m.profiles[idx].name), labels, ["enter", "rename", "kids", "delete", "close"], "actions")
end sub

sub closeMenu()
    m.menuPanel.visible = false
    m.tiles.setFocus(true)
end sub

sub onMenuSelected()
    idx = m.menu.itemSelected
    if idx < 0 or idx >= m.menuActions.count() then return
    act = m.menuActions[idx]

    if m.menuMode = "kind" then
        createProfile(act = "kids")
        return
    end if

    if m.menuMode = "confirm" then
        if act = "yes" then deleteSelected()
        closeMenu()
        return
    end if

    ' modo "actions"
    p = m.profiles[m.menuIdx]
    if act = "enter" then
        closeMenu()
        m.top.chosen = asStr(p.id)
    else if act = "rename" then
        closeMenu()
        showNameDialog("rename", asStr(p.name))
    else if act = "kids" then
        list = loadProfiles()
        list[m.menuIdx].kids = not (list[m.menuIdx].kids = true)
        saveProfiles(list)
        if asStr(p.id) = m.global.profileId then m.global.profileKids = (list[m.menuIdx].kids = true)
        closeMenu()
        render()
    else if act = "delete" then
        if asStr(p.id) = "main" then
            closeMenu()
            showMessage(i18n("pf_title"), i18n("pf_main_locked"))
        else
            fillMenu(i18n("pf_delete_confirm"), [i18n("btn_confirm"), i18n("btn_cancel")], ["yes", "no"], "confirm")
        end if
    else
        closeMenu()
    end if
end sub

' ---------------------------------------------------------------------------
' Novo perfil: nome (teclado) -> tipo (menu do app)
' ---------------------------------------------------------------------------
sub startNewProfile()
    if m.profiles.count() >= 6 then
        showMessage(i18n("pf_title"), i18n("pf_max"))
        return
    end if
    showNameDialog("new", i18n("pf_default_name") + " " + Str(m.profiles.count() + 1).trim())
end sub

sub showNameDialog(purpose as String, current as String)
    dlg = CreateObject("roSGNode", "StandardKeyboardDialog")
    if dlg = invalid then return
    dlg.title = i18n("pf_name_dlg")
    dlg.text = current
    dlg.buttons = [i18n("btn_confirm"), i18n("btn_cancel")]
    dlg.observeField("buttonSelected", "onNameButton")
    m.dlgPurpose = purpose
    m.dlg = dlg
    m.top.getScene().dialog = dlg
end sub

sub onNameButton(event as Object)
    idx = event.getData()
    txt = asStr(m.dlg.text).trim()
    m.dlg.close = true
    m.dlg = invalid
    if idx <> 0 or Len(txt) = 0 then return
    if Len(txt) > 12 then txt = Left(txt, 12)

    if m.dlgPurpose = "rename" then
        list = loadProfiles()
        list[m.menuIdx].name = txt
        saveProfiles(list)
        if asStr(list[m.menuIdx].id) = m.global.profileId then m.global.profileName = txt
        render()
    else
        ' espera o dialogo fechar de vez para o foco ir para o menu do app
        m.pendingName = txt
        m.nextStep = "kind"
        m.dlgTimer.control = "start"
    end if
end sub

sub onDlgTimer()
    if m.nextStep = "kind" then
        fillMenu(m.pendingName, [i18n("pf_kind_normal"), i18n("pf_kind_kids")], ["normal", "kids"], "kind")
    end if
    m.nextStep = ""
end sub

sub createProfile(kids as Boolean)
    list = loadProfiles()
    secs = CreateObject("roDateTime").AsSeconds()
    list.push({ id: "p" + Str(secs).trim(), name: m.pendingName, color: list.count(), kids: kids })
    saveProfiles(list)
    closeMenu()
    render()
end sub

sub deleteSelected()
    list = loadProfiles()
    if m.menuIdx < 0 or m.menuIdx >= list.count() then return
    gone = asStr(list[m.menuIdx].id)
    if gone = "main" then return
    out = []
    for i = 0 to list.count() - 1
        if i <> m.menuIdx then out.push(list[i])
    end for
    saveProfiles(out)
    deleteProfileData(gone)
    render()
    ' apagou o perfil em uso: volta para o principal
    if gone = m.global.profileId then m.top.chosen = "main"
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false
    if m.menuPanel.visible then
        if key = "back" then
            closeMenu()
            return true
        end if
        return false
    end if
    if key = "options" and m.tiles.hasFocus() then
        openMenu(m.tiles.itemFocused)
        return true
    end if
    return false
end function
