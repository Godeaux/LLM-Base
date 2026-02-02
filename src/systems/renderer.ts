import * as THREE from "three";
import * as CANNON from "cannon-es";
import { GameState, EnemyState, ProjectileState } from "../state.js";

// Track Three.js objects by entity ID
const enemyMeshes = new Map<number, THREE.Group>();
const projectileMeshes = new Map<number, THREE.Mesh>();

// Shared materials
const BODY_MAT = new THREE.MeshStandardMaterial({ color: 0xcc3333 });
const LEG_MAT = new THREE.MeshStandardMaterial({ color: 0x993322 });
const HEAD_MAT = new THREE.MeshStandardMaterial({ color: 0xdd4444 });
const FIREBALL_MAT = new THREE.MeshStandardMaterial({
  color: 0xff6600,
  emissive: 0xff3300,
  emissiveIntensity: 0.8,
});

// Shared geometries
const TORSO_GEO = new THREE.BoxGeometry(0.8, 1.0, 0.6);
const LEG_GEO = new THREE.BoxGeometry(0.25, 0.7, 0.25);
const HEAD_GEO = new THREE.SphereGeometry(0.3, 6, 4);
const FIREBALL_GEO = new THREE.SphereGeometry(0.3, 6, 4);

export function createEnemyMesh(enemy: EnemyState, scene: THREE.Scene): THREE.Group {
  const group = new THREE.Group();

  // Torso
  const torso = new THREE.Mesh(TORSO_GEO, BODY_MAT);
  torso.castShadow = true;
  torso.position.y = 0.5;
  group.add(torso);

  // Head
  const head = new THREE.Mesh(HEAD_GEO, HEAD_MAT);
  head.castShadow = true;
  head.position.y = 1.3;
  group.add(head);

  // Left leg
  const leftLeg = new THREE.Mesh(LEG_GEO, LEG_MAT);
  leftLeg.castShadow = true;
  leftLeg.position.set(-0.2, -0.1, 0);
  leftLeg.name = "leftLeg";
  group.add(leftLeg);

  // Right leg
  const rightLeg = new THREE.Mesh(LEG_GEO, LEG_MAT);
  rightLeg.castShadow = true;
  rightLeg.position.set(0.2, -0.1, 0);
  rightLeg.name = "rightLeg";
  group.add(rightLeg);

  scene.add(group);
  enemyMeshes.set(enemy.id, group);
  return group;
}

export function createProjectileMesh(proj: ProjectileState, scene: THREE.Scene): THREE.Mesh {
  const mesh = new THREE.Mesh(FIREBALL_GEO, FIREBALL_MAT);
  mesh.castShadow = true;
  scene.add(mesh);
  projectileMeshes.set(proj.id, mesh);

  // Add a point light for glow
  const light = new THREE.PointLight(0xff4400, 2, 8);
  mesh.add(light);

  return mesh;
}

export function syncRenderer(state: GameState, scene: THREE.Scene): void {
  // Sync enemies
  for (const enemy of state.enemies) {
    let group = enemyMeshes.get(enemy.id);
    if (!group) {
      group = createEnemyMesh(enemy, scene);
    }

    const pos = enemy.body.position;
    const quat = enemy.body.quaternion;
    group.position.set(pos.x, pos.y - 0.6, pos.z);
    group.quaternion.set(quat.x, quat.y, quat.z, quat.w);

    // Animate legs — bipedal walking gait
    if (enemy.alive) {
      const leftLeg = group.getObjectByName("leftLeg") as THREE.Mesh | undefined;
      const rightLeg = group.getObjectByName("rightLeg") as THREE.Mesh | undefined;
      const swing = Math.sin(enemy.legPhase) * 0.6;
      if (leftLeg) leftLeg.rotation.x = swing;
      if (rightLeg) rightLeg.rotation.x = -swing;
    }

    // Fade out dead enemies
    if (!enemy.alive) {
      group.scale.multiplyScalar(0.97);
      if (group.scale.x < 0.05) {
        scene.remove(group);
        enemyMeshes.delete(enemy.id);
      }
    }
  }

  // Sync projectiles
  for (const proj of state.projectiles) {
    let mesh = projectileMeshes.get(proj.id);
    if (!mesh) {
      mesh = createProjectileMesh(proj, scene);
    }

    const pos = proj.body.position;
    mesh.position.set(pos.x, pos.y, pos.z);

    // Spin the fireball
    mesh.rotation.x += 0.2;
    mesh.rotation.y += 0.15;

    if (!proj.alive) {
      scene.remove(mesh);
      projectileMeshes.delete(proj.id);
    }
  }
}

export function cleanupDeadEntities(state: GameState, world: CANNON.World): void {
  // Remove dead enemies that have faded out
  for (let i = state.enemies.length - 1; i >= 0; i--) {
    const enemy = state.enemies[i]!;
    if (!enemy.alive && !enemyMeshes.has(enemy.id)) {
      world.removeBody(enemy.body);
      state.enemies.splice(i, 1);
    }
  }

  // Remove dead projectiles
  for (let i = state.projectiles.length - 1; i >= 0; i--) {
    const proj = state.projectiles[i]!;
    if (!proj.alive && !projectileMeshes.has(proj.id)) {
      world.removeBody(proj.body);
      state.projectiles.splice(i, 1);
    }
  }
}
