import * as THREE from "three";
import * as CANNON from "cannon-es";
import { GameState } from "../state.js";
import {
  createEnemyMesh,
  createFireballMesh,
  createArrowMesh,
  createArcaneMesh,
  createMinionMesh,
} from "./meshes.js";

// Track Three.js objects by entity ID
const enemyMeshes = new Map<number, THREE.Group>();
const projectileMeshes = new Map<number, THREE.Object3D>();
const arcaneTrails = new Map<number, THREE.Mesh[]>();
const minionMeshes = new Map<number, THREE.Group>();
const lightningLines: THREE.Line[] = [];

const LIGHTNING_MAT = new THREE.LineBasicMaterial({ color: 0x88ccff, linewidth: 2 });

// Reusable temp objects to avoid per-frame allocations
const _arrowDir = new THREE.Vector3();
const _arrowUp = new THREE.Vector3(0, 1, 0);
const _arrowQuat = new THREE.Quaternion();

export function syncRenderer(state: GameState, scene: THREE.Scene): void {
  syncEnemies(state, scene);
  syncProjectiles(state, scene);
  syncMinions(state, scene);
  syncLightning(state, scene);
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
    _arrowDir.set(velocity.x, velocity.y, velocity.z).normalize();
    _arrowQuat.setFromUnitVectors(_arrowUp, _arrowDir);
    obj.quaternion.copy(_arrowQuat);
  }
}

function syncMinions(state: GameState, scene: THREE.Scene): void {
  // Track which minion IDs are still present
  const activeIds = new Set(state.minions.map((m) => m.id));

  // Remove meshes for despawned minions
  for (const [id, group] of minionMeshes) {
    if (!activeIds.has(id)) {
      scene.remove(group);
      minionMeshes.delete(id);
    }
  }

  for (const minion of state.minions) {
    let group = minionMeshes.get(minion.id);
    if (!group) {
      group = createMinionMesh(minion, scene, minionMeshes);
    }

    const pos = minion.body.position;
    const quat = minion.body.quaternion;
    group.position.set(pos.x, pos.y - 0.35, pos.z);
    group.quaternion.set(quat.x, quat.y, quat.z, quat.w);

    // Leg animation when roaming
    if (minion.aiState === "roaming") {
      const leftLeg = group.getObjectByName("leftLeg") as THREE.Mesh | undefined;
      const rightLeg = group.getObjectByName("rightLeg") as THREE.Mesh | undefined;
      const swing = Math.sin(minion.legPhase) * 0.5;
      if (leftLeg) leftLeg.rotation.x = swing;
      if (rightLeg) rightLeg.rotation.x = -swing;
    }

    // Windup: raise arms
    const leftArm = group.getObjectByName("leftArm") as THREE.Mesh | undefined;
    const rightArm = group.getObjectByName("rightArm") as THREE.Mesh | undefined;
    if (minion.aiState === "windup") {
      if (leftArm) leftArm.rotation.x = -1.8;
      if (rightArm) rightArm.rotation.x = -1.8;
    } else if (minion.aiState === "bonk") {
      if (leftArm) leftArm.rotation.x = 0.8;
      if (rightArm) rightArm.rotation.x = 0.8;
    } else {
      if (leftArm) leftArm.rotation.x = 0;
      if (rightArm) rightArm.rotation.x = 0;
    }

    // Recovery: tilt sideways (tumbled)
    if (minion.aiState === "recovery") {
      group.rotation.z = Math.PI / 3;
    } else {
      group.rotation.z = 0;
    }
  }
}

function syncLightning(state: GameState, scene: THREE.Scene): void {
  // Remove and dispose old lines (free GPU buffers)
  for (const line of lightningLines) {
    scene.remove(line);
    line.geometry.dispose();
    (line.material as THREE.Material).dispose();
  }
  lightningLines.length = 0;

  for (const arc of state.lightningArcs) {
    const fade = 1 - arc.age / arc.maxAge;
    // Build jagged line between chain points
    for (let i = 0; i < arc.points.length - 1; i++) {
      const a = arc.points[i]!;
      const b = arc.points[i + 1]!;
      const pts: THREE.Vector3[] = [new THREE.Vector3(a.x, a.y, a.z)];

      // Add 3-4 random jag points between each pair
      const segs = 4;
      for (let s = 1; s < segs; s++) {
        const t = s / segs;
        const jitter = 0.6;
        pts.push(new THREE.Vector3(
          a.x + (b.x - a.x) * t + (Math.random() - 0.5) * jitter,
          a.y + (b.y - a.y) * t + (Math.random() - 0.5) * jitter,
          a.z + (b.z - a.z) * t + (Math.random() - 0.5) * jitter,
        ));
      }
      pts.push(new THREE.Vector3(b.x, b.y, b.z));

      const geo = new THREE.BufferGeometry().setFromPoints(pts);
      const mat = LIGHTNING_MAT.clone();
      mat.opacity = fade;
      mat.transparent = true;
      const line = new THREE.Line(geo, mat);
      scene.add(line);
      lightningLines.push(line);
    }
  }
}

export function cleanupDeadEntities(state: GameState, world: CANNON.World): void {
  // Swap-and-pop: O(1) removal instead of O(n) splice
  swapRemove(state.enemies, (enemy) => {
    if (!enemy.alive && !enemyMeshes.has(enemy.id)) {
      world.removeBody(enemy.body);
      return true;
    }
    return false;
  });

  swapRemove(state.projectiles, (proj) => {
    if (!proj.alive && !projectileMeshes.has(proj.id)) {
      world.removeBody(proj.body);
      return true;
    }
    return false;
  });
}

/** Remove items from an array in O(1) per removal by swapping with the last element. */
function swapRemove<T>(arr: T[], shouldRemove: (item: T) => boolean): void {
  let i = 0;
  while (i < arr.length) {
    if (shouldRemove(arr[i]!)) {
      arr[i] = arr[arr.length - 1]!;
      arr.pop();
    } else {
      i++;
    }
  }
}
