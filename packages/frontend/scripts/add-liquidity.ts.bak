import { createWalletClient, http, parseUnits, encodeFunctionData, getContract } from 'viem';
import { base } from 'viem/chains';
import { privateKeyToAccount } from 'viem/accounts';

const POSITION_MANAGER = '0x7c5f5a4bbd8fd63184577525326123b519429bdc';
const NATGAS = '0x4aA1dF02688241e4c665D4837a7c201CddF9F3CD';
const USDC = '0xbB9d7298273dFEbe2706aafb06d7f1c10E8B356a';
const HOOK = '0xC3CEe78d0825b24C684355de4e6FbD51F0b940c0';

const ERC20_ABI = [
  {
    name: 'approve',
    type: 'function',
    stateMutability: 'nonpayable',
    inputs: [
      { name: 'spender', type: 'address' },
      { name: 'amount', type: 'uint256' }
    ],
    outputs: [{ name: '', type: 'bool' }]
  },
  {
    name: 'balanceOf',
    type: 'function',
    stateMutability: 'view',
    inputs: [{ name: 'account', type: 'address' }],
    outputs: [{ name: '', type: 'uint256' }]
  }
] as const;

async function main() {
  if (!process.env.PRIVATE_KEY) {
    throw new Error('PRIVATE_KEY environment variable not set');
  }

  const account = privateKeyToAccount(process.env.PRIVATE_KEY as `0x${string}`);

  const client = createWalletClient({
    account,
    chain: base,
    transport: http('https://mainnet.base.org'),
  });

  console.log('📍 Adding liquidity from:', account.address);
  console.log('');

  const natgasContract = getContract({
    address: NATGAS,
    abi: ERC20_ABI,
    client,
  });

  const usdcContract = getContract({
    address: USDC,
    abi: ERC20_ABI,
    client,
  });

  console.log('🔍 Checking token balances...');
  const natgasBalance = await natgasContract.read.balanceOf([account.address]);
  const usdcBalance = await usdcContract.read.balanceOf([account.address]);

  console.log(`  NATGAS: ${natgasBalance.toString()} (${Number(natgasBalance) / 1e18} tokens)`);
  console.log(`  USDC: ${usdcBalance.toString()} (${Number(usdcBalance) / 1e6} tokens)`);
  console.log('');

  const natgasAmount = parseUnits('1000', 18);
  const usdcAmount = parseUnits('1000', 6);

  if (natgasBalance < natgasAmount || usdcBalance < usdcAmount) {
    console.log('❌ Insufficient balance!');
    console.log('');
    console.log('Mint more tokens with:');
    console.log(`cast send ${NATGAS} "mint(address,uint256)" ${account.address} 10000000000000000000000 --rpc-url https://mainnet.base.org --private-key $PRIVATE_KEY`);
    console.log(`cast send ${USDC} "mint(address,uint256)" ${account.address} 10000000000 --rpc-url https://mainnet.base.org --private-key $PRIVATE_KEY`);
    return;
  }

  console.log('✅ Step 1: Approving NATGAS to PositionManager...');
  const natgasHash = await natgasContract.write.approve([POSITION_MANAGER, natgasAmount]);
  console.log(`  Tx: https://basescan.org/tx/${natgasHash}`);
  console.log('');

  console.log('✅ Step 2: Approving USDC to PositionManager...');
  const usdcHash = await usdcContract.write.approve([POSITION_MANAGER, usdcAmount]);
  console.log(`  Tx: https://basescan.org/tx/${usdcHash}`);
  console.log('');

  console.log('⚠️  Step 3: Minting position...');
  console.log('');
  console.log('To complete liquidity addition, you need to:');
  console.log('');
  console.log('1. Install Uniswap V4 SDK:');
  console.log('   npm install @uniswap/v4-sdk @uniswap/sdk-core');
  console.log('');
  console.log('2. Use the SDK to calculate proper liquidity parameters:');
  console.log('   - Current pool price (sqrtPriceX96)');
  console.log('   - Liquidity amount from token amounts');
  console.log('   - Tick range (-887220 to 887220 for full range)');
  console.log('');
  console.log('3. Call PositionManager.mint() with calculated parameters');
  console.log('');
  console.log('See LIQUIDITY_GUIDE.md for full instructions');
  console.log('');
  console.log('Position Manager: https://basescan.org/address/' + POSITION_MANAGER);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
