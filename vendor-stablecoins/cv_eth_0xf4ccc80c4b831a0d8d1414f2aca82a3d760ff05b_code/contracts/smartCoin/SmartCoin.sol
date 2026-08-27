// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.22;

/**
 * This is an official institutional stablecoin issued by Societe Generale–FORGE
 *
 * CoinVertible are exclusively intended for persons who are not U.S. Persons, as defined in Regulation S of the U.S. Securities Act of 1933, as amended and who are not physically present in the U.S..
 *
 * Offering, or inviting to purchase, CoinVertible in the U.S. is not authorized. Potential users shall observe any such restrictions in accordance with the relevant CoinVertible whitepaper available on SG Forge website.
 */

import "./ISmartCoin.sol";

import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./AccessControlUpgradeable.sol";
import "./SmartCoinDataLayout.sol";

/**
 * @dev Used when "available" balance is insufficient
 */
error InsufficientBalance(uint256 current, uint256 required);


/**
 * @dev The `SmartCoin` contract is basically an ERC20 with a few specifics
 * It uses the UUPS upgrade mechanism
 * It has a set of operators with specific rights :
 * - the registrar operator :
 *      - manages the blacklisting of users
 *      - names the operators for next implementation contract upgrade (AccessControlUpgradeable.nameNewOperators)
 *      - authorises upgrade to next implementation contract (AccessControlUpgradeable.authorizeImplementation)
        - manages redemption addresses
 * - the technical operator :
 *      - only the technical operator can launch a (previously authorised) upgrade of the implementation contract (upgradeTo/upgradeToAndCall)
 * Redemption Addresses are special addresses used when token owners want to 'cash out' of the SmartCoin (i.e. sell their tokens to the issuer in exchange for cash)
 */
contract SmartCoin is
    SmartCoinDataLayout,
    AccessControlUpgradeable,
    ERC20Upgradeable,
    UUPSUpgradeable,
    ISmartCoin
{

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address _registrar,
        address _operations,
        address _technical
    )
        onlyNotZeroAddress(_registrar)
        onlyNotZeroAddress(_operations)
        onlyNotZeroAddress(_technical)
        OnlyWhenOperatorsHaveDifferentAddress(
            _registrar,
            _operations,
            _technical
        )
        AccessControlUpgradeable(
            _registrar,
            _operations,
            _technical
        )
    {
        // https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#potentially-unsafe-operations
        // https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializing_the_implementation_contract
        _disableInitializers();
    }

    /**
     * @dev UUPS initializer that initializes the token's name and symbol
     */
    function initialize(
        string memory _name,
        string memory _symbol
    ) public initializer {
        __AccessControl_init();
        __ERC20_init(_name, _symbol);
        __UUPSUpgradeable_init();
    }

    /**
     * @dev Burns the balance of `_addr` address
     *
     * NB: This method is reserved to the registrar operator.
     */
    function wipeFrozenAddress(
        address _addr
    ) external override onlyRegistrar onlyFrozen(_addr) returns (bool) {
        super._burn(_addr, balanceOf(_addr));
        return true;
    }

    /**
     * @dev Burns a `amount` amount of tokens from the caller.
     * NB: only the registrar operator is allowed to burn their tokens
     */
    function burn(
        uint256 _amount
    )
        external
        override
        onlyWhenNotPaused
        onlyRegistrar
        returns (bool)
    {
        super._burn(registrar, _amount);
        return true;
    }

    /**
     * @dev Mints a `amount` amount of tokens on `to` address
     * NB: only the registrar operator is allowed to mint new tokens
     * NB: the `_to` address has to be unfrozen
     */
    function mint(
        address _to,
        uint256 _amount
    )
        external
        override(ISmartCoin)
        onlyWhenNotPaused
        onlyAllowedMinter
        onlyNotFrozen(_to)
        returns (bool)
    {
        super._mint(_to, _amount);
        return true;
    }

    function upgradeTo(
        address _newImplementation
    )
        external
        virtual
        override
        onlyProxy
        consumeAuthorizeImplementation(_newImplementation)
    {
        _authorizeUpgrade(_newImplementation);
        _upgradeToAndCallUUPS(_newImplementation, new bytes(0), false);
        _resetNewOperators();
    }

    function upgradeToAndCall(
        address _newImplementation,
        bytes memory data
    )
        external
        payable
        virtual
        override
        onlyProxy
        consumeAuthorizeImplementation(_newImplementation)
    {
        _authorizeUpgrade(_newImplementation);
        _upgradeToAndCallUUPS(_newImplementation, data, true);
        _resetNewOperators();
    }

    /**
     * @dev Returns the contract's operators' addresses
     */
    function getOperators() external view returns (address, address, address) {
        return (registrar, operations, technical);
    }

    /**
     * @dev Returns the version number of this contract
     */
    function version() external pure virtual returns (string memory) {
        return "V4";
    }

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     * NB: both the owner(msg.sender) and the spender have to be not frozen
     */
    function approve(
        address _spender,
        uint256 _value
    )
        public
        override(ERC20Upgradeable, ISmartCoin)
        onlyWhenNotPaused
        onlyNotFrozen(_msgSender())
        onlyNotFrozen(_spender)
        returns (bool)
    {
        super._approve(_msgSender(), _spender, _value);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `requestedDecrease`.
     * - `spender` and msg.sender have to be unfrozen
     *
     * NOTE: Although this function is designed to avoid double spending with {approval},
     * it can still be frontrunned, preventing any attempt of allowance reduction.
     */
    function decreaseAllowance(
        address _spender,
        uint256 _subtractedValue
    )
        public
        override(ERC20Upgradeable, ISmartCoin)
        onlyWhenNotPaused
        onlyNotFrozen(_spender)
        onlyNotFrozen(_msgSender())
        returns (bool)
    {
        return super.decreaseAllowance(_spender, _subtractedValue);
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` and msg.sender have to be unfrozen
     */
    function increaseAllowance(
        address _spender,
        uint256 _addedValue
    )
        public
        override(ERC20Upgradeable, ISmartCoin)
        onlyWhenNotPaused
        onlyNotFrozen(_spender)
        onlyNotFrozen(_msgSender())
        returns (bool)
    {
        return super.increaseAllowance(_spender, _addedValue);
    }

    /**
     * @dev Same semantic as ERC20's transferFrom function(no validation needed)
     * NB: the owner(_from),the spender(msg.sender) and the destination have to be unfrozen
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        override(ERC20Upgradeable, ISmartCoin)
        onlyWhenNotPaused
        onlyNotFrozen(_msgSender())
        onlyNotFrozen(_from)
        onlyNotFrozen(_to)
        returns (bool)
    {
        if (isRedemptionAddress[_to]) {
            super.transferFrom(_from, registrar, _value);
            emit RedemptionStarted(_from, _to, _value);
        } else {
            return super.transferFrom(_from, _to, _value);
        }

        return true;
    }

    /**
     * @dev Same semantic as ERC20's transfer function although there is one case :
     * if the destination is a redemption address, funds are transferred to the registrar operator instead of the redemption address
     *
     * NB: both the source(msg.sender) and the destination have to be unfrozen
     */
    function transfer(
        address _to,
        uint256 _value
    )
        public
        override(ISmartCoin, ERC20Upgradeable)
        onlyWhenNotPaused
        onlyNotFrozen(_msgSender())
        onlyNotFrozen(_to)
        returns (bool)
    {
        if (isRedemptionAddress[_to]) {
            super._transfer(_msgSender(), registrar, _value);
            emit RedemptionStarted(_msgSender(), _to, _value);
        } else {
            super._transfer(_msgSender(), _to, _value);
        }

        return true;
    }

    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyTechnical {}
}
