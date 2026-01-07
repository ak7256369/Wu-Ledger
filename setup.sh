#!/bin/bash
# Fixed ignite flags for compatibility with v29+

# Wu Ledger - SAFE & MINIMAL
# Setup Script for GitHub Codespaces
# Doctrine: "Safety over features. Speed achieved by removing complexity."

set -e

# Ensure we are in the script's directory
cd "$(dirname "$0")"

echo ">>> [0/5] Preparing Environment..."
# Cleanup previous run
rm -rf chain

echo ">>> [1/5] Installing Ignite CLI..."
curl https://get.ignite.com/cli! | bash

echo ">>> [2/5] Scaffolding Chain 'ogc-ledger-1'..."
# FIX: Scaffolding to directory 'chain' to avoid name conflicts with parent 'Wu-Ledger'
# FIX: Using explicit module path
# Force update
ignite scaffold chain wu-ledger --address-prefix ogc --chain-id ogc-ledger-1-address-prefix ogc --module github.com/wuledger/ogc-ledger-1

cd chain

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
ignite scaffold module market --dep bank

# Scaffold a Singleton Pool (One pool for the whole chain)
# Fields: reserveOgc (uint), reserveQuote (uint) -> uint64 (Safe for < 18 quintillion)
ignite scaffold single pool reserveOgc:uint reserveQuote:uint --module market --no-message

# Scaffold the Swap Message
ignite scaffold message swap amount:uint isBuyOgc:bool --module market --response amountOut:uint

echo ">>> [4/5] Applying Doctrine & AMM Logic..."

# 4.1 Define Pool Methods (Extension)
# We extend the Ignite-generated 'Pool' struct (defined in pool.pb.go)
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

# 4.2 AMM Logic (Keeper)
cat <<EOF > x/market/keeper/amm.go
package keeper

import (
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/wuledger/ogc-ledger-1/x/market/types"
)

// CalculateSwapOutput calculates dy = (y * dx) / (x + dx)
// No fees are applied.
func (k Keeper) CalculateSwapOutput(ctx sdk.Context, pool types.Pool, amountInUint uint64, isBuyOgc bool) (amountOutUint uint64, err error) {
	// Convert to sdk.Int for safe math
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

# 4.3 Wire up MsgSwap Handler
# We inject the logic to call our AMM calculation and update the pool.
# Note: Bank transfers are omitted for simplicity doctrine (simulated swap).
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

	// 1. Get the Pool
	pool, found := k.GetPool(ctx)
	if !found {
		return nil, fmt.Errorf("pool not found")
	}

	// 2. Calculate Output
	amountOut, err := k.CalculateSwapOutput(ctx, pool, msg.Amount, msg.IsBuyOgc)
	if err != nil {
		return nil, err
	}

	// 3. Update Pool Reserves (In Memory)
    // Checks for safe bounds are implicit in logic (uint cannot be negative)
	if msg.IsBuyOgc {
		// User gives Quote (Amount), Gets OGC (AmountOut)
		pool.ReserveQuote += msg.Amount
        if pool.ReserveOgc < amountOut {
            return nil, fmt.Errorf("insufficient liquidity")
        }
		pool.ReserveOgc -= amountOut
	} else {
		// User gives OGC (Amount), Gets Quote (AmountOut)
		pool.ReserveOgc += msg.Amount
        if pool.ReserveQuote < amountOut {
             return nil, fmt.Errorf("insufficient liquidity")
        }
		pool.ReserveQuote -= amountOut
	}
    
	// 4. Save Pool
	k.SetPool(ctx, pool)
    
	return &types.MsgSwapResponse{AmountOut: amountOut}, nil
}
EOF

echo ">>> [5/5] Setup Complete. Run 'ignite chain serve' to start."
