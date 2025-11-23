// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6 <0.9;

interface IWeb2Json {
    struct Proof {
        bytes32 merkleRoot;
        bytes32 leaf;
        bytes32[] proof;
        Data data;
    }

    struct Data {
        bytes32 requestHash;
        ResponseBody responseBody;
    }

    struct ResponseBody {
        bytes abiEncodedData;
    }
}
