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
    return startJsonT(url, callback, context, 15000)
end function

function startJsonT(url as String, callback as String, context as Object, timeoutMs as Integer) as Object
    if m.tasks = invalid then m.tasks = []
    task = CreateObject("roSGNode", "JsonTask")
    task.url = url
    task.timeoutMs = timeoutMs
    task.context = context
    task.observeField("result", callback)
    m.tasks.push(task)
    task.control = "RUN"
    return task
end function

sub releaseTask(node as Object)
    res = node.result
    if res <> invalid then
        if res.ok <> true then logNet(node.url, Str(res.status).trim(), asStr(res.error))
    end if
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


' ---------------------------------------------------------------------------
' Idiomas de faixas (legenda/audio): pref = "pt" | "en" | "es"
' ---------------------------------------------------------------------------
function langMatches(code as String, pref as String) as Boolean
    c = LCase(code)
    if c = "" then return false
    if pref = "pt" then return (c = "pt" or startsWith(c, "pt-") or startsWith(c, "pt_") or c = "por" or c = "pob" or c = "pb")
    if pref = "en" then return (c = "en" or startsWith(c, "en-") or startsWith(c, "en_") or c = "eng")
    if pref = "es" then return (c = "es" or startsWith(c, "es-") or startsWith(c, "es_") or c = "spa" or c = "esl" or c = "lat")
    if Len(pref) = 3 and pref <> "off" then return (c = LCase(pref))
    return false
end function

function toLang3(code as String) as String
    if langMatches(code, "pt") then return "por"
    if langMatches(code, "en") then return "eng"
    if langMatches(code, "es") then return "spa"
    c = LCase(code)
    if c = "" then return "und"
    return c
end function

function langName(code as String) as String
    if langMatches(code, "pt") then return "Português"
    if langMatches(code, "en") then return "English"
    if langMatches(code, "es") then return "Español"
    if code = "" then return "?"
    return UCase(code)
end function

function pad2(n as Integer) as String
    return Right("0" + Str(n).trim(), 2)
end function

' 3725 -> "1:02:05" ; 125 -> "2:05"
function formatTime(totalSec as Integer) as String
    if totalSec < 0 then totalSec = 0
    h = totalSec \ 3600
    mi = (totalSec mod 3600) \ 60
    sc = totalSec mod 60
    if h > 0 then return Str(h).trim() + ":" + pad2(mi) + ":" + pad2(sc)
    return Str(mi).trim() + ":" + pad2(sc)
end function

' ---------------------------------------------------------------------------
' Qualidade, conteudo adulto, PIN, preferencias de faixa
' ---------------------------------------------------------------------------
function streamQuality(text as String) as Integer
    t = LCase(text)
    if contains(t, "2160") or contains(t, "4k") or contains(t, "uhd") then return 2160
    if contains(t, "1080") then return 1080
    if contains(t, "720") then return 720
    if contains(t, "480") then return 480
    if contains(t, "360") then return 360
    return 0
end function

function isAdultMeta(meta as Object) as Boolean
    g = meta.genres
    if Type(g) = "roArray" then
        for each x in g
            t = LCase(asStr(x))
            if t = "adult" or t = "erotic" or t = "erotica" then return true
        end for
    end if
    return false
end function

function filterAdultGenres(list as Object) as Object
    out = []
    for each g in list
        if LCase(asStr(g)) <> "adult" then out.push(g)
    end for
    return out
end function

function pinHash(pin as String) as String
    ba = CreateObject("roByteArray")
    ba.FromAsciiString("kinora:" + pin)
    d = CreateObject("roEVPDigest")
    d.Setup("sha256")
    return d.Process(ba)
end function

' "pob" -> "pt", "eng" -> "en"; outros idiomas ficam com o codigo original
function prefCode(lang as String) as String
    if langMatches(lang, "pt") then return "pt"
    if langMatches(lang, "en") then return "en"
    if langMatches(lang, "es") then return "es"
    return LCase(lang)
end function

' ---------------------------------------------------------------------------
' Registro de falhas de rede (sem expor caminhos de configuracao dos addons)
' ---------------------------------------------------------------------------
function formatClock() as String
    dt = CreateObject("roDateTime")
    dt.ToLocalTime()
    return pad2(dt.GetHours()) + ":" + pad2(dt.GetMinutes()) + ":" + pad2(dt.GetSeconds())
end function

function hostOf(url as String) as String
    u = url
    p = Instr(1, u, "://")
    if p > 0 then u = Mid(u, p + 3)
    q = Instr(1, u, "/")
    if q > 0 then u = Left(u, q - 1)
    return u
end function

function netTarget(url as String) as String
    res = ""
    for each r in ["/manifest.json", "/catalog/", "/meta/", "/stream/", "/subtitles/"]
        if Instr(1, url, r) > 0 then
            res = r
            exit for
        end if
    end for
    return hostOf(url) + res
end function

sub logNet(url as String, status as String, err as String)
    if m.global.netLog = invalid then return
    list = m.global.netLog
    list.push({ t: formatClock(), target: netTarget(url), msg: err + " " + status })
    while list.count() > 30
        list.shift()
    end while
    m.global.netLog = list
end sub

' ---------------------------------------------------------------------------
' Cor de destaque (acento): cada titulo/perfil ganha uma cor da paleta
' ---------------------------------------------------------------------------
function accentPalette() as Object
    return ["0xFF4D6DFF", "0xFF7A29FF", "0xFFB703FF", "0x2EC4B6FF", "0x3A86FFFF", "0x8338ECFF", "0xFF006EFF", "0x06D6A0FF", "0xEF476FFF", "0x118AB2FF", "0x9B5DE5FF", "0xF15BB5FF"]
end function

function accentByIndex(i as Integer) as String
    pal = accentPalette()
    return pal[((i mod pal.count()) + pal.count()) mod pal.count()]
end function

function accentFor(id as String) as String
    total = 0
    for i = 1 to Len(id)
        total = total + Asc(Mid(id, i, 1))
    end for
    return accentByIndex(total)
end function

' Divide um texto por um separador de 1 caractere (ex.: "a|b|c")
function splitText(s as String, sep as String) as Object
    out = []
    rest = s
    while true
        p = Instr(1, rest, sep)
        if p = 0 then exit while
        out.push(Left(rest, p - 1))
        rest = Mid(rest, p + Len(sep))
    end while
    out.push(rest)
    return out
end function

function initialOf(name as String) as String
    t = name.trim()
    if Len(t) = 0 then return "?"
    return UCase(Left(t, 1))
end function

' Versao da release do app (campo kinora_release do manifest, ex.: 1.5.2)
function currentRelease() as String
    ai = CreateObject("roAppInfo")
    v = ai.GetValue("kinora_release")
    if v = invalid or v = "" then v = ai.GetVersion()
    return v
end function

' true se a versao "a" for maior que "b" (ex.: "1.5.10" > "1.5.2")
function versionNewer(a as String, b as String) as Boolean
    pa = splitText(a, ".")
    pb = splitText(b, ".")
    n = pa.count()
    if pb.count() > n then n = pb.count()
    for i = 0 to n - 1
        x = 0
        y = 0
        if i < pa.count() then x = toInt(pa[i])
        if i < pb.count() then y = toInt(pb[i])
        if x > y then return true
        if x < y then return false
    end for
    return false
end function
