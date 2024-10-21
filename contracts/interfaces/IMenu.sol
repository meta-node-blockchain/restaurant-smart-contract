// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;
enum TABLE_STATUS {
    EMPTY,
    BUSY,
    PAYING
}
enum PAYMENT_STATUS {
    CREATED,
    PAID,
    ABORT,
    REFUNDED
}
enum COURSE_STATUS {
    ORDERD,
    PREPARING,
    SERVED,
    CANCELED
}
struct Category{
    string code;
    string name;
    uint rank;
    string desc;
    bool active;
    string imgUrl;
    Dish[] dishes;
}   
struct Dish {
    string code;
    string nameCategory;
    string name;
    string des;
    uint price;
    bool available;
    bool active;
    string imgUrl;
}
struct Table {
    uint number;
    uint numPeople;
    TABLE_STATUS status;
    bytes32 paymentId;
    uint[] orders;
    bool active;
}
struct Course {
    uint id;
    Dish dish;
    string note;
    COURSE_STATUS status;
}
struct Order {
    uint id;
    uint tableNum;
    uint createdAt;
}
struct Discount{
    string code;
    string name;
    uint discountPercent;
    string desc;
    uint from;
    uint to;
    bool active;
    string imgURL;
    uint amountMax;
    uint amountUsed;
    uint updatedAt;   
}
struct Payment {
    bytes32 id;
    uint tableNum;
    uint[] orderIds;
    uint foodCharge;
    uint tax;
    uint tip;
    uint discountAmount;
    string discountCode;
    address customer;
    PAYMENT_STATUS status;
    uint createdAt;
    string method;
    bool comfirmed;
    string reasonComfirm;
}
