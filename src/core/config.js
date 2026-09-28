/**
 * Central tuning + quality configuration.
 * Subsystems read from here rather than hardcoding magic numbers, so the
 * quality scaler and the capture harness can drive everything from one place.
 */

export const PHYSICS_HZ = 120;
export const FIXED_DT = 1 / PHYSICS_HZ;
/** Never simulate more than this many physics steps in one frame (spiral-of-death guard). */
export const MAX_SUBSTEPS = 8;

/** Real-world units are metres, seconds, kilograms. */
export const UNITS = {
  gravity: -9.81 * 2.1, // Games use exaggerated gravity; CoD-like feel.
  playerHeight: 1.78,
  playerCrouchHeight: 1.12,
  playerRadius: 0.32,
  eyeOffset: 0.12, // below top of capsule
};

export const QUALITY_PRESETS = {
  potato: {
    renderScale: 0.5,
    shadowMapSize: 512,
    cascades: 2,
    shadowDistance: 40,
    taa: false,
    gtao: false,
    ssr: false,
    volumetrics: false,
    motionBlur: false,
    bloom: false,
    anisotropy: 1,
    particleBudget: 500,
    decalBudget: 16,
  },
  low: {
    renderScale: 0.72,
    shadowMapSize: 1024,
    cascades: 3,
    shadowDistance: 60,
    taa: false,
    gtao: false,
    ssr: false,
    volumetrics: false,
    motionBlur: false,
    bloom: true,
    anisotropy: 4,
    particleBudget: 2000,
    decalBudget: 64,
  },
  medium: {
    renderScale: 0.85,
    shadowMapSize: 2048,
    cascades: 3,
    shadowDistance: 90,
    taa: true,
    gtao: true,
    ssr: false,
    volumetrics: true,
    motionBlur: true,
    bloom: true,
    anisotropy: 8,
    particleBudget: 6000,
    decalBudget: 128,
  },
  high: {
    renderScale: 1.0,
    shadowMapSize: 2048,
    cascades: 4,
    shadowDistance: 140,
    taa: true,
    gtao: true,
    ssr: true,
    volumetrics: true,
    motionBlur: true,
    bloom: true,
    anisotropy: 16,
    particleBudget: 12000,
    decalBudget: 256,
  },
  ultra: {
    renderScale: 1.0,
    shadowMapSize: 4096,
    cascades: 4,
    shadowDistance: 200,
    taa: true,
    gtao: true,
    ssr: true,
    volumetrics: true,
    motionBlur: true,
    bloom: true,
    anisotropy: 16,
    particleBudget: 24000,
    decalBudget: 512,
  },
};

export const DEFAULTS = {
  quality: 'auto',
  fov: 80, // horizontal-ish vertical FOV, CoD default feel
  adsFovScale: 0.72,
  sensitivity: 0.0022,
  adsSensScale: 0.65,
  invertY: false,
  exposure: 1.0,
  /** Capture mode disables anything nondeterministic so screenshots are stable. */
  deterministic: false,
};

/**
 * Pick a safe starting preset for the current device.
 * Desktop with many cores keeps high/ultra, anything mobile or low-RAM
 * falls back to potato/low so the game boots playable instead of 5 fps.
 * Override with `?q=low|medium|high|ultra|potato` in the URL.
 */
export function detectDeviceQuality() {
  try {
    const nav = globalThis.navigator ?? {};
    const ua = String(nav.userAgent ?? '').toLowerCase();
    const mobile = /android|iphone|ipad|ipod|mobile|tablet|touch/.test(ua)
      || (globalThis.matchMedia?.('(pointer: coarse)').matches ?? false);
    const cores = nav.hardwareConcurrency ?? 4;
    const mem = nav.deviceMemory ?? 4; // GB, Chrome-only; undefined elsewhere
    const smallScreen = Math.min(globalThis.innerWidth || 1920, globalThis.innerHeight || 1080) < 500;
    if (mobile || smallScreen) return cores >= 8 && mem >= 6 ? 'low' : 'potato';
    if (cores <= 4 || mem <= 4) return 'low';
    if (cores <= 8) return 'medium';
    return 'high'; // ultra stays opt-in via ?q=ultra or the pause menu
  } catch {
    return 'low';
  }
}

export function createConfig(overrides = {}) {
  const cfg = { ...DEFAULTS, ...overrides };
  if (cfg.quality === 'auto') cfg.quality = detectDeviceQuality();
  cfg.q = { ...QUALITY_PRESETS[cfg.quality] ?? QUALITY_PRESETS.low };
  cfg.setQuality = (name) => {
    if (!QUALITY_PRESETS[name]) throw new Error(`unknown quality preset "${name}"`);
    cfg.quality = name;
    Object.assign(cfg.q, QUALITY_PRESETS[name]);
  };
  return cfg;
}
