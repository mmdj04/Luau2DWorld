# Luau2DWorld — Guia de Instalacao no Roblox Studio

## Tipos de Script

| Tipo | Sufixo | Onde roda |
|------|--------|-----------|
| **LocalScript** | `.client.lua` | Cliente (computador/jogador) |
| **ModuleScript** | `.lua` | Efecto de quem o require |
| **Script** | `.server.lua` | Servidor (Roblox) |

---

## Onde colocar cada ficheiro

### StarterGui (painel de UI)

Coloca **tudo** aqui dentro numa pasta chamada `Luau2DWorld`:

```
StarterGui
└── Luau2DWorld
    ├── Main.client.lua        ← LocalScript (entry point)
    └── Modules
        ├── UICamera.lua       ← ModuleScript
        ├── UITools.lua        ← ModuleScript
        ├── UIWorldRenderer.lua← ModuleScript
        ├── UIInventory.lua    ← ModuleScript
        ├── WorldGenerator.lua ← ModuleScript
        ├── PlayerController.lua← ModuleScript
        ├── CaveGenerator.lua  ← ModuleScript
        ├── LightingSystem.lua ← ModuleScript
        ├── HUD.lua            ← ModuleScript
        ├── Noise.lua          ← ModuleScript
        └── TileRenderer.lua   ← ModuleScript (legado)
```

---

## Passo a passo no Roblox Studio

1. **Abre** o Roblox Studio
2. **Cria** um novo Baseplate (ou abre o teu projecto)
3. No **Explorer**, expande `StarterGui`
4. Clica direito em `StarterGui` → **Insert Object** → **LocalScript**
5. Renomeia o LocalScript para `Main`
6. Clica direito no `Main` → **Insert Object** → **Folder**
7. Renomeia a Folder para `Modules`
8. Dentro de `Modules`, cria **11 ModuleScripts** (um por cada ficheiro .lua)
9. Copia o conteudo de cada ficheiro para o ModuleScript correspondente
10. Copia o conteudo de `Main.client.lua` para o LocalScript `Main`

### Atalho (ficheiros)

Se tiveres os ficheiros locais, podes arrastar directamente para o Explorer:

1. Arrasta a pasta `Luau2DWorld` inteira para dentro de `StarterGui`
2. Renomeia `Main.client.lua` para `Main` (o Studio reconhece o tipo pelo sufixo)
3. Pronto!

---

## Script Type Reference

| Ficheiro | Tipo no Studio | Notas |
|----------|---------------|-------|
| `Main.client.lua` | **LocalScript** | Entry point, corre no cliente |
| `UICamera.lua` | **ModuleScript** | Camera suave, shake, zoom |
| `UITools.lua` | **ModuleScript** | Utilitarios UI (lerp, tween, botoes) |
| `UIWorldRenderer.lua` | **ModuleScript** | Renderer chunk-based otimizado |
| `UIInventory.lua` | **ModuleScript** | Sistema de inventario |
| `WorldGenerator.lua` | **ModuleScript** | Geracao procedural de terreno |
| `PlayerController.lua` | **ModuleScript** | Movimento e fisica do jogador |
| `CaveGenerator.lua` | **ModuleScript** | Geracao de cavernas |
| `LightingSystem.lua` | **ModuleScript** | Fog-of-war / iluminacao |
| `HUD.lua` | **ModuleScript** | Barra de vida, minimapa |
| `Noise.lua` | **ModuleScript** | Perlin Noise FBM |
| `TileRenderer.lua` | **ModuleScript** | Renderer legado (opcional) |

---

## Controles do Jogo

| Tecla | Accao |
|-------|-------|
| WASD / Setas | Mover |
| Shift | Correr |
| Espaco | Pular |
| 1-9 | Selecionar slot do inventario |
