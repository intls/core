// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {IReferenceModule} from 'contracts/interfaces/IReferenceModule.sol';
import {HubRestricted} from 'contracts/base/HubRestricted.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';
import {ILensHub} from 'contracts/interfaces/ILensHub.sol';
import {FollowValidationLib} from 'contracts/modules/libraries/FollowValidationLib.sol';

/**
 * @title FollowerOnlyReferenceModule
 * @author Lens Protocol
 *
 * @notice A simple reference module that validates that comments, quotes or mirrors originate from a profile that
 * follows the profile of the original publication.
 */
contract FollowerOnlyReferenceModule is HubRestricted, IReferenceModule {
    using FollowValidationLib for ILensHub;

    constructor(address hub) HubRestricted(hub) {}

    /**
     * @inheritdoc IReferenceModule
     *
     * @dev There is nothing needed at initialization.
     */
    function initializeReferenceModule(
        uint256 /* profileId */,
        uint256 /* pubId */,
        address /* transactionExecutor */,
        bytes calldata /* data */
    ) external pure returns (bytes memory) {
        return '';
    }

    /**
     * @inheritdoc IReferenceModule
     *
     * @dev Validates that the commenting profile's owner is a follower.
     */
    function processComment(
        Types.ProcessCommentParams calldata processCommentParams
    ) external view override returns (bytes memory) {
        ILensHub(HUB).validateIsFollowing({
            followerProfileId: processCommentParams.profileId,
            followedProfileId: processCommentParams.pointedProfileId
        });
        return '';
    }

    /**
     * @inheritdoc IReferenceModule
     *
     * @dev Validates that the quoting profile's owner is a follower.
     */
    function processQuote(
        Types.ProcessQuoteParams calldata processQuoteParams
    ) external view override returns (bytes memory) {
        ILensHub(HUB).validateIsFollowing({
            followerProfileId: processQuoteParams.profileId,
            followedProfileId: processQuoteParams.pointedProfileId
        });
        return '';
    }

    /**
     * @inheritdoc IReferenceModule
     *
     * @dev Validates that the mirroring profile's owner is a follower.
     */
    function processMirror(
        Types.ProcessMirrorParams calldata processMirrorParams
    ) external view override returns (bytes memory) {
        ILensHub(HUB).validateIsFollowing({
            followerProfileId: processMirrorParams.profileId,
            followedProfileId: processMirrorParams.pointedProfileId
        });
        return '';
    }
}