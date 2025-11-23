// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6 <0.9;

import { IFdcVerification } from "@flarenetwork/flare-periphery-contracts/coston2/IFdcVerification.sol";
import { IWeb2Json } from "./IWeb2Json.sol";

interface IFdcVerificationExtended is IFdcVerification {
    function verifyWeb2Json(IWeb2Json.Proof calldata _proof) external view returns (bool);
}
