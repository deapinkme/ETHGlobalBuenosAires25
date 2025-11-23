#!/bin/bash

source .env

~/.foundry/bin/forge script script/InitializePoolMainnet.s.sol:InitializePoolMainnet \
  --rpc-url https://mainnet.base.org \
  --private-key $PRIVATE_KEY \
  --broadcast
