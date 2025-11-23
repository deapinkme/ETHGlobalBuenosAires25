import { http, createConfig } from 'wagmi'
import { base } from 'wagmi/chains'
import { injected } from 'wagmi/connectors'

export const config = createConfig({
  chains: [base],
  connectors: [injected()],
  transports: {
    [base.id]: http('https://mainnet.base.org'),
  },
})

export const CONTRACTS = {
  oracleReceiver: '0xdC1e39e8B56c6a4d14f9526843D95C3471d735D5' as `0x${string}`,
  natgas: '0x4aA1dF02688241e4c665D4837a7c201CddF9F3CD' as `0x${string}`,
  mockUsdc: '0xbB9d7298273dFEbe2706aafb06d7f1c10E8B356a' as `0x${string}`,
  hook: '0xC3CEe78d0825b24C684355de4e6FbD51F0b940c0' as `0x${string}`,
  poolManager: '0x498581fF718922c3f8e6A244956aF099B2652b2b' as `0x${string}`,
  swapRouter: '0xa139967F61f2677b3Bd4147542Cb3b8069E54b52' as `0x${string}`,
} as const

export const POOL_ID = '0xee3563ab546dddd4c9b8c4db4721077d62d363bfeabf0a98b5ed786e0ff2a7be' as `0x${string}`
