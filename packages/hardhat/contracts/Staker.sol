// SPDX-License-Identifier: MIT
pragma solidity 0.8.4; //Do not change the solidity version as it negativly impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

error SendFailed(); // 用send发送ETH失败error
error CallFailed(); // 用call发送ETH失败error

contract Staker {
    ExampleExternalContract public exampleExternalContract;
    mapping(address => uint256) public balances;
    uint256 public constant threshold = 1 ether;
    uint256 public deadline;
    bool public openForWithdraw;

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
        deadline = block.timestamp + 72 hours;
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    // ( Make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
    event Stake(address, uint256);

    function stake() public payable {
        require(timeLeft() > 0, "deadline passed, can't stake anymore");
        balances[msg.sender] = msg.value;
        emit Stake(msg.sender, msg.value);
    }

    // After some `deadline` allow anyone to call an `execute()` function
    // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`

    // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance
    function execute() external notCompleted {
        require(timeLeft() == 0, "can't execute before deadline");

        if (address(this).balance >= threshold) {
            exampleExternalContract.complete{value: address(this).balance}();
        } else {
            require(
                !openForWithdraw,
                "entered into withdraw mode, can't execute anymore"
            );
            // exampleExternalContract.complete{value: address(this).balance}();
            openForWithdraw = true;
        }
    }

    function withdraw() public notCompleted {
        require(openForWithdraw, "do not allow withdraw if not withdraw mode");
        require(
            balances[msg.sender] > 0,
            "user didn't stake or has withdrawn already"
        );
        payable(msg.sender).transfer(balances[msg.sender]);
    }

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
    function timeLeft() public view returns (uint256) {
        return block.timestamp >= deadline ? 0 : deadline - block.timestamp;
    }

    // Add the `receive()` special function that receives eth and calls stake()
    receive() external payable {
        this.stake();
    }

    modifier notCompleted() {
        require(
            !exampleExternalContract.completed(),
            "entered into stake-completed mode, can't execute anymore"
        );
        _;
    }
}
