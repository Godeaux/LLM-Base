import * as CANNON from "cannon-es";
import { GameState, ProjectileState, ProjectileType, nextEntityId } from "../state.js";
import { GROUP_ENEMY, GROUP_GROUND, GROUP_PROJECTILE } from "../systems/physics.js";

interface LaunchConfig {
  speed: number;
  damage: number;
  knockback: number;
  type: ProjectileType;
  splashRadius: number;
  splashForce: number;
  radius: number;
  mass: number;
  launchAngleMin: number;
  launchAngleMax: number;
  maxAge: number;
}

const FIREBALL_CONFIG: LaunchConfig = {
  speed: 20,
  damage: 2.5,
  knockback: 22,
  type: "fireball",
  splashRadius: 5,
  splashForce: 14,
  radius: 0.35,
  mass: 2,
  launchAngleMin: Math.PI / 5, // 36 deg — high arcs
  launchAngleMax: Math.PI / 3, // 60 deg
  maxAge: 6,
};

const ARROW_CONFIG: LaunchConfig = {
  speed: 45,
  damage: 1,
  knockback: 8,
  type: "arrow",
  splashRadius: 0,
  splashForce: 0,
  radius: 0.1,
  mass: 0.3,
  launchAngleMin: Math.PI / 12, // 15 deg — flat trajectories
  launchAngleMax: Math.PI / 5,  // 36 deg
  maxAge: 4,
};

/**
 * Iterative lead-target prediction.
 * Runs 3 iterations to converge on an intercept point, accounting for
 * the projectile's own flight time at each step.
 */
function predictIntercept(
  origin: CANNON.Vec3,
  targetPos: CANNON.Vec3,
  targetVel: CANNON.Vec3,
  projectileSpeed: number,
  gravity: number,
  launchAngle: number,
): CANNON.Vec3 {
  let predicted = targetPos.clone();

  for (let i = 0; i < 3; i++) {
    const dx = predicted.x - origin.x;
    const dz = predicted.z - origin.z;
    const horizDist = Math.sqrt(dx * dx + dz * dz);

    // Estimate flight time from horizontal component
    const hSpeed = Math.cos(launchAngle) * projectileSpeed;
    const flightTime = hSpeed > 0.1 ? horizDist / hSpeed : 1;

    // Also account for vertical: the projectile arcs up then down
    // under gravity, so actual flight time is slightly longer.
    // Use the quadratic: y = vy*t - 0.5*g*t^2, solve for t when y = targetY - originY
    const vy = Math.sin(launchAngle) * projectileSpeed;
    const dy = (targetPos.y + 0.5) - origin.y;
    // Approximate: flight time ~ 2*vy/g if target is at same height
    const vertFlightTime = vy > 0 ? (vy + Math.sqrt(Math.max(0, vy * vy + 2 * gravity * dy))) / gravity : flightTime;
    const estimatedTime = Math.min(flightTime, vertFlightTime);

    // Predict where enemy will be at that time
    predicted = new CANNON.Vec3(
      targetPos.x + targetVel.x * estimatedTime,
      targetPos.y + 0.5,
      targetPos.z + targetVel.z * estimatedTime,
    );
  }

  return predicted;
}

export function fireProjectile(
  _state: GameState,
  world: CANNON.World,
  targetPos: CANNON.Vec3,
  targetVel: CANNON.Vec3,
  type: ProjectileType,
  targetId?: number,
): ProjectileState {
  const origin = new CANNON.Vec3(0, 6.5, 0); // top of tower

  // Arcane bolt: no gravity, floaty launch toward target
  if (type === "arcane") {
    return fireArcaneBolt(world, origin, targetPos, targetId ?? null);
  }

  const config = type === "fireball" ? FIREBALL_CONFIG : ARROW_CONFIG;

  const dx = targetPos.x - origin.x;
  const dz = targetPos.z - origin.z;
  const horizDist = Math.sqrt(dx * dx + dz * dz);

  // Choose launch angle based on distance (farther = higher arc)
  const distFactor = Math.min(1, horizDist / 50);
  const launchAngle =
    config.launchAngleMin + (config.launchAngleMax - config.launchAngleMin) * distFactor;

  // Iterative lead prediction
  const predicted = predictIntercept(
    origin, targetPos, targetVel, config.speed, 20, launchAngle,
  );

  // Recalculate direction to predicted position
  const pdx = predicted.x - origin.x;
  const pdz = predicted.z - origin.z;
  const pHorizDist = Math.sqrt(pdx * pdx + pdz * pdz);

  const vy = Math.sin(launchAngle) * config.speed;
  const hSpeed = Math.cos(launchAngle) * config.speed;

  const dirX = pHorizDist > 0.1 ? (pdx / pHorizDist) * hSpeed : 0;
  const dirZ = pHorizDist > 0.1 ? (pdz / pHorizDist) * hSpeed : 0;

  const body = new CANNON.Body({
    mass: config.mass,
    shape: new CANNON.Sphere(config.radius),
    position: origin.clone(),
    velocity: new CANNON.Vec3(dirX, vy, dirZ),
    collisionFilterGroup: GROUP_PROJECTILE,
    collisionFilterMask: GROUP_ENEMY | GROUP_GROUND,
    linearDamping: type === "arrow" ? 0.005 : 0.01,
  });

  world.addBody(body);

  return {
    id: nextEntityId(),
    body,
    alive: true,
    damage: config.damage,
    knockback: config.knockback,
    age: 0,
    maxAge: config.maxAge,
    type: config.type,
    splashRadius: config.splashRadius,
    splashForce: config.splashForce,
    targetId: null,
  };
}

const ARCANE_SPEED = 12;
const ARCANE_STEER_FORCE = 280;

function fireArcaneBolt(
  world: CANNON.World,
  origin: CANNON.Vec3,
  targetPos: CANNON.Vec3,
  targetId: number | null,
): ProjectileState {
  // Initial launch: lob upward and vaguely toward target
  const dx = targetPos.x - origin.x;
  const dz = targetPos.z - origin.z;
  const dist = Math.sqrt(dx * dx + dz * dz) || 1;

  const body = new CANNON.Body({
    mass: 0.5,
    shape: new CANNON.Sphere(0.2),
    position: origin.clone(),
    velocity: new CANNON.Vec3(
      (dx / dist) * ARCANE_SPEED * 0.4,
      ARCANE_SPEED * 0.6,
      (dz / dist) * ARCANE_SPEED * 0.4,
    ),
    collisionFilterGroup: GROUP_PROJECTILE,
    collisionFilterMask: GROUP_ENEMY,
    linearDamping: 0.05,
  });

  world.addBody(body);

  return {
    id: nextEntityId(),
    body,
    alive: true,
    damage: 1.8,
    knockback: 6,
    age: 0,
    maxAge: 8,
    type: "arcane",
    splashRadius: 0,
    splashForce: 0,
    targetId,
  };
}

/**
 * Homing update for arcane bolts. Called each physics tick.
 * Steers toward the target with a force, creating a floaty curved path.
 */
export function updateArcaneHoming(state: GameState): void {
  for (const proj of state.projectiles) {
    if (!proj.alive || proj.type !== "arcane") continue;

    // Cancel gravity so arcane bolts float
    proj.body.force.y += 20 * proj.body.mass;

    if (proj.targetId === null) continue;

    const target = state.enemies.find((e) => e.id === proj.targetId && e.alive);
    if (!target) {
      // Target died — find nearest alive enemy to retarget
      let nearest: { id: number; distSq: number } | null = null;
      for (const e of state.enemies) {
        if (!e.alive) continue;
        const dx = e.body.position.x - proj.body.position.x;
        const dy = e.body.position.y - proj.body.position.y;
        const dz = e.body.position.z - proj.body.position.z;
        const dSq = dx * dx + dy * dy + dz * dz;
        if (!nearest || dSq < nearest.distSq) nearest = { id: e.id, distSq: dSq };
      }
      if (nearest) {
        proj.targetId = nearest.id;
      } else {
        proj.targetId = null;
      }
      continue;
    }

    // Steer toward target
    const tPos = target.body.position;
    const pPos = proj.body.position;
    const dx = tPos.x - pPos.x;
    const dy = (tPos.y + 0.5) - pPos.y;
    const dz = tPos.z - pPos.z;
    const dist = Math.sqrt(dx * dx + dy * dy + dz * dz);
    if (dist < 0.1) continue;

    const dirX = dx / dist;
    const dirY = dy / dist;
    const dirZ = dz / dist;

    // Apply steering force toward target
    proj.body.applyForce(
      new CANNON.Vec3(
        dirX * ARCANE_STEER_FORCE,
        dirY * ARCANE_STEER_FORCE,
        dirZ * ARCANE_STEER_FORCE,
      ),
      proj.body.position,
    );

    // Cap speed so it stays floaty
    const vel = proj.body.velocity;
    const speed = vel.length();
    if (speed > ARCANE_SPEED) {
      const scale = ARCANE_SPEED / speed;
      vel.x *= scale;
      vel.y *= scale;
      vel.z *= scale;
    }
  }
}

export function updateProjectiles(state: GameState, dt: number): void {
  for (const proj of state.projectiles) {
    if (!proj.alive) continue;
    proj.age += dt;
    if (proj.age > proj.maxAge) {
      proj.alive = false;
    }
  }
}

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
        // Direct hit — full damage + knockback
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
      // Damage falloff: full at center, zero at edge
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
