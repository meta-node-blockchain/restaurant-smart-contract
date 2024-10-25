// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;
import "./interfaces/IRestaurant.sol";
import "./interfaces/IManagement.sol";
import "./abstract/use_pos.sol";
import "./Management.sol";
import "forge-std/console.sol";
contract RestaurantOrder is UsePos{
    // uint public orderNum;
    IManagement public MANAGEMENT;
    mapping(uint => Order[]) public mTableToOrders;
    mapping(uint => bytes32[]) public mTableToOrderIds;
    mapping(uint => Course[]) public mTableToCourses;
    mapping(uint => Payment) public mTableToPayment;
    mapping(uint => mapping(uint => Course)) public mTableToIdToCourse; //Table number => IdCourse => Course
    mapping(uint => uint[]) public mTableToIdCourses; //Table number => []IdCourse 
    mapping(bytes32 => Course[]) public mOrderIdToCourses; //IdOrder => []Courses
    mapping(bytes32 => Order) public mIdToOrder;   //IdOrder => Order
    mapping(bytes32 => Payment) public mIdToPayment; //IdPayment =>Payment
    mapping(bytes32 => bytes) public mCallData;
    mapping(uint => bytes32 ) public mTableToIdPayment; // Table number => last IdPayment
    mapping(bytes32 => Course[]) public mPaymentIdToCourses; // paymentId => courses
    bytes32[] public paymentIds;
    Review[] public reviews;
    mapping(bytes32 => Review) public mIdToReview;
    Order[] public allOrders;
    Payment[] public historyPayments;
    address public MasterPool;
    address public Owner;
    IERC20 public SCUsdt;
    address public POS;
    uint public taxPercent; //8%->8
    mapping(address => bool) isStaff;
    event Paid(
        uint numberTable,
        uint totalCharge,
        bytes32 orderId,
        uint createdAt
    );
    constructor()payable{
        Owner = msg.sender;
        SCUsdt = IERC20(address(0x0000000000000000000000000000000000000002));
    }
    modifier onlyOwner() {
        require(
            Owner == msg.sender,
            '{"from": "Order.sol", "code": 1, "message": "Invalid caller-Only Owner"}'
        );
        _;
    }
    modifier onlyPOS() {
        require(
            msg.sender == POS,
            '{"from": "FiCam.sol", "code": 3, "message": "Only POS"}'
        );
        _;
    }
    modifier onlyStaff() {
        require(MANAGEMENT.isStaff(msg.sender), "Not a staff member");
        _;
    }
        //owner set
    function SetPOS(address _pos) external onlyOwner {
        POS = _pos;
    }
    function SetUsdt(address _usdt) external onlyOwner {
        SCUsdt = IERC20(_usdt);
    }
    function SetMasterPool(address _masterPool) external onlyOwner {
        MasterPool = _masterPool;
    }
    function SetTax(uint _taxPercent)external onlyOwner {
        taxPercent = _taxPercent;
    }
    function GetTax()external view returns(uint){
        return taxPercent;
    }
    function SetManangement(address _management) external onlyOwner {
        MANAGEMENT = IManagement(_management);
    }
    function MakeOrder(
        uint _numTable,
        OrderInput[] memory input
    )external returns(bytes32){
        require(input.length > 0, "Order input cannot be empty");
        uint totalPrice;
        Order memory order = Order({
            id: keccak256(abi.encodePacked(input.length,_numTable,block.timestamp)),
            tableNum: _numTable,
            createdAt: block.timestamp
        });
        mTableToOrderIds[_numTable].push(order.id);
        mIdToOrder[order.id] = order;
        uint len = mTableToCourses[_numTable].length;
        for(uint i; i < input.length; i++){
            Dish memory dish = MANAGEMENT.GetDish(input[i].dishCode);
            require(dish.available && dish.active ,"dish is unavailable or inactive");
            require(MANAGEMENT.IsDishEnough(input[i].dishCode,input[i].quantity),"dish not enough");
            Course memory course = Course({
                id: len + i+1,
                dish : dish,
                quantity : input[i].quantity,
                note : input[i].note,
                status : COURSE_STATUS.ORDERD
            });
            mTableToCourses[_numTable].push(course);
            mOrderIdToCourses[order.id].push(course);
            mTableToIdToCourse[_numTable][course.id] = course ;
            mTableToIdCourses[_numTable].push(course.id);
            totalPrice += dish.price * course.quantity; 
        }
        mTableToOrders[_numTable].push(order);
        Payment storage temPayment = mTableToPayment[_numTable];
        if (temPayment.id == bytes32(0)) {
            bytes32 paymentId = keccak256(abi.encodePacked(_numTable,block.timestamp));
            Payment memory payment = Payment({
                id : paymentId,
                tableNum : _numTable,
                orderIds : mTableToOrderIds[_numTable],
                foodCharge : totalPrice,
                tax : totalPrice * taxPercent / 100,
                tip : 0,
                discountAmount : 0,
                discountCode : "",
                customer : address(0),
                status : PAYMENT_STATUS.CREATED,
                createdAt : 0,
                method : "",
                staffComfirm: address(0),
                reasonComfirm : "",
                total:totalPrice + totalPrice * taxPercent / 100
            });
            mTableToPayment[_numTable] = payment;
            paymentIds.push(paymentId);
            mIdToPayment[paymentId] = payment;
        }else{           
            temPayment.orderIds.push(order.id);
            temPayment.foodCharge += totalPrice;
            temPayment.tax += totalPrice * taxPercent / 100;
            temPayment.total += (totalPrice + totalPrice * taxPercent / 100);
            mIdToPayment[temPayment.id] = temPayment;
        }
        allOrders.push(order);
        mTableToIdPayment[_numTable] = mTableToPayment[_numTable].id;
        return order.id;
    }
    function UpdateOrder(
        uint _numTable,
        bytes32 _orderId,
        uint[] memory _courseIds,
        uint[] memory _quantities
    )external returns(bool){
        require(_courseIds.length == _quantities.length,"number of course id should be equal to number of quantity");
        Payment storage payment = mTableToPayment[_numTable];         
        Course[] storage courseArr = mOrderIdToCourses[_orderId];
        Course[] storage courses = mTableToCourses[_numTable];
        for (uint i; i < _courseIds.length; i++) {
            for (uint j = 0; j < courseArr.length; j++) {
                if (courseArr[j].id == _courseIds[i]) {
                    if(courseArr[j].quantity == _quantities[i]){
                        break;
                    }
                    if(courseArr[j].quantity > _quantities[i]){ //minus quantity
                        uint diffPrice = (courseArr[j].quantity - _quantities[i]) * courseArr[j].dish.price;
                        payment.foodCharge -= diffPrice;
                        payment.tax -= diffPrice * taxPercent / 100;
                        payment.total -= diffPrice + diffPrice * taxPercent / 100;
                    }
                    if(courseArr[j].quantity < _quantities[i]){                              //add more quantity
                        uint diffPrice = (_quantities[i] - courseArr[j].quantity) * courseArr[j].dish.price;
                        payment.foodCharge += diffPrice;
                        payment.tax += diffPrice * taxPercent / 100;
                        payment.total += diffPrice + diffPrice * taxPercent / 100;
                    }                 
                    courseArr[j].quantity = _quantities[i];
                    break; 
                }
            }
            for (uint j = 0; j < courses.length; j++) {
                if (courses[j].id == _courseIds[i]) {
                    courses[j].quantity = _quantities[i];
                    break; 
                }
            }
        }
        mIdToPayment[payment.id] = payment;
        for(uint i; i < _courseIds.length; i++){
            Course storage course = mTableToIdToCourse[_numTable][_courseIds[i]];
            require(course.status == COURSE_STATUS.ORDERD,"course can not change anymore");
            course.quantity = _quantities[i];           
        }
        return true;       
    }
    function PayUSDT(uint _numTable, string memory _discountCode, uint _tip )external returns(bytes32){
        uint total = _pay(_numTable,_discountCode,_tip);
        Payment storage payment = mTableToPayment[_numTable];
        payment.method = "USDT";
        mIdToPayment[payment.id] = payment;
        require(SCUsdt.transferFrom(msg.sender, MasterPool, total), "Token transfer failed");      
        historyPayments.push(payment);
        emit Paid(_numTable,total,bytes32(0),block.timestamp);      
        return payment.id;
    }
    function _pay(
        uint _numTable, 
        string memory _discountCode, 
        uint _tip
    )internal returns(uint total ){
        Payment storage payment = mTableToPayment[_numTable];
        require(payment.status == PAYMENT_STATUS.CREATED,"payment status is wrong");
        require(payment.foodCharge > 0,"payment is 0");
        (bool valid, string memory message,Discount memory discount) = _checkDiscountValid(_discountCode);
        require(valid,message);
        payment.discountAmount = payment.foodCharge * discount.discountPercent / 100;
        payment.discountCode = _discountCode;
        payment.tip = _tip;  
        payment.total -= (payment.discountAmount - _tip);
        payment.status = PAYMENT_STATUS.PAID;
        payment.createdAt = block.timestamp;
        payment.customer = msg.sender;
        total = payment.foodCharge + payment.tax - payment.discountAmount + payment.tip;
        mPaymentIdToCourses[payment.id] = mTableToCourses[_numTable];
    }
    function _checkDiscountValid(string memory _discountCode)internal returns(bool valid, string memory message ,Discount memory discount) {
        discount = MANAGEMENT.GetDiscount(_discountCode);
        if (discount.amountUsed >= discount.amountMax){
            return (false, "Maximum number of discount code was reached",discount);
        }
        if (!discount.active){
            return (false, "This discount was inactive",discount);
        }
        if (discount.from > block.timestamp || discount.to < block.timestamp){
            return (false, "time of this discount is not valid",discount);
        }
        MANAGEMENT.UpdateDiscountCodeUsed(_discountCode);
        return (true,"",discount);
    }
    function GetOrders(uint _numTable)external view returns(Order[] memory ){
        return mTableToOrders[_numTable];
    }
    function GetCoursesByOrderId(bytes32 _idOrder) external view returns(Course[] memory){
        return mOrderIdToCourses[_idOrder];
    }
    function GetCoursesByTable(uint _numTable)external view returns(Course[]memory){
        return mTableToCourses[_numTable];
    }
    function GetAllOrders()external view returns(Order[] memory){
        return allOrders;
    }
    function GetIdCoursesByTable(uint _numTable) external view returns(uint[] memory) {
        return mTableToIdCourses[_numTable];
    }
    function GetCourseByTableAndIdCourse(uint _numTable,uint _idCourse) external view returns(Course memory){
        return mTableToIdToCourse[_numTable][_idCourse];
    }
    function UpdateCourseStatus(
        uint _numTable,
        bytes32 _orderId,
        uint _courseId,
        COURSE_STATUS _newStatus
    ) external onlyStaff returns(bool) {
        require(_newStatus != COURSE_STATUS.CREATED &&
                _newStatus != COURSE_STATUS.ORDERD,
                "course status of CREATED/ORDERED autonomically set when make a new order"
        );
        Course storage course = mTableToIdToCourse[_numTable][_courseId];
        if (
            (_newStatus == COURSE_STATUS.PREPARING && course.status != COURSE_STATUS.ORDERD) ||
            (_newStatus == COURSE_STATUS.SERVED && course.status != COURSE_STATUS.PREPARING)
        ) {
            revert("Invalid Status");
        }
        course.status = _newStatus;
        Course[] storage coursesOrder = mOrderIdToCourses[_orderId];
        for(uint i; i < coursesOrder.length;i++){
            if (_courseId == coursesOrder[i].id){
                coursesOrder[i].status = _newStatus;
                break;
            }
        }
        Course[] storage coursesTable = mTableToCourses[_numTable];
        for(uint i; i < coursesTable.length;i++){
            if (_courseId == coursesTable[i].id){
                coursesTable[i].status = _newStatus;
                break;
            }
        }
        return true;
    }
    function GetPaymentNotPaidByTable(uint _numTable)external view returns(Payment memory){
        return mTableToPayment[_numTable];
    }
    function GetPaymentById(bytes32 _idPayment)external view returns(Payment memory){
        return mIdToPayment[_idPayment];
    }
    function GetLastIdPaymentByTable(uint _numTable)external view returns(bytes32){
        return mTableToIdPayment[_numTable];
    }
    function GetPaymentHistory()external view returns(Payment[]memory){
        return historyPayments;
    }
    function GetCoursesByPaymentId(bytes32 _paymentId) external view returns(Course[] memory){
        return mPaymentIdToCourses[_paymentId];
    }
    function GetInfoToPay(uint _numTable)external view returns(Course[]memory allCourses,uint foodCharge,uint tax){
        Payment memory payment = mTableToPayment[_numTable];
        foodCharge = payment.foodCharge;
        tax = payment.tax;
        allCourses = mTableToCourses[_numTable];
        return (allCourses,foodCharge,tax);
    }
    function ExecuteOrder(
        bytes memory callData,
        bytes32 orderId,
        uint256 paymentAmount
    ) public override onlyPOS returns (bool) {
        (uint _numTable, string memory _discountCode,uint _tip) = abi.decode(
            callData,
            (uint, string,uint)
        );
        Payment storage payment = mTableToPayment[_numTable];
        uint total = _pay(_numTable,_discountCode,_tip);
        payment.method = "VISA";
        require(
            paymentAmount >= total , 
            '{"from": "CustomerOrder.sol", "code": 8, "message": "Insufficient payment amount"}'
        );  
        mIdToPayment[payment.id] = payment;
        historyPayments.push(payment);
        emit Paid(_numTable,total,orderId,block.timestamp);      
        return true;
    }
    function SetCallData(
        uint _numTable,
        string memory _discountCode,
        uint _tip
    )public returns(bytes32 idCallData){
        bytes memory callData = abi.encode(_numTable,_discountCode,_tip);
        idCallData = keccak256(abi.encodePacked(_numTable,msg.sender,block.timestamp));
        mCallData[idCallData] = callData;
        return idCallData;
    }
    function GetCallData(bytes32 _idCalldata)public view returns(bytes memory){
        return mCallData[_idCalldata];
    }
    function ComfirmPayment(uint _numTable,bytes32 _idPayment,string memory _reason)external onlyStaff returns(bool){
        Payment storage payment = mIdToPayment[_idPayment];
        require(payment.status == PAYMENT_STATUS.PAID,"Payment is not paid");
        payment.status = PAYMENT_STATUS.CONFIRMED_BY_STAFF;
        payment.staffComfirm = msg.sender;
        payment.reasonComfirm = _reason;
        mIdToPayment[payment.id] = payment;
        _resetTable(_numTable);
        return true;
    }
    function _resetTable(uint _numTable)internal{
        delete mTableToCourses[_numTable];
        delete mTableToOrders[_numTable];
        delete mTableToOrderIds[_numTable];
        delete mTableToPayment[_numTable];
        uint[] memory idCourses = mTableToIdCourses[_numTable];
        for(uint i; i < idCourses.length; i++){
            delete mTableToIdToCourse[_numTable][idCourses[i]];
        }
        delete mTableToIdCourses[_numTable];
    }
    function MakeReview(
        bytes32 _idPayment,
        uint8 _serviceQuality,
        uint8 _foodQuality,
        string memory _contribution,
        string memory _needAprove
    )external returns(bool){
        require(mIdToPayment[_idPayment].id != bytes32(0),"no payment was found");
        require(_serviceQuality >= 1 && _serviceQuality <=5 ,"service quality review from 1- 5 star");
        require(_foodQuality >= 1 && _foodQuality <=5 ,"food quality review from 1- 5 star");
        // require(mIdToPayment[_idPayment].customer == msg.sender,"not right customer of the payment to review");
        mIdToReview[_idPayment] = Review({           
            serviceQuality : _serviceQuality,
            foodQuality : _foodQuality,
            contribution : _contribution,
            needAprove : _needAprove
        });       
        reviews.push(mIdToReview[_idPayment]);
        return true;
    }
    function GetAllViews()external view returns(Review[] memory){
        return reviews;
    }
    function GetReviewByIdPayment(bytes32 _idPayment) external view returns(Review memory){
        return mIdToReview[_idPayment];
    }
    function RefundRequest()external {

    }

}