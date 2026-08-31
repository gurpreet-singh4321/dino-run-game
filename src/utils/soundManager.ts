// Robust High-Fidelity Audio Engine for Dino Run Epochs
// Dual Mode: Direct HTML5 Audio Streaming + Web Audio Synthesizer

export interface AudioState {
  isPlaying: boolean;
  isBuffering: boolean;
  volume: number;
  currentTrack: string;
  error: string | null;
}

class SoundManager {
  private ostAudio: HTMLAudioElement | null = null;
  private audioCtx: AudioContext | null = null;
  private state: AudioState = {
    isPlaying: false,
    isBuffering: false,
    volume: 0.45,
    currentTrack: 'pixel_jump_title.mp3',
    error: null,
  };
  private listeners: Set<(state: AudioState) => void> = new Set();
  private userExplicitlyMuted: boolean = false;

  private tracks: Record<string, string> = {
    'pixel_jump_title.mp3': '/assets/audio/pixel_jump_title.mp3',
    'one_more_try.mp3': '/assets/audio/one_more_try.mp3',
    'pixel_jump.mp3': '/assets/audio/pixel_jump.mp3',
  };

  constructor() {
    if (typeof window !== 'undefined') {
      // Check saved volume or state from localStorage
      try {
        const savedVol = localStorage.getItem('dino_volume');
        if (savedVol !== null) {
          this.state.volume = parseFloat(savedVol);
        }
      } catch (_) {}

      // Explicit trigger to mute web audio when user enters game fullscreen or plays arcade sound
      window.addEventListener('dino:mute-web-audio', () => {
        this.pauseOst();
      });

      // Preload & unlock audio context on first user click or touch
      const unlockAudio = () => {
        this.ensureAudioContext();
        this.initOst(this.state.currentTrack);
        window.removeEventListener('click', unlockAudio);
        window.removeEventListener('touchstart', unlockAudio);
        window.removeEventListener('keydown', unlockAudio);
      };
      window.addEventListener('click', unlockAudio, { passive: true });
      window.addEventListener('touchstart', unlockAudio, { passive: true });
      window.addEventListener('keydown', unlockAudio, { passive: true });
    }
  }

  private ensureAudioContext(): AudioContext | null {
    if (typeof window === 'undefined') return null;
    if (!this.audioCtx) {
      const AudioContextClass = window.AudioContext || (window as any).webkitAudioContext;
      if (AudioContextClass) {
        this.audioCtx = new AudioContextClass();
      }
    }
    if (this.audioCtx && this.audioCtx.state === 'suspended') {
      this.audioCtx.resume().catch(() => {});
    }
    return this.audioCtx;
  }

  public initOst(trackKey: string = 'pixel_jump_title.mp3'): void {
    if (typeof window === 'undefined') return;
    
    const src = this.tracks[trackKey] || this.tracks['pixel_jump_title.mp3'];

    if (!this.ostAudio || this.state.currentTrack !== trackKey) {
      if (this.ostAudio) {
        this.ostAudio.pause();
        this.ostAudio.src = '';
      }

      this.ostAudio = new Audio(src);
      this.ostAudio.loop = true;
      this.ostAudio.volume = this.state.volume;
      this.ostAudio.preload = 'auto';

      this.ostAudio.addEventListener('waiting', () => {
        this.state.isBuffering = true;
        this.notify();
      });

      this.ostAudio.addEventListener('playing', () => {
        this.state.isPlaying = true;
        this.state.isBuffering = false;
        this.state.error = null;
        this.notify();
      });

      this.ostAudio.addEventListener('pause', () => {
        this.state.isPlaying = false;
        this.state.isBuffering = false;
        this.notify();
      });

      this.ostAudio.addEventListener('error', (e) => {
        console.warn('Audio playback error:', e);
        this.state.isPlaying = false;
        this.state.isBuffering = false;
        this.state.error = 'Audio load error';
        this.notify();
      });

      this.state.currentTrack = trackKey;
    }
  }

  public toggleOst(trackKey?: string): boolean {
    this.ensureAudioContext();
    if (trackKey && trackKey !== this.state.currentTrack) {
      this.initOst(trackKey);
      this.playOst();
      this.playUiClick();
      return true;
    }

    this.initOst(this.state.currentTrack);
    if (!this.ostAudio) return false;

    if (this.state.isPlaying) {
      this.userExplicitlyMuted = true;
      this.pauseOst();
      this.playUiClick();
      return false;
    } else {
      this.userExplicitlyMuted = false;
      this.playOst();
      this.playUiClick();
      return true;
    }
  }

  public playOst(): void {
    this.ensureAudioContext();
    this.initOst(this.state.currentTrack);
    if (!this.ostAudio) return;

    this.state.isBuffering = true;
    this.notify();

    const playPromise = this.ostAudio.play();
    if (playPromise !== undefined) {
      playPromise
        .then(() => {
          this.state.isPlaying = true;
          this.state.isBuffering = false;
          this.state.error = null;
          this.notify();
        })
        .catch((err) => {
          console.warn('Playback blocked or pending interaction:', err);
          this.state.isPlaying = false;
          this.state.isBuffering = false;
          this.notify();
        });
    }
  }

  public pauseOst(): void {
    if (this.ostAudio) {
      this.ostAudio.pause();
    }
    this.state.isPlaying = false;
    this.state.isBuffering = false;
    this.notify();
  }

  public setVolume(vol: number): void {
    const clamped = Math.max(0, Math.min(1, vol));
    this.state.volume = clamped;
    if (this.ostAudio) {
      this.ostAudio.volume = clamped;
    }
    try {
      localStorage.setItem('dino_volume', clamped.toString());
    } catch (_) {}
    this.notify();
  }

  // 8-bit Synth Audio Effects (Web Audio API)
  public playUiClick(): void {
    const ctx = this.ensureAudioContext();
    if (!ctx) return;
    try {
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = 'square';
      osc.frequency.setValueAtTime(520, ctx.currentTime);
      osc.frequency.exponentialRampToValueAtTime(1040, ctx.currentTime + 0.07);
      gain.gain.setValueAtTime(0.12, ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.07);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start();
      osc.stop(ctx.currentTime + 0.07);
    } catch (e) {}
  }

  public playEpochSelectSfx(): void {
    const ctx = this.ensureAudioContext();
    if (!ctx) return;
    try {
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = 'triangle';
      osc.frequency.setValueAtTime(320, ctx.currentTime);
      osc.frequency.exponentialRampToValueAtTime(640, ctx.currentTime + 0.12);
      gain.gain.setValueAtTime(0.15, ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.12);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start();
      osc.stop(ctx.currentTime + 0.12);
    } catch (e) {}
  }

  public playJumpSfx(): void {
    this.ensureAudioContext();
    try {
      const sfx = new Audio('/assets/audio/pixel_jump.mp3');
      sfx.volume = Math.min(1, this.state.volume * 1.2);
      sfx.play().catch(() => {});
    } catch (_) {}

    const ctx = this.audioCtx;
    if (ctx) {
      try {
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'square';
        osc.frequency.setValueAtTime(160, ctx.currentTime);
        osc.frequency.exponentialRampToValueAtTime(640, ctx.currentTime + 0.15);
        gain.gain.setValueAtTime(0.16, ctx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.15);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start();
        osc.stop(ctx.currentTime + 0.15);
      } catch (e) {}
    }
  }

  public subscribe(callback: (state: AudioState) => void): () => void {
    this.listeners.add(callback);
    callback(this.state);
    return () => this.listeners.delete(callback);
  }

  private notify(): void {
    this.listeners.forEach(cb => cb({ ...this.state }));
  }

  public getState(): AudioState {
    return { ...this.state };
  }
}

export const soundManager = (() => {
  if (typeof window !== 'undefined') {
    if (!(window as any).__GLOBAL_SOUND_MANAGER__) {
      (window as any).__GLOBAL_SOUND_MANAGER__ = new SoundManager();
    }
    return (window as any).__GLOBAL_SOUND_MANAGER__;
  }
  return new SoundManager();
})();
