import { useState, useEffect } from 'react';
import { TrendingUp, Activity } from 'lucide-react';

export default function MarketActivity() {
    // Use null to represent "No active market" state initially or on error
    const [data, setData] = useState<{ price: string; volume: string; time: string } | null>(null);

    useEffect(() => {
        // Determine URL based on environment (Codespaces vs Localhost)
        const getApiUrl = () => {
            if (typeof window !== 'undefined') {
                return `http://${window.location.hostname}:1317`;
            }
            return "http://localhost:1317";
        };

        const fetchData = async () => {
            try {
                const API_URL = getApiUrl();
                // Fetch valid pools. Setup.sh uses 'market' module and 'pool' type.
                // Standard Ignite REST path: /<org>/<repo>/<module>/<type>
                // Based on scaffolding: /wuledger/wuledger/market/pool
                const response = await fetch(`${API_URL}/wuledger/wuledger/market/pool`);

                if (!response.ok) {
                    // 404 means no pool created yet -> "No active market"
                    setData(null);
                    return;
                }

                const json = await response.json();

                // If pool exists but is empty (ignite might return {pool: {}} or {pool: null})
                // We access the singleton 'pool'
                const pool = json.pool;

                if (pool && pool.reserveOgc && pool.reserveQuote) {
                    // Basic formatting
                    const ogc = parseInt(pool.reserveOgc);
                    const quote = parseInt(pool.reserveQuote);

                    if (ogc === 0) {
                        setData(null);
                        return;
                    }

                    // Price = y / x
                    const priceVal = (quote / ogc).toFixed(4);

                    setData({
                        price: `${priceVal} QUOTE`,
                        volume: "N/A", // Volume requires block indexing, out of scope for basic MVP
                        time: "Live"
                    });
                } else {
                    setData(null);
                }
            } catch (error) {
                console.error("Failed to fetch market data", error);
                setData(null);
            }
        };

        fetchData();
        const interval = setInterval(fetchData, 5000); // Refresh every 5s
        return () => clearInterval(interval);
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
