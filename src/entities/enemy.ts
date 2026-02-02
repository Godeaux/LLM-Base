import * as CANNON from "cannon-es";
import { EnemyState, GameState, nextEntityId } from "../state.js";
import { GROUP_ENEMY, GROUP_GROUND, GROUP_PROJECTILE, GROUP_TOWER } from "../systems/physics.js";

const SPAWN_RADIUS = 45;

export function spawnEnemy(state: GameState, world: CANNON.World): EnemyState {
  const angle = Math.random() * Math.PI * 2;
  const x = Math.cos(angle) * SPAWN_RADIUS;
  const z = Math.sin(angle) * SPAWN_RADIUS;

  // Main body: a box torso
  const body = new CANNON.Body({
    mass: 5,
    position: new CANNON.Vec3(x, 1.2, z),
    shape: new CANNON.Box(new CANNON.Vec3(0.4, 0.6, 0.3)),
    collisionFilterGroup: GROUP_ENEMY,
    collisionFilterMask: GROUP_GROUND | GROUP_PROJECTILE | GROUP_TOWER | GROUP_ENEMY,
    linearDamping: 0.4,
    angularDamping: 0.8,
  });

  world.addBody(body);

  const waveScale = 1 + (state.wave.number - 1) * 0.15;

  return {
    id: nextEntityId(),
    body,
    hp: 3 * waveScale,
    maxHp: 3 * waveScale,
    speed: 3 + Math.random() * 1.5,
    damage: 1,
    alive: true,
    legPhase: Math.random() * Math.PI * 2,
    meshGroup: null,
    type: "walker",
  };
}

export function updateEnemies(state: GameState, dt: number): void {
  const towerPos = state.tower.position;

  for (const enemy of state.enemies) {
    if (!enemy.alive) continue;

    const pos = enemy.body.position;
    const dx = towerPos.x - pos.x;
    const dz = towerPos.z - pos.z;
    const dist = Math.sqrt(dx * dx + dz * dz);

    if (dist < 2.5) {
      // Enemy is at the tower — deal damage
      state.tower.hp -= enemy.damage * dt;
      // Push enemy back slightly so they don't pile inside
      enemy.body.velocity.set(
        -dx * 0.5,
        enemy.body.velocity.y,
        -dz * 0.5,
      );
      continue;
    }

    // Move toward tower
    const dirX = dx / dist;
    const dirZ = dz / dist;
    const speed = enemy.speed;

    // Apply force toward tower (not direct velocity, so physics knockback works)
    const forceMag = speed * enemy.body.mass * 3;
    enemy.body.applyForce(
      new CANNON.Vec3(dirX * forceMag, 0, dirZ * forceMag),
      enemy.body.position,
    );

    // Cap horizontal speed
    const vx = enemy.body.velocity.x;
    const vz = enemy.body.velocity.z;
    const hSpeed = Math.sqrt(vx * vx + vz * vz);
    if (hSpeed > speed) {
      const scale = speed / hSpeed;
      enemy.body.velocity.x *= scale;
      enemy.body.velocity.z *= scale;
    }

    // Face the tower
    const targetAngle = Math.atan2(dirX, dirZ);
    enemy.body.quaternion.setFromEuler(0, targetAngle, 0);

    // Advance leg animation phase
    enemy.legPhase += dt * speed * 2.5;
  }
}
