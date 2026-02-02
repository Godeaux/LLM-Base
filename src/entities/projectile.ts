import * as CANNON from "cannon-es";
import { GameState, ProjectileState, nextEntityId } from "../state.js";
import { GROUP_ENEMY, GROUP_GROUND, GROUP_PROJECTILE } from "../systems/physics.js";

export function fireProjectile(
  state: GameState,
  world: CANNON.World,
  targetPos: CANNON.Vec3,
): ProjectileState {
  const origin = new CANNON.Vec3(0, 6, 0); // top of tower

  // Calculate launch velocity for an arcing trajectory
  const dx = targetPos.x - origin.x;
  const dy = targetPos.y - origin.y;
  const dz = targetPos.z - origin.z;
  const horizDist = Math.sqrt(dx * dx + dz * dz);

  const speed = state.tower.projectileSpeed;
  // Launch at ~45 degrees for a nice arc, adjusted for distance
  const launchAngle = Math.min(Math.PI / 3, Math.max(Math.PI / 6, Math.atan2(horizDist, 10)));
  const vy = Math.sin(launchAngle) * speed;
  const hSpeed = Math.cos(launchAngle) * speed;

  const dirX = horizDist > 0.1 ? (dx / horizDist) * hSpeed : 0;
  const dirZ = horizDist > 0.1 ? (dz / horizDist) * hSpeed : 0;

  const body = new CANNON.Body({
    mass: 1,
    shape: new CANNON.Sphere(0.3),
    position: origin.clone(),
    velocity: new CANNON.Vec3(dirX, vy, dirZ),
    collisionFilterGroup: GROUP_PROJECTILE,
    collisionFilterMask: GROUP_ENEMY | GROUP_GROUND,
    linearDamping: 0.01,
  });

  world.addBody(body);

  return {
    id: nextEntityId(),
    body,
    alive: true,
    damage: state.tower.damage,
    knockback: 18,
    age: 0,
    maxAge: 5,
  };
}

export function updateProjectiles(state: GameState, dt: number): void {
  for (const proj of state.projectiles) {
    if (!proj.alive) continue;
    proj.age += dt;
    if (proj.age > proj.maxAge || proj.body.position.y < -1) {
      proj.alive = false;
    }
  }
}

export function checkProjectileHits(state: GameState): void {
  for (const proj of state.projectiles) {
    if (!proj.alive) continue;

    for (const enemy of state.enemies) {
      if (!enemy.alive) continue;

      const dx = proj.body.position.x - enemy.body.position.x;
      const dy = proj.body.position.y - enemy.body.position.y;
      const dz = proj.body.position.z - enemy.body.position.z;
      const distSq = dx * dx + dy * dy + dz * dz;

      // Hit radius: projectile sphere (0.3) + enemy box (~0.5)
      if (distSq < 1.0) {
        // Apply damage
        enemy.hp -= proj.damage;

        // Apply knockback impulse — this is the juice
        const dist = Math.sqrt(distSq) || 0.1;
        const knockDir = new CANNON.Vec3(dx / dist, 0.4, dz / dist);
        knockDir.normalize();
        knockDir.scale(proj.knockback, knockDir);
        enemy.body.applyImpulse(knockDir, enemy.body.position);

        if (enemy.hp <= 0) {
          enemy.alive = false;
          state.wave.kills++;
          // Death impulse — launch them
          enemy.body.applyImpulse(
            new CANNON.Vec3(
              knockDir.x * 2,
              15 + Math.random() * 10,
              knockDir.z * 2,
            ),
            enemy.body.position,
          );
          // Spin on death
          enemy.body.angularVelocity.set(
            (Math.random() - 0.5) * 20,
            (Math.random() - 0.5) * 20,
            (Math.random() - 0.5) * 20,
          );
          enemy.body.linearDamping = 0.01;
        }

        proj.alive = false;
        break;
      }
    }
  }
}
