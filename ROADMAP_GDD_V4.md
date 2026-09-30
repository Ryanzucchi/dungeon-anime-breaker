# Roadmap de implementação — GDD v4

## Gerador procedural — módulos das etapas 1–10 implementados; gameplay ainda pendente de validação
- `MapGeneration/ThemeRegistry.lua` carrega ThemePacks pelo contrato, sem ramificações específicas do DragonWorld no gerador.
- `MapGeneration/Themes/DragonWorld/` separa paleta, biomas, props, landmarks, estruturas e regras ambientais.
- As fases declaram um biome id; o gerador atual resolve chão e rocha por `Config.MapTheme` e pelo biome da fase.
- `MapGraph` cria uma rota principal ascendente, nós tipados e desvios secretos/tesouro/puzzle determinísticos por seed; `RegionGenerator` produz regiões e pontos de entrada/saída.
- Cada região escolhe um dos 24 layouts catalogados e materializa pilares, divisórias, altares e cobertura sem bloquear os conectores.
- `HeightGenerator`, `TerrainGenerator` e `CliffGenerator` compõem elevação, terreno orgânico, plataformas, ravinas e bordas rochosas.
- `PathGenerator` e `ConnectorGenerator` conectam os centros aos acessos e unem as regiões com trilhas curvas, passagens, escadas e pontes.
- `LandmarkGenerator`, `PropClusters`, `PropScatter` e `VegetationScatter` decoram de acordo com os dados do ThemePack e com limites por região.
- `WaterGenerator` cria lagos/poças e água sob cruzamentos de rio com pontes; `SecretGenerator` adiciona baús/santuários interativos com recompensa.
- `DebugRenderer` expõe visualização opcional de regiões, grafo, conectores, zonas de spawn e áreas reservadas.
- `MapGenerator.generateMap` coordena as etapas e `DungeonGenerator.generate` mantém o contrato legado como adaptador.
- `Enemies:start` gera o mapa uma vez por run; a ativação dos encontros continua por proximidade ao longo do caminho contínuo.

### Otimização e validação
- Geração determinística por seed, separação entre geometria de gameplay e decoração visual, limites por região e streaming do Workspace preservado.
- A compilação Rojo valida a árvore e serialização do projeto. A run ainda precisa ser executada em Play no Studio para confirmar navegação, colisões e leitura visual.
- `Rest` cura ao ativar; `Puzzle` hoje é um santuário de interação e recompensa, não um desafio de lógica; `Vista` ainda não garante um mirante orientado para uma composição específica.

## Estado da base
- Rojo mapeia o place preservado e a base de combate para os serviços Roblox.
- Personagens, habilidades, supports, progressão individual e inventário já existem.
- Em Studio sem DataStore disponível, o perfil agora cai para progresso temporário em vez de interromper o servidor.

## Entrega atual: impacto visual de combate
- Reagir ao impacto de skills pesadas e ataques de boss com marcas temporárias no chão.
- Perfis visuais por personagem; níveis de impacto crescentes; qualidade Low/Medium/High.
- Toda geometria é local, sem colisão e com limite de peças e tempo de vida para preservar a navegação e performance.

## Entrega atual: dungeon ascendente e lobby
- Área de lobby separada da arena, com portal físico e interação Z/botão.
- Entrada e retorno de run posicionam o personagem corretamente; seleção de Main/Support fica no lobby.
- 25 regiões principais e desvios opcionais em um único mapa contínuo, gerados por seed e conectados por passagens físicas.
- 24 arranjos de gameplay por região; os encontros semialeatórios são ativados conforme o jogador se aproxima pelo caminho até a região do chefe.
- Dash segue a direção de movimento; animações procedurais locais cobrem idle, corrida, dash e ataques.
- Dash segue a direção de movimento; animações procedurais locais cobrem idle, corrida, dash e ataques.

## Próxima entrega: recompensas e variedade da run
1. Adicionar baús e eventos de sala com recompensas persistentes e prévia antes da escolha.
2. Criar ramificações reais do caminho e rotas que alterem encontros e recompensas.
3. Apresentar tela de resultados com XP, loot e caminho percorrido.
4. Validar solo e coop no Studio; ajustar navegação, câmera e duração da run com base nessa sessão.

## Depois da vertical slice
- Mastery e desafios por personagem; Awakening com mudança de kit e visual.
- Transformation collection, meter, duração e mastery.
- Blacksmith com salvage/craft/upgrade e affixes que mudam builds.
- Dificuldades e modifiers, coop de 1–4 jogadores, e modos de endgame.
- Tutorial, quests, social e monetização somente após o loop de gameplay estar validado.

## Critérios de aceite da dungeon slice
- Nenhuma rota bloqueia o caminho principal permanentemente.
- Uma run é completável solo, com sinais claros de objetivo e telegraph.
- Pelo menos uma escolha muda encontro/recompensa sem depender de monetização.
- Inimigos, VFX e debris têm limites configuráveis e são removidos entre salas.



