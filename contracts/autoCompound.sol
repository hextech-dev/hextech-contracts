// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface IMasterChef {
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

    function BONUS_MULTIPLIER() external view returns (uint256);

    function add(
        uint256 _allocPoint,
        address _lpToken,
        bool _withUpdate
    ) external;

    function cake() external view returns (address);

    function cakePerBlock() external view returns (uint256);

    function deposit(uint256 _pid, uint256 _amount) external;

    function dev(address _devaddr) external;

    function devaddr() external view returns (address);

    function emergencyWithdraw(uint256 _pid) external;

    function enterStaking(uint256 _amount) external;

    function getMultiplier(uint256 _from, uint256 _to)
        external
        view
        returns (uint256);

    function leaveStaking(uint256 _amount) external;

    function massUpdatePools() external;

    function migrate(uint256 _pid) external;

    function migrator() external view returns (address);

    function owner() external view returns (address);

    function pendingCake(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function poolInfo(uint256)
        external
        view
        returns (
            address lpToken,
            uint256 allocPoint,
            uint256 lastRewardBlock,
            uint256 accCakePerShare
        );

    function poolLength() external view returns (uint256);

    function renounceOwnership() external;

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external;

    function setMigrator(address _migrator) external;

    function startBlock() external view returns (uint256);

    function syrup() external view returns (address);

    function totalAllocPoint() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function updateMultiplier(uint256 multiplierNumber) external;

    function updatePool(uint256 _pid) external;

    function userInfo(uint256, address)
        external
        view
        returns (uint256 amount, uint256 rewardDebt);

    function withdraw(uint256 _pid, uint256 _amount) external;
}

contract farmsAutoCompound is Ownable, Pausable {
    mapping (address => uint) public cakeDeposit;
    IMasterChef private CAKE_MASTER_CHEF = IMasterChef(0x9a80c493665A4B3B5e163c0bb42EDF5327532595);

    function setMasterChef(address _addr) public payable onlyOwner {
       CAKE_MASTER_CHEF = IMasterChef(_addr);
    }

    function balanceOf() public view returns (uint256) {
        return CAKE_MASTER_CHEF.cakePerBlock();
    }

    function cake() public view returns (address) {
        return CAKE_MASTER_CHEF.cake();
    }

    function setPaused(bool _paused) public onlyOwner {
        if(_paused){
            _pause();
        } else {
            _unpause();
        }
    }

    function deposit(uint256 _pid, uint256 _amount) public payable whenNotPaused {
        //CAKE_MASTER_CHEF.deposit(_pid, _amount);
        require(_amount > 0, "Amount is negative");
        cakeDeposit[msg.sender] = cakeDeposit[msg.sender] + _amount;
    }

}

