' =============================================================================
' SearchView: teclado proprio desenhado por nos (a SearchView inteira recebe as
' teclas do controle, entao nao ha "pulos" de foco) + resultados dos addons.
'   Teclado: setas movem o cursor, OK digita.
'   Atalhos: voltar-rapido = apagar, avancar-rapido = espaco, play = ver resultados.
'   Resultados: Voltar / Esquerda / Cima (na borda) / * voltam ao teclado.
' =============================================================================

sub init()
    m.keysGroup = m.top.findNode("keys")
    m.cursor = m.top.findNode("cursor")
    m.grid = m.top.findNode("grid")
    m.queryLabel = m.top.findNode("queryLabel")
    m.status = m.top.findNode("statusLabel")
    m.debounce = m.top.findNode("debounce")

    m.tasks = []
    m.gen = 0
    m.pending = 0
    m.catalogs = []
    m.results = {}
    m.hasResults = false
    m.query = ""
    m.focusArea = "kb"
    m.cols = 6
    m.rowsCount = 7
    m.curCol = 0
    m.curRow = 0

    m.top.findNode("titleLabel").text = i18n("search_title")
    m.top.findNode("hintLabel").text = i18n("search_hint_keys")
    m.status.text = i18n("search_hint_min")

    buildKeyboard()
    moveCursor()
    refreshQuery()

    m.debounce.observeField("fire", "onDebounce")
    m.grid.observeField("rowItemSelected", "onGridSelected")
end sub

sub buildKeyboard()
    m.keyDefs = []
    letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    for i = 1 to Len(letters)
        c = Mid(letters, i, 1)
        m.keyDefs.push({ label: c, kind: "char", ch: LCase(c) })
    end for
    m.keyDefs.push({ label: i18n("key_space"), kind: "space", ch: " " })
    m.keyDefs.push({ label: i18n("key_del"), kind: "del", ch: "" })
    m.keyDefs.push({ label: i18n("key_clear"), kind: "clear", ch: "" })
    m.keyDefs.push({ label: "-", kind: "char", ch: "-" })
    m.keyDefs.push({ label: "'", kind: "char", ch: "'" })
    m.keyDefs.push({ label: i18n("key_go"), kind: "go", ch: "" })

    for i = 0 to m.keyDefs.count() - 1
        col = i mod m.cols
        rw = i \ m.cols
        k = CreateObject("roSGNode", "KeyItem")
        k.width = 92
        k.height = 62
        k.translation = [col * 98, rw * 68]
        node = CreateObject("roSGNode", "ContentNode")
        node.title = m.keyDefs[i].label
        k.itemContent = node
        m.keysGroup.appendChild(k)
    end for
end sub

sub moveCursor()
    m.cursor.translation = [80 + m.curCol * 98, 240 + m.curRow * 68]
end sub

sub focusView()
    if m.focusArea = "grid" and m.hasResults then
        m.grid.setFocus(true)
    else
        m.focusArea = "kb"
        m.top.setFocus(true)
    end if
end sub

sub goResults()
    if not m.hasResults then return
    m.focusArea = "grid"
    m.grid.setFocus(true)
end sub

sub goKeyboard()
    m.focusArea = "kb"
    m.top.setFocus(true)
end sub

sub refreshQuery()
    if m.query = "" then
        m.queryLabel.text = i18n("search_placeholder")
        m.queryLabel.color = "0x7A7A86FF"
    else
        m.queryLabel.text = m.query + "|"
        m.queryLabel.color = "0xFFFFFFFF"
    end if
end sub

sub applyKey(def as Object)
    if def.kind = "go" then
        goResults()
        return
    end if
    if def.kind = "char" then
        if Len(m.query) < 60 then m.query = m.query + def.ch
    else if def.kind = "space" then
        if Len(m.query) > 0 and Right(m.query, 1) <> " " then m.query = m.query + " "
    else if def.kind = "del" then
        if Len(m.query) > 0 then m.query = Left(m.query, Len(m.query) - 1)
    else if def.kind = "clear" then
        m.query = ""
    end if
    refreshQuery()
    m.debounce.control = "stop"
    m.debounce.control = "start"
end sub

sub onDebounce()
    q = m.query.trim()
    m.gen = m.gen + 1
    if Len(q) < 2 then
        clearResults(i18n("search_hint_min"))
        return
    end if

    m.catalogs = listCatalogs(m.global.addons, "", true, 6)
    m.pending = m.catalogs.count()
    m.results = {}
    if m.pending = 0 then
        clearResults(i18n("search_none_addon"))
        return
    end if

    m.status.text = i18n("searching")
    m.status.visible = true
    enc = urlEncode(q)
    for i = 0 to m.catalogs.count() - 1
        c = m.catalogs[i]
        url = c.base + "/catalog/" + urlEncode(c.kind) + "/" + urlEncode(c.id) + "/search=" + enc + ".json"
        startJson(url, "onSearchResult", { gen: m.gen, index: i })
    end for
end sub

sub clearResults(message as String)
    m.hasResults = false
    m.grid.visible = false
    m.grid.content = CreateObject("roSGNode", "ContentNode")
    m.status.text = message
    m.status.visible = true
    if m.focusArea = "grid" then goKeyboard()
end sub

sub onSearchResult(event as Object)
    task = event.getRoSGNode()
    ctx = task.context
    res = event.getData()
    releaseTask(task)
    if ctx.gen <> m.gen then return

    if res.ok = true and Type(res.data) = "roAssociativeArray" then
        metas = res.data.metas
        if Type(metas) = "roArray" then m.results[Str(ctx.index).trim()] = metas
    end if

    m.pending = m.pending - 1
    if m.pending <= 0 then renderResults()
end sub

sub renderResults()
    root = CreateObject("roSGNode", "ContentNode")
    seen = {}
    row = invalid
    n = 0
    for i = 0 to m.catalogs.count() - 1
        metas = m.results[Str(i).trim()]
        if metas <> invalid then
            c = m.catalogs[i]
            for each meta in metas
                if Type(meta) = "roAssociativeArray" and n < 40 then
                    info = metaToInfo(meta, c.base, c.kind)
                    if info.id <> "" and info.name <> "" and not seen.doesExist(info.id) then
                        seen[info.id] = true
                        if row = invalid or (n mod 5) = 0 then row = root.createChild("ContentNode")
                        row.appendChild(infoToNode(info, info.name))
                        n = n + 1
                    end if
                end if
            end for
        end if
    end for

    if n = 0 then
        clearResults(i18n("nothing_found"))
        return
    end if

    m.grid.content = root
    m.hasResults = true
    m.grid.visible = true
    m.status.visible = false
end sub

sub onGridSelected()
    sel = m.grid.rowItemSelected
    row = m.grid.content.getChild(sel[0])
    if row = invalid then return
    item = row.getChild(sel[1])
    if item = invalid then return
    m.focusArea = "grid"
    m.top.itemSelected = item.info
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    if m.focusArea = "grid" then
        if key = "back" or key = "left" or key = "up" or key = "options" then
            goKeyboard()
            return true
        end if
        return false
    end if

    ' foco no teclado
    if key = "left" then
        if m.curCol > 0 then m.curCol = m.curCol - 1
        moveCursor()
        return true
    else if key = "right" then
        if m.curCol < m.cols - 1 then
            m.curCol = m.curCol + 1
            moveCursor()
        else
            goResults()
        end if
        return true
    else if key = "up" then
        if m.curRow > 0 then m.curRow = m.curRow - 1
        moveCursor()
        return true
    else if key = "down" then
        if m.curRow < m.rowsCount - 1 then m.curRow = m.curRow + 1
        moveCursor()
        return true
    else if key = "OK" then
        idx = m.curRow * m.cols + m.curCol
        if idx >= 0 and idx < m.keyDefs.count() then applyKey(m.keyDefs[idx])
        return true
    else if key = "rewind" then
        applyKey({ kind: "del", ch: "" })
        return true
    else if key = "fastforward" then
        applyKey({ kind: "space", ch: " " })
        return true
    else if key = "play" then
        goResults()
        return true
    end if
    return false
end function
