#!/bin/bash
source .env

~/.foundry/bin/forge script script/FixPoolPrice.s.sol:FixPoolPrice \
  --rpc-url https://mainnet.base.org \
  --private-key $PRIVATE_KEY \
  --broadcast \
  -vvv
