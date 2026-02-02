import * as THREE from "three";
import * as CANNON from "cannon-es";
import { GameState } from "../state.js";
import {
  createEnemyMesh,
  createFireballMesh,
  createArrowMesh,
  createArcaneMesh,
} from "./meshes.js";

// Track Three.js objects by entity ID
const enemyMeshes = new Map<number, THREE.Group>();
const projectileMeshes = new Map<number, THREE.Object3D>();
const arcaneTrails = new Map<number, THREE.Mesh[]>();

export function syncRenderer(state: GameState, scene: THREE.Scene): void {
  syncEnemies(state, scene);
  syncProjectiles(state, scene);
}

function syncEnemies(state: GameState, scene: THREE.Scene): void {
  for (const enemy of state.enemies) {
    let group = enemyMeshes.get(enemy.id);
    if (!group) {
      group = createEnemyMesh(enemy, scene, enemyMeshes);
    }

    const pos = enemy.body.position;
    const quat = enemy.body.quaternion;
    group.position.set(pos.x, pos.y - 0.6, pos.z);
    group.quaternion.set(quat.x, quat.y, quat.z, quat.w);

    if (enemy.alive) {
      const leftLeg = group.getObjectByName("leftLeg") as THREE.Mesh | undefined;
      const rightLeg = group.getObjectByName("rightLeg") as THREE.Mesh | undefined;
      const swing = Math.sin(enemy.legPhase) * 0.6;
      if (leftLeg) leftLeg.rotation.x = swing;
      if (rightLeg) rightLeg.rotation.x = -swing;
    }

    if (!enemy.alive) {
      group.scale.multiplyScalar(0.97);
      if (group.scale.x < 0.05) {
        scene.remove(group);
        enemyMeshes.delete(enemy.id);
      }
    }
  }
}

function syncProjectiles(state: GameState, scene: THREE.Scene): void {
  for (const proj of state.projectiles) {
    let obj = projectileMeshes.get(proj.id);
    if (!obj) {
      if (proj.type === "arcane") {
        obj = createArcaneMesh(proj, scene, projectileMeshes, arcaneTrails);
      } else if (proj.type === "arrow") {
        obj = createArrowMesh(proj, scene, projectileMeshes);
      } else {
        obj = createFireballMesh(proj, scene, projectileMeshes);
      }
    }

    const pos = proj.body.position;
    obj.position.set(pos.x, pos.y, pos.z);

    if (proj.type === "arcane") {
      syncArcaneVisuals(obj, proj.id, pos);
    } else if (proj.type === "arrow") {
      syncArrowVisuals(obj, proj.body.velocity);
    } else {
      obj.rotation.x += 0.2;
      obj.rotation.y += 0.15;
    }

    if (!proj.alive) {
      scene.remove(obj);
      projectileMeshes.delete(proj.id);
      const trail = arcaneTrails.get(proj.id);
      if (trail) {
        for (const p of trail) scene.remove(p);
        arcaneTrails.delete(proj.id);
      }
    }
  }
}

function syncArcaneVisuals(obj: THREE.Object3D, id: number, pos: CANNON.Vec3): void {
  const core = obj.getObjectByName("core");
  if (core) {
    core.rotation.x += 0.08;
    core.rotation.y += 0.12;
    core.rotation.z += 0.05;
  }

  const trail = arcaneTrails.get(id);
  if (trail) {
    for (let i = trail.length - 1; i > 0; i--) {
      const prev = trail[i - 1]!;
      const curr = trail[i]!;
      curr.position.copy(prev.position);
      curr.visible = prev.visible;
      const t = i / trail.length;
      curr.scale.setScalar(1 - t * 0.8);
      const mat = curr.material as THREE.MeshBasicMaterial;
      mat.opacity = 0.6 * (1 - t);
    }
    const head = trail[0]!;
    head.position.set(
      pos.x + (Math.random() - 0.5) * 0.3,
      pos.y + (Math.random() - 0.5) * 0.3,
      pos.z + (Math.random() - 0.5) * 0.3,
    );
    head.visible = true;
  }
}

function syncArrowVisuals(obj: THREE.Object3D, velocity: CANNON.Vec3): void {
  if (velocity.length() > 0.5) {
    const dir = new THREE.Vector3(velocity.x, velocity.y, velocity.z).normalize();
    const up = new THREE.Vector3(0, 1, 0);
    const quat = new THREE.Quaternion().setFromUnitVectors(up, dir);
    obj.quaternion.copy(quat);
  }
}

export function cleanupDeadEntities(state: GameState, world: CANNON.World): void {
  for (let i = state.enemies.length - 1; i >= 0; i--) {
    const enemy = state.enemies[i]!;
    if (!enemy.alive && !enemyMeshes.has(enemy.id)) {
      world.removeBody(enemy.body);
      state.enemies.splice(i, 1);
    }
  }

  for (let i = state.projectiles.length - 1; i >= 0; i--) {
    const proj = state.projectiles[i]!;
    if (!proj.alive && !projectileMeshes.has(proj.id)) {
      world.removeBody(proj.body);
      state.projectiles.splice(i, 1);
    }
  }
}
