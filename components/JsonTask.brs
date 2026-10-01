' Task de rede: GET de uma URL e parse de JSON fora da render thread.
' Resultado em m.top.result = { ok, status, data, error }
sub init()
    m.top.functionName = "doRequest"
end sub

sub doRequest()
    res = { ok: false, status: 0, data: invalid, error: "" }
    url = m.top.url
    if url = "" then
        res.error = "url vazia"
        m.top.result = res
        return
    end if

    http = CreateObject("roUrlTransfer")
    http.SetCertificatesFile("common:/certs/ca-bundle.crt")
    http.InitClientCertificates()
    http.AddHeader("Accept", "application/json")
    http.AddHeader("User-Agent", "KinoraRoku/1.2")
    http.EnableEncodings(true)
    http.RetainBodyOnError(true)
    http.SetUrl(url)

    port = CreateObject("roMessagePort")
    http.SetMessagePort(port)

    if http.AsyncGetToString() then
        msg = wait(m.top.timeoutMs, port)
        if type(msg) = "roUrlEvent" then
            res.status = msg.GetResponseCode()
            if res.status >= 200 and res.status < 300 then
                parsed = ParseJson(msg.GetString())
                if parsed <> invalid then
                    res.ok = true
                    res.data = parsed
                else
                    res.error = "json invalido"
                end if
            else
                res.error = "http " + Str(res.status).trim()
            end if
        else
            http.AsyncCancel()
            res.error = "timeout"
        end if
    else
        res.error = "falha ao iniciar a requisicao"
    end if

    m.top.result = res
end sub
