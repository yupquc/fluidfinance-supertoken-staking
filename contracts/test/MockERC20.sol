// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MockERC20 is ERC20, Ownable, ERC20Burnable, ERC20Pausable {
    string private _name = "RewardToken";
    string private _symbol = "REW";
    uint8 private _decimals = 8;

    constructor() ERC20(_name, _symbol) {}

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Pausable) {
        require(amount > 0, "Transfer amount must be greater than zero");
        super._beforeTokenTransfer(from, to, amount);
    }

}
