# Changelog

Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/).

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
