import * as THREE from "three";
import { OrbitControls } from "three/addons/controls/OrbitControls.js";

// --- Renderer ---
const renderer = new THREE.WebGLRenderer({ antialias: true });
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.setPixelRatio(window.devicePixelRatio);
renderer.shadowMap.enabled = true;
document.body.appendChild(renderer.domElement);

// --- Scene ---
const scene = new THREE.Scene();
scene.background = new THREE.Color(0x1a1a2e);
scene.fog = new THREE.Fog(0x1a1a2e, 80, 150);

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

// --- Lights ---
const ambient = new THREE.AmbientLight(0x404060, 0.6);
scene.add(ambient);

const sun = new THREE.DirectionalLight(0xffeedd, 1.2);
sun.position.set(30, 40, 20);
sun.castShadow = true;
scene.add(sun);

// --- Ground plane ---
const groundGeo = new THREE.CircleGeometry(60, 64);
const groundMat = new THREE.MeshStandardMaterial({ color: 0x2d5a27 });
const ground = new THREE.Mesh(groundGeo, groundMat);
ground.rotation.x = -Math.PI / 2;
ground.receiveShadow = true;
scene.add(ground);

// --- Tower (placeholder) ---
const towerGeo = new THREE.CylinderGeometry(1, 1.5, 6, 8);
const towerMat = new THREE.MeshStandardMaterial({ color: 0x888899 });
const tower = new THREE.Mesh(towerGeo, towerMat);
tower.position.set(0, 3, 0);
tower.castShadow = true;
scene.add(tower);

// --- Resize handler ---
window.addEventListener("resize", () => {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
});

// --- Render loop ---
function animate(): void {
  requestAnimationFrame(animate);
  controls.update();
  renderer.render(scene, camera);
}

animate();
