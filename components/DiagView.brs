' =============================================================================
' DiagView: versao, aparelho, status dos addons, ultimos erros de rede e autoteste.
' Tire uma foto desta tela ao relatar um problema.
' =============================================================================

sub init()
    m.menu = m.top.findNode("menu")
    m.report = m.top.findNode("report")
    m.testLines = []
    m.top.findNode("titleLabel").text = i18n("diag_title")
    m.top.findNode("hintLabel").text = i18n("diag_hint")

    content = CreateObject("roSGNode", "ContentNode")
    c = content.createChild("ContentNode")
    c.title = i18n("diag_run")
    c = content.createChild("ContentNode")
    c.title = i18n("diag_refresh")
    m.menu.content = content
    m.menu.observeField("itemSelected", "onSelected")
    refreshReport()
end sub

sub focusView()
    refreshReport()
    m.menu.setFocus(true)
end sub

sub onSelected()
    idx = m.menu.itemSelected
    if idx = 0 then
        r = runSelfTests()
        lines = []
        passed = r.total - r.failures.count()
        lines.push(i18n("diag_selftest") + ": " + Str(passed).trim() + "/" + Str(r.total).trim())
        for each f in r.failures
            lines.push("  X " + f)
        end for
        m.testLines = lines
    else
        m.testLines = []
    end if
    refreshReport()
end sub

function osVersion(di as Object) as String
    v = di.GetOSVersion()
    if Type(v) = "roAssociativeArray" then return asStr(v.major) + "." + asStr(v.minor) + "." + asStr(v.build)
    return asStr(v)
end function

sub refreshReport()
    ai = CreateObject("roAppInfo")
    di = CreateObject("roDeviceInfo")
    lines = []
    lines.push("Kinora " + ai.GetVersion())
    lines.push(i18n("diag_device") + ": " + asStr(di.GetModel()) + "   |   Roku OS " + osVersion(di))
    lines.push("")

    lines.push(i18n("diag_addons") + ":")
    for each a in m.global.addons
        st = i18n("state_on")
        if a.ok <> true then
            st = i18n("state_err")
        else if a.enabled <> true then
            st = i18n("state_off")
        end if
        lines.push("  [" + st + "] " + a.name + "  (" + hostOf(a.url) + ")")
    end for
    lines.push("")

    entries = m.global.netLog
    lines.push(i18n("diag_errors") + " (" + Str(entries.count()).trim() + "):")
    if entries.count() = 0 then
        lines.push("  " + i18n("diag_none"))
    else
        shown = 0
        for i = entries.count() - 1 to 0 step -1
            e = entries[i]
            lines.push("  " + e.t + "  " + e.target + "  " + e.msg)
            shown = shown + 1
            if shown >= 7 then exit for
        end for
    end if

    if m.testLines.count() > 0 then
        lines.push("")
        for each t in m.testLines
            lines.push(t)
        end for
    end if
    m.report.text = joinWith(lines, Chr(10))
end sub
