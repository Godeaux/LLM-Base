import * as CANNON from "cannon-es";
import { GameState } from "../state.js";
import { spawnEnemy } from "../entities/enemy.js";

const REPRIEVE_DURATION = 3;

export function updateWaves(state: GameState, world: CANNON.World, dt: number): void {
  if (state.tower.hp <= 0) return;

  const wave = state.wave;

  // In reprieve between waves
  if (wave.inReprieve) {
    wave.reprieveTimer -= dt;
    if (wave.reprieveTimer <= 0) {
      wave.inReprieve = false;
      startNextWave(state);
    }
    return;
  }

  // Spawn enemies for current wave
  if (wave.enemiesSpawned < wave.enemiesTotal) {
    wave.spawnTimer -= dt;
    if (wave.spawnTimer <= 0) {
      const enemy = spawnEnemy(state, world);
      state.enemies.push(enemy);
      wave.enemiesSpawned++;
      wave.enemiesRemaining++;
      // Spawn faster as wave progresses (ramp up to focal point)
      const progress = wave.enemiesSpawned / wave.enemiesTotal;
      wave.spawnTimer = wave.spawnInterval * (1 - progress * 0.6);
    }
  }

  // Check if wave is complete (all spawned and all dead)
  const aliveEnemies = state.enemies.filter((e) => e.alive).length;
  if (wave.enemiesSpawned >= wave.enemiesTotal && aliveEnemies === 0) {
    wave.inReprieve = true;
    wave.reprieveTimer = REPRIEVE_DURATION;
  }
}

function startNextWave(state: GameState): void {
  state.wave.number++;
  const n = state.wave.number;
  state.wave.enemiesSpawned = 0;
  state.wave.enemiesTotal = Math.floor(5 + n * 3 + n * n * 0.5);
  state.wave.spawnTimer = 0;
  state.wave.spawnInterval = Math.max(0.3, 1.5 - n * 0.08);
  state.wave.enemiesRemaining = 0;
}
