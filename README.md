# Kinora - canal Roku para filmes, séries e animes

**Kinora** é um canal SceneGraph (BrightScript) com catálogo real via **addons no protocolo Stremio** (padrão: Cinemeta),
busca, temporadas/episódios, escolha de fonte, player e "Continuar assistindo".

## O que há de novo na v1.5

Resumo do que foi adicionado nesta série (1.5.0, 1.5.1 e 1.5.2). Os detalhes por versão estão no `CHANGELOG.md`.

### Perfis ("Quem está assistindo?")
- Tela de escolha de perfil ao abrir o app (aparece quando existe mais de um perfil). Até **6 perfis**, cada um com
  avatar colorido e inicial.
- Cada perfil tem **histórico, Minha lista, episódios assistidos, buscas recentes, legendas/áudio lembrados e ajustes
  próprios**. Os addons e o PIN são compartilhados entre todos.
- **Perfil infantil:** conteúdo adulto sempre oculto e Ajustes/Addons bloqueados (pedem o PIN, se houver um; sem PIN,
  mostram um aviso para pedir a um adulto). Sair de um perfil infantil para um perfil de adulto pede o PIN, se houver.
- Criar, renomear, alternar infantil e excluir: tecla `*` na tela de perfis, ou **Ajustes > Perfis > Gerenciar perfis**.
  O menu de cada perfil tem "Entrar neste perfil".
- Os dados de antes da v1.5 viram o perfil **Principal** (nada se perde). O nome do perfil ativo aparece na barra do topo.

### Visual
- **Luz ambiente** colorida atrás do banner que muda com cada título (a cor sai do código do título, então é sempre a
  mesma para o mesmo filme) e **barra de navegação em vidro** com indicador colorido.
- **Cartões de vidro** nas telas de Addons, Ajustes e Perfis; posters maiores; selos arredondados (tipo, IMDb) no banner.
- **Zoom lento no banner** (efeito cinematográfico): começa **desligado**, ligue em Ajustes > Geral.
- **Continuar / Assistir com um clique** no banner: abre a ficha, escolhe a fonte (a mesma de antes, se houver) e já
  começa a tocar. O que você estava assistindo vai primeiro nos destaques.

### Player (estilo Netflix/YouTube)
- Esquerda/Direita **pulam na hora** (10, 15 ou 30 s, configurável; acelera se você repetir ou segurar) mostrando só a
  barra vermelha com os tempos. OK pausa mostrando só a barra e um ícone grande de pausa.
- **Baixo** abre os controles completos (-/+ salto, pausar, Ir para, legendas, áudio, próximo episódio, fonte).
  **Ir para** (ou Cima nos controles) escolhe um ponto na barra e confirma com OK.
- Não há miniaturas de quadro ao mover a barra: elas dependem de arquivos de pré-visualização que streams comuns não têm.

### Addons
- Cartões com o **ícone do addon** (logo do manifest ou uma inicial colorida), versão e status (ativo, desativado, sem conexão).
- Painel de detalhes e quatro botões: **Ativar/Desativar**, **Atualizar** (busca o manifest de novo e mostra a versão
  antiga e a nova), **Configurar** (mostra o endereço da página de configuração, só para addons que declaram uma;
  abra no celular ou computador) e **Remover** (com confirmação).
- No topo da lista: **Adicionar addon** e **Atualizar todos**.

### Ajustes
Sete categorias, cada linha com descrição e o valor em uma pílula:
- **Geral:** idioma, banner animado, zoom do banner, luz ambiente.
- **Reprodução:** retomar, escolher fonte automaticamente, qualidade preferida, próximo episódio automático, ficha ao
  iniciar, salto dos botões (10/15/30 s).
- **Legendas e áudio:** idioma preferido de cada um.
- **Segurança e conteúdo:** ocultar conteúdo adulto (travado em perfil infantil) e bloqueio por PIN.
- **Perfis:** trocar de perfil e gerenciar perfis.
- **Dados:** limpar Continuar assistindo, Minha lista, pesquisas recentes e episódios assistidos; restaurar addons padrão
  e restaurar ajustes padrão.
- **Sobre e ajuda:** verificar atualização, diagnóstico e autoteste, atalhos do controle e sobre.

### Atualização
- **Aviso dentro do app:** ao abrir, o Kinora consulta as releases do GitHub e avisa uma vez por versão nova. Também em
  Ajustes > Sobre e ajuda > Verificar atualização. O app **não instala nada sozinho**.
- **Atualização automática pelo computador:** `tools/auto-update.sh` (veja a seção "Atualização automática").

### Correções da 1.5.1
- **Travadas:** o banner (carrossel, zoom e transições) agora para e solta as imagens de fundo enquanto o vídeo toca;
  a tela inicial cria só as linhas próximas e monta o resto conforme você desce; gradientes e brilho usam imagens
  pequenas esticadas em vez de texturas de tela cheia.
- **Perfil infantil:** criar perfil e escolher o tipo usa um menu do próprio app (sem diálogos encadeados) e o menu do
  perfil ganhou "Entrar neste perfil".

## Instalar no Roku

1. No Roku: Home x3, Cima x2, Direita, Esquerda, Direita, Esquerda, Direita. Ative o Modo Desenvolvedor e defina a senha.
2. Gere o pacote (o `manifest` precisa ficar na raiz do zip):
   ```
   cd kinora-canal-roku
   sh tools/package.sh ../kinora.zip
   ```
3. Envie por `http://IP_DO_ROKU` (Upload > Install), ou por terminal:
   ```
   curl --user rokudev:SUA_SENHA --digest -F "mysubmit=Install" -F "archive=@../kinora.zip" http://IP_DO_ROKU/plugin_install
   ```
4. Logs em tempo real: `telnet IP_DO_ROKU 8085` (todo `print` e erro de BrightScript aparece ali).

## Atualização automática

O Roku não atualiza sozinho apps instalados pelo modo desenvolvedor (isso só existe para apps da loja oficial).
O que dá para fazer é o seu computador instalar a versão nova assim que ela sai no GitHub:

```
sh tools/auto-update.sh --setup           # IP do Roku e senha do modo desenvolvedor (ficam só neste computador)
sh tools/auto-update.sh                   # verifica agora e instala se houver versão nova
sh tools/auto-update.sh --install-timer   # verifica sozinho a cada 30 minutos
```

O computador precisa estar ligado e na mesma rede do Roku. Dentro do app, em **Ajustes > Sobre e ajuda > Verificar
atualização**, o Kinora avisa quando existe uma versão mais nova.

## Visual

Tema escuro estilo "AMOLED" (fundo quase preto, texto branco, sem cores berrantes), inspirado nos apps de catálogo
para TV do ecossistema Stremio/Nuvio: barra de navegação no topo, **banner do título em foco** (fundo, título,
metadados e sinopse mudam conforme você navega), posters com cantos arredondados e anel de foco branco,
barra de progresso nos itens de "Continuar assistindo", botão de assistir em pílula e episódios em cards com miniatura.
Na v1.5 ganhou luz ambiente colorida, barra de navegação e cartões em vidro (veja "O que há de novo na v1.5").
Fonte: Poppins (licença SIL OFL, embutida em `fonts/`).

## Como usar

- **Início / Filmes / Séries**: barra no topo; Baixo entra nas linhas de catálogo, Cima/Voltar volta à barra.
- **Buscar**: teclado próprio à esquerda; Direita (ou Baixo na última linha de teclas) passa para os resultados,
  Esquerda na primeira coluna dos resultados volta ao teclado. OK em um poster abre os detalhes.
- **Detalhes**: filmes têm o botão Assistir; séries/animes mostram chips de Temporada (Baixo vai para os episódios).
- **Fontes**: ao escolher Assistir/episódio, o app consulta os addons que têm o recurso `stream` e lista as fontes de vídeo direto (http/https).
  O último item da lista é sempre um **vídeo de teste** (Big Buck Bunny) para validar o player.
- **Addons** (menu): escolha um addon na lista e use os botões Ativar/Desativar, Atualizar, Configurar e Remover; "Adicionar addon" pede a URL do manifest (aceita `stremio://`) e "Atualizar todos" confere todos de uma vez.
- **Ajustes** (menu): categorias à esquerda, opções à direita; OK muda o valor da linha.
- **Perfis** (último item da barra do topo): escolher, criar e gerenciar perfis.
- **Player**: Esquerda/Direita pulam, OK pausa, Baixo abre os controles, Voltar sai.
- **Continuar assistindo**: o progresso é salvo a cada 15 s no registry do Roku e a reprodução retoma de onde parou.

## Sobre as fontes de vídeo

O Cinemeta só fornece catálogo e metadados, **não vídeo**. Para assistir de verdade, adicione um addon
que devolva links diretos (`url` http/https em `/stream/...`) e que você tenha direito de usar.
O Roku não reproduz torrent (`infoHash`) nem YouTube (`ytId`); essas fontes são ignoradas e contadas na mensagem do painel.

## Estrutura

```
manifest
source/      main.brs, Utils.brs, I18n.brs, Storage.brs, AddonStore.brs, Streams.brs, Subs.brs,
             Settings.brs, SelfTest.brs
components/  MainScene (pilha de telas, carrega addons, perfis e aviso de versão)
             HomeView, HomeRow, SearchView, DetailsView, PlayerView
             AddonsView, AddonItem            (addons com ícone e botões)
             SettingsView, SettingsCat, SettingRow   (ajustes em categorias)
             ProfileView, ProfileTile         (quem está assistindo)
             DiagView (diagnóstico e autoteste), JsonTask (rede em Task)
             PosterItem, NavItem, KeyItem, ChipItem, PlayerButton, PillButton, HeroButton (itens e botões)
images/      ícones, splash, gradientes, brilho, cartões e bitmaps 9-patch (foco, cantos, pílulas)
fonts/       Poppins (Regular, Medium, Bold)
tools/       package.sh, install.sh, auto-update.sh, add-addon.sh/.html, lint.py
```

## O que foi corrigido em relação à versão anterior

- Os componentes agora incluem os `.brs` de `source/` via `<script>` (antes davam "função não definida").
- Toda rede roda em `JsonTask` (Task) com certificados HTTPS; nada de `roUrlTransfer` na render thread.
- `roSGScreen` só é criado em `main.brs`; a navegação é uma pilha de views dentro de uma única Scene.
- Sem login obrigatório e sem a API "Nuvio" (os endpoints eram inventados). Addons e histórico ficam no registry local.
- Pasta `images/` criada, com todos os assets referenciados.
- Addons, catálogos, metadados, episódios e streams vêm de dados reais em vez de listas mockadas.
- `.env`, `CLAUDE.md`, `.bak` e `index.html` ficaram de fora do pacote.

## Novidades da v1.4

- **Player no estilo Netflix/YouTube:** Esquerda/Direita pulam na hora mostrando só a barra vermelha; OK pausa mostrando só a barra; Baixo abre os controles completos.
- **Troca automática de fonte** quando o vídeo falha, e **qualidade preferida** (1080p/720p/480p).
- **Minha lista**, episódios assistidos, pesquisas recentes, elenco e duração na ficha.
- **Ajustes:** ocultar conteúdo adulto, bloqueio por PIN e **Diagnóstico e autoteste**.
- **Adicionar addon de fora:** `sh tools/add-addon.sh IP_DO_ROKU URL` (a TV pede confirmação).
- **Para quem contribui:** `python3 tools/lint.py`, `sh tools/package.sh`, GitHub Actions e `CONTRIBUTING.md`.

## Ferramentas (pasta `tools/`)

| Arquivo | Para quê |
|---|---|
| `package.sh` | gera o zip de instalação (`sh tools/package.sh kinora.zip`) |
| `auto-update.sh` | instala sozinho no Roku a release mais nova do GitHub (veja "Atualização automática") |
| `install.sh` | baixa a última release e instala no Roku (`sh tools/install.sh IP SENHA`) |
| `add-addon.sh` / `add-addon.html` | enviam a URL de um addon ao Kinora aberto no Roku |
| `lint.py` | checagem estática do projeto |
| `open-good-first-issues.sh` | abre issues para novos colaboradores |

## Novidades da v1.3

- **Player próprio:** Baixo mostra os controles (progresso, -10 s, pausar, +10 s, legendas, áudio, próximo episódio e
  detalhes do addon/fonte); OK pausa e Esquerda/Direita pulam 10 s com os controles escondidos. Legendas do stream e de
  addons `subtitles`, faixas de áudio e episódios seguintes automáticos.
- **Destaques:** o banner da tela inicial gira sozinho entre títulos em destaque, como nos serviços de streaming, com um botão **Detalhes**.
- **Barra de tempo:** Esquerda/Direita no player abrem a barra e movem o ponto com passos que aceleram; OK confirma, Voltar cancela, e parado por 3 s confirma sozinho.
- **Ficha ao iniciar:** título, nota do IMDb e classificação indicativa (se o addon fornecer) aparecem por alguns segundos; dá para desligar em Ajustes.
- **Player com ícones:** botões com ícone, barra de progresso arredondada e ícone grande de pausa no centro.
- **Ajustes:** idioma preferido da legenda e do áudio, e próximo episódio automático.
- **Addons:** painel de detalhes de cada addon.
- **Tela inicial:** linhas de filmes por gênero; sinopse buscada sob demanda quando falta.

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

## Relatar erros e sugerir funções

Use as abas **Issues** (modelos prontos pedem o modelo do Roku, a versão do sistema e o log do console)
e **Discussions** do repositório. Não cite nomes nem links de addons que forneçam conteúdo pirata:
esses relatos serão fechados. O projeto não ajuda a encontrar addons ou fontes de vídeo.

## Status

Projeto de estudo, ainda experimental: foi testado em poucos aparelhos Roku. Issues e sugestões são bem-vindas.

## Licença

Código sob licença MIT (arquivo `LICENSE`). A fonte Poppins mantém a SIL Open Font License 1.1 (`fonts/OFL.txt`).
Créditos e avisos em `NOTICE.md`.
