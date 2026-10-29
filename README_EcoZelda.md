# EcoZelda: El Despertar del Ecosistema

Serious game de acción-aventura top-down 2D (Godot 4.7) basado en el GDD del proyecto.
Se construyó dentro de este mismo proyecto, reutilizando el Link, el Octorok y el Moldorm que ya existían.
La escena anterior (`Scenes/World/Scene_Game.tscn`) no se modificó.

## Flujo del juego (storyboard)
1. **Título** → ENTER.
2. **Trivia inicial**: 3 preguntas rápidas A/B/C/D sobre reciclaje (no se muestra si acertaste).
3. **Mundo** (3 zonas, cámara por pantallas como el Zelda clásico):
   - El anciano explica las canecas y los controles.
   - Eliges el color de caneca en la **barra inferior** (siempre visible) y recoges la basura con la **pinza**.
	 Si la caneca no corresponde al residuo, aparece un **error** (−5 puntos) y el residuo se queda.
   - Cada residuo bien clasificado **limpia el mapa** alrededor (los tiles pasan de contaminados a limpios).
	 Lo que se limpia no vuelve a ensuciarse, aunque regreses a la zona.
   - Al clasificar toda la basura de la zona sale el aviso **"¡Amenaza inminente!"**: la pinza se cambia por la
	 **espada** y aparecen los enemigos. Al derrotarlos, toda la zona se restaura, la barrera de basura se abre
	 y vuelves a tener la pinza.
4. **Zona 3**: al derrotar al Gusano de Basura revive el **Árbol Sagrado**.
5. **Trivia final**: las mismas 3 preguntas, esta vez con la respuesta correcta y una explicación.
6. **Resultados**: trivia inicial contra final, residuos por tipo, errores, enemigos, puntaje y tiempo.

## Controles
| Acción | Tecla |
|---|---|
| Moverse | WASD / flechas |
| Pinza / Espada | ESPACIO (`ATAQUE`) |
| Elegir caneca | 1-4, Q/E o clic en la barra inferior |
| Hablar / continuar diálogos | ENTER (`ACEPTAR`) |

## Código de colores usado
AZUL = Plástico · GRIS = Papel y cartón · VERDE = Orgánico · AMARILLA = Metal

## Zonas
| Zona | Residuos | Amenaza |
|---|---|---|
| 1. Bosque Sucio | plástico, papel, orgánico (9) | 2 Monstruos Plásticos (Octorok que dispara tapas) |
| 2. Río de Lodo | aparecen los metales (10) | Espectro de Lodo (persigue y lanza lodo) + 1 Octorok |
| 3. Claro del Árbol | los 4 tipos (12) | Gusano de Basura (usa el script del Moldorm) |

## Estructura
```
Assets/EcoZelda/        PNG pixel art, tileset.tres (fila 0 contaminada / fila 1 limpia), tema.tres
Scenes/EcoZelda/
  World/mundo.tscn      Suelo (TileMapLayer), Zonas/Zona1..3 (Basura, Amenaza, Barrera, Entrada, MurosEnemigos),
						Guia, Player, Camera2D, Efectos, HUD
  Player/eco_player.tscn   AnimatedSprite2D (animaciones del Link original), Pinza, AreaPinza, AreaEspada, Hurtbox
  Enemies/              octorok_plastico, espectro_lodo, gusano_basura
  Objetos/              basura (tipo/variante editables en el Inspector), barrera, arbol_sagrado, proyectil, destello
  NPC/guia.tscn         Anciano (los diálogos se editan en el Inspector)
  UI/                   titulo, trivia, hud, resultados
Scripts/EcoZelda/       game_manager.gd (autoload GameManager) y un script por escena
```

### Cómo editar
- **Mover o agregar basura**: abre `mundo.tscn` → `Zonas/ZonaN/Basura`, duplica un residuo y cambia `tipo`/`variante`.
- **Cambiar enemigos**: colócalos dentro de `Zonas/ZonaN/Amenaza` (ese nodo está apagado hasta que aparece la amenaza).
- **Repintar el mapa**: nodo `Suelo`. Pinta con la fila de arriba del tileset (contaminada): el juego la cambia sola
  por la fila de abajo (limpia) cuando se recicla.
- **Preguntas de la trivia**: `PREGUNTAS` en `Scripts/EcoZelda/game_manager.gd`.

### Ajustes del proyecto que cambiaron
- Escena principal: `Scenes/EcoZelda/UI/titulo.tscn`.
- Viewport 256×240 (antes 256×176) para dejar espacio al HUD superior y a la barra de canecas; ventana 768×720.
- Nuevas acciones: `CANECA_1..4`, `CANECA_SIGUIENTE` (E), `CANECA_ANTERIOR` (Q), `ACEPTAR` (Enter).
- Autoload `GameManager` y tema `Assets/EcoZelda/tema.tres`.
