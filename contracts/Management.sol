// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;
import "@openzeppelin/contracts@v4.9.0/access/AccessControl.sol";
import "./interfaces/IMenu.sol";
import "./interfaces/IStaff.sol";

contract Management is AccessControl {
    bytes32 public ROLE_ADMIN = keccak256("ROLE_ADMIN");
    bytes32 public ROLE_STAFF = keccak256("ROLE_STAFF");
    mapping(address => Staff) public mAddToStaff;
    Staff[] public staffs;
    mapping(uint => Table) public mNumberToTable;
    Table[] public tables;
    mapping(string => Category) public mCodeToCat;
    Category[]public categories;
    mapping(string => Dish) public mCodeToDish;
    mapping(string => Dish[]) public mCodeCatToDishes;
    mapping(string => Discount) public mCodeToDiscount;
    Discount[] public discounts;

    constructor()payable{
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
    //staff management

    function CreateStaff(
        Staff memory staff
    )external onlyRole(ROLE_ADMIN){
        require(staff.wallet != address(0),"wallet of staff is wrong");
        require(mAddToStaff[staff.wallet].wallet == address(0),"wallet existed");
        mAddToStaff[staff.wallet] = staff;
        staffs.push(staff);
    }
    function UpdateStaffInfo(
        address _wallet,
        string memory _name,
        string memory _code,
        string memory _phone,
        string memory _addr,
        ROLE _role,
        bool _active    
    )external onlyRole(ROLE_ADMIN) returns(bool){
        require(_wallet != address(0),"wallet of staff is wrong");
        Staff storage staff = mAddToStaff[_wallet];
        require(mAddToStaff[staff.wallet].wallet != address(0),"does not find any staff");
        staff.name = _name;
        staff.code = _code;
        staff.phone = _phone;
        staff.addr = _addr;
        staff.role = _role;
        staff.active = _active;
        return true;
    }
    function GetStaffInfo(address _wallet)external view onlyRole(ROLE_ADMIN) returns(Staff memory){
        return mAddToStaff[_wallet];
    }
    function GetAllStaffs()external view onlyRole(ROLE_ADMIN) returns(Staff[] memory){
        return staffs;
    }
    //table management

    function CreateTable(
        uint _number,
        uint _numPeople,
        bool _active
    )external onlyRole(ROLE_ADMIN){
        require(_number != 0,"Table number can not be 0");
        require(mNumberToTable[_number].number == 0,"this number existed");
        Table memory table = Table({
            number: _number,
            numPeople: _numPeople,
            status: TABLE_STATUS.EMPTY,
            paymentId: bytes32(0),
            orders: new uint[](0),
            active: _active
        });
        mNumberToTable[_number] = table;
        tables.push(table);
    }
    function UpdateTable(
        uint _number,
        uint _numPeople,
        bool _active
    )external onlyRole(ROLE_ADMIN){
        require(_number != 0,"Table number can not be 0");
        require(mNumberToTable[_number].number != 0,"this number table does not exist");
        mNumberToTable[_number].numPeople = _numPeople;
        mNumberToTable[_number].active = _active;
    }
    function GetAllTables()external view onlyRole(ROLE_ADMIN) returns(Table[] memory){
        return tables;
    }
    function GetTable(uint _number)external view onlyRole(ROLE_ADMIN) returns(Table memory){
        return mNumberToTable[_number];
    }
    //category management

    function CreateCategory(
        Category memory category
    )external onlyRole(ROLE_ADMIN){
        require(bytes(category.code).length >0,"category code can not be empty");
        require(
            bytes(mCodeToCat[category.code].code).length == 0,
            "category code existed"
        );
        Category storage cat = mCodeToCat[category.code];
        cat.code= category.code;
        cat.name= category.name;
        cat.rank= category.rank;
        cat.desc= category.desc;
        cat.active= category.active;
        cat.imgUrl= category.imgUrl;
        categories.push(cat);

    }
    function UpdateCategory(
        string memory _name,
        string memory _code,
        uint _rank,
        string memory _desc,
        bool _active,
        string memory _imgUrl
    )external onlyRole(ROLE_ADMIN){
        require(bytes(_code).length >0,"category code can not be empty");
        require(bytes(mCodeToCat[_code].code).length > 0,"category code does not exist");
        mCodeToCat[_code].name = _name;
        mCodeToCat[_code].rank = _rank;
        mCodeToCat[_code].desc = _desc;
        mCodeToCat[_code].active = _active;
        mCodeToCat[_code].imgUrl = _imgUrl;

    }
    function GetCategories()external view returns(Category[] memory){
        return categories;
    }
    function GetCategory(
        string memory _code
    )external view returns(Category memory){
        require(bytes(_code).length >0,"category code can not be empty");
        require(bytes(mCodeToCat[_code].code).length > 0 ,"category code does not exist");
        return mCodeToCat[_code];
    }
    //dish management

    function CreateDish(
        string memory _codeCategory,
        Dish memory dish
    )external onlyRole(ROLE_ADMIN){
        require(bytes(_codeCategory).length >0 && bytes(dish.code).length >0,"category code and dish code can not be empty");
        require(
            bytes(mCodeToCat[_codeCategory].code).length > 0,
            "category code does not exist"
        );
        Category storage category = mCodeToCat[_codeCategory];
        mCodeToDish[dish.code] = dish;
        category.dishes.push(dish);
        mCodeCatToDishes[_codeCategory].push(dish);
    }
    function UpdateDish(
        string memory _codeDish,
        string memory _nameCategory,
        string memory _name,
        string memory _des,
        uint _price,
        bool _available,
        bool _active,
        string memory _imgUrl
    )external onlyRole(ROLE_ADMIN){
        require(bytes(_codeDish).length >0,"category code can not be empty");
        require(
            bytes(mCodeToDish[_codeDish].code).length > 0,
            "does not find dish"
        );
        mCodeToDish[_codeDish].nameCategory = _nameCategory;
        mCodeToDish[_codeDish].name = _name;
        mCodeToDish[_codeDish].des = _des;
        mCodeToDish[_codeDish].price = _price;
        mCodeToDish[_codeDish].available = _available;
        mCodeToDish[_codeDish].active = _active;
        mCodeToDish[_codeDish].imgUrl = _imgUrl;
    }
    function GetDish(
        string memory _codeDish
    )external view returns(Dish memory){
        return mCodeToDish[_codeDish];
    }
    function GetDishes(
        string memory _codeCategory
    )external view returns(Dish[] memory){
        return mCodeCatToDishes[_codeCategory];
    }
    //discount management

    function CreateDiscount(
        Discount memory discount
    )external onlyRole(ROLE_ADMIN){
        require(bytes(discount.code).length >0,"code of discount can not be empty");
        require(bytes(mCodeToDiscount[discount.code].code).length == 0,"code of discount existed");
        mCodeToDiscount[discount.code] = discount;
        discounts.push(discount);
    }
    function UpdateDiscount(
        string memory _code,
        string memory _name,
        uint _discountPercent,
        string memory _desc,
        uint _from,
        uint _to,
        bool _active,
        string memory _imgURL,
        uint _amountMax,
        uint _amountUsed  
    )external onlyRole(ROLE_ADMIN){
        require(bytes(_code).length >0,"code of discount can not be empty");
        require(bytes(mCodeToDiscount[_code].code).length > 0,"can not find any discount");
        mCodeToDiscount[_code].name = _name;
        mCodeToDiscount[_code].discountPercent = _discountPercent;
        mCodeToDiscount[_code].desc = _desc;
        mCodeToDiscount[_code].from = _from;
        mCodeToDiscount[_code].to = _to;
        mCodeToDiscount[_code].active = _active;
        mCodeToDiscount[_code].imgURL = _imgURL;
        mCodeToDiscount[_code].amountMax = _amountMax;
        mCodeToDiscount[_code].amountUsed = _amountUsed;
    }
    function GetDiscount(
        string memory _code
    )external view returns(Discount memory){
        return mCodeToDiscount[_code];
    }
    function GetAllDiscounts()external view returns(Discount[] memory){
        return discounts;
    }
    // function GetHistoryPayment()external view returns(Dish[] memory){

    // }

}