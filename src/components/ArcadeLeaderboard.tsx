import React, { useState, useEffect } from 'react';
import { Trophy, Medal, Lightning, Sparkle } from '@phosphor-icons/react';
import { soundManager } from '../utils/soundManager';

interface LeaderboardEntry {
  rank: number;
  name: string;
  score: number;
  epoch: string;
  isPlayer?: boolean;
}

export default function ArcadeLeaderboard() {
  const [personalBest, setPersonalBest] = useState<number>(14250);
  const [runsCount, setRunsCount] = useState<number>(12);

  useEffect(() => {
    try {
      const savedPb = localStorage.getItem('dino_personal_best');
      const savedRuns = localStorage.getItem('dino_runs_count');
      if (savedPb) setPersonalBest(parseInt(savedPb, 10));
      if (savedRuns) setRunsCount(parseInt(savedRuns, 10));
    } catch (_) {}
  }, []);

  const entries: LeaderboardEntry[] = [
    { rank: 1, name: "VELOCITY_REX", score: 48920, epoch: "Cosmic Singularity" },
    { rank: 2, name: "APEX_SPRINTER", score: 36400, epoch: "Magma Caldera" },
    { rank: 3, name: "FROST_BYTE", score: 28150, epoch: "Glacial Permafrost" },
    { rank: 4, name: "YOU (Personal Record)", score: personalBest, epoch: "Primeval Forest", isPlayer: true },
    { rank: 5, name: "NEO_RAPTOR", score: 12890, epoch: "Monsoon Basin" },
  ];

  return (
    <div className="w-full rounded-2xl surface-card p-6 md:p-7 border border-white/10 shadow-xl">
      {/* Header */}
      <div className="flex items-center justify-between border-b border-white/8 pb-4 mb-5">
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-lg bg-white/[0.04] border border-white/10 flex items-center justify-center text-slate-200">
            <Trophy size={20} />
          </div>
          <div>
            <h3 className="text-base font-bold font-['Chakra_Petch'] text-white uppercase tracking-wide">
              GLOBAL LEADERBOARD
            </h3>
            <p className="text-xs text-slate-400 font-['Geist_Mono']">
              Survival Standings & Epoch Mastery
            </p>
          </div>
        </div>

        <span className="text-[11px] font-['Geist_Mono'] px-2.5 py-1 rounded-md bg-white/[0.04] border border-white/8 text-slate-400">
          SEASON 01
        </span>
      </div>

      {/* Leaderboard Table */}
      <div className="space-y-2 font-['Geist_Mono']">
        {entries.map((entry) => (
          <div
            key={entry.rank}
            className={`flex items-center justify-between px-3.5 py-3 rounded-xl border transition-colors ${
              entry.isPlayer
                ? 'bg-amber-500/10 border-amber-500/30'
                : 'bg-white/[0.02] border-white/5 hover:border-white/10'
            }`}
          >
            <div className="flex items-center gap-3">
              <span className={`w-6 h-6 rounded-md flex items-center justify-center text-xs font-bold ${
                entry.rank === 1 ? 'bg-amber-400 text-slate-950 font-bold' :
                entry.rank === 2 ? 'bg-slate-300 text-slate-950 font-bold' :
                entry.rank === 3 ? 'bg-amber-700/80 text-white font-bold' :
                'bg-slate-800 text-slate-400'
              }`}>
                {entry.rank}
              </span>
              <div className="flex flex-col">
                <span className={`text-xs sm:text-sm font-semibold ${entry.isPlayer ? 'text-amber-300 font-bold' : 'text-slate-200'}`}>
                  {entry.name}
                </span>
                <span className="text-[10px] text-slate-400">
                  {entry.epoch}
                </span>
              </div>
            </div>

            <div className="text-right">
              <span className={`text-xs sm:text-sm font-bold font-['Geist_Mono'] ${
                entry.isPlayer ? 'text-amber-300' : 'text-white'
              }`}>
                {entry.score.toLocaleString()} PTS
              </span>
            </div>
          </div>
        ))}
      </div>

      {/* Footer Stat Bar */}
      <div className="mt-5 pt-4 border-t border-white/8 flex items-center justify-between text-xs font-['Geist_Mono'] text-slate-400">
        <div className="flex items-center gap-4">
          <span>Personal Best: <strong className="text-white">{personalBest.toLocaleString()} pts</strong></span>
          <span>Career Runs: <strong className="text-slate-300">{runsCount}</strong></span>
        </div>
        <div className="flex items-center gap-1.5 text-[11px] text-slate-400">
          <span className="w-1.5 h-1.5 rounded-full bg-emerald-400" />
          <span>Local Sync</span>
        </div>
      </div>
    </div>
  );
}
