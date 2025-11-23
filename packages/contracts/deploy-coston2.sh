#!/bin/bash

set -e

echo "╔══════════════════════════════════════════════════════════╗"
echo "║   Deploying DisruptionOracle to Coston2 Testnet         ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

if [ ! -f .env ]; then
    echo "❌ Error: .env file not found"
    echo "   Copy .env.example to .env and fill in your values"
    exit 1
fi

source .env

if [ -z "$PRIVATE_KEY" ]; then
    echo "❌ Error: PRIVATE_KEY not set in .env"
    exit 1
fi

if [ -z "$COSTON2_RPC" ]; then
    echo "❌ Error: COSTON2_RPC not set in .env"
    exit 1
fi

echo "🚀 Deploying DisruptionOracle..."
echo ""

forge script script/DeployCoston2.s.sol:DeployCoston2 \
  --rpc-url $COSTON2_RPC \
  --broadcast \
  --legacy

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📝 Next steps:"
echo "   1. Copy the deployed address to .env as DISRUPTION_ORACLE_ADDRESS"
echo "   2. Verify contract on Coston2 explorer: https://coston2-explorer.flare.network/"
echo "   3. Test manual update: ./update-oracle-price.sh"
echo "   4. Set up FDC integration: see FDC_QUICKSTART.md"
echo ""
