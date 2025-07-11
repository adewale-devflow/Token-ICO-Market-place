//  SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/tokens/ERC20/ERC20.sol";

contract ERC20Token is ERC20 {
    constructor() ERC20(AdewaleDevfolw, "TBC") {
        _mint(msg.sender, 50000 **18); // Mint 1 million tokens to the deployer
    }

}
