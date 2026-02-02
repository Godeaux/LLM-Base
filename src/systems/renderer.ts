import * as THREE from "three";
import * as CANNON from "cannon-es";
import { GameState, EnemyState, ProjectileState } from "../state.js";

// Track Three.js objects by entity ID
const enemyMeshes = new Map<number, THREE.Group>();
const projectileMeshes = new Map<number, THREE.Object3D>();

// Shared materials
const BODY_MAT = new THREE.MeshStandardMaterial({ color: 0xcc3333 });
const LEG_MAT = new THREE.MeshStandardMaterial({ color: 0x993322 });
const HEAD_MAT = new THREE.MeshStandardMaterial({ color: 0xdd4444 });
const FIREBALL_MAT = new THREE.MeshStandardMaterial({
  color: 0xff6600,
  emissive: 0xff3300,
  emissiveIntensity: 0.8,
});
const ARROW_SHAFT_MAT = new THREE.MeshStandardMaterial({ color: 0x8b6914 });
const ARROW_TIP_MAT = new THREE.MeshStandardMaterial({ color: 0xcccccc });
const ARROW_FLETCH_MAT = new THREE.MeshStandardMaterial({ color: 0xcc2222 });
const ARCANE_MAT = new THREE.MeshStandardMaterial({
  color: 0x8844ff,
  emissive: 0x6622cc,
  emissiveIntensity: 1.2,
});
const ARCANE_PARTICLE_MAT = new THREE.MeshBasicMaterial({
  color: 0xaa66ff,
  transparent: true,
  opacity: 0.6,
});

// Shared geometries
const TORSO_GEO = new THREE.BoxGeometry(0.8, 1.0, 0.6);
const LEG_GEO = new THREE.BoxGeometry(0.25, 0.7, 0.25);
const HEAD_GEO = new THREE.SphereGeometry(0.3, 6, 4);
const FIREBALL_GEO = new THREE.SphereGeometry(0.35, 6, 4);
const ARROW_SHAFT_GEO = new THREE.CylinderGeometry(0.03, 0.03, 1.2, 4);
const ARROW_TIP_GEO = new THREE.ConeGeometry(0.06, 0.2, 4);
const ARROW_FLETCH_GEO = new THREE.BoxGeometry(0.15, 0.01, 0.08);
const ARCANE_CORE_GEO = new THREE.OctahedronGeometry(0.25, 0);
const ARCANE_PARTICLE_GEO = new THREE.SphereGeometry(0.08, 4, 3);

// Particle trail storage: projectile id -> array of trail meshes
const arcaneTrails = new Map<number, THREE.Mesh[]>();
const TRAIL_LENGTH = 12;

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

function createFireballMesh(proj: ProjectileState, scene: THREE.Scene): THREE.Mesh {
  const mesh = new THREE.Mesh(FIREBALL_GEO, FIREBALL_MAT);
  mesh.castShadow = true;
  scene.add(mesh);

  // Glow light
  const light = new THREE.PointLight(0xff4400, 2, 8);
  mesh.add(light);

  projectileMeshes.set(proj.id, mesh);
  return mesh;
}

function createArrowMesh(proj: ProjectileState, scene: THREE.Scene): THREE.Group {
  const group = new THREE.Group();

  // Shaft (along local Y axis, will be rotated to face velocity)
  const shaft = new THREE.Mesh(ARROW_SHAFT_GEO, ARROW_SHAFT_MAT);
  shaft.castShadow = true;
  group.add(shaft);

  // Tip
  const tip = new THREE.Mesh(ARROW_TIP_GEO, ARROW_TIP_MAT);
  tip.position.y = 0.7;
  tip.castShadow = true;
  group.add(tip);

  // Fletching (two crossed planes at the back)
  const fletch1 = new THREE.Mesh(ARROW_FLETCH_GEO, ARROW_FLETCH_MAT);
  fletch1.position.y = -0.5;
  group.add(fletch1);
  const fletch2 = new THREE.Mesh(ARROW_FLETCH_GEO, ARROW_FLETCH_MAT);
  fletch2.position.y = -0.5;
  fletch2.rotation.y = Math.PI / 2;
  group.add(fletch2);

  scene.add(group);
  projectileMeshes.set(proj.id, group);
  return group;
}

function createArcaneMesh(proj: ProjectileState, scene: THREE.Scene): THREE.Group {
  const group = new THREE.Group();

  // Core: spinning octahedron
  const core = new THREE.Mesh(ARCANE_CORE_GEO, ARCANE_MAT);
  core.castShadow = true;
  core.name = "core";
  group.add(core);

  // Glow light — purple
  const light = new THREE.PointLight(0x8844ff, 3, 10);
  group.add(light);

  // Initialize trail particles
  const trail: THREE.Mesh[] = [];
  for (let i = 0; i < TRAIL_LENGTH; i++) {
    const particle = new THREE.Mesh(ARCANE_PARTICLE_GEO, ARCANE_PARTICLE_MAT.clone());
    particle.visible = false;
    scene.add(particle);
    trail.push(particle);
  }
  arcaneTrails.set(proj.id, trail);

  scene.add(group);
  projectileMeshes.set(proj.id, group);
  return group;
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
    let obj = projectileMeshes.get(proj.id);
    if (!obj) {
      if (proj.type === "arcane") {
        obj = createArcaneMesh(proj, scene);
      } else if (proj.type === "arrow") {
        obj = createArrowMesh(proj, scene);
      } else {
        obj = createFireballMesh(proj, scene);
      }
    }

    const pos = proj.body.position;
    obj.position.set(pos.x, pos.y, pos.z);

    if (proj.type === "arcane") {
      // Spin the octahedron core
      const core = obj.getObjectByName("core");
      if (core) {
        core.rotation.x += 0.08;
        core.rotation.y += 0.12;
        core.rotation.z += 0.05;
      }

      // Update particle trail: shift particles back, newest at [0]
      const trail = arcaneTrails.get(proj.id);
      if (trail) {
        for (let i = trail.length - 1; i > 0; i--) {
          const prev = trail[i - 1]!;
          const curr = trail[i]!;
          curr.position.copy(prev.position);
          curr.visible = prev.visible;
          // Fade and shrink toward the tail
          const t = i / trail.length;
          curr.scale.setScalar(1 - t * 0.8);
          const mat = curr.material as THREE.MeshBasicMaterial;
          mat.opacity = 0.6 * (1 - t);
        }
        // Newest particle at current position with slight random offset
        const head = trail[0]!;
        head.position.set(
          pos.x + (Math.random() - 0.5) * 0.3,
          pos.y + (Math.random() - 0.5) * 0.3,
          pos.z + (Math.random() - 0.5) * 0.3,
        );
        head.visible = true;
      }
    } else if (proj.type === "arrow") {
      // Orient arrow along its velocity vector
      const vel = proj.body.velocity;
      if (vel.length() > 0.5) {
        const dir = new THREE.Vector3(vel.x, vel.y, vel.z).normalize();
        const up = new THREE.Vector3(0, 1, 0);
        const quat = new THREE.Quaternion().setFromUnitVectors(up, dir);
        obj.quaternion.copy(quat);
      }
    } else {
      // Spin the fireball
      obj.rotation.x += 0.2;
      obj.rotation.y += 0.15;
    }

    if (!proj.alive) {
      scene.remove(obj);
      projectileMeshes.delete(proj.id);
      // Clean up trail particles
      const trail = arcaneTrails.get(proj.id);
      if (trail) {
        for (const p of trail) scene.remove(p);
        arcaneTrails.delete(proj.id);
      }
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
