// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Uns721} from "../src/NftContract.sol";

contract UnsERC721Test is Test {
    Uns721 public token;
    address owner = address(0xABCD);
    address user = address(1);
    address nonWhiteListedUser = address(2);

    function setUp() public {
        token = new Uns721();
        address[] memory whiteListAddresses = new address[](1);
        whiteListAddresses[0] = user;
        token.updateWhiteList(whiteListAddresses); // Agrega al usuario a la whitelist
        token.updateMintWindows(false, true); // Solo abre la ventana de whitelist mint
        vm.deal(user, 1 ether); 
    }

    function testWhiteListMint() public {
        uint256 price = 0.001 ether;

        vm.deal(user, price);
        vm.prank(user);

        token.whiteListMint{value: price}();

        // Verificar el balance y el propietario del token
        assertEq(token.balanceOf(user), 1);
        assertEq(token.ownerOf(0), user);
    }


    function testWhiteListMintNotInWhitelist() public {
        uint256 price = 0.001 ether;

        vm.deal(nonWhiteListedUser, price);
        vm.prank(nonWhiteListedUser);

        vm.expectRevert("You're not in the whitelist");
        token.whiteListMint{value: price}();
    }

    function testWhiteListMintWindowClosed() public {
        uint256 price = 0.001 ether;

        token.updateMintWindows(false, false);

        vm.deal(user, price);
        vm.prank(user);

        vm.expectRevert("Window closed");
        token.whiteListMint{value: price}();
    }

    function testWhiteListMintInvalidAmount() public {
        uint256 invalidPrice = 0.0005 ether;

        vm.deal(user, invalidPrice);
        vm.prank(user);

        vm.expectRevert("Not enough ether send");
        token.whiteListMint{value: invalidPrice}();
    }

        function testPublicMint() public {
        uint256 price = 0.01 ether;

        // Abrir la ventana de public mint
        token.updateMintWindows(true, false);

        // Etiquetar el usuario
        vm.deal(user, price);
        vm.prank(user);

        // Ejecutar la función publicMint
        token.publicMint{value: price}();

        // Verificar el balance y el propietario del token
        assertEq(token.balanceOf(user), 1);
        assertEq(token.ownerOf(0), user);
    }

    function testPublicMintWindowClosed() public {
        uint256 price = 0.01 ether;

        // Etiquetar el usuario
        vm.deal(user, price);
        vm.prank(user);

        // Intentar ejecutar la función publicMint y esperar que falle
        vm.expectRevert("Window closed");
        token.publicMint{value: price}();
    }

    function testPublicMintInvalidAmount() public {
        uint256 invalidPrice = 0.005 ether;

        // Abrir la ventana de public mint
        token.updateMintWindows(true, false);

        // Etiquetar el usuario
        vm.deal(user, invalidPrice);
        vm.prank(user);

        // Intentar ejecutar la función publicMint y esperar que falle
        vm.expectRevert("Not enough ether send");
        token.publicMint{value: invalidPrice}();
    }

 function testMaxSupplyReached() public {
        uint256 price = 0.001 ether;

        token.updateMintWindows(false, true);

        // Asegurarse de que el usuario esté en la whitelist
        address[] memory whiteListAddresses = new address[](1);
        whiteListAddresses[0] = user;
        token.updateWhiteList(whiteListAddresses);

        // Etiquetar el usuario
        vm.deal(user, price * 5); // Suficiente ether para 5 minteos

        for (uint256 i = 0; i < 4; i++) {
            vm.prank(user);
            token.whiteListMint{value: price}();
        }

        // Intentar mintear otro token y esperar que falle
        vm.prank(user);
        vm.expectRevert("No more NFTs");
        token.whiteListMint{value: price}();
    }

    function testFail_UpdateMintWindowsAsNotOwner() public {
        vm.prank(address(0)); 
        token.updateMintWindows(false, true);
    }
}



