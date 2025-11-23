#!/bin/bash

source .env

~/.foundry/bin/forge script script/DeployAndAddLiquidity.s.sol:DeployAndAddLiquidity \
  --rpc-url https://mainnet.base.org \
  --private-key $PRIVATE_KEY \
  --broadcast
