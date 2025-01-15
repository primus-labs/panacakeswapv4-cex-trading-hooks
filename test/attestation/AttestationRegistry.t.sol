// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../src/attestation/AttestationRegistry.sol";
import "../../src/types/Common.sol";
import {Attestation as PrimusAttestation, AttNetworkRequest, AttNetworkResponseResolve, Attestor, IPrimusZKTLS} from "zkTLS-contracts/src/IPrimusZKTLS.sol";

contract AttestationRegistryTest is Test {
    AttestationRegistry private registry;
    IPrimusZKTLS private primusZKTLSMock;
    address private owner = address(0x123);
    address private feeRecipient = payable(address(0x456));
    uint256 private submissionFee = 0.01 ether;

    event FeeReceived(address sender, uint256 amount);
    event AttestationSubmitted(bytes32 attestationId, address recipient, string exchange, uint256 value, uint256 timestamp);

    function setUp() public {
        primusZKTLSMock = IPrimusZKTLS(address(new MockPrimusZKTLS()));
        registry = new AttestationRegistry(address(primusZKTLSMock), submissionFee, payable(feeRecipient));
        registry.transferOwnership(owner);
    }

    function testAddUrlToExchange() public {
        vm.prank(owner);
        registry.addUrlToExchange("https://example.com", "ExampleExchange");
        assertEq(registry.cexCheckList("https://example.com"), "ExampleExchange");
    }

    function stringToAddress(string memory _addressString) public pure returns (address) {
        bytes memory addressBytes = bytes(_addressString);
        require(addressBytes.length == 42, "Invalid address length");
        address addr;
        assembly {
            addr := mload(add(_addressString, 20)) // 从字符串中的偏移位置加载地址
        }
        return addr;
    }


    function testRemoveUrlToExchange() public {
        vm.prank(owner);
        registry.addUrlToExchange("https://example.com", "ExampleExchange");
        vm.prank(owner);
        registry.removeUrlToExchange("https://example.com");
        assertEq(bytes(registry.cexCheckList("https://example.com")).length, 0);
    }

    function testSubmitAttestation() public {
        vm.prank(owner);
        registry.addUrlToExchange("https://www.okx.com/v3/users/fee/trading-volume-progress", "okx");
        vm.prank(owner);
        registry.addExchangeToParsePath("okx", "$.data.requirements[1].currentVolume");
     
        AttNetworkRequest memory request = AttNetworkRequest({
            url: "https://www.okx.com/v3/users/fee/trading-volume-progress?t=1736757319823",
            header: "",
            method: "GET",
            body: ""
            });
        AttNetworkResponseResolve[] memory response = new AttNetworkResponseResolve[](1);
        response[0] = AttNetworkResponseResolve({
            keyName: "",
            parseType: "",
            parsePath: "$.data.requirements[1].currentVolume"
        });
        Attestor[] memory attestors = new Attestor[](1);
        address addr = stringToAddress("0xe02bd7a6c8aa401189aebb5bad755c2610940a73");
        attestors[0] = Attestor({
            attestorAddr: addr,
            url: "https://primuslabs.org"
        });
        bytes[] memory signas = new bytes[](1);
        signas[0] = bytes("0x2fccc45102cd1b46b3da6543e75ab906c768f1c5bd5adf6d1cd9cd1b305e0609746a373e92c4295be2d9b5f3dcf8623c2e369698e964ed9c10d658250a0d2f211c");
    
        PrimusAttestation memory attestation = PrimusAttestation({
            recipient: address(this),
            request: request,
            reponseResolve: response,
            data: "",
            attConditions: "[{\"op\":\">\",\"field\":\"$.data.requirements[1].currentVolume\",\"value\":\"100\"}]",
            timestamp: uint64(block.timestamp),
            additionParams: "",
            attestors: attestors,
            signatures: signas
        });
        vm.deal(address(this), 1 ether);
        vm.expectEmit(true, true, true, true);
        emit FeeReceived(address(this), submissionFee);

 
        vm.expectEmit(true, true, true, true);
        bytes32 expectedId = keccak256(
            abi.encodePacked(
                attestation.recipient,
                "https://www.okx.com/v3/users/fee/trading-volume-progress?t=1736757319823",
                "okx",
                "$.data.requirements[1].currentVolume",
                "100",
                attestation.timestamp
            )
        );
        emit AttestationSubmitted(expectedId, address(this), "okx", 100, attestation.timestamp);
      
        registry.submitAttestation{value: submissionFee}(attestation);
  

        Attestation[] memory savedAttestation = registry.getAttestationByRecipient(address(this));
        assertEq(savedAttestation[0].recipient, address(this));
        assertEq(savedAttestation[0].exchange, "okx");
        assertEq(savedAttestation[0].value, 100);
        assertEq(savedAttestation[0].timestamp, attestation.timestamp);
    }

     function testSubmitAttestation1() public {
        vm.prank(owner);
        registry.addUrlToExchange("https://www.binance.com/bapi/accounts/v1/private/vip/vip-portal/vip-fee/vip-programs-and-fees" ,"bsc");
        vm.prank(owner);
        registry.addExchangeToParsePath("bsc", "$.data.traderProgram.spotTrader.spotVolume30d");
        console.log("---1---");
        AttNetworkRequest memory request = AttNetworkRequest({
            url: "https://www.binance.com/bapi/accounts/v1/private/vip/vip-portal/vip-fee/vip-programs-and-fees",
            header: "",
            method: "GET",
            body: ""
            });
        AttNetworkResponseResolve[] memory response = new AttNetworkResponseResolve[](1);
        response[0] = AttNetworkResponseResolve({
            keyName: "",
            parseType: "",
            parsePath: "$.data.traderProgram.spotTrader.spotVolume30d"
        });
        Attestor[] memory attestors = new Attestor[](1);
        address addr = stringToAddress("0xe02bd7a6c8aa401189aebb5bad755c2610940a73");
        attestors[0] = Attestor({
            attestorAddr: addr,
            url: "https://primuslabs.org"
        });
        bytes[] memory signas = new bytes[](1);
        signas[0] = bytes("0x2fccc45102cd1b46b3da6543e75ab906c768f1c5bd5adf6d1cd9cd1b305e0609746a373e92c4295be2d9b5f3dcf8623c2e369698e964ed9c10d658250a0d2f211c");
    
        PrimusAttestation memory attestation = PrimusAttestation({
            recipient: address(this),
            request: request,
            reponseResolve: response,
            data: "",
            attConditions: "[{\"op\":\">\",\"field\":\"$.data.traderProgram.spotTrader.spotVolume30d\",\"value\":\"1000\"}]",
            timestamp: uint64(block.timestamp),
            additionParams: "",
            attestors: attestors,
            signatures: signas
        });
        vm.deal(address(this), 1 ether);
        vm.expectEmit(true, true, true, true);
        emit FeeReceived(address(this), submissionFee);

        vm.expectEmit(true, true, true, true);
        bytes32 expectedId = keccak256(
            abi.encodePacked(
                attestation.recipient,
                "https://www.binance.com/bapi/accounts/v1/private/vip/vip-portal/vip-fee/vip-programs-and-fees",
                "bsc",
                "$.data.traderProgram.spotTrader.spotVolume30d",
                "1000",
                attestation.timestamp
            )
        );
        emit AttestationSubmitted(expectedId, address(this), "bsc", 1000, attestation.timestamp);
        registry.submitAttestation{value: submissionFee}(attestation);
    

        Attestation[] memory savedAttestation = registry.getAttestationByRecipient(address(this));
        assertEq(savedAttestation[0].recipient, address(this));
        assertEq(savedAttestation[0].exchange, "bsc");
        assertEq(savedAttestation[0].value, 1000);
        assertEq(savedAttestation[0].timestamp, attestation.timestamp);
    }

    function testFailSubmitAttestationInsufficientFee() public {
        AttNetworkRequest memory request = AttNetworkRequest({
            url: "https://www.okx.com/v3/users/fee/trading-volume-progress?t=1736757319823",
            header: "",
            method: "GET",
            body: ""
            });
        AttNetworkResponseResolve[] memory response = new AttNetworkResponseResolve[](1);
        response[0] = AttNetworkResponseResolve({
            keyName: "",
            parseType: "",
            parsePath: "$.data.requirements[1].currentVolume"
        });

        Attestor[] memory attestors = new Attestor[](1);
        //address("0xe02bd7a6c8aa401189aebb5bad755c2610940a73")
        address addr = stringToAddress("0xe02bd7a6c8aa401189aebb5bad755c2610940a73");
        attestors[0] = Attestor({
            attestorAddr: addr,
            url: "https://primuslabs.org"
        });

        PrimusAttestation memory attestation = PrimusAttestation({
            recipient: address(this),
            request: request,
            reponseResolve: response,
            data: "",
            timestamp: uint64(block.timestamp),
            attConditions: "{\"value\":\"100\"}",
            additionParams: "",
            attestors: attestors,
            signatures: new bytes[](0)
        });

        vm.deal(address(this), 1 ether);
        registry.submitAttestation{value: submissionFee - 1}(attestation);
    }

    function testGetAttestationByRecipient() public {
        vm.prank(owner);
        registry.addUrlToExchange("https://example.com", "ExampleExchange");
        vm.prank(owner);
        registry.addExchangeToParsePath("ExampleExchange", "path/to/parse");
         AttNetworkRequest memory request = AttNetworkRequest({
            url: "https://example.com",
            header: "",
            method: "GET",
            body: ""
            });
        AttNetworkResponseResolve[] memory response = new AttNetworkResponseResolve[](1);
        response[0] = AttNetworkResponseResolve({
            keyName: "",
            parseType: "",
            parsePath: "path/to/parse"
        });


        PrimusAttestation memory attestation = PrimusAttestation({
            recipient: address(this),
            request: request,
            reponseResolve: response,
            data:"",
            timestamp: uint64(block.timestamp),
            additionParams: "",
            attConditions: "{\"value\":\"100\"}",
            attestors:  new Attestor[](0),
            signatures: new bytes[](0)
        });
        vm.deal(address(this), 1 ether);

        bytes32 attestationId = registry.submitAttestation{value: submissionFee}(attestation);

        Attestation[] memory attestations = registry.getAttestationByRecipient(address(this));
        assertEq(attestations.length, 1);
        assertEq(attestations[0].attestationId, attestationId);
    }
}

contract MockPrimusZKTLS is IPrimusZKTLS {
    function verifyAttestation(PrimusAttestation calldata) external pure override {}
}
