# Changelog

Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/).

## [1.5.2]

### Adicionado
- **Atualização automática (pelo computador):** `tools/auto-update.sh` consulta as releases do GitHub, baixa o zip, confere
  que o `manifest` está na raiz e instala no Roku pelo modo desenvolvedor. Não instala enquanto um vídeo está tocando.
  `--setup` guarda o IP e a senha só neste computador, `--install-timer` verifica sozinho a cada 30 minutos (systemd de
  usuário) e `--remove-timer` desliga.
- **Aviso de versão nova dentro do app:** ao abrir, o Kinora consulta as releases e avisa uma vez por versão. Em
  Ajustes > Sobre e ajuda há "Verificar atualização" (o valor mostra a versão instalada).
- O manifest ganhou `kinora_release` (versão da release, usada na comparação).

## [1.5.1]

### Corrigido
- **Travadas:** o banner (carrossel, zoom e transições) continuava rodando escondido enquanto o vídeo tocava; agora para
  e solta as imagens de fundo. A tela inicial cria só as linhas próximas (antes criava todas) e os nós são montados
  sob demanda. As sobreposições de gradiente e de brilho usam imagens pequenas esticadas (antes eram texturas de tela cheia).
  O zoom do banner agora começa desligado (Ajustes > Geral).
- **Perfil infantil:** criar perfil e escolher o tipo usa um menu do próprio app (sem diálogos encadeados); o menu do perfil
  ganhou "Entrar neste perfil" (antes, em Gerenciar perfis, não havia como entrar). Sair de um perfil infantil para um perfil
  de adulto pede o PIN, se houver.

### Alterado
- Posters maiores (200x300), selos arredondados no banner (tipo, IMDb), teclas e chips de vidro, indicador de carregamento.

## [1.5.0]

### Adicionado
- **Perfis ("Quem está assistindo?")**: cada perfil tem histórico, Minha lista, assistidos, buscas, legendas lembradas e
  ajustes próprios. Perfil infantil (conteúdo adulto sempre oculto; Ajustes e Addons só com PIN). Criar, renomear,
  alternar infantil e excluir. Os dados de antes viram o perfil "Principal"; o nome do perfil ativo aparece na barra do topo.
- **Visual mais cinematográfico**: luz ambiente colorida que muda com cada título, zoom lento no banner, barra de navegação
  em vidro com indicador colorido e cartões de vidro nas telas internas.
- **Continuar / Assistir com um clique** no banner: abre a ficha, escolhe a fonte (a mesma de antes, se houver) e já toca.
- **Addons**: cartões com o ícone do addon (logo do manifest ou inicial colorida), status, painel de detalhes e botões
  Ativar/Desativar, **Atualizar** (busca o manifest de novo e mostra a versão antiga e a nova), **Configurar**
  (mostra o endereço da página de configuração do addon) e Remover (com confirmação). "Atualizar todos" no topo.
- **Ajustes** completos em categorias (Geral, Reprodução, Legendas e áudio, Segurança e conteúdo, Perfis, Dados, Sobre e ajuda),
  cada linha com descrição e valor: banner animado, zoom, luz ambiente, salto de 10/15/30 s, limpar Minha lista/pesquisas/
  assistidos, restaurar ajustes e atalhos do controle.

### Alterado
- A imagem de fundo do banner é buscada no addon quando falta (histórico e Minha lista são entradas enxutas).
- O histórico guarda a fonte (addon) usada para retomar do mesmo lugar.

## [1.4.0]

### Adicionado
- **Player no estilo Netflix/YouTube:** Esquerda/Direita pulam na hora (10 s, acelerando se repetir) mostrando só a barra
  vermelha com os tempos, sem título nem botões; pausar com OK também mostra só a barra e o ícone grande de pausa;
  os controles completos (ícones, legendas, áudio, próximo episódio, fonte) abrem com Baixo. O botão "Ir para"
  (ou Cima nos controles) permite escolher um ponto e confirmar com OK. Indicador de carregamento girando.
- **Troca automática de fonte:** se o vídeo der erro ou demorar mais de 30 s, o player tenta a próxima fonte da lista.
- **Qualidade preferida** (Automática, 1080p, 720p, 480p) ordena as fontes e vale para a escolha automática.
- **Minha lista:** botão na ficha do título e linha própria na tela inicial.
- **Episódios assistidos:** barra cheia nos assistidos e barra parcial nos em andamento, nos cartões de episódio.
- **Pesquisas recentes** na busca.
- **Ficha do título** com elenco, direção e duração.
- **Legenda e áudio lembrados por título.**
- **Ocultar conteúdo adulto** (ligado por padrão) e **bloqueio por PIN** de Ajustes e Addons.
- **Diagnóstico e autoteste** em Ajustes: versão, aparelho, status dos addons, últimos erros de rede (sem expor os
  endereços de configuração) e um autoteste que confere as funções do app no próprio Roku.
- **Adicionar addon pelo computador ou celular:** `tools/add-addon.sh` e `tools/add-addon.html` enviam a URL ao Roku
  por rede local; a TV pede confirmação.
- Catálogos guardados em memória por 5 minutos (tela inicial mais rápida).
- Ferramentas do repositório: `tools/package.sh`, `tools/install.sh`, `tools/lint.py`, GitHub Actions (checagem a cada
  push e release automática ao criar uma tag), `CONTRIBUTING.md` e guia de capturas de tela.

### Alterado
- `HomeView.brs` dividido em `HomeView`, `HomeHero` e `HomeFilters`.
- O histórico de "Continuar assistindo" guarda entradas mais enxutas (a sinopse é buscada quando necessária).

## [1.3.0]

### Adicionado
- Player próprio: a tecla Baixo (ou Cima/`*`) mostra a barra de controles com progresso, tempo e botões
  (-10 s, pausar, +10 s, legendas, áudio, próximo episódio, fonte). Com os controles escondidos, OK pausa e
  Esquerda/Direita pulam 10 s. Legendas do próprio stream e de addons com o recurso `subtitles`, escolha de faixa
  de áudio e detalhes do addon e da fonte em uso.
- Botão **Detalhes** redesenhado no carrossel (pílula de 320x72 com ícone e texto centralizados; vidro em repouso,
  branca com texto escuro em foco). O banner ficou mais arejado (sinopse em 2 linhas). Navegação: barra, filtros, botão, linhas.
- Ficha de abertura no player: ao iniciar o vídeo aparecem por 7 s o título, a nota do IMDb, a classificação indicativa
  (quando o addon fornecer; o Cinemeta não traz), o ano e os gêneros. Dá para desligar em Ajustes.
- Player: barra de tempo ajustável. Esquerda/Direita, mesmo com os controles escondidos, abrem a barra e movem o ponto
  com passos que aceleram (10, 20, 30, 60, 90, 120 s); um balão mostra o tempo de destino. OK confirma, Voltar cancela,
  e parado por 3 s ele confirma sozinho. Também dá para entrar por Cima nos controles ou pelo botão "Ir para".
- Player com visual novo: ícones (retroceder, pausar/continuar, avançar, legendas, áudio, próximo episódio, fonte),
  barra de progresso arredondada com bolinha e ícone grande de pausa/continuar no centro da tela.
- Tela inicial com carrossel de destaques: o banner gira sozinho (com fade) entre títulos em destaque enquanto o foco
  está na barra ou nos filtros; ao entrar nas linhas, o banner acompanha o poster em foco. A tecla Play abre o destaque atual.
- Episódios seguintes: perto do fim aparece um cartão com contagem, e o próximo episódio começa sozinho
  (preferindo a mesma fonte); OK no cartão assiste na hora.
- Ajustes: idioma preferido da legenda, idioma preferido do áudio e próximo episódio automático.
- Tela de Addons com painel de detalhes (versão, descrição, tipos, recursos, catálogos e endereço).
- Tela inicial com linhas extras de filmes por gênero (Ação, Comédia, Terror, Ficção científica).

### Corrigido
- Filmes sem sinopse: a ficha do filme e o banner da tela inicial agora buscam o meta completo do addon quando a
  sinopse não vem no catálogo, e mostram "Sinopse indisponível." se o addon realmente não tiver.

## [1.2.1]

### Corrigido
- Nomes do menu e títulos das linhas apareciam como chaves de tradução (`nav_home`, `kind_movie_p`):
  a função de tradução tinha o mesmo nome de uma função nativa do BrightScript (`Tr`) e foi renomeada.
- Títulos das linhas ("Filmes - Popular" etc.) ficavam atrás dos posters a partir da segunda linha.
  Agora cada linha desenha o próprio título em posição fixa, e a rolagem vertical é feita pelo app.

### Adicionado
- Ajustes > Sobre mostra a versão instalada, para facilitar relatos de erro.
- Modelos de relato de erro e de sugestão no GitHub.

## [1.2.0]

### Adicionado
- Interface escura com banner em destaque, posters arredondados e barra de navegação no topo.
- Busca com teclado próprio.
- "Continuar assistindo": séries continuam apontando para o próximo episódio.
- Ajustes: idioma da interface (português, inglês, espanhol), retomar de onde parou, escolher a fonte automaticamente,
  limpar o histórico e restaurar os addons padrão.
- Filtros por catálogo e por gênero/ano em Filmes e Séries.
- Gerenciador de addons: adicionar por URL, ativar/desativar e remover.
- Nova tentativa de carregamento quando a imagem de uma capa falha.

## Versões anteriores

Versões de desenvolvimento, sem tag: catálogos e busca via addons no protocolo Stremio, temporadas e episódios,
escolha de fonte e player.
