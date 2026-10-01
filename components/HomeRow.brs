' =============================================================================
' HomeRow: UMA linha da tela inicial = titulo (Label nosso, posicao fixa) + RowList de 1 linha.
' O titulo e desenhado por nos, entao nao depende das regras de rotulo da RowList do Roku.
' =============================================================================

sub init()
    m.label = m.top.findNode("titleLabel")
    m.list = m.top.findNode("list")
    m.list.observeField("rowItemSelected", "onSelected")
    m.list.observeField("rowItemFocused", "onFocused")
end sub

sub onTitle()
    m.label.text = m.top.rowTitle
end sub

sub onContent()
    m.list.content = m.top.rowContent
end sub

function itemAt(col as Integer) as Dynamic
    c = m.list.content
    if c = invalid then return invalid
    row = c.getChild(0)
    if row = invalid then return invalid
    item = row.getChild(col)
    if item = invalid then return invalid
    return item.info
end function

sub onSelected()
    sel = m.list.rowItemSelected
    info = itemAt(sel[1])
    if info <> invalid then m.top.itemSelected = info
end sub

sub onFocused()
    sel = m.list.rowItemFocused
    info = itemAt(sel[1])
    if info <> invalid then m.top.itemFocused = info
end sub

function focusRow() as Boolean
    m.list.setFocus(true)
    return true
end function

function currentInfo() as Dynamic
    sel = m.list.rowItemFocused
    return itemAt(sel[1])
end function
