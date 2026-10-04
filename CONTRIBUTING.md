# Como contribuir

Obrigado pelo interesse no Kinora! É um projeto de estudo mantido no tempo livre; toda ajuda é bem-vinda.

## Antes de começar
- Leia o `README.md` e o `NOTICE.md`. O projeto **não inclui, não recomenda e não ajuda a encontrar** addons ou fontes de vídeo.
  Contribuições que facilitem pirataria serão recusadas.
- Procure as issues marcadas com `good first issue`.

## Ambiente
1. Ative o Modo Desenvolvedor no Roku (Home x3, Cima x2, Direita, Esquerda, Direita, Esquerda, Direita).
2. Gere o pacote e instale pela página `http://IP_DO_ROKU`:
   ```
   sh tools/package.sh kinora.zip
   ```
3. Acompanhe o console enquanto testa: `telnet IP_DO_ROKU 8085` (erros de compilação e de execução aparecem ali).

## Antes de enviar o pull request
- Rode a checagem estática: `python3 tools/lint.py` (ela confere blocos, ids do XML, callbacks, scripts incluídos,
  imagens e fontes referenciadas e as chaves de tradução).
- Textos novos da interface entram em **português, inglês e espanhol** (`source/I18n.brs`).
- No Roku, abra **Ajustes > Diagnóstico e autoteste** e execute o autoteste: nenhuma falha deve aparecer.
- Cuidado com nomes de variáveis e funções: o BrightScript tem funções nativas (`Pos`, `Tr`, `Log`, `Rem`...) que vencem as suas.
- Não inclua chaves, tokens, senhas, o arquivo `.env` ou endereços de addons.

## Estrutura
- `source/`: funções compartilhadas (`Utils`, `I18n`, `Storage`, `AddonStore`, `Streams`, `Subs`, `Settings`, `SelfTest`).
- `components/`: telas e componentes SceneGraph (`MainScene`, `HomeView`, `DetailsView`, `PlayerView`...).
- `tools/`: scripts de apoio (empacotar, instalar, adicionar addon, checagem).
