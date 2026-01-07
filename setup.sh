#!/bin/bash
# Wu Ledger — Ignite v29+ Compatible Setup
# GitHub Codespaces Safe Version

set -e

cd "$(dirname "$0")"

echo ">>> [0/5] Preparing Environment..."
rm -rf wu-ledger

echo ">>> [1/5] Installing Ignite CLI..."
curl https://get.ignite.com/cli! | bash

echo ">>> [2/5] Scaffolding Chain..."
ignite scaffold chain wu-ledger \
  --address-prefix ogc

cd wu-ledger

echo ">>> [3/5] Writing config.yml with explicit chain-id..."
cat <<EOF > config.yml
version: 1

accounts:
  - name: alice
    coins: ["1000000000000000uogc"]
  - name: bob
    coins: ["1000000uogc"]

validators:
  - name: alice
    bonded: "1000000000000000uogc"

genesis:
  chain_id: "ogc-ledger-1"

client:
  openapi:
    path: docs/static/openapi.yml
EOF

echo ">>> [4/5] Scaffolding market module..."
ignite scaffold module market --dep bank

ignite scaffold single pool \
  reserveOgc:uint \
  reserveQuote:uint \
  --module market \
  --no-message

ignite scaffold message swap \
  amount:uint \
  isBuyOgc:bool \
  --module market \
  --response amountOut:uint

echo ">>> [5/5] Setup complete."
echo "Run: ignite chain serve"
