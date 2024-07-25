// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StakingNft is Ownable {

    IERC721 public s_nftToken;
    IERC20 public s_rewardToken;

    struct Staker {
        uint256[] stakedTokens;
        uint256 rewardDebt;
        uint256 lastUpdateTime;
    }

    uint256 public s_rewardRate = 100;

    mapping(address => Staker) public s_stakers;
    mapping(uint256 => address) public s_tokenOwner;

    event Staked(address indexed user, uint256 tokenId);
    event Unstaked(address indexed user, uint256 tokenId);
    event RewardClaimed(address indexed user, uint256 amount);

    constructor(IERC721 _nftToken, IERC20 _rewardToken) Ownable(msg.sender) {
        s_nftToken = _nftToken;
        s_rewardToken = _rewardToken;
    }

    function stake(uint256 _tokenId) external {
        require(s_nftToken.ownerOf(_tokenId) == msg.sender, "You are not the owner");
        
        s_nftToken.transferFrom(msg.sender, address(this), _tokenId);
        Staker storage staker = s_stakers[msg.sender];
        _updateReward(msg.sender);

        staker.stakedTokens.push(_tokenId);
        s_tokenOwner[_tokenId] = msg.sender;

        emit Staked(msg.sender, _tokenId);
    }

    function unstake(uint256 _tokenId) external {
        require(s_tokenOwner[_tokenId] == msg.sender, "You are not the owner");

        Staker storage staker = s_stakers[msg.sender];
        _updateReward(msg.sender);

        uint256 length = staker.stakedTokens.length;

        for (uint256 i; i < length; i++) 
        {
            if(staker.stakedTokens[i] == _tokenId) {
                staker.stakedTokens[i] = staker.stakedTokens[length - 1];
                staker.stakedTokens.pop();
                break;
            }
        }

        s_tokenOwner[_tokenId] = address(0);
        s_nftToken.transferFrom(address(this), msg.sender, _tokenId);

        emit Unstaked(msg.sender, _tokenId);
    }

    function claimRewards() external {
        Staker storage staker = s_stakers[msg.sender];

        _updateReward(msg.sender);

        uint256 reward = staker.rewardDebt;
        staker.rewardDebt = 0;

        //mint
        s_rewardToken.mint(reward);
        s_rewardToken.transfer(msg.sender, reward);

        emit RewardClaimed(msg.sender, reward);
    }

    function _updateReward(address _user) internal {
        Staker storage staker = s_stakers[_user];

        uint256 timeDiff = block.timestamp - staker.lastUpdateTime;
        uint256 pendingReward = staker.stakedTokens.length * s_rewardRate * timeDiff;

        staker.rewardDebt += pendingReward;
        staker.lastUpdateTime = block.timestamp;
    }

    function setRewardRate(uint256 _newRewardRate) external onlyOwner {
        s_rewardRate = _newRewardRate;
    }
}