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
    m.heroBackdropB = m.top.findNode("heroBackdropB")
    m.fadeIn = m.top.findNode("fadeIn")
    m.fadeOut = m.top.findNode("fadeOut")
    m.dots = m.top.findNode("dots")
    m.heroBtn = m.top.findNode("heroBtn")
    m.carouselTimer = m.top.findNode("carouselTimer")
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
    m.heroId = ""
    m.curBackdrop = ""
    m.frontIsB = false
    m.fading = false
    m.fadeStall = 0
    m.queuedBackdrop = ""
    m.fadeTarget = invalid
    m.featured = []
    m.fIdx = 0
    m.metaCache = {}
    m.metaPending = {}
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
    m.carouselTimer.observeField("fire", "onCarousel")
    m.heroBackdrop.observeField("loadStatus", "onBackdropLoaded")
    m.heroBackdropB.observeField("loadStatus", "onBackdropLoaded")
    m.fadeIn.observeField("state", "onFadeState")
    m.fadeOut.observeField("state", "onFadeState")
    setupHeroBtn()
    moveIndicator("home")
end sub

sub setupHeroBtn()
    m.heroBtn.text = i18n("hero_details")
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
        setupHeroBtn()
        stale = true
    end if
    if stale then loadCategory(m.category)

    if m.panelOpen then
        m.filterList.setFocus(true)
    else if m.focusArea = "rows" and m.hasRows then
        focusRows()
    else if m.focusArea = "filters" and m.filterBar.visible then
        m.filterBar.setFocus(true)
    else if m.focusArea = "hero" and m.featured.count() > 0 then
        m.heroBtn.setFocus(true)
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
    refreshHeroChrome()
    m.rowViews[m.curRow].callFunc("focusRow")
    info = m.rowViews[m.curRow].callFunc("currentInfo")
    if info <> invalid then setHero(info, false)
end sub

sub focusNav()
    m.focusArea = "nav"
    m.nav.setFocus(true)
    onTopFocus()
end sub

sub focusHero()
    m.focusArea = "hero"
    refreshHeroChrome()
    m.heroBtn.setFocus(true)
    onTopFocus()
end sub

sub focusFilters()
    m.focusArea = "filters"
    m.filterBar.setFocus(true)
    onTopFocus()
end sub

' Foco voltou para a barra/filtros: retoma o carrossel de destaques
sub onTopFocus()
    refreshHeroChrome()
    if m.featured.count() > 0 then setHero(m.featured[m.fIdx], true)
end sub

sub refreshHeroChrome()
    carousel = (m.focusArea <> "rows")
    m.dots.visible = (m.featured.count() > 1 and carousel)
    m.heroBtn.visible = (m.featured.count() > 0 and carousel)
    m.heroBtn.active = (m.focusArea = "hero")
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

    hasHero = (m.featured.count() > 0)

    if key = "play" and m.focusArea <> "rows" and hasHero then
        m.top.itemSelected = m.featured[m.fIdx]
        return true
    end if
    if key = "OK" and m.focusArea = "hero" and hasHero then
        m.top.itemSelected = m.featured[m.fIdx]
        return true
    end if

    if key = "down" then
        if m.focusArea = "rows" then
            moveRow(1)
            return true
        else if m.focusArea = "hero" then
            if m.hasRows then focusRows()
            return true
        else if m.nav.hasFocus() then
            if m.filterBar.visible then
                focusFilters()
                return true
            else if hasHero then
                focusHero()
                return true
            else if m.hasRows then
                focusRows()
                return true
            end if
        else if m.filterBar.hasFocus() then
            if hasHero then
                focusHero()
                return true
            else if m.hasRows then
                focusRows()
                return true
            end if
        end if
    else if key = "up" then
        if m.focusArea = "rows" then
            if m.curRow > 0 then
                moveRow(-1)
            else if hasHero then
                focusHero()
            else if m.filterBar.visible then
                focusFilters()
            else
                focusNav()
            end if
            return true
        else if m.focusArea = "hero" then
            if m.filterBar.visible then
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
        if m.focusArea = "rows" or m.focusArea = "hero" or m.filterBar.hasFocus() then
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
    if info <> invalid then setHero(info, false)
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
sub setHero(info as Object, animate as Boolean)
    bg = asStr(info.background)
    if bg = "" then bg = asStr(info.poster)
    setBackdrop(bg, animate)
    applyHeroInfo(info)
end sub

sub applyHeroInfo(info as Object)
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

    ' Sinopse ausente (ou cortada, no caso do historico): busca o meta completo
    m.heroId = asStr(info.id)
    if asStr(info.description) = "" or asStr(info.videoId) <> "" then requestHeroMeta(info)
end sub

' ---------------------------------------------------------------------------
' Fundo do banner: troca direta ou com fade (camada B sobre a A)
' ---------------------------------------------------------------------------
sub setBackdrop(url as String, animate as Boolean)
    if url = m.curBackdrop then return
    if url = "" or not animate then
        setBackdropInstant(url)
        return
    end if
    if m.fading then
        m.queuedBackdrop = url
        return
    end if
    startFade(url)
end sub

sub setBackdropInstant(url as String)
    m.fading = false
    m.queuedBackdrop = ""
    m.fadeIn.control = "stop"
    m.fadeOut.control = "stop"
    m.heroBackdrop.uri = url
    m.heroBackdropB.opacity = 0.0
    m.frontIsB = false
    m.curBackdrop = url
end sub

sub startFade(url as String)
    m.fading = true
    m.curBackdrop = url
    if m.frontIsB then
        m.fadeTarget = m.heroBackdrop
    else
        m.fadeTarget = m.heroBackdropB
    end if
    if asStr(m.fadeTarget.uri) = url then
        runFade()
    else
        m.fadeTarget.uri = url
    end if
end sub

sub runFade()
    if m.frontIsB then
        m.fadeOut.control = "start"
    else
        m.fadeIn.control = "start"
    end if
end sub

sub onBackdropLoaded(event as Object)
    if not m.fading then return
    node = event.getRoSGNode()
    if not node.isSameNode(m.fadeTarget) then return
    st = node.loadStatus
    if st = "ready" then
        runFade()
    else if st = "failed" then
        m.fading = false
        m.curBackdrop = ""
    end if
end sub

sub onFadeState(event as Object)
    if not m.fading then return
    if event.getData() <> "stopped" then return
    m.frontIsB = not m.frontIsB
    m.fading = false
    if m.queuedBackdrop <> "" then
        q = m.queuedBackdrop
        m.queuedBackdrop = ""
        setBackdrop(q, true)
    end if
end sub

' ---------------------------------------------------------------------------
' Carrossel de destaques (gira sozinho enquanto o foco esta na barra ou nos filtros)
' ---------------------------------------------------------------------------
sub onCarousel()
    if m.fading then
        m.fadeStall = m.fadeStall + 1
        if m.fadeStall >= 2 then
            m.fadeStall = 0
            setBackdropInstant(m.curBackdrop)
        end if
        return
    end if
    m.fadeStall = 0
    if m.focusArea = "rows" or m.panelOpen then return
    if m.featured.count() < 2 then return
    m.fIdx = (m.fIdx + 1) mod m.featured.count()
    setHero(m.featured[m.fIdx], true)
    updateDots()
end sub

sub rebuildDots()
    while m.dots.getChildCount() > 0
        m.dots.removeChildIndex(0)
    end while
    for i = 0 to m.featured.count() - 1
        r = CreateObject("roSGNode", "Rectangle")
        r.height = 6
        m.dots.appendChild(r)
    end for
    updateDots()
end sub

sub updateDots()
    x = 0
    for i = 0 to m.dots.getChildCount() - 1
        r = m.dots.getChild(i)
        w = 12
        r.color = "0x6A6A75FF"
        if i = m.fIdx then
            w = 34
            r.color = "0xFFFFFFFF"
        end if
        r.width = w
        r.translation = [x, 0]
        x = x + w + 8
    end for
end sub

sub requestHeroMeta(info as Object)
    id = asStr(info.id)
    if id = "" then return
    cached = m.metaCache[id]
    if cached <> invalid then
        applyHeroMeta(cached)
        return
    end if
    if m.metaPending[id] <> invalid then return
    base = findMetaBase(m.global.addons, asStr(info.kind), id, asStr(info.addon))
    if base = "" then return
    m.metaPending[id] = true
    startJson(base + "/meta/" + urlEncode(asStr(info.kind)) + "/" + urlEncode(id) + ".json", "onHeroMeta", { id: id })
end sub

sub onHeroMeta(event as Object)
    task = event.getRoSGNode()
    ctx = task.context
    res = event.getData()
    releaseTask(task)
    m.metaPending.delete(ctx.id)

    entry = { description: "" }
    if res.ok = true and Type(res.data) = "roAssociativeArray" then
        meta = res.data.meta
        if Type(meta) = "roAssociativeArray" then entry.description = asStr(meta.description)
    end if
    m.metaCache[ctx.id] = entry
    if ctx.id = m.heroId then applyHeroMeta(entry)
end sub

sub applyHeroMeta(entry as Object)
    d = asStr(entry.description)
    if d = "" then d = i18n("no_synopsis")
    m.heroDesc.text = d
end sub

sub clearHero()
    m.heroId = ""
    setBackdropInstant("")
    m.heroTitle.text = ""
    m.heroMeta.text = ""
    m.heroDesc.text = ""
end sub

sub onHeroTimer()
    if m.pendingHero <> invalid then setHero(m.pendingHero, false)
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
        catalogs = listCatalogs(m.global.addons, "", false, 6)
        addGenreRows(catalogs)
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

' Linhas extras de filmes por genero na tela inicial (Acao, Comedia, Terror, Ficcao...)
sub addGenreRows(catalogs as Object)
    pick = invalid
    for each c in listFilterCatalogs(m.global.addons, "movie")
        if c.hasGenre = true and c.genreReq <> true and c.genres.count() > 0 then
            pick = c
            exit for
        end if
    end for
    if pick = invalid then return

    chosen = []
    for each w in ["action", "comedy", "horror", "sci-fi", "drama"]
        for each g in pick.genres
            if LCase(g) = w then
                chosen.push(g)
                exit for
            end if
        end for
        if chosen.count() >= 4 then exit for
    end for
    if chosen.count() = 0 then
        for each g in pick.genres
            chosen.push(g)
            if chosen.count() >= 4 then exit for
        end for
    end if

    for each g in chosen
        catalogs.push({ base: pick.base, kind: "movie", id: pick.id, title: kindLabel("movie") + " - " + genreLabel(g), extra: "genre=" + urlEncode(g), hasGenre: true })
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
            defs.push({ title: i18n("continue_watching"), nodes: nodes, isHistory: true })
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

    ' Destaques do carrossel: ate 2 titulos (com imagem de fundo) de cada linha de catalogo
    feats = []
    for each d in defs
        if d.isHistory <> true then
            taken = 0
            for each n in d.nodes
                inf = n.info
                if asStr(inf.background) <> "" and taken < 2 and feats.count() < 8 then
                    feats.push(inf)
                    taken = taken + 1
                end if
            end for
        end if
    end for
    m.featured = feats
    m.fIdx = 0
    rebuildDots()

    if m.hasRows then
        m.status.visible = false
        if feats.count() > 0 then
            setHero(feats[0], false)
        else if firstInfo <> invalid then
            setHero(firstInfo, false)
        end if
        refreshHeroChrome()
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
