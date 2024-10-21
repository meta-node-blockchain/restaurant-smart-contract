// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;
import "./IMenu.sol";

interface IManagement {
    function GetDish(string memory _codeDish)external view returns(Dish memory);
    function GetTax()external view returns(uint);
    function GetDiscount(string memory _code)external view returns(Discount memory);
}