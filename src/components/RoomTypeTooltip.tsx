import { useState, useRef, useEffect } from 'react';
import { Info, X } from 'lucide-react';

interface RoomTypeTooltipProps {
  roomType: string;
  description: string;
}

export function RoomTypeTooltip({ roomType, description }: RoomTypeTooltipProps) {
  const [showTooltip, setShowTooltip] = useState(false);
  const [position, setPosition] = useState({ top: 0, left: 0 });
  const triggerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (showTooltip && triggerRef.current) {
      const rect = triggerRef.current.getBoundingClientRect();
      const tooltipWidth = 320; // Fixed width for better control
      const tooltipHeight = 120; // Estimated height
      const padding = 8;
      
      let left = rect.left;
      let top = rect.bottom + padding;
      
      // Adjust horizontal position to prevent overflow
      if (left + tooltipWidth > window.innerWidth - padding) {
        left = window.innerWidth - tooltipWidth - padding;
      }
      if (left < padding) {
        left = padding;
      }
      
      // Adjust vertical position if tooltip would go below viewport
      if (top + tooltipHeight > window.innerHeight - padding) {
        top = rect.top - tooltipHeight - padding;
      }
      
      setPosition({ top, left });
    }
  }, [showTooltip]);

  const handleClick = (e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setShowTooltip(!showTooltip);
  };

  const handleOutsideClick = (e: MouseEvent) => {
    if (triggerRef.current && !triggerRef.current.contains(e.target as Node)) {
      setShowTooltip(false);
    }
  };

  useEffect(() => {
    if (showTooltip) {
      document.addEventListener('click', handleOutsideClick);
      return () => document.removeEventListener('click', handleOutsideClick);
    }
  }, [showTooltip]);

  return (
    <>
      <div 
        ref={triggerRef}
        className="relative inline-block"
        onMouseEnter={() => setShowTooltip(true)}
        onMouseLeave={() => setShowTooltip(false)}
        onClick={handleClick}
      >
        <span className="rounded-full bg-accent px-3 py-1 text-sm text-accent-foreground cursor-pointer hover:bg-accent/80 transition-colors flex items-center gap-1">
          {roomType}
          <Info className="h-3 w-3 opacity-60" />
        </span>
      </div>
      
      {showTooltip && (
        <div 
          className="fixed z-50 w-80 max-w-xs p-4 text-sm bg-card border rounded-lg shadow-xl backdrop-blur-sm"
          style={{ 
            top: `${position.top}px`, 
            left: `${position.left}px`,
            opacity: 0,
            animation: 'fadeIn 0.2s ease-in-out forwards'
          }}
        >
          <div className="flex items-start justify-between mb-2">
            <div className="font-semibold text-foreground text-base">{roomType}</div>
            <button
              onClick={(e) => {
                e.stopPropagation();
                setShowTooltip(false);
              }}
              className="text-muted-foreground hover:text-foreground transition-colors p-1 rounded hover:bg-accent"
            >
              <X className="h-4 w-4" />
            </button>
          </div>
          <div className="text-muted-foreground leading-relaxed text-sm">{description}</div>
          
          {/* Arrow pointing to trigger */}
          <div 
            className="absolute w-3 h-3 bg-card border-l border-t transform -rotate-45"
            style={{
              top: triggerRef.current ? `${triggerRef.current.getBoundingClientRect().bottom - position.top - 6}px` : '-6px',
              left: triggerRef.current ? `${Math.min(triggerRef.current.getBoundingClientRect().left - position.left + 16, 20)}px` : '16px'
            }}
          />
        </div>
      )}
      
      <style>{`
        @keyframes fadeIn {
          from { opacity: 0; transform: translateY(-4px); }
          to { opacity: 1; transform: translateY(0); }
        }
      `}</style>
    </>
  );
}
