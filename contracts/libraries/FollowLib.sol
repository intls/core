// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {IFollowModule} from 'contracts/interfaces/IFollowModule.sol';
import {ValidationLib} from 'contracts/libraries/ValidationLib.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';
import {Errors} from 'contracts/libraries/constants/Errors.sol';
import {Events} from 'contracts/libraries/constants/Events.sol';
import {StorageLib} from 'contracts/libraries/StorageLib.sol';
import {IFollowNFT} from 'contracts/interfaces/IFollowNFT.sol';
import {FollowNFTProxy} from 'contracts/base/upgradeability/FollowNFTProxy.sol';

library FollowLib {
    function follow(
        uint256 followerProfileId,
        address transactionExecutor,
        uint256[] calldata idsOfProfilesToFollow,
        uint256[] calldata followTokenIds,
        bytes[] calldata followModuleDatas
    ) external returns (uint256[] memory) {
        if (
            idsOfProfilesToFollow.length != followTokenIds.length ||
            idsOfProfilesToFollow.length != followModuleDatas.length
        ) {
            revert Errors.ArrayMismatch();
        }
        uint256[] memory followTokenIdsAssigned = new uint256[](idsOfProfilesToFollow.length);
        uint256 i;
        while (i < idsOfProfilesToFollow.length) {
            ValidationLib.validateProfileExists({profileId: idsOfProfilesToFollow[i]});

            ValidationLib.validateNotBlocked({profile: followerProfileId, byProfile: idsOfProfilesToFollow[i]});

            if (followerProfileId == idsOfProfilesToFollow[i]) {
                revert Errors.SelfFollow();
            }

            followTokenIdsAssigned[i] = _follow({
                followerProfileId: followerProfileId,
                transactionExecutor: transactionExecutor,
                idOfProfileToFollow: idsOfProfilesToFollow[i],
                followTokenId: followTokenIds[i],
                followModuleData: followModuleDatas[i]
            });

            unchecked {
                ++i;
            }
        }
        return followTokenIdsAssigned;
    }

    function unfollow(
        uint256 unfollowerProfileId,
        address transactionExecutor,
        uint256[] calldata idsOfProfilesToUnfollow
    ) external {
        uint256 i;
        while (i < idsOfProfilesToUnfollow.length) {
            uint256 idOfProfileToUnfollow = idsOfProfilesToUnfollow[i];
            ValidationLib.validateProfileExists(idOfProfileToUnfollow);

            address followNFT = StorageLib.getProfile(idOfProfileToUnfollow).followNFT;

            if (followNFT == address(0)) {
                revert Errors.NotFollowing();
            }

            IFollowNFT(followNFT).unfollow({
                unfollowerProfileId: unfollowerProfileId,
                transactionExecutor: transactionExecutor
            });

            emit Events.Unfollowed(unfollowerProfileId, idOfProfileToUnfollow, transactionExecutor, block.timestamp);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Deploys the given profile's Follow NFT contract.
     *
     * @param profileId The token ID of the profile which Follow NFT should be deployed.
     *
     * @return address The address of the deployed Follow NFT contract.
     */
    function _deployFollowNFT(uint256 profileId) private returns (address) {
        bytes memory functionData = abi.encodeWithSelector(IFollowNFT.initialize.selector, profileId);
        address followNFT = address(new FollowNFTProxy(functionData));
        emit Events.FollowNFTDeployed(profileId, followNFT, block.timestamp);

        return followNFT;
    }

    function _follow(
        uint256 followerProfileId,
        address transactionExecutor,
        uint256 idOfProfileToFollow,
        uint256 followTokenId,
        bytes calldata followModuleData
    ) private returns (uint256) {
        Types.Profile storage _profileToFollow = StorageLib.getProfile(idOfProfileToFollow);

        address followNFT = _profileToFollow.followNFT;
        if (followNFT == address(0)) {
            followNFT = _deployFollowNFT(idOfProfileToFollow);
            _profileToFollow.followNFT = followNFT;
        }

        return
            _processFollow(
                ProcessFollowParams({
                    followNFT: followNFT,
                    followerProfileId: followerProfileId,
                    transactionExecutor: transactionExecutor,
                    idOfProfileToFollow: idOfProfileToFollow,
                    followTokenId: followTokenId,
                    followModule: _profileToFollow.followModule,
                    followModuleData: followModuleData
                })
            );
    }

    // Struct defined for the sole purpose of avoiding 'stack too deep' error.
    struct ProcessFollowParams {
        address followNFT;
        uint256 followerProfileId;
        address transactionExecutor;
        uint256 idOfProfileToFollow;
        uint256 followTokenId;
        address followModule;
        bytes followModuleData;
    }

    function _processFollow(ProcessFollowParams memory processFollowParams) private returns (uint256) {
        uint256 followTokenIdAssigned = IFollowNFT(processFollowParams.followNFT).follow({
            followerProfileId: processFollowParams.followerProfileId,
            transactionExecutor: processFollowParams.transactionExecutor,
            followTokenId: processFollowParams.followTokenId
        });

        bytes memory processFollowModuleReturnData;
        if (processFollowParams.followModule != address(0)) {
            processFollowModuleReturnData = IFollowModule(processFollowParams.followModule).processFollow(
                processFollowParams.followerProfileId,
                processFollowParams.followTokenId,
                processFollowParams.transactionExecutor,
                processFollowParams.idOfProfileToFollow,
                processFollowParams.followModuleData
            );
        }

        emit Events.Followed(
            processFollowParams.followerProfileId,
            processFollowParams.idOfProfileToFollow,
            followTokenIdAssigned,
            processFollowParams.followModuleData,
            processFollowModuleReturnData,
            processFollowParams.transactionExecutor,
            block.timestamp
        );

        return followTokenIdAssigned;
    }
}
