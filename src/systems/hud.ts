import { GameState } from "../state.js";

let container: HTMLDivElement | null = null;
let hpBar: HTMLDivElement | null = null;
let hpText: HTMLSpanElement | null = null;
let waveText: HTMLSpanElement | null = null;
let killText: HTMLSpanElement | null = null;
let gameOverOverlay: HTMLDivElement | null = null;

export function createHUD(): void {
  container = document.createElement("div");
  container.id = "hud";
  container.innerHTML = `
    <div style="
      position: fixed; top: 16px; left: 16px;
      font-family: 'Courier New', monospace;
      color: #eee; font-size: 14px;
      background: rgba(0,0,0,0.6);
      padding: 12px 16px;
      border-radius: 8px;
      min-width: 180px;
      pointer-events: none;
      user-select: none;
    ">
      <div style="margin-bottom: 8px;">
        <span style="color: #aaa;">HP</span>
        <div style="
          background: #333; border-radius: 4px;
          height: 16px; margin-top: 4px;
          overflow: hidden;
        ">
          <div id="hp-bar" style="
            background: linear-gradient(90deg, #e74c3c, #e67e22);
            height: 100%; width: 100%;
            border-radius: 4px;
            transition: width 0.2s;
          "></div>
        </div>
        <span id="hp-text" style="font-size: 12px; color: #ccc;">10 / 10</span>
      </div>
      <div><span style="color: #aaa;">Wave:</span> <span id="wave-text">1</span></div>
      <div><span style="color: #aaa;">Kills:</span> <span id="kill-text">0</span></div>
    </div>
  `;
  document.body.appendChild(container);

  hpBar = document.getElementById("hp-bar") as HTMLDivElement;
  hpText = document.getElementById("hp-text") as HTMLSpanElement;
  waveText = document.getElementById("wave-text") as HTMLSpanElement;
  killText = document.getElementById("kill-text") as HTMLSpanElement;
}

export function updateHUD(state: GameState): void {
  if (!hpBar || !hpText || !waveText || !killText) return;

  const hpPct = Math.max(0, (state.tower.hp / state.tower.maxHp) * 100);
  hpBar.style.width = `${hpPct}%`;
  hpText.textContent = `${Math.ceil(Math.max(0, state.tower.hp))} / ${state.tower.maxHp}`;
  waveText.textContent = state.wave.inReprieve
    ? `${state.wave.number} (next wave...)`
    : `${state.wave.number}`;
  killText.textContent = `${state.wave.kills}`;

  // Game over
  if (state.tower.hp <= 0 && !gameOverOverlay) {
    gameOverOverlay = document.createElement("div");
    gameOverOverlay.innerHTML = `
      <div style="
        position: fixed; inset: 0;
        display: flex; align-items: center; justify-content: center;
        background: rgba(0,0,0,0.7);
        font-family: 'Courier New', monospace;
        color: #e74c3c; font-size: 48px;
        pointer-events: none;
        flex-direction: column;
        gap: 16px;
      ">
        <div>TOWER DESTROYED</div>
        <div style="font-size: 20px; color: #ccc;">
          Wave ${state.wave.number} | ${state.wave.kills} kills
        </div>
        <div style="font-size: 16px; color: #888;">Refresh to restart</div>
      </div>
    `;
    document.body.appendChild(gameOverOverlay);
  }
}
