import * as THREE from "three";
import { EnemyState, ProjectileState } from "../state.js";

// --- Shared materials ---
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

// --- Shared geometries ---
const TORSO_GEO = new THREE.BoxGeometry(0.8, 1.0, 0.6);
const LEG_GEO = new THREE.BoxGeometry(0.25, 0.7, 0.25);
const HEAD_GEO = new THREE.SphereGeometry(0.3, 6, 4);
const FIREBALL_GEO = new THREE.SphereGeometry(0.35, 6, 4);
const ARROW_SHAFT_GEO = new THREE.CylinderGeometry(0.03, 0.03, 1.2, 4);
const ARROW_TIP_GEO = new THREE.ConeGeometry(0.06, 0.2, 4);
const ARROW_FLETCH_GEO = new THREE.BoxGeometry(0.15, 0.01, 0.08);
const ARCANE_CORE_GEO = new THREE.OctahedronGeometry(0.25, 0);
const ARCANE_PARTICLE_GEO = new THREE.SphereGeometry(0.08, 4, 3);

export const TRAIL_LENGTH = 12;

export function createEnemyMesh(enemy: EnemyState, scene: THREE.Scene, registry: Map<number, THREE.Group>): THREE.Group {
  const group = new THREE.Group();

  const torso = new THREE.Mesh(TORSO_GEO, BODY_MAT);
  torso.castShadow = true;
  torso.position.y = 0.5;
  group.add(torso);

  const head = new THREE.Mesh(HEAD_GEO, HEAD_MAT);
  head.castShadow = true;
  head.position.y = 1.3;
  group.add(head);

  const leftLeg = new THREE.Mesh(LEG_GEO, LEG_MAT);
  leftLeg.castShadow = true;
  leftLeg.position.set(-0.2, -0.1, 0);
  leftLeg.name = "leftLeg";
  group.add(leftLeg);

  const rightLeg = new THREE.Mesh(LEG_GEO, LEG_MAT);
  rightLeg.castShadow = true;
  rightLeg.position.set(0.2, -0.1, 0);
  rightLeg.name = "rightLeg";
  group.add(rightLeg);

  scene.add(group);
  registry.set(enemy.id, group);
  return group;
}

export function createFireballMesh(
  proj: ProjectileState,
  scene: THREE.Scene,
  registry: Map<number, THREE.Object3D>,
): THREE.Mesh {
  const mesh = new THREE.Mesh(FIREBALL_GEO, FIREBALL_MAT);
  mesh.castShadow = true;
  scene.add(mesh);

  const light = new THREE.PointLight(0xff4400, 2, 8);
  mesh.add(light);

  registry.set(proj.id, mesh);
  return mesh;
}

export function createArrowMesh(
  proj: ProjectileState,
  scene: THREE.Scene,
  registry: Map<number, THREE.Object3D>,
): THREE.Group {
  const group = new THREE.Group();

  const shaft = new THREE.Mesh(ARROW_SHAFT_GEO, ARROW_SHAFT_MAT);
  shaft.castShadow = true;
  group.add(shaft);

  const tip = new THREE.Mesh(ARROW_TIP_GEO, ARROW_TIP_MAT);
  tip.position.y = 0.7;
  tip.castShadow = true;
  group.add(tip);

  const fletch1 = new THREE.Mesh(ARROW_FLETCH_GEO, ARROW_FLETCH_MAT);
  fletch1.position.y = -0.5;
  group.add(fletch1);
  const fletch2 = new THREE.Mesh(ARROW_FLETCH_GEO, ARROW_FLETCH_MAT);
  fletch2.position.y = -0.5;
  fletch2.rotation.y = Math.PI / 2;
  group.add(fletch2);

  scene.add(group);
  registry.set(proj.id, group);
  return group;
}

export function createArcaneMesh(
  proj: ProjectileState,
  scene: THREE.Scene,
  registry: Map<number, THREE.Object3D>,
  trailRegistry: Map<number, THREE.Mesh[]>,
): THREE.Group {
  const group = new THREE.Group();

  const core = new THREE.Mesh(ARCANE_CORE_GEO, ARCANE_MAT);
  core.castShadow = true;
  core.name = "core";
  group.add(core);

  const light = new THREE.PointLight(0x8844ff, 3, 10);
  group.add(light);

  const trail: THREE.Mesh[] = [];
  for (let i = 0; i < TRAIL_LENGTH; i++) {
    const particle = new THREE.Mesh(ARCANE_PARTICLE_GEO, ARCANE_PARTICLE_MAT.clone());
    particle.visible = false;
    scene.add(particle);
    trail.push(particle);
  }
  trailRegistry.set(proj.id, trail);

  scene.add(group);
  registry.set(proj.id, group);
  return group;
}
