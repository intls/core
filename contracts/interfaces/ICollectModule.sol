// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/**
 * @title ICollectModule
 * @author Lens Protocol
 *
 * @notice This is the standard interface for all Lens-compatible CollectModules.
 */
interface ICollectModule {
    // function getModuleVersion() external view returns (uint256);

    //
    // function processModuleChange(
    // uint256 profileId,
    // uint256 pubId,
    // bytes calldata data
    // ) external;
    //
    /**
     * @notice Initializes data for a given publication being published. This can only be called by the hub.
     *
     * @param profileId The token ID of the profile publishing the publication.
     * @param executor The owner or an approved delegated executor.
     * @param pubId The associated publication's LensHub publication ID.
     * @param data Arbitrary data __passed from the user!__ to be decoded.
     *
     * @return bytes An abi encoded byte array encapsulating the execution's state changes. This will be emitted by the
     * hub alongside the collect module's address and should be consumed by front ends.
     */
    function initializePublicationCollectModule(
        uint256 profileId,
        address executor,
        uint256 pubId,
        bytes calldata data
    ) external returns (bytes memory);

    /**
     * @notice Processes a collect action for a given publication, this can only be called by the hub.
     *
     * @param referrerProfileId The LensHub profile token ID of the referrer's profile (only different in case of mirrors).
     * @param onBehalfOf The collector address.
     * @param delegatedExecutor The executor address, only different from onBehalfOf if a delegated executor is used.
     * @param profileId The token ID of the profile associated with the publication being collected.
     * @param pubId The LensHub publication ID associated with the publication being collected.
     * @param data Arbitrary data __passed from the collector!__ to be decoded.
     */
    function processCollect(
        uint256 referrerProfileId,
        address onBehalfOf,
        address delegatedExecutor,
        uint256 profileId,
        uint256 pubId,
        bytes calldata data
    ) external;
}
