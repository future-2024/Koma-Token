// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
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
contract ATM  {
    
    using SafeMath for uint256;
    struct tokenAmount {
        address tokenAddress;
        uint256 value;
    }
    struct ATMWallet {
        address walletAddress;
        bool isAllow;
        tokenAmount[] amount;
    }
    struct treasuryAmount {
        address tokenAddress;
        uint256 value;
    }
    struct TreasuryWallet {
        treasuryAmount[] amount;
    }
    address public owner;
    uint256 public numberOfWallet;

    mapping(uint256 => ATMWallet) public wallet;
    TreasuryWallet private treasuryWallet;
    modifier onlyOwner() {
        require(msg.sender == owner, "Not onwer");
        _;
    }
    modifier checkAllowance(address _tokenAddress, uint256 _amount) {
        IERC20 _token = IERC20(address(_tokenAddress));
        require(_token.allowance(msg.sender, address(this)) >= _amount, "Allowance Error");
        _;
    }
    constructor() {
        owner = msg.sender;
        numberOfWallet = 0;
    }
    function transferOwnership(address newOwner) public onlyOwner {
        require(owner == msg.sender, "You are not owner!");
        owner = newOwner;
    }
    function depositTreasury(address _tokenAddress, uint256 _depositAmount) external checkAllowance(_tokenAddress, _depositAmount) onlyOwner {
        bool isToken = false;
        for(uint256 cnt = 0; cnt < treasuryWallet.amount.length; cnt++) {
            if(treasuryWallet.amount[cnt].tokenAddress == _tokenAddress) {
                isToken = true;
                treasuryWallet.amount[cnt].value = treasuryWallet.amount[cnt].value.add(_depositAmount);
            }
        }
        if(isToken == false) {
            treasuryAmount memory perTreasury = treasuryAmount(_tokenAddress, _depositAmount);
            treasuryWallet.amount.push(perTreasury);
        }
    }
    function depositToken(address _walletAddress, address _tokenAddress, uint256 _depositAmount) external checkAllowance(_tokenAddress, _depositAmount) {
        IERC20 _token;
        uint256 depositAmount = _depositAmount;
        _token = IERC20(address(_tokenAddress));
        _token.transferFrom(_walletAddress, address(this), depositAmount);
        bool isAsset = false;
        for(uint256 _cnt1 = 0; _cnt1 < numberOfWallet; _cnt1++) {
            if(wallet[_cnt1].walletAddress == _walletAddress) {
                bool isToken = false;
                for(uint256 _cnt2 = 0; _cnt2 < wallet[_cnt1].amount.length; _cnt2++) {
                    if(wallet[_cnt1].amount[_cnt2].tokenAddress == _tokenAddress) {
                        wallet[_cnt1].amount[_cnt2].value = wallet[_cnt1].amount[_cnt2].value.add(depositAmount);
                        isAsset = true;
                        isToken = true;
                    }
                } 
                if(isToken == false) {                                        
                    tokenAmount memory perToken = tokenAmount(_tokenAddress, depositAmount);       
                    wallet[_cnt1].amount.push(perToken);
                    isAsset = true;
                }
            }
        }
        if(isAsset == false) {  
            wallet[numberOfWallet].walletAddress = _walletAddress;   
            wallet[numberOfWallet].isAllow = false;   
            tokenAmount memory perToken = tokenAmount(_tokenAddress, depositAmount);       
            wallet[numberOfWallet].amount.push(perToken);
            numberOfWallet = numberOfWallet.add(1);
        }
    }
    function withdrawTreasury(address _tokenAddress, uint256 _withdrawAmount) external onlyOwner {
        IERC20 _token;
        _token = IERC20(address(_tokenAddress));
        for(uint256 cnt = 0; cnt < treasuryWallet.amount.length; cnt++) {
            if(treasuryWallet.amount[cnt].tokenAddress == _tokenAddress) {
                uint256 _balance = _token.balanceOf(address(this));
                require(_withdrawAmount <= _balance, "sorry, pool has not enough token");
                require(_withdrawAmount <= treasuryWallet.amount[cnt].value, "You cannot withdraw this amount"); 
                _token.transfer(owner, _withdrawAmount);
                treasuryWallet.amount[cnt].value = treasuryWallet.amount[cnt].value.sub(_withdrawAmount);
            }
        }
    }
    function preWithdrawToken(address _walletAddress) external {
        for(uint256 _cnt1 = 0; _cnt1 < numberOfWallet; _cnt1++) {
            if(wallet[_cnt1].walletAddress == _walletAddress) {
                wallet[_cnt1].isAllow = true;
            }
        }
    }


    function sendTokens(address _tokenAddress, address _walletAddress, uint256 _amount) public onlyOwner {
        IERC20 _token = IERC20(_tokenAddress);
        require(_token.allowance(msg.sender, address(this)) >= _amount, "Allowance Error: msg.sender does not have enough allowance from the token contract");
        uint256 selectedWallet;
        for(uint256 _cnt1 = 0; _cnt1 < numberOfWallet; _cnt1++) {
            if(wallet[_cnt1].walletAddress == _walletAddress) {
                selectedWallet = _cnt1;
                for(uint256 _cnt2 = 0; _cnt2 < wallet[_cnt1].amount.length; _cnt2++) {
                    if(wallet[_cnt1].amount[_cnt2].tokenAddress == _tokenAddress) {
                        require(msg.sender == _walletAddress, "you are not owner");
                        require(wallet[_cnt1].isAllow == true, "you are not allowed");
                        require(_amount <= wallet[_cnt1].amount[_cnt2].value, "You cannot withdraw this amount");
                        _token.transfer(_walletAddress, _amount);                        
                        wallet[_cnt1].amount[_cnt2].value = wallet[_cnt1].amount[_cnt2].value.sub(_amount);
                    }
                } 
            }
        }
    }
    // function withdrawToken(address _walletAddress, address _tokenAddress, uint256 _withdrawAmount) external {
    //     IERC20 _token;
    //     _token = IERC20(address(_tokenAddress));
    //     uint256 selectedWallet;
    //     for(uint256 _cnt1 = 0; _cnt1 < numberOfWallet; _cnt1++) {
    //         if(wallet[_cnt1].walletAddress == _walletAddress) {
    //             selectedWallet = _cnt1;
    //             for(uint256 _cnt2 = 0; _cnt2 < wallet[_cnt1].amount.length; _cnt2++) {
    //                 if(wallet[_cnt1].amount[_cnt2].tokenAddress == _tokenAddress) {
    //                     uint256 _balance = _token.balanceOf(address(this));
    //                     require(msg.sender == _walletAddress, "you are not owner");
    //                     require(wallet[_cnt1].isAllow == true, "you are not allowed");
    //                     require(_withdrawAmount <= wallet[_cnt1].amount[_cnt2].value, "You cannot withdraw this amount");
    //                     require(_withdrawAmount <= _balance, "Sorry, pool has not enough token.");
    //                     _token.transfer(_walletAddress, _withdrawAmount);                        
    //                     wallet[_cnt1].amount[_cnt2].value = wallet[_cnt1].amount[_cnt2].value.sub(_withdrawAmount);
    //                 }
    //             } 
    //         }
    //     }
    //     wallet[selectedWallet].isAllow = false;
    // }
    // function cancelWithdrawToken(address _walletAddress) external {
    //     for(uint256 _cnt1 = 0; _cnt1 < numberOfWallet; _cnt1++) {
    //         if(wallet[_cnt1].walletAddress == _walletAddress) {
    //             wallet[_cnt1].isAllow = false;
    //         }
    //     }
    // }
    // function updateBalance(address _walletAddress, address _tokenAddress, uint256 _updateAmount, bool _isResult) external onlyOwner{
    //     bool isAvailable = false;
    //     for(uint256 _cnt1 = 0; _cnt1 < numberOfWallet; _cnt1++) {
    //         if(wallet[_cnt1].walletAddress == _walletAddress) {
    //             for(uint256 _cnt2 = 0; _cnt2 < wallet[_cnt1].amount.length; _cnt2++) {
    //                 if(wallet[_cnt1].amount[_cnt2].tokenAddress == _tokenAddress) {
    //                     if(_isResult == true) {
    //                         wallet[_cnt1].amount[_cnt2].value = wallet[_cnt1].amount[_cnt2].value.sub(_updateAmount);   
    //                         isAvailable = true;                         
    //                     } else {
    //                         wallet[_cnt1].amount[_cnt2].value = wallet[_cnt1].amount[_cnt2].value.add(_updateAmount);
    //                         isAvailable = true;  
    //                     }
    //                 }
    //             } 
    //         }
    //     }
    //     require(isAvailable == true, "you haven't deposited amount");
    //     bool isToken = false;
    //     for(uint256 cnt = 0; cnt < treasuryWallet.amount.length; cnt++) {
    //         if(treasuryWallet.amount[cnt].tokenAddress == _tokenAddress) {
    //             if(_isResult == false) {
    //                 treasuryWallet.amount[cnt].value = treasuryWallet.amount[cnt].value.sub(_updateAmount);                            
    //             } else {
    //                 treasuryWallet.amount[cnt].value = treasuryWallet.amount[cnt].value.add(_updateAmount);
    //             }
    //             isToken = true;
    //         }
    //     }
    //     if(isToken == false) {
    //         treasuryAmount memory perTreasury = treasuryAmount(_tokenAddress, _updateAmount);
    //         treasuryWallet.amount.push(perTreasury);
    //     }
    // }
}