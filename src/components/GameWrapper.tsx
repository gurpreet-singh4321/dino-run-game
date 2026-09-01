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
  const [hasStarted, setHasStarted] = useState(false);

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
    setHasStarted(true);
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
    setHasStarted(true);
  };

  const startGame = () => {
    soundManager.playUiClick();
    setHasStarted(true);
    if (window.innerWidth <= 768) {
      enterFullscreenMode();
    }
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
              <span className={`w-2 h-2 rounded-full ${hasStarted ? 'bg-emerald-400' : 'bg-amber-400 animate-pulse'}`} />
              <span className="text-slate-300 font-semibold text-[11px] uppercase">
                {hasStarted ? 'RUNNER ENGINE ACTIVE' : 'ENGINE STANDBY'}
              </span>
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
              <span className="hidden sm:inline">CRT Filter</span>
            </button>

            {hasStarted && (
              <button
                onClick={reloadGame}
                className="p-1 sm:px-2.5 sm:py-1 rounded-md bg-white/[0.03] border border-white/8 text-slate-400 hover:text-white transition-colors flex items-center gap-1 text-[11px] cursor-pointer"
                title="Restart Game"
              >
                <ArrowClockwise size={13} />
                <span className="hidden sm:inline">Reset</span>
              </button>
            )}

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
        <div className={`relative w-full overflow-hidden bg-slate-950 ${
          isFullscreen 
            ? 'flex-1 w-full h-full rounded-none border-none' 
            : 'aspect-[16/10] sm:aspect-video rounded-xl border border-white/8 shadow-inner'
        }`}>
          
          {!hasStarted ? (
            <div className="absolute inset-0 flex flex-col items-center justify-center p-6 text-center z-10">
              <div 
                className="absolute inset-0 bg-cover bg-center opacity-40 grayscale-[0.3]"
                style={{ backgroundImage: 'url(/assets/backgrounds/bg_forest.jpg)' }}
              />
              <div className="absolute inset-0 bg-gradient-to-t from-slate-950 via-slate-950/60 to-transparent" />
              
              <div className="relative z-10 flex flex-col items-center max-w-[500px]">
                <button
                  onClick={startGame}
                  className="group relative px-10 py-5 rounded-2xl bg-amber-500 hover:bg-amber-400 text-slate-950 font-['Chakra_Petch'] font-bold text-2xl uppercase tracking-wider transition-all shadow-[0_0_40px_rgba(245,158,11,0.3)] hover:shadow-[0_0_60px_rgba(245,158,11,0.5)] active:scale-95 flex items-center gap-3 cursor-pointer overflow-hidden"
                >
                  <div className="absolute inset-0 bg-white/20 translate-y-[100%] group-hover:translate-y-[0%] transition-transform duration-300" />
                  <Play size={28} weight="fill" className="relative z-10" />
                  <span className="relative z-10">Play Now</span>
                </button>

                <p className="mt-6 text-white font-['Geist_Mono'] font-bold tracking-widest text-sm flex items-center gap-3 uppercase">
                  <span>Free</span>
                  <span className="w-1.5 h-1.5 rounded-full bg-emerald-400" />
                  <span>No Download</span>
                  <span className="w-1.5 h-1.5 rounded-full bg-sky-400" />
                  <span>7 Epochs</span>
                </p>
                <p className="mt-3 text-slate-400 text-sm font-['Outfit']">
                  Works seamlessly on Desktop & Mobile.
                </p>
              </div>
            </div>
          ) : (
            <iframe
              key={iframeKey}
              src="/game/index.html"
              title="Dino Run Epochs Arcade Game - Play Online"
              className="w-full h-full border-0 outline-none bg-black"
              allow="autoplay; fullscreen; accelerometer"
            />
          )}

          {/* CRT Scanline Overlay */}
          {scanlines && (
            <div className="absolute inset-0 scanlines pointer-events-none z-20" />
          )}

          {/* Mobile Landscape Advice - Now strict and blocks portrait completely */}
          {hasStarted && isPortraitMobile && (
            <div className="absolute inset-0 bg-slate-950/95 backdrop-blur-md z-[9999] flex flex-col items-center justify-center p-6 text-center text-white space-y-3">
              <DeviceMobile size={40} className="text-slate-300 animate-bounce" />
              <h4 className="font-['Chakra_Petch'] font-bold text-xl uppercase tracking-wide text-amber-400">Rotate Device</h4>
              <p className="text-sm text-slate-300 max-w-[32ch] font-medium leading-relaxed">
                Dino Run is optimized for widescreen play. Please rotate your phone to landscape mode to continue.
              </p>
              {!isFullscreen && (
                <div className="pt-4">
                  <button
                    onClick={enterFullscreenMode}
                    className="px-5 py-2.5 rounded-xl bg-white hover:bg-slate-200 text-slate-950 font-['Chakra_Petch'] font-bold text-sm uppercase transition-colors"
                  >
                    Enter Fullscreen
                  </button>
                </div>
              )}
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
              High Score: <span className="text-amber-400 font-bold">SAVED LOCALLY</span>
            </div>
          </div>
        )}

      </div>
    </section>
  );
}
