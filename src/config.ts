/**
 * ============================================================
 *  TUNABLE GAME PARAMETERS
 *  Edit these values to balance / upgrade attack types.
 *  Grouped by attack type so you can find everything in one place.
 * ============================================================
 */

// ----- TOWER -----
export const TOWER = {
  hp: 10,
  maxHp: 10,
};

// ----- FIREBALL -----
export const FIREBALL = {
  fireRate: 1.0,       // shots per second
  damage: 2.5,         // direct hit damage
  speed: 20,           // projectile speed
  knockback: 22,       // impulse on direct hit
  splashRadius: 5,     // area of effect radius
  splashForce: 14,     // outward push force on splash
  splashDamageMult: 0.5, // splash damage = damage * this * falloff
  projectileRadius: 0.35,
  mass: 2,
  launchAngleMin: Math.PI / 5,
  launchAngleMax: Math.PI / 3,
  maxAge: 6,           // seconds before projectile expires
  hitRadius: 1.0,      // direct hit detection radius
};

// ----- ARROW -----
export const ARROW = {
  fireRate: 2.5,       // shots per second
  damage: 1,
  speed: 45,
  knockback: 8,
  projectileRadius: 0.1,
  mass: 0.3,
  launchAngleMin: Math.PI / 12,
  launchAngleMax: Math.PI / 5,
  maxAge: 4,
  hitRadius: 0.7,
};

// ----- ARCANE BOLT -----
export const ARCANE = {
  fireRate: 0.8,       // shots per second
  damage: 1.8,
  speed: 12,           // max homing speed (capped)
  steerForce: 280,     // homing steering force
  knockback: 6,
  projectileRadius: 0.2,
  mass: 0.5,
  maxAge: 8,
  hitRadius: 1.0,
  initialSpeedFractionXZ: 0.4,  // fraction of speed for initial XZ launch
  initialSpeedFractionY: 0.6,   // fraction of speed for initial upward launch
};

// ----- LIGHTNING -----
export const LIGHTNING = {
  fireRate: 0.6,       // zaps per second
  damage: 0.8,         // damage per chain target
  chains: 3,           // number of enemies it jumps to
  chainRange: 8,       // max distance to next chain target
  stunDuration: 0.4,   // seconds enemies are stunned
  arcFadeTime: 0.25,   // how long the visual arc lasts
};

// ----- ENEMIES -----
export const ENEMY = {
  baseHp: 3,
  hpScalePerWave: 0.15,  // multiplier increase per wave
  speedMin: 3,
  speedMax: 4.5,          // speed = speedMin + random * (speedMax - speedMin)
  damage: 1,              // damage per second to tower
  spawnRadius: 45,
  mass: 5,
  towerDamageRange: 2.5,  // distance at which enemy hits tower
  forceMult: 3,           // movement force multiplier
  stunDamping: 0.92,      // velocity multiplier per tick while stunned
};

// ----- WAVES -----
export const WAVE = {
  baseEnemies: 5,
  linearScale: 3,       // enemies += n * this
  quadraticScale: 0.5,  // enemies += n^2 * this
  spawnInterval: 1.5,   // seconds between spawns
  reprieveDuration: 3,  // seconds between waves
};

// ----- PHYSICS -----
export const PHYSICS = {
  gravity: 20,           // world gravity magnitude (positive = downward)
  tickRate: 1 / 60,
};

// ----- DEATH EFFECTS -----
export const DEATH = {
  launchUpMin: 15,
  launchUpMax: 25,       // launchUp = min + random * (max - min)
  launchSideMult: 2,     // sideways impulse = knockDir * this
  ragdollSpin: 20,       // max angular velocity on death
};

// ----- MINIONS -----
export const MINION = {
  count: 1,              // starting minion count (upgrades up to ~6)
  damage: 1.5,           // damage per bonk
  attackRange: 1.8,      // distance to start windup
  windupTime: 0.4,       // seconds before bonk lands
  cooldownTime: 0.6,     // seconds after bonk before next attack
  speed: 5,              // run speed
  mass: 1.5,             // light — gets flung by explosions
  forceMult: 4,          // movement force multiplier
  recoveryTime: 1.2,     // seconds lying on ground after being flung
  flingThreshold: 8,     // velocity magnitude that triggers recovery state
  pushForce: 3,          // small impulse applied to enemy on bonk
  spawnRadius: 4,        // distance from tower where minions spawn
};
