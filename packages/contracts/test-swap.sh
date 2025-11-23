#!/bin/bash
source .env

~/.foundry/bin/forge script script/TestSwap.s.sol:TestSwap \
  --rpc-url https://mainnet.base.org \
  --private-key $PRIVATE_KEY \
  --broadcast \
  -vvv
