//SPDX-License-Identifier: MIT
 
pragma solidity ^0.8.18;
 
import {Script} from "forge-std/Script.sol";
import {CharityFund} from "../src/CharityFund.sol";
 
contract DeployCharity is Script {
    function run() external returns (CharityFund) {
        vm.startBroadcast();
        CharityFund charity = new CharityFund("Healthcare",  1000  ether,  30 days);
        vm.stopBroadcast();
        return charity;
    }
}
// make deploy ARGS="--network sepolia"