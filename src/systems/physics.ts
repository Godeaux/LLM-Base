import * as CANNON from "cannon-es";

// Collision groups
export const GROUP_GROUND = 1;
export const GROUP_TOWER = 2;
export const GROUP_ENEMY = 4;
export const GROUP_PROJECTILE = 8;

export function createPhysicsWorld(): CANNON.World {
  const world = new CANNON.World();
  world.gravity.set(0, -20, 0);
  world.broadphase = new CANNON.NaiveBroadphase();
  world.allowSleep = false;

  // Ground plane
  const groundBody = new CANNON.Body({
    mass: 0,
    shape: new CANNON.Plane(),
    collisionFilterGroup: GROUP_GROUND,
    collisionFilterMask: GROUP_ENEMY | GROUP_PROJECTILE,
  });
  groundBody.quaternion.setFromEuler(-Math.PI / 2, 0, 0);
  world.addBody(groundBody);

  // Tower body (static cylinder approximated as a box)
  const towerBody = new CANNON.Body({
    mass: 0,
    shape: new CANNON.Cylinder(1, 1.5, 6, 8),
    position: new CANNON.Vec3(0, 3, 0),
    collisionFilterGroup: GROUP_TOWER,
    collisionFilterMask: GROUP_ENEMY,
  });
  world.addBody(towerBody);

  return world;
}
