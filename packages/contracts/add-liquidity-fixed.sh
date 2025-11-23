#!/bin/bash

source .env

~/.foundry/bin/forge script script/AddLiquidityFixed.s.sol:AddLiquidityFixed \
  --rpc-url https://mainnet.base.org \
  --private-key $PRIVATE_KEY \
  --broadcast \
  -vvvv
