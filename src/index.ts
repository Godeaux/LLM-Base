import * as THREE from "three";
import { createScene, SceneContext } from "./scene.js";
import { createTowerState, createTowerMesh, getUpgradeCost, getAttackUpgradeCost, animateTower } from "./tower.js";
import { spawnEnemy, updateEnemy, updateHealthBar, getWaveEnemies } from "./enemies.js";
import {
  findTarget,
  findEnemiesInRadius,
  createLightningProjectile,
  createFireballProjectile,
  createLaserProjectile,
  createMeteorProjectile,
  createVortexEffect,
  createParticleExplosion,
  updateParticles,
} from "./attacks.js";
import { initUI, updateUI, showWaveBanner } from "./ui.js";
import { Enemy, Projectile, ParticleSystem, TowerState } from "./types.js";

// --- Game State ---
let ctx: SceneContext;
let towerState: TowerState;
let towerMesh: THREE.Group;
let enemies: Enemy[] = [];
let projectiles: Projectile[] = [];
let particles: ParticleSystem[] = [];
let spawnQueue: string[] = [];
let spawnTimer = 0;
const SPAWN_INTERVAL = 0.4;
const TOWER_POS = new THREE.Vector3(0, 4, 0);
const DAMAGE_RANGE = 2.5;
let cameraAngle = 0;
let lastTime = 0;

function init(): void {
  ctx = createScene();
  towerState = createTowerState();
  towerMesh = createTowerMesh(towerState.level);
  ctx.scene.add(towerMesh);

  initUI(handleUpgrade);

  // Start first wave
  startWave(1);

  // Camera orbit with mouse
  let isDragging = false;
  let prevX = 0;
  let cameraDistance = 30;
  let cameraHeight = 25;

  ctx.renderer.domElement.addEventListener("mousedown", (e) => {
    isDragging = true;
    prevX = e.clientX;
  });
  window.addEventListener("mouseup", () => {
    isDragging = false;
  });
  window.addEventListener("mousemove", (e) => {
    if (!isDragging) return;
    cameraAngle += (e.clientX - prevX) * 0.005;
    prevX = e.clientX;
  });
  ctx.renderer.domElement.addEventListener("wheel", (e) => {
    cameraDistance = Math.max(15, Math.min(60, cameraDistance + e.deltaY * 0.05));
    cameraHeight = Math.max(8, Math.min(40, cameraHeight + e.deltaY * 0.02));
  });

  // Auto-orbit
  function updateCamera(): void {
    if (!isDragging) {
      cameraAngle += 0.001;
    }
    ctx.camera.position.x = Math.cos(cameraAngle) * cameraDistance;
    ctx.camera.position.z = Math.sin(cameraAngle) * cameraDistance;
    ctx.camera.position.y = cameraHeight;
    ctx.camera.lookAt(0, 5, 0);
  }

  // Game loop
  function gameLoop(time: number): void {
    requestAnimationFrame(gameLoop);
    const dt = Math.min((time - lastTime) / 1000, 0.05);
    lastTime = time;

    updateCamera();
    ctx.world.step(1 / 60, dt, 3);

    updateSpawning(dt);
    updateEnemies(dt);
    updateAttacks(dt);
    updateProjectiles(dt);
    updateParticleSystems(dt);
    animateTower(towerMesh, time / 1000, towerState.level);
    checkWaveComplete();
    updateUI(towerState);

    ctx.renderer.render(ctx.scene, ctx.camera);
  }

  requestAnimationFrame(gameLoop);
}

function startWave(wave: number): void {
  towerState.wave = wave;
  towerState.waveActive = true;
  const waveEnemies = getWaveEnemies(wave);
  spawnQueue = [...waveEnemies];
  towerState.enemiesRemaining = spawnQueue.length;
  spawnTimer = 0;
  showWaveBanner(wave);
}

function updateSpawning(dt: number): void {
  if (spawnQueue.length === 0) return;
  spawnTimer += dt;
  if (spawnTimer >= SPAWN_INTERVAL) {
    spawnTimer = 0;
    const type = spawnQueue.pop();
    if (type) {
      const waveMultiplier = 1 + (towerState.wave - 1) * 0.3;
      const enemy = spawnEnemy(
        type as Enemy["type"],
        ctx.scene,
        ctx.world,
        waveMultiplier,
      );
      enemies.push(enemy);
    }
  }
}

function updateEnemies(dt: number): void {
  for (const enemy of enemies) {
    if (!enemy.alive) continue;
    updateEnemy(enemy, dt, TOWER_POS);
    updateHealthBar(enemy);

    // Check if enemy reached tower
    const dist = enemy.mesh.position.distanceTo(TOWER_POS);
    if (dist < DAMAGE_RANGE) {
      towerState.health -= enemy.damage * dt;
      // Push enemy back slightly
      const pushDir = new THREE.Vector3()
        .subVectors(enemy.mesh.position, TOWER_POS)
        .normalize()
        .multiplyScalar(3);
      enemy.body.velocity.set(pushDir.x, pushDir.y, pushDir.z);
    }

    // Check death
    if (enemy.health <= 0) {
      killEnemy(enemy);
    }
  }

  // Tower death -> reset
  if (towerState.health <= 0) {
    towerState.health = towerState.maxHealth;
    // Lose some gold on death
    towerState.gold = Math.floor(towerState.gold * 0.7);
  }

  // Cleanup dead enemies
  enemies = enemies.filter((e) => {
    if (!e.alive) return false;
    // Remove if too far away (somehow escaped)
    if (e.mesh.position.length() > 80) {
      removeEnemyFromScene(e);
      return false;
    }
    return true;
  });
}

function killEnemy(enemy: Enemy): void {
  enemy.alive = false;
  towerState.gold += enemy.reward;
  towerState.kills++;
  towerState.enemiesRemaining--;

  // Death particles
  const color =
    enemy.type === "boss"
      ? 0xff8800
      : enemy.type === "tank"
        ? 0x888866
        : enemy.type === "fast"
          ? 0xcccc44
          : 0xff4444;
  const particleCount = enemy.type === "boss" ? 60 : 20;
  const ps = createParticleExplosion(enemy.mesh.position.clone(), color, particleCount);
  ctx.scene.add(ps.points);
  particles.push(ps);

  removeEnemyFromScene(enemy);
}

function removeEnemyFromScene(enemy: Enemy): void {
  ctx.scene.remove(enemy.mesh);
  ctx.world.removeBody(enemy.body);
  // Dispose geometries and materials
  enemy.mesh.traverse((child) => {
    if (child instanceof THREE.Mesh) {
      child.geometry.dispose();
      if (Array.isArray(child.material)) {
        child.material.forEach((m) => m.dispose());
      } else {
        child.material.dispose();
      }
    }
  });
}

function updateAttacks(dt: number): void {
  for (let i = 0; i < towerState.attacks.length; i++) {
    const attack = towerState.attacks[i]!;
    const timer = towerState.attackTimers[i]!;

    if (timer > 0) {
      towerState.attackTimers[i] = timer - dt;
      continue;
    }

    const scaledDamage = attack.damage * (1 + (attack.level - 1) * 0.3);
    const scaledRange = attack.range * (1 + (attack.level - 1) * 0.1);
    const scaledCooldown = attack.cooldown * Math.max(0.3, 1 - (attack.level - 1) * 0.05);

    const target = findTarget(enemies, TOWER_POS, scaledRange);
    if (!target) continue;

    towerState.attackTimers[i] = scaledCooldown;

    let proj: Projectile | null = null;

    switch (attack.type) {
      case "lightning":
        proj = createLightningProjectile(
          TOWER_POS.clone().add(new THREE.Vector3(0, 2, 0)),
          target,
          scaledDamage,
          enemies,
          attack.level,
        );
        // Apply damage immediately for lightning
        target.health -= scaledDamage;
        target.stunTimer = 0.2;
        if (proj.chainTargets) {
          for (const ct of proj.chainTargets) {
            ct.health -= scaledDamage * 0.6;
            ct.stunTimer = 0.15;
          }
        }
        break;
      case "fireball":
        proj = createFireballProjectile(
          TOWER_POS.clone().add(new THREE.Vector3(0, 3, 0)),
          target,
          scaledDamage,
          attack.level,
        );
        break;
      case "blizzard": {
        const affected = findEnemiesInRadius(enemies, TOWER_POS, scaledRange);
        for (const e of affected) {
          e.health -= scaledDamage;
          e.slowFactor = 0.3;
          e.slowTimer = 3;
        }
        // Create blizzard visual
        const blizzardPs = createParticleExplosion(
          TOWER_POS.clone().add(new THREE.Vector3(0, 3, 0)),
          0xaaddff,
          40 + attack.level * 10,
        );
        ctx.scene.add(blizzardPs.points);
        particles.push(blizzardPs);
        break;
      }
      case "laser":
        proj = createLaserProjectile(
          TOWER_POS.clone().add(new THREE.Vector3(0, 4, 0)),
          target,
          scaledDamage,
          attack.level,
        );
        // Laser hits all enemies in line
        {
          const laserDir = new THREE.Vector3()
            .subVectors(target.mesh.position, TOWER_POS)
            .normalize();
          for (const e of enemies) {
            if (!e.alive) continue;
            const toEnemy = new THREE.Vector3().subVectors(e.mesh.position, TOWER_POS);
            const proj2 = toEnemy.dot(laserDir);
            if (proj2 < 0) continue;
            const closest = TOWER_POS.clone().add(laserDir.clone().multiplyScalar(proj2));
            if (closest.distanceTo(e.mesh.position) < 1.5) {
              e.health -= scaledDamage;
            }
          }
        }
        break;
      case "meteor": {
        // Spawn multiple meteors
        const meteorCount = 1 + Math.floor(attack.level / 2);
        for (let m = 0; m < meteorCount; m++) {
          const meteorTarget =
            m === 0 ? target : findTarget(enemies, TOWER_POS, scaledRange) ?? target;
          const mProj = createMeteorProjectile(TOWER_POS, meteorTarget, scaledDamage, attack.level);
          ctx.scene.add(mProj.mesh);
          projectiles.push(mProj);
        }
        break;
      }
      case "vortex": {
        const vortex = createVortexEffect(target.mesh.position.clone(), scaledDamage, attack.level);
        ctx.scene.add(vortex.mesh);
        projectiles.push(vortex);
        // Pull and damage enemies
        const vortexTargets = findEnemiesInRadius(
          enemies,
          target.mesh.position,
          vortex.aoeRadius ?? 12,
        );
        for (const e of vortexTargets) {
          e.health -= scaledDamage;
          // Pull toward vortex center
          const pullDir = new THREE.Vector3()
            .subVectors(target.mesh.position, e.mesh.position)
            .normalize()
            .multiplyScalar(5);
          e.body.velocity.set(pullDir.x, pullDir.y, pullDir.z);
          e.stunTimer = 0.5;
        }
        break;
      }
    }

    if (proj && attack.type !== "meteor") {
      ctx.scene.add(proj.mesh);
      projectiles.push(proj);
    }
  }
}

function updateProjectiles(dt: number): void {
  projectiles = projectiles.filter((proj) => {
    proj.lifetime -= dt;
    if (proj.lifetime <= 0) {
      // Fireball/meteor AoE on expire or on reaching target
      if (
        (proj.attackType === "fireball" || proj.attackType === "meteor") &&
        proj.aoeRadius
      ) {
        const affected = findEnemiesInRadius(enemies, proj.position, proj.aoeRadius);
        for (const e of affected) {
          e.health -= proj.damage * 0.5;
          if (proj.attackType === "fireball") {
            e.burnTimer = 3;
            e.burnDamage = proj.damage * 0.1;
          }
        }
        const ps = createParticleExplosion(
          proj.position.clone(),
          proj.attackType === "fireball" ? 0xff6622 : 0xff8800,
          30,
        );
        ctx.scene.add(ps.points);
        particles.push(ps);
      }
      ctx.scene.remove(proj.mesh);
      disposeMesh(proj.mesh);
      return false;
    }

    // Move projectile
    if (proj.velocity.length() > 0) {
      proj.position.add(proj.velocity.clone().multiplyScalar(dt));
      proj.mesh.position.copy(proj.position);

      // Check if fireball/meteor reached target area
      if (proj.target && proj.target.alive) {
        const dist = proj.position.distanceTo(proj.target.mesh.position);
        if (dist < 2) {
          proj.lifetime = 0; // trigger AoE next frame
        }
      }
    }

    // Animate vortex
    if (proj.attackType === "vortex") {
      proj.mesh.rotation.y += dt * 3;
      proj.mesh.children.forEach((child, i) => {
        child.rotation.z += dt * (1 + i * 0.5);
      });
    }

    return true;
  });
}

function updateParticleSystems(dt: number): void {
  particles = particles.filter((ps) => {
    const done = updateParticles(ps, dt);
    if (done) {
      ctx.scene.remove(ps.points);
      ps.points.geometry.dispose();
      (ps.points.material as THREE.PointsMaterial).dispose();
      return false;
    }
    return true;
  });
}

function checkWaveComplete(): void {
  if (!towerState.waveActive) return;
  if (spawnQueue.length === 0 && enemies.length === 0) {
    towerState.waveActive = false;
    // Brief pause then next wave
    setTimeout(() => {
      startWave(towerState.wave + 1);
    }, 3000);
  }
}

function handleUpgrade(type: string, index?: number): void {
  if (type === "tower") {
    const cost = getUpgradeCost(towerState.level);
    if (towerState.gold >= cost) {
      towerState.gold -= cost;
      towerState.level++;
      towerState.maxHealth = 100 + towerState.level * 30;
      towerState.health = towerState.maxHealth;
      // Rebuild tower mesh
      ctx.scene.remove(towerMesh);
      towerMesh = createTowerMesh(towerState.level);
      ctx.scene.add(towerMesh);
    }
  } else if (type === "attack" && index !== undefined) {
    const attack = towerState.attacks[index];
    if (!attack) return;
    const cost = getAttackUpgradeCost(attack.level);
    if (towerState.gold >= cost) {
      towerState.gold -= cost;
      attack.level++;
    }
  }
}

function disposeMesh(obj: THREE.Object3D): void {
  obj.traverse((child) => {
    if (child instanceof THREE.Mesh) {
      child.geometry.dispose();
      if (Array.isArray(child.material)) {
        child.material.forEach((m) => m.dispose());
      } else {
        child.material.dispose();
      }
    } else if (child instanceof THREE.Line) {
      child.geometry.dispose();
      if (Array.isArray(child.material)) {
        child.material.forEach((m) => m.dispose());
      } else {
        child.material.dispose();
      }
    }
  });
}

// Boot
init();
