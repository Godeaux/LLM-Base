import * as CANNON from "cannon-es";
import { EnemyState, GameState } from "../state.js";

/**
 * Fire a chain lightning bolt from the tower to the nearest enemy,
 * then chain to nearby enemies. Instant hit — no physics projectile.
 */
export function fireLightning(state: GameState): void {
  const tower = state.tower;
  const aliveEnemies = state.enemies.filter((e) => e.alive);
  if (aliveEnemies.length === 0) return;

  // Find nearest enemy to tower
  const first = findNearest(aliveEnemies, tower.position);
  if (!first) return;

  const chainTargets: EnemyState[] = [first];
  const hit = new Set<number>([first.id]);

  // Chain to nearby enemies
  let current = first;
  for (let i = 1; i < tower.lightningChains; i++) {
    const next = findNearestExcluding(aliveEnemies, current.body.position, hit, tower.lightningChainRange);
    if (!next) break;
    chainTargets.push(next);
    hit.add(next.id);
    current = next;
  }

  // Apply damage and stun to all chained enemies
  for (const enemy of chainTargets) {
    enemy.hp -= tower.lightningDamage;
    enemy.stunTimer = Math.max(enemy.stunTimer, tower.lightningStunDuration);

    if (enemy.hp <= 0 && enemy.alive) {
      enemy.alive = false;
      state.wave.kills++;
      // Small upward launch on lightning kill
      enemy.body.velocity.set(
        (Math.random() - 0.5) * 4,
        6,
        (Math.random() - 0.5) * 4,
      );
    }
  }

  // Build visual arc: tower top -> enemy1 -> enemy2 -> ...
  const points: CANNON.Vec3[] = [new CANNON.Vec3(0, 6.5, 0)];
  for (const enemy of chainTargets) {
    points.push(enemy.body.position.clone());
  }

  state.lightningArcs.push({
    points,
    age: 0,
    maxAge: 0.25,
  });
}

/** Update lightning arc lifetimes, removing expired ones. */
export function updateLightningArcs(state: GameState, dt: number): void {
  for (let i = state.lightningArcs.length - 1; i >= 0; i--) {
    const arc = state.lightningArcs[i]!;
    arc.age += dt;
    if (arc.age >= arc.maxAge) {
      state.lightningArcs.splice(i, 1);
    }
  }
}

function findNearest(enemies: EnemyState[], pos: CANNON.Vec3): EnemyState | null {
  let best: EnemyState | null = null;
  let bestDist = Infinity;
  for (const e of enemies) {
    const dx = e.body.position.x - pos.x;
    const dz = e.body.position.z - pos.z;
    const d = dx * dx + dz * dz;
    if (d < bestDist) {
      bestDist = d;
      best = e;
    }
  }
  return best;
}

function findNearestExcluding(
  enemies: EnemyState[],
  pos: CANNON.Vec3,
  exclude: Set<number>,
  maxRange: number,
): EnemyState | null {
  let best: EnemyState | null = null;
  let bestDist = maxRange * maxRange;
  for (const e of enemies) {
    if (!e.alive || exclude.has(e.id)) continue;
    const dx = e.body.position.x - pos.x;
    const dz = e.body.position.z - pos.z;
    const d = dx * dx + dz * dz;
    if (d < bestDist) {
      bestDist = d;
      best = e;
    }
  }
  return best;
}
