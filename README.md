# Kinora - canal Roku para filmes, séries e animes

**Kinora** é um canal SceneGraph (BrightScript) com catálogo real via **addons no protocolo Stremio** (padrão: Cinemeta),
busca, temporadas/episódios, escolha de fonte, player e "Continuar assistindo".

## Instalar no Roku

1. No Roku: Home x3, Cima x2, Direita, Esquerda, Direita, Esquerda, Direita. Ative o Modo Desenvolvedor e defina a senha.
2. Gere o pacote (o `manifest` precisa ficar na raiz do zip):
   ```
   cd kinora-canal-roku
   zip -r ../kinora.zip . -x "README.md" ".gitignore" ".git/*"
   ```
3. Envie por `http://IP_DO_ROKU` (Upload > Install), ou por terminal:
   ```
   curl --user rokudev:SUA_SENHA --digest -F "mysubmit=Install" -F "archive=@../kinora.zip" http://IP_DO_ROKU/plugin_install
   ```
4. Logs em tempo real: `telnet IP_DO_ROKU 8085` (todo `print` e erro de BrightScript aparece ali).

## Visual

Tema escuro estilo "AMOLED" (fundo quase preto, texto branco, sem cores berrantes), inspirado nos apps de catálogo
para TV do ecossistema Stremio/Nuvio: barra de navegação no topo, **banner do título em foco** (fundo, título,
metadados e sinopse mudam conforme você navega), posters com cantos arredondados e anel de foco branco,
barra de progresso nos itens de "Continuar assistindo", botão de assistir em pílula e episódios em cards com miniatura.
Fonte: Poppins (licença SIL OFL, embutida em `fonts/`).

## Como usar

- **Início / Filmes / Séries**: barra no topo; Baixo entra nas linhas de catálogo, Cima/Voltar volta à barra.
- **Buscar**: teclado próprio à esquerda; Direita (ou Baixo na última linha de teclas) passa para os resultados,
  Esquerda na primeira coluna dos resultados volta ao teclado. OK em um poster abre os detalhes.
- **Detalhes**: filmes têm o botão Assistir; séries/animes mostram chips de Temporada (Baixo vai para os episódios).
- **Fontes**: ao escolher Assistir/episódio, o app consulta os addons que têm o recurso `stream` e lista as fontes de vídeo direto (http/https).
  O último item da lista é sempre um **vídeo de teste** (Big Buck Bunny) para validar o player.
- **Addons** (menu): OK ativa/desativa, `*` remove, "+ Adicionar addon" pede a URL do manifest (aceita `stremio://`).
- **Continuar assistindo**: o progresso é salvo a cada 15 s no registry do Roku e a reprodução retoma de onde parou.

## Sobre as fontes de vídeo

O Cinemeta só fornece catálogo e metadados, **não vídeo**. Para assistir de verdade, adicione um addon
que devolva links diretos (`url` http/https em `/stream/...`) e que você tenha direito de usar.
O Roku não reproduz torrent (`infoHash`) nem YouTube (`ytId`); essas fontes são ignoradas e contadas na mensagem do painel.

## Estrutura

```
manifest
source/      main.brs, Utils.brs, Storage.brs, AddonStore.brs
components/  MainScene (pilha de telas, carrega addons)
             HomeView, SearchView, AddonsView, DetailsView, PlayerView
             JsonTask (rede em Task), PosterItem, NavItem, KeyItem, ChipItem (itens de lista)
images/      ícones, splash, gradientes do banner e bitmaps 9-patch (foco, cantos, pílulas)
fonts/       Poppins (Regular, Medium, Bold)
```

## O que foi corrigido em relação à versão anterior

- Os componentes agora incluem os `.brs` de `source/` via `<script>` (antes davam "função não definida").
- Toda rede roda em `JsonTask` (Task) com certificados HTTPS; nada de `roUrlTransfer` na render thread.
- `roSGScreen` só é criado em `main.brs`; a navegação é uma pilha de views dentro de uma única Scene.
- Sem login obrigatório e sem a API "Nuvio" (os endpoints eram inventados). Addons e histórico ficam no registry local.
- Pasta `images/` criada, com todos os assets referenciados.
- Addons, catálogos, metadados, episódios e streams vêm de dados reais em vez de listas mockadas.
- `.env`, `CLAUDE.md`, `.bak` e `index.html` ficaram de fora do pacote.

## Novidades da v1.2

- **Continuar assistindo para séries:** a série fica na lista mesmo ao terminar um episódio, apontando para o PRÓXIMO
  (sem barra de progresso). Ao terminar o último episódio (ou um filme), sai da lista. Abrir um item dessa lista
  já mostra a escolha de fonte do episódio certo; Voltar mostra todos os episódios.
- **Busca:** teclado totalmente próprio (a tela inteira recebe as teclas do controle, sem pulos de foco);
  cursor translúcido e legível; espaço funcionando, com atalhos: voltar-rápido apaga, avançar-rápido dá espaço,
  Play ou a tecla Ver (ou Direita na última coluna) vai para os resultados; Voltar/Esquerda/Cima/`*` voltam ao teclado.
- **Capas:** a imagem tenta carregar de novo (até 3 vezes) quando falha.
- **Ajustes** (menu no topo): idioma da interface (Português/English/Español), retomar de onde parou,
  escolher a fonte automaticamente, limpar "Continuar assistindo" e restaurar os addons padrão.
  O idioma muda só a interface; descrições e títulos vêm do addon (o Cinemeta é em inglês; para outros idiomas
  adicione um addon de metadados configurado para o idioma desejado).
- **Filtros em Filmes e Séries:** chips "Catálogo" e "Gênero" (ou "Ano" no catálogo por ano) abaixo da barra de navegação.
  Com "Catálogo: Todos" o filtro de gênero vale para todas as linhas; escolhendo um catálogo, ele vira uma grade completa.
- O vídeo de teste também registra progresso, para você conseguir testar o "Continuar assistindo" sem um addon de streams.

## Correções da v1.2.1

- Textos cortados/embolados: a fonte Poppins tem linha ~50% mais alta que as fontes do sistema e várias caixas de texto
  eram baixas demais (título do banner, sinopse, títulos sob os posters, título do painel de fontes). Fontes e caixas foram reajustadas.
- Títulos das linhas ("Filmes - Popular" etc.) colados nos posters: mais espaço entre linhas (`rowSpacings`) e rótulo
  deslocado para cima (`rowLabelOffset`) em `components/HomeView.xml`.
- Teclas da busca mais largas para caber "Espaço"/"Limpiar" sem cortar.

## Correções da v1.1.2

- Busca: o MiniKeyboard nativo engolia as teclas Direita/Baixo e você não conseguia chegar aos resultados.
  Foi trocado por um teclado próprio (grade de teclas) que passa o foco para a lista de resultados.
- Redesign completo das telas (ver seção Visual).

## Observações

- Feito para UI em 1920x1080 (`ui_resolutions=fhd`); o Roku escala para 720p automaticamente.
- Se o rótulo de alguma linha do catálogo ficar sobreposto no seu aparelho, ajuste `rowSpacings` e `rowLabelOffset` em `components/HomeView.xml`.

## Nome e avisos

- "Kinora" é o nome do projeto; ele não tem relação com Roku, Stremio ou Nuvio. "Roku" é marca da Roku, Inc. e "Stremio" é marca de seus
  respectivos donos; o app apenas é compatível com o protocolo público de addons do Stremio.
- O projeto não inclui, hospeda nem indexa nenhum conteúdo de vídeo. As fontes vêm de addons que o próprio usuário adiciona,
  e o usuário é responsável por usar apenas conteúdo que tenha direito de assistir.
- Os dados salvos (addons, ajustes, histórico) ficam no registry do Roku na seção `kinora`; dados de versões antigas
  (seções `vitrine` e `brightscript`) são lidos automaticamente.

## Status

Projeto de estudo, ainda experimental: foi testado em poucos aparelhos Roku. Issues e sugestões são bem-vindas.

## Licença

Código sob licença MIT (arquivo `LICENSE`). A fonte Poppins mantém a SIL Open Font License 1.1 (`fonts/OFL.txt`).
Créditos e avisos em `NOTICE.md`.
