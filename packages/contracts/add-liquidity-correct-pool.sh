#!/bin/bash
source .env

~/.foundry/bin/forge script script/AddLiquidityCorrectPool.s.sol:AddLiquidityCorrectPool \
  --rpc-url https://mainnet.base.org \
  --private-key $PRIVATE_KEY \
  --broadcast \
  -vvv
