import { useState, useEffect } from 'react';
import { TrendingUp, Activity } from 'lucide-react';

export default function MarketActivity() {
    // Use null to represent "No active market" state initially or on error
    const [data, setData] = useState<{ price: string; volume: string; time: string } | null>(null);

    useEffect(() => {
        // In a real implementation, fetch from REST API here.
        // ensure "No active market" is the default or fallback
        // For demo purposes in valid state:
        // setData({ price: "1.05 USDC", volume: "45,230 OGC", time: "2 mins ago" });
    }, []);

    if (!data) {
        return (
            <div className="flex flex-col items-center justify-center p-12 border border-dashed border-slate-800 rounded-xl bg-slate-900/50">
                <Activity className="text-slate-600 mb-2 w-8 h-8 opacity-50" />
                <span className="text-slate-500 font-mono text-lg">No active market</span>
            </div>
        );
    }

    return (
        <div className="flex flex-wrap gap-8 items-end">
            <div>
                <div className="text-sm text-slate-500 uppercase tracking-wider mb-1">Last Trade</div>
                <div className="text-4xl font-mono font-bold text-white glow-text">{data.price}</div>
            </div>
            <div>
                <div className="text-sm text-slate-500 uppercase tracking-wider mb-1">24h Vol</div>
                <div className="text-2xl font-mono text-slate-300">{data.volume}</div>
            </div>
            <div className="ml-auto text-right">
                <div className="flex items-center gap-2 text-green-400 text-sm bg-green-900/20 px-3 py-1 rounded-full border border-green-900/30">
                    <TrendingUp size={14} /> Live
                </div>
                <div className="text-xs text-slate-500 mt-2">Update: {data.time}</div>
            </div>
        </div>
    );
}
