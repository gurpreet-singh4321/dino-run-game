import React, { useState, useEffect } from 'react';
import { Play, SpeakerHigh, SpeakerSlash, Trophy, Sparkle } from '@phosphor-icons/react';
import { soundManager, type AudioState } from '../utils/soundManager';

interface NavItem {
  id: string;
  label: string;
  href: string;
}

const navItems: NavItem[] = [
  { id: 'arcade', label: 'Play Game', href: '/#arcade' },
  { id: 'biomes', label: '6 Epochs', href: '/epochs' },
  { id: 'mechanics', label: 'Strategy', href: '/guides/how-to-play-dino-runner' },
  { id: 'specs', label: 'Tech Stack', href: '/guides/tech-stack-flutter-wasm' },
  { id: 'about', label: 'About', href: '/about' },
];

export default function Navbar({ pathname = '/' }: { pathname?: string }) {
  const [scrolled, setScrolled] = useState(false);

  const getInitialActiveId = (path: string) => {
    if (path.includes('/epochs')) return 'biomes';
    if (path.includes('/guides/how-to-play')) return 'mechanics';
    if (path.includes('/guides/tech-stack')) return 'specs';
    if (path.includes('/about')) return 'about';
    return 'arcade';
  };

  const [activeId, setActiveId] = useState<string>(getInitialActiveId(pathname));
  const [audioState, setAudioState] = useState<AudioState>(soundManager.getState());

  const isClickScrolling = React.useRef(false);

  useEffect(() => {
    const handleScroll = () => {
      setScrolled(window.scrollY > 25);
    };
    window.addEventListener('scroll', handleScroll, { passive: true });

    let observer: IntersectionObserver | null = null;
    
    // Active path vs in-page scroll detection
    const pathname = window.location.pathname;
    if (pathname.includes('/epochs')) {
      setActiveId('biomes');
    } else if (pathname.includes('/guides/how-to-play')) {
      setActiveId('mechanics');
    } else if (pathname.includes('/guides/tech-stack')) {
      setActiveId('specs');
    } else if (pathname.includes('/about')) {
      setActiveId('about');
    } else {
      const sections = ['arcade', 'biomes', 'mechanics', 'specs', 'faq'];
      const observerCallback: IntersectionObserverCallback = (entries) => {
        if (isClickScrolling.current) return;
        
        // Find the intersection entry with the highest intersection ratio
        let bestMatch = entries[0];
        for (const entry of entries) {
          if (entry.isIntersecting && entry.intersectionRatio > (bestMatch?.intersectionRatio || 0)) {
            bestMatch = entry;
          }
        }
        
        if (bestMatch && bestMatch.isIntersecting) {
          setActiveId(bestMatch.target.id);
        }
      };

      observer = new IntersectionObserver(observerCallback, {
        root: null,
        rootMargin: '-20% 0px -60% 0px',
        threshold: [0, 0.25, 0.5, 0.75, 1], // Multiple thresholds for smoother detection
      });

      sections.forEach((id) => {
        const el = document.getElementById(id);
        if (el) observer.observe(el);
      });
    }

    const unsubscribe = soundManager.subscribe((st) => {
      setAudioState(st);
    });

    return () => {
      window.removeEventListener('scroll', handleScroll);
      if (observer) {
        observer.disconnect();
      }
      unsubscribe();
    };
  }, []);

  const handleToggleSound = () => {
    soundManager.toggleOst();
  };

  const handleNavClick = (item: NavItem, e: React.MouseEvent) => {
    soundManager.playUiClick();
    setActiveId(item.id);
    isClickScrolling.current = true;

    if (item.href.startsWith('/#') && (window.location.pathname === '/' || window.location.pathname === '')) {
      e.preventDefault();
      const targetEl = document.getElementById(item.id);
      if (targetEl) {
        targetEl.scrollIntoView({ behavior: 'smooth' });
        window.history.pushState(null, '', `#${item.id}`);
      }
    }
    
    setTimeout(() => {
      isClickScrolling.current = false;
    }, 1000);
  };

  return (
    <header className="fixed top-0 inset-x-0 z-50 flex justify-center px-4 py-3.5 pointer-events-none">
      <nav 
        className={`pointer-events-auto flex items-center justify-between gap-3 md:gap-6 px-4 md:px-5 py-2 rounded-full transition-all duration-300 ${
          scrolled 
            ? 'surface-pill border-white/10 shadow-[0_16px_36px_rgba(0,0,0,0.65)] scale-98' 
            : 'bg-slate-950/60 backdrop-blur-xl border border-white/8'
        }`}
      >
        {/* Brand */}
        <a 
          href="/" 
          onClick={() => soundManager.playUiClick()}
          className="flex items-center gap-2.5 group pr-2"
        >
          <div className="w-7 h-7 rounded-lg overflow-hidden border border-white/10 p-0.5 bg-slate-900 flex items-center justify-center transition-transform group-hover:scale-105">
            <img 
              src="/assets/app_icon.png" 
              alt="Dino Run Epochs" 
              width="28"
              height="28"
              className="w-full h-full object-cover rounded-md pixelated"
            />
          </div>
          <span className="font-['Chakra_Petch'] font-bold text-sm tracking-wide text-white flex items-center gap-1.5">
            DINO RUN
            <span className="text-[10px] px-1.5 py-0.5 rounded bg-white/5 text-slate-300 border border-white/10 font-['Geist_Mono'] font-medium">
              EPOCHS
            </span>
          </span>
        </a>

        {/* Center Navigation Links - Clean Minimal Indicators */}
        <div className="hidden lg:flex items-center gap-1 text-xs tracking-wider font-medium text-slate-300">
          {navItems.map((item) => {
            const isActive = activeId === item.id;
            return (
              <a
                key={item.id}
                href={item.href}
                onClick={(e) => handleNavClick(item, e)}
                className={`relative px-3 py-1.5 rounded-full transition-all duration-200 ${
                  isActive
                    ? 'text-white font-semibold bg-white/10 border border-white/15'
                    : 'text-slate-400 hover:text-slate-200 hover:bg-white/5 border border-transparent'
                }`}
              >
                {item.label}
              </a>
            );
          })}
        </div>

        {/* Action Controls */}
        <div className="flex items-center gap-2 pl-2">
          {/* Soundtrack Control */}
          <button
            onClick={handleToggleSound}
            title={audioState.isPlaying ? "Mute Soundtrack" : "Play 8-Bit Soundtrack"}
            aria-label="Soundtrack toggle"
            className={`px-3 py-1.5 rounded-full border transition-all text-xs flex items-center gap-2 cursor-pointer ${
              audioState.isPlaying 
                ? 'border-amber-500/30 bg-amber-500/10 text-amber-300' 
                : 'border-white/10 text-slate-400 hover:text-white hover:bg-white/5'
            }`}
          >
            {audioState.isPlaying ? (
              <SpeakerHigh weight="fill" size={14} className="text-amber-400" />
            ) : (
              <SpeakerSlash size={14} className="text-slate-400" />
            )}
            <span className="hidden sm:inline text-[11px] font-['Geist_Mono'] font-medium">
              {audioState.isPlaying ? "OST ON" : "OST OFF"}
            </span>
          </button>

          {/* Jump to Game Button */}
          <a 
            href="/#arcade"
            onClick={(e) => {
              handleNavClick({ id: 'arcade', label: 'Play', href: '/#arcade' }, e);
            }}
            className="inline-flex items-center gap-1.5 h-8 px-4 rounded-full bg-white text-slate-950 font-['Chakra_Petch'] font-bold text-xs uppercase tracking-wider hover:bg-slate-200 active:scale-95 transition-all shadow-sm"
          >
            <Play weight="fill" size={12} />
            <span>Play Now</span>
          </a>
        </div>
      </nav>
    </header>
  );
}
