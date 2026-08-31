import React, { useState } from 'react';
import { PaperPlaneRight, Envelope } from '@phosphor-icons/react';
import { soundManager } from '../utils/soundManager';

export default function FeedbackForm() {
  const [feedback, setFeedback] = useState('');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    soundManager.playUiClick();
    
    if (!feedback.trim()) return;

    // Google Webmail Compose URL
    const subject = encodeURIComponent('Feedback for Dino Run Epochs');
    const body = encodeURIComponent(`Hi Dino Run Team,\n\nHere is my feedback:\n\n${feedback}`);
    const gmailUrl = `https://mail.google.com/mail/?view=cm&fs=1&to=dinorunepochs@gmail.com&su=${subject}&body=${body}`;
    
    // Open in new tab
    window.open(gmailUrl, '_blank');
    setFeedback('');
  };

  return (
    <section className="w-full py-10 px-4 md:px-8 max-w-[800px] mx-auto" id="contact">
      <div className="surface-card rounded-2xl p-6 md:p-8 flex flex-col items-center border border-white/10 relative overflow-hidden text-center">
        
        <div className="inline-flex items-center gap-2 mb-3">
          <Envelope size={24} className="text-emerald-400" />
          <h3 className="text-xl font-bold tracking-tight text-white font-['Chakra_Petch'] uppercase">
            Contact & Feedback
          </h3>
        </div>

        <p className="text-slate-400 text-sm max-w-[45ch] mb-6 leading-relaxed">
          Found a bug or have a suggestion? We'd love to hear from you. Submitting will securely open your Gmail with the details.
        </p>

        <form onSubmit={handleSubmit} className="w-full flex flex-col gap-3">
          <textarea
            value={feedback}
            onChange={(e) => setFeedback(e.target.value)}
            placeholder="Type your feedback here..."
            required
            rows={4}
            className="w-full bg-slate-900/50 border border-white/10 rounded-xl p-4 text-sm text-white placeholder-slate-500 focus:outline-none focus:border-emerald-500/50 transition-colors resize-none"
          />
          <button 
            type="submit"
            className="inline-flex items-center justify-center gap-2 h-11 px-6 rounded-xl bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 font-['Geist_Mono'] font-bold text-sm tracking-wider hover:bg-emerald-500/20 active:scale-98 transition-all shadow-lg cursor-pointer w-full sm:w-auto self-center"
          >
            <PaperPlaneRight weight="fill" size={16} />
            <span>Send via Gmail</span>
          </button>
        </form>

        <div className="mt-4 text-xs text-slate-500 font-['Geist_Mono']">
          Or email us directly at <a href="mailto:dinorunepochs@gmail.com" className="text-emerald-400 hover:underline">dinorunepochs@gmail.com</a>
        </div>
      </div>
    </section>
  );
}
