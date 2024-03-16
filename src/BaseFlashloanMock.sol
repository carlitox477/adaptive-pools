// // SPDX-License-Identifier: GPL-2.0-or-later
// pragma solidity ^0.8.0;

// import {IERC20} from "./interfaces/IERC20.sol";
// import {IMorpho} from "../interfaces/IMorpho.sol";
// import {IMorphoFlashLoanCallback} from "../interfaces/IMorphoCallbacks.sol";

// contract FlashBorrowerMock is IMorphoFlashLoanCallback {
//     IMorpho private immutable MORPHO;

//     constructor(IMorpho newMorpho) {
//         MORPHO = newMorpho;
//     }

//     function flashLoan(address token, uint256 assets, bytes calldata data) external {
//         MORPHO.flashLoan(token, assets, data);
//     }

//     function onMorphoFlashLoan(uint256 assets, bytes calldata data) external {
//         require(msg.sender == address(MORPHO));
//         address token = abi.decode(data, (address));
//         IERC20(token).approve(address(MORPHO), assets);

//         // Add you logic here.
//         // e.g swap, liquidate, and much more...
//         //@audit add liquidity
//         //@audit swap del user
//         //@audit check del balance total si es suficiente para devolver el valor
//         //@audit en caso de que si
//         //@audit devolvemos
//         //@audit en caso de que no
//         //@audit llamamos un endpoint de trade (1inch, matcha, swap) minoutputamount + el balance del pool >= flashloan
//         //@audit devolvemos
//     }
// }