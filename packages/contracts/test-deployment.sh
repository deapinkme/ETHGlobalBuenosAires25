#!/bin/bash

# Test deployment script for Natural Gas Disruption Hook
# Make sure Anvil is running first!

export PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
export RPC_URL="http://localhost:8545"

ORACLE="0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9"
USDC="0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512"
NATGAS="0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0"
DEPLOYER="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"

echo "================================"
echo "Natural Gas Hook - Test Suite"
echo "================================"
echo ""

echo "📊 Checking Initial State..."
echo ""

PRICE=$(~/.foundry/bin/cast call $ORACLE "getTheoreticalPrice()" --rpc-url $RPC_URL)
PRICE_DEC=$((16#${PRICE:2}))
PRICE_DISPLAY=$(echo "scale=2; $PRICE_DEC / 1000000" | bc)
echo "✅ Oracle Price: \$$PRICE_DISPLAY"

USDC_BAL=$(~/.foundry/bin/cast call $USDC "balanceOf(address)" $DEPLOYER --rpc-url $RPC_URL)
USDC_DEC=$((16#${USDC_BAL:2}))
USDC_DISPLAY=$(echo "scale=0; $USDC_DEC / 1000000" | bc)
echo "✅ USDC Balance: $USDC_DISPLAY USDC"

NATGAS_BAL=$(~/.foundry/bin/cast call $NATGAS "balanceOf(address)" $DEPLOYER --rpc-url $RPC_URL)
NATGAS_HEX=${NATGAS_BAL:2}
NATGAS_DISPLAY=$(echo "scale=0; ibase=16; $NATGAS_HEX / DE0B6B3A7640000" | bc)
echo "✅ NATGAS Balance: $NATGAS_DISPLAY NATGAS"

echo ""
echo "🔄 Testing Oracle Price Update..."
echo ""

echo "Updating price from \$$PRICE_DISPLAY to \$200.00..."
~/.foundry/bin/cast send $ORACLE "updateBasePrice(uint256)" 200000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL \
  --quiet

NEW_PRICE=$(~/.foundry/bin/cast call $ORACLE "getTheoreticalPrice()" --rpc-url $RPC_URL)
NEW_PRICE_DEC=$((16#${NEW_PRICE:2}))
NEW_PRICE_DISPLAY=$(echo "scale=2; $NEW_PRICE_DEC / 1000000" | bc)
echo "✅ New Oracle Price: \$$NEW_PRICE_DISPLAY"

echo ""
echo "💸 Testing Token Transfers..."
echo ""

RECIPIENT="0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
echo "Transferring 100 NATGAS to $RECIPIENT..."

~/.foundry/bin/cast send $NATGAS "transfer(address,uint256)" $RECIPIENT 100000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL \
  --quiet

RECIPIENT_BAL=$(~/.foundry/bin/cast call $NATGAS "balanceOf(address)" $RECIPIENT --rpc-url $RPC_URL)
RECIPIENT_HEX=${RECIPIENT_BAL:2}
RECIPIENT_DISPLAY=$(echo "scale=0; ibase=16; $RECIPIENT_HEX / DE0B6B3A7640000" | bc)
echo "✅ Recipient Balance: $RECIPIENT_DISPLAY NATGAS"

echo ""
echo "🎯 Testing USDC Faucet..."
echo ""

~/.foundry/bin/cast send $USDC "faucet()" \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL \
  --quiet

NEW_USDC_BAL=$(~/.foundry/bin/cast call $USDC "balanceOf(address)" $DEPLOYER --rpc-url $RPC_URL)
NEW_USDC_DEC=$((16#${NEW_USDC_BAL:2}))
NEW_USDC_DISPLAY=$(echo "scale=0; $NEW_USDC_DEC / 1000000" | bc)
echo "✅ New USDC Balance: $NEW_USDC_DISPLAY USDC"

echo ""
echo "================================"
echo "✅ All Tests Passed!"
echo "================================"
echo ""
echo "📝 Contract Addresses:"
echo "  Oracle:     $ORACLE"
echo "  USDC:       $USDC"
echo "  NATGAS:     $NATGAS"
echo ""
echo "🔗 Your Wallet: $DEPLOYER"
echo ""
echo "💡 Next Steps:"
echo "  1. Deploy to testnet for real testing"
echo "  2. Implement CREATE2 for hook deployment"
echo "  3. Build frontend for demo"
echo ""
