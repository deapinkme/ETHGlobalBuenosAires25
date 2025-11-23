#!/bin/bash

source .env

~/.foundry/bin/forge script script/AddLiquidityMainnet.s.sol:AddLiquidityMainnet \
  --rpc-url https://mainnet.base.org \
  --private-key $PRIVATE_KEY \
  --broadcast
