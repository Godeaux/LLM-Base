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

// --- Lights ---
const ambient = new THREE.AmbientLight(0x404060, 0.6);
scene.add(ambient);

const sun = new THREE.DirectionalLight(0xffeedd, 1.2);
sun.position.set(30, 40, 20);
sun.castShadow = true;
sun.shadow.mapSize.width = 2048;
sun.shadow.mapSize.height = 2048;
sun.shadow.camera.near = 1;
sun.shadow.camera.far = 100;
sun.shadow.camera.left = -50;
sun.shadow.camera.right = 50;
sun.shadow.camera.top = 50;
sun.shadow.camera.bottom = -50;
scene.add(sun);

// --- Ground plane ---
const groundGeo = new THREE.CircleGeometry(60, 64);
const groundMat = new THREE.MeshStandardMaterial({ color: 0x2d5a27 });
const ground = new THREE.Mesh(groundGeo, groundMat);
ground.rotation.x = -Math.PI / 2;
ground.receiveShadow = true;
scene.add(ground);

// --- Spawn ring indicator ---
const ringGeo = new THREE.RingGeometry(44, 46, 64);
const ringMat = new THREE.MeshBasicMaterial({
  color: 0x660000,
  transparent: true,
  opacity: 0.2,
  side: THREE.DoubleSide,
});
const ring = new THREE.Mesh(ringGeo, ringMat);
ring.rotation.x = -Math.PI / 2;
ring.position.y = 0.05;
scene.add(ring);

// --- Tower (visual) ---
const towerGroup = new THREE.Group();

// Base
const baseGeo = new THREE.CylinderGeometry(2, 2.5, 1, 8);
const towerMat = new THREE.MeshStandardMaterial({ color: 0x888899 });
const base = new THREE.Mesh(baseGeo, towerMat);
base.position.y = 0.5;
base.castShadow = true;
towerGroup.add(base);

// Shaft
const shaftGeo = new THREE.CylinderGeometry(1, 1.5, 4, 8);
const shaft = new THREE.Mesh(shaftGeo, towerMat);
shaft.position.y = 3;
shaft.castShadow = true;
towerGroup.add(shaft);

// Top / turret
const topGeo = new THREE.CylinderGeometry(1.5, 1, 1.5, 8);
const topMat = new THREE.MeshStandardMaterial({ color: 0x6666aa });
const top = new THREE.Mesh(topGeo, topMat);
top.position.y = 5.5;
top.castShadow = true;
towerGroup.add(top);

// Crenellations
for (let i = 0; i < 8; i++) {
  const angle = (i / 8) * Math.PI * 2;
  const cren = new THREE.Mesh(
    new THREE.BoxGeometry(0.4, 0.5, 0.4),
    topMat,
  );
  cren.position.set(Math.cos(angle) * 1.3, 6.5, Math.sin(angle) * 1.3);
  cren.castShadow = true;
  towerGroup.add(cren);
}

scene.add(towerGroup);

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
const PHYSICS_DT = 1 / 60;
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
