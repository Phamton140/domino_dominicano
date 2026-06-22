# Dominó Dominicano

Aplicación móvil del juego de **Dominó Dominicano** desarrollada con Flutter.

Este proyecto sigue una metodología de desarrollo por fases, comenzando por el
motor de reglas y puntuación.

## Fases de desarrollo

1. **Fase 1 — Motor de reglas y puntuación** ✅
2. Fase 2 — Motor de mesa y colocación de fichas
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
│   ├── board.dart       # Lógica de la mesa
│   ├── round.dart       # Lógica de una ronda
│   └── game.dart        # Lógica de la partida
test/
└── engine/              # Tests unitarios del motor
```
