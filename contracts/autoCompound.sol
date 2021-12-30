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

interface PancakePair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function MINIMUM_LIQUIDITY() external view returns (uint256);

    function PERMIT_TYPEHASH() external view returns (bytes32);

    function allowance(address, address) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function balanceOf(address) external view returns (uint256);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function decimals() external view returns (uint8);

    function factory() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );

    function initialize(address _token0, address _token1) external;

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function name() external view returns (string memory);

    function nonces(address) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function skim(address to) external;

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes memory data
    ) external;

    function symbol() external view returns (string memory);

    function sync() external;

    function token0() external view returns (address);

    function token1() external view returns (address);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

interface IUserVault {
    function depositLP(uint256 _pid, uint256 _amount) public payable;
}

contract userVault is Ownable {
    IMasterChef private CAKE_MASTER_CHEF;

    event Deposited(uint amount);
    event Withdrawn(uint amount);

    constructor(IMasterChef masterChefContract) internal {
       CAKE_MASTER_CHEF = masterChefContract;
    }

    function setMasterChef(IMasterChef masterChefContract) public payable onlyOwner {
       CAKE_MASTER_CHEF = IMasterChef(_addr);
    }

    function depositLP(uint256 _pid, uint256 _amount) public payable whenNotPaused {
        require(_amount > 0, "Amount is negative");
        CAKE_MASTER_CHEF.deposit(_pid, _amount);
        emit Deposited(_amount);
    }

    function harvest(uint256 _pid, uint256 _amount) public payable whenNotPaused {
        require(_amount > 0, "Amount is negative");
        CAKE_MASTER_CHEF.deposit(_pid, _amount);
        emit Withdrawn(_amount);
    }

    function harvestableCake(uint _pid) public view returns(uint){
        return CAKE_MASTER_CHEF.pendingCake(_pid, address(this));
    }
}

contract farmsAutoCompoundPancakeSwap is Ownable, Pausable {
    mapping (address => uint) public lpDeposited;
    mapping (address => UserVault) public userVaults;

    IMasterChef private CAKE_MASTER_CHEF = IMasterChef(0x9a80c493665A4B3B5e163c0bb42EDF5327532595);
    address private fee_receiver = owner();

    event Deposit(address indexed sender, uint amount);
    event Harvest(address indexed sender, uint amount);

    constructor() internal {

    }

    function setFeeReceiver(address _addr) public payable onlyOwner {
       fee_receiver = _addr;
    }

    function setMasterChef(address _addr) public payable onlyOwner {
        //Change for all escrows?
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
        require(_amount > 0, "Amount is negative");
        lpDeposited[msg.sender] = lpDeposited[msg.sender] + _amount;
        //If vault doesn't exists create it
        if(userVaults[msg.sender] == 0){
            userVaults[msg.sender] = new UserVault(CAKE_MASTER_CHEF);
        }
        userVaults[msg.sender].deposit(_pid, _amount);
        emit Deposit(msg.sender, _amount);
    }

    function harvestableCake(uint _pid, address _addr) public view returns(uint){
        return CAKE_MASTER_CHEF.pendingCake(_pid, _addr);
    }

    function harvest(uint _pid, uint _amount) public payable whenNotPaused {
        CAKE_MASTER_CHEF.withdraw(_pid, _amount);
        emit Harvest(msg.sender, _amount);
    }

}

