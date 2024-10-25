// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;
import "./IRestaurant.sol";

interface IManagement {
    function GetDish(string memory _codeDish)external view returns(Dish memory);
    function GetDiscount(string memory _code)external view returns(Discount memory);
    function isStaff(address account) external view returns (bool);
    function UpdateDiscountCodeUsed(string memory _code)external;
    function IsDishEnough(string memory _dishCode,uint _quantity)external returns(bool);
}