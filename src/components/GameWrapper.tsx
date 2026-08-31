import React, { useState, useRef, useEffect } from 'react';
import { 
  Television, 
  ArrowsOutSimple, 
  ArrowsInSimple, 
  ArrowClockwise, 
  DeviceMobile, 
  ArrowsClockwise, 
  GameController,
  Play,
  Cpu,
  Monitor
} from '@phosphor-icons/react';
import { soundManager } from '../utils/soundManager';

export default function GameWrapper() {
  const containerRef = useRef<HTMLDivElement>(null);
  const [isFullscreen, setIsFullscreen] = useState(false);
  const [scanlines, setScanlines] = useState(false);
  const [iframeKey, setIframeKey] = useState(0);
  const [isPortraitMobile, setIsPortraitMobile] = useState(false);
  const [dismissLandscapePrompt, setDismissLandscapePrompt] = useState(false);

  useEffect(() => {
    const checkOrientation = () => {
      const isMobile = window.innerWidth <= 768;
      const isPortrait = window.innerHeight > window.innerWidth;
      setIsPortraitMobile(isMobile && isPortrait);
    };

    checkOrientation();
    window.addEventListener('resize', checkOrientation);
    window.addEventListener('orientationchange', checkOrientation);

    const handleFullscreenChange = () => {
      const isNativeFs = !!(document.fullscreenElement || (document as any).webkitFullscreenElement);
      if (!isNativeFs && isFullscreen) {
        exitFullscreenMode();
      }
    };

    document.addEventListener('fullscreenchange', handleFullscreenChange);
    document.addEventListener('webkitfullscreenchange', handleFullscreenChange);

    return () => {
      window.removeEventListener('resize', checkOrientation);
      window.removeEventListener('orientationchange', checkOrientation);
      document.removeEventListener('fullscreenchange', handleFullscreenChange);
      document.removeEventListener('webkitfullscreenchange', handleFullscreenChange);
      document.body.style.overflow = '';
    };
  }, [isFullscreen]);

  const enterFullscreenMode = async () => {
    soundManager.pauseOst();
    setIsFullscreen(true);
    document.body.style.overflow = 'hidden';

    const el = containerRef.current || document.documentElement;
    try {
      if (el.requestFullscreen) {
        await el.requestFullscreen();
      } else if ((el as any).webkitRequestFullscreen) {
        await (el as any).webkitRequestFullscreen();
      }
    } catch (_) {}

    try {
      if (screen.orientation && (screen.orientation as any).lock) {
        await (screen.orientation as any).lock('landscape').catch(() => {});
      }
    } catch (_) {}
  };

  const exitFullscreenMode = async () => {
    setIsFullscreen(false);
    document.body.style.overflow = '';

    try {
      if (document.fullscreenElement || (document as any).webkitFullscreenElement) {
        if (document.exitFullscreen) {
          await document.exitFullscreen().catch(() => {});
        } else if ((document as any).webkitExitFullscreen) {
          await (document as any).webkitExitFullscreen().catch(() => {});
        }
      }
    } catch (_) {}

    try {
      if (screen.orientation && screen.orientation.unlock) {
        screen.orientation.unlock();
      }
    } catch (_) {}
  };

  const toggleFullscreen = () => {
    if (isFullscreen) {
      exitFullscreenMode();
    } else {
      enterFullscreenMode();
    }
  };

  const reloadGame = () => {
    soundManager.pauseOst();
    setIframeKey(prev => prev + 1);
  };

  return (
    <section id="arcade" className="relative w-full py-16 px-4 md:px-8 max-w-[1360px] mx-auto flex flex-col items-center">
      
      {/* Section Header */}
      <div className="flex flex-col items-center text-center space-y-3 mb-8">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full border border-white/10 bg-white/[0.03] text-slate-300 text-xs font-['Geist_Mono']">
          <Monitor size={14} className="text-amber-400" />
          <span>CANVASKIT GPU ACCELERATION • 60 FPS WASM</span>
        </div>
        <h2 className="text-3xl sm:text-5xl font-bold tracking-tight text-white font-['Chakra_Petch'] uppercase">
          ARCADE GAME ARENA
        </h2>
        <p className="text-slate-400 max-w-[50ch] text-sm sm:text-base leading-relaxed">
          Play directly in your browser. Controls: <kbd className="px-1.5 py-0.5 rounded bg-white/10 text-white font-mono text-xs">Space</kbd> or <kbd className="px-1.5 py-0.5 rounded bg-white/10 text-white font-mono text-xs">↑</kbd> to jump, <kbd className="px-1.5 py-0.5 rounded bg-white/10 text-white font-mono text-xs">↓</kbd> to duck.
        </p>
      </div>

      {/* Hardware Matte Titanium Cabinet Chassis */}
      <div 
        ref={containerRef}
        className={`w-full transition-all duration-300 ${
          isFullscreen
            ? 'fixed inset-0 z-[99999] w-screen h-[100dvh] bg-slate-950 p-0 m-0 rounded-none border-none flex flex-col'
            : 'max-w-[1100px] surface-panel rounded-2xl md:rounded-3xl p-3 sm:p-4 border border-white/10 shadow-[0_32px_64px_-16px_rgba(0,0,0,0.85)]'
        }`}
      >
        {/* Sleek Hardware Telemetry Bar */}
        <div className={`flex items-center justify-between text-xs font-['Geist_Mono'] ${
          isFullscreen 
            ? 'px-4 py-2 bg-slate-950 border-b border-white/10 shrink-0' 
            : 'px-3.5 py-2 mb-2.5 rounded-xl bg-slate-900/60 border border-white/8'
        }`}>
          <div className="flex items-center gap-3">
            <div className="flex items-center gap-1.5">
              <span className="w-2 h-2 rounded-full bg-emerald-400" />
              <span className="text-slate-300 font-semibold text-[11px]">RUNNER ENGINE ACTIVE</span>
            </div>
            <span className="text-slate-600 hidden md:inline">•</span>
            <span className="text-slate-400 hidden md:inline text-[11px]">CANVASKIT 60FPS</span>
          </div>

          <div className="flex items-center gap-1.5">
            <button
              onClick={() => setScanlines(!scanlines)}
              className={`px-2.5 py-1 rounded-md border flex items-center gap-1.5 transition-colors text-[11px] cursor-pointer ${
                scanlines 
                  ? 'bg-white/15 border-white/20 text-white' 
                  : 'bg-white/[0.03] border-white/8 text-slate-400 hover:text-white'
              }`}
              title="Toggle CRT Scanline Effect"
            >
              <Television size={13} weight={scanlines ? "fill" : "regular"} />
              <span>CRT Filter</span>
            </button>

            <button
              onClick={reloadGame}
              className="p-1 sm:px-2.5 sm:py-1 rounded-md bg-white/[0.03] border border-white/8 text-slate-400 hover:text-white transition-colors flex items-center gap-1 text-[11px] cursor-pointer"
              title="Restart Game"
            >
              <ArrowClockwise size={13} />
              <span className="hidden sm:inline">Reset</span>
            </button>

            <button
              onClick={toggleFullscreen}
              className="px-2.5 py-1 rounded-md bg-white/10 border border-white/15 text-white hover:bg-white/20 transition-colors flex items-center gap-1.5 text-[11px] font-medium cursor-pointer"
              title={isFullscreen ? "Exit Fullscreen" : "Fullscreen Mode"}
            >
              {isFullscreen ? (
                <>
                  <ArrowsInSimple size={13} />
                  <span>Exit</span>
                </>
              ) : (
                <>
                  <ArrowsOutSimple size={13} />
                  <span>Fullscreen</span>
                </>
              )}
            </button>
          </div>
        </div>

        {/* Recessed Game Screen Frame */}
        <div className={`relative w-full overflow-hidden bg-black ${
          isFullscreen 
            ? 'flex-1 w-full h-full rounded-none border-none' 
            : 'aspect-[16/10] sm:aspect-video rounded-xl border border-white/8 shadow-inner'
        }`}>
          
          <iframe
            key={iframeKey}
            src="/game/index.html"
            title="Dino Run Epochs Arcade Game - Play Online"
            className="w-full h-full border-0 outline-none bg-black"
            allow="autoplay; fullscreen; accelerometer"
          />

          {/* CRT Scanline Overlay */}
          {scanlines && (
            <div className="absolute inset-0 scanlines pointer-events-none z-20" />
          )}

          {/* Mobile Landscape Advice */}
          {isPortraitMobile && !dismissLandscapePrompt && !isFullscreen && (
            <div className="absolute inset-0 bg-slate-950/95 backdrop-blur-md z-30 flex flex-col items-center justify-center p-6 text-center text-white space-y-3">
              <DeviceMobile size={40} className="text-slate-300 animate-bounce" />
              <h4 className="font-['Chakra_Petch'] font-bold text-lg">Rotate to Landscape</h4>
              <p className="text-xs text-slate-400 max-w-[32ch]">
                Dino Run is optimized for widescreen controls. Rotate your phone or launch fullscreen.
              </p>
              <div className="flex items-center gap-2 pt-2">
                <button
                  onClick={enterFullscreenMode}
                  className="px-4 py-2 rounded-lg bg-white text-slate-950 font-['Chakra_Petch'] font-bold text-xs uppercase"
                >
                  Enter Fullscreen
                </button>
                <button
                  onClick={() => setDismissLandscapePrompt(true)}
                  className="px-3 py-2 rounded-lg border border-white/10 text-xs text-slate-400"
                >
                  Dismiss
                </button>
              </div>
            </div>
          )}
        </div>

        {/* Sub-Cabinet Control Guide */}
        {!isFullscreen && (
          <div className="mt-3 pt-2.5 border-t border-white/8 flex flex-wrap items-center justify-between text-[11px] font-['Geist_Mono'] text-slate-400 px-1">
            <div className="flex items-center gap-4">
              <span><strong>SPACE / ↑</strong> Jump</span>
              <span><strong>↓</strong> Duck</span>
              <span><strong>P / ESC</strong> Pause</span>
            </div>
            <div className="text-slate-500 hidden sm:inline">
              Instant WASM Runtime • No Sign-up
            </div>
          </div>
        )}

      </div>
    </section>
  );
}
