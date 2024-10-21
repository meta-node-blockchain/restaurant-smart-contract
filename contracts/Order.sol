// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;
import "./interfaces/IMenu.sol";
import "./interfaces/IStaff.sol";
import "./interfaces/IManagement.sol";
import "./abstract/use_pos.sol";
import "./Management.sol";
contract CustomerOrder is UsePos{
    uint public orderNum;
    IManagement public MANAGEMENT;
    mapping(uint => Order[]) public mTableToOrders;
    mapping(uint => uint[]) public mTableToOrderIds;
    mapping(uint => Course[]) public mTableToCourses;
    mapping(uint => Payment) public mTableToPayment;
    mapping(uint => Course[]) public mOrderIdToCourses;
    mapping(uint => Order) public mIdToOrder;   //IdOrder => Order
    mapping(bytes32 => Payment) public mIdToPayment; //IdPayment =>Payment
    mapping(uint => mapping(uint => Course)) public mIdToCourse; //Table number => IdCourse => Course
    mapping(bytes32 => bytes) public mCallData;
    bytes32[] public paymentIds;
    Order[] public allOrders;
    address public MasterPool;
    address public Owner;
    IERC20 public SCUsdt;
    address public POS;
    uint public taxPercent; //8%->8
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
        string[] memory dishCodes,
        string[] memory notes
    )internal returns(bytes32){
        uint totalPrice;
        uint courseNum = dishCodes.length;
        Order memory order = Order({
            id: orderNum++,
            tableNum: _numTable,
            createdAt: block.timestamp
        });
        mTableToOrderIds[_numTable].push(order.id);
        mIdToOrder[order.id] = order;
        for(uint i;i<courseNum;i++){
            Dish memory dish = MANAGEMENT.GetDish(dishCodes[i]);
            Course memory course = Course({
                id: i,
                dish : dish,
                note : notes[i],
                status : COURSE_STATUS.ORDERD
            });
            mTableToCourses[_numTable].push(course);
            mOrderIdToCourses[order.id].push(course);
            mIdToCourse[_numTable][i] = course ;
            totalPrice += dish.price;
        }
        mTableToOrders[_numTable].push(order);
        uint[] memory orderIds = mTableToOrderIds[_numTable];
        Payment storage temPayment = mTableToPayment[_numTable];
        if (temPayment.id == bytes32(0)) {
            bytes32 paymentId = keccak256(abi.encodePacked(_numTable,block.timestamp));
            Payment memory payment = Payment({
                id : paymentId,
                tableNum : _numTable,
                orderIds : orderIds,
                foodCharge : totalPrice,
                tax : totalPrice * taxPercent / 100,
                tip : 0,
                discountAmount : 0,
                discountCode : "",
                customer : msg.sender,
                status : PAYMENT_STATUS.CREATED,
                createdAt : 0,
                method : "",
                comfirmed: false,
                reasonComfirm : ""
            });
            mTableToPayment[_numTable] = payment;
            paymentIds.push(paymentId);
            mIdToPayment[paymentId] = payment;
        }else{           
            temPayment.orderIds.push(order.id);
            temPayment.foodCharge += totalPrice;
            temPayment.tax += totalPrice * taxPercent / 100;
            mIdToPayment[temPayment.id] = temPayment;
        }
        allOrders.push(order);
        return temPayment.id;
    }
    function PayUSDT(uint _numTable, string memory _discountCode, uint _tip )external returns(bool){
        (Payment memory payment,uint total) = _pay(_numTable,_discountCode,_tip);
        payment.method = "USDT";
        require(SCUsdt.transferFrom(msg.sender, MasterPool, total), "Token transfer failed");
        payment.status = PAYMENT_STATUS.PAID;
        payment.createdAt = block.timestamp;
        emit Paid(_numTable,total,bytes32(0),block.timestamp);      
        return true;
    }
    function _pay(
        uint _numTable, 
        string memory _discountCode, 
        uint _tip
    )internal view returns(Payment memory payment,uint total ){
        payment = mTableToPayment[_numTable];
        require(payment.status == PAYMENT_STATUS.CREATED,"payment status is wrong");
        require(payment.foodCharge > 0,"payment is 0");
        (bool valid, string memory message,Discount memory discount) = _checkDiscountValid(_discountCode);
        require(valid,message);
        payment.discountAmount = payment.foodCharge * discount.discountPercent / 100;
        payment.discountCode = _discountCode;
        payment.tip = _tip;       
        total = payment.foodCharge + payment.tax - payment.discountAmount + payment.tip;
    }
    function _checkDiscountValid(string memory _discountCode)internal view returns(bool valid, string memory message ,Discount memory discount) {
        discount = MANAGEMENT.GetDiscount(_discountCode);
        if (discount.amountUsed == discount.amountMax){
            return (false, "Maximum number of discount code was reached",discount);
        }
        if (discount.active == false){
            return (false, "This discount was inactive",discount);
        }
        if (discount.from >= block.timestamp || discount.to <= block.timestamp){
            return (false, "time of this discount is not valid",discount);
        }
        return (true,"",discount);
    }
    function GetOrders(uint _numTable)external view returns(Order[] memory ){
        return mTableToOrders[_numTable];
    }
    function GetCoursesByOrderId(uint _idOrder) external view returns(Course[] memory){
        return mOrderIdToCourses[_idOrder];
    }
    function GetCoursesByTable(uint _numTable)external view returns(Course[]memory){
        // return _getCoursesByTable(_numTable);
        return mTableToCourses[_numTable];

    }
    function UpdateCourseStatus(
        uint _numTable,
        uint _orderId,
        uint _courseId,
        COURSE_STATUS _newStatus
    ) external returns(bool) {
        Course storage course = mIdToCourse[_numTable][_courseId];
        if (_newStatus == COURSE_STATUS.PREPARING){
            require(course.status == COURSE_STATUS.ORDERD,"Invalid Status");
        }
        if (_newStatus == COURSE_STATUS.SERVED){
            require(course.status == COURSE_STATUS.PREPARING,"Invalid Status");
        }
        course.status = _newStatus;
        Course[] storage coursesOrder = mOrderIdToCourses[_orderId];
        for(uint i; i < coursesOrder.length;i++){
            Course storage aCourseOrder = coursesOrder[i];
            if (_courseId == aCourseOrder.id){
                aCourseOrder.status = _newStatus;
            }
        }
        Course[] storage coursesTable = mTableToCourses[_numTable];
        for(uint i; i < coursesTable.length;i++){
            Course storage aCourseTable = coursesTable[i];
            if (_courseId == aCourseTable.id){
                aCourseTable.status = _newStatus;
            }
        }
        return true;
    }

    function GetPaymentDetail(uint _numTable)external view returns(Payment memory){
        return mTableToPayment[_numTable];
    }
    function GetInfoToPay(uint _numTable)external view returns(Course[]memory allCourses,uint foodCharge,uint tax){
        Payment memory payment = mTableToPayment[_numTable];
        foodCharge = payment.foodCharge;
        tax = payment.tax;
        // allCourses = _getCoursesByTable(_numTable);
        allCourses = mTableToCourses[_numTable];
        return (allCourses,foodCharge,tax);
    }
    // function _getCoursesByTable(uint _numTable)internal view returns(Course[]memory){
    //     Payment memory payment = mTableToPayment[_numTable];
    //     uint[] memory orderIds = payment.orderIds;
    //     uint count=0;
    //     for(uint i;i < orderIds.length;i++){
    //         uint orderId = orderIds[i];
    //         count += mOrderIdToCourses[orderId].length;
    //     }
    //     Course[]memory allCourses = new Course[](count);
    //     uint k=0;
    //     for(uint i;i < orderIds.length;i++){
    //         uint orderId = orderIds[i];
    //         Course[]memory courses = mOrderIdToCourses[orderId];
    //         for(uint j;j < courses.length;j++){
    //             allCourses[k] = courses[j];
    //             k++;
    //         }
    //     }
    //     return allCourses;
    // }
    function GetAllOrders()external view returns(Order[] memory){
        return allOrders;
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
        (Payment memory payment,uint total) = _pay(_numTable,_discountCode,_tip);
        payment.method = "VISA";
        require(
            paymentAmount >= total , 
            '{"from": "CustomerOrder.sol", "code": 8, "message": "Insufficient payment amount"}'
        );  
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
    function RefundRequest()external {

    }
    function Review()external {

    }
    function ComfirmPayment(uint _numTable)external {
        _resetTable(_numTable);
    }

    function _resetTable(uint _numTable)internal{
        delete mTableToCourses[_numTable];
        delete mTableToOrders[_numTable];
        delete mTableToOrderIds[_numTable];
        delete mTableToPayment[_numTable];
        // delete mIdToCourse[_numTable];
    }
}