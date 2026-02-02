import * as CANNON from "cannon-es";
import { TOWER, FIREBALL, ARROW, ARCANE, LIGHTNING } from "./config.js";

export interface GameState {
  tower: TowerState;
  enemies: EnemyState[];
  projectiles: ProjectileState[];
  lightningArcs: LightningArc[];
  wave: WaveState;
  time: number;
  deltaTime: number;
}

export interface TowerState {
  hp: number;
  maxHp: number;
  position: CANNON.Vec3;
  fireRate: number; // shots per second
  fireTimer: number;
  damage: number;
  projectileSpeed: number;
  // Arrow attack
  arrowFireRate: number;
  arrowFireTimer: number;
  arrowDamage: number;
  arrowSpeed: number;
  // Arcane bolt attack
  arcaneFireRate: number;
  arcaneFireTimer: number;
  arcaneDamage: number;
  arcaneSpeed: number;
  // Lightning attack
  lightningFireRate: number;
  lightningFireTimer: number;
  lightningDamage: number;
  lightningChains: number; // how many enemies it jumps to
  lightningChainRange: number;
  lightningStunDuration: number;
  // Debug toggles
  attackToggles: Record<AttackType, boolean>;
}

export interface EnemyState {
  id: number;
  body: CANNON.Body;
  hp: number;
  maxHp: number;
  speed: number;
  damage: number; // damage per second to tower
  alive: boolean;
  stunTimer: number; // seconds remaining of stun (0 = not stunned)
  // leg animation
  legPhase: number;
  meshGroup: null; // set by renderer
  type: "walker";
}

export type ProjectileType = "fireball" | "arrow" | "arcane";
export type AttackType = ProjectileType | "lightning";

/** Visual-only lightning arc that fades out over time. */
export interface LightningArc {
  points: CANNON.Vec3[]; // chain of positions: tower -> enemy1 -> enemy2 -> ...
  age: number;
  maxAge: number;
}

export interface ProjectileState {
  id: number;
  body: CANNON.Body;
  alive: boolean;
  damage: number;
  knockback: number;
  age: number;
  maxAge: number;
  type: ProjectileType;
  splashRadius: number; // 0 = no splash
  splashForce: number;
  targetId: number | null; // homing target (arcane bolt)
}

export interface WaveState {
  number: number;
  enemiesRemaining: number;
  enemiesSpawned: number;
  enemiesTotal: number;
  spawnTimer: number;
  spawnInterval: number;
  reprieveTimer: number;
  inReprieve: boolean;
  kills: number;
}

let nextId = 1;

export function nextEntityId(): number {
  return nextId++;
}

export function createInitialState(): GameState {
  return {
    tower: {
      hp: TOWER.hp,
      maxHp: TOWER.maxHp,
      position: new CANNON.Vec3(0, 0, 0),
      // Runtime fire timers (staggered so attacks don't all fire on frame 1)
      fireRate: FIREBALL.fireRate,
      fireTimer: 0,
      damage: FIREBALL.damage,
      projectileSpeed: FIREBALL.speed,
      arrowFireRate: ARROW.fireRate,
      arrowFireTimer: 0.3,
      arrowDamage: ARROW.damage,
      arrowSpeed: ARROW.speed,
      arcaneFireRate: ARCANE.fireRate,
      arcaneFireTimer: 0.6,
      arcaneDamage: ARCANE.damage,
      arcaneSpeed: ARCANE.speed,
      lightningFireRate: LIGHTNING.fireRate,
      lightningFireTimer: 0.9,
      lightningDamage: LIGHTNING.damage,
      lightningChains: LIGHTNING.chains,
      lightningChainRange: LIGHTNING.chainRange,
      lightningStunDuration: LIGHTNING.stunDuration,
      attackToggles: { fireball: true, arrow: true, arcane: true, lightning: true },
    },
    enemies: [],
    projectiles: [],
    lightningArcs: [],
    wave: {
      number: 1,
      enemiesRemaining: 0,
      enemiesSpawned: 0,
      enemiesTotal: 5,
      spawnTimer: 0,
      spawnInterval: 1.5,
      reprieveTimer: 0,
      inReprieve: false,
      kills: 0,
    },
    time: 0,
    deltaTime: 0,
  };
}
