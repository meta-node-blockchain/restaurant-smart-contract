// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;
import "@openzeppelin/contracts@v4.9.0/access/AccessControl.sol";
import "@openzeppelin/contracts@v4.9.0/token/ERC20/IERC20.sol";

import "./interfaces/IRestaurant.sol";

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
    mapping(string => bool) public isCodeExist;
    mapping(string => uint) public mDishRemain;
    constructor()payable{
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ROLE_ADMIN, msg.sender);
    }
    //staff management
    modifier onlyAdminAndStaff(){
        require(
            hasRole(ROLE_ADMIN, msg.sender) || hasRole(ROLE_STAFF, msg.sender),
            "Access denied: Requires ADMIN or STAFF role"
        );
        _;
    }
    function CreateStaff(
        Staff memory staff
    )external onlyRole(ROLE_ADMIN){
        require(staff.wallet != address(0),"wallet of staff is wrong");
        require(mAddToStaff[staff.wallet].wallet == address(0),"wallet existed");
        mAddToStaff[staff.wallet] = staff;
        staffs.push(staff);
    }
    function isStaff(address account) external view returns (bool) {
        return hasRole(ROLE_STAFF, account);
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
        for(uint i;i<staffs.length;i++){
            if(keccak256(abi.encodePacked(staffs[i].wallet ))== keccak256(abi.encodePacked(_wallet))){
                staffs[i] = staff;
            }
        }

        return true;
    }
    function GetStaffInfo(address _wallet)external view onlyAdminAndStaff returns(Staff memory){
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
            active: _active
        });
        mNumberToTable[_number] = table;
        tables.push(table);
    }
    function UpdateTable(
        uint _number,
        uint _numPeople,
        bool _active
    )external onlyRole(ROLE_ADMIN) returns(bool){
        require(_number != 0,"Table number can not be 0");
        require(mNumberToTable[_number].number != 0,"this number table does not exist");
        mNumberToTable[_number].numPeople = _numPeople;
        mNumberToTable[_number].active = _active;
        for(uint i;i<tables.length;i++){
            if(keccak256(abi.encodePacked(tables[i].number ))== keccak256(abi.encodePacked(_number))){
                tables[i] = mNumberToTable[_number];
            }
        }

        return true;
    }
    function GetAllTables()external view returns(Table[] memory){
        return tables;
    }
    function GetTable(uint _number)external view returns(Table memory){
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
        require(!isCodeExist[category.code],"code category exists");
        Category storage cat = mCodeToCat[category.code];
        cat.code= category.code;
        cat.name= category.name;
        cat.rank= category.rank;
        cat.desc= category.desc;
        cat.active= category.active;
        cat.imgUrl= category.imgUrl;
        categories.push(cat);
        isCodeExist[cat.code] = true;
    }
    function UpdateCategory(
        string memory _code,
        string memory _name,
        uint _rank,
        string memory _desc,
        bool _active,
        string memory _imgUrl
    )external onlyRole(ROLE_ADMIN) returns(bool){
        require(bytes(_code).length >0,"category code can not be empty");
        require(bytes(mCodeToCat[_code].code).length > 0,"category code does not exist");
        Category storage category = mCodeToCat[_code];
        category.name = _name;
        category.rank = _rank;
        category.desc = _desc;
        category.active = _active;
        category.imgUrl = _imgUrl;
        for(uint i;i<categories.length;i++){
            if(keccak256(abi.encodePacked(categories[i].code ))== keccak256(abi.encodePacked(_code))){
                categories[i] = category;
            }
        }
        return true;
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
        Dish memory dish,
        uint _quantity
    )external onlyRole(ROLE_ADMIN){
        require(bytes(_codeCategory).length >0 && bytes(dish.code).length >0,"category code and dish code can not be empty");
        require(
            bytes(mCodeToCat[_codeCategory].code).length > 0,
            "category code does not exist"
        );
        require(!isCodeExist[dish.code],"code dish exists");
        mCodeToDish[dish.code] = dish;
        mCodeCatToDishes[_codeCategory].push(dish);
        isCodeExist[dish.code] = true;
        mDishRemain[dish.code] = _quantity;
    }
    function IsDishEnough(
        string memory _dishCode,
        uint _quantity
    )external view returns(bool) {
        return _quantity <= mDishRemain[_dishCode];
    }
    function UpdateDish(
        string memory _codeCat,
        string memory _codeDish,
        string memory _nameCategory,
        string memory _name,
        string memory _des,
        uint _price,
        bool _available,
        bool _active,
        string memory _imgUrl
    )external onlyRole(ROLE_ADMIN) returns(bool){
        require(bytes(_codeDish).length >0 && bytes(_codeCat).length >0,"dish code and category code can not be empty");
        require(
            bytes(mCodeToDish[_codeDish].code).length > 0,
            "can not find dish"
        );
        Dish storage dish = mCodeToDish[_codeDish];
        dish.nameCategory = _nameCategory;
        dish.name = _name;
        dish.des = _des;
        dish.price = _price;
        dish.available = _available;
        dish.active = _active;
        dish.imgUrl = _imgUrl;
        _updateDishFromCat(_codeCat,_codeDish);
        return true;
    }
    function _updateDishFromCat(
        string memory _codeCat,
        string memory _codeDish  
    )internal{
        Dish[] storage dishes = mCodeCatToDishes[_codeCat];
        Dish storage dish = mCodeToDish[_codeDish];
        require(dishes.length > 0,"no dish in this category found");
        for(uint i; i < dishes.length; i++){
            if(keccak256(abi.encodePacked(dishes[i].code)) == keccak256(abi.encodePacked(_codeDish))){
                dishes[i] = dish;
                break;
            }
        }
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
    function UpdateDishStatus(
        string memory _codeCat,
        string memory _codeDish,
        bool _available
    ) external onlyRole(ROLE_STAFF) returns(bool) {
        require(bytes(mCodeToDish[_codeDish].code).length != 0,"can not find dish");
        mCodeToDish[_codeDish].available = _available;
        _updateDishFromCat(_codeCat,_codeDish);
        return true;
    }
    //discount management

    function CreateDiscount(
        string memory _code,
        string memory _name,
        uint _discountPercent,
        string memory _desc,
        uint _from,
        uint _to,
        bool _active,
        string memory _imgURL,
        uint _amountMax
    )external onlyRole(ROLE_ADMIN){
        require(bytes(_code).length >0,"code of discount can not be empty");
        require(bytes(mCodeToDiscount[_code].code).length == 0,"code of discount existed");
        mCodeToDiscount[_code] = Discount({
            code: _code ,
            name: _name ,
            discountPercent : _discountPercent,
            desc : _desc,
            from : _from,
            to : _to,
            active : _active,
            imgURL : _imgURL,
            amountMax : _amountMax,
            amountUsed : 0,
            updatedAt  : block.timestamp
        });
        discounts.push(mCodeToDiscount[_code]);
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
        uint _amountMax
    )external onlyRole(ROLE_ADMIN){
        require(bytes(_code).length >0,"code of discount can not be empty");
        require(bytes(mCodeToDiscount[_code].code).length > 0,"can not find any discount");
        require(_amountMax > 0 && _discountPercent > 0 ,"maximum number and percent of discount can be zero" );
        require(_discountPercent <= 100, "discount percent need to be less than 100");
        require(_from >= block.timestamp && _to > block.timestamp,"time is not valid");
        require(_amountMax >= mCodeToDiscount[_code].amountUsed , 
                "number of maximum can not be less than number discount used");
        mCodeToDiscount[_code].name = _name;
        mCodeToDiscount[_code].discountPercent = _discountPercent;
        mCodeToDiscount[_code].desc = _desc;
        mCodeToDiscount[_code].from = _from;
        mCodeToDiscount[_code].to = _to;
        mCodeToDiscount[_code].active = _active;
        mCodeToDiscount[_code].imgURL = _imgURL;
        mCodeToDiscount[_code].amountMax = _amountMax;
        for(uint i;i<discounts.length;i++){
            if(keccak256(abi.encodePacked(discounts[i].code ))== keccak256(abi.encodePacked(_code))){
                discounts[i] = mCodeToDiscount[_code];
            }
        }

    }
    function UpdateDiscountCodeUsed(string memory _code)external{
        mCodeToDiscount[_code].amountUsed += 1;
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