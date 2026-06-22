# Dominó Dominicano

Aplicación móvil del juego de **Dominó Dominicano** desarrollada con Flutter.

Este proyecto sigue una metodología de desarrollo por fases, comenzando por el
motor de reglas y puntuación.

## Fases de desarrollo

1. **Fase 1 — Motor de reglas y puntuación** ✅
2. **Fase 2 — Motor de mesa y colocación de fichas** ✅
3. Fase 3 — Interfaz de usuario
4. Fase 4 — Partidas multijugador
5. Fase 5 — Bots y reconexión
6. Fase 6 — Persistencia y optimización

## Fase 1: Motor de reglas y puntuación

La Fase 1 implementa el núcleo lógico del juego en `lib/engine/`:

- **Modelos**: fichas, jugadores, equipos, movimientos y resultados de ronda.
- **Board**: representación de la mesa con colocación de fichas, extremos
  abiertos e inversión automática.
- **Round**: gestión de una ronda completa: reparto, orden de turnos,
  validación de jugadas, dominación, capicúa, tranque, pase redondo y
  bonificaciones de salida.
- **Game**: orquestación de la partida, puntuación por equipos, regla de los
  170 puntos y detección de victoria a 200 puntos.
- **Reglas de puntuación**: cálculo de puntos para dominación, capicúa,
  tranque, pases de salida y pase redondo.

### Reglas implementadas

- Partida con 4 jugadores en 2 equipos.
- Orden de turnos antihorario.
- Primera ronda inicia obligatoriamente con el doble seis.
- Rondas posteriores inician con el ganador de la ronda anterior.
- Validación de jugadas legales.
- Doble punta: cuando ambos extremos son iguales, la ficha debe colocarse por
  el lado derecho.
- Dominación y Capicúa (solo cuando los extremos son diferentes).
- Pases de salida con doble (30 / 60 puntos) y con ficha normal (60 puntos).
- Pase redondo (30 puntos).
- Tranque con comparación directa entre trancador y siguiente jugador.
- Regla de los 170 puntos para bonificaciones de pase.
- Victoria de la partida al alcanzar 200 puntos.

## Fase 2: Motor de mesa y colocación de fichas

La Fase 2 añade la capa geométrica sobre el `Board` lógico: dada la
secuencia de `Move` de una ronda, calcula la posición, orientación y
dimensiones de cada ficha para su renderizado en pantalla.

- **`TileGeometry`**: rectángulo de cada ficha, su centro, su orientación
  (`horizontal` / `vertical`) y sus dimensiones en píxeles.
- **`BoardLayout`**: clase que toma la lista de `Move` (incluyendo el flag
  `tileWasSwapped` calculado en el `Round`) y devuelve la lista de
  `TileGeometry` listos para dibujar.
- **Orientación de la primera ficha**: depende de quién realizó la salida
  (local/compañero vs. adversario) y de si la ficha es doble. La regla
  mantiene la "línea larga" de la ficha apuntando hacia el jugador local.
- **Dobles perpendiculares**: cualquier doble se coloca perpendicular a la
  ficha anterior, dejando ambas "orejas" libres.
- **Crecimiento en Z**: cuando la cadena llega al borde de la mesa, el
  extremo pivota 90° sobre la esquina de la última ficha para seguir
  creciendo. Si tras cuatro rotaciones no hay hueco, se lanza
  `StateError`.
- **Sin solapamientos**: la geometría se valida para que ninguna ficha
  pise a otra ni quede fuera de los límites del tablero.

### Fuente de verdad de la inversión

El `Board` y el `Round` calculan y persisten en cada `Move` el flag
`tileWasSwapped`, que indica si la ficha fue invertida para coincidir con
el extremo abierto. El `BoardLayout` consume ese flag a través de
`TileGeometry.move` y no recalcula la inversión.

### Limitaciones conocidas

- El crecimiento en Z prueba 4 rotaciones alrededor de la última ficha del
  extremo. Para mesas muy pequeñas podría no encontrar espacio antes de
  agotar los intentos. La interfaz lo detectará y mostrará un error.
- El layout no optimiza para minimizar el área ocupada; siempre crece en
  la dirección natural antes de girar.

## Ejecutar tests

```bash
flutter test
```

## Estructura del proyecto

```
lib/
├── engine/
│   ├── models/          # Entidades del dominio
│   ├── rules/           # Reglas de puntuación
│   ├── board.dart       # Lógica de la mesa (Fase 1)
│   ├── board_layout.dart# Geometría visual de la mesa (Fase 2)
│   ├── round.dart       # Lógica de una ronda
│   └── game.dart        # Lógica de la partida
test/
└── engine/              # Tests unitarios del motor
```
