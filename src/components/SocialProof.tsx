import React from 'react';
import { motion } from 'framer-motion';

const reviews = [
  {
    name: "Elena Rostova",
    handle: "@erostova_dev",
    body: "Finally, a browser game that actually runs at a solid 60FPS. The biome transitions are incredibly smooth.",
    avatar: "https://api.dicebear.com/7.x/notionists/svg?seed=Elena&backgroundColor=ea580c"
  },
  {
    name: "Marcus Thorne",
    handle: "@mthorne_design",
    body: "I was supposed to be working, but then I hit the Ice Age epoch. The adaptive AI is brutal in the best way possible.",
    avatar: "https://api.dicebear.com/7.x/notionists/svg?seed=Marcus&backgroundColor=3b82f6"
  },
  {
    name: "Dr. Sarah Lin",
    handle: "@slin_paleo",
    body: "Historically inaccurate pterodactyl flight patterns, but mechanically flawless. 10/10 would run again.",
    avatar: "https://api.dicebear.com/7.x/notionists/svg?seed=Sarah&backgroundColor=f59e0b"
  }
];

export default function SocialProof() {
  return (
    <section className="w-full py-24 px-4 md:px-8 max-w-[1400px] mx-auto border-t border-orange-500/10">
      <div className="flex flex-col items-center text-center space-y-4 mb-16">
        <h2 className="text-4xl md:text-5xl font-bold tracking-tighter text-white font-display uppercase">
          Loved by <span className="text-gradient-magma">Runners.</span>
        </h2>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {reviews.map((review, idx) => (
          <motion.div 
            key={idx}
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-50px" }}
            transition={{ type: "spring", stiffness: 100, damping: 20, delay: idx * 0.1 }}
            className="obsidian-glass rounded-[2rem] p-8 flex flex-col justify-between group hover:-translate-y-2 transition-transform duration-300"
          >
            <p className="text-zinc-300 text-lg leading-relaxed mb-8 font-medium">"{review.body}"</p>
            
            <div className="flex items-center gap-4">
              <div className="w-12 h-12 rounded-full overflow-hidden bg-zinc-800 border-2 border-orange-500/30 group-hover:border-orange-500 transition-colors">
                <img src={review.avatar} alt={review.name} className="w-full h-full object-cover" />
              </div>
              <div>
                <p className="text-white font-bold">{review.name}</p>
                <p className="text-amber-500/80 text-sm">{review.handle}</p>
              </div>
            </div>
          </motion.div>
        ))}
      </div>

      <div className="mt-20 flex justify-center">
         <div className="obsidian-glass px-8 py-6 rounded-full flex flex-wrap justify-center items-center gap-8 md:gap-16 border-orange-500/30 shadow-[0_0_40px_rgba(245,158,11,0.15)]">
            <div className="text-center">
              <p className="text-4xl font-display text-orange-500">47.2k</p>
              <p className="text-xs text-zinc-400 font-bold uppercase tracking-widest mt-1">Daily Plays</p>
            </div>
            <div className="w-px h-8 bg-zinc-800" />
            <div className="text-center">
              <p className="text-4xl font-display text-amber-400">12.4m</p>
              <p className="text-xs text-zinc-400 font-bold uppercase tracking-widest mt-1">Miles Run</p>
            </div>
            <div className="w-px h-8 bg-zinc-800 hidden md:block" />
            <div className="text-center hidden md:block">
              <p className="text-4xl font-display text-cyan-400">99.9%</p>
              <p className="text-xs text-zinc-400 font-bold uppercase tracking-widest mt-1">Uptime</p>
            </div>
         </div>
      </div>
    </section>
  );
}
