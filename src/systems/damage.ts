import * as CANNON from "cannon-es";
import { GameState, ProjectileState } from "../state.js";

export function checkProjectileHits(state: GameState): void {
  for (const proj of state.projectiles) {
    if (!proj.alive) continue;

    // Check if projectile hit the ground (for splash) — arcane bolts float, skip ground check
    if (proj.type !== "arcane" && proj.body.position.y < 0.3 && proj.body.velocity.y < 0) {
      if (proj.splashRadius > 0) {
        applySplashDamage(state, proj);
      }
      proj.alive = false;
      continue;
    }

    // Direct hit check
    const hitRadius = proj.type === "arrow" ? 0.7 : 1.0;

    for (const enemy of state.enemies) {
      if (!enemy.alive) continue;

      const dx = proj.body.position.x - enemy.body.position.x;
      const dy = proj.body.position.y - enemy.body.position.y;
      const dz = proj.body.position.z - enemy.body.position.z;
      const distSq = dx * dx + dy * dy + dz * dz;

      if (distSq < hitRadius * hitRadius) {
        applyDirectHit(state, proj, enemy);

        // Fireballs also splash on direct hit
        if (proj.splashRadius > 0) {
          applySplashDamage(state, proj, enemy.id);
        }

        proj.alive = false;
        break;
      }
    }
  }
}

function applyDirectHit(
  state: GameState,
  proj: ProjectileState,
  enemy: { id: number; body: CANNON.Body; hp: number; alive: boolean },
): void {
  enemy.hp -= proj.damage;

  // Knockback impulse from projectile velocity direction
  const vel = proj.body.velocity;
  const speed = vel.length() || 1;
  const knockDir = new CANNON.Vec3(
    vel.x / speed,
    0.4,
    vel.z / speed,
  );
  knockDir.normalize();
  knockDir.scale(proj.knockback, knockDir);
  enemy.body.applyImpulse(knockDir, enemy.body.position);

  if (enemy.hp <= 0) {
    killEnemy(state, enemy, knockDir);
  }
}

function applySplashDamage(
  state: GameState,
  proj: ProjectileState,
  excludeId?: number,
): void {
  const splashPos = proj.body.position;

  for (const enemy of state.enemies) {
    if (!enemy.alive || enemy.id === excludeId) continue;

    const dx = splashPos.x - enemy.body.position.x;
    const dy = splashPos.y - enemy.body.position.y;
    const dz = splashPos.z - enemy.body.position.z;
    const dist = Math.sqrt(dx * dx + dy * dy + dz * dz);

    if (dist < proj.splashRadius) {
      const falloff = 1 - dist / proj.splashRadius;
      const splashDamage = proj.damage * 0.5 * falloff;
      enemy.hp -= splashDamage;

      // Shockwave push: enemies get launched outward + upward
      const pushDir = new CANNON.Vec3(
        -(dx / (dist || 0.1)),
        0.6,
        -(dz / (dist || 0.1)),
      );
      pushDir.normalize();
      pushDir.scale(proj.splashForce * falloff, pushDir);
      enemy.body.applyImpulse(pushDir, enemy.body.position);

      if (enemy.hp <= 0) {
        killEnemy(state, enemy, pushDir);
      }
    }
  }
}

function killEnemy(
  state: GameState,
  enemy: { body: CANNON.Body; alive: boolean },
  knockDir: CANNON.Vec3,
): void {
  enemy.alive = false;
  state.wave.kills++;

  // Death launch
  enemy.body.applyImpulse(
    new CANNON.Vec3(
      knockDir.x * 2,
      15 + Math.random() * 10,
      knockDir.z * 2,
    ),
    enemy.body.position,
  );
  // Ragdoll spin
  enemy.body.angularVelocity.set(
    (Math.random() - 0.5) * 20,
    (Math.random() - 0.5) * 20,
    (Math.random() - 0.5) * 20,
  );
  enemy.body.linearDamping = 0.01;
}
