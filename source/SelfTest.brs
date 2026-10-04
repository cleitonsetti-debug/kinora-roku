' =============================================================================
' Autoteste: confere no proprio Roku as funcoes puras do app. Mostrado em
' Ajustes > Diagnostico e autoteste. Usa m.stTotal / m.stFails.
' =============================================================================

sub chk(name as String, cond as Boolean)
    m.stTotal = m.stTotal + 1
    if not cond then m.stFails.push(name)
end sub

function runSelfTests() as Object
    m.stTotal = 0
    m.stFails = []

    ' texto e URLs
    chk("urlEncode espaco", urlEncode("a b") = "a%20b")
    chk("urlEncode dois-pontos", urlEncode("tt1:1:2") = "tt1%3A1%3A2")
    chk("urlEncode acento (UTF-8)", urlEncode("é") = "%C3%A9")
    chk("normalizeAddonUrl stremio://", normalizeAddonUrl("stremio://x.com/manifest.json") = "https://x.com")
    chk("normalizeAddonUrl barra final", normalizeAddonUrl("https://x.com/a/") = "https://x.com/a")
    chk("normalizeAddonUrl esquema invalido", normalizeAddonUrl("ftp://x.com") = "")
    chk("replaceAll", replaceAll("a-b-c", "-", "+") = "a+b+c")
    chk("startsWith", startsWith("tt123", "tt") and not startsWith("x", "tt"))
    chk("contains", contains("abc", "b") and not contains("abc", "z"))
    chk("hostOf", hostOf("https://abc.example.com/token/stream/x.json") = "abc.example.com")
    chk("netTarget sem caminho de configuracao", netTarget("https://abc.example.com/token123/stream/movie/tt1.json") = "abc.example.com/stream/")

    ' tempo
    chk("formatTime 125", formatTime(125) = "2:05")
    chk("formatTime 3725", formatTime(3725) = "1:02:05")
    chk("formatTime 5", formatTime(5) = "0:05")
    chk("formatClock", Len(formatClock()) = 8)

    ' conversoes
    chk("asStr numero", asStr(5) = "5")
    chk("asStr invalid", asStr(invalid) = "")
    chk("toInt string", toInt("12") = 12)
    chk("toInt float", toInt(3.7) = 3)
    chk("joinList", joinList(["a", "b", "c"], 2) = "a, b")

    ' ordenacao
    arr = [{ n: 3 }, { n: 1 }, { n: 2 }]
    sortByNumber(arr, "n")
    chk("sortByNumber", arr[0].n = 1 and arr[1].n = 2 and arr[2].n = 3)

    ' fontes, qualidade e formatos
    chk("guessStreamFormat hls", guessStreamFormat("http://x/a.m3u8?t=1") = "hls")
    chk("guessStreamFormat mp4", guessStreamFormat("http://x/a.mp4") = "mp4")
    chk("guessStreamFormat mkv", guessStreamFormat("http://x/a.mkv") = "mkv")
    chk("guessStreamFormat desconhecido", guessStreamFormat("http://x/a") = "")
    chk("streamQuality 1080p", streamQuality("Filme 1080p WEB") = 1080)
    chk("streamQuality 4K", streamQuality("Filme 4K HDR") = 2160)
    chk("streamQuality desconhecida", streamQuality("Filme") = 0)

    ' idiomas
    chk("langMatches por/pt", langMatches("por", "pt"))
    chk("langMatches pob/pt", langMatches("pob", "pt"))
    chk("langMatches eng/pt", not langMatches("eng", "pt"))
    chk("langMatches est/es (estonio)", not langMatches("est", "es"))
    chk("langMatches spa/es", langMatches("spa", "es"))
    chk("langMatches fra/fra", langMatches("fra", "fra"))
    chk("toLang3 pt-BR", toLang3("pt-BR") = "por")
    chk("prefCode pob", prefCode("pob") = "pt")
    chk("prefCode fra", prefCode("fra") = "fra")

    ' conteudo adulto, PIN
    chk("isAdultMeta sim", isAdultMeta({ genres: ["Drama", "Adult"] }))
    chk("isAdultMeta nao", not isAdultMeta({ genres: ["Drama"] }))
    chk("pinHash tamanho", Len(pinHash("1234")) = 64)
    chk("pinHash difere", pinHash("1234") <> pinHash("1235"))

    ' traducoes (o bug da funcao nativa Tr() mostrava as chaves)
    chk("i18n traduz", i18n("nav_home") <> "nav_home")

    ' perfis, cores e ajustes
    chk("accentFor formato", Len(accentFor("tt1")) = 10 and Left(accentFor("tt1"), 2) = "0x")
    chk("accentFor estavel", accentFor("tt1") = accentFor("tt1"))
    chk("splitText", splitText("a|b|c", "|").count() = 3)
    chk("initialOf", initialOf("  kinora") = "K")
    chk("regKey compartilhada", regKey("addons") = "addons" and regKey("profiles") = "profiles")
    chk("defaultSettings salto", defaultSettings().jump = 10)
    chk("loadSettings idioma valido", loadSettings().lang <> "")
    chk("i18n categorias", i18n("cat_general") <> "cat_general" and i18n("st_lang") <> "st_lang")
    chk("perfis padrao", loadProfiles().count() >= 1)
    chk("versionNewer maior", versionNewer("1.5.10", "1.5.2") and versionNewer("2.0", "1.9.9"))
    chk("versionNewer igual/menor", not versionNewer("1.5.2", "1.5.2") and not versionNewer("1.4.9", "1.5.0"))
    chk("currentRelease", currentRelease() <> "")

    ' registry e JSON
    regWrite("selftest", { a: 1, b: "é" })
    d = regRead("selftest")
    ok = false
    if Type(d) = "roAssociativeArray" then ok = (d.a = 1 and d.b = "é")
    chk("registry ida e volta (com acento)", ok)
    sec = CreateObject("roRegistrySection", "kinora")
    sec.Delete("selftest")
    sec.Flush()

    return { total: m.stTotal, failures: m.stFails }
end function
