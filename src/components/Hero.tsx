import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  Play, 
  GameController, 
  Sparkle, 
  Lightning,
  Sun, 
  Drop, 
  Tree, 
  Snowflake, 
  Fire, 
  Planet 
} from '@phosphor-icons/react';
import RiveDino from './RiveDino';
import { soundManager } from '../utils/soundManager';

const epochs = [
  {
    id: 'desert',
    name: 'Desert Dunes',
    tag: '01',
    score: '0 — 4.5K',
    bgImage: '/assets/backgrounds/bg_desert.jpg',
    icon: Sun,
    desc: 'Prehistoric amber dunes with fossil hazards and intense solar heat distortion.'
  },
  {
    id: 'rain',
    name: 'Monsoon Basin',
    tag: '02',
    score: '4.5K — 9K',
    bgImage: '/assets/backgrounds/bg_rain.jpg',
    icon: Drop,
    desc: 'Low-friction torrential downpours, slippery mud flats, and obscured vision.'
  },
  {
    id: 'forest',
    name: 'Primeval Forest',
    tag: '03',
    score: '9K — 13.5K',
    bgImage: '/assets/backgrounds/bg_forest.jpg',
    icon: Tree,
    desc: 'Lush Jurassic redwood canopy with dense bio-luminescent flora.'
  },
  {
    id: 'ice',
    name: 'Glacial Permafrost',
    tag: '04',
    score: '13.5K — 18K',
    bgImage: '/assets/backgrounds/bg_ice.jpg',
    icon: Snowflake,
    desc: 'Sub-zero temperatures, aurora skies, and jagged crystalline ice spikes.'
  },
  {
    id: 'volcano',
    name: 'Magma Caldera',
    tag: '05',
    score: '18K — 22.5K',
    bgImage: '/assets/backgrounds/bg_volcano.jpg',
    icon: Fire,
    desc: 'Molten lava flows, falling volcanic cinder rocks, and seismic floor rifts.'
  },
  {
    id: 'cosmos',
    name: 'Cosmic Singularity',
    tag: '06',
    score: '22.5K+',
    bgImage: '/assets/backgrounds/bg_cosmos.jpg',
    icon: Planet,
    desc: 'Spacetime rupture, anti-gravity physics, and celestial asteroid debris.'
  }
];

export default function Hero() {
  const [activeEpoch, setActiveEpoch] = useState(epochs[0]);

  const handleSelectEpoch = (ep: typeof epochs[0]) => {
    soundManager.playEpochSelectSfx();
    setActiveEpoch(ep);
  };

  const handleLaunchGame = () => {
    soundManager.playUiClick();
    const arcadeEl = document.getElementById('arcade');
    if (arcadeEl) {
      arcadeEl.scrollIntoView({ behavior: 'smooth' });
    }
  };

  return (
    <section className="relative w-full pt-28 pb-16 px-4 md:px-8 max-w-[1360px] mx-auto min-h-[85vh] flex flex-col justify-center">
      
      {/* Delicate background ambient spotlight */}
      <div className="absolute top-12 left-1/2 -translate-x-1/2 w-[700px] h-[300px] bg-slate-800/20 rounded-full blur-[140px] pointer-events-none -z-10" />

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-10 lg:gap-14 items-center">
        
        {/* Left Column: Asymmetric Editorial Presentation */}
        <div className="lg:col-span-6 space-y-6 text-left">
          
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full border border-white/10 bg-white/[0.03] text-slate-300 text-xs font-['Geist_Mono']">
            <span className="w-1.5 h-1.5 rounded-full bg-emerald-400" />
            <span>FLUTTER FLAME 2D • 60 FPS WASM</span>
          </div>

          <h1 className="text-4xl sm:text-5xl lg:text-6xl font-bold tracking-tight text-white font-['Chakra_Petch'] leading-[1.08]">
            THE CHROME DINO <br className="hidden sm:block" />
            RE-ENGINEERED <br className="hidden sm:block" />
            <span className="text-amber-400 block sm:inline mt-1 sm:mt-0">
              ACROSS 6 EPOCHS.
            </span>
          </h1>

          <p className="text-slate-400 text-base md:text-lg leading-relaxed max-w-[50ch]">
            Procedural prehistoric survival powered by WebAssembly, Skia GPU acceleration, and interactive vector bone physics. Zero downloads required.
          </p>

          {/* Action CTAs */}
          <div className="flex flex-wrap items-center gap-3.5 pt-2">
            <button
              onClick={handleLaunchGame}
              className="px-7 py-3.5 rounded-xl bg-white hover:bg-slate-200 text-slate-950 font-bold font-['Chakra_Petch'] text-sm tracking-wider uppercase flex items-center gap-2.5 transition-all active:scale-98 shadow-md cursor-pointer"
            >
              <Play size={16} weight="fill" />
              <span>Launch Arcade Free</span>
            </button>

            <a
              href="/epochs"
              onClick={() => soundManager.playUiClick()}
              className="px-5 py-3.5 rounded-xl border border-white/10 bg-white/[0.02] hover:bg-white/[0.06] text-slate-200 font-semibold font-['Chakra_Petch'] text-sm tracking-wider uppercase flex items-center gap-2 transition-colors"
            >
              <GameController size={16} />
              <span>Explore Epochs</span>
            </a>
          </div>

          {/* Hardware & Spec Badges */}
          <div className="pt-6 border-t border-white/8 grid grid-cols-3 gap-4 font-['Geist_Mono'] text-xs">
            <div>
              <p className="text-slate-500 text-[11px]">RENDER ENGINE</p>
              <p className="text-white font-semibold mt-0.5">Flame 2D WASM</p>
            </div>
            <div>
              <p className="text-slate-500 text-[11px]">TARGET REFRESH</p>
              <p className="text-emerald-400 font-semibold mt-0.5">60 FPS Locked</p>
            </div>
            <div>
              <p className="text-slate-500 text-[11px]">RIG DYNAMICS</p>
              <p className="text-white font-semibold mt-0.5">Rive Vector Bones</p>
            </div>
          </div>
        </div>

        {/* Right Column: Live Interactive Game Deck */}
        <div className="lg:col-span-6">
          <div className="surface-card rounded-2xl p-4 sm:p-5 border border-white/10 shadow-2xl space-y-4">
            
            {/* Viewport Frame */}
            <div className="relative aspect-[16/10] rounded-xl overflow-hidden bg-slate-950 border border-white/8">
              <AnimatePresence mode="wait">
                <motion.div
                  key={activeEpoch.id}
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  exit={{ opacity: 0 }}
                  transition={{ duration: 0.35 }}
                  className="absolute inset-0 bg-cover bg-center"
                  style={{ backgroundImage: `url(${activeEpoch.bgImage})` }}
                />
              </AnimatePresence>

              {/* Recessed Vignette */}
              <div className="absolute inset-0 bg-gradient-to-t from-slate-950/90 via-transparent to-slate-950/30 pointer-events-none" />

              {/* Rive Bone Interactive Model in Canvas */}
              <div className="absolute bottom-6 left-1/2 -translate-x-1/2 z-10 flex flex-col items-center">
                <RiveDino className="w-28 h-28 drop-shadow-2xl" />
              </div>

              {/* Info Pill Top Right */}
              <div className="absolute top-3 right-3 z-10 flex items-center gap-1.5 px-2.5 py-1 rounded-md bg-slate-950/80 border border-white/10 text-[11px] font-['Geist_Mono'] text-slate-300">
                <span>{activeEpoch.name}</span>
                <span className="text-slate-500">•</span>
                <span className="text-amber-400 font-bold">{activeEpoch.score} PTS</span>
              </div>
            </div>

            {/* Epoch Selector Strip - Clean Minimal Buttons */}
            <div className="grid grid-cols-3 sm:grid-cols-6 gap-1.5 pt-1">
              {epochs.map((ep) => {
                const isSelected = activeEpoch.id === ep.id;
                const Icon = ep.icon;
                return (
                  <button
                    key={ep.id}
                    onClick={() => handleSelectEpoch(ep)}
                    title={ep.name}
                    className={`flex flex-col items-center justify-center py-2 px-1 rounded-lg border transition-all cursor-pointer ${
                      isSelected
                        ? 'bg-white/10 border-white/20 text-white shadow-sm'
                        : 'bg-white/[0.02] border-transparent text-slate-400 hover:text-slate-200 hover:bg-white/[0.05]'
                    }`}
                  >
                    <Icon size={16} weight={isSelected ? "fill" : "regular"} />
                    <span className="text-[9px] font-['Geist_Mono'] mt-1 tracking-tighter">
                      {ep.tag}
                    </span>
                  </button>
                );
              })}
            </div>

            {/* Active Description */}
            <div className="p-3 rounded-lg bg-white/[0.02] border border-white/5 flex items-start gap-2.5 text-xs text-slate-300">
              <span className="w-1.5 h-1.5 rounded-full bg-amber-400 mt-1.5 shrink-0" />
              <p className="leading-relaxed font-['Outfit']">
                <strong className="text-white font-medium">{activeEpoch.name}:</strong> {activeEpoch.desc}
              </p>
            </div>

          </div>
        </div>

      </div>
    </section>
  );
}
