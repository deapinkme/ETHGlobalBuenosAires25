#!/bin/bash
source .env

~/.foundry/bin/forge script script/DeploySwapRouter.s.sol:DeploySwapRouter \
  --rpc-url https://mainnet.base.org \
  --private-key $PRIVATE_KEY \
  --broadcast \
  -vvv
