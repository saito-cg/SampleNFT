// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {IERC721Receiver} from "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";

contract SampleNFT is ERC721 {
    uint256 private _nextTokenId;

    constructor() ERC721("test", "TEST") {}

    function safeMint(address to) public {
        uint256 tokenId = _nextTokenId++;
        bytes memory data = _decodeFuncSig();
        _safeMint(to, tokenId, data);
    }

    function safeTransferFrom(address from, address to, uint256 id) public override {
        transferFrom(from, to, id);

        bytes memory data = _decodeFuncSig();
        require(
            to.code.length == 0
                || IERC721Receiver(to).onERC721Received(msg.sender, from, id, data)
                    == IERC721Receiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function tokenURI(uint256) public pure override returns (string memory) {
        return "";
    }

    function _decodeFuncSig() private returns (bytes memory) {
        return abi.encode(msg.sig);
    }
}
