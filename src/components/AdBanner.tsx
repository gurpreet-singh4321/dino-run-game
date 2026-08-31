import React, { useEffect, useRef } from 'react';

interface AdBannerProps {
  slotId?: string;
  format?: 'leaderboard' | 'rectangle';
  className?: string;
}

export default function AdBanner({
  slotId = '8999529758',
  format = 'leaderboard',
  className = '',
}: AdBannerProps) {
  const adRef = useRef<HTMLModElement | null>(null);
  const pushedRef = useRef(false);

  useEffect(() => {
    if (typeof window === 'undefined' || pushedRef.current) return;

    try {
      const container = adRef.current;
      if (container && container.offsetWidth > 0) {
        ((window as any).adsbygoogle = (window as any).adsbygoogle || []).push({});
        pushedRef.current = true;
      }
    } catch (e) {
      console.warn('AdSense notice:', e);
    }
  }, []);

  const config = {
    leaderboard: {
      wrapperClass: 'min-h-[90px] w-full max-w-[728px] md:max-w-[970px]',
      insStyle: { display: 'block', minHeight: '90px' },
      label: 'ADVERTISEMENT',
    },
    rectangle: {
      wrapperClass: 'min-h-[250px] w-full max-w-[300px] sm:max-w-[336px]',
      insStyle: { display: 'block', minHeight: '250px' },
      label: 'SPONSORED',
    },
  }[format];

  return (
    <div className={`flex flex-col items-center justify-center my-6 ${className}`}>
      {/* Discreet Compliance Label */}
      <span className="text-[9px] font-['Geist_Mono'] text-slate-500 uppercase tracking-wider mb-1">
        {config.label}
      </span>

      {/* Clean Slate Frame */}
      <div 
        className={`${config.wrapperClass} relative rounded-xl border border-white/8 overflow-hidden flex items-center justify-center bg-slate-950/60`}
      >
        <ins
          ref={adRef}
          className="adsbygoogle w-full"
          style={config.insStyle}
          data-ad-client="ca-pub-6461062896377292"
          data-ad-slot={slotId}
          data-ad-format="auto"
          data-full-width-responsive="true"
        />

        {/* Minimal Fallback when ad is pending */}
        <div 
          className="absolute inset-1 -z-10 rounded-lg border border-dashed border-white/5 flex flex-col items-center justify-center text-center p-2 pointer-events-none"
        >
          <p className="text-[10px] text-slate-500 font-['Geist_Mono']">
            Sponsored Partner Slot
          </p>
        </div>
      </div>
    </div>
  );
}
