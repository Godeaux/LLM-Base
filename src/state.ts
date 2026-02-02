import * as CANNON from "cannon-es";

export interface GameState {
  tower: TowerState;
  enemies: EnemyState[];
  projectiles: ProjectileState[];
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
}

export interface EnemyState {
  id: number;
  body: CANNON.Body;
  hp: number;
  maxHp: number;
  speed: number;
  damage: number; // damage per second to tower
  alive: boolean;
  // leg animation
  legPhase: number;
  meshGroup: null; // set by renderer
  type: "walker";
}

export interface ProjectileState {
  id: number;
  body: CANNON.Body;
  alive: boolean;
  damage: number;
  knockback: number;
  age: number;
  maxAge: number;
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
      hp: 10,
      maxHp: 10,
      position: new CANNON.Vec3(0, 0, 0),
      fireRate: 1.5,
      fireTimer: 0,
      damage: 2,
      projectileSpeed: 25,
    },
    enemies: [],
    projectiles: [],
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
