#!/bin/bash
source .env

~/.foundry/bin/forge script script/DeployCorrectPool.s.sol:DeployCorrectPool \
  --rpc-url https://mainnet.base.org \
  --private-key $PRIVATE_KEY \
  --broadcast \
  -vvv
