export const OracleReceiverABI = [
  {
    inputs: [],
    name: 'getTheoreticalPrice',
    outputs: [{ internalType: 'uint256', name: '', type: 'uint256' }],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [],
    name: 'lastUpdateTimestamp',
    outputs: [{ internalType: 'uint256', name: '', type: 'uint256' }],
    stateMutability: 'view',
    type: 'function',
  },
] as const

export const ERC20ABI = [
  {
    inputs: [{ internalType: 'address', name: 'account', type: 'address' }],
    name: 'balanceOf',
    outputs: [{ internalType: 'uint256', name: '', type: 'uint256' }],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [],
    name: 'decimals',
    outputs: [{ internalType: 'uint8', name: '', type: 'uint8' }],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [],
    name: 'symbol',
    outputs: [{ internalType: 'string', name: '', type: 'string' }],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [
      { internalType: 'address', name: 'spender', type: 'address' },
      { internalType: 'uint256', name: 'amount', type: 'uint256' },
    ],
    name: 'approve',
    outputs: [{ internalType: 'bool', name: '', type: 'bool' }],
    stateMutability: 'nonpayable',
    type: 'function',
  },
  {
    inputs: [
      { internalType: 'address', name: 'owner', type: 'address' },
      { internalType: 'address', name: 'spender', type: 'address' },
    ],
    name: 'allowance',
    outputs: [{ internalType: 'uint256', name: '', type: 'uint256' }],
    stateMutability: 'view',
    type: 'function',
  },
] as const

export const PoolManagerABI = [
  {
    inputs: [{ internalType: 'bytes32', name: 'slot', type: 'bytes32' }],
    name: 'extsload',
    outputs: [{ internalType: 'bytes32', name: 'value', type: 'bytes32' }],
    stateMutability: 'view',
    type: 'function',
  },
] as const

export const SwapRouterABI = [
  {
    inputs: [
      {
        components: [
          { internalType: 'address', name: 'currency0', type: 'address' },
          { internalType: 'address', name: 'currency1', type: 'address' },
          { internalType: 'uint24', name: 'fee', type: 'uint24' },
          { internalType: 'int24', name: 'tickSpacing', type: 'int24' },
          { internalType: 'address', name: 'hooks', type: 'address' },
        ],
        internalType: 'struct PoolKey',
        name: 'key',
        type: 'tuple',
      },
      {
        components: [
          { internalType: 'bool', name: 'zeroForOne', type: 'bool' },
          { internalType: 'int256', name: 'amountSpecified', type: 'int256' },
          { internalType: 'uint160', name: 'sqrtPriceLimitX96', type: 'uint160' },
        ],
        internalType: 'struct SwapParams',
        name: 'params',
        type: 'tuple',
      },
      { internalType: 'bytes', name: 'hookData', type: 'bytes' },
    ],
    name: 'swap',
    outputs: [
      {
        components: [
          { internalType: 'int128', name: '_amount0', type: 'int128' },
          { internalType: 'int128', name: '_amount1', type: 'int128' },
        ],
        internalType: 'struct BalanceDelta',
        name: 'delta',
        type: 'tuple',
      },
    ],
    stateMutability: 'nonpayable',
    type: 'function',
  },
] as const
