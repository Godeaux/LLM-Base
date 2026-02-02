import * as THREE from "three";

/** Build and return all static scene objects (ground, lights, tower visual, spawn ring). */
export function buildScene(scene: THREE.Scene): void {
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

  // --- Tower (visual only — physics tower is in physics.ts) ---
  const towerGroup = new THREE.Group();
  const towerMat = new THREE.MeshStandardMaterial({ color: 0x888899 });

  // Base
  const baseGeo = new THREE.CylinderGeometry(2, 2.5, 1, 8);
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
}
