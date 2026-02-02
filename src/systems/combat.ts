import * as CANNON from "cannon-es";
import { GameState } from "../state.js";
import { fireProjectile } from "../entities/projectile.js";

export function updateTowerCombat(state: GameState, world: CANNON.World, dt: number): void {
  if (state.tower.hp <= 0) return;

  state.tower.fireTimer -= dt;
  if (state.tower.fireTimer > 0) return;

  // Find nearest alive enemy
  let nearestEnemy = null;
  let nearestDistSq = Infinity;

  for (const enemy of state.enemies) {
    if (!enemy.alive) continue;
    const dx = enemy.body.position.x - state.tower.position.x;
    const dz = enemy.body.position.z - state.tower.position.z;
    const distSq = dx * dx + dz * dz;
    if (distSq < nearestDistSq) {
      nearestDistSq = distSq;
      nearestEnemy = enemy;
    }
  }

  if (!nearestEnemy) return;

  // Lead the target slightly based on distance
  const dist = Math.sqrt(nearestDistSq);
  const leadTime = dist / state.tower.projectileSpeed * 0.5;
  const targetPos = new CANNON.Vec3(
    nearestEnemy.body.position.x + nearestEnemy.body.velocity.x * leadTime,
    nearestEnemy.body.position.y + 0.5,
    nearestEnemy.body.position.z + nearestEnemy.body.velocity.z * leadTime,
  );

  const proj = fireProjectile(state, world, targetPos);
  state.projectiles.push(proj);
  state.tower.fireTimer = 1 / state.tower.fireRate;
}
