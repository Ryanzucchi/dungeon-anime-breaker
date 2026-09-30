# Quebra-Masmorras de Anime — Rojo

O lugar exportado `place.rbxl` foi preservado. A V1.1 foi integrada de forma aditiva ao mapeamento original do Rojo, nos serviços ReplicatedStorage, ServerScriptService e StarterGui. Assim, o projeto mantém os arquivos do lugar e inclui a base de combate, interface, coleção, equipamentos e salvamento da V1.1.

## Abrir e conectar

1. Abra `place.rbxl` no Roblox Studio.
2. Inicie `Iniciar Rojo.bat` nesta pasta e mantenha o servidor ativo.
3. No Studio, use **Plugins → Rojo** e conecte a `localhost:34872`.
4. Pressione **Play** para iniciar no lobby. Use Z perto do portal ou o botão **Entrar na dungeon**. As alterações sincronizam pelo Rojo.

O Rojo sincroniza a árvore deste projeto, por isso use o `default.project.json` desta pasta. A pasta `src` contém tanto a exportação do lugar quanto a implementação da V1.1 encaixada nos serviços existentes. O arquivo `build.rbxlx` é apenas uma saída gerada; o lugar exportado para abrir é `place.rbxl`.

Se o Roblox Studio reiniciar ao conectar, não continue reconectando. Confira o log e reabra o place preservado antes de tentar novamente.
## Organização de personagens e efeitos

- Personagens: `src/ReplicatedStorage/Breakmasmorras/characters/<rarity>/<id>/character.json` contém identidade e atributos; `configs.json` contém passiva, Support e habilidades.
- Inimigos: `src/ReplicatedStorage/Breakmasmorras/enemies/<family>/<id>/enemy.json` contém identidade/tipo/cor; `configs.json` guarda atributos de combate. `EnemyCatalog.lua` valida e carrega os tipos.
- Comportamentos de inimigo: `src/ServerScriptService/Breakmasmorras/EnemyLogic/<type>/init.lua` define movimento e perfil de ataque para cada tipo sem concentrar seus números no controlador de salas.
- Para adicionar um inimigo, crie sua identidade/configuração na família apropriada, adicione o comportamento com o `LogicId` correspondente e inclua seu `Type` nos pools de `DungeonPhases.lua`.
- ThemePacks: `src/ReplicatedStorage/Breakmasmorras/MapGeneration/Themes/<ThemeId>/` implementa o contrato de paleta, biomas, props, landmarks, estruturas e regras. `ThemeRegistry.lua` descobre e valida os packs.
- O gerador recebe `MapTheme` de `Config.lua` e o `Biome` declarado na fase; o core não verifica nomes de temas nem contém regras exclusivas do DragonWorld.
- O carregador `Characters.lua` percorre as pastas de raridade, monta o catálogo e valida que cada habilidade, passiva e Support aponta para um efeito existente.
- Raridades previstas: `common`, `uncommon`, `rare`, `epic`, `legendary`, `mythic`, `celestial`, `transcendent`, `secret` e `limited`. O elenco atual usa `common/iruko`, `uncommon/renli`, `uncommon/kurino` e `rare/gaoro`.
- Efeitos: `src/ReplicatedStorage/Breakmasmorras/effects/<id>/` contém `config.json`, `logic/init.lua` e a pasta `visual_particles` para assets. Crie um efeito novo quando nenhum existente cobrir o comportamento necessário.
- Habilidades usam `Effect`, passivas usam `PassiveEffect` e Supports usam `Effect` em `configs.json`. O dash global usa `DashEffect` em `Config.lua`.
- `effects/Renderer.lua` reúne a renderização visual comum; os dados e comportamentos de cada efeito ficam em suas próprias pastas.
- Não substitua o mapeamento do place por um projeto independente: estes caminhos ficam dentro dos serviços já mapeados pelo `default.project.json`.
- As passivas também apontam para efeitos (discipline, rhythm, sand, precision); o dash global usa DashEffect = "evade" e mantém distância, recarga e invulnerabilidade na configuração do efeito.

## Impacto visual de cenário (GDD v4)

- O efeito `scenery_impact` mantém `config.json`, `logic/init.lua` e `visual_particles/` em `src/ReplicatedStorage/Breakmasmorras/effects/`.
- Skills F usam impacto nível 2; ultimates G usam nível 3; ataques inimigos/boss também deixam marcas temporárias.
- Perfis visuais por personagem ficam em `configs.json` (`ImpactProfile`).
- A renderização acontece só no cliente, com peças ancoradas sem colisão, limite de 180 peças e remoção após alguns segundos.
- A qualidade padrão é Medium. Um cliente pode definir o atributo `DestructionQuality` como `Low`, `Medium` ou `High`.
- O plano de entregas baseado no GDD v4 está em `ROADMAP_GDD_V4.md`.

## Lobby e progressão ascendente

- `World.lua` monta um lobby independente com portal, pontos de coleção, summon, build e treino.
- O portal aceita Z, gamepad e toque; a interface também pode iniciar a entrada.
- `DungeonPhases.lua` define cinco fases; cada uma cobre cinco regiões principais, até a arena do chefe.
- `MapGeneration/MapGenerator.lua` monta, por seed, um grafo de rota principal e desvios opcionais; `DungeonGenerator.lua` conserva a API antiga como adaptador.
- Cada região escolhe um entre 24 arranjos de gameplay e usa os dados do ThemePack para montar relevo, terreno, estruturas, rochas e vegetação.
- ThemeRegistry/DragonWorld fornece biomas, paletas, landmarks, estruturas e regras ambientais consumidos pelos módulos genéricos.
- As 25 regiões são geradas de uma vez no mesmo mapa contínuo, com relevo, cliffs, trilhas, conectores e decoração; não há teleporte nem carregamento entre regiões durante a run.
- Desvios de tesouro usam ProximityPrompt e concedem ouro ao participante que abrir o baú.
- Os encontros são semialeatórios e ativados conforme o jogador se aproxima das áreas; o chefe fica no fim do percurso.
- `Enemies.lua` distribui grupos semialeatórios por sala e mantém elites, mini-chefe e chefe do cume.
- Dash usa a direção do movimento; `Animator.lua` aplica animações procedurais locais de idle, corrida, dash, ataque e skill.
- O servidor controla participantes, teleporte apenas na entrada/retorno, respawn e fim da run; o cliente exibe sala e região.
- Bosses e elites pagam recompensas diferentes; a conclusão da run dá o loot especial do chefe final.
