pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20Detailed.sol";

/**
 * @title BatteryPaymentToken
 * @dev Very basic ERC20 Token in TS, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */
contract BatteryPaymentToken is Initializable, ERC20, ERC20Detailed, Ownable {

    function initialize(string memory name, string memory symbol, uint256 initialSupply, address owner) public initializer {
        Ownable.initialize(owner);
        ERC20Detailed.initialize(name, symbol, 0);
        _mint(owner, initialSupply * 10**uint(decimals()));
    }

    function tokenDetails() external view returns (string memory, string memory, uint8, uint256) {
        return (ERC20Detailed.name(), ERC20Detailed.symbol(), ERC20Detailed.decimals(), ERC20.totalSupply());    
    }
}
