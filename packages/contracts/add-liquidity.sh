#!/bin/bash

source .env

NATGAS=0x4aA1dF02688241e4c665D4837a7c201CddF9F3CD
USDC=0xbB9d7298273dFEbe2706aafb06d7f1c10E8B356a
POSITION_MANAGER=0x4b2c77d209d3405f41a037ec6c77f7f5b8e2ca80

# Approve tokens to PositionManager
echo "Approving NATGAS to PositionManager..."
~/.foundry/bin/cast send $NATGAS \
  "approve(address,uint256)" \
  $POSITION_MANAGER \
  100000000000000000000000 \
  --rpc-url https://mainnet.base.org \
  --private-key $PRIVATE_KEY

echo "Approving MockUSDC to PositionManager..."
~/.foundry/bin/cast send $USDC \
  "approve(address,uint256)" \
  $POSITION_MANAGER \
  100000000000 \
  --rpc-url https://mainnet.base.org \
  --private-key $PRIVATE_KEY

echo "✅ Token approvals complete!"
echo ""
echo "Liquidity amounts:"
echo "  NATGAS: 10,000 tokens (10000000000000000000000 wei)"
echo "  MockUSDC: 10,000 tokens (10000000000 - 6 decimals)"
echo ""
echo "Next: Use frontend or V4 SDK to add liquidity via PositionManager"
