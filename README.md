# Quebra-Masmorras de Anime (Dungeon Anime Breaker)

Projeto de jogo para Roblox sincronizado via [Rojo](https://rojo.space/). Inclui sistema modular de masmorras procedurais, classes/personagens colecionáveis, efeitos de combate, lobby interativo, catálogo de inimigos e bosses, e destruição/impacto de cenário procedural.

---

## 🚀 Como Abrir e Conectar (Rojo)

1. Abra o arquivo `place.rbxl` no **Roblox Studio**.
2. Execute o script `Iniciar Rojo.bat` (ou execute `rojo serve default.project.json` no terminal).
3. No Roblox Studio, acesse a aba **Plugins → Rojo** e conecte na porta padrão `localhost:34872`.
4. Pressione **Play** (F5) para iniciar no lobby.
   - Aproxime-se do portal e pressione **Z** (ou use o botão da interface) para entrar na dungeon.
   - Qualquer alteração nos arquivos dentro de `src/` será sincronizada em tempo real com o Studio.

---

## 📁 Estrutura do Projeto

- **`src/`**: Código-fonte do jogo mapeado nos serviços do Roblox:
  - **`ReplicatedStorage/Breakmasmorras/`**:
    - `characters/`: Definições e atributos dos personagens por raridade (`common`, `uncommon`, `rare`, etc.).
    - `effects/`: Efeitos de combate, projéteis, partículas visuais e renderização (`Renderer.lua`).
    - `enemies/`: Catálogo e configurações de inimigos e chefes.
    - `MapGeneration/`: Geração procedural contínua do mapa, biomas, relevos e regras de salas.
    - `Config.lua`, `Progression.lua`, `Rules.lua`, `DungeonPhases.lua`.
  - **`ServerScriptService/Breakmasmorras/`**:
    - `EnemyLogic/`: Máquinas de estado e IA de inimigos e chefes.
    - `World.lua`, `Enemies.lua`, `DungeonPhases.lua`.
  - **`StarterGui/`**: Interface do usuário (HUD, inventário, seleção e menus).
  - **`StarterPlayer/`**: Controles locais, animações procedurais (`Animator.lua`) e movimentação/dash.
- **`default.project.json`**: Mapeamento do projeto Rojo para a árvore de instâncias do Roblox DataModel.
- **`place.rbxl`**: Place base preservado para sincronização com o Roblox Studio.
- **`ROADMAP_GDD_V4.md`**: Planejamento e especificações técnicas de design e roadmap (GDD v4).
- **`LEIA-ME.md`**: Guia técnico detalhado da arquitetura V1.1 e organização de personagens/efeitos.

---

## 🛠️ Tecnologias
- **Roblox Studio** & **Luau**
- **Rojo 7.x**