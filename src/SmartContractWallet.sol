// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Hashes} from "openzeppelin-contracts/contracts/utils/cryptography/Hashes.sol";
import {MerkleProof} from "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";

import {console} from "forge-std/Test.sol";

contract SmartContractWallet {
    using MerkleProof for bytes32;

    bytes4 constant Sig_SafeMint = 0x40d097c3;
    bytes4 constant Sig_SafeTransfer = 0xb88d4fde;
    bytes4 constant Sig_OnERC721Received = 0x150b7a02;

    error NotAllowed();

    event NewLeaf(uint256 tokenId, address owner, bytes32 leaf);

    address private immutable tokenAddress;

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
    }

    // Root Hash
    bytes32 private s_balances;

    function updateBalanceMerkleRoot(bytes32 _root) external {
        s_balances = _root;
    }

    // function balanceOf(address owner) external view returns (uint256 balance) {}

    function isTokenOwner(uint256 tokenId, address owner, bytes32[] calldata proof) external view returns (bool) {
        //@note leafの作成もオフチェーンに移行してしまって良いかも
        // tokenIdとownerをまとめた構造体を作った方が良いかも
        bytes32 leaf = keccak256(abi.encodePacked(tokenId, owner));
        console.logBytes32(leaf);
        return MerkleProof.verify(proof, s_balances, leaf);
    }

    // // @notice このコントラクト内でのみトークンの移動を行う。ERC721のストレージには影響しない。
    // function transfer(address from, address to, uint256 tokenId, bytes32[] calldata proof) external {
    //     bytes32 leaf = keccak256(abi.encodePacked(tokenId, from));
    //     if (!MerkleProof.verify(proof, s_balances, leaf)) {
    //         revert("not owner");
    //     }

    //     bytes32 newLeaf = keccak256(abi.encodePacked(tokenId, to));
    //     // s_balances = Hashes.commutativeKeccak256(s_balances, newLeaf);
    //     // s_balances = keccak256(abi.encodePacked(s_balances, newLeaf));
    //     MerkleProof.processMultiProof(proof, newLeaf);

    //     // @notice 秘匿化のために出力するか要検討
    //     // DA問題解決のために出している。(calldataに保存されているので不要かもしれない)
    //     emit NewLeaf(tokenId, to, newLeaf);
    // }

    function transfer(address from, address to, uint256 tokenId, bytes32[] calldata proof, bool[] calldata proofFlags)
        external
    {
        // MerkleProofを使用して所有者を検証
        bytes32 leaf = keccak256(abi.encodePacked(tokenId, from));

        // MerkleProofを使って`leaf`が正当なものであるか確認
        if (!MerkleProof.verify(proof, s_balances, leaf)) {
            revert("not owner");
        }

        // 新しいLeafを計算（toアドレスに対する新しい所有権）
        bytes32 newLeaf = keccak256(abi.encodePacked(tokenId, to));

        // Proofを使って`s_balances`（Merkleツリーのルート）を再計算
        // `leaves`は配列なので、新しく追加される`newLeaf`と`leaf`を両方渡す
        bytes32[] memory leaves = new bytes32[](2);
        leaves[0] = leaf;
        leaves[1] = newLeaf;

        // `processMultiProof`を使ってMerkleツリーの新しいルートを計算
        s_balances = MerkleProof.processMultiProof(proof, proofFlags, leaves);

        // // 新しいLeafをイベントとして発行
        // emit NewLeaf(tokenId, to, newLeaf);
    }

    function deposit() external {}

    function withdraw(address to, uint256 tokenId, bytes32[] calldata proof) external {
        bytes32 leaf = keccak256(abi.encodePacked(tokenId, to));
        if (!MerkleProof.verify(proof, s_balances, leaf)) {
            revert("not owner");
        }

        ERC721(tokenAddress).safeTransferFrom(address(this), to, tokenId);
    }

    function onERC721Received(address, address, uint256, bytes calldata _data) public pure returns (bytes4) {
        // @dev ERC721側で実行されたFunction Signatureを取得
        bytes4 functionSig = abi.decode(_data, (bytes4));

        if (functionSig == Sig_SafeMint) {
            console.log("Hello1");
            // revert("not implement");
        } else if (functionSig == Sig_SafeTransfer) {
            console.log("Hello2");
            // revert("not implement");
        } else {
            revert NotAllowed();
        }

        return Sig_OnERC721Received;
    }
}
