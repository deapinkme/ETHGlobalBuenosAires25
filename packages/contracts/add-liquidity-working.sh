#!/bin/bash

source .env

~/.foundry/bin/forge script script/AddLiquidityWorking.s.sol:AddLiquidityWorking \
  --rpc-url https://mainnet.base.org \
  --private-key $PRIVATE_KEY \
  --broadcast \
  -vvv
