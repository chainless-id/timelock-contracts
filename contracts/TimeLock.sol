// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TimeLock is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    enum depositType {
        ETH,
        ERC20
    }

    struct lockedToken {
        IERC20 token;
        address payable withdrawer;
        uint256 amount;
        uint256 unlockTimeStamp;
        bool  withdrawn;
        bool deposited;
    }

    uint256 public depositsCount;
    mapping (address => uint256[]) public depositsByTokenAddress;
    mapping (address => uint256[]) public depositsByWithdrawers;
    mapping (uint256 => lockedToken) public vault;

    // userAdress -> tokenAddress -> token amount
    mapping (address => mapping (address => uint256)) public userTokenBalance;

    event tokenDepositComplete(address token, uint256 amount);
    event tokenWithdrawalComplete(address withdrawer, uint256 amount);

    // function depositAndLockETH(
    //     address payable _withdrawer,
    //     uint256 _amount,
    //     uint256 _unlockTimeStamp
    //     ) external payable returns (uint256) {
            
    //         require(msg.value > 0, "No amount mentioned");
    //         require(_unlockTimeStamp > block.timestamp, "Unlock timestamp is not in the future!");


    //         }

    function depositAndLockTokens(
        IERC20 _token,
        address payable _withdrawer, 
        uint256 _amount, 
        uint256 _unlockTimeStamp
        )
            external returns (uint256 _id) {

                require(_unlockTimeStamp > block.timestamp, "Unlock timestamp is not in the future!");
                require(_token.allowance(msg.sender, address(this)) >= _amount, "You should have more tokens than you wish to deposit");

                _token.transferFrom(msg.sender, address(this), _amount);

                userTokenBalance[msg.sender][address(_token)] += _amount;

                
                _id = ++depositsCount;
                vault[_id].token = _token;
                vault[_id].withdrawer = _withdrawer;
                vault[_id].amount = _amount;
                vault[_id].unlockTimeStamp = _unlockTimeStamp;
                vault[_id].withdrawn = false;
                vault[_id].deposited = true;

                depositsByTokenAddress[address(_token)].push(_id);
                depositsByWithdrawers[_withdrawer].push(_id);

                emit tokenDepositComplete(address(_token), _amount);

                return _id;
            }

    function withdrawTokens(uint256 _id) external {

        require(block.timestamp >= vault[_id].unlockTimeStamp, "Tokens are still locked!");
        require(msg.sender == vault[_id].withdrawer, "Not the withdrawer!");
        require(vault[_id].deposited, "Tokens are not yet deposited!");
        require(!vault[_id].withdrawn, "Tokens are already withdrawn!");

        vault[_id].withdrawn = true;

        userTokenBalance[msg.sender][address(vault[_id].token)] = userTokenBalance[msg.sender][address(vault[_id].token)].sub(vault[_id].amount);

        vault[_id].token.transfer(msg.sender, vault[_id].amount);

        emit tokenWithdrawalComplete(msg.sender, vault[_id].amount);
    }

    function getDepositsByWithdrawer(address _withdrawer) view external returns (uint256[] memory) {
        return depositsByWithdrawers[_withdrawer];
    }

    function getDepositsByTokenAddress(address _id) view external returns (uint256[] memory) {
        return depositsByTokenAddress[_id];
    }

}