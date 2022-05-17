// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TimeLock is Ownable {
    using SafeERC20 for IERC20;

    enum DepositType {
        ETH,
        ERC20
    }

    struct Deposit {
        IERC20 token;
        address payable receiver;
        address sender;
        uint256 amount;
        uint256 unlockTimeStamp;
        bool withdrawn;
    }

    mapping(address => uint256) public senderDepositCount;
    mapping(address => uint256) public receiverDepositCount;

    Deposit[] public deposits;

    event TokenDeposit(uint256 depositId);
    event TokenWithdrawal(uint256 depositId);

    // function depositAndLockETH(
    // address payable _withdrawer,
    // uint256 _amount,
    // uint256 _unlockTimeStamp
    // ) external payable returns (uint256) {
    // require(msg.value > 0, "No amount mentioned");
    // require(_unlockTimeStamp > block.timestamp, "Unlock timestamp is not in the future!");
    // }

    function depositERC20(
        IERC20 _token,
        address payable _receiver,
        uint256 _amount,
        uint256 _unlockTimeStamp
    ) external returns (uint256 _id) {
        require(
            _unlockTimeStamp > block.timestamp,
            "ERR__INVALID_TIME"
        );
        require(
            _token.allowance(msg.sender, address(this)) >= _amount,
            "ERR__NOT_ENOUGH_ALLOWANCE"
        );

        _token.transferFrom(msg.sender, address(this), _amount);

        Deposit memory newDeposit = Deposit(
            _token,
            _receiver,
            msg.sender,
            _amount,
            _unlockTimeStamp,
            false
        );

        deposits.push(newDeposit);
        uint256 id = deposits.length - 1;

        senderDepositCount[msg.sender]++;
        receiverDepositCount[_receiver]++;

        emit TokenDeposit(id);
        return id;
    }

    function withdrawTokens(uint256 _id) external {
        Deposit storage myDeposit = deposits[_id];
        // require(myDeposit, "ERR__INVALID_DEPOSIT_ID");
        require(
            block.timestamp >= myDeposit.unlockTimeStamp,
            "ERR__TOO_EARLY"
        );
        require(msg.sender == myDeposit.receiver, "ERR__INCORRECT_RECEIVER");
        require(!myDeposit.withdrawn, "ERR_ALREADY_WITHDRAWN");

        myDeposit.withdrawn = true;
        myDeposit.token.transfer(msg.sender, myDeposit.amount);
        emit TokenWithdrawal(_id);
    }

    function getDepositsByReceiver(address _receiver)
        external
        view
        returns (Deposit[] memory)
    {
        Deposit[] memory results = new Deposit[](
            receiverDepositCount[_receiver]
        );
        uint256 counter = 0;

        for (uint256 i = 0; i < deposits.length; i++) {
            if (deposits[i].receiver == _receiver) {
                results[counter] = deposits[i];
                counter++;
            }
        }
        return results;
    }

    function getDepositsBySender(address _sender)
        external
        view
        returns (Deposit[] memory)
    {
        Deposit[] memory results = new Deposit[](senderDepositCount[_sender]);
        uint256 counter = 0;

        for (uint256 i = 0; i < deposits.length; i++) {
            if (deposits[i].sender == _sender) {
                results[counter] = deposits[i];
                counter++;
            }
        }

        return results;
    }
}
