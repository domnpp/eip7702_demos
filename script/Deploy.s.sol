// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import "../src/SourceTok.sol";

contract Deploy is Script {
    // using stdJson for string;
    function run() external {
        vm.startBroadcast();
        // Just test the third contract

        SourceTok st = new SourceTok();
        RewardTok reward = new RewardTok(address(st));
        vm.stopBroadcast();

        string memory json = '{"SourceTok":"';
        json = string.concat(json, vm.toString(address(st)));
        json = string.concat(json, '","RewardTok":"');
        json = string.concat(json, vm.toString(address(reward)));
        json = string.concat(json, '"}');

        // console.log(vm.projectRoot());
        string memory filePath = string.concat(
            vm.projectRoot(),
            "/webapp-demo-eip7702/src/lib/contracts.json"
        );
        // console.log(filePath);
        // vm.writeJson(json, filePath);
        string memory artifacts_helper = string.concat(
            vm.projectRoot(),
            "/out/HelperApproveAndSwap.sol/HelperApproveAndSwap.json"
        );
        string memory file_contents = vm.readFile(artifacts_helper);
        vm.writeFile(
        string.concat(
                 vm.projectRoot(),
                 "/webapp-demo-eip7702/src/lib/HelperApproveAndSwap.json"
             ),file_contents
        
        );

        // vm.cp(
        //     artifacts_helper,
        //     string.concat(
        //         vm.projectRoot(),
        //         "/webapp-demo-eip7702/src/lib/HelperApproveAndSwap.json"
        //     )
        // );
    }
}
