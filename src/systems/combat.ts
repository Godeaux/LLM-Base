import * as CANNON from "cannon-es";
import { EnemyState, GameState } from "../state.js";
import { fireProjectile } from "../entities/projectile.js";

export function updateTowerCombat(state: GameState, world: CANNON.World, dt: number): void {
  if (state.tower.hp <= 0) return;

  const aliveEnemies = state.enemies.filter((e) => e.alive);
  if (aliveEnemies.length === 0) return;

  // --- Fireball: slower, targets clusters for splash value ---
  state.tower.fireTimer -= dt;
  if (state.tower.fireTimer <= 0) {
    const target = findBestFireballTarget(aliveEnemies, state.tower.position);
    if (target) {
      const proj = fireProjectile(
        state, world,
        target.body.position.clone(),
        target.body.velocity.clone(),
        "fireball",
      );
      state.projectiles.push(proj);
    }
    state.tower.fireTimer = 1 / state.tower.fireRate;
  }

  // --- Arrow: faster, targets nearest enemy ---
  state.tower.arrowFireTimer -= dt;
  if (state.tower.arrowFireTimer <= 0) {
    const target = findNearestEnemy(aliveEnemies, state.tower.position);
    if (target) {
      const proj = fireProjectile(
        state, world,
        target.body.position.clone(),
        target.body.velocity.clone(),
        "arrow",
      );
      state.projectiles.push(proj);
    }
    state.tower.arrowFireTimer = 1 / state.tower.arrowFireRate;
  }
}

/** Pick the enemy near the densest cluster of other enemies (for splash value). */
function findBestFireballTarget(
  enemies: EnemyState[],
  towerPos: CANNON.Vec3,
): EnemyState | null {
  if (enemies.length <= 2) return findNearestEnemy(enemies, towerPos);

  let bestScore = -Infinity;
  let bestTarget: EnemyState | null = null;

  for (const candidate of enemies) {
    // Count neighbors within splash radius
    let neighbors = 0;
    for (const other of enemies) {
      if (other.id === candidate.id) continue;
      const dx = candidate.body.position.x - other.body.position.x;
      const dz = candidate.body.position.z - other.body.position.z;
      if (dx * dx + dz * dz < 25) neighbors++; // within 5 units
    }

    // Prefer clusters, but also prefer closer enemies (slight bias)
    const dx = candidate.body.position.x - towerPos.x;
    const dz = candidate.body.position.z - towerPos.z;
    const dist = Math.sqrt(dx * dx + dz * dz);
    const score = neighbors * 3 - dist * 0.1;

    if (score > bestScore) {
      bestScore = score;
      bestTarget = candidate;
    }
  }

  return bestTarget;
}

function findNearestEnemy(
  enemies: EnemyState[],
  towerPos: CANNON.Vec3,
): EnemyState | null {
  let nearest: EnemyState | null = null;
  let nearestDistSq = Infinity;

  for (const enemy of enemies) {
    const dx = enemy.body.position.x - towerPos.x;
    const dz = enemy.body.position.z - towerPos.z;
    const distSq = dx * dx + dz * dz;
    if (distSq < nearestDistSq) {
      nearestDistSq = distSq;
      nearest = enemy;
    }
  }

  return nearest;
}
