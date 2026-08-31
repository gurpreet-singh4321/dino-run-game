import React, { useState, useEffect, useRef } from 'react';
import { soundManager } from '../utils/soundManager';

interface RiveDinoProps {
  className?: string;
}

export default function RiveDino({ className = "w-24 h-24" }: RiveDinoProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const riveInstanceRef = useRef<any>(null);
  const [isJumping, setIsJumping] = useState(false);
  const [riveLoaded, setRiveLoaded] = useState(false);

  useEffect(() => {
    let isMounted = true;

    // Load Rive on client-side safely
    const initRive = async () => {
      try {
        const riveModule = await import('@rive-app/canvas');
        const Rive = riveModule.Rive || (riveModule as any).default?.Rive;

        if (canvasRef.current && Rive) {
          const r = new Rive({
            src: '/assets/dino.riv',
            canvas: canvasRef.current,
            autoplay: true,
            animations: ['Motion'],
            layout: new (riveModule.Layout || (riveModule as any).default?.Layout)({
              fit: (riveModule.Fit || (riveModule as any).default?.Fit)?.Contain,
              alignment: (riveModule.Alignment || (riveModule as any).default?.Alignment)?.Center,
            }),
            onLoad: () => {
              if (isMounted) {
                setRiveLoaded(true);
              }
            },
            onLoadError: (err: any) => {
              console.warn('Rive canvas load error:', err);
            }
          });
          riveInstanceRef.current = r;
        }
      } catch (err) {
        console.warn('Rive import error:', err);
      }
    };

    initRive();

    return () => {
      isMounted = false;
      if (riveInstanceRef.current) {
        try {
          riveInstanceRef.current.cleanup();
        } catch (e) {}
      }
    };
  }, []);

  const handleTriggerJump = () => {
    soundManager.playJumpSfx();
    setIsJumping(true);
    setTimeout(() => {
      setIsJumping(false);
    }, 450);
  };

  return (
    <div 
      onClick={handleTriggerJump}
      className={`relative cursor-pointer transition-transform duration-200 ${isJumping ? '-translate-y-8 scale-110' : ''} ${className}`}
      title="Click Dino to trigger Jump!"
    >
      <canvas 
        ref={canvasRef}
        className={`w-full h-full object-contain ${riveLoaded ? 'opacity-100' : 'opacity-0'} transition-opacity duration-300`}
      />
      {!riveLoaded && (
        <img 
          src="/assets/dino_sprite.png" 
          alt="Dino Rex Sprite" 
          className="absolute inset-0 w-full h-full object-contain pixelated drop-shadow-[0_4px_12px_rgba(245,158,11,0.4)]"
          width="96"
          height="96"
        />
      )}
    </div>
  );
}
