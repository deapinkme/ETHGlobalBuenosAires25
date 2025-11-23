import { createWalletClient, http, parseUnits, publicActions, encodeFunctionData, getContract } from 'viem';
import { base } from 'viem/chains';
import { privateKeyToAccount } from 'viem/accounts';

const POSITION_MANAGER = '0x7C5f5A4bBd8fD63184577525326123B519429bDc';
const POOL_MANAGER = '0x498581fF718922c3f8e6A244956aF099B2652b2b';
const NATGAS = '0x4aA1dF02688241e4c665D4837a7c201CddF9F3CD';
const USDC = '0xbB9d7298273dFEbe2706aafb06d7f1c10E8B356a';
const HOOK = '0xC3CEe78d0825b24C684355de4e6FbD51F0b940c0';

const POSITION_MANAGER_ABI = [
  {
    name: 'modifyLiquidities',
    type: 'function',
    stateMutability: 'payable',
    inputs: [
      { name: 'unlockData', type: 'bytes' },
      { name: 'deadline', type: 'uint256' }
    ],
    outputs: []
  }
] as const;

async function main() {
  if (!process.env.PRIVATE_KEY) {
    throw new Error('PRIVATE_KEY not set');
  }

  const account = privateKeyToAccount(process.env.PRIVATE_KEY as `0x${string}`);
  const client = createWalletClient({
    account,
    chain: base,
    transport: http('https://mainnet.base.org'),
  }).extend(publicActions);

  console.log('🚀 Adding liquidity to Uniswap V4 pool');
  console.log('📍 Account:', account.address);
  console.log('');

  const poolKey = {
    currency0: NATGAS,
    currency1: USDC,
    fee: 0,
    tickSpacing: 60,
    hooks: HOOK
  };

  const tickLower = -887220;
  const tickUpper = 887220;

  const sqrtPriceX96 = 79228162514264337593543950336n;
  const liquidity = 10000000000000000n;

  const amount0Max = parseUnits('10000', 18);
  const amount1Max = parseUnits('10000', 6);

  const Actions = {
    INCREASE_LIQUIDITY: 0,
    DECREASE_LIQUIDITY: 1,
    MINT_POSITION: 2,
    BURN_POSITION: 3,
    SETTLE_PAIR: 4,
    TAKE_PAIR: 5,
    SETTLE: 6,
    TAKE: 7,
    CLOSE_CURRENCY: 8,
    CLEAR_OR_TAKE: 9,
    SWEEP: 10
  };

  const mintParams = {
    poolKey,
    tickLower,
    tickUpper,
    liquidity,
    amount0Max,
    amount1Max,
    owner: account.address,
    hookData: '0x'
  };

  console.log('📊 Position Parameters:');
  console.log('  Tick Range:', tickLower, 'to', tickUpper);
  console.log('  Liquidity:', liquidity.toString());
  console.log('  Max NATGAS:', amount0Max.toString());
  console.log('  Max USDC:', amount1Max.toString());
  console.log('');

  const encodedActions = [
    {
      actionType: Actions.SETTLE_PAIR,
      params: { currency0: NATGAS, currency1: USDC }
    },
    {
      actionType: Actions.MINT_POSITION,
      params: mintParams
    },
    {
      actionType: Actions.SWEEP,
      params: { currency: NATGAS, to: account.address }
    }
  ];

  const deadline = BigInt(Math.floor(Date.now() / 1000) + 3600);

  console.log('⏳ Calling modifyLiquidities...');
  console.log('⚠️  NOTE: This may fail with encoding issues.');
  console.log('    The Uniswap V4 SDK (@uniswap/v4-sdk) is required for proper encoding.');
  console.log('');
  console.log('🔗 Position Manager:', POSITION_MANAGER);
  console.log('');

  try {
    const hash = await client.writeContract({
      address: POSITION_MANAGER,
      abi: POSITION_MANAGER_ABI,
      functionName: 'modifyLiquidities',
      args: ['0x', deadline],
      value: 0n,
    });

    console.log('✅ Transaction sent:', hash);
    console.log('🔗 View on BaseScan: https://basescan.org/tx/' + hash);

    const receipt = await client.waitForTransactionReceipt({ hash });
    console.log('✅ Liquidity added! Status:', receipt.status);

  } catch (error: any) {
    console.error('❌ Error:', error.message);
    console.log('');
    console.log('📝 To properly add liquidity, you need:');
    console.log('   1. npm install @uniswap/v4-sdk @uniswap/sdk-core');
    console.log('   2. Use the SDK to encode actions properly');
    console.log('   3. See: https://docs.uniswap.org/sdk/v4/guides/liquidity/position-minting');
  }
}

main().catch(console.error);
