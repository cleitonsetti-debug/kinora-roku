# Capturas de tela limpas (sem fotografar a TV)

O Roku tem uma ferramenta de captura de tela na página do desenvolvedor. Pelo que sei da documentação da Roku
(confira em developer.roku.com, os passos podem mudar), o caminho é:

1. Com o Modo Desenvolvedor ativo, abra `http://IP_DO_ROKU` e entre com `rokudev` e a senha definida.
2. Gere uma chave de assinatura: no terminal, `telnet IP_DO_ROKU 8080` e rode o comando `genkey`
   (ele mostra uma senha e um DevID; anote os dois).
3. Na página do desenvolvedor, abra o empacotador (**Packager**), informe um nome para o app, a senha da chave e clique em **Package**.
4. Depois, em **Utilities**, use **Screenshot**: informe a senha da chave e gere a imagem.

Dicas:
- Prefira telas sem capas de filmes (Ajustes, Addons, Diagnóstico, busca vazia), para evitar dúvidas sobre direitos de imagem.
- Salve as imagens em `docs/` e referencie no README.
