import * as CANNON from "cannon-es";
import { GameState, ProjectileState, ProjectileType, nextEntityId } from "../state.js";
import { GROUP_ENEMY, GROUP_GROUND, GROUP_PROJECTILE } from "../systems/physics.js";
import { FIREBALL, ARROW, ARCANE, PHYSICS } from "../config.js";

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
  speed: FIREBALL.speed,
  damage: FIREBALL.damage,
  knockback: FIREBALL.knockback,
  type: "fireball",
  splashRadius: FIREBALL.splashRadius,
  splashForce: FIREBALL.splashForce,
  radius: FIREBALL.projectileRadius,
  mass: FIREBALL.mass,
  launchAngleMin: FIREBALL.launchAngleMin,
  launchAngleMax: FIREBALL.launchAngleMax,
  maxAge: FIREBALL.maxAge,
};

const ARROW_CONFIG: LaunchConfig = {
  speed: ARROW.speed,
  damage: ARROW.damage,
  knockback: ARROW.knockback,
  type: "arrow",
  splashRadius: 0,
  splashForce: 0,
  radius: ARROW.projectileRadius,
  mass: ARROW.mass,
  launchAngleMin: ARROW.launchAngleMin,
  launchAngleMax: ARROW.launchAngleMax,
  maxAge: ARROW.maxAge,
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

    const hSpeed = Math.cos(launchAngle) * projectileSpeed;
    const flightTime = hSpeed > 0.1 ? horizDist / hSpeed : 1;

    const vy = Math.sin(launchAngle) * projectileSpeed;
    const dy = (targetPos.y + 0.5) - origin.y;
    const vertFlightTime = vy > 0 ? (vy + Math.sqrt(Math.max(0, vy * vy + 2 * gravity * dy))) / gravity : flightTime;
    const estimatedTime = Math.min(flightTime, vertFlightTime);

    predicted = new CANNON.Vec3(
      targetPos.x + targetVel.x * estimatedTime,
      targetPos.y + 0.5,
      targetPos.z + targetVel.z * estimatedTime,
    );
  }

  return predicted;
}

export function fireProjectile(
  world: CANNON.World,
  targetPos: CANNON.Vec3,
  targetVel: CANNON.Vec3,
  type: ProjectileType,
  targetId?: number,
): ProjectileState {
  const origin = new CANNON.Vec3(0, 6.5, 0);

  if (type === "arcane") {
    return fireArcaneBolt(world, origin, targetPos, targetId ?? null);
  }

  const config = type === "fireball" ? FIREBALL_CONFIG : ARROW_CONFIG;

  const dx = targetPos.x - origin.x;
  const dz = targetPos.z - origin.z;
  const horizDist = Math.sqrt(dx * dx + dz * dz);

  const distFactor = Math.min(1, horizDist / 50);
  const launchAngle =
    config.launchAngleMin + (config.launchAngleMax - config.launchAngleMin) * distFactor;

  const predicted = predictIntercept(
    origin, targetPos, targetVel, config.speed, PHYSICS.gravity, launchAngle,
  );

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

function fireArcaneBolt(
  world: CANNON.World,
  origin: CANNON.Vec3,
  targetPos: CANNON.Vec3,
  targetId: number | null,
): ProjectileState {
  const dx = targetPos.x - origin.x;
  const dz = targetPos.z - origin.z;
  const dist = Math.sqrt(dx * dx + dz * dz) || 1;

  const body = new CANNON.Body({
    mass: ARCANE.mass,
    shape: new CANNON.Sphere(ARCANE.projectileRadius),
    position: origin.clone(),
    velocity: new CANNON.Vec3(
      (dx / dist) * ARCANE.speed * ARCANE.initialSpeedFractionXZ,
      ARCANE.speed * ARCANE.initialSpeedFractionY,
      (dz / dist) * ARCANE.speed * ARCANE.initialSpeedFractionXZ,
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
    damage: ARCANE.damage,
    knockback: ARCANE.knockback,
    age: 0,
    maxAge: ARCANE.maxAge,
    type: "arcane",
    splashRadius: 0,
    splashForce: 0,
    targetId,
  };
}

export function updateArcaneHoming(state: GameState): void {
  for (const proj of state.projectiles) {
    if (!proj.alive || proj.type !== "arcane") continue;

    // Cancel gravity so arcane bolts float
    proj.body.force.y += PHYSICS.gravity * proj.body.mass;

    if (proj.targetId === null) continue;

    const target = state.enemies.find((e) => e.id === proj.targetId && e.alive);
    if (!target) {
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

    const tPos = target.body.position;
    const pPos = proj.body.position;
    const dx = tPos.x - pPos.x;
    const dy = (tPos.y + 0.5) - pPos.y;
    const dz = tPos.z - pPos.z;
    const dist = Math.sqrt(dx * dx + dy * dy + dz * dz);
    if (dist < 0.1) continue;

    proj.body.applyForce(
      new CANNON.Vec3(
        (dx / dist) * ARCANE.steerForce,
        (dy / dist) * ARCANE.steerForce,
        (dz / dist) * ARCANE.steerForce,
      ),
      proj.body.position,
    );

    const vel = proj.body.velocity;
    const speed = vel.length();
    if (speed > ARCANE.speed) {
      const scale = ARCANE.speed / speed;
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
