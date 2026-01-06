#!/bin/bash

# Wu Ledger - SAFE & MINIMAL
# Setup Script for GitHub Codespaces
# Doctrine: "Safety over features. Speed achieved by removing complexity."

set -e

echo ">>> [1/5] Installing Ignite CLI..."
curl https://get.ignite.com/cli! | bash

echo ">>> [2/5] Scaffolding Chain 'ogc-ledger-1'..."
# Scaffold chain with no default module to keep it clean, we will add market later
ignite scaffold chain wuledger --no-module --address-prefix ogc
cd wuledger

echo ">>> [2.5/5] Configuring Chain ID and Genesis..."
cat <<EOF > config.yml
version: 1
build:
  proto:
    path: proto
    third_party_paths:
    - third_party/proto
    - proto_vendor
accounts:
  - name: alice
    coins: ["1000000000000000uogc"] # 1 Billion OGC (6 decimals)
  - name: bob
    coins: ["1000000uogc"]
validators:
  - name: alice
    bonded: "1000000000000000uogc"
client:
  vue:
    path: vue
  openapi:
    path: docs/static/openapi.yml
genesis:
  chain_id: "ogc-ledger-1"
EOF

echo ">>> [3/5] Scaffolding 'market' Module (AMM)..."
# The market module depends on 'bank' for handling tokens
ignite scaffold module market --dep bank

echo ">>> [4/5] Applying Doctrine & AMM Logic..."

# 4.1 Define Constants (Types)
# We overwrite the types to include our specific Pool struct
cat <<EOF > x/market/types/pool.go
package types

import (
	sdk "github.com/cosmos/cosmos-sdk/types"
)

// Pool defines the single AMM pool 
// Doctrine: One pool (OGC/QUOTE), No fees, x*y=k
type Pool struct {
	ReserveOgc   sdk.Int
	ReserveQuote sdk.Int
}

func NewPool(ogc, quote sdk.Int) Pool {
	return Pool{
		ReserveOgc:   ogc,
		ReserveQuote: quote,
	}
}

// GetPrice returns Quote per OGC (y / x)
func (p Pool) GetPrice() sdk.Dec {
	if p.ReserveOgc.IsZero() {
		return sdk.ZeroDec()
	}
	return p.ReserveQuote.ToDec().Quo(p.ReserveOgc.ToDec())
}

// GetConstantProduct returns k = x * y
func (p Pool) GetConstantProduct() sdk.Int {
	return p.ReserveOgc.Mul(p.ReserveQuote)
}
EOF

# 4.2 AMM Logic (Keeper)
# Strict constant product, no fees
cat <<EOF > x/market/keeper/amm.go
package keeper

import (
	sdk "github.com/cosmos/cosmos-sdk/types"
	"wuledger/x/market/types"
)

// CalculateSwapOutput calculates dy = (y * dx) / (x + dx)
// No fees are applied.
func (k Keeper) CalculateSwapOutput(ctx sdk.Context, pool types.Pool, amountIn sdk.Int, isBuyOgc bool) (amountOut sdk.Int, err error) {
	// x = OGC, y = QUOTE
	// if Buy OGC: input is QUOTE (dy), output is OGC (dx)
	// (x - dx)(y + dy) = k = xy
	// xy + xdy - dxy - dxdy = xy
	// xdy = dx(y + dy)
	// dx = (x * dy) / (y + dy)
	
	var inputReserve, outputReserve sdk.Int
	
	if isBuyOgc {
		// Input QUOTE, Output OGC
		inputReserve = pool.ReserveQuote
		outputReserve = pool.ReserveOgc
	} else {
		// Input OGC, Output QUOTE
		inputReserve = pool.ReserveOgc
		outputReserve = pool.ReserveQuote
	}

	numerator := outputReserve.Mul(amountIn)
	denominator := inputReserve.Add(amountIn)
	
	amountOut = numerator.Quo(denominator)
	return amountOut, nil
}
EOF

# 4.3 Configure config.toml for fixed validator set (Basic simulation config)
# In a real genesis, we would manually edit genesis.json, but here we set defaults
# sed -i 's/stake/uogc/g' config.yml

echo ">>> [5/5] Setup Complete. Run 'ignite chain serve' to start."
