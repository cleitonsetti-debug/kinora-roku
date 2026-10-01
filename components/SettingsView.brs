' =============================================================================
' SettingsView: idioma da interface, retomar de onde parou, escolha automatica
' de fonte, limpar historico e restaurar addons padrao
' =============================================================================

sub init()
    m.list = m.top.findNode("list")
    m.confirmAction = ""
    m.confirmDlg = invalid
    m.list.observeField("itemSelected", "onSelected")
    renderList()
end sub

sub focusView()
    renderList()
    m.list.setFocus(true)
end sub

function yesNo(v as Dynamic) as String
    if v = true then return i18n("yes")
    return i18n("no")
end function

sub renderList()
    m.top.findNode("titleLabel").text = i18n("settings_title")
    m.top.findNode("topHint").text = i18n("settings_hint")
    lines = [
        i18n("set_language") + ":   " + i18n("lang_name")
        i18n("set_resume") + ":   " + yesNo(m.global.optResume)
        i18n("set_autopick") + ":   " + yesNo(m.global.optAutoPick)
        i18n("set_clear_history")
        i18n("set_reset_addons")
        i18n("set_about")
    ]
    content = CreateObject("roSGNode", "ContentNode")
    for each t in lines
        c = content.createChild("ContentNode")
        c.title = t
    end for
    idx = m.list.itemFocused
    m.list.content = content
    if idx > 0 and idx < lines.count() then m.list.jumpToItem = idx
end sub

sub onSelected()
    idx = m.list.itemSelected
    if idx = 0 then
        cycleLanguage()
    else if idx = 1 then
        m.global.optResume = not (m.global.optResume = true)
        persistSettings()
        renderList()
    else if idx = 2 then
        m.global.optAutoPick = not (m.global.optAutoPick = true)
        persistSettings()
        renderList()
    else if idx = 3 then
        askConfirm("history", i18n("confirm_clear_history"))
    else if idx = 4 then
        askConfirm("addons", i18n("confirm_reset_addons"))
    else if idx = 5 then
        ai = CreateObject("roAppInfo")
        showMessage(i18n("about_title"), i18n("about_body") + "  [" + ai.GetVersion() + "]")
    end if
end sub

sub cycleLanguage()
    codes = langCodes()
    cur = 0
    for i = 0 to codes.count() - 1
        if codes[i] = m.global.lang then cur = i
    end for
    m.global.lang = codes[(cur + 1) mod codes.count()]
    persistSettings()
    renderList()
end sub

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

    if m.confirmAction = "history" then
        regWrite("history", [])
        m.global.historyRev = m.global.historyRev + 1
        showMessage(i18n("settings_title"), i18n("history_cleared"))
    else if m.confirmAction = "addons" then
        regWrite("addons", defaultAddonConfig())
        m.top.action = "reload"
        showMessage(i18n("settings_title"), i18n("addons_reset"))
    end if
end sub
