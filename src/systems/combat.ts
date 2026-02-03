import * as CANNON from "cannon-es";
import { EnemyState, GameState, ProjectileType } from "../state.js";
import { fireProjectile } from "../entities/projectile.js";
import { fireLightning } from "./lightning.js";
import { spawnMinion, despawnMinion } from "../entities/minion.js";
import { MINION } from "../config.js";

/** Targeting strategy per projectile attack type. */
const TARGET_STRATEGY: Record<
  ProjectileType,
  (enemies: EnemyState[], pos: CANNON.Vec3) => EnemyState | null
> = {
  fireball: findBestFireballTarget,
  arrow: findNearestEnemy,
  arcane: findFarthestEnemy,
};

export function updateTowerCombat(state: GameState, world: CANNON.World, dt: number): void {
  if (state.tower.hp <= 0) return;

  const aliveEnemies = state.enemies.filter((e) => e.alive);
  if (aliveEnemies.length === 0) return;

  const attacks = state.tower.attacks;

  // --- Projectile attacks (fireball, arrow, arcane) ---
  for (const type of ["fireball", "arrow", "arcane"] as const) {
    const atk = attacks[type];
    if (!atk.enabled) continue;
    atk.fireTimer -= dt;
    if (atk.fireTimer <= 0) {
      const findTarget = TARGET_STRATEGY[type];
      const target = findTarget(aliveEnemies, state.tower.position);
      if (target) {
        const proj = fireProjectile(
          world,
          target.body.position.clone(),
          target.body.velocity.clone(),
          type,
          type === "arcane" ? target.id : undefined,
        );
        state.projectiles.push(proj);
      }
      atk.fireTimer = 1 / atk.fireRate;
    }
  }

  // --- Lightning: instant chain zap ---
  const lightning = attacks.lightning;
  if (lightning.enabled) {
    lightning.fireTimer -= dt;
    if (lightning.fireTimer <= 0) {
      fireLightning(state);
      lightning.fireTimer = 1 / lightning.fireRate;
    }
  }

  // --- Minions: spawn/despawn based on toggle ---
  const minionsAtk = attacks.minions;
  if (minionsAtk.enabled) {
    // Spawn up to desired count
    while (state.minions.length < MINION.count) {
      state.minions.push(spawnMinion(world));
    }
  } else {
    // Despawn all immediately
    for (const minion of state.minions) {
      despawnMinion(minion, world);
    }
    state.minions.length = 0;
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
    let neighbors = 0;
    for (const other of enemies) {
      if (other.id === candidate.id) continue;
      const dx = candidate.body.position.x - other.body.position.x;
      const dz = candidate.body.position.z - other.body.position.z;
      if (dx * dx + dz * dz < 25) neighbors++;
    }

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

/** Arcane bolt targets farthest enemy — it homes in, so distance doesn't matter for accuracy. */
function findFarthestEnemy(
  enemies: EnemyState[],
  towerPos: CANNON.Vec3,
): EnemyState | null {
  let farthest: EnemyState | null = null;
  let farthestDistSq = -1;

  for (const enemy of enemies) {
    const dx = enemy.body.position.x - towerPos.x;
    const dz = enemy.body.position.z - towerPos.z;
    const distSq = dx * dx + dz * dz;
    if (distSq > farthestDistSq) {
      farthestDistSq = distSq;
      farthest = enemy;
    }
  }

  return farthest;
}
