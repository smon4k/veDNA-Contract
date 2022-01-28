// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;


import "./TimeLock.sol";
import "./Ownable.sol";


contract AirDrop is Ownable {
    using SafeMath for *;
    using SafeERC20 for IERC20;
    mapping(address => address[]) public recommend;

    mapping(address => bool) public whiteList;
    mapping(address => address) public upper;

    mapping(address => bool) public drawed;
    mapping(address => bool) public operators;
    address public token;
    uint256 public minHold;
    uint256 public airLimit;
    uint256 public airAmount;
    uint256 public tokenDecimals = 18;
    uint256 public ariNum = 10 * (10 ** tokenDecimals);

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;


    uint256 private _status = _NOT_ENTERED;


    address public lockAddress;
    //uint256 public airDropValue = 1000000000000000000;
    TimeLock public lockReward;
    mapping(address => uint256) public airDropValue;
    mapping(address => uint256) public airDropDrawed;
    mapping(address => uint256) public recommendReward;
    modifier onlyOperator() {
        require(operators[msg.sender], "caller is not the operator");
        _;
    }
      /** from openzeppelin
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    address public  minHoldToken =    0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE;// minhold token
    constructor(address _token) public {
        token = _token;
    }

    function setOperator(address[] memory users, bool b) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            operators[users[i]] = b;
        }
    }
    //change min hold
    function setMinHoldToken(address _token) external onlyOwner {

        require(_token != address(0), "address 0");
        minHoldToken = _token;
    }
    //change min hold
    function setMinHold(uint256 _minHold) external onlyOwner {
        minHold = _minHold;
    }
       //change setAirNum
    function setAirNum(uint256 _ariNum) external onlyOwner {
        ariNum = _ariNum;

    }

    function setLockAddress(address _lockAddress) external onlyOwner {
        lockAddress = _lockAddress;
        lockReward = TimeLock(_lockAddress);
    }



    function setUpperReward(uint256 _reward, address _lower) external onlyOperator {
        address one;
        address two;
        address three;
        (one, two, three,) = _getUppers(_lower);
        if (one != address(0)) {
            recommendReward[one] = recommendReward[one].add(_reward);
        }
        if (two != address(0)) {
            recommendReward[two] = recommendReward[two].add(_reward);
        }

        if (three != address(0)) {
            recommendReward[three] = recommendReward[three].add(_reward);
        }


    }

    function claim() external nonReentrant{
        uint256 reward = recommendReward[msg.sender];
        require(reward > 0, "no reward");
        IERC20(token).approve(lockAddress, reward);
        lockReward.deposit(msg.sender, token, reward);
        //TransferHelper.safeTransfer(token, lockAddress, reward);
        recommendReward[msg.sender] = 0;
    }

    function getOneLevelLists(address addr) public view returns (address[] memory){
        return recommend[addr];
    }


    function getTwoLevelLists(address addr) public view returns (address[] memory){
        address[] memory ones = recommend[addr];
        //twos = new address[](ones.length);
        uint256 k = 0;
        for (uint256 i = 0; i < ones.length; i++) {
            for (uint256 j = 0; j < recommend[ones[i]].length; j++) {
                k++;
            }
        }
        address[]  memory twos = new address[](k);
        for (uint256 i = 0; i < ones.length; i++) {
            for (uint256 j = 0; j < recommend[ones[i]].length; j++) {
                k--;
                twos[k] = recommend[ones[i]][j];

            }
        }
        return twos;
    }

    function getThreeLevelLists(address addr) public view returns (address[] memory){
        address[] memory twos = getTwoLevelLists(addr);
        uint256 k = 0;
        for (uint256 i = 0; i < twos.length; i++) {
            for (uint256 j = 0; j < recommend[twos[i]].length; j++) {
                //threes[k] = recommend[twos[i]][j];
                k++;
            }
        }
        address[] memory threes = new address[](k);
        for (uint256 i = 0; i < twos.length; i++) {
            for (uint256 j = 0; j < recommend[twos[i]].length; j++) {
                k--;
                threes[k] = recommend[twos[i]][j];

            }
        }
        return threes;
    }

    function getFourLevelLists(address addr) public view returns (address[] memory){
        address[] memory threes = getThreeLevelLists(addr);

        uint256 k = 0;
        for (uint256 i = 0; i < threes.length; i++) {
            for (uint256 j = 0; j < recommend[threes[i]].length; j++) {
                //fours[k] = recommend[threes[i]][j];
                k++;
            }
        }
        address[] memory fours = new address[](k);
        for (uint256 i = 0; i < threes.length; i++) {
            for (uint256 j = 0; j < recommend[threes[i]].length; j++) {
                k--;
                fours[k] = recommend[threes[i]][j];
            }
        }
        return fours;
    }
    // add white list
    function addWhiteList(address _whiteList, address _recommend) internal returns (bool) {
        //console.log("recommend:", _recommend);
        if (whiteList[_whiteList] == false && _recommend != _whiteList) {
            recommend[_recommend].push(_whiteList);
            whiteList[_whiteList] = true;
            upper[_whiteList] = _recommend;
            whiteList[_recommend] = true;
            return true;
        } else {
            return false;
        }


    }

    function _getUppers(address user) internal view returns (address one, address two, address three, address four){
        one = upper[user];
        if (one != address(0)) {
            two = upper[one];
            if (two != address(0)) {
                three = upper[two];
                if (three != address(0)) {
                    four = upper[three];
                }
            }
        }
    }


    function getUppers(address user) public view returns (address one, address two, address three, address four){
        one = upper[user];
        if (one != address(0)) {
            two = upper[one];
            if (two != address(0)) {
                three = upper[two];
                if (three != address(0)) {
                    four = upper[three];
                }
            }
        }
    }


    function draw(address _recommend) external nonReentrant{

        require(IERC20(minHoldToken).balanceOf(address(msg.sender))>=minHold , "less than minHold");

        if (_recommend != address(0)) {
            if (whiteList[_recommend] == false && msg.sender != _recommend) {
                airDropValue[_recommend] = ariNum;
            }

            bool b = addWhiteList(msg.sender, _recommend);
            if (b == true) {
                address one;
                address two;
                address three;
                (one, two, three,) = _getUppers(msg.sender);
                if (one != address(0)) {
                    airDropValue[one] = airDropValue[one].add(ariNum);
                }
                if (two != address(0)) {
                    airDropValue[two] = airDropValue[two].add(ariNum);
                }
                if (three != address(0)) {
                    airDropValue[three] = airDropValue[three].add(ariNum);
                }
                airDropValue[msg.sender] = ariNum;
            } else {
                if (whiteList[msg.sender] == false) {
                    airDropValue[msg.sender] = ariNum;
                    whiteList[msg.sender] = true;
                }
            }
        }

        if (airDropValue[msg.sender] > 0
        && IERC20(token).balanceOf(address(this)) >= airDropValue[msg.sender]
        && airAmount.add(airDropValue[msg.sender])<=airLimit) {
           // TransferHelper.safeTransfer(token, msg.sender,  airDropValue[msg.sender]);
            IERC20(token).safeTransfer(address(msg.sender), airDropValue[msg.sender]);
            airDropDrawed[msg.sender] = airDropDrawed[msg.sender].add(airDropValue[msg.sender]);
            airAmount = airAmount.add(airDropValue[msg.sender]);
            airDropValue[msg.sender] = 0;
        }


    }
    function drawlater(address _recommend) external {


        if (_recommend != address(0)) {
            if (whiteList[_recommend] == false && msg.sender != _recommend) {

            }

            bool b = addWhiteList(msg.sender, _recommend);
            if (b == true) {
                address one;
                address two;
                address three;
                (one, two, three,) = _getUppers(msg.sender);

            } else {
                if (whiteList[msg.sender] == false) {

                    whiteList[msg.sender] = true;
                }
            }
        }

    }


    function  AirInit(uint256 amount) external onlyOwner {
        IERC20(token).transferFrom(
                address(msg.sender),
                address(this),
                amount
            );
        airLimit = amount;
        airAmount = 0;
    }


}