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
    m.heroBtn2 = m.top.findNode("heroBtn2")
    m.kindBg = m.top.findNode("kindBg")
    m.kindLabel = m.top.findNode("kindLabel")
    m.imdbBg = m.top.findNode("imdbBg")
    m.imdbLabel = m.top.findNode("imdbLabel")
    m.busy = m.top.findNode("busy")
    m.glow = m.top.findNode("glow")
    m.heroZoom = m.top.findNode("heroZoom")
    m.zoomAnim = m.top.findNode("zoomAnim")
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
    m.loadedFav = -1
    m.cache = {}
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
    m.defs = []
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
    m.menuKeys = ["home", "movies", "series", "search", "addons", "settings", "profiles"]
    m.heroIdx = 0
    m.heroInfo = invalid
    m.heroBgNeeded = false
    m.uiProf = ""
    m.uiLang = ""

    rebuildNav()

    m.nav.observeField("itemFocused", "onNavFocused")
    m.nav.observeField("itemSelected", "onNavSelected")
    m.filterBar.observeField("itemSelected", "onFilterSelected")
    m.filterList.observeField("itemSelected", "onPickerSelected")
    m.debounce.observeField("fire", "onDebounce")
    m.heroTimer.observeField("fire", "onHeroTimer")
    m.carouselTimer.observeField("fire", "onCarousel")
    m.top.observeField("visible", "onVisibleChange")
    m.heroBackdrop.observeField("loadStatus", "onBackdropLoaded")
    m.heroBackdropB.observeField("loadStatus", "onBackdropLoaded")
    m.fadeIn.observeField("state", "onFadeState")
    m.fadeOut.observeField("state", "onFadeState")
    setupHeroBtn()
    moveIndicator("home")
end sub

sub rebuildNav()
    m.uiLang = m.global.lang
    navContent = CreateObject("roSGNode", "ContentNode")
    m.uiProf = asStr(m.global.profileId) + "|" + asStr(m.global.profileName)
    pname = asStr(m.global.profileName)
    if pname = "" then pname = i18n("pf_default_name")
    if Len(pname) > 11 then pname = Left(pname, 10) + "…"
    labels = [i18n("nav_home"), i18n("nav_movies"), i18n("nav_series"), i18n("nav_search"), i18n("nav_addons"), i18n("nav_settings"), pname]
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
    if m.category = "home" then
        if m.global.historyRev <> m.loadedHist or m.global.favRev <> m.loadedFav then stale = true
    end if
    if m.uiLang <> m.global.lang or m.uiProf <> asStr(m.global.profileId) + "|" + asStr(m.global.profileName) then
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
        focusHeroBtn()
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
    if key = "search" or key = "addons" or key = "settings" or key = "profiles" then
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
    ensureWindow()
    v = curRowView()
    if v = invalid then return
    m.focusArea = "rows"
    refreshHeroChrome()
    v.callFunc("focusRow")
    info = v.callFunc("currentInfo")
    if info <> invalid then setHero(info, false)
end sub

sub focusNav()
    m.focusArea = "nav"
    m.nav.setFocus(true)
    onTopFocus()
end sub

sub focusHero()
    m.focusArea = "hero"
    m.heroIdx = 0
    refreshHeroChrome()
    focusHeroBtn()
    onTopFocus()
end sub

sub focusFilters()
    m.focusArea = "filters"
    m.filterBar.setFocus(true)
    onTopFocus()
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
        m.top.itemSelected = heroPlayInfo()
        return true
    end if
    if m.focusArea = "hero" and hasHero then
        if key = "OK" then
            if m.heroIdx = 1 and m.heroBtn2.visible then
                m.top.itemSelected = heroPlayInfo()
            else
                m.top.itemSelected = m.featured[m.fIdx]
            end if
            return true
        else if key = "left" then
            m.heroIdx = 0
            refreshHeroChrome()
            return true
        else if key = "right" then
            if m.heroBtn2.visible then m.heroIdx = 1
            refreshHeroChrome()
            return true
        end if
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
        if v <> invalid then m.rowsGroup.removeChild(v)
    end for
    m.rowViews = []
    m.rowHasTitle = []
    m.defs = []
    m.curRow = 0
    m.hasRows = false
end sub

' So existem as views da linha em foco e das vizinhas (economiza memoria e evita travadas):
' os nos das demais linhas so sao criados quando elas chegam perto
sub buildRows(defs as Object)
    clearRows()
    m.defs = defs
    for each d in defs
        m.rowViews.push(invalid)
        m.rowHasTitle.push(d.title <> "")
    end for
    m.curRow = 0
    m.hasRows = (m.rowViews.count() > 0)
    ensureWindow()
    layoutRows()
end sub

function makeRowView(i as Integer) as Object
    d = m.defs[i]
    root = CreateObject("roSGNode", "ContentNode")
    row = root.createChild("ContentNode")
    for each info in d.items
        row.appendChild(infoToNode(info, ""))
    end for
    view = CreateObject("roSGNode", "HomeRow")
    view.rowTitle = d.title
    view.rowContent = root
    view.observeField("itemSelected", "onRowSelected")
    view.observeField("itemFocused", "onRowFocused")
    m.rowsGroup.appendChild(view)
    return view
end function

sub ensureWindow()
    for i = 0 to m.rowViews.count() - 1
        want = (i >= m.curRow - 1 and i <= m.curRow + 2)
        if want and m.rowViews[i] = invalid then
            m.rowViews[i] = makeRowView(i)
        else if not want and m.rowViews[i] <> invalid then
            m.rowsGroup.removeChild(m.rowViews[i])
            m.rowViews[i] = invalid
        end if
    end for
end sub

' A linha em foco fica sempre no mesmo lugar (y=540); as proximas vem abaixo,
' as anteriores ficam escondidas. Linhas com titulo tem 90 px de respiro, sem titulo 24 px.
sub layoutRows()
    y = 540
    for i = 0 to m.rowViews.count() - 1
        if i > m.curRow then
            if m.rowHasTitle[i] then
                y = y + 300 + 90
            else
                y = y + 300 + 24
            end if
        end if
        v = m.rowViews[i]
        if v <> invalid then
            if i < m.curRow then
                v.visible = false
            else
                v.translation = [70, y]
                v.visible = (y < 1080)
            end if
        end if
    end for
end sub

' View da linha em foco (ou invalid)
function curRowView() as Dynamic
    if m.rowViews.count() = 0 then return invalid
    if m.curRow < 0 or m.curRow >= m.rowViews.count() then return invalid
    return m.rowViews[m.curRow]
end function

sub moveRow(delta as Integer)
    n = m.curRow + delta
    if n < 0 or n >= m.rowViews.count() then return
    m.curRow = n
    ensureWindow()
    layoutRows()
    focusRows()
end sub

sub onRowSelected(event as Object)
    info = event.getData()
    if info <> invalid then m.top.itemSelected = info
end sub

sub onRowFocused(event as Object)
    v = curRowView()
    if v = invalid then return
    node = event.getRoSGNode()
    if not node.isSameNode(v) then return
    m.pendingHero = event.getData()
    m.heroTimer.control = "stop"
    m.heroTimer.control = "start"
end sub

' ---------------------------------------------------------------------------
' Carregamento dos catalogos
' ---------------------------------------------------------------------------
sub loadCategory(cat as String)
    m.gen = m.gen + 1
    m.category = cat
    m.loadedRev = m.global.addonsRev
    m.loadedHist = m.global.historyRev
    m.loadedFav = m.global.favRev
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
    m.busy.visible = true
    m.busy.control = "start"

    if m.total = 0 then
        finishLoad()
        return
    end if

    now = CreateObject("roDateTime").AsSeconds()
    for i = 0 to m.total - 1
        c = m.catalogs[i]
        url = c.base + "/catalog/" + urlEncode(c.kind) + "/" + urlEncode(c.id)
        ex = asStr(c.extra)
        if ex <> "" then url = url + "/" + ex
        url = url + ".json"
        cached = m.cache[url]
        if cached <> invalid and (now - cached.t) < 300 then
            m.results[Str(i).trim()] = cached.metas
            m.pending = m.pending - 1
        else
            startJson(url, "onCatalogResult", { gen: m.gen, index: i, url: url })
        end if
    end for
    if m.pending <= 0 then finishLoad()
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
            if metas.count() > 0 then
                m.results[Str(ctx.index).trim()] = metas
                m.cache[ctx.url] = { t: CreateObject("roDateTime").AsSeconds(), metas: metas }
            end if
        end if
    end if

    m.pending = m.pending - 1
    if m.pending <= 0 then finishLoad()
end sub

sub finishLoad()
    m.loading = false
    m.busy.control = "stop"
    m.busy.visible = false
    defs = []
    firstInfo = invalid

    ' Linha "Continuar assistindo" (so na tela inicial)
    if m.category = "home" then
        hist = loadHistory()
        seen = {}
        items = []
        for each h in hist
            hid = asStr(h.id)
            if hid <> "" and not seen.doesExist(hid) then
                seen[hid] = true
                items.push(h)
            end if
        end for
        if items.count() > 0 then
            defs.push({ title: i18n("continue_watching"), items: items, isHistory: true })
            firstInfo = items[0]
        end if
    end if

    ' Linha "Minha lista" (so na tela inicial)
    if m.category = "home" then
        favItems = []
        for each f in loadFavorites()
            if asStr(f.id) <> "" then favItems.push(f)
        end for
        if favItems.count() > 0 then defs.push({ title: i18n("my_list"), items: favItems, isFav: true })
    end if

    hideAdult = (m.global.optHideAdult = true)

    ' Linhas dos catalogos, na ordem dos addons
    for i = 0 to m.total - 1
        metas = m.results[Str(i).trim()]
        if metas <> invalid then
            c = m.catalogs[i]
            chunk = invalid
            n = 0
            perRow = 20
            if m.singleMode then perRow = 8
            for each meta in metas
                if Type(meta) = "roAssociativeArray" and not (hideAdult and isAdultMeta(meta)) then
                    info = metaToInfo(meta, c.base, c.kind)
                    if info.id <> "" and info.name <> "" then
                        if chunk = invalid or (n mod perRow) = 0 then
                            if chunk <> invalid and not m.singleMode then exit for
                            t = ""
                            if n = 0 then t = c.title
                            chunk = { title: t, items: [] }
                            defs.push(chunk)
                        end if
                        chunk.items.push(info)
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
        if d.isHistory <> true and d.isFav <> true then
            taken = 0
            for each inf in d.items
                if asStr(inf.background) <> "" and taken < 2 and feats.count() < 8 then
                    feats.push(inf)
                    taken = taken + 1
                end if
            end for
        end if
    end for
    ' o que voce estava assistindo vai primeiro (com o botao "Continuar")
    if m.category = "home" then
        for each d in defs
            if d.isHistory = true and d.items.count() > 0 then
                feats.unshift(d.items[0])
                if feats.count() > 8 then feats.pop()
            end if
        end for
    end if
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

' Escondida (ex.: durante um video): para o carrossel e as animacoes e solta as
' imagens de fundo, que ocupam bastante memoria de video
sub onVisibleChange()
    if m.top.visible then
        m.carouselTimer.control = "start"
        if m.curBackdrop <> "" then m.heroBackdrop.uri = m.curBackdrop
    else
        m.fading = false
        m.queuedBackdrop = ""
        m.carouselTimer.control = "stop"
        m.heroTimer.control = "stop"
        m.zoomAnim.control = "stop"
        m.fadeIn.control = "stop"
        m.fadeOut.control = "stop"
        m.heroBackdropB.opacity = 0.0
        m.frontIsB = false
        m.heroBackdrop.uri = ""
        m.heroBackdropB.uri = ""
    end if
end sub
