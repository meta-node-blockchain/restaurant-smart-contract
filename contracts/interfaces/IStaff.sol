// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;
enum ROLE {
    STAFF,
    ADMIN
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
