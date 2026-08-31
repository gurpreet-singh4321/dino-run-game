import React, { useState } from 'react';
import { CaretDown, Question } from '@phosphor-icons/react';

const faqs = [
  {
    q: "What is Dino Run Epochs?",
    a: "Dino Run Epochs is a modern, high-octane 60FPS evolution of the classic Chrome offline dinosaur game. Built with Flutter, Flame Engine, and WebAssembly, it features 6 procedural atmospheric eras (Desert, Monsoon, Forest, Ice Age, Volcano, and Cosmos), dynamic velocity physics, aerial pterodactyl evasion, and customizable Rive vector bone skins."
  },
  {
    q: "How do Epoch Transitions work in the game?",
    a: "Every 4,500 score points (~3 to 4 minutes of continuous survival), the game triggers an atmospheric transition. Over a 3.5-second sine wave transition, weather fog sweeps in while sky and ground shaders dynamically interpolate to the next era, bringing new obstacle layouts and increased speed."
  },
  {
    q: "What are the controls for playing Dino Run Epochs?",
    a: "On Desktop, press the Spacebar or Up Arrow key to jump, and the Down Arrow key to aerial duck or slide under high pterodactyls. On Mobile or Touch devices, tap anywhere on the screen to jump."
  },
  {
    q: "Is Dino Run Epochs free to play in the browser?",
    a: "Yes! Dino Run Epochs is 100% free and unblocked. It runs directly inside modern web browsers with zero downloads, zero installation, and no paywalls required."
  },
  {
    q: "How is Dino Run Epochs built for 60FPS performance?",
    a: "The game is developed using Google's Flutter framework with the Flame 2D game engine, compiled directly into WebAssembly (WASM) utilizing Skia CanvasKit GPU rendering for silky-smooth 60 frames-per-second performance."
  }
];

export default function GameFaq() {
  const [openIndex, setOpenIndex] = useState<number | null>(0);

  const toggle = (idx: number) => {
    setOpenIndex(openIndex === idx ? null : idx);
  };

  return (
    <section id="faq" className="w-full py-16 px-4 md:px-8 max-w-[900px] mx-auto border-t border-white/8">
      
      {/* Header */}
      <div className="flex flex-col items-center text-center space-y-3 mb-10">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full border border-white/10 bg-white/[0.03] text-slate-300 text-xs font-['Geist_Mono']">
          <Question size={14} />
          <span>FREQUENTLY ASKED QUESTIONS</span>
        </div>
        <h2 className="text-3xl sm:text-4xl font-bold tracking-tight text-white font-['Chakra_Petch'] uppercase">
          KNOWLEDGE BASE
        </h2>
        <p className="text-slate-400 max-w-[45ch] text-sm leading-relaxed">
          Gameplay mechanics, browser compatibility, and technical engine details.
        </p>
      </div>

      {/* Accordion List */}
      <div className="space-y-3">
        {faqs.map((faq, idx) => {
          const isOpen = openIndex === idx;
          return (
            <div 
              key={idx}
              className="surface-card rounded-xl overflow-hidden border border-white/8 transition-colors"
            >
              <button
                onClick={() => toggle(idx)}
                className="w-full px-5 py-4 text-left flex items-center justify-between gap-4 cursor-pointer hover:bg-white/[0.02] transition-colors"
              >
                <span className="font-['Chakra_Petch'] font-semibold text-sm sm:text-base text-white">
                  {faq.q}
                </span>
                <CaretDown 
                  size={16} 
                  className={`text-slate-400 transition-transform duration-200 shrink-0 ${isOpen ? 'rotate-180 text-white' : ''}`}
                />
              </button>

              {isOpen && (
                <div className="px-5 pb-5 pt-1 text-slate-400 text-xs sm:text-sm leading-relaxed border-t border-white/5 font-['Outfit']">
                  {faq.a}
                </div>
              )}
            </div>
          );
        })}
      </div>

    </section>
  );
}
