sub init()
    m.bg = m.top.findNode("bg")
    m.label = m.top.findNode("label")
end sub

sub onLayout()
    w = m.top.width
    h = m.top.height
    if w <= 0 or h <= 0 then return
    m.bg.width = w
    m.bg.height = h
    m.label.width = w
    m.label.height = h
end sub

sub onContentChange()
    c = m.top.itemContent
    if c = invalid then return
    m.label.text = c.title
end sub
