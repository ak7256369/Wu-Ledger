#!/bin/bash
# Wu Ledger — Ignite v29+ Compatible Setup
# GitHub Codespaces Safe Version

set -e

cd "$(dirname "$0")"

echo ">>> [0/5] Preparing Environment..."
rm -rf wu-ledger

echo ">>> [1/5] Installing Ignite CLI..."
curl https://get.ignite.com/cli! | bash -s -- v28.5.0

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

# ==========================================
# CUSTOM LOGIC INJECTION (Restoring AMM Math)
# ==========================================

echo ">>> Injecting Custom AMM Logic..."

# 1. Define Pool Methods (x*y=k Helpers)
cat <<EOF > x/market/types/pool_gam.go
package types

import (
	sdk "github.com/cosmos/cosmos-sdk/types"
)

// Helper to convert uint64 reserves to sdk.Int for calculation
func (p Pool) GetReserveOgcInt() sdk.Int {
	return sdk.NewIntFromUint64(p.ReserveOgc)
}

func (p Pool) GetReserveQuoteInt() sdk.Int {
	return sdk.NewIntFromUint64(p.ReserveQuote)
}

// GetPrice returns Quote per OGC (y / x)
func (p Pool) GetPrice() sdk.Dec {
	x := p.GetReserveOgcInt()
	y := p.GetReserveQuoteInt()
	
	if x.IsZero() {
		return sdk.ZeroDec()
	}
	return y.ToDec().Quo(x.ToDec())
}

// GetConstantProduct returns k = x * y
func (p Pool) GetConstantProduct() sdk.Int {
	return p.GetReserveOgcInt().Mul(p.GetReserveQuoteInt())
}
EOF

# 2. AMM Math Logic (Keeper)
# Calculates: dy = (y * dx) / (x + dx)
cat <<EOF > x/market/keeper/amm.go
package keeper

import (
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/wuledger/ogc-ledger-1/x/market/types"
)

func (k Keeper) CalculateSwapOutput(ctx sdk.Context, pool types.Pool, amountInUint uint64, isBuyOgc bool) (amountOutUint uint64, err error) {
	amountIn := sdk.NewIntFromUint64(amountInUint)
	x := pool.GetReserveOgcInt()
	y := pool.GetReserveQuoteInt()
	
	var inputReserve, outputReserve sdk.Int
	
	if isBuyOgc {
		// Input QUOTE, Output OGC
		inputReserve = y
		outputReserve = x
	} else {
		// Input OGC, Output QUOTE
		inputReserve = x
		outputReserve = y
	}

	numerator := outputReserve.Mul(amountIn)
	denominator := inputReserve.Add(amountIn)
	amountOut := numerator.Quo(denominator)
	
	return amountOut.Uint64(), nil
}
EOF

# 3. Wire up MsgSwap Handler
# Updates the pool state based on the calculated output.
cat <<EOF > x/market/keeper/msg_server_swap.go
package keeper

import (
	"context"
	"fmt"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/wuledger/ogc-ledger-1/x/market/types"
)

func (k msgServer) Swap(goCtx context.Context, msg *types.MsgSwap) (*types.MsgSwapResponse, error) {
	ctx := sdk.UnwrapSDKContext(goCtx)

	pool, found := k.GetPool(ctx)
	if !found {
		return nil, fmt.Errorf("pool not found")
	}

	amountOut, err := k.CalculateSwapOutput(ctx, pool, msg.Amount, msg.IsBuyOgc)
	if err != nil {
		return nil, err
	}

	if msg.IsBuyOgc {
		pool.ReserveQuote += msg.Amount
		if pool.ReserveOgc < amountOut {
			return nil, fmt.Errorf("insufficient liquidity")
		}
		pool.ReserveOgc -= amountOut
	} else {
		pool.ReserveOgc += msg.Amount
		if pool.ReserveQuote < amountOut {
			return nil, fmt.Errorf("insufficient liquidity")
		}
		pool.ReserveQuote -= amountOut
	}
    
	k.SetPool(ctx, pool)
	return &types.MsgSwapResponse{AmountOut: amountOut}, nil
}
EOF

echo ">>> Logic Injected. Ready to Serve."

