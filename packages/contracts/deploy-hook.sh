#!/bin/bash

source .env

export POOL_MANAGER=0x498581ff718922c3f8e6a244956af099b2652b2b
export ORACLE=0xdC1e39e8B56c6a4d14f9526843D95C3471d735D5
export HOOK_SALT=0x00000000000000000000000000000000000000000000000000000000000009da

~/.foundry/bin/forge script script/DeployHookCREATE2.s.sol:DeployHookCREATE2 \
  --rpc-url https://mainnet.base.org \
  --private-key $PRIVATE_KEY \
  --broadcast
