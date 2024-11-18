// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {Hashes} from "openzeppelin-contracts/contracts/utils/cryptography/Hashes.sol";
import {MerkleProof} from "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";

import {SmartContractWallet} from "../src/SmartContractWallet.sol";
import {SampleNFT} from "../src/SampleNFT.sol";

contract SmartContractWalletTest is Test {
    SmartContractWallet public scWallet;
    SampleNFT public sampleNFT;

    address aliceAddr;
    address bobAddr;

    function setUp() public {
        aliceAddr = makeAddr("alice");
        bobAddr = makeAddr("bob");

        sampleNFT = new SampleNFT();
        scWallet = new SmartContractWallet(address(sampleNFT));
        console.log("scWallet", address(scWallet));

        // pre mint
        sampleNFT.safeMint(address(scWallet));
        sampleNFT.safeMint(address(scWallet));

        // update balance merkle root
        bytes32 leaf1 = _calculateLeef(0, aliceAddr);
        bytes32 leaf2 = _calculateLeef(1, bobAddr);
        scWallet.updateBalanceMerkleRoot(Hashes.commutativeKeccak256(leaf1, leaf2));
        console.log("Debug");
        console.logBytes32(keccak256(abi.encodePacked(leaf1, leaf2)));
    }

    function test_isOwnerOf() external {
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = _calculateLeef(1, bobAddr);

        bool isValid = scWallet.isTokenOwner(0, aliceAddr, proof);
        assertTrue(isValid);
        isValid = scWallet.isTokenOwner(0, makeAddr("invalid address"), proof);
        assertFalse(isValid);
    }

    function test_withdraw() external {
        assertEq(sampleNFT.balanceOf(aliceAddr), 0);

        bytes32[] memory proof = new bytes32[](1);
        proof[0] = _calculateLeef(1, bobAddr);

        vm.expectRevert("not owner");
        scWallet.withdraw(makeAddr("invalid address"), 0, proof);

        scWallet.withdraw(aliceAddr, 0, proof);

        address owner = sampleNFT.ownerOf(0);
        console.log("aliceAddr", aliceAddr);
        console.logAddress(owner);
        assertEq(owner, aliceAddr);
        assertEq(sampleNFT.balanceOf(aliceAddr), 1);
    }

    function test_transfer() external {
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = _calculateLeef(1, bobAddr);

        bool[] memory proofFlags = new bool[](2);
        proofFlags[0] = true;
        proofFlags[1] = false;

        scWallet.transfer(aliceAddr, bobAddr, 0, proof, proofFlags);

        // bool isValid = scWallet.isTokenOwner(0, aliceAddr, proof);
        // assertFalse(isValid);
        // isValid = scWallet.isTokenOwner(0, bobAddr, proof);
        // assertTrue(isValid);
    }

    function _calculateLeef(uint256 tokenId, address owner) private returns (bytes32) {
        return keccak256(abi.encodePacked(tokenId, owner));
    }
}
