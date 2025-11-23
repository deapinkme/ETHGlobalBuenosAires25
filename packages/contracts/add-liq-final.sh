#!/bin/bash
source .env

~/.foundry/bin/forge script script/AddLiquidityFinal.s.sol:AddLiquidityFinal \
  --rpc-url https://mainnet.base.org \
  --private-key $PRIVATE_KEY \
  --broadcast \
  -vvv
