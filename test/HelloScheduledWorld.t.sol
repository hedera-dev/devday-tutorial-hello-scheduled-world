// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Test} from "forge-std/Test.sol";
import {HelloScheduledWorld} from "../src/HelloScheduledWorld.sol";

contract HelloScheduledWorldTest is Test {
    HelloScheduledWorld public hello;
    address public owner;
    address public user;

    function setUp() public {
        owner = address(this);
        user = makeAddr("user");
        hello = new HelloScheduledWorld{value: 10 ether}();
    }

    // ============ Initial State Tests ============

    function test_InitialState() public view {
        assertFalse(hello.isActive());
        assertEq(hello.interval(), 0);
        assertEq(bytes(hello.message()).length, 0);
    }

    function test_InitialBalance() public view {
        assertEq(address(hello).balance, 10 ether);
    }

    // ============ Receive HBAR Tests ============

    function test_ReceiveHBAR() public {
        uint256 balanceBefore = address(hello).balance;
        payable(address(hello)).transfer(1 ether);
        assertEq(address(hello).balance, balanceBefore + 1 ether);
    }

    // ============ Stop Scheduling Tests ============

    function test_StopWhenNotActive() public {
        // Should not revert, just sets isActive to false
        hello.stopScheduling();
        assertFalse(hello.isActive());
    }

    // ============ Print Message Tests ============

    function test_RevertWhen_PrintNotActive() public {
        vm.expectRevert("Not active");
        hello.printMessage();
    }

    // ============ Fuzz Tests ============

    function testFuzz_ReceiveHBAR(uint256 amount) public {
        amount = bound(amount, 0, 100 ether);
        uint256 balanceBefore = address(hello).balance;
        deal(address(this), amount);
        payable(address(hello)).transfer(amount);
        assertEq(address(hello).balance, balanceBefore + amount);
    }
}
