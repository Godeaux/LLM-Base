import * as THREE from "three";
import * as CANNON from "cannon-es";
import { Enemy, EnemyConfig, EnemyType } from "./types.js";

let nextEnemyId = 0;

function buildBasicMesh(config: EnemyConfig): THREE.Group {
  const group = new THREE.Group();
  const geo = new THREE.BoxGeometry(0.8 * config.scale, 0.8 * config.scale, 0.8 * config.scale);
  const mat = new THREE.MeshStandardMaterial({ color: config.color, roughness: 0.5 });
  const mesh = new THREE.Mesh(geo, mat);
  mesh.castShadow = true;
  group.add(mesh);
  return group;
}

function buildFastMesh(config: EnemyConfig): THREE.Group {
  const group = new THREE.Group();
  const geo = new THREE.ConeGeometry(0.4 * config.scale, 1.0 * config.scale, 6);
  const mat = new THREE.MeshStandardMaterial({ color: config.color, roughness: 0.3 });
  const mesh = new THREE.Mesh(geo, mat);
  mesh.castShadow = true;
  group.add(mesh);
  return group;
}

function buildTankMesh(config: EnemyConfig): THREE.Group {
  const group = new THREE.Group();
  const geo = new THREE.SphereGeometry(0.6 * config.scale, 8, 6);
  const mat = new THREE.MeshStandardMaterial({
    color: config.color,
    roughness: 0.8,
    metalness: 0.3,
  });
  const mesh = new THREE.Mesh(geo, mat);
  mesh.castShadow = true;
  group.add(mesh);
  // armor plates
  const plateGeo = new THREE.BoxGeometry(0.3, 0.3, 0.1);
  const plateMat = new THREE.MeshStandardMaterial({ color: 0x666666, metalness: 0.8 });
  for (let i = 0; i < 4; i++) {
    const plate = new THREE.Mesh(plateGeo, plateMat);
    const angle = (i / 4) * Math.PI * 2;
    plate.position.set(Math.cos(angle) * 0.5, 0, Math.sin(angle) * 0.5);
    plate.lookAt(0, 0, 0);
    group.add(plate);
  }
  return group;
}

function buildFlyingMesh(config: EnemyConfig): THREE.Group {
  const group = new THREE.Group();
  const bodyGeo = new THREE.OctahedronGeometry(0.4 * config.scale);
  const mat = new THREE.MeshStandardMaterial({
    color: config.color,
    roughness: 0.2,
    transparent: true,
    opacity: 0.8,
  });
  const mesh = new THREE.Mesh(bodyGeo, mat);
  mesh.castShadow = true;
  group.add(mesh);
  // wings
  const wingGeo = new THREE.PlaneGeometry(1.2 * config.scale, 0.4 * config.scale);
  const wingMat = new THREE.MeshStandardMaterial({
    color: config.color,
    side: THREE.DoubleSide,
    transparent: true,
    opacity: 0.5,
  });
  const wing1 = new THREE.Mesh(wingGeo, wingMat);
  wing1.position.x = 0.5;
  wing1.rotation.y = 0.3;
  const wing2 = new THREE.Mesh(wingGeo, wingMat);
  wing2.position.x = -0.5;
  wing2.rotation.y = -0.3;
  group.add(wing1, wing2);
  return group;
}

function buildSwarmMesh(config: EnemyConfig): THREE.Group {
  const group = new THREE.Group();
  const geo = new THREE.TetrahedronGeometry(0.3 * config.scale);
  const mat = new THREE.MeshStandardMaterial({ color: config.color, roughness: 0.4 });
  const mesh = new THREE.Mesh(geo, mat);
  mesh.castShadow = true;
  group.add(mesh);
  return group;
}

function buildShieldedMesh(config: EnemyConfig): THREE.Group {
  const group = new THREE.Group();
  const innerGeo = new THREE.DodecahedronGeometry(0.4 * config.scale);
  const innerMat = new THREE.MeshStandardMaterial({ color: config.color, roughness: 0.5 });
  const inner = new THREE.Mesh(innerGeo, innerMat);
  inner.castShadow = true;
  group.add(inner);
  const shieldGeo = new THREE.SphereGeometry(0.65 * config.scale, 16, 12);
  const shieldMat = new THREE.MeshStandardMaterial({
    color: 0x4488ff,
    transparent: true,
    opacity: 0.25,
    side: THREE.DoubleSide,
  });
  const shield = new THREE.Mesh(shieldGeo, shieldMat);
  shield.name = "shield";
  group.add(shield);
  return group;
}

function buildBossMesh(config: EnemyConfig): THREE.Group {
  const group = new THREE.Group();
  const bodyGeo = new THREE.IcosahedronGeometry(0.8 * config.scale, 1);
  const mat = new THREE.MeshStandardMaterial({
    color: config.color,
    roughness: 0.3,
    metalness: 0.6,
    emissive: new THREE.Color(config.color).multiplyScalar(0.3),
  });
  const mesh = new THREE.Mesh(bodyGeo, mat);
  mesh.castShadow = true;
  group.add(mesh);
  // crown spikes
  for (let i = 0; i < 6; i++) {
    const spikeGeo = new THREE.ConeGeometry(0.1, 0.6, 4);
    const spikeMat = new THREE.MeshStandardMaterial({ color: 0xffd700, metalness: 0.9 });
    const spike = new THREE.Mesh(spikeGeo, spikeMat);
    const angle = (i / 6) * Math.PI * 2;
    spike.position.set(
      Math.cos(angle) * 0.6 * config.scale,
      0.7 * config.scale,
      Math.sin(angle) * 0.6 * config.scale,
    );
    group.add(spike);
  }
  return group;
}

export const ENEMY_CONFIGS: Record<EnemyType, EnemyConfig> = {
  basic: {
    health: 30,
    speed: 2.0,
    damage: 5,
    reward: 10,
    color: 0xcc4444,
    scale: 1.0,
    meshBuilder: buildBasicMesh,
  },
  fast: {
    health: 15,
    speed: 4.5,
    damage: 3,
    reward: 8,
    color: 0xcccc22,
    scale: 0.7,
    meshBuilder: buildFastMesh,
  },
  tank: {
    health: 120,
    speed: 1.0,
    damage: 15,
    reward: 25,
    color: 0x666644,
    scale: 1.4,
    meshBuilder: buildTankMesh,
  },
  flying: {
    health: 25,
    speed: 3.0,
    damage: 4,
    reward: 15,
    color: 0x8844cc,
    scale: 0.9,
    meshBuilder: buildFlyingMesh,
  },
  swarm: {
    health: 8,
    speed: 3.5,
    damage: 2,
    reward: 3,
    color: 0x44cc44,
    scale: 0.5,
    meshBuilder: buildSwarmMesh,
  },
  shielded: {
    health: 60,
    speed: 1.8,
    damage: 8,
    reward: 20,
    color: 0x4466cc,
    scale: 1.1,
    meshBuilder: buildShieldedMesh,
  },
  boss: {
    health: 500,
    speed: 0.8,
    damage: 30,
    reward: 100,
    color: 0xff2200,
    scale: 2.0,
    meshBuilder: buildBossMesh,
  },
};

function createHealthBar(): THREE.Sprite {
  const canvas = document.createElement("canvas");
  canvas.width = 64;
  canvas.height = 8;
  const ctx = canvas.getContext("2d")!;
  ctx.fillStyle = "#44ff44";
  ctx.fillRect(0, 0, 64, 8);
  const texture = new THREE.CanvasTexture(canvas);
  const mat = new THREE.SpriteMaterial({ map: texture, depthTest: false });
  const sprite = new THREE.Sprite(mat);
  sprite.scale.set(1.2, 0.15, 1);
  sprite.position.y = 1.2;
  return sprite;
}

export function updateHealthBar(enemy: Enemy): void {
  const ratio = Math.max(0, enemy.health / enemy.maxHealth);
  const sprite = enemy.healthBar;
  const mat = sprite.material as THREE.SpriteMaterial;
  const canvas = document.createElement("canvas");
  canvas.width = 64;
  canvas.height = 8;
  const ctx = canvas.getContext("2d")!;
  ctx.fillStyle = "#333";
  ctx.fillRect(0, 0, 64, 8);
  const r = Math.floor(255 * (1 - ratio));
  const g = Math.floor(255 * ratio);
  ctx.fillStyle = `rgb(${r},${g},0)`;
  ctx.fillRect(0, 0, Math.floor(64 * ratio), 8);
  mat.map?.dispose();
  mat.map = new THREE.CanvasTexture(canvas);
}

export function spawnEnemy(
  type: EnemyType,
  scene: THREE.Scene,
  world: CANNON.World,
  waveMultiplier: number,
): Enemy {
  const config = ENEMY_CONFIGS[type];
  const scaledHealth = Math.floor(config.health * waveMultiplier);
  const mesh = config.meshBuilder(config);
  const healthBar = createHealthBar();
  mesh.add(healthBar);

  // Spawn on a sphere around the tower
  const spawnRadius = 40 + Math.random() * 15;
  const theta = Math.random() * Math.PI * 2;
  // Use a bias toward the equator but allow full sphere coverage
  const phi = Math.acos(2 * Math.random() - 1);
  // Clamp so enemies don't spawn directly below ground
  const clampedPhi = Math.min(phi, Math.PI * 0.75);

  const x = spawnRadius * Math.sin(clampedPhi) * Math.cos(theta);
  const y = Math.max(1.0, spawnRadius * Math.cos(clampedPhi));
  const z = spawnRadius * Math.sin(clampedPhi) * Math.sin(theta);

  mesh.position.set(x, y, z);
  scene.add(mesh);

  const bodyShape = new CANNON.Sphere(0.5 * config.scale);
  const body = new CANNON.Body({
    mass: type === "flying" ? 0.1 : 1,
    position: new CANNON.Vec3(x, y, z),
    shape: bodyShape,
    linearDamping: 0.5,
    angularDamping: 0.9,
  });
  world.addBody(body);

  return {
    id: nextEnemyId++,
    mesh,
    body,
    health: scaledHealth,
    maxHealth: scaledHealth,
    speed: config.speed,
    damage: config.damage,
    reward: config.reward,
    type,
    healthBar,
    alive: true,
    stunTimer: 0,
    burnTimer: 0,
    burnDamage: 0,
    slowFactor: 1,
    slowTimer: 0,
  };
}

export function updateEnemy(enemy: Enemy, dt: number, towerPosition: THREE.Vector3): void {
  if (!enemy.alive) return;

  // Status effect timers
  if (enemy.stunTimer > 0) {
    enemy.stunTimer -= dt;
    return; // stunned, don't move
  }
  if (enemy.slowTimer > 0) {
    enemy.slowTimer -= dt;
    if (enemy.slowTimer <= 0) enemy.slowFactor = 1;
  }
  if (enemy.burnTimer > 0) {
    enemy.burnTimer -= dt;
    enemy.health -= enemy.burnDamage * dt;
  }

  // Move toward tower
  const dir = new CANNON.Vec3(
    towerPosition.x - enemy.body.position.x,
    towerPosition.y - enemy.body.position.y,
    towerPosition.z - enemy.body.position.z,
  );
  const dist = dir.length();
  if (dist > 0.1) {
    dir.scale(1 / dist, dir);
    const speed = enemy.speed * enemy.slowFactor;
    enemy.body.velocity.set(dir.x * speed, dir.y * speed, dir.z * speed);
  }

  // Sync mesh to physics body
  enemy.mesh.position.set(enemy.body.position.x, enemy.body.position.y, enemy.body.position.z);
  enemy.mesh.quaternion.set(
    enemy.body.quaternion.x,
    enemy.body.quaternion.y,
    enemy.body.quaternion.z,
    enemy.body.quaternion.w,
  );

  // Animate flying enemies bob
  if (enemy.type === "flying") {
    enemy.mesh.position.y += Math.sin(Date.now() * 0.003 + enemy.id) * 0.02;
  }
}

export function getWaveEnemies(wave: number): EnemyType[] {
  const enemies: EnemyType[] = [];
  const baseCount = 5 + wave * 2;

  // Always have some basics
  for (let i = 0; i < baseCount; i++) enemies.push("basic");

  // Introduce types as waves progress
  if (wave >= 2) {
    for (let i = 0; i < Math.floor(wave * 1.5); i++) enemies.push("fast");
  }
  if (wave >= 3) {
    for (let i = 0; i < Math.floor(wave * 0.5); i++) enemies.push("swarm");
    for (let i = 0; i < Math.floor(wave * 0.8); i++) enemies.push("swarm");
  }
  if (wave >= 4) {
    for (let i = 0; i < Math.floor(wave * 0.4); i++) enemies.push("tank");
  }
  if (wave >= 5) {
    for (let i = 0; i < Math.floor(wave * 0.5); i++) enemies.push("flying");
  }
  if (wave >= 7) {
    for (let i = 0; i < Math.floor(wave * 0.3); i++) enemies.push("shielded");
  }
  if (wave % 5 === 0 && wave > 0) {
    enemies.push("boss");
  }

  return enemies;
}
