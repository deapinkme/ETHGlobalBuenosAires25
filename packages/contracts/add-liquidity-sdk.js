// Add liquidity using Uniswap V4 SDK
// Run: node add-liquidity-sdk.js

import { createWalletClient, http, parseUnits } from 'viem';
import { base } from 'viem/chains';
import { privateKeyToAccount } from 'viem/accounts';

const POSITION_MANAGER = '0x7c5f5a4bbd8fd63184577525326123b519429bdc';
const POOL_MANAGER = '0x498581fF718922c3f8e6A244956aF099B2652b2b';
const NATGAS = '0x4aA1dF02688241e4c665D4837a7c201CddF9F3CD';
const USDC = '0xbB9d7298273dFEbe2706aafb06d7f1c10E8B356a';
const HOOK = '0xC3CEe78d0825b24C684355de4e6FbD51F0b940c0';

const account = privateKeyToAccount(process.env.PRIVATE_KEY);
const client = createWalletClient({
  account,
  chain: base,
  transport: http('https://mainnet.base.org'),
});

async function addLiquidity() {
  console.log('Step 1: Approve NATGAS to PositionManager');
  const natgasHash = await client.writeContract({
    address: NATGAS,
    abi: [{
      name: 'approve',
      type: 'function',
      stateMutability: 'nonpayable',
      inputs: [
        { name: 'spender', type: 'address' },
        { name: 'amount', type: 'uint256' }
      ],
      outputs: [{ name: '', type: 'bool' }]
    }],
    functionName: 'approve',
    args: [POSITION_MANAGER, parseUnits('10000', 18)],
  });
  console.log(`NATGAS approval tx: ${natgasHash}`);

  console.log('\nStep 2: Approve USDC to PositionManager');
  const usdcHash = await client.writeContract({
    address: USDC,
    abi: [{
      name: 'approve',
      type: 'function',
      stateMutability: 'nonpayable',
      inputs: [
        { name: 'spender', type: 'address' },
        { name: 'amount', type: 'uint256' }
      ],
      outputs: [{ name: '', type: 'bool' }]
    }],
    functionName: 'approve',
    args: [POSITION_MANAGER, parseUnits('10000', 6)],
  });
  console.log(`USDC approval tx: ${usdcHash}`);

  console.log('\nStep 3: Mint position via PositionManager');
  console.log('NOTE: You need to use the @uniswap/v4-sdk to calculate proper parameters');
  console.log('See: https://docs.uniswap.org/sdk/v4/guides/liquidity/position-minting');

  // The PositionManager.mint() call requires:
  // - PoolKey (currency0, currency1, fee, tickSpacing, hooks)
  // - tickLower / tickUpper (price range)
  // - liquidity amount (calculated by SDK)
  // - recipient address
  // - hookData
}

addLiquidity().catch(console.error);
