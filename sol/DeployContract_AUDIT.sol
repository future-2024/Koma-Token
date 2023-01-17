// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.17;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
library EnumerableSet {
    struct Set {
        bytes32[] _values;
        mapping(bytes32 => uint256) _indexes;
    }
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }
    struct AddressSet {
        Set _inner;
    }
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }
    
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;
        assembly {
            result := store
        }

        return result;
    }
}
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
library myLibrary {
    struct bidPrice {
        uint256 bidOption;
        uint256 variable1;
        uint256 variable2;
    }
    struct expiryTimeInfo {
        uint256 expiryOption;
        uint256 startTime;
        uint256 decreaseBy;
        uint256 minimumTime;
    }
    struct createPotValue {
        address ERC721Address;
        address topOwner;
        address ownerOfTournament;
        bool isNative;
        uint256 tokenID;
        address bidToken;
        address potControlAddress;
        bidPrice bid;
        address[] toAddress;
        uint256[] toPercent;
        expiryTimeInfo expiryTime;
        bool priorityPool;
        uint256 toPreviousFee;
        uint256 ownerOfTournamentFee;
        uint256 hardExpiry;
        uint256 createNumber;
    }
}

contract Pot {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet _listedLicenseSet;
    uint256 public tokenID;
    address public bidToken;
    uint256 public bidAmount;
    bool public priorityPool;
    bool public isClaim;
    uint256 public createdDate;
    uint256 public timeUntilExpiry;   
    address public ownerOfTournament;
    uint256 public ownerOfTournamentFee;
    address public lastBidWinner;
    uint256 public lengthOfBidDistribution = 0;
    uint256 public toOwnerFee = 3;
    uint256 public percent = 100;
    address public toPreviousBidder;
    uint256 public toPreviousBidderFee;
    uint256 private winnerClaimAllowTime = 2851200;
    uint256 private createClaimAllowTime = 5702400;
    address public topOwner;
    uint256 public bidOption;
    uint256 public bidVariable1;
    uint256 public bidVariable2;
    uint256 public hardExpiry;
    bool public isNative;
    uint256 public claimedDate;
    address public potControlAddress;
    uint256 public expirationTime;
    uint256 public expExpiryOption;
    uint256 public expDecreaseBy;
    uint256 public expMinimumTime;
    address public CERC721AddRess;
    uint256 createNumber;
    IERC20 _token;    
    IERC721 erc721Token;
    struct bidDistributionInfo {
        address toAddress;
        uint256 percentage;
    }
    mapping(uint256 => bidDistributionInfo) public bidInfo;
    struct bidderInfo {
        uint256 total_bid;
    }
    mapping(address => bidderInfo) public bidders;    
    address[] public bidAddressList;
    modifier onlyOwner() {
        require(msg.sender == ownerOfTournament, "Not owner");
        _;
    }
    modifier checkAllowance(uint256 amount) {
        require(_token.allowance(msg.sender, address(this)) >= amount, "Allowance Error");
        _;
    }
    constructor() {
    }
    function setTopOwner(address newTopOwner) public {
        require(topOwner == msg.sender, "Error: not change Top");
        topOwner = newTopOwner;
    }
    function calcBidAmount(uint256 _bidOption, uint256 _variable1, uint256 _variable2) internal {
        if(_bidOption == 0) {
            bidAmount = _variable1;
        } else if (_bidOption == 1) {
            bidAmount = bidAmount.add(bidAmount.mul(_variable2).div(percent));
        }
    }
    function initialize(myLibrary.createPotValue memory sValue) external {   
        if (lengthOfBidDistribution > 0) {
            require(topOwner == msg.sender, "can not change");
        }
        bidToken = sValue.bidToken;
        isNative = sValue.isNative;        
        _token = IERC20(address(bidToken));
        lengthOfBidDistribution = sValue.toAddress.length;
        for(uint256 i = 0; i < sValue.toAddress.length; i++) {
            bidInfo[i].toAddress = sValue.toAddress[i];
            bidInfo[i].percentage = sValue.toPercent[i];
        }        
        erc721Token = IERC721(address(sValue.ERC721Address));
        priorityPool = sValue.priorityPool;
        CERC721AddRess = address(sValue.ERC721Address);
        createNumber = sValue.createNumber;
        _listedLicenseSet.add(sValue.ownerOfTournament);
        createdDate = block.timestamp;
        potControlAddress = sValue.potControlAddress;
        timeUntilExpiry = createdDate.add(sValue.expiryTime.startTime);  
        expExpiryOption = sValue.expiryTime.expiryOption;      
        expirationTime = sValue.expiryTime.startTime;
        expDecreaseBy = sValue.expiryTime.decreaseBy;
        expMinimumTime = sValue.expiryTime.minimumTime;
        tokenID = sValue.tokenID;
        lastBidWinner = sValue.ownerOfTournament;
        toPreviousBidderFee = sValue.toPreviousFee;
        ownerOfTournamentFee = sValue.ownerOfTournamentFee;
        ownerOfTournament = sValue.ownerOfTournament;
        topOwner = sValue.topOwner;           
        bidOption = sValue.bid.bidOption;  
        bidVariable1 = sValue.bid.variable1;  
        bidVariable2 = sValue.bid.variable2; 
        isClaim = false;
        if(bidOption == 0) {
            bidAmount = bidVariable1;
        } else if (bidOption == 1) {
            bidAmount = bidVariable1;
        }
    }
               
    function bid() public payable {
        require(timeUntilExpiry > block.timestamp, "pot is closed biding!");
        require(msg.value > 0, "Insufficinet value");
        require(msg.value == bidAmount, "not bid amount");   

        toPreviousBidder = lastBidWinner;
        bidders[msg.sender].total_bid = bidders[msg.sender].total_bid.add(bidAmount);
        uint256 value = msg.value;
        lastBidWinner = msg.sender;
        
        bool exist = false;
        for(uint256 cnt = 0; cnt < bidAddressList.length; cnt++) {
            if(bidAddressList[cnt] == msg.sender) {
                exist = true;
            }
        }
        if(exist == false) {
            bidAddressList.push(msg.sender);
        }
        _listedLicenseSet.add(lastBidWinner);
        if(expExpiryOption == 2 && expirationTime > expMinimumTime) {
            expirationTime = expirationTime.sub(expDecreaseBy);
        }
        uint256 ownerFee = bidAmount.mul(toOwnerFee).div(percent);        
        payable(address(topOwner)).transfer(ownerFee);    
        value = value.sub(ownerFee);
        uint256 previousBidderFee = bidAmount.mul(toPreviousBidderFee).div(percent);        
        payable(address(toPreviousBidder)).transfer(previousBidderFee);    
        value = value.sub(previousBidderFee);
        uint256 vOwnerOfTournamentFee = bidAmount.mul(ownerOfTournamentFee).div(percent);        
        payable(address(ownerOfTournament)).transfer(vOwnerOfTournamentFee);    
        value = value.sub(vOwnerOfTournamentFee);
        for (uint i = 0; i < lengthOfBidDistribution; i++) {
            uint256 bidFee = bidAmount.mul(bidInfo[i].percentage).div(percent);
            payable(address(bidInfo[i].toAddress)).transfer(bidFee);
            value = value.sub(bidFee);
        }
        uint256 createdBid = block.timestamp;
        timeUntilExpiry = createdBid.add(expirationTime);
        calcBidAmount(bidOption, bidVariable1, bidVariable2);
    }

    function bidERC20() public {
        if(hardExpiry != 0) {
            require(hardExpiry > block.timestamp, "is working now");
        }
        require(timeUntilExpiry > block.timestamp, "closed biding!");
        toPreviousBidder = lastBidWinner;
        bidders[msg.sender].total_bid = bidders[msg.sender].total_bid.add(bidAmount);
        uint256 value = bidAmount;
        lastBidWinner = msg.sender;
        _listedLicenseSet.add(lastBidWinner);
        bool exist = false;
        for(uint256 cnt = 0; cnt < bidAddressList.length; cnt++) {
            if(bidAddressList[cnt] == msg.sender) {
                exist = true;
            }
        }
        if(exist == false) {
            bidAddressList.push(msg.sender);
        }
        if(expExpiryOption == 2 && expirationTime > expMinimumTime) {
            expirationTime = expirationTime.sub(expDecreaseBy);
        }
        uint256 ownerFee = bidAmount.mul(toOwnerFee).div(percent);        
        _token.transferFrom(msg.sender, topOwner, ownerFee);
        value = value.sub(ownerFee);
        uint256 previousBidderFee = bidAmount.mul(toPreviousBidderFee).div(percent);  
        _token.transferFrom(msg.sender, toPreviousBidder, previousBidderFee);   
        value = value.sub(previousBidderFee);
        uint256 vOwnerOfTournamentFee = bidAmount.mul(ownerOfTournamentFee).div(percent);  
        _token.transferFrom(msg.sender, ownerOfTournament, vOwnerOfTournamentFee);   
        value = value.sub(vOwnerOfTournamentFee);
        for (uint i = 0; i < lengthOfBidDistribution; i++) {
            uint256 bidFee = bidAmount.mul(bidInfo[i].percentage).div(percent);        
            _token.transferFrom(msg.sender, bidInfo[i].toAddress, bidFee);   
            value = value.sub(bidFee);
        }
        _token.transferFrom(msg.sender, address(this), value); 
        uint256 createdBid = block.timestamp;
        timeUntilExpiry = createdBid.add(expirationTime);
        calcBidAmount(bidOption, bidVariable1, bidVariable2);
    }    
    function getTotalBid(address to) public view returns(uint256) {
        bidderInfo storage bidder = bidders[to];
        return bidder.total_bid;
    }
    function getLifeTime() public view returns (uint256) {
        if(timeUntilExpiry > block.timestamp){
            return timeUntilExpiry.sub(block.timestamp);  
        } else {
            return 0;
        }
    }
    function getBiddersInfo() public view returns(address[] memory ){
        return bidAddressList;
    }
    function claim() public {
        require(isClaim == false, "claimed!");
        address claimAvailableAddress;
        address topBidder = _listedLicenseSet.at(0);
        for(uint256 cnt = 0; cnt < _listedLicenseSet.length(); cnt++) {
            if(bidders[topBidder].total_bid < bidders[_listedLicenseSet.at(cnt)].total_bid) {
                topBidder = _listedLicenseSet.at(cnt);
            }
        }
        if(hardExpiry == 0) {
            if(block.timestamp < timeUntilExpiry) {
                claimAvailableAddress = 0x0000000000000000000000000000000000000000;
            } else if (timeUntilExpiry < block.timestamp && block.timestamp < timeUntilExpiry.add(winnerClaimAllowTime)) {
                claimAvailableAddress = topBidder;
            } else if (timeUntilExpiry.add(winnerClaimAllowTime) < block.timestamp && block.timestamp < timeUntilExpiry.add(createClaimAllowTime)) {
                claimAvailableAddress = ownerOfTournament;
            } else {
                claimAvailableAddress = topOwner;
            }
        } else {
            if(block.timestamp < hardExpiry) {
                claimAvailableAddress = 0x0000000000000000000000000000000000000000;
            } else if (hardExpiry < block.timestamp && block.timestamp < hardExpiry + winnerClaimAllowTime) {
                claimAvailableAddress = topBidder;
            } else if (hardExpiry.add(winnerClaimAllowTime) < block.timestamp && block.timestamp < hardExpiry.add(createClaimAllowTime)) {
                claimAvailableAddress = ownerOfTournament;
            } else {
                claimAvailableAddress = topOwner;
            }
        }
        require(msg.sender == claimAvailableAddress, "cannot claim!");
        erc721Token.transferFrom(address(this), msg.sender, tokenID);
        isClaim = true;
        claimedDate = block.timestamp;
    }
    function depositNFTNative() external {
        require(erc721Token.ownerOf(tokenID) == msg.sender, "not Owner");
        erc721Token.transferFrom(erc721Token.ownerOf(tokenID), address(this), tokenID);
    }
}
contract ControlPot {   
    using SafeMath for uint256;
    event Deployed(address);
    event Received(address, uint256);
    address public topOwner;
    address[] public allTournaments;
    address[] public bidDistributionAddress;
    uint256 public toOwnerFee = 3;
    uint256 public percent = 100;
    address[] public tokenList;     
    constructor() {
        topOwner = msg.sender;
    }
    struct bidPrice {
        uint256 bidOption;
        uint256 variable1;
        uint256 variable2;
    }
    struct expiryTimeInfoVal {
        uint256 expiryOption;
        uint256 startTime;
        uint256 decreaseBy;
        uint256 minimumTime;
    }
    modifier onlyOwner() {
        require(msg.sender == topOwner, "Not owner");
        _;
    }
    function addToken(address _token) external onlyOwner{
        if(tokenList.length > 0) {
            for(uint256 i = 0; i < tokenList.length; i++) {
                if(_token == tokenList[i]) {
                    revert();
                }
            }
        }
        tokenList.push(_token);
    }
    function getTokenList() external view returns (address[] memory) {
        return tokenList;
    }
    function removeToken(uint256 _index) external onlyOwner{
        if (_index >= tokenList.length) revert();

        for (uint i = _index; i<tokenList.length-1; i++){
            tokenList[i] = tokenList[i+1];
        }
        delete tokenList[tokenList.length-1];
        tokenList.pop();
    }
    function allTournamentsLength() external view returns (uint256) {
        return allTournaments.length;
    }
    function setTopOwner(address newTopOwner) public onlyOwner{
        topOwner = newTopOwner;
    }
    function setToOwnerFee(uint256 newToOwnerFee) public onlyOwner {
        toOwnerFee = newToOwnerFee;
    }
    function createPot(address _NFTERC721, uint256 _tokenID, uint256 _bidTokenIndex, bool _isNative, bidPrice memory _bid, address[] memory _toAddress, uint256[] memory _toPercent, expiryTimeInfoVal memory _expirationTime, uint256 _hardExpiry, bool _priorityPool, uint256[] memory _creatorAndPreviousFee) external payable returns (address pair) {
        require(_toAddress.length == _toPercent.length, "not match");        
        require(_toAddress.length > 0, "cannot empty");
        require(_toPercent.length > 0, "cannot empty"); 
        require(_expirationTime.startTime > 0, "cannot be 0");
        require(_expirationTime.startTime > _expirationTime.minimumTime, "bigger");
        require(_bid.bidOption <= 1, "wrong option");
        require(_bid.variable2 < 100, "wrong option");
        require(_bidTokenIndex <= tokenList.length, "set wrongly");
        uint256 bidPercent = 0;
        for (uint256 i = 0; i < _toPercent.length; i++) {
            bidPercent = bidPercent.add(_toPercent[i]);
        }
        if(_toAddress.length >= 2) {
            for (uint256 i = 0; i < _toAddress.length - 1; i++) {
                for(uint256 j = i + 1; j < _toAddress.length; j++) {
                    if(_toAddress[i] == _toAddress[j]) {
                        revert();
                    }
                }
            }
        }
        require(bidPercent == (percent.sub(toOwnerFee).sub(_creatorAndPreviousFee[0]).sub(_creatorAndPreviousFee[1])), "Fee is not 100%!");
        require(_creatorAndPreviousFee.length == 3, "mismatch number");        
        if(_priorityPool == false) {
            require(msg.value == 100000000000000, "amount as allowed");
        } else {
            require(msg.value == 200000000000000, "amount as allowed");
        }
        bytes memory bytecode = type(Pot).creationCode;
        myLibrary.createPotValue memory cValue; 
        cValue.ERC721Address = _NFTERC721;
        cValue.topOwner = topOwner;
        cValue.tokenID = _tokenID;
        cValue.createNumber = _creatorAndPreviousFee[2];
        cValue.ownerOfTournament = msg.sender;
        cValue.bidToken = tokenList[_bidTokenIndex];
        cValue.bid.bidOption = _bid.bidOption;
        cValue.bid.variable1 = _bid.variable1;
        cValue.bid.variable2 = _bid.variable2;
        cValue.toAddress = _toAddress;
        cValue.isNative = _isNative;
        cValue.toPercent = _toPercent;
        cValue.hardExpiry = _hardExpiry;
        cValue.ownerOfTournamentFee = _creatorAndPreviousFee[1];
        cValue.expiryTime.expiryOption = _expirationTime.expiryOption;
        cValue.expiryTime.startTime = _expirationTime.startTime;
        cValue.expiryTime.decreaseBy = _expirationTime.decreaseBy;
        cValue.expiryTime.minimumTime = _expirationTime.minimumTime;
        cValue.priorityPool = _priorityPool;
        cValue.toPreviousFee = _creatorAndPreviousFee[0] ;
        cValue.potControlAddress = address(this);
        bytes32 salt = keccak256(abi.encodePacked(tokenList[_bidTokenIndex], _bid.variable1, _toAddress, _toPercent, cValue.expiryTime.startTime, cValue.expiryTime.decreaseBy, cValue.expiryTime.minimumTime, _priorityPool, _creatorAndPreviousFee[0]));
        assembly { pair := create2(0, add(bytecode, 32), mload(bytecode), salt) }
        allTournaments.push(pair);
        Pot(pair).initialize(cValue);
        payable(topOwner).transfer(msg.value);
        emit Deployed(pair);
        return pair;
    }
}