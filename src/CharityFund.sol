// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CharityFund is Ownable(msg.sender) {
    struct Fund {
        string cause;
        uint256 targetAmount;
        uint256 currentAmount;
        bool completed;
        uint256 createdAt;
    }

    Fund public fund;
    uint256 public refundPeriod;
    mapping(address => uint256) public donations;

    constructor(
        string memory _cause,
        uint256 _targetAmount,
        uint256 _refundPeriod
    ) {
        fund = Fund(_cause, _targetAmount, 0, false, block.timestamp);
        refundPeriod = _refundPeriod;
    }

    function isTimePast() public view returns (bool) {
        return fund.createdAt + refundPeriod < block.timestamp;
    }

    function donate() public payable {
        require(!fund.completed, "This fund has been completed.");
        fund.currentAmount += msg.value;
        donations[msg.sender] += msg.value;

        if (fund.currentAmount >= fund.targetAmount) {
            fund.completed = true;
        }
    }

    function getTotalDonations() public view returns (uint256) {
        return fund.currentAmount;
    }

    function getRemainingAmount() public view returns (uint256) {
        return fund.targetAmount - fund.currentAmount;
    }

    function isFundOpen() public view returns (bool) {
        return !fund.completed;
    }

    function getCreatedTime() public view returns (uint256){
        return fund.createdAt;
    }

    function refundDonation() public {
        require(!fund.completed, "This fund has been completed.");
        require(donations[msg.sender] > 0, "No donation to refund.");
        require(isTimePast(), "Time is not over.");

        uint256 amountToRefund = donations[msg.sender];
        donations[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: amountToRefund}("");
        require(success, "Failed to refund donation to donor.");
        fund.currentAmount -= amountToRefund;
    }
}
