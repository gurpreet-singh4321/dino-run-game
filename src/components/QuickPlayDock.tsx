import React, { useState, useEffect } from 'react';
import { Play, ArrowUp, GameController } from '@phosphor-icons/react';
import { soundManager } from '../utils/soundManager';

export default function QuickPlayDock() {
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      const scrolledPastHero = window.scrollY > 400;
      setVisible(scrolledPastHero);
    };

    window.addEventListener('scroll', handleScroll, { passive: true });
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  const handleJumpToGame = () => {
    soundManager.playUiClick();
    const el = document.getElementById('arcade');
    if (el) {
      el.scrollIntoView({ behavior: 'smooth' });
    }
  };

  const handleScrollTop = () => {
    soundManager.playUiClick();
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  if (!visible) return null;

  return (
    <div className="fixed bottom-5 left-1/2 -translate-x-1/2 z-40 flex items-center gap-1.5 p-1.5 rounded-full surface-pill border border-white/12 shadow-[0_16px_36px_rgba(0,0,0,0.6)] backdrop-blur-2xl">
      {/* Quick Play Main Action */}
      <button
        onClick={handleJumpToGame}
        className="flex items-center gap-2 px-4 py-2 rounded-full bg-white text-slate-950 font-['Chakra_Petch'] font-bold text-xs uppercase tracking-wider hover:bg-slate-200 transition-all active:scale-95 cursor-pointer shadow-sm"
      >
        <Play weight="fill" size={13} />
        <span>Jump to Arena</span>
      </button>

      {/* Scroll to Top Action */}
      <button
        onClick={handleScrollTop}
        className="w-8 h-8 rounded-full bg-white/[0.04] border border-white/10 hover:bg-white/10 text-slate-400 hover:text-white flex items-center justify-center transition-colors cursor-pointer"
        title="Scroll to Top"
        aria-label="Scroll to top"
      >
        <ArrowUp size={14} />
      </button>
    </div>
  );
}
