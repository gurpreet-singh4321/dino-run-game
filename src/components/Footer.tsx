import React from 'react';
import { GameController, BookOpen, ShieldCheck, Heart, ArrowUpRight } from '@phosphor-icons/react';

export default function Footer() {
  return (
    <footer className="w-full border-t border-white/10 mt-20 pt-16 pb-12 bg-slate-950/80 backdrop-blur-xl">
      <div className="max-w-[1400px] mx-auto px-4 md:px-8">
        
        {/* Main Grid */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-10 pb-12 border-b border-white/10">
          
          {/* Col 1: Brand & Identity */}
          <div className="lg:col-span-2 space-y-4">
            <a href="/" className="inline-flex items-center gap-2.5">
              <div className="w-9 h-9 rounded-xl overflow-hidden border border-amber-500/30 p-0.5 bg-slate-900 flex items-center justify-center">
                <img 
                  src="/assets/app_icon.png" 
                  alt="Dino Run Epochs Logo" 
                  width="36" 
                  height="36" 
                  className="w-full h-full object-cover rounded-lg pixelated" 
                />
              </div>
              <span className="font-['Chakra_Petch'] font-bold text-lg tracking-wider text-white flex items-center gap-2">
                DINO RUN
                <span className="text-[10px] px-1.5 py-0.5 rounded bg-amber-500/10 text-amber-400 border border-amber-500/30 font-['Geist_Mono'] font-semibold">
                  EPOCHS
                </span>
              </span>
            </a>
            
            <p className="text-slate-400 text-sm leading-relaxed max-w-[42ch]">
              The high-octane 60FPS evolution of the classic offline dinosaur arcade. Engineered with Flutter, Flame 2D, CanvasKit, and WebAssembly with 6 procedural biomes and Rive bone physics.
            </p>

            <div className="flex items-center gap-3 pt-2 text-xs font-['Geist_Mono'] text-slate-400">
              <span className="flex items-center gap-1.5">
                <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
                V2.0.4 Online
              </span>
              <span>•</span>
              <span>100% Free & Unblocked</span>
            </div>
          </div>

          {/* Col 2: The 6 Epochs */}
          <div className="space-y-3">
            <h4 className="font-['Chakra_Petch'] font-bold text-xs uppercase tracking-widest text-amber-400 flex items-center gap-1.5">
              <GameController size={16} />
              The 6 Epochs
            </h4>
            <ul className="space-y-2 text-sm text-slate-300 font-['Outfit']">
              <li><a href="/epochs#desert" className="hover:text-amber-300 transition-colors">Desert Dunes (0 - 4.5K)</a></li>
              <li><a href="/epochs#rain" className="hover:text-cyan-300 transition-colors">Monsoon Basin (4.5K - 9K)</a></li>
              <li><a href="/epochs#forest" className="hover:text-emerald-300 transition-colors">Primeval Forest (9K - 13.5K)</a></li>
              <li><a href="/epochs#ice" className="hover:text-sky-300 transition-colors">Glacial Permafrost (13.5K - 18K)</a></li>
              <li><a href="/epochs#volcano" className="hover:text-rose-300 transition-colors">Magma Caldera (18K - 22.5K)</a></li>
              <li><a href="/epochs#cosmos" className="hover:text-purple-300 transition-colors">Cosmic Singularity (22.5K+)</a></li>
              <li className="pt-1">
                <a href="/epochs" className="text-xs font-['Geist_Mono'] text-amber-400 hover:underline flex items-center gap-1">
                  Full Epochs Codex →
                </a>
              </li>
            </ul>
          </div>

          {/* Col 3: Strategy & Guides */}
          <div className="space-y-3">
            <h4 className="font-['Chakra_Petch'] font-bold text-xs uppercase tracking-widest text-sky-400 flex items-center gap-1.5">
              <BookOpen size={16} />
              Guides & Devlogs
            </h4>
            <ul className="space-y-2 text-sm text-slate-300 font-['Outfit']">
              <li>
                <a href="/guides/how-to-play-dino-runner" className="hover:text-sky-300 transition-colors">
                  How to Play & Tactics Guide
                </a>
              </li>
              <li>
                <a href="/guides/history-of-the-chrome-dinosaur-game" className="hover:text-sky-300 transition-colors">
                  Evolution of the Chrome Dino
                </a>
              </li>
              <li>
                <a href="/guides/tech-stack-flutter-wasm" className="hover:text-sky-300 transition-colors">
                  Flutter Flame & WASM Architecture
                </a>
              </li>
              <li>
                <a href="/#faq" className="hover:text-sky-300 transition-colors">
                  Frequently Asked Questions
                </a>
              </li>
              <li>
                <a href="/about" className="hover:text-sky-300 transition-colors">
                  About the Studio & Mission
                </a>
              </li>
            </ul>
          </div>

          {/* Col 4: Trust, Legal & Transparency */}
          <div className="space-y-3">
            <h4 className="font-['Chakra_Petch'] font-bold text-xs uppercase tracking-widest text-emerald-400 flex items-center gap-1.5">
              <ShieldCheck size={16} />
              Trust & Legal
            </h4>
            <ul className="space-y-2 text-sm text-slate-300 font-['Outfit']">
              <li>
                <a href="/privacy" className="hover:text-emerald-300 transition-colors">
                  Privacy Policy (GDPR / CCPA)
                </a>
              </li>
              <li>
                <a href="/terms" className="hover:text-emerald-300 transition-colors">
                  Terms of Service
                </a>
              </li>
              <li>
                <a href="/contact" className="hover:text-emerald-300 transition-colors">
                  Contact & Support
                </a>
              </li>
              <li>
                <a href="/about" className="hover:text-emerald-300 transition-colors">
                  Editorial & E-E-A-T Policy
                </a>
              </li>
            </ul>
          </div>

        </div>

        {/* Bottom Attribution Bar */}
        <div className="pt-8 flex flex-col sm:flex-row items-center justify-between gap-4 text-xs font-['Geist_Mono'] text-slate-400">
          <p>© {new Date().getFullYear()} Dino Run Epochs Studio. All rights reserved.</p>
          <div className="flex items-center gap-4">
            <a href="/privacy" className="hover:text-slate-300">Privacy</a>
            <span>•</span>
            <a href="/terms" className="hover:text-slate-300">Terms</a>
            <span>•</span>
            <a href="/contact" className="hover:text-slate-300">Contact</a>
            <span>•</span>
            <a href="/sitemap.xml" className="hover:text-slate-300">Sitemap</a>
          </div>
        </div>

      </div>
    </footer>
  );
}
