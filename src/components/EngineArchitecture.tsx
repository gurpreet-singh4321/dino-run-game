import React from 'react';
import { Cpu, Code, Lightning, ShieldCheck, Terminal } from '@phosphor-icons/react';

const specs = [
  {
    icon: <Cpu size={20} className="text-slate-300" />,
    title: "Flame 2D Lifecycle",
    desc: "Decoupled component update/render loops prevent garbage collection pauses during high-speed sprint stages."
  },
  {
    icon: <Lightning size={20} className="text-slate-300" />,
    title: "WASM CanvasKit",
    desc: "Compiled directly to WebAssembly with Skia GPU hardware rendering for zero dropped frames across all modern browsers."
  },
  {
    icon: <Code size={20} className="text-slate-300" />,
    title: "Rive Bone State-Machine",
    desc: "Integrated vector bone rigs dynamically blend run, jump, duck, and velocity-tilt states with zero pixel artifacting."
  },
  {
    icon: <ShieldCheck size={20} className="text-slate-300" />,
    title: "Fair Spawning System",
    desc: "Deterministic difficulty algorithm balances obstacle spacing against current player speed to guarantee skill-based clearance."
  }
];

export default function EngineArchitecture() {
  return (
    <section id="specs" className="w-full py-16 px-4 md:px-8 max-w-[1360px] mx-auto border-t border-white/8">
      
      {/* Header */}
      <div className="mb-10 max-w-[70ch]">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full border border-white/10 bg-white/[0.03] text-slate-300 text-xs font-['Geist_Mono'] mb-3">
          <Terminal size={14} />
          <span>ARCHITECTURE & ENGINE SPECIFICATIONS</span>
        </div>
        <h2 className="text-3xl sm:text-4xl font-bold tracking-tight text-white font-['Chakra_Petch'] uppercase">
          ENGINEERED FOR ZERO JANK
        </h2>
        <p className="mt-3 text-slate-400 text-sm sm:text-base leading-relaxed">
          Deep architectural optimization ensuring consistent 60FPS physics and responsiveness across desktop and mobile devices.
        </p>
      </div>

      {/* Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {specs.map((item, idx) => (
          <div 
            key={idx}
            className="surface-card rounded-xl p-5 border border-white/8 flex flex-col justify-between"
          >
            <div>
              <div className="w-9 h-9 rounded-lg bg-white/5 border border-white/10 flex items-center justify-center mb-4">
                {item.icon}
              </div>
              <h3 className="text-base font-bold text-white font-['Chakra_Petch'] mb-2">
                {item.title}
              </h3>
              <p className="text-slate-400 text-xs leading-relaxed font-['Outfit']">
                {item.desc}
              </p>
            </div>
          </div>
        ))}
      </div>

    </section>
  );
}
