#!/bin/bash

source .env

~/.foundry/bin/forge script script/MintPosition.s.sol:MintPosition \
  --rpc-url https://mainnet.base.org \
  --private-key $PRIVATE_KEY \
  --broadcast \
  -vvv
