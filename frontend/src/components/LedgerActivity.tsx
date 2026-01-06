import { ArrowRight } from 'lucide-react';

const MOCK_API_DATA = [
    { from: 'ogc...39s', to: 'ogc...2x9', amount: '1,000 OGC', height: '8,992,102', time: '10s ago' },
    { from: 'ogc...1a4', to: 'ogc...88q', amount: '500 OGC', height: '8,992,101', time: '22s ago' },
    { from: 'ogc...9cc', to: 'ogc...k22', amount: '12,500 OGC', height: '8,992,098', time: '1m ago' },
];

export default function LedgerActivity() {
    return (
        <div className="overflow-y-auto pr-2 mt-2 space-y-3 flex-1 custom-scrollbar">
            {MOCK_API_DATA.map((tx, i) => (
                <div key={i} className="flex items-center justify-between p-3 rounded-lg bg-white/5 border border-white/5 hover:bg-white/10 transition-colors">
                    <div className="flex flex-col gap-1">
                        <div className="flex items-center gap-2 text-xs font-mono text-slate-300">
                            <span className="opacity-70">{tx.from}</span>
                            <ArrowRight size={10} className="text-slate-500" />
                            <span className="opacity-70">{tx.to}</span>
                        </div>
                        <div className="text-xs text-slate-500">Block {tx.height} • {tx.time}</div>
                    </div>
                    <div className="text-sm font-mono font-medium text-blue-300">
                        {tx.amount}
                    </div>
                </div>
            ))}
        </div>
    );
}
