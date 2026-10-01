' =============================================================================
' HomeView: barra de navegacao no topo, filtros (Filmes/Series), banner (hero)
' do titulo em foco e linhas de catalogos dos addons ativos.
' Cada linha e um HomeRow (titulo proprio + RowList de uma linha); a rolagem
' vertical e feita aqui, com posicoes fixas, sem depender dos rotulos da RowList.
' =============================================================================

sub init()
    m.nav = m.top.findNode("nav")
    m.navIndicator = m.top.findNode("navIndicator")
    m.filterBar = m.top.findNode("filterBar")
    m.filterPanel = m.top.findNode("filterPanel")
    m.filterList = m.top.findNode("filterList")
    m.filterTitle = m.top.findNode("filterTitle")
    m.rowsGroup = m.top.findNode("rowsGroup")
    m.status = m.top.findNode("statusLabel")
    m.debounce = m.top.findNode("debounce")
    m.heroTimer = m.top.findNode("heroTimer")
    m.heroBackdrop = m.top.findNode("heroBackdrop")
    m.heroTitle = m.top.findNode("heroTitle")
    m.heroMeta = m.top.findNode("heroMeta")
    m.heroDesc = m.top.findNode("heroDesc")

    m.tasks = []
    m.gen = 0
    m.pending = 0
    m.total = 0
    m.catalogs = []
    m.results = {}
    m.category = "home"
    m.loadedRev = -1
    m.loadedHist = -1
    m.hasRows = false
    m.loading = false
    m.singleMode = false
    m.focusArea = "nav"
    m.panelOpen = false
    m.pickerMode = ""
    m.pickerValues = []
    m.catOptions = []
    m.rowViews = []
    m.rowHasTitle = []
    m.curRow = 0
    m.pendingHero = invalid
    m.fState = { movie: { cat: -1, genre: "" }, series: { cat: -1, genre: "" } }
    m.menuKeys = ["home", "movies", "series", "search", "addons", "settings"]
    m.uiLang = ""

    rebuildNav()

    m.nav.observeField("itemFocused", "onNavFocused")
    m.nav.observeField("itemSelected", "onNavSelected")
    m.filterBar.observeField("itemSelected", "onFilterSelected")
    m.filterList.observeField("itemSelected", "onPickerSelected")
    m.debounce.observeField("fire", "onDebounce")
    m.heroTimer.observeField("fire", "onHeroTimer")
    moveIndicator("home")
end sub

sub rebuildNav()
    m.uiLang = m.global.lang
    navContent = CreateObject("roSGNode", "ContentNode")
    labels = [i18n("nav_home"), i18n("nav_movies"), i18n("nav_series"), i18n("nav_search"), i18n("nav_addons"), i18n("nav_settings")]
    for each label in labels
        c = navContent.createChild("ContentNode")
        c.title = label
    end for
    idx = m.nav.itemFocused
    m.nav.content = navContent
    if idx > 0 then m.nav.jumpToItem = idx
end sub

sub focusView()
    stale = (m.global.addonsRev <> m.loadedRev)
    if m.category = "home" and m.global.historyRev <> m.loadedHist then stale = true
    if m.uiLang <> m.global.lang then
        rebuildNav()
        stale = true
    end if
    if stale then loadCategory(m.category)

    if m.panelOpen then
        m.filterList.setFocus(true)
    else if m.focusArea = "rows" and m.hasRows then
        focusRows()
    else if m.focusArea = "filters" and m.filterBar.visible then
        m.filterBar.setFocus(true)
    else
        m.focusArea = "nav"
        m.nav.setFocus(true)
    end if
end sub

' ---------------------------------------------------------------------------
' Navegacao superior
' ---------------------------------------------------------------------------
sub moveIndicator(cat as String)
    idx = 0
    if cat = "movies" then idx = 1
    if cat = "series" then idx = 2
    m.navIndicator.translation = [600 + idx * 178 + 35, 98]
end sub

sub onNavFocused()
    m.debounce.control = "stop"
    m.debounce.control = "start"
end sub

sub onDebounce()
    idx = m.nav.itemFocused
    if idx < 0 then return
    key = m.menuKeys[idx]
    if key = "home" or key = "movies" or key = "series" then
        if key <> m.category then loadCategory(key)
    end if
end sub

sub onNavSelected()
    idx = m.nav.itemSelected
    key = m.menuKeys[idx]
    if key = "search" or key = "addons" or key = "settings" then
        m.top.menuAction = key
        return
    end if
    if key <> m.category then
        loadCategory(key)
    else if m.hasRows then
        focusRows()
    else if not m.loading then
        if m.global.addons.count() = 0 or anyAddonFailed(m.global.addons) then
            m.top.menuAction = "reload"
        else
            loadCategory(key)
        end if
    end if
end sub

sub focusRows()
    if m.rowViews.count() = 0 then return
    m.focusArea = "rows"
    m.rowViews[m.curRow].callFunc("focusRow")
end sub

sub focusNav()
    m.focusArea = "nav"
    m.nav.setFocus(true)
end sub

sub focusFilters()
    m.focusArea = "filters"
    m.filterBar.setFocus(true)
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    if m.panelOpen then
        if key = "back" then
            closePicker()
            return true
        end if
        return false
    end if

    if key = "down" then
        if m.focusArea = "rows" then
            moveRow(1)
            return true
        else if m.nav.hasFocus() then
            if m.filterBar.visible then
                focusFilters()
                return true
            else if m.hasRows then
                focusRows()
                return true
            end if
        else if m.filterBar.hasFocus() then
            if m.hasRows then
                focusRows()
                return true
            end if
        end if
    else if key = "up" then
        if m.focusArea = "rows" then
            if m.curRow > 0 then
                moveRow(-1)
            else if m.filterBar.visible then
                focusFilters()
            else
                focusNav()
            end if
            return true
        else if m.filterBar.hasFocus() then
            focusNav()
            return true
        end if
    else if key = "back" then
        if m.focusArea = "rows" or m.filterBar.hasFocus() then
            focusNav()
            return true
        end if
    end if
    return false
end function

' ---------------------------------------------------------------------------
' Linhas (HomeRow): criacao, posicao e rolagem vertical
' ---------------------------------------------------------------------------
sub clearRows()
    for each v in m.rowViews
        m.rowsGroup.removeChild(v)
    end for
    m.rowViews = []
    m.rowHasTitle = []
    m.curRow = 0
    m.hasRows = false
end sub

sub buildRows(defs as Object)
    clearRows()
    for each d in defs
        root = CreateObject("roSGNode", "ContentNode")
        row = root.createChild("ContentNode")
        for each n in d.nodes
            row.appendChild(n)
        end for
        view = CreateObject("roSGNode", "HomeRow")
        view.rowTitle = d.title
        view.rowContent = root
        view.observeField("itemSelected", "onRowSelected")
        view.observeField("itemFocused", "onRowFocused")
        m.rowsGroup.appendChild(view)
        m.rowViews.push(view)
        m.rowHasTitle.push(d.title <> "")
    end for
    m.curRow = 0
    m.hasRows = (m.rowViews.count() > 0)
    layoutRows()
end sub

' A linha em foco fica sempre no mesmo lugar (y=548); as proximas vem abaixo,
' as anteriores ficam escondidas. Linhas com titulo tem 90 px de respiro, sem titulo 24 px.
sub layoutRows()
    y = 548
    for i = 0 to m.rowViews.count() - 1
        v = m.rowViews[i]
        if i < m.curRow then
            v.visible = false
        else
            if i > m.curRow then
                if m.rowHasTitle[i] then
                    y = y + 240 + 90
                else
                    y = y + 240 + 24
                end if
            end if
            v.translation = [70, y]
            v.visible = (y < 1080)
        end if
    end for
end sub

sub moveRow(delta as Integer)
    n = m.curRow + delta
    if n < 0 or n >= m.rowViews.count() then return
    m.curRow = n
    layoutRows()
    focusRows()
    info = m.rowViews[n].callFunc("currentInfo")
    if info <> invalid then setHero(info)
end sub

sub onRowSelected(event as Object)
    info = event.getData()
    if info <> invalid then m.top.itemSelected = info
end sub

sub onRowFocused(event as Object)
    if m.rowViews.count() = 0 then return
    node = event.getRoSGNode()
    if not node.isSameNode(m.rowViews[m.curRow]) then return
    m.pendingHero = event.getData()
    m.heroTimer.control = "stop"
    m.heroTimer.control = "start"
end sub

' ---------------------------------------------------------------------------
' Banner (hero) do item em foco
' ---------------------------------------------------------------------------
sub setHero(info as Object)
    bg = asStr(info.background)
    if bg = "" then bg = asStr(info.poster)
    m.heroBackdrop.uri = bg
    m.heroTitle.text = asStr(info.name)
    parts = []
    k = kindSingular(asStr(info.kind))
    if k <> "" then parts.push(k)
    sn = toInt(info.season)
    ep = toInt(info.episode)
    if sn > 0 or ep > 0 then parts.push(epCode(sn, ep))
    y = asStr(info.year)
    if y <> "" then parts.push(y)
    r = asStr(info.rating)
    if r <> "" then parts.push("IMDb " + r)
    g = asStr(info.genres)
    if g <> "" then parts.push(g)
    m.heroMeta.text = joinWith(parts, "  •  ")
    m.heroDesc.text = asStr(info.description)
end sub

sub clearHero()
    m.heroBackdrop.uri = ""
    m.heroTitle.text = ""
    m.heroMeta.text = ""
    m.heroDesc.text = ""
end sub

sub onHeroTimer()
    if m.pendingHero <> invalid then setHero(m.pendingHero)
end sub

' ---------------------------------------------------------------------------
' Filtros (Filmes e Series): catalogo e genero/ano
' ---------------------------------------------------------------------------
function currentKind() as String
    if m.category = "movies" then return "movie"
    if m.category = "series" then return "series"
    return ""
end function

' Generos disponiveis para o estado atual (sem a opcao "Todos")
function genreChoices(kind as String) as Object
    st = m.fState[kind]
    if st.cat >= 0 and st.cat < m.catOptions.count() then
        return m.catOptions[st.cat].genres
    end if
    out = []
    seen = {}
    for each c in m.catOptions
        if c.genreReq <> true then
            for each g in c.genres
                if not seen.doesExist(g) then
                    seen[g] = true
                    out.push(g)
                end if
            end for
        end if
    end for
    return out
end function

sub updateFilterBar(kind as String)
    if kind = "" then
        m.filterBar.visible = false
        m.catOptions = []
        return
    end if

    m.catOptions = listFilterCatalogs(m.global.addons, kind)
    st = m.fState[kind]
    if st.cat >= m.catOptions.count() then
        st.cat = -1
        st.genre = ""
    end if
    if st.cat >= 0 then
        c = m.catOptions[st.cat]
        if c.hasGenre <> true then st.genre = ""
        if c.genreReq = true and st.genre = "" and c.genres.count() > 0 then st.genre = c.genres[0]
    end if

    if m.catOptions.count() = 0 then
        m.filterBar.visible = false
        return
    end if

    catName = i18n("filter_all")
    gLabel = i18n("filter_genre")
    if st.cat >= 0 then
        catName = m.catOptions[st.cat].name
        if m.catOptions[st.cat].id = "year" then gLabel = i18n("filter_year")
    end if
    genreName = i18n("filter_all")
    if st.genre <> "" then genreName = genreLabel(st.genre)

    content = CreateObject("roSGNode", "ContentNode")
    c1 = content.createChild("ContentNode")
    c1.title = i18n("filter_catalog") + ": " + catName
    if genreChoices(kind).count() > 0 then
        c2 = content.createChild("ContentNode")
        c2.title = gLabel + ": " + genreName
    end if

    idx = m.filterBar.itemFocused
    m.filterBar.content = content
    if idx > 0 and idx < content.getChildCount() then m.filterBar.jumpToItem = idx
    m.filterBar.visible = true
end sub

sub onFilterSelected()
    kind = currentKind()
    if kind = "" then return
    if m.filterBar.itemSelected = 0 then
        openPicker("cat")
    else
        openPicker("genre")
    end if
end sub

sub openPicker(mode as String)
    kind = currentKind()
    st = m.fState[kind]
    m.pickerMode = mode
    m.pickerValues = []
    content = CreateObject("roSGNode", "ContentNode")
    current = 0

    if mode = "cat" then
        m.filterTitle.text = i18n("filter_pick_catalog")
        c = content.createChild("ContentNode")
        c.title = i18n("filter_all")
        m.pickerValues.push(-1)
        for i = 0 to m.catOptions.count() - 1
            c = content.createChild("ContentNode")
            c.title = m.catOptions[i].name
            m.pickerValues.push(i)
            if i = st.cat then current = i + 1
        end for
    else
        isYear = false
        required = false
        if st.cat >= 0 then
            isYear = (m.catOptions[st.cat].id = "year")
            required = (m.catOptions[st.cat].genreReq = true)
        end if
        if isYear then
            m.filterTitle.text = i18n("filter_pick_year")
        else
            m.filterTitle.text = i18n("filter_pick_genre")
        end if
        if not required then
            c = content.createChild("ContentNode")
            c.title = i18n("filter_all")
            m.pickerValues.push("")
        end if
        for each g in genreChoices(kind)
            c = content.createChild("ContentNode")
            c.title = genreLabel(g)
            m.pickerValues.push(g)
            if g = st.genre then current = m.pickerValues.count() - 1
        end for
    end if

    m.filterList.content = content
    m.filterList.jumpToItem = current
    m.filterPanel.visible = true
    m.panelOpen = true
    m.filterList.setFocus(true)
end sub

sub onPickerSelected()
    idx = m.filterList.itemSelected
    if idx < 0 or idx >= m.pickerValues.count() then return
    kind = currentKind()
    st = m.fState[kind]
    if m.pickerMode = "cat" then
        st.cat = m.pickerValues[idx]
        st.genre = ""
    else
        st.genre = m.pickerValues[idx]
    end if
    closePicker()
    loadCategory(m.category)
end sub

sub closePicker()
    m.panelOpen = false
    m.filterPanel.visible = false
    if m.filterBar.visible then
        focusFilters()
    else
        focusNav()
    end if
end sub

' ---------------------------------------------------------------------------
' Carregamento dos catalogos
' ---------------------------------------------------------------------------
sub loadCategory(cat as String)
    m.gen = m.gen + 1
    m.category = cat
    m.loadedRev = m.global.addonsRev
    m.loadedHist = m.global.historyRev
    m.results = {}
    m.loading = true
    m.singleMode = false
    clearRows()
    moveIndicator(cat)
    clearHero()

    kind = currentKind()
    updateFilterBar(kind)

    catalogs = []
    if kind = "" then
        catalogs = listCatalogs(m.global.addons, "", false, 10)
    else
        st = m.fState[kind]
        if st.cat >= 0 then
            c = m.catOptions[st.cat]
            m.singleMode = true
            title = c.name
            extra = ""
            if st.genre <> "" then
                title = title + " - " + genreLabel(st.genre)
                if c.hasGenre = true then extra = "genre=" + urlEncode(st.genre)
            end if
            catalogs.push({ base: c.base, kind: c.kind, id: c.id, title: title, extra: extra })
        else
            for each c in listCatalogs(m.global.addons, kind, false, 10)
                include = true
                c.extra = ""
                if st.genre <> "" then
                    if c.hasGenre = true then
                        c.extra = "genre=" + urlEncode(st.genre)
                        c.title = c.title + " - " + genreLabel(st.genre)
                    else
                        include = false
                    end if
                end if
                if include then catalogs.push(c)
            end for
        end if
    end if

    m.catalogs = catalogs
    m.total = m.catalogs.count()
    m.pending = m.total
    m.status.text = i18n("loading")
    m.status.visible = true

    if m.total = 0 then
        finishLoad()
        return
    end if

    for i = 0 to m.total - 1
        c = m.catalogs[i]
        url = c.base + "/catalog/" + urlEncode(c.kind) + "/" + urlEncode(c.id)
        ex = asStr(c.extra)
        if ex <> "" then url = url + "/" + ex
        url = url + ".json"
        startJson(url, "onCatalogResult", { gen: m.gen, index: i })
    end for
end sub

sub onCatalogResult(event as Object)
    task = event.getRoSGNode()
    ctx = task.context
    res = event.getData()
    releaseTask(task)
    if ctx.gen <> m.gen then return

    if res.ok = true and Type(res.data) = "roAssociativeArray" then
        metas = res.data.metas
        if Type(metas) = "roArray" then
            if metas.count() > 0 then m.results[Str(ctx.index).trim()] = metas
        end if
    end if

    m.pending = m.pending - 1
    if m.pending <= 0 then finishLoad()
end sub

sub finishLoad()
    m.loading = false
    defs = []
    firstInfo = invalid

    ' Linha "Continuar assistindo" (so na tela inicial)
    if m.category = "home" then
        hist = loadHistory()
        seen = {}
        nodes = []
        for each h in hist
            hid = asStr(h.id)
            if hid <> "" and not seen.doesExist(hid) then
                seen[hid] = true
                nodes.push(infoToNode(h, ""))
            end if
        end for
        if nodes.count() > 0 then
            defs.push({ title: i18n("continue_watching"), nodes: nodes })
            firstInfo = nodes[0].info
        end if
    end if

    ' Linhas dos catalogos, na ordem dos addons
    for i = 0 to m.total - 1
        metas = m.results[Str(i).trim()]
        if metas <> invalid then
            c = m.catalogs[i]
            chunk = invalid
            n = 0
            perRow = 30
            if m.singleMode then perRow = 8
            for each meta in metas
                if Type(meta) = "roAssociativeArray" then
                    info = metaToInfo(meta, c.base, c.kind)
                    if info.id <> "" and info.name <> "" then
                        if chunk = invalid or (n mod perRow) = 0 then
                            if chunk <> invalid and not m.singleMode then exit for
                            t = ""
                            if n = 0 then t = c.title
                            chunk = { title: t, nodes: [] }
                            defs.push(chunk)
                        end if
                        chunk.nodes.push(infoToNode(info, ""))
                        if firstInfo = invalid then firstInfo = info
                        n = n + 1
                        if n >= 96 then exit for
                    end if
                end if
            end for
        end if
    end for

    buildRows(defs)

    if m.hasRows then
        m.status.visible = false
        if firstInfo <> invalid then setHero(firstInfo)
    else
        m.status.text = emptyMessage()
        m.status.visible = true
        if m.focusArea = "rows" then focusNav()
    end if
end sub

function emptyMessage() as String
    addons = m.global.addons
    if addons.count() = 0 then return i18n("empty_no_addons")
    if countEnabled(addons) = 0 then return i18n("empty_all_disabled")
    if anyAddonFailed(addons) then return i18n("empty_failed")
    return i18n("empty_nocatalog")
end function
