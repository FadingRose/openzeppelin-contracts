// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.2.0) (proxy/beacon/BeaconProxy.sol)

pragma solidity ^0.8.22;

import {IBeacon} from "./IBeacon.sol";
import {Proxy} from "../Proxy.sol";
import {ERC1967Utils} from "../ERC1967/ERC1967Utils.sol";

// NOTE: Beacon Pattern
// 1. Storage Slot Location
//    Beacon address is stored in a fixed storage slot:
//    `0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50`
//    (Calculation method: `bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)`)
// 2. Workflow
// - The proxy contract does NOT store the logic contract address directly, but rather stores the Beacon address
// - When Proxy executes logic, it calls the Beacon contract's `implementation()` function to get the latest logic address
// - Example call path:
//   ```solidity
//   address impl = Beacon(beaconAddress).implementation();
//   (bool success, ) = impl.delegatecall(data);
//   ```
// 3. Upgrade Beacon
//    After modifying the logic address in the Beacon contract, all associated proxies automatically upgrade:
//    ```solidity
//    // Upgrade operation (in Beacon contract)
//    function upgradeTo(address newImplementation) external {
//        require(msg.sender == admin);
//        _setImplementation(newImplementation);
//    }
//    ```

/**
 * @dev This contract implements a proxy that gets the implementation address for each call from an {UpgradeableBeacon}.
 *
 * The beacon address can only be set once during construction, and cannot be changed afterwards. It is stored in an
 * immutable variable to avoid unnecessary storage reads, and also in the beacon storage slot specified by
 * https://eips.ethereum.org/EIPS/eip-1967[ERC-1967] so that it can be accessed externally.
 *
 * CAUTION: Since the beacon address can never be changed, you must ensure that you either control the beacon, or trust
 * the beacon to not upgrade the implementation maliciously.
 *
 * IMPORTANT: Do not use the implementation logic to modify the beacon storage slot. Doing so would leave the proxy in
 * an inconsistent state where the beacon storage slot does not match the beacon address.
 */
contract BeaconProxy is Proxy {
    // An immutable address for the beacon to avoid unnecessary SLOADs before each delegate call.
    address private immutable _beacon;

    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializing the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {IBeacon}.
     * - If `data` is empty, `msg.value` must be zero.
     */
    constructor(address beacon, bytes memory data) payable {
        ERC1967Utils.upgradeBeaconToAndCall(beacon, data);
        _beacon = beacon;
    }

    /**
     * @dev Returns the current implementation address of the associated beacon.
     */
    function _implementation() internal view virtual override returns (address) {
        return IBeacon(_getBeacon()).implementation();
    }

    /**
     * @dev Returns the beacon.
     */
    function _getBeacon() internal view virtual returns (address) {
        return _beacon;
    }
}
