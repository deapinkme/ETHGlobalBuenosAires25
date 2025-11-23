#!/bin/bash
source .env

~/.foundry/bin/forge script script/AddProperLiquidity.s.sol:AddProperLiquidity \
  --rpc-url https://mainnet.base.org \
  --private-key $PRIVATE_KEY \
  --broadcast \
  -vvv
