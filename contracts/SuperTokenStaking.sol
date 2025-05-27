// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperToken.sol";
import "@superfluid-finance/ethereum-contracts/contracts/apps/SuperTokenV1Library.sol";
import "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperTokenFactory.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SuperTokenStaking is
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    using SuperTokenV1Library for ISuperToken;
    using SafeERC20 for IERC20;

    struct StreamInfo {
        uint256 lastAccumulated;
        uint256 stakedAmount;
        int96 flowRate;
        address pool;
    }

    /// @notice Total staked super tokens on the contract
    uint256 public totalStaked;

    /// @notice Address of the fluid finance super token (will be used as staking token)
    ISuperToken public superToken;

    /// @notice Address of the reward token will be distributed to the super token stakers
    IERC20 public rewardToken;

    /// @notice Staker address => their detailed information
    mapping (address => StreamInfo) public streamInfos;
    
    /// @notice Emitted when stream started by staking super tokens
    event StreamStarted(
        address indexed user,
        uint256 suppliedAmount,
        int96 flowRate,
        uint256 timestamp
    );

    /// @notice Emitted when stream stopped by unstaking their super tokens
    event StreamStopped(
        address indexed user,
        address pool,
        uint256 remainingSuperTokens,
        uint256 timestamp
    );

    /// @notice Emitted when rewards tokens are being charged
    event RewardsAdded(uint256 rewards, uint256 timestamp);

    /// @notice Emitted when stakers claim their pending rewad tokens
    event RewardsClaimed(
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );

    /// @notice Emitted when owner withdraw tokens from the contract for emergency reason
    event EmergencyWithdrawalExecuted(
        IERC20 token,
        address to,
        uint256 amount,
        uint256 timestamp
    );


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _superToken,
        address _rewardToken
    )
        public
        initializer
     {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        __Pausable_init();

        require(_superToken != address(0), "SfTokenStaking: invalid staking token");
        require(_rewardToken != address(0), "SfTokenStaking: invalid reward token");

        rewardToken = IERC20(_rewardToken);
        superToken = ISuperToken(_superToken);
    }

    /// @notice External function to charge reward tokens
    /// @param amount The amount of reward tokens to be added
    function updateRewards(uint256 amount)
        external
        nonReentrant
        whenNotPaused
    {
        require(amount > 0, "SfTokenStaking: invalid amount");
        rewardToken.safeTransferFrom(msg.sender, address(this), amount);
        emit RewardsAdded(amount, block.timestamp);
    }


    /**
     * @notice User stakes by STREAMING a superfluid token X at a flow rate of his choice
     * @param amount The amount of staking tokens
     * @param flowRate The flow rate of super token distribution
     */
    function stake(uint256 amount, int96 flowRate)
        external
        nonReentrant
        whenNotPaused
    {
        require(amount > 0, "SfTokenStaking: invalid amount");
        require(flowRate > 0, "SfTokenStaking: invalid flow rate");
        require(
            streamInfos[msg.sender].pool == address(0),
            "SfTokenStaking: stream already started"
        );

        ISuperfluidPool pool = superToken.createPool(
            address(this),
            PoolConfig({
                transferabilityForUnitsOwner: false,
                distributionFromAnyAddress: true
            })
        );

        totalStaked += amount;
        streamInfos[msg.sender] = StreamInfo({
            lastAccumulated: block.timestamp,
            stakedAmount: amount,
            flowRate: flowRate,
            pool: address(pool)
        });

        IERC20(address(superToken)).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(address(superToken)).safeApprove(address(superToken), amount);

        superToken.distributeFlow(pool, flowRate);

        emit StreamStarted(msg.sender, amount, flowRate, block.timestamp);
    }

    
    /// @notice User unstakes by stop streaming a superfluid token X
    /// @dev User will receive the pro-rate reward tokens and not contributed super token
    function unstake()
        external
        whenNotPaused
        onlyStaker(msg.sender)
    {
        // claim pending rewards
        claimRewards(msg.sender);

        totalStaked -= streamInfos[msg.sender].stakedAmount;

        StreamInfo memory streamInfo = streamInfos[msg.sender];
        require(streamInfo.pool != address(0), "SfTokenStaking: stream not started");

        superToken.distributeFlow(ISuperfluidPool(streamInfo.pool), 0);

        uint256 distributedAmount = uint256(int256(streamInfo.flowRate))
            * (block.timestamp - streamInfo.lastAccumulated);

        uint256 remainingSuperTokens;
        if (distributedAmount < streamInfo.stakedAmount) {
            remainingSuperTokens = streamInfo.stakedAmount - distributedAmount;
            IERC20(address(superToken)).safeTransfer(msg.sender, remainingSuperTokens);
        }

        emit StreamStopped(
            msg.sender,
            streamInfo.pool,
            remainingSuperTokens,
            block.timestamp
        );

        delete streamInfos[msg.sender];
    }

    /// @notice External function claim pending rewards
    /// @param user The address of wallet claiming the rewards
    function claimRewards(address user)
        public
        nonReentrant
        whenNotPaused
        onlyStaker(user)
    {
        uint256 userRewards = getPendingRewards(user);
        if (userRewards == 0) {
            return;
        }

        StreamInfo storage streamInfo = streamInfos[user];
        streamInfo.lastAccumulated = block.timestamp;

        rewardToken.safeTransfer(user, userRewards);
        emit RewardsClaimed(user, userRewards, block.timestamp);
    }

    /// @notice Helper function to provide pending reward amount
    /// @param user The address of wallet checking the pending reward balance
    function getPendingRewards(address user)
        public
        view
        onlyStaker(user)
        returns (uint256 userRewards)
    {
        uint256 stakedAmount = streamInfos[user].stakedAmount;
        uint256 totalRewards = rewardToken.balanceOf(address(this));
        userRewards = totalRewards * stakedAmount / totalStaked;
    }

    modifier onlyStaker(address user) {
        require(streamInfos[user].stakedAmount > 0, "SfTokenStaking: no stake");
        _;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    /// @notice Function to pause the contract (only owner)
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Function to unpause the contract (only owner)
    function unpause() external onlyOwner {
        _unpause();
    }


    /// @notice Allows the owner to withdraw any tokens in case of emergency
    /// @param token The token to withdraw
    function emergencyWithdraw(IERC20 token, address to)
        external
        whenPaused
        onlyOwner
    {
        uint256 balance = token.balanceOf(address(this));
        if (balance > 0) {
            token.safeTransfer(to, balance);
            emit EmergencyWithdrawalExecuted(token, to, balance, block.timestamp);
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
