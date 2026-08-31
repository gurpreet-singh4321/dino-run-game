import React from 'react';
import { Crosshair, WarningOctagon, Wind, Trophy } from '@phosphor-icons/react';

const tactics = [
  {
    code: "TAC-01",
    title: "Ground Obstacle Cluster Scaling",
    desc: "Single cacti require standard apex jump arcs. Triple dense clusters demand late takeoffs to prevent clipped heel hitboxes upon landing.",
    hazard: "Small & Tall Saguaro Clusters",
    action: "TAP SPACEBAR AT 120PX DISTANCE"
  },
  {
    code: "TAC-02",
    title: "Tri-Altitude Pterodactyl Evasion",
    desc: "Pterodactyls patrol at three discrete altitudes. High patrol: sprint underneath without jumping. Low patrol: leap over. Mid patrol: initiate immediate aerial crouch.",
    hazard: "Aerial Hunting Flight Paths",
    action: "PRESS DOWN ARROW TO DUCK"
  },
  {
    code: "TAC-03",
    title: "Atmospheric Fog Threshold",
    desc: "Every 4,500 points (~3-4 min), the environment transitions through dense weather fog. Maintain consistent jump cadence as visual markers shift.",
    hazard: "Peak Sine Wave Fog Obscurity",
    action: "LISTEN FOR AUDIO CUES"
  },
  {
    code: "TAC-04",
    title: "Near-Miss Velocity Combos",
    desc: "Clearing obstacles with narrow hitboxes triggers near-miss combo multipliers, multiplying your point accumulation rate exponentially.",
    hazard: "High Risk Close Proximity Jump",
    action: "TIME CLOSE GRAZE FRAMES"
  }
];

export default function HowToPlay() {
  return (
    <section id="mechanics" className="w-full py-16 px-4 md:px-8 max-w-[1360px] mx-auto border-t border-white/8">
      
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-10 items-start">
        
        {/* Left Intro */}
        <div className="lg:col-span-4 lg:sticky lg:top-24">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full border border-white/10 bg-white/[0.03] text-slate-300 text-xs font-['Geist_Mono'] mb-3">
            <Crosshair size={14} />
            <span>MOVEMENT DOCTRINES</span>
          </div>
          <h2 className="text-3xl sm:text-4xl font-bold tracking-tight text-white font-['Chakra_Petch'] leading-tight">
            SURVIVAL TACTICS MANUAL
          </h2>
          <p className="mt-3 text-slate-400 text-sm sm:text-base leading-relaxed">
            Every epoch accelerates velocity and introduces varied obstacle density. Master these core maneuvers to push past the 20,000-point mark.
          </p>
        </div>

        {/* Right Tactics List */}
        <div className="lg:col-span-8 space-y-4">
          {tactics.map((tac, idx) => (
            <div 
              key={idx}
              className="surface-card rounded-xl p-5 md:p-6 border border-white/8 transition-all hover:border-white/15"
            >
              <div className="flex items-center justify-between mb-2">
                <span className="text-[10px] font-['Geist_Mono'] px-2 py-0.5 rounded bg-white/5 border border-white/10 text-slate-400 font-semibold">
                  {tac.code}
                </span>
                <span className="text-[10px] font-['Geist_Mono'] text-slate-500 uppercase">
                  {tac.hazard}
                </span>
              </div>

              <h3 className="text-base sm:text-lg font-bold text-white font-['Chakra_Petch'] mb-1.5">
                {tac.title}
              </h3>
              
              <p className="text-slate-400 text-xs sm:text-sm leading-relaxed mb-3">
                {tac.desc}
              </p>

              <div className="pt-2 border-t border-white/5 flex items-center justify-between text-[11px] font-['Geist_Mono'] text-slate-400">
                <span>ACTION RULE:</span>
                <span className="text-white font-medium">{tac.action}</span>
              </div>
            </div>
          ))}
        </div>

      </div>

    </section>
  );
}
