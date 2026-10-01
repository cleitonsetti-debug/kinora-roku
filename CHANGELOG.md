# Changelog

Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/).

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
