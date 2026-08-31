import React from 'react';
import { Play, Lightning } from '@phosphor-icons/react';
import { soundManager } from '../utils/soundManager';

export default function FooterCTA() {
  const handleLaunch = () => {
    soundManager.playUiClick();
    const el = document.getElementById('arcade');
    if (el) el.scrollIntoView({ behavior: 'smooth' });
  };

  return (
    <section className="w-full py-16 px-4 md:px-8 max-w-[1360px] mx-auto border-t border-white/8">
      <div className="surface-card rounded-3xl p-8 md:p-14 text-center flex flex-col items-center relative overflow-hidden border border-white/10">
        
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full border border-white/10 bg-white/[0.03] text-slate-300 text-xs font-['Geist_Mono'] mb-4">
          <Lightning size={14} className="text-amber-400" />
          <span>FREE INSTANT WEB BROWSER ACCESS</span>
        </div>

        <h2 className="text-3xl sm:text-5xl font-bold tracking-tight text-white font-['Chakra_Petch'] uppercase max-w-[20ch] leading-tight">
          READY TO SURVIVE ALL SIX PREHISTORIC ERAS?
        </h2>

        <p className="text-slate-400 text-sm sm:text-base max-w-[45ch] mt-3 mb-6 leading-relaxed">
          Zero paywalls, zero lag, instant 60FPS browser action. Test your reflexes in the ultimate dinosaur runner.
        </p>

        <button 
          onClick={handleLaunch}
          className="inline-flex items-center justify-center gap-2.5 h-12 px-8 rounded-xl bg-white text-slate-950 font-['Chakra_Petch'] font-bold text-sm uppercase tracking-wider hover:bg-slate-200 active:scale-98 transition-all shadow-lg cursor-pointer"
        >
          <Play weight="fill" size={16} />
          <span>Jump to Arena</span>
        </button>

      </div>
    </section>
  );
}
