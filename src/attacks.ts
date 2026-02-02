import * as THREE from "three";
import { AttackConfig, AttackType, Enemy, Projectile, ParticleSystem } from "./types.js";

export const ATTACK_CONFIGS: AttackConfig[] = [
  {
    name: "Chain Lightning",
    type: "lightning",
    damage: 15,
    cooldown: 0.8,
    range: 30,
    color: 0x44ccff,
    description: "Arcs between enemies",
    level: 1,
  },
  {
    name: "Fireball",
    type: "fireball",
    damage: 40,
    cooldown: 1.5,
    range: 35,
    color: 0xff6622,
    description: "Explosive AoE damage",
    level: 1,
  },
  {
    name: "Blizzard",
    type: "blizzard",
    damage: 8,
    cooldown: 2.5,
    range: 25,
    color: 0xaaddff,
    description: "Slows all nearby enemies",
    level: 1,
  },
  {
    name: "Death Ray",
    type: "laser",
    damage: 60,
    cooldown: 3.0,
    range: 45,
    color: 0xff0044,
    description: "Piercing beam attack",
    level: 1,
  },
  {
    name: "Meteor Storm",
    type: "meteor",
    damage: 80,
    cooldown: 5.0,
    range: 40,
    color: 0xff8800,
    description: "Rains destruction from above",
    level: 1,
  },
  {
    name: "Gravity Vortex",
    type: "vortex",
    damage: 20,
    cooldown: 4.0,
    range: 30,
    color: 0x9933ff,
    description: "Pulls and damages enemies",
    level: 1,
  },
];

export function findTarget(
  enemies: Enemy[],
  towerPos: THREE.Vector3,
  range: number,
): Enemy | null {
  let closest: Enemy | null = null;
  let closestDist = range;
  for (const enemy of enemies) {
    if (!enemy.alive) continue;
    const dist = new THREE.Vector3(
      enemy.mesh.position.x,
      enemy.mesh.position.y,
      enemy.mesh.position.z,
    ).distanceTo(towerPos);
    if (dist < closestDist) {
      closestDist = dist;
      closest = enemy;
    }
  }
  return closest;
}

export function findEnemiesInRadius(
  enemies: Enemy[],
  center: THREE.Vector3,
  radius: number,
): Enemy[] {
  return enemies.filter((e) => {
    if (!e.alive) return false;
    return e.mesh.position.distanceTo(center) < radius;
  });
}

export function createLightningProjectile(
  from: THREE.Vector3,
  target: Enemy,
  damage: number,
  enemies: Enemy[],
  level: number,
): Projectile {
  // Create lightning bolt visual as a line
  const points = [from.clone(), target.mesh.position.clone()];
  const midCount = 4 + level;
  const actualPoints: THREE.Vector3[] = [points[0]!.clone()];
  for (let i = 1; i <= midCount; i++) {
    const t = i / (midCount + 1);
    const p = new THREE.Vector3().lerpVectors(points[0]!, points[1]!, t);
    p.x += (Math.random() - 0.5) * 2;
    p.y += (Math.random() - 0.5) * 2;
    p.z += (Math.random() - 0.5) * 2;
    actualPoints.push(p);
  }
  actualPoints.push(points[1]!.clone());

  const geo = new THREE.BufferGeometry().setFromPoints(actualPoints);
  const mat = new THREE.LineBasicMaterial({ color: 0x44ccff, linewidth: 2 });
  const line = new THREE.Line(geo, mat);

  // Chain targets
  const chainCount = 2 + level;
  const chainTargets: Enemy[] = [];
  let lastPos = target.mesh.position.clone();
  const visited = new Set<number>([target.id]);
  for (let c = 0; c < chainCount; c++) {
    let best: Enemy | null = null;
    let bestDist = 10;
    for (const e of enemies) {
      if (!e.alive || visited.has(e.id)) continue;
      const d = e.mesh.position.distanceTo(lastPos);
      if (d < bestDist) {
        bestDist = d;
        best = e;
      }
    }
    if (best) {
      chainTargets.push(best);
      visited.add(best.id);
      lastPos = best.mesh.position.clone();
    }
  }

  return {
    mesh: line,
    target,
    position: from.clone(),
    velocity: new THREE.Vector3(),
    damage,
    attackType: "lightning",
    lifetime: 0.15,
    chainTargets,
  };
}

export function createFireballProjectile(
  from: THREE.Vector3,
  target: Enemy,
  damage: number,
  level: number,
): Projectile {
  const group = new THREE.Group();
  const coreGeo = new THREE.SphereGeometry(0.3 + level * 0.05, 8, 8);
  const coreMat = new THREE.MeshBasicMaterial({ color: 0xff6622 });
  group.add(new THREE.Mesh(coreGeo, coreMat));
  const glowGeo = new THREE.SphereGeometry(0.5 + level * 0.08, 8, 8);
  const glowMat = new THREE.MeshBasicMaterial({
    color: 0xff4400,
    transparent: true,
    opacity: 0.4,
  });
  group.add(new THREE.Mesh(glowGeo, glowMat));
  group.position.copy(from);

  const dir = new THREE.Vector3().subVectors(target.mesh.position, from).normalize();
  const speed = 20;

  return {
    mesh: group,
    target,
    position: from.clone(),
    velocity: dir.multiplyScalar(speed),
    damage,
    attackType: "fireball",
    lifetime: 3.0,
    aoeRadius: 4 + level,
  };
}

export function createLaserProjectile(
  from: THREE.Vector3,
  target: Enemy,
  damage: number,
  _level: number,
): Projectile {
  const dir = new THREE.Vector3().subVectors(target.mesh.position, from).normalize();
  const far = from.clone().add(dir.clone().multiplyScalar(50));
  const geo = new THREE.BufferGeometry().setFromPoints([from.clone(), far]);
  const mat = new THREE.LineBasicMaterial({ color: 0xff0044, linewidth: 3 });
  const line = new THREE.Line(geo, mat);

  return {
    mesh: line,
    target,
    position: from.clone(),
    velocity: new THREE.Vector3(),
    damage,
    attackType: "laser",
    lifetime: 0.3,
  };
}

export function createMeteorProjectile(
  _from: THREE.Vector3,
  target: Enemy,
  damage: number,
  level: number,
): Projectile {
  const group = new THREE.Group();
  const size = 0.6 + level * 0.1;
  const rockGeo = new THREE.IcosahedronGeometry(size, 0);
  const rockMat = new THREE.MeshStandardMaterial({
    color: 0x884400,
    emissive: 0xff4400,
    emissiveIntensity: 0.5,
  });
  group.add(new THREE.Mesh(rockGeo, rockMat));
  const trailGeo = new THREE.ConeGeometry(size * 0.7, size * 2, 6);
  const trailMat = new THREE.MeshBasicMaterial({
    color: 0xff6600,
    transparent: true,
    opacity: 0.5,
  });
  const trail = new THREE.Mesh(trailGeo, trailMat);
  trail.position.y = size * 1.5;
  group.add(trail);

  // Start high above target
  const startPos = target.mesh.position.clone().add(new THREE.Vector3(0, 30, 0));
  group.position.copy(startPos);

  return {
    mesh: group,
    target,
    position: startPos.clone(),
    velocity: new THREE.Vector3(0, -25, 0),
    damage,
    attackType: "meteor",
    lifetime: 2.0,
    aoeRadius: 6 + level,
  };
}

export function createVortexEffect(
  center: THREE.Vector3,
  _damage: number,
  level: number,
): Projectile {
  const group = new THREE.Group();
  const ringCount = 3 + level;
  for (let i = 0; i < ringCount; i++) {
    const ringGeo = new THREE.RingGeometry(1 + i * 1.5, 1.5 + i * 1.5, 32);
    const ringMat = new THREE.MeshBasicMaterial({
      color: 0x9933ff,
      transparent: true,
      opacity: 0.4 - i * 0.05,
      side: THREE.DoubleSide,
    });
    const ring = new THREE.Mesh(ringGeo, ringMat);
    ring.position.copy(center);
    ring.rotation.x = Math.random() * Math.PI;
    ring.rotation.y = Math.random() * Math.PI;
    group.add(ring);
  }

  return {
    mesh: group,
    target: null,
    position: center.clone(),
    velocity: new THREE.Vector3(),
    damage: 0,
    attackType: "vortex",
    lifetime: 2.0,
    aoeRadius: 12 + level * 2,
  };
}

export function createParticleExplosion(
  position: THREE.Vector3,
  color: number,
  count: number,
): ParticleSystem {
  const positions = new Float32Array(count * 3);
  const velocities = new Float32Array(count * 3);
  const lifetimes = new Float32Array(count);
  const maxLifetimes = new Float32Array(count);

  for (let i = 0; i < count; i++) {
    positions[i * 3] = position.x;
    positions[i * 3 + 1] = position.y;
    positions[i * 3 + 2] = position.z;

    const speed = 2 + Math.random() * 8;
    const theta = Math.random() * Math.PI * 2;
    const phi = Math.acos(2 * Math.random() - 1);
    velocities[i * 3] = Math.sin(phi) * Math.cos(theta) * speed;
    velocities[i * 3 + 1] = Math.sin(phi) * Math.sin(theta) * speed;
    velocities[i * 3 + 2] = Math.cos(phi) * speed;

    lifetimes[i] = 0;
    maxLifetimes[i] = 0.5 + Math.random() * 1.0;
  }

  const geo = new THREE.BufferGeometry();
  geo.setAttribute("position", new THREE.BufferAttribute(positions, 3));

  const mat = new THREE.PointsMaterial({
    color,
    size: 0.3,
    transparent: true,
    opacity: 1,
    blending: THREE.AdditiveBlending,
    depthWrite: false,
  });

  const points = new THREE.Points(geo, mat);

  return {
    points,
    velocities,
    lifetimes,
    maxLifetimes,
    count,
    elapsed: 0,
    duration: 1.5,
  };
}

export function updateParticles(system: ParticleSystem, dt: number): boolean {
  system.elapsed += dt;
  if (system.elapsed > system.duration) return true;

  const positions = system.points.geometry.attributes["position"]!.array as Float32Array;

  for (let i = 0; i < system.count; i++) {
    system.lifetimes[i]! += dt;
    if (system.lifetimes[i]! > system.maxLifetimes[i]!) continue;

    positions[i * 3]! += system.velocities[i * 3]! * dt;
    positions[i * 3 + 1]! += system.velocities[i * 3 + 1]! * dt - 4.9 * dt * dt;
    positions[i * 3 + 2]! += system.velocities[i * 3 + 2]! * dt;
  }
  system.points.geometry.attributes["position"]!.needsUpdate = true;

  const mat = system.points.material as THREE.PointsMaterial;
  mat.opacity = Math.max(0, 1 - system.elapsed / system.duration);

  return false;
}
