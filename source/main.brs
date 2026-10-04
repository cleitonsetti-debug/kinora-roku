' Ponto de entrada do canal. Toda a interface vive na MainScene (SceneGraph).
' Tambem recebe parametros por fora (ECP), ex.: "addon=<url>" (ver tools/add-addon.sh).
sub Main(args as Dynamic)
    screen = CreateObject("roSGScreen")
    port = CreateObject("roMessagePort")
    screen.setMessagePort(port)
    input = CreateObject("roInput")
    input.setMessagePort(port)
    scene = screen.CreateScene("MainScene")
    screen.show()

    if Type(args) = "roAssociativeArray" then scene.inputArgs = args

    while true
        msg = wait(0, port)
        if type(msg) = "roSGScreenEvent" then
            if msg.isScreenClosed() then return
        else if type(msg) = "roInputEvent" then
            if msg.isInput() then
                info = msg.getInfo()
                if info <> invalid then scene.inputArgs = info
            end if
        end if
    end while
end sub
