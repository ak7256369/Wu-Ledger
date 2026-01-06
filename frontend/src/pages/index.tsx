import Head from 'next/head';
import MarketActivity from '../components/MarketActivity';
import LedgerActivity from '../components/LedgerActivity';
import NetworkStatus from '../components/NetworkStatus';
import { ExternalLink } from 'lucide-react';

export default function Home() {
    return (
        <div className="min-h-screen bg-background text-foreground antialiased selection:bg-primary/20">
            <Head>
                <title>Wu Ledger | Sovereign Cosmos Layer-1</title>
                <meta name="description" content="Safe, Minimal, Sovereign Ledger" />
            </Head>

            <main className="container mx-auto px-4 py-12 max-w-5xl">
                {/* Header */}
                <header className="mb-16 text-center space-y-4">
                    <h1 className="text-4xl md:text-6xl font-bold tracking-tighter bg-clip-text text-transparent bg-gradient-to-r from-blue-400 via-primary to-purple-400 animate-pulse">
                        Wu Ledger
                    </h1>
                    <p className="text-slate-400 text-lg max-w-2xl mx-auto">
                        Sovereign Cosmos Layer-1 (Doctrine-Compliant)
                    </p>
                </header>

                {/* Grid Layout */}
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-12">

                    {/* Market Activity Section */}
                    <div className="glass-panel rounded-2xl p-6 md:col-span-2">
                        <h2 className="text-xl font-semibold mb-2 flex items-center gap-2 text-primary">
                            WU Market Activity
                        </h2>
                        <p className="text-sm text-slate-400 mb-6">
                            Market data shown below reflects observed on-chain transactions.
                            Wu Ledger does not set, guarantee, or interpret price.
                        </p>
                        <MarketActivity />
                    </div>

                    {/* Ledger Activity Section */}
                    <div className="glass-panel rounded-2xl p-6 h-[400px] overflow-hidden flex flex-col">
                        <h2 className="text-xl font-semibold mb-2 text-blue-400">
                            Ledger Activity
                        </h2>
                        <p className="text-sm text-slate-400 mb-6">
                            Below is a live view of finalized transfers on Wu Ledger.
                            All transfers shown here are final and irreversible.
                        </p>
                        <LedgerActivity />
                    </div>

                    {/* Network Status Section */}
                    <div className="space-y-6">
                        <div className="glass-panel rounded-2xl p-6">
                            <h2 className="text-xl font-semibold mb-2 text-green-400">
                                Network Status
                            </h2>
                            <p className="text-sm text-slate-400 mb-6">
                                Wu Ledger finalizes state through a fixed validator set.
                            </p>
                            <NetworkStatus />
                        </div>

                        {/* Acquire Guidance Section */}
                        <div className="glass-panel rounded-2xl p-6 relative overflow-hidden group">
                            <div className="absolute inset-0 bg-gradient-to-br from-primary/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity" />
                            <h2 className="text-xl font-semibold mb-2">Acquire OGC</h2>
                            <p className="text-xs text-yellow-500/80 mb-4 font-mono border border-yellow-500/20 bg-yellow-500/5 p-2 rounded">
                                Wu Ledger does not custody funds or execute transactions.
                                To acquire OGC, use a supported Cosmos wallet and interact directly with the network.
                            </p>

                            <ol className="list-decimal list-inside text-sm text-slate-300 space-y-2 mb-6 ml-1">
                                <li>Install a Cosmos wallet (e.g., Keplr)</li>
                                <li>Acquire the supported quote asset</li>
                                <li>Swap for OGC using your wallet</li>
                            </ol>

                            <div className="flex gap-3">
                                <a href="https://www.keplr.app/" target="_blank" rel="noreferrer"
                                    className="flex items-center gap-2 px-4 py-2 bg-slate-800 hover:bg-slate-700 rounded-lg text-sm transition-colors border border-slate-700">
                                    Install Keplr <ExternalLink size={14} />
                                </a>
                            </div>
                        </div>
                    </div>

                </div>

                {/* Footer */}
                <footer className="text-center text-xs text-slate-600 border-t border-slate-800 pt-8 mt-12">
                    <p>OGC Ledger does not provide investment advice, custody services, or price guarantees.</p>
                </footer>
            </main>
        </div>
    );
}
