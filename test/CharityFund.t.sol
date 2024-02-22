// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {DeployCharity} from "../../script/DeployCharity.s.sol";
import {CharityFund} from "../../src/CharityFund.sol";
import {Test, console} from "forge-std/Test.sol";

contract CharityFundTest is Test {
    CharityFund public charityFund;
    uint256 public TARGET_AMOUNT = 100 ether;
    uint256 public REFUND_PERIOD = 30;
    address owner;
    address donor;
    uint256 public constant STARTING_USER_BALANCE_10_ETH = 10 ether;

    function setUp() external {
        owner = msg.sender;
        donor = address(0x1);
        vm.deal(owner, STARTING_USER_BALANCE_10_ETH);
        vm.deal(donor, STARTING_USER_BALANCE_10_ETH);
        charityFund = new CharityFund(
            "Test Cause",
            TARGET_AMOUNT,
            REFUND_PERIOD
        );
    }

    function testRefund() public {
        uint256 balanceBeforeDonation = address(donor).balance;
        console.log(balanceBeforeDonation);

        uint256 donationsBefore = charityFund.getTotalDonations();
        console.log(donationsBefore);

        vm.startPrank(donor);
        vm.warp(block.timestamp);
        charityFund.donate{value: 5}();
        vm.stopPrank();

        uint256 balanceAfterDonation = address(donor).balance;
        console.log(balanceAfterDonation);

        uint256 donationsAfter = charityFund.getTotalDonations();
        console.log(donationsAfter);

        vm.startPrank(donor);
        vm.warp(block.timestamp + REFUND_PERIOD + REFUND_PERIOD);
        charityFund.refundDonation();
        vm.stopPrank();

        uint256 balanceAfterRefund = address(donor).balance;
        console.log(balanceAfterRefund);

        uint256 donationsAfterRefund = charityFund.getTotalDonations();
        console.log(donationsAfterRefund);

        assertEq(donationsBefore, donationsAfterRefund);
    }

    function testDonate() public {
        uint256 initialAmount = charityFund.getTotalDonations(); //0

        charityFund.donate{value: 5}(); //5

        uint256 afterDonation = charityFund.getTotalDonations(); //5

        assertEq(afterDonation, initialAmount + 5);
    }

    function testDonateExceedsTarget() public {
        uint256 remainingAmount = TARGET_AMOUNT;

        charityFund.donate{value: remainingAmount}();

        vm.expectRevert("This fund has been completed.");
        charityFund.donate{value: 1}();
    }

    function testGetAllDonations() public {
        charityFund.donate{value: 50 ether}();
        assertEq(charityFund.getTotalDonations(), 50 ether);
    }

    function testGetRemainingAmount() public {
        charityFund.donate{value: 50}();
        assertEq(
            charityFund.getRemainingAmount(),
            TARGET_AMOUNT - 50,
            "Remaining amount should be correct"
        );
    }

    function testIsFundOpen() public {
        assertTrue(charityFund.isFundOpen(), "Fund should be open initially");
    }

    function testCompleteFund_NotReached() public {
        charityFund.donate{value: TARGET_AMOUNT}();
        assertEq(charityFund.isFundOpen(), false);
    }

    function test_donate_nothing() public {
        vm.prank(donor);
        charityFund.donate{value: 0}();
        vm.expectRevert("No donation to refund.");
        charityFund.refundDonation();
    }

    function testCompleteFund() public {
        charityFund.donate{value: 10 ether}();
        assertEq(charityFund.isFundOpen(), true);
    }

    function testRefundAtCompletedFund() public {
        uint256 currentFund = charityFund.getTotalDonations();
        charityFund.donate{value: TARGET_AMOUNT - currentFund}();
        vm.expectRevert("This fund has been completed.");
        charityFund.refundDonation();
    }

    function testRefundFail() public {
        charityFund.donate{value: 50 ether}();
        vm.warp(block.timestamp + REFUND_PERIOD + REFUND_PERIOD);
        vm.expectRevert("Failed to refund donation to donor.");
        charityFund.refundDonation();
    }

    function testTimeIsNotOver() public {
        charityFund.donate{value: 50 ether}();
        vm.warp(block.timestamp - 1);
        vm.expectRevert("Time is not over.");
        charityFund.refundDonation();
    }

    function testIsTimePast() public {
        vm.startPrank(donor);
        uint256 donorCoinsBefore = address(donor).balance;
        charityFund.donate{value: 5}();
        vm.warp(block.timestamp + REFUND_PERIOD + REFUND_PERIOD);
        charityFund.refundDonation();
        uint256 donorCoinsAfter = address(donor).balance;
        assertEq(donorCoinsBefore, donorCoinsAfter);
        vm.stopPrank();
    }

    function testCurrentCreateTime() public {
        uint256 fundCreateTime = charityFund.getCreatedTime();
        uint256 timeRightNow = block.timestamp;
        console.log(fundCreateTime);
        console.log(timeRightNow);
        assertEq(fundCreateTime, timeRightNow);
    }

    function testGetCreatedTime() public {
        uint256 creationTime = charityFund.getCreatedTime();
        assertTrue(creationTime > 0, "Creation time should be greater than  0");
    }

    function testIsTimePastFunction() public {
       
        vm.warp(charityFund.getCreatedTime() + REFUND_PERIOD + REFUND_PERIOD);
        assertEq(charityFund.isTimePast(), true);

    }
}
