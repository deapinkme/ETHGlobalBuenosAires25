require('dotenv').config();
const { createWalletClient, http, parseUnits, encodePacked, pad } = require('viem');
const { base } = require('viem/chains');
const { privateKeyToAccount } = require('viem/accounts');

const POSITION_MANAGER = '0x7C5f5A4bBd8fD63184577525326123B519429bDc';
const NATGAS = '0x4aA1dF02688241e4c665D4837a7c201CddF9F3CD';
const USDC = '0xbB9d7298273dFEbe2706aafb06d7f1c10E8B356a';
const HOOK = '0xC3CEe78d0825b24C684355de4e6FbD51F0b940c0';

const ABI = [
  {
    name: 'modifyLiquidities',
    type: 'function',
    stateMutability: 'payable',
    inputs: [
      { name: 'unlockData', type: 'bytes' },
      { name: 'deadline', type: 'uint256' }
    ],
    outputs: []
  },
  {
    name: 'approve',
    type: 'function',
    inputs: [
      { name: 'spender', type: 'address' },
      { name: 'amount', type: 'uint256' }
    ],
    outputs: [{ name: '', type: 'bool' }]
  }
];

async function main() {
  const account = privateKeyToAccount(process.env.PRIVATE_KEY);
  const client = createWalletClient({
    account,
    chain: base,
    transport: http('https://mainnet.base.org'),
  });

  console.log('Adding liquidity...');
  console.log('Account:', account.address);

  const actions = '0x020808';

  const poolKey = [NATGAS, USDC, 0, 60, HOOK];
  const mintParams = [
    poolKey,
    -60n,
    60n,
    100000n,
    parseUnits('1', 18),
    parseUnits('1', 6),
    account.address,
    '0x'
  ];

  const params = [
    { type: 'tuple(address,address,uint24,int24,address)', value: poolKey },
    { type: 'int24', value: -60n },
    { type: 'int24', value: 60n },
    { type: 'uint256', value: 100000n },
    { type: 'uint128', value: parseUnits('1', 18) },
    { type: 'uint128', value: parseUnits('1', 6) },
    { type: 'address', value: account.address },
    { type: 'bytes', value: '0x' }
  ];

  // Manual ABI encoding
  const paramsArray = [
    encodeFunctionData({
      abi: [{
        type: 'function',
        name: 'mint',
        inputs: [
          { name: 'poolKey', type: 'tuple(address,address,uint24,int24,address)' },
          { name: 'tickLower', type: 'int24' },
          { name: 'tickUpper', type: 'int24' },
          { name: 'liquidity', type: 'uint256' },
          { name: 'amount0Max', type: 'uint128' },
          { name: 'amount1Max', type: 'uint128' },
          { name: 'owner', type: 'address' },
          { name: 'hookData', type: 'bytes' }
        ]
      }],
      functionName: 'mint',
      args: mintParams
    }).slice(10), // Remove function selector
    encodeFunctionData({
      abi: [{ type: 'function', name: 'close', inputs: [{ name: 'currency', type: 'address' }] }],
      functionName: 'close',
      args: [NATGAS]
    }).slice(10),
    encodeFunctionData({
      abi: [{ type: 'function', name: 'close', inputs: [{ name: 'currency', type: 'address' }] }],
      functionName: 'close',
      args: [USDC]
    }).slice(10)
  ];

  const unlockData = encodePacked(
    ['bytes', 'bytes[]'],
    [actions, paramsArray]
  );

  console.log('Approving...');
  await client.writeContract({
    address: NATGAS,
    abi: ABI,
    functionName: 'approve',
    args: [POSITION_MANAGER, parseUnits('1000000', 18)]
  });

  await client.writeContract({
    address: USDC,
    abi: ABI,
    functionName: 'approve',
    args: [POSITION_MANAGER, parseUnits('1000000', 6)]
  });

  console.log('Adding liquidity...');
  const hash = await client.writeContract({
    address: POSITION_MANAGER,
    abi: ABI,
    functionName: 'modifyLiquidities',
    args: [unlockData, BigInt(Math.floor(Date.now() / 1000) + 3600)]
  });

  console.log('TX:', hash);
}

main().catch(console.error);
