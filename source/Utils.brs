' =============================================================================
' Utilitarios compartilhados (incluidos via <script> nos componentes)
' =============================================================================

function isNumberType(t as String) as Boolean
    return t = "roInt" or t = "Integer" or t = "roInteger" or t = "roFloat" or t = "Float" or t = "roDouble" or t = "Double" or t = "roLongInteger" or t = "LongInteger"
end function

' Converte qualquer valor em String de forma segura
function asStr(v as Dynamic) as String
    if v = invalid then return ""
    t = Type(v)
    if t = "roString" or t = "String" then return "" + v
    if isNumberType(t) then return Str(v).trim()
    return ""
end function

function toInt(v as Dynamic) as Integer
    if v = invalid then return 0
    t = Type(v)
    if t = "roString" or t = "String" then return Int(Val("" + v))
    if isNumberType(t) then return Int(v)
    return 0
end function

function startsWith(s as String, prefix as String) as Boolean
    return Left(s, Len(prefix)) = prefix
end function

function contains(s as String, part as String) as Boolean
    return Instr(1, s, part) > 0
end function

function replaceAll(s as String, oldTxt as String, newTxt as String) as String
    if oldTxt = "" then return s
    out = ""
    rest = s
    while true
        p = Instr(1, rest, oldTxt)
        if p = 0 then exit while
        out = out + Left(rest, p - 1) + newTxt
        rest = Mid(rest, p + Len(oldTxt))
    end while
    return out + rest
end function

function joinWith(items as Object, sep as String) as String
    out = ""
    for each s in items
        if out <> "" then out = out + sep
        out = out + s
    end for
    return out
end function

' Junta ate maxItems strings de um array JSON (ex.: generos)
function joinList(v as Dynamic, maxItems as Integer) as String
    out = ""
    if v = invalid then return out
    if Type(v) <> "roArray" then return out
    n = 0
    for each g in v
        s = asStr(g)
        if s <> "" then
            if out <> "" then out = out + ", "
            out = out + s
            n = n + 1
            if n >= maxItems then exit for
        end if
    end for
    return out
end function

' Percent-encoding (UTF-8) sem depender de roUrlTransfer (proibido na render thread)
function urlEncode(s as String) as String
    ba = CreateObject("roByteArray")
    ba.FromAsciiString(s)
    digits = "0123456789ABCDEF"
    out = ""
    for i = 0 to ba.Count() - 1
        b = ba[i]
        safe = (b >= 48 and b <= 57) or (b >= 65 and b <= 90) or (b >= 97 and b <= 122) or b = 45 or b = 46 or b = 95 or b = 126
        if safe then
            out = out + Chr(b)
        else
            out = out + "%" + Mid(digits, (b \ 16) + 1, 1) + Mid(digits, (b mod 16) + 1, 1)
        end if
    end for
    return out
end function

' Normaliza a URL de um addon: aceita stremio://, remove /manifest.json e a barra final
function normalizeAddonUrl(u as String) as String
    s = u.trim()
    if LCase(Left(s, 10)) = "stremio://" then s = "https://" + Mid(s, 11)
    if LCase(Right(s, 14)) = "/manifest.json" then s = Left(s, Len(s) - 14)
    while Right(s, 1) = "/"
        s = Left(s, Len(s) - 1)
    end while
    low = LCase(s)
    if startsWith(low, "http://") or startsWith(low, "https://") then return s
    return ""
end function

function guessStreamFormat(url as String) as String
    low = LCase(url)
    if contains(low, ".m3u8") then return "hls"
    if contains(low, ".mpd") then return "dash"
    if contains(low, ".mkv") then return "mkv"
    if contains(low, ".mp4") then return "mp4"
    return ""
end function

' Insertion sort ascendente de um array de AAs por um campo numerico
sub sortByNumber(arr as Object, key as String)
    for i = 1 to arr.count() - 1
        cur = arr[i]
        j = i - 1
        while j >= 0
            if arr[j][key] > cur[key] then
                arr[j + 1] = arr[j]
                j = j - 1
            else
                exit while
            end if
        end while
        arr[j + 1] = cur
    end for
end sub

' ---------------------------------------------------------------------------
' Rede: cada requisicao roda em um Task (JsonTask); o resultado volta por callback
' ---------------------------------------------------------------------------
function startJson(url as String, callback as String, context as Object) as Object
    if m.tasks = invalid then m.tasks = []
    task = CreateObject("roSGNode", "JsonTask")
    task.url = url
    task.context = context
    task.observeField("result", callback)
    m.tasks.push(task)
    task.control = "RUN"
    return task
end function

sub releaseTask(node as Object)
    if m.tasks = invalid then return
    for i = m.tasks.count() - 1 to 0 step -1
        if m.tasks[i].isSameNode(node) then
            m.tasks.delete(i)
            exit for
        end if
    end for
end sub

' ---------------------------------------------------------------------------
' Dialogo simples de mensagem
' ---------------------------------------------------------------------------
sub showMessage(title as String, text as String)
    dlg = CreateObject("roSGNode", "StandardMessageDialog")
    dlg.title = title
    dlg.message = [text]
    dlg.buttons = ["OK"]
    dlg.observeField("buttonSelected", "onMessageClosed")
    m.top.getScene().dialog = dlg
end sub

sub onMessageClosed(event as Object)
    dlg = event.getRoSGNode()
    dlg.close = true
end sub

' ---------------------------------------------------------------------------
' Conversao Stremio meta -> estrutura enxuta / ContentNode
' ---------------------------------------------------------------------------
function metaToInfo(meta as Object, base as String, defKind as String) as Object
    kind = asStr(meta["type"])
    if kind = "" then kind = defKind
    return {
        id: asStr(meta.id)
        kind: kind
        name: asStr(meta.name)
        poster: asStr(meta.poster)
        background: asStr(meta.background)
        description: asStr(meta.description)
        year: asStr(meta.releaseInfo)
        rating: asStr(meta.imdbRating)
        genres: joinList(meta.genres, 3)
        addon: base
    }
end function

function infoToNode(info as Object, label as String) as Object
    n = CreateObject("roSGNode", "ContentNode")
    n.title = label
    n.hdPosterUrl = asStr(info.poster)
    n.addFields({ info: info })
    return n
end function

