# Deployment Addresses Reference

## Uniswap V4 Contracts

### Base Sepolia Testnet (Chain ID: 84532)
- **PoolManager**: `0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408`
- **PositionManager**: `0x4b2c77d209d3405f41a037ec6c77f7f5b8e2ca80`
- **StateView**: `0x571291b572ed32ce6751a2cb2486ebee8defb9b4`
- **Quoter**: `0x4a6513c898fe1b2d0e78d3b0e0a4a151589b1cba`
- **Universal Router**: `0x492e6456d9528771018deb9e87ef7750ef184104`
- **Permit2**: `0x000000000022D473030F116dDEE9F6B43aC78BA3`

### Ethereum Sepolia Testnet (Chain ID: 11155111)
- **PoolManager**: `0xE03A1074c86CFeDd5C142C4F04F1a1536e203543`
- **PositionManager**: `0x429ba70129df741B2Ca2a85BC3A2a3328e5c09b4`
- **StateView**: `0xe1dd9c3fa50edb962e442f60dfbc432e24537e4c`
- **Quoter**: `0x61b3f2011a92d183c7dbadbda940a7555ccf9227`
- **Universal Router**: `0x3A9D48AB9751398BbFa63ad67599Bb04e4BdF98b`
- **Permit2**: `0x000000000022D473030F116dDEE9F6B43aC78BA3`

### Base Mainnet (Chain ID: 8453)
- **PoolManager**: `0x498581ff718922c3f8e6a244956af099b2652b2b`
- **PositionManager**: `0x7c5f5a4bbd8fd63184577525326123b519429bdc`
- **StateView**: `0xa3c0c9b65bad0b08107aa264b0f3db444b867a71`
- **Quoter**: `0x0d5e0f971ed27fbff6c2837bf31316121532048d`
- **Universal Router**: `0x6ff5693b99212da76ad316178a184ab56d299b43`
- **Permit2**: `0x000000000022D473030F116dDEE9F6B43aC78BA3`

---

## LayerZero V2 Endpoints

### Base Sepolia Testnet
- **Endpoint Address**: `0x6EDCE65403992e310A62460808c4b910D972f10f`
- **Endpoint ID (EID)**: `40245`
- **Chain ID**: `84532`

### Ethereum Sepolia Testnet
- **Endpoint Address**: `0x6EDCE65403992e310A62460808c4b910D972f10f`
- **Endpoint ID (EID)**: `40161`
- **Chain ID**: `11155111`
- **Additional Contracts**:
  - SendUln302: `0xcc1ae8Cf5D3904Cef3360A9532B477529b177cCE`
  - ReceiveUln302: `0xdAf00F5eE2158dD58E0d3857851c432E34A3A851`
  - ReadLib1002: `0x908E86e9cb3F16CC94AE7569Bf64Ce2CE04bbcBE`
  - Executor: `0x718B92b5CB0a5552039B593faF724D182A881eDA`

### Flare Mainnet
- **Endpoint Address**: `0x1a44076050125825900e736c501f859c50fE728c`
- **Endpoint ID (EID)**: `30295`
- **Chain ID**: `14`

### Coston2 Testnet (Flare)
- **Status**: ⚠️ **NOT CONFIRMED**
- **Notes**: LayerZero V2 integration with Flare was announced in July 2024, but Coston2 testnet endpoint addresses are not publicly documented yet.
- **Alternatives**:
  1. Contact Flare or LayerZero teams for testnet deployment info
  2. Use Flare mainnet (30295) for production
  3. Use alternative testnets (Base Sepolia or Ethereum Sepolia)

---

## Recommended Deployment Architecture

### Option 1: Base Sepolia (RECOMMENDED)
```
Coston2 (Flare Testnet):
├── DisruptionOracle (deployed: 0x16AAf8F3CDfa890b2BeD67c33b4c39beaE9866aa)
├── FDC verification available
└── ❌ LayerZero NOT CONFIRMED

      ⬇ MANUAL PRICE UPDATES OR WAIT FOR LAYERZERO

Base Sepolia:
├── LayerZero Endpoint: 0x6EDCE65403992e310A62460808c4b910D972f10f (EID: 40245)
├── Uniswap V4 PoolManager: 0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408
├── NatGasDisruptionHook (to be deployed)
└── NATGAS/USDC pool
```

**Pros:**
- Full Uniswap V4 testnet support
- LayerZero V2 confirmed deployment
- Base is production target anyway

**Cons:**
- Cannot bridge from Coston2 (LayerZero not deployed there)
- Need manual price updates OR deploy oracle on Base Sepolia

### Option 2: Ethereum Sepolia
```
Ethereum Sepolia:
├── LayerZero Endpoint: 0x6EDCE65403992e310A62460808c4b910D972f10f (EID: 40161)
├── Uniswap V4 PoolManager: 0xE03A1074c86CFeDd5C142C4F04F1a1536e203543
├── NatGasDisruptionHook (to be deployed)
└── NATGAS/USDC pool
```

**Pros:**
- Full Uniswap V4 + LayerZero support
- Well-established testnet

**Cons:**
- Same Coston2 bridging issue
- Not the production target chain

### Option 3: Local Anvil + Manual Integration
```
Local Anvil:
├── Fork Base Sepolia
├── Deploy full Uniswap V4 locally
├── Deploy DisruptionOracle locally (with FDC mocks)
└── Deploy NatGasDisruptionHook
```

**Pros:**
- Full control, fast iteration
- No testnet faucet dependencies

**Cons:**
- No public demo
- Cannot showcase FDC integration

---

## Cross-Chain Architecture Decision

### ISSUE: Coston2 → Base Sepolia Bridge

**Problem**: DisruptionOracle is deployed on Coston2 (for FDC integration), but LayerZero endpoint doesn't exist on Coston2.

**Solutions**:

#### Solution A: Dual Oracle Deployment (SIMPLEST)
Deploy DisruptionOracle on BOTH networks:
- **Coston2**: FDC-powered oracle (reference implementation)
- **Base Sepolia**: Same oracle contract, manually updated OR use Base-compatible oracle service

```solidity
// On Base Sepolia - simplified oracle without FDC
contract DisruptionOracleSimple {
    uint256 public basePrice;
    address public owner;

    function updateBasePrice(uint256 _price) external onlyOwner {
        basePrice = _price;
    }
}
```

#### Solution B: Wait for Coston2 LayerZero Support
Contact LayerZero/Flare to confirm testnet deployment timeline.

#### Solution C: Flare Mainnet Bridge
Use Flare mainnet (EID: 30295) instead of Coston2:
- Deploy DisruptionOracle on Flare mainnet
- Bridge prices to Base Sepolia via LayerZero
- Requires mainnet tokens/gas

---

## Integration Code Examples

### Deploying Hook with Correct PoolManager

```solidity
// In your deployment script
address poolManager = 0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408; // Base Sepolia
address oracle = 0x...;  // Your oracle address

NatGasDisruptionHook hook = new NatGasDisruptionHook(
    IPoolManager(poolManager),
    oracle
);
```

### LayerZero Cross-Chain Message (if bridging)

```solidity
// On Coston2 (if LayerZero gets deployed)
import {ILayerZeroEndpointV2} from "@layerzerolabs/v2-protocol/contracts/interfaces/ILayerZeroEndpointV2.sol";

contract OracleMessageSender {
    ILayerZeroEndpointV2 public endpoint;
    uint32 public baseSepolia_EID = 40245;

    function sendPriceUpdate(uint256 price) external payable {
        bytes memory payload = abi.encode(price);

        endpoint.send{value: msg.value}(
            baseSepolia_EID,
            abi.encodePacked(targetAddress),
            payload,
            msg.sender,
            address(0),
            bytes("")
        );
    }
}
```

---

## Next Steps

1. **Immediate**: Deploy simplified oracle on Base Sepolia
2. **Parallel**: Contact LayerZero team about Coston2 support
3. **Development**: Build hook using Base Sepolia PoolManager
4. **Testing**: Local Anvil fork for rapid iteration
5. **Production**: Base mainnet when ready

---

## References

- [Uniswap V4 Deployments](https://docs.uniswap.org/contracts/v4/deployments)
- [LayerZero Deployed Contracts](https://docs.layerzero.network/v2/developers/evm/technical-reference/deployed-contracts)
- [LayerZero Flare Mainnet](https://docs.layerzero.network/v2/deployments/chains/flare)
- [Base Documentation - LayerZero](https://docs.base.org/learn/onchain-app-development/cross-chain/bridge-tokens-with-layerzero)
- [LayerZero Base Sepolia Quickstart](https://docs.layerzero.network/v2/deployments/evm-chains/base-sepolia-testnet-oft-quickstart)

---

**Last Updated**: 2025-11-23
**Verified**: All Uniswap V4 and LayerZero addresses confirmed from official documentation
