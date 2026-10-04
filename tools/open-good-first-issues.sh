#!/bin/sh
# Abre issues "good first issue" para atrair colaboradores. Requer o GitHub CLI logado (gh auth login).
# uso: sh tools/open-good-first-issues.sh
set -e
gh issue create --label "good first issue" --label "enhancement" --title "Opcao de texto maior (acessibilidade)" --body "Adicionar em Ajustes uma opcao de tamanho de texto (normal/grande) aplicada aos titulos e sinopses. Os tamanhos das fontes ficam nos arquivos .xml em components/."
gh issue create --label "good first issue" --label "enhancement" --title "Mostrar a qualidade (1080p/720p) como etiqueta na lista de fontes" --body "A funcao streamQuality em source/Utils.brs ja detecta a qualidade. Falta exibir uma etiqueta ao lado de cada fonte no painel de fontes (components/DetailsView.xml e DetailsView.brs)."
gh issue create --label "good first issue" --label "documentation" --title "Revisar as traducoes em ingles e espanhol" --body "Os textos ficam em source/I18n.brs (funcoes stringsEn e stringsEs). Revise e corrija o que soar estranho."
gh issue create --label "good first issue" --label "enhancement" --title "Adicionar mais idiomas de interface (ex.: frances)" --body "Criar uma funcao stringsFr em source/I18n.brs, incluir o codigo em langCodes e em buildStrings, e a chave lang_name. A checagem tools/lint.py confere se todas as chaves existem."
gh issue create --label "good first issue" --label "documentation" --title "Guia de instalacao com capturas de tela" --body "Ver docs/SCREENSHOTS.md para capturar telas limpas. Escrever um passo a passo ilustrado do Modo Desenvolvedor e da instalacao."
