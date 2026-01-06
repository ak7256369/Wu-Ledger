import { Circle } from 'lucide-react';

export default function NetworkStatus() {
    const isOperational = true; // Would fetch from /status

    return (
        <div className="space-y-4">
            <div className="flex items-center justify-between">
                <span className="text-slate-400">Status</span>
                <div className={`flex items-center gap-2 px-3 py-1 rounded-md text-sm font-medium border ${isOperational ? 'bg-emerald-950/30 text-emerald-400 border-emerald-900/50' : 'bg-red-950/30 text-red-400 border-red-900/50'}`}>
                    <Circle size={8} fill="currentColor" className={isOperational ? "animate-pulse" : ""} />
                    {isOperational ? "Operational" : "Halted"}
                </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
                <div className="bg-white/5 p-3 rounded-lg border border-white/5">
                    <span className="text-xs text-slate-500 uppercase">Block Height</span>
                    <div className="text-xl font-mono text-white mt-1">8,992,103</div>
                </div>
                <div className="bg-white/5 p-3 rounded-lg border border-white/5">
                    <span className="text-xs text-slate-500 uppercase">Validator Set</span>
                    <div className="text-xl font-mono text-white mt-1">3 <span className="text-xs text-slate-500 font-sans">/ Fixed</span></div>
                </div>
            </div>
        </div>
    );
}
