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
    ABORT
}
enum METHOD {
    VISA,
    TOKEN
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
    Dish dish;
    string note;
    COURSE_STATUS status;
}
struct Order {
    uint Id;
    Course[] courses;
    uint TableNum;
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
}
struct Payment {
    bytes32 id;
    uint tableNum;
    Order[] orders;
    uint foodCharge;
    uint tax;
    uint tip;
    uint discountAmount;
    Discount discountInfo;
    address customer;
    PAYMENT_STATUS status;
    uint createdAt;
    METHOD method;
    string reasonComfirm;
}
