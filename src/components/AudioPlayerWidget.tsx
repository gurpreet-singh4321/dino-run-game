import React, { useState, useEffect } from 'react';
import { 
  Play, 
  Pause, 
  SpeakerHigh, 
  SpeakerSlash, 
  CaretDown,
  Lightning
} from '@phosphor-icons/react';
import { soundManager, type AudioState } from '../utils/soundManager';

const trackList = [
  { key: 'pixel_jump_title.mp3', name: 'Title Theme (8-Bit)' },
  { key: 'one_more_try.mp3', name: 'Stage Run' },
  { key: 'pixel_jump.mp3', name: 'High Velocity Arcade' }
];

export default function AudioPlayerWidget() {
  const [audioState, setAudioState] = useState<AudioState>(soundManager.getState());
  const [expanded, setExpanded] = useState(false);

  useEffect(() => {
    const unsub = soundManager.subscribe((st) => {
      setAudioState(st);
    });
    return () => unsub();
  }, []);

  const handleTogglePlay = (e: React.MouseEvent) => {
    e.stopPropagation();
    soundManager.toggleOst();
  };

  const handleSelectTrack = (trackKey: string) => {
    soundManager.toggleOst(trackKey);
  };

  const handleVolumeChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    soundManager.setVolume(parseFloat(e.target.value));
  };

  return (
    <div className="fixed bottom-5 right-5 z-40 font-['Geist_Mono'] select-none">
      
      {/* Expanded Control Box */}
      {expanded && (
        <div className="mb-2.5 p-4 rounded-xl surface-card border border-white/12 shadow-2xl w-68 space-y-3">
          <div className="flex items-center justify-between border-b border-white/8 pb-2">
            <span className="text-[11px] font-semibold text-white uppercase tracking-wider">Soundtrack</span>
            <button
              onClick={() => setExpanded(false)}
              className="text-slate-400 hover:text-white p-0.5 cursor-pointer"
            >
              <CaretDown size={14} />
            </button>
          </div>

          {/* Track Selector */}
          <div className="space-y-1">
            {trackList.map((t) => (
              <button
                key={t.key}
                onClick={() => handleSelectTrack(t.key)}
                className={`w-full text-left px-2.5 py-1.5 rounded-lg text-[11px] transition-colors flex items-center justify-between cursor-pointer ${
                  audioState.currentTrack === t.key
                    ? 'bg-white/10 text-white font-medium'
                    : 'text-slate-400 hover:text-white hover:bg-white/5'
                }`}
              >
                <span className="truncate">{t.name}</span>
                {audioState.currentTrack === t.key && audioState.isPlaying && (
                  <span className="w-1.5 h-1.5 rounded-full bg-emerald-400" />
                )}
              </button>
            ))}
          </div>

          {/* Volume Slider */}
          <div className="pt-2 border-t border-white/8 flex items-center gap-2 text-xs text-slate-400">
            <SpeakerHigh size={14} />
            <input
              type="range"
              min="0"
              max="1"
              step="0.05"
              value={audioState.volume}
              onChange={handleVolumeChange}
              className="w-full accent-white h-1 rounded-lg bg-slate-800 cursor-pointer"
            />
            <span className="text-[10px] w-7 text-right">
              {Math.round(audioState.volume * 100)}%
            </span>
          </div>
        </div>
      )}

      {/* Main Floating Pill Button */}
      <div 
        onClick={() => {
          soundManager.playUiClick();
          setExpanded(!expanded);
        }}
        className="flex items-center gap-2.5 p-1.5 pr-3 rounded-full surface-pill border border-white/10 shadow-xl hover:border-white/20 cursor-pointer transition-all active:scale-98"
      >
        <button
          onClick={handleTogglePlay}
          className="w-7 h-7 rounded-full bg-white text-slate-950 flex items-center justify-center font-bold hover:bg-slate-200 transition-colors cursor-pointer"
        >
          {audioState.isPlaying ? (
            <Pause size={12} weight="fill" />
          ) : (
            <Play size={12} weight="fill" className="ml-0.5" />
          )}
        </button>

        <div className="flex flex-col text-left">
          <span className="text-[10px] font-semibold text-slate-200">
            {audioState.isPlaying ? 'OST PLAYING' : 'GAME OST'}
          </span>
          <span className="text-[9px] text-slate-500 truncate max-w-[110px]">
            {audioState.currentTrack.replace('.mp3', '')}
          </span>
        </div>

        {/* Subtle Waveform */}
        <div className="flex items-end gap-0.5 h-3 ml-0.5">
          <div className={`w-0.5 bg-slate-300 rounded-full transition-all duration-200 ${audioState.isPlaying ? 'h-3 animate-pulse' : 'h-1'}`} />
          <div className={`w-0.5 bg-slate-300 rounded-full transition-all duration-300 ${audioState.isPlaying ? 'h-2.5 animate-pulse delay-75' : 'h-1'}`} />
          <div className={`w-0.5 bg-slate-300 rounded-full transition-all duration-150 ${audioState.isPlaying ? 'h-3 animate-pulse delay-150' : 'h-1'}`} />
        </div>
      </div>

    </div>
  );
}
