import * as THREE from "three";
import { TowerState } from "./types.js";
import { ATTACK_CONFIGS } from "./attacks.js";

export function createTowerState(): TowerState {
  return {
    level: 1,
    health: 100,
    maxHealth: 100,
    attacks: ATTACK_CONFIGS.map((a) => ({ ...a })),
    activeAttackIndex: 0,
    attackTimers: ATTACK_CONFIGS.map(() => 0),
    gold: 0,
    kills: 0,
    wave: 0,
    waveTimer: 0,
    waveActive: false,
    enemiesRemaining: 0,
    autoUpgrade: false,
  };
}

export function createTowerMesh(level: number): THREE.Group {
  const group = new THREE.Group();

  const height = 3 + level * 0.5;
  const baseRadius = 1.2 + level * 0.1;

  // Base
  const baseGeo = new THREE.CylinderGeometry(baseRadius, baseRadius * 1.3, 1.5, 8);
  const baseMat = new THREE.MeshStandardMaterial({
    color: 0x555566,
    roughness: 0.7,
    metalness: 0.3,
  });
  const base = new THREE.Mesh(baseGeo, baseMat);
  base.position.y = 0.75;
  base.castShadow = true;
  base.receiveShadow = true;
  group.add(base);

  // Main column
  const colGeo = new THREE.CylinderGeometry(baseRadius * 0.6, baseRadius * 0.8, height, 8);
  const colMat = new THREE.MeshStandardMaterial({
    color: 0x667788,
    roughness: 0.5,
    metalness: 0.4,
  });
  const col = new THREE.Mesh(colGeo, colMat);
  col.position.y = 1.5 + height / 2;
  col.castShadow = true;
  group.add(col);

  // Crown / orb at top
  const orbRadius = 0.5 + level * 0.05;
  const orbGeo = new THREE.SphereGeometry(orbRadius, 16, 12);
  const orbMat = new THREE.MeshStandardMaterial({
    color: 0x44aaff,
    emissive: 0x2266cc,
    emissiveIntensity: 0.8 + level * 0.1,
    roughness: 0.1,
    metalness: 0.8,
  });
  const orb = new THREE.Mesh(orbGeo, orbMat);
  orb.position.y = 1.5 + height + orbRadius;
  orb.name = "orb";
  group.add(orb);

  // Orb glow
  const glowGeo = new THREE.SphereGeometry(orbRadius * 2, 16, 12);
  const glowMat = new THREE.MeshBasicMaterial({
    color: 0x44aaff,
    transparent: true,
    opacity: 0.15,
  });
  const glow = new THREE.Mesh(glowGeo, glowMat);
  glow.position.y = 1.5 + height + orbRadius;
  group.add(glow);

  // Level-based decorations
  if (level >= 3) {
    // Floating rings
    for (let i = 0; i < Math.min(level - 2, 4); i++) {
      const ringGeo = new THREE.TorusGeometry(baseRadius + 0.5 + i * 0.3, 0.05, 8, 32);
      const ringMat = new THREE.MeshBasicMaterial({
        color: 0x44ccff,
        transparent: true,
        opacity: 0.5,
      });
      const ring = new THREE.Mesh(ringGeo, ringMat);
      ring.position.y = 2 + i * 1.5;
      ring.rotation.x = Math.PI / 2;
      ring.name = `ring-${i}`;
      group.add(ring);
    }
  }

  // Point light from orb
  const light = new THREE.PointLight(0x44aaff, 2 + level * 0.5, 15 + level * 2);
  light.position.y = 1.5 + height + orbRadius;
  group.add(light);

  return group;
}

export function getUpgradeCost(level: number): number {
  return Math.floor(50 * Math.pow(1.5, level - 1));
}

export function getAttackUpgradeCost(attackLevel: number): number {
  return Math.floor(30 * Math.pow(1.4, attackLevel - 1));
}

export function animateTower(towerMesh: THREE.Group, time: number, level: number): void {
  // Rotate orb
  const orb = towerMesh.getObjectByName("orb");
  if (orb) {
    orb.rotation.y = time * 0.5;
  }

  // Animate rings
  for (let i = 0; i < 4; i++) {
    const ring = towerMesh.getObjectByName(`ring-${i}`);
    if (ring) {
      ring.rotation.z = time * (0.3 + i * 0.1);
      ring.position.y = 2 + i * 1.5 + Math.sin(time + i) * 0.2;
    }
  }

  // Pulse glow based on level
  const glow = towerMesh.children.find(
    (c) =>
      c instanceof THREE.Mesh &&
      (c.material as THREE.MeshBasicMaterial).transparent === true &&
      !(c as THREE.Mesh).name,
  );
  if (glow && glow instanceof THREE.Mesh) {
    const mat = glow.material as THREE.MeshBasicMaterial;
    mat.opacity = 0.1 + Math.sin(time * 2) * 0.05 + level * 0.01;
  }
}
