// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;
enum ROLE {
    STAFF,
    ADMIN
}
enum TABLE_STATUS {
    EMPTY,
    BUSY,
    PAYING
}
enum PAYMENT_STATUS {
    CREATED,
    PAID,
    CONFIRMED_BY_STAFF,
    ABORT,
    REFUNDED
}
enum COURSE_STATUS {
    CREATED,
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
    bool active;
}
struct Course {
    uint id;
    Dish dish;
    uint quantity;
    string note;
    COURSE_STATUS status;
}
struct Order {
    bytes32 id;
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
    bytes32[] orderIds;
    uint foodCharge;
    uint tax;
    uint tip;
    uint discountAmount;
    string discountCode;
    address customer;
    PAYMENT_STATUS status;
    uint createdAt;
    string method;
    address staffComfirm;
    string reasonComfirm;
    uint total;
}
struct Review {
    uint8 serviceQuality;
    uint8 foodQuality;
    string contribution;
    string needAprove;
}
struct OrderInput {
    string dishCode;
    uint quantity;
    string note;
}
struct Staff {
    address wallet;
    string name;
    string code;
    string phone;
    string addr;
    ROLE role;
    bool active;
}