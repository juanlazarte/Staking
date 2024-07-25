// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {StakingNft} from "../src/Staking.sol";
import {ERC20Mock} from "";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// Mock ERC20 token for rewards
contract MockERC20 is ERC20 {
    constructor() ERC20("Mock Reward Token", "MRT") {}

    function mint(uint256 amount) external {
        _mint(msg.sender, amount);
    }
}

// Mock ERC721 token for staking
contract MockERC721 is ERC721 {
    constructor() ERC721("Mock NFT Token", "MNT") {}

    function mint(uint256 tokenId) external {
        _mint(msg.sender, tokenId);
    }
}


contract StakingNftTest is Test {
    StakingNft public stakingNft;
    MockERC20 public rewardToken;
    MockERC721 public nftToken;
    address public user;

    function setUp() public {
        rewardToken = new MockERC20();
        nftToken = new MockERC721();
        stakingNft = new StakingNft(IERC721(address(nftToken)), IERC20(address(rewardToken)));

        user = address(0x1234);
        vm.startPrank(user);
        nftToken.mint(1);
        nftToken.mint(2);
        vm.stopPrank();
    }

    function testStake() public {
        vm.startPrank(user);
        nftToken.approve(address(stakingNft), 1);
        stakingNft.stake(1);
        vm.stopPrank();

        assertEq(nftToken.ownerOf(1), address(stakingNft));
        assertEq(stakingNft.s_tokenOwner(1), user);
        assertEq(stakingNft.s_stakers(user).stakedTokens.length, 1);
    }

    function testUnstake() public {
        vm.startPrank(user);
        nftToken.approve(address(stakingNft), 1);
        stakingNft.stake(1);
        stakingNft.unstake(1);
        vm.stopPrank();

        assertEq(nftToken.ownerOf(1), user);
        assertEq(stakingNft.s_tokenOwner(1), address(0));
        assertEq(stakingNft.s_stakers(user).stakedTokens.length, 0);
    }

    function testClaimRewards() public {
        vm.startPrank(user);
        nftToken.approve(address(stakingNft), 1);
        stakingNft.stake(1);
        vm.warp(block.timestamp + 1 days);
        stakingNft.claimRewards();
        vm.stopPrank();

        uint256 expectedReward = 1 * stakingNft.s_rewardRate() * 1 days;
        assertEq(rewardToken.balanceOf(user), expectedReward);
    }

    function testSetRewardRate() public {
        uint256 newRate = 200;
        stakingNft.setRewardRate(newRate);
        assertEq(stakingNft.s_rewardRate(), newRate);
    }
}