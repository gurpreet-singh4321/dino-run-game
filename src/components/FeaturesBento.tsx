import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  Sparkle,
  Sun,
  Drop,
  Tree,
  Snowflake,
  Fire,
  Planet,
  SpeakerHigh,
  ArrowsClockwise
} from '@phosphor-icons/react';
import { soundManager } from '../utils/soundManager';

const levelBiomes = [
  { id: 'desert', name: 'Desert Dunes', score: '0 - 4.5K', bg: '/assets/backgrounds/bg_desert.jpg', icon: Sun, desc: 'Prehistoric amber dunes, cracked mudflats, dinosaur fossil hazards.' },
  { id: 'rain', name: 'Monsoon Basin', score: '4.5K - 9K', bg: '/assets/backgrounds/bg_rain.jpg', icon: Drop, desc: 'Thunderstorms, pouring rain streaks, wet rock cliffs, waterfalls.' },
  { id: 'forest', name: 'Primeval Forest', score: '9K - 13.5K', bg: '/assets/backgrounds/bg_forest.jpg', icon: Tree, desc: 'Ancient Jurassic ferns, bioluminescent moss, massive redwood canopy.' },
  { id: 'ice', name: 'Glacial Permafrost', score: '13.5K - 18K', bg: '/assets/backgrounds/bg_ice.jpg', icon: Snowflake, desc: 'Sub-zero blizzards, aurora borealis, crystal ice spikes, icy terrain.' },
  { id: 'volcano', name: 'Magma Caldera', score: '18K - 22.5K', bg: '/assets/backgrounds/bg_volcano.jpg', icon: Fire, desc: 'Erupting ash volcano, molten lava flows, obsidian basalt crags.' },
  { id: 'cosmos', name: 'Cosmic Singularity', score: '22.5K+', bg: '/assets/backgrounds/bg_cosmos.jpg', icon: Planet, desc: 'Spacetime rifts, glowing nebula spiral, anti-gravity asteroid fields.' }
];

export default function FeaturesBento() {
  const [selectedBiome, setSelectedBiome] = useState(levelBiomes[0]);

  const handleSelectBiome = (biome: typeof levelBiomes[0]) => {
    soundManager.playEpochSelectSfx();
    setSelectedBiome(biome);
  };

  return (
    <section id="biomes" className="relative w-full py-16 px-4 md:px-8 max-w-[1360px] mx-auto">
      
      {/* Section Header */}
      <div className="mb-10 max-w-[70ch]">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full border border-white/10 bg-white/[0.03] text-slate-300 text-xs font-['Geist_Mono'] mb-3">
          <Sparkle size={14} />
          <span>PROCEDURAL ATMOSPHERIC ENVIRONMENTS</span>
        </div>
        <h2 className="text-3xl sm:text-4xl font-bold tracking-tight text-white font-['Chakra_Petch'] uppercase">
          THE 6 ERA PROGRESSION SYSTEM
        </h2>
        <p className="mt-3 text-slate-400 text-sm sm:text-base leading-relaxed">
          Dynamic weather, parallax terrain, and shifting velocity. Every 4,500 points transitions the runner seamlessly into a brand new biome.
        </p>
      </div>

      {/* Main Feature Layout */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 w-full items-start">
        
        {/* Left Column: Big Interactive Environment Preview */}
        <div className="lg:col-span-8 surface-card rounded-2xl p-4 sm:p-6 border border-white/10 space-y-4">
          <div className="relative aspect-[16/9] rounded-xl overflow-hidden bg-slate-950 border border-white/8">
            <AnimatePresence mode="wait">
              <motion.div
                key={selectedBiome.id}
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                transition={{ duration: 0.3 }}
                className="absolute inset-0 bg-cover bg-center"
                style={{ backgroundImage: `url(${selectedBiome.bg})` }}
              />
            </AnimatePresence>

            <div className="absolute inset-0 bg-gradient-to-t from-slate-950/80 via-transparent to-black/20 pointer-events-none" />

            <div className="absolute bottom-4 left-4 right-4 flex items-end justify-between">
              <div>
                <span className="text-[10px] font-['Geist_Mono'] px-2 py-0.5 rounded bg-white/10 text-white">
                  SCORE GOAL: {selectedBiome.score}
                </span>
                <h3 className="text-xl sm:text-2xl font-bold text-white font-['Chakra_Petch'] mt-1">
                  {selectedBiome.name}
                </h3>
              </div>
            </div>
          </div>

          <div className="p-3 rounded-lg bg-white/[0.02] border border-white/5 text-xs text-slate-300">
            <p className="leading-relaxed font-['Outfit']">
              {selectedBiome.desc} Atmospheric fog and sky shader parameters dynamically interpolate over 3.5 seconds when crossing score threshold.
            </p>
          </div>
        </div>

        {/* Right Column: Clean Vertical Era Selector Tabs */}
        <div className="lg:col-span-4 space-y-2">
          <p className="text-[11px] font-['Geist_Mono'] text-slate-500 uppercase tracking-wider mb-2 px-1">
            SELECT ERA TO INSPECT:
          </p>

          {levelBiomes.map((biome, idx) => {
            const isSelected = selectedBiome.id === biome.id;
            const Icon = biome.icon;
            return (
              <button
                key={biome.id}
                onClick={() => handleSelectBiome(biome)}
                className={`w-full text-left p-3 rounded-xl border transition-all flex items-center justify-between cursor-pointer ${
                  isSelected
                    ? 'bg-white/10 border-white/20 text-white shadow-sm'
                    : 'bg-white/[0.02] border-white/5 text-slate-400 hover:text-slate-200 hover:bg-white/[0.05]'
                }`}
              >
                <div className="flex items-center gap-3">
                  <div className={`w-8 h-8 rounded-lg flex items-center justify-center ${
                    isSelected ? 'bg-white/15 text-white' : 'bg-white/5 text-slate-400'
                  }`}>
                    <Icon size={16} />
                  </div>
                  <div>
                    <h4 className="text-xs sm:text-sm font-semibold font-['Chakra_Petch']">
                      {biome.name}
                    </h4>
                    <span className="text-[10px] font-['Geist_Mono'] text-slate-500">
                      EPOCH 0{idx + 1}
                    </span>
                  </div>
                </div>

                <span className="text-[11px] font-['Geist_Mono'] text-slate-400">
                  {biome.score}
                </span>
              </button>
            );
          })}
        </div>

      </div>

    </section>
  );
}
