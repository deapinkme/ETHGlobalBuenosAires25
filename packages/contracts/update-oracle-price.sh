#!/bin/bash

set -e

echo "╔══════════════════════════════════════════════════════════╗"
echo "║   Updating DisruptionOracle Price                       ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

if [ ! -f .env ]; then
    echo "❌ Error: .env file not found"
    exit 1
fi

source .env

if [ -z "$DISRUPTION_ORACLE_ADDRESS" ]; then
    echo "❌ Error: DISRUPTION_ORACLE_ADDRESS not set in .env"
    echo "   Deploy the oracle first using: ./deploy-coston2.sh"
    exit 1
fi

if [ -z "$NEW_PRICE" ]; then
    echo "❌ Error: NEW_PRICE not set in .env"
    echo "   Set NEW_PRICE in .env (e.g., 3930000 for $3.93)"
    exit 1
fi

if [ -z "$PRIVATE_KEY" ]; then
    echo "❌ Error: PRIVATE_KEY not set in .env"
    exit 1
fi

echo "📊 Current Configuration:"
echo "   Oracle Address: $DISRUPTION_ORACLE_ADDRESS"
echo "   New Price:      $NEW_PRICE"
echo "   RPC:            $COSTON2_RPC"
echo ""

read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

echo ""
echo "🔄 Updating price..."
echo ""

forge script script/UpdateOraclePrice.s.sol:UpdateOraclePrice \
  --rpc-url $COSTON2_RPC \
  --broadcast \
  --legacy

echo ""
echo "✅ Price update complete!"
echo ""
echo "📝 Verify on Coston2 explorer:"
echo "   https://coston2-explorer.flare.network/address/$DISRUPTION_ORACLE_ADDRESS"
echo ""
