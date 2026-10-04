' =============================================================================
' HomeFilters: filtros de Filmes/Series (catalogo, genero/ano) e linhas por genero.
' Incluido pela HomeView (usa o m dela).
' =============================================================================

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
        if m.global.optHideAdult = true then return filterAdultGenres(m.catOptions[st.cat].genres)
        return m.catOptions[st.cat].genres
    end if
    out = []
    seen = {}
    for each c in m.catOptions
        if c.genreReq <> true then
            cg = c.genres
            if m.global.optHideAdult = true then cg = filterAdultGenres(cg)
            for each g in cg
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
