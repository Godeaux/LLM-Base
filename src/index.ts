import * as THREE from "three";
import { OrbitControls } from "three/addons/controls/OrbitControls.js";
import { createPhysicsWorld } from "./systems/physics.js";
import { createInitialState } from "./state.js";
import { updateEnemies } from "./entities/enemy.js";
import { updateProjectiles, updateArcaneHoming } from "./entities/projectile.js";
import { checkProjectileHits } from "./systems/damage.js";
import { updateTowerCombat } from "./systems/combat.js";
import { updateLightningArcs } from "./systems/lightning.js";
import { updateWaves } from "./systems/waves.js";
import { syncRenderer, cleanupDeadEntities } from "./systems/renderer.js";
import { createHUD, updateHUD } from "./systems/hud.js";
import { PHYSICS } from "./config.js";
import { buildScene } from "./systems/scene.js";

// --- Renderer ---
const renderer = new THREE.WebGLRenderer({ antialias: true });
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.setPixelRatio(window.devicePixelRatio);
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;
document.body.appendChild(renderer.domElement);

// --- Scene ---
const scene = new THREE.Scene();
scene.background = new THREE.Color(0x1a1a2e);
scene.fog = new THREE.Fog(0x1a1a2e, 60, 120);

// --- Camera (free-fly orbit) ---
const camera = new THREE.PerspectiveCamera(
  60,
  window.innerWidth / window.innerHeight,
  0.1,
  500,
);
camera.position.set(20, 15, 20);

const controls = new OrbitControls(camera, renderer.domElement);
controls.enableDamping = true;
controls.dampingFactor = 0.1;
controls.target.set(0, 3, 0);
controls.maxDistance = 80;
controls.minDistance = 5;

// --- Build static scene objects (lights, ground, tower visual) ---
buildScene(scene);

// --- Physics World ---
const world = createPhysicsWorld();

// --- Game State ---
const state = createInitialState();

// --- HUD ---
createHUD(state);

// --- Resize handler ---
window.addEventListener("resize", () => {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
});

// --- Fixed timestep game loop ---
const PHYSICS_DT = PHYSICS.tickRate;
let accumulator = 0;
let lastTime = performance.now();

function gameLoop(now: number): void {
  requestAnimationFrame(gameLoop);

  const frameTime = Math.min((now - lastTime) / 1000, 0.1); // cap at 100ms
  lastTime = now;

  if (state.tower.hp > 0) {
    accumulator += frameTime;

    while (accumulator >= PHYSICS_DT) {
      state.time += PHYSICS_DT;
      state.deltaTime = PHYSICS_DT;

      // Game systems
      updateWaves(state, world, PHYSICS_DT);
      updateEnemies(state, PHYSICS_DT);
      updateTowerCombat(state, world, PHYSICS_DT);
      updateArcaneHoming(state);
      updateProjectiles(state, PHYSICS_DT);
      checkProjectileHits(state);
      updateLightningArcs(state, PHYSICS_DT);

      // Physics step
      world.step(PHYSICS_DT);

      accumulator -= PHYSICS_DT;
    }

    // Cleanup dead entities (remove bodies + meshes)
    cleanupDeadEntities(state, world);
  }

  // Render (every frame, not tied to physics rate)
  syncRenderer(state, scene);
  updateHUD(state);
  controls.update();
  renderer.render(scene, camera);
}

requestAnimationFrame(gameLoop);
