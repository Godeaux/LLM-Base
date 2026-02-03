import * as CANNON from "cannon-es";
import { EnemyState, GameState, MinionState, nextEntityId } from "../state.js";
import { GROUP_MINION, GROUP_GROUND, GROUP_PROJECTILE } from "../systems/physics.js";
import { MINION } from "../config.js";
import { killEnemy } from "../systems/damage.js";

export function spawnMinion(world: CANNON.World): MinionState {
  const angle = Math.random() * Math.PI * 2;
  const x = Math.cos(angle) * MINION.spawnRadius;
  const z = Math.sin(angle) * MINION.spawnRadius;

  const body = new CANNON.Body({
    mass: MINION.mass,
    position: new CANNON.Vec3(x, 0.5, z),
    shape: new CANNON.Box(new CANNON.Vec3(0.2, 0.35, 0.15)),
    collisionFilterGroup: GROUP_MINION,
    // Collides with ground and projectiles (gets flung), NOT enemies (they walk through)
    collisionFilterMask: GROUP_GROUND | GROUP_PROJECTILE,
    linearDamping: 0.4,
    angularDamping: 0.8,
  });

  world.addBody(body);

  return {
    id: nextEntityId(),
    body,
    aiState: "roaming",
    stateTimer: 0,
    targetId: null,
    legPhase: Math.random() * Math.PI * 2,
    meshGroup: null,
  };
}

export function despawnMinion(minion: MinionState, world: CANNON.World): void {
  world.removeBody(minion.body);
}

export function updateMinions(state: GameState, dt: number): void {
  const aliveEnemies = state.enemies.filter((e) => e.alive);

  for (const minion of state.minions) {
    // Check if flung (high velocity) — enter recovery regardless of current state
    if (minion.aiState !== "recovery") {
      const vel = minion.body.velocity;
      const speed = Math.sqrt(vel.x * vel.x + vel.y * vel.y + vel.z * vel.z);
      if (speed > MINION.flingThreshold) {
        minion.aiState = "recovery";
        minion.stateTimer = MINION.recoveryTime;
        minion.targetId = null;
        continue;
      }
    }

    switch (minion.aiState) {
      case "roaming":
        updateRoaming(minion, aliveEnemies, dt);
        break;
      case "windup":
        updateWindup(minion, state, dt);
        break;
      case "bonk":
        updateBonk(minion, state, dt);
        break;
      case "cooldown":
        updateCooldown(minion, dt);
        break;
      case "recovery":
        updateRecovery(minion, dt);
        break;
    }
  }
}

function findNearestEnemy(pos: CANNON.Vec3, enemies: EnemyState[]): EnemyState | null {
  let nearest: EnemyState | null = null;
  let nearestDistSq = Infinity;

  for (const enemy of enemies) {
    const dx = enemy.body.position.x - pos.x;
    const dz = enemy.body.position.z - pos.z;
    const distSq = dx * dx + dz * dz;
    if (distSq < nearestDistSq) {
      nearestDistSq = distSq;
      nearest = enemy;
    }
  }

  return nearest;
}

function moveToward(minion: MinionState, tx: number, tz: number, dt: number): void {
  const pos = minion.body.position;
  const dx = tx - pos.x;
  const dz = tz - pos.z;
  const dist = Math.sqrt(dx * dx + dz * dz);
  if (dist < 0.1) return;

  const dirX = dx / dist;
  const dirZ = dz / dist;
  const forceMag = MINION.speed * minion.body.mass * MINION.forceMult;
  minion.body.applyForce(
    new CANNON.Vec3(dirX * forceMag, 0, dirZ * forceMag),
    minion.body.position,
  );

  // Cap horizontal speed
  const vx = minion.body.velocity.x;
  const vz = minion.body.velocity.z;
  const hSpeed = Math.sqrt(vx * vx + vz * vz);
  if (hSpeed > MINION.speed) {
    const scale = MINION.speed / hSpeed;
    minion.body.velocity.x *= scale;
    minion.body.velocity.z *= scale;
  }

  // Face movement direction
  const angle = Math.atan2(dirX, dirZ);
  minion.body.quaternion.setFromEuler(0, angle, 0);

  // Leg animation
  minion.legPhase += dt * MINION.speed * 3;
}

function updateRoaming(minion: MinionState, enemies: EnemyState[], dt: number): void {
  const target = findNearestEnemy(minion.body.position, enemies);
  if (!target) return; // no enemies, just idle

  const dx = target.body.position.x - minion.body.position.x;
  const dz = target.body.position.z - minion.body.position.z;
  const dist = Math.sqrt(dx * dx + dz * dz);

  if (dist < MINION.attackRange) {
    // Close enough — start windup
    minion.aiState = "windup";
    minion.stateTimer = MINION.windupTime;
    minion.targetId = target.id;
    return;
  }

  moveToward(minion, target.body.position.x, target.body.position.z, dt);
}

function updateWindup(minion: MinionState, state: GameState, dt: number): void {
  minion.stateTimer -= dt;

  // Face the target during windup
  const target = state.enemies.find((e) => e.id === minion.targetId && e.alive);
  if (!target) {
    // Target died, go back to roaming
    minion.aiState = "roaming";
    minion.targetId = null;
    return;
  }

  const dx = target.body.position.x - minion.body.position.x;
  const dz = target.body.position.z - minion.body.position.z;
  const angle = Math.atan2(dx, dz);
  minion.body.quaternion.setFromEuler(0, angle, 0);

  if (minion.stateTimer <= 0) {
    minion.aiState = "bonk";
    minion.stateTimer = 0.1; // brief bonk frame
  }
}

function updateBonk(minion: MinionState, state: GameState, dt: number): void {
  minion.stateTimer -= dt;

  const target = state.enemies.find((e) => e.id === minion.targetId && e.alive);
  if (target) {
    // Deal damage
    target.hp -= MINION.damage;

    // Small push on the enemy
    const dx = target.body.position.x - minion.body.position.x;
    const dz = target.body.position.z - minion.body.position.z;
    const dist = Math.sqrt(dx * dx + dz * dz) || 0.1;
    const pushDir = new CANNON.Vec3(dx / dist, 0.2, dz / dist);
    pushDir.normalize();
    pushDir.scale(MINION.pushForce, pushDir);
    target.body.applyImpulse(pushDir, target.body.position);

    if (target.hp <= 0 && target.alive) {
      killEnemy(state, target, pushDir);
    }
  }

  // Transition to cooldown
  minion.aiState = "cooldown";
  minion.stateTimer = MINION.cooldownTime;
  minion.targetId = null;
}

function updateCooldown(minion: MinionState, dt: number): void {
  minion.stateTimer -= dt;
  if (minion.stateTimer <= 0) {
    minion.aiState = "roaming";
  }
}

function updateRecovery(minion: MinionState, dt: number): void {
  minion.stateTimer -= dt;
  // Heavy damping while recovering (tumbling on ground)
  minion.body.velocity.x *= 0.95;
  minion.body.velocity.z *= 0.95;

  if (minion.stateTimer <= 0) {
    minion.aiState = "roaming";
  }
}
