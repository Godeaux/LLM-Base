# Web Principles

Web-specific philosophy, patterns, and best practices. This complements the universal principles in `PRINCIPLES.md`.

Browser games have unique constraints and opportunities. This guide helps you build games that work well across devices and browsers without over-engineering for edge cases.

---

## Responsive Design (Mobile Cognizant)

### Design for Desktop, Adapt for Mobile

Your primary target is likely desktop browsers, but mobile players exist. Don't ignore them, but don't design around them either.

**The approach:**
1. Build for desktop with mouse/keyboard
2. Test that it doesn't *break* on mobile
3. Add touch controls if the game makes sense on mobile
4. Accept that some games are desktop-only (complex RTS, keyboard-heavy)

### Canvas Sizing Strategy

Games need consistent sizing behavior. Choose a strategy:

**Fixed aspect ratio (recommended for most games):**
```typescript
const GAME_WIDTH = 1280;
const GAME_HEIGHT = 720;

function resizeCanvas(): void {
  const windowRatio = window.innerWidth / window.innerHeight;
  const gameRatio = GAME_WIDTH / GAME_HEIGHT;

  let width: number, height: number;

  if (windowRatio > gameRatio) {
    // Window is wider than game - letterbox sides
    height = window.innerHeight;
    width = height * gameRatio;
  } else {
    // Window is taller than game - letterbox top/bottom
    width = window.innerWidth;
    height = width / gameRatio;
  }

  canvas.style.width = `${width}px`;
  canvas.style.height = `${height}px`;
}

window.addEventListener('resize', resizeCanvas);
```

**Fluid scaling (for UI-heavy or casual games):**
```css
canvas {
  width: 100vw;
  height: 100vh;
  object-fit: contain;
}
```

### CSS Units for UI

For UI elements outside the canvas (menus, HUD overlays), use viewport-relative units:

```css
.game-container {
  width: 100vw;
  height: 100vh;
  /* Mobile Safari needs this for reliable vh */
  height: 100dvh;
}

.ui-button {
  /* Scales with screen size but has reasonable bounds */
  font-size: clamp(14px, 2vw, 24px);
  padding: clamp(8px, 1.5vw, 16px);
}
```

`clamp()` lets you set min/max bounds while scaling fluidly in between.

---

## Input Handling

### Pointer Events Over Mouse/Touch Split

Pointer Events unify mouse, touch, and pen input. Use them unless you need specific behaviors.

```typescript
// Good: Works for mouse, touch, and stylus
canvas.addEventListener('pointerdown', (e: PointerEvent) => {
  const x = e.clientX - canvas.offsetLeft;
  const y = e.clientY - canvas.offsetTop;
  handleInput(x, y);
});

// Prevent touch scrolling on the canvas
canvas.addEventListener('touchstart', (e) => e.preventDefault(), { passive: false });
```

### Keyboard Handling

```typescript
const keysDown = new Set<string>();

window.addEventListener('keydown', (e: KeyboardEvent) => {
  // Prevent default for game keys (arrows, space) but not browser shortcuts
  if (['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', ' '].includes(e.key)) {
    e.preventDefault();
  }
  keysDown.add(e.key);
});

window.addEventListener('keyup', (e: KeyboardEvent) => {
  keysDown.delete(e.key);
});

// In game loop
function update(): void {
  if (keysDown.has('ArrowLeft') || keysDown.has('a')) {
    player.moveLeft();
  }
}
```

### Gamepad API

Gamepads work in browsers but require polling:

```typescript
function getGamepadInput(): { x: number; y: number; buttons: boolean[] } | null {
  const gamepads = navigator.getGamepads();
  const gp = gamepads[0]; // First connected gamepad

  if (!gp) return null;

  return {
    x: gp.axes[0],  // Left stick horizontal
    y: gp.axes[1],  // Left stick vertical
    buttons: gp.buttons.map(b => b.pressed),
  };
}
```

### Input Abstraction

For games with multiple input methods, abstract the input layer:

```typescript
interface GameInput {
  moveDirection: { x: number; y: number };
  jump: boolean;
  attack: boolean;
}

function pollInput(): GameInput {
  const input: GameInput = {
    moveDirection: { x: 0, y: 0 },
    jump: false,
    attack: false,
  };

  // Keyboard
  if (keysDown.has('ArrowLeft')) input.moveDirection.x -= 1;
  if (keysDown.has('ArrowRight')) input.moveDirection.x += 1;
  if (keysDown.has(' ')) input.jump = true;

  // Gamepad (if connected)
  const gamepad = getGamepadInput();
  if (gamepad) {
    if (Math.abs(gamepad.x) > 0.2) input.moveDirection.x = gamepad.x;
    if (gamepad.buttons[0]) input.jump = true;
  }

  // Touch (from your touch controller state)
  // ...

  return input;
}
```

---

## Performance

### The Game Loop

Use `requestAnimationFrame` for smooth, vsync'd rendering:

```typescript
let lastTime = 0;

function gameLoop(currentTime: number): void {
  const deltaTime = (currentTime - lastTime) / 1000; // Convert to seconds
  lastTime = currentTime;

  // Cap delta to prevent spiral of death after tab switch
  const cappedDelta = Math.min(deltaTime, 1 / 30);

  update(cappedDelta);
  render();

  requestAnimationFrame(gameLoop);
}

requestAnimationFrame(gameLoop);
```

### Avoid Layout Thrashing

Reading layout properties (offsetWidth, getBoundingClientRect) forces the browser to recalculate. Batch reads and writes.

```typescript
// Bad: Forces recalculation each iteration
elements.forEach(el => {
  const width = el.offsetWidth;       // Read (triggers layout)
  el.style.width = (width * 2) + 'px'; // Write
});

// Good: Batch reads, then batch writes
const widths = elements.map(el => el.offsetWidth);  // All reads
elements.forEach((el, i) => {
  el.style.width = (widths[i] * 2) + 'px';          // All writes
});
```

### Object Pooling Matters More in JS

JavaScript garbage collection can cause frame hitches. Pool frequently created objects:

```typescript
// Bad: Creates garbage every frame
function update(): void {
  const velocity = { x: 0, y: 0 }; // Allocated every frame
  // ...
}

// Good: Reuse objects
const tempVelocity = { x: 0, y: 0 };
function update(): void {
  tempVelocity.x = 0;
  tempVelocity.y = 0;
  // ...
}
```

This is especially important for vectors, collision results, and other per-frame allocations.

### Web Workers for Heavy Lifting

Move expensive computations off the main thread:

```typescript
// pathfinding-worker.ts
self.onmessage = (e: MessageEvent) => {
  const { start, end, grid } = e.data;
  const path = calculatePath(start, end, grid);
  self.postMessage({ path });
};

// main.ts
const pathWorker = new Worker('pathfinding-worker.ts', { type: 'module' });

pathWorker.postMessage({ start, end, grid });
pathWorker.onmessage = (e) => {
  enemy.setPath(e.data.path);
};
```

Use workers for: pathfinding, procedural generation, physics simulation, large data processing.

---

## Asset Loading

### Preload Critical Assets

Don't let the player see assets pop in:

```typescript
async function preloadAssets(): Promise<void> {
  const imagesToLoad = [
    'sprites/player.png',
    'sprites/enemy.png',
    'sprites/tileset.png',
  ];

  const imagePromises = imagesToLoad.map(src => {
    return new Promise<HTMLImageElement>((resolve, reject) => {
      const img = new Image();
      img.onload = () => resolve(img);
      img.onerror = reject;
      img.src = src;
    });
  });

  await Promise.all(imagePromises);
}

// Show loading screen while preloading
showLoadingScreen();
await preloadAssets();
hideLoadingScreen();
startGame();
```

### Lazy Load Non-Critical Assets

For large games, load level-specific assets on demand:

```typescript
const assetCache = new Map<string, HTMLImageElement>();

async function loadImage(src: string): Promise<HTMLImageElement> {
  if (assetCache.has(src)) {
    return assetCache.get(src)!;
  }

  const img = new Image();
  img.src = src;
  await img.decode(); // Wait until ready to render
  assetCache.set(src, img);
  return img;
}
```

### Audio Loading

Audio requires user interaction before playing on most browsers:

```typescript
let audioContext: AudioContext | null = null;

function initAudio(): void {
  // Must be called from user gesture (click, keypress)
  if (!audioContext) {
    audioContext = new AudioContext();
  }
}

// Common pattern: Initialize on first interaction
document.addEventListener('click', initAudio, { once: true });
document.addEventListener('keydown', initAudio, { once: true });
```

For simpler audio needs, consider Howler.js which handles these quirks.

---

## TypeScript Specifics

### No `any`

TypeScript's value is in its types. Using `any` defeats the purpose.

```typescript
// Bad
function processData(data: any): any {
  return data.foo.bar;
}

// Good
interface GameData {
  foo: {
    bar: string;
  };
}

function processData(data: GameData): string {
  return data.foo.bar;
}
```

### Interfaces for Data, Types for Unions

```typescript
// Interfaces for object shapes (can be extended)
interface Player {
  position: Vector2;
  health: number;
  inventory: Item[];
}

// Types for unions and primitives
type Direction = 'up' | 'down' | 'left' | 'right';
type EntityId = string;
type Milliseconds = number;
```

### Strict Null Checks

Enable `strictNullChecks` in tsconfig.json. It catches bugs:

```typescript
// With strict null checks, this is an error:
function findEnemy(id: string): Enemy {
  return enemies.get(id); // Error: might return undefined
}

// Force you to handle the null case:
function findEnemy(id: string): Enemy | undefined {
  return enemies.get(id);
}

// Or assert it exists when you're certain:
function findEnemy(id: string): Enemy {
  const enemy = enemies.get(id);
  if (!enemy) throw new Error(`Enemy ${id} not found`);
  return enemy;
}
```

---

## Browser Compatibility

### Target Modern Browsers

Unless you have specific requirements, target:
- Chrome/Edge (last 2 versions)
- Firefox (last 2 versions)
- Safari (last 2 versions)

This covers 95%+ of users and lets you use modern APIs without polyfills.

### Feature Detection Over Browser Detection

```typescript
// Bad: Checks browser
if (navigator.userAgent.includes('Safari')) {
  // Safari-specific code
}

// Good: Checks feature
if ('PointerEvent' in window) {
  // Use pointer events
} else {
  // Fall back to mouse/touch events
}
```

### Vendor Prefixes

Modern CSS rarely needs prefixes, but when it does, use autoprefixer in your build or write both:

```css
.animated {
  -webkit-animation: spin 1s linear infinite;
  animation: spin 1s linear infinite;
}
```

---

## Build and Deploy

### Vite for Development

Vite is the recommended build tool. It provides:
- Instant hot module replacement
- TypeScript support out of the box
- Optimized production builds
- Import assets directly

```typescript
// Import images directly
import playerSprite from './assets/player.png';

// Use in code
const img = new Image();
img.src = playerSprite; // Vite handles the path
```

### Production Considerations

```typescript
// vite.config.ts
export default {
  build: {
    target: 'es2020',
    minify: 'terser',
    rollupOptions: {
      output: {
        manualChunks: {
          // Split vendor code for better caching
          vendor: ['three', 'howler'],
        },
      },
    },
  },
};
```

### Testing Setup

Use Vitest (Vite's test runner) for unit tests:

```typescript
// src/utils/collision.test.ts
import { describe, it, expect } from 'vitest';
import { checkCollision } from './collision';

describe('checkCollision', () => {
  it('detects overlapping rectangles', () => {
    const a = { x: 0, y: 0, width: 10, height: 10 };
    const b = { x: 5, y: 5, width: 10, height: 10 };
    expect(checkCollision(a, b)).toBe(true);
  });

  it('returns false for non-overlapping rectangles', () => {
    const a = { x: 0, y: 0, width: 10, height: 10 };
    const b = { x: 20, y: 20, width: 10, height: 10 };
    expect(checkCollision(a, b)).toBe(false);
  });
});
```

Run with `npm test` or `npm run test:watch` for development.

---

## Asset Formats for Web

| Type | Format | Notes |
|------|--------|-------|
| Sprites | PNG | Transparency, lossless, widely supported |
| Compressed images | WebP | 25-35% smaller than PNG, broad support |
| Vector UI | SVG | Scales perfectly, good for icons/UI |
| 3D Models | glTF/GLB | Standard for web 3D, Three.js native |
| Audio (music) | MP3 or OGG | MP3 for compatibility, OGG for quality/size |
| Audio (SFX) | MP3 or WAV | WAV for low latency, MP3 for size |
| Fonts | WOFF2 | Best compression, broad support |

### Image Optimization

Before committing images:
- Remove metadata with tools like ImageOptim
- Consider generating multiple resolutions for different screens
- Use sprite sheets for many small images (reduces HTTP requests)

---

## Common Anti-Patterns

### Blocking the Main Thread

**Problem:** Heavy computation freezes the game.

**Solution:** Use Web Workers for pathfinding, procedural generation, physics calculations. Keep the main thread for rendering and input.

### Memory Leaks via Event Listeners

**Problem:** Adding listeners without removing them.

```typescript
// Bad: Listener accumulates each time
function showMenu(): void {
  document.addEventListener('keydown', handleMenuInput);
}

// Good: Track and remove
let menuInputHandler: ((e: KeyboardEvent) => void) | null = null;

function showMenu(): void {
  menuInputHandler = handleMenuInput;
  document.addEventListener('keydown', menuInputHandler);
}

function hideMenu(): void {
  if (menuInputHandler) {
    document.removeEventListener('keydown', menuInputHandler);
    menuInputHandler = null;
  }
}
```

### Ignoring Tab Visibility

**Problem:** Game keeps running when tab is hidden, wasting resources.

```typescript
document.addEventListener('visibilitychange', () => {
  if (document.hidden) {
    pauseGame();
  } else {
    resumeGame();
  }
});
```

### Fixed Pixel Sizes

**Problem:** UI looks tiny on 4K screens, huge on phones.

**Solution:** Use relative units (rem, em, vw, vh, clamp) for UI. Keep pixel sizes only for game world coordinates.
