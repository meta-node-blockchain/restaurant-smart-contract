// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Management} from "../contracts/Management.sol";
import "../contracts/interfaces/IRestaurant.sol";
import {RestaurantOrder} from "../contracts/Order.sol";
import {USDT} from "../contracts/usdt.sol";
import {MasterPool} from "../contracts/MasterPool.sol";

contract RestaurantTest is Test {
    Management public MANAGEMENT;
    RestaurantOrder public ORDER;
    USDT public USDT_ERC;
    MasterPool public MONEY_POOL;
    uint256 ONE_USDT = 1_000_000;
    address public pos = address(0x11);
    address public Deployer = address(0x1);
    address admin = address(0x2);
    address staff1 = address(0x83CEC343cFc7A6644C1547277d26D7A621FDc40C);
    address staff2 = address(0xE730d4572f20A4d701EBb80b8b5aFA99b36d5e49);
    address customer = address(0x5);
    bytes32 public ROLE_ADMIN = keccak256("ROLE_ADMIN");
    bytes32 public ROLE_STAFF = keccak256("ROLE_STAFF");
    // bytes32 public DEFAULT_ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE");


    constructor() {
        vm.startPrank(Deployer);
        MANAGEMENT = new Management();
        ORDER = new RestaurantOrder();
        USDT_ERC = new USDT();
        MONEY_POOL = new MasterPool(address(USDT_ERC));
        ORDER.SetUsdt(address(USDT_ERC));
        ORDER.SetMasterPool(address(MONEY_POOL));
        ORDER.SetPOS(pos);
        ORDER.SetTax(8);
        ORDER.SetManangement(address(MANAGEMENT));
        vm.stopPrank();
        mintUSDT(customer,1_000_000);
        SetUpRestaurant();
    }
    function mintUSDT(address user, uint256 amount) internal {
        vm.startPrank(Deployer);
        USDT_ERC.mintToAddress(user, amount * ONE_USDT);
        vm.stopPrank();
    }
    function SetUpRestaurant()public{
        SetUpStaff();
        SetUpTable();
        SetUpCategory();
        SetUpDish();
        SetUpDiscount();
    }
    function SetUpStaff()public{
        vm.startPrank(Deployer);
        bytes32 role = MANAGEMENT.DEFAULT_ADMIN_ROLE();
        MANAGEMENT.grantRole(role,admin);
        vm.startPrank(admin);
        MANAGEMENT.grantRole(ROLE_ADMIN,admin);
        bytes memory bytesCodeCall = abi.encodeCall(
        MANAGEMENT.grantRole,
            (
               role,
               0x1c5A2B25f7483Ee4F6DcCbF0663E066D68C68ad7
            )
        );
        console.log("grantRole DEFAULT_ADMIN_ROLE:");
        console.logBytes(bytesCodeCall);
        console.log(
            "-----------------------------------------------------------------------------"
        );  
        bytesCodeCall = abi.encodeCall(
        MANAGEMENT.grantRole,
            (
               ROLE_ADMIN,
               0xF898fc3d62bFC36f613eb28dE3E20847B4B34d70
            )
        );
        console.log("grantRole ADMIN_ROLE:");
        console.logBytes(bytesCodeCall);
        console.log(
            "-----------------------------------------------------------------------------"
        );  
        Staff memory staff = Staff({
            wallet: staff1,
            name:"thuy",
            code:"NV1",
            phone:"0913088965",
            addr:"phu nhuan",
            role:ROLE.STAFF,
            active: true
        });
        MANAGEMENT.CreateStaff(staff);
        // bytes memory bytesCodeCall = abi.encodeCall(
        //     MANAGEMENT.CreateStaff,
        //     (
        //        staff
        //     )
        // );
        // console.log("CreateStaff 1:");
        // console.logBytes(bytesCodeCall);
        // console.log(
        //     "-----------------------------------------------------------------------------"
        // );  
        staff = Staff({
            wallet: staff2,
            name:"han",
            code:"NV2",
            phone:"0914526387",
            addr:"quan 7",
            role:ROLE.STAFF,
            active: true
        });
        MANAGEMENT.CreateStaff(staff);
        // bytesCodeCall = abi.encodeCall(
        //     MANAGEMENT.CreateStaff,
        //     (
        //        staff
        //     )
        // );
        // console.log("CreateStaff 2:");
        // console.logBytes(bytesCodeCall);
        // console.log(
        //     "-----------------------------------------------------------------------------"
        // );  

        Staff[] memory staffs = MANAGEMENT.GetAllStaffs();
        bytesCodeCall = abi.encodeCall(
            MANAGEMENT.GetAllStaffs,()
        );
        console.log("GetAllStaffs:");
        console.logBytes(bytesCodeCall);
        console.log(
            "-----------------------------------------------------------------------------"
        );  

        assertEq(staffs.length,2,"should be equal");
        Staff memory staffInfo = MANAGEMENT.GetStaffInfo(staff1);
        assertEq(staffInfo.name,"thuy","should be equal");
        assertEq(staffInfo.phone,"0913088965","should be equal");
        MANAGEMENT.grantRole(ROLE_STAFF,staff1);
        MANAGEMENT.UpdateStaffInfo(staff1,"thanh thuy","NV1","1111111111","phu nhuan",ROLE.STAFF,true);
        staffInfo = MANAGEMENT.GetStaffInfo(staff1);
        assertEq(staffInfo.name,"thanh thuy","should be equal");
        assertEq(staffInfo.phone,"1111111111","should be equal");
        bool kq = MANAGEMENT.isStaff(staff1);
        assertEq(kq,true,"should be equal"); 
        staffs = MANAGEMENT.GetAllStaffs();
        assertEq(staffs[0].name,"thanh thuy","should be equal");
        assertEq(staffs[0].phone,"1111111111","should be equal");

        MANAGEMENT.grantRole(ROLE_STAFF,staff2);
        // bytesCodeCall = abi.encodeCall(
        //     MANAGEMENT.hasRole,
        //     (
        //        DEFAULT_ADMIN_ROLE,
        //        0xF898fc3d62bFC36f613eb28dE3E20847B4B34d70
        //     )
        // );
        // console.log("hasRole DEFAULT_ADMIN_ROLE:");
        // console.logBytes(bytesCodeCall);
        // console.log(
        //     "-----------------------------------------------------------------------------"
        // );  
        // bytesCodeCall = abi.encodeCall(
        //     MANAGEMENT.hasRole,
        //     (
        //        ROLE_ADMIN,
        //        0xF898fc3d62bFC36f613eb28dE3E20847B4B34d70
        //     )
        // );
        // console.log("hasRole ROLE_ADMIN:");
        // console.logBytes(bytesCodeCall);
        // console.log(
        //     "-----------------------------------------------------------------------------"
        // );  

        // bytesCodeCall = abi.encodeCall(
        // MANAGEMENT.ROLE_ADMIN,()
        // );
        // console.log("ROLE_ADMIN:");
        // console.logBytes(bytesCodeCall);
        // console.log(
        //     "-----------------------------------------------------------------------------"
        // );  
        vm.stopPrank();
        
    }
    function SetUpTable()public {
        vm.startPrank(admin);
        MANAGEMENT.CreateTable(1,4,true);
        MANAGEMENT.CreateTable(2,6,true);
        MANAGEMENT.CreateTable(3,8,true);
        MANAGEMENT.CreateTable(4,4,true);
        Table[] memory tables = MANAGEMENT.GetAllTables();
        assertEq(tables.length,4,"should be equal");
        Table memory table3 = MANAGEMENT.GetTable(3);
        assertEq(table3.number,3,"should be equal");
        assertEq(table3.numPeople,8,"should be equal");
        MANAGEMENT.UpdateTable(3,6,true);
        table3 = MANAGEMENT.GetTable(3);
        assertEq(table3.numPeople,6,"should be equal");
        Table[] memory tablesUpdate = MANAGEMENT.GetAllTables();
        assertEq(tablesUpdate[2].numPeople,6,"should be equal");
        vm.stopPrank();
    }
    function SetUpCategory()public {
        vm.startPrank(admin);
        Category memory category1 = Category({
            code:"THITBO",
            name:"thit bo",
            rank:1,
            desc:"Cac mon voi thit bo",
            active:true,
            imgUrl:"_imgURL1"
        });
        MANAGEMENT.CreateCategory(category1);
        bytes memory bytesCodeCall = abi.encodeCall(
            MANAGEMENT.CreateCategory,
            (
               category1
            )
        );
        console.log("CreateCategory 1:");
        console.logBytes(bytesCodeCall);
        console.log(
            "-----------------------------------------------------------------------------"
        );  

        Category memory category2 = Category({
            code:"THITGA",
            name:"thit ga",
            rank:2,
            desc:"Cac mon voi thit ga",
            active:true,
            imgUrl:"_imgURL2"
        });
        MANAGEMENT.CreateCategory(category2);
        // bytesCodeCall = abi.encodeCall(
        //     MANAGEMENT.CreateCategory,
        //     (
        //        category2
        //     )
        // );
        // console.log("CreateCategory 2:");
        // console.logBytes(bytesCodeCall);
        // console.log(
        //     "-----------------------------------------------------------------------------"
        // );  
        Category[] memory categories = MANAGEMENT.GetCategories();
        // bytesCodeCall = abi.encodeCall(
        //     MANAGEMENT.CreateCategory,
        //     (
        //        category2
        //     )
        // );
        // console.log("GetCategories:");
        // console.logBytes(bytesCodeCall);
        // console.log(
        //     "-----------------------------------------------------------------------------"
        // );  
        assertEq(categories.length,2,"should be equal");
        Category memory cat2 = MANAGEMENT.GetCategory("THITGA");
        assertEq(cat2.name,"thit ga","should be equal");
        assertEq(cat2.imgUrl,"_imgURL2","should be equal");
        MANAGEMENT.UpdateCategory("THITGA","thit ga ta",1,"Cac mon voi thit ga",true,"_imgURL3");
        cat2 = MANAGEMENT.GetCategory("THITGA");
        // bytesCodeCall = abi.encodeCall(
        //     MANAGEMENT.UpdateCategory,
        //     (
        //        "THITBO","thit bo my",1,"Cac mon voi thit bo my",true,"_imgURL3"
        //     )
        // );
        // console.log("UpdateCategory :");
        // console.logBytes(bytesCodeCall);
        // console.log(
        //     "-----------------------------------------------------------------------------"
        // ); 
        // bytesCodeCall = abi.encodeCall(
        //     MANAGEMENT.GetCategory,
        //     (
        //        "THITBO"
        //     )
        // );
        // console.log("GetCategory :");
        // console.logBytes(bytesCodeCall);
        // console.log(
        //     "-----------------------------------------------------------------------------"
        // );  
        assertEq(cat2.name,"thit ga ta","should be equal");
        assertEq(cat2.imgUrl,"_imgURL3","should be equal");
        Category[] memory categoriesUpdate = MANAGEMENT.GetCategories();
        assertEq(categoriesUpdate[1].name,"thit ga ta","should be equal");
        assertEq(categoriesUpdate[1].imgUrl,"_imgURL3","should be equal");

        vm.stopPrank();
    }
    function SetUpDish()public {
        vm.startPrank(admin);
        Dish memory dish1 = Dish({
            code:"B001",
            nameCategory:"Thit bo",
            name:"Bo BBQ",
            des:"Thit bo nuong BBQ voi nhieu loai sot",
            price:50 * ONE_USDT,
            available:true,
            active:true,
            imgUrl:"img_bo1"
        });
        Dish memory dish2 = Dish({
            code:"B002",
            nameCategory:"Thit bo",
            name:"Bo nuong tang",
            des:"Thit bo nuong tang an kem phomai",
            price:100 * ONE_USDT,
            available:true,
            active:true,
            imgUrl:"img_bo2"
        });
        Dish memory dish3 = Dish({
            code:"G001",
            nameCategory:"Thit ga",
            name:"Ga luoc",
            des:"Thit ga luoc an kem com chien",
            price:300 * ONE_USDT,
            available:true,
            active:true,
            imgUrl:"img_ga1"
        });

        MANAGEMENT.CreateDish("THITBO",dish1,1000);
        bytes memory bytesCodeCall = abi.encodeCall(
            MANAGEMENT.CreateDish,
            (
               "THITBO",dish1,1000
            )
        );
        console.log("CreateDish 1:");
        console.logBytes(bytesCodeCall);
        console.log(
            "-----------------------------------------------------------------------------"
        );  
        MANAGEMENT.CreateDish("THITBO",dish2,200);
        bytesCodeCall = abi.encodeCall(
            MANAGEMENT.CreateDish,
            (
               "THITBO",dish2,200
            )
        );
        console.log("CreateDish 2:");
        console.logBytes(bytesCodeCall);
        console.log(
            "-----------------------------------------------------------------------------"
        );  

        MANAGEMENT.CreateDish("THITGA",dish3,500);
        bytesCodeCall = abi.encodeCall(
            MANAGEMENT.CreateDish,
            (
               "THITGA",dish3,500
            )
        );
        console.log("CreateDish 3:");
        console.logBytes(bytesCodeCall);
        console.log(
            "-----------------------------------------------------------------------------"
        );  

        Dish[] memory dishes = MANAGEMENT.GetDishes("THITBO");
        assertEq(dishes.length,2,"should be equal");
        Dish memory dish = MANAGEMENT.GetDish("B002");
        assertEq(dish.name,"Bo nuong tang","should be equal");
        assertEq(dish.price,100 * ONE_USDT,"should be equal");
        MANAGEMENT.UpdateDish(
            "THITBO",
            "B002",
            "Thit bo",
            "Bo xong khoi",
            "Thit bo xong khoi an kem salad",
            200 * ONE_USDT,
            true,
            true,
            "img_bo2"
        );
        dish = MANAGEMENT.GetDish("B002");
        assertEq(dish.name,"Bo xong khoi","should be equal");
        assertEq(dish.price,200 * ONE_USDT,"should be equal");
        assertEq(dish.available,true,"should be equal");
        Dish[] memory dishesUpdate = MANAGEMENT.GetDishes("THITBO");
        assertEq(dishesUpdate[1].name,"Bo xong khoi","should be equal");
        assertEq(dishesUpdate[1].price,200 * ONE_USDT,"should be equal");
        assertEq(dishesUpdate[1].available,true,"should be equal");

        vm.stopPrank();
        vm.startPrank(staff1);
        MANAGEMENT.UpdateDishStatus("THITBO","B002",false);
        dish = MANAGEMENT.GetDish("B002");
        assertEq(dish.available,false,"should be equal");
        bool kq = MANAGEMENT.IsDishEnough("B002",100);
        assertEq(kq,true,"should be equal");
        kq = MANAGEMENT.IsDishEnough("B001",1001);
        assertEq(kq,false,"should be equal");
        vm.stopPrank();
    }
    function SetUpDiscount()public{
        vm.startPrank(admin);
        MANAGEMENT.CreateDiscount(
            "KM20",
            "Chuong trinh kmai mua thu",
            15,
            "Kmai giam 15% tren tong chi phi",
            block.timestamp,
            block.timestamp + 30 days,
            true,
            "_imgIRL",
            100
        );
        // bytes memory bytesCodeCall = abi.encodeCall(
        //     MANAGEMENT.CreateDiscount,
        //     (
        //         "KM20",
        //         "Chuong trinh kmai mua thu",
        //         20,
        //         "Kmai giam 15% tren tong chi phi",
        //         1730079957,    //8.46am 28/10/2024
        //         1730079957 + 365 days,
        //         true,
        //         "_imgIRL",
        //         100           
        //     )
        // );
        // console.log("CreateDiscount:");
        // console.logBytes(bytesCodeCall);
        // console.log(
        //     "-----------------------------------------------------------------------------"
        // );  

        Discount memory discount = MANAGEMENT.GetDiscount("KM20");
        assertEq(discount.amountMax,100,"should be equal");
        MANAGEMENT.UpdateDiscount(
            "KM20",
            "Chuong trinh kmai mua dong",
            20,
            "Kmai giam 20% tren tong chi phi",
            block.timestamp,
            block.timestamp + 30 days,
            true,
            "_imgIRL",
            200
        ); 
        discount = MANAGEMENT.GetDiscount("KM20");
        assertEq(discount.amountMax,200,"should be equal");
        Discount[] memory discounts = MANAGEMENT.GetAllDiscounts();
        assertEq(discounts.length,1,"should be equal");
        assertEq(discounts[0].amountMax,200,"should be equal");
        assertEq(discounts[0].discountPercent,20,"should be equal");
        vm.stopPrank();
    }
    function testMakeOrder()public{
        //order lan 1 table1
        OrderInput[] memory inputT1 = new OrderInput[](3);
        OrderInput memory inputB1 = OrderInput({
            dishCode : "B001",
            quantity:2,
            note:"medium"
        });
        inputT1[0] = inputB1;
        OrderInput memory inputB2 = OrderInput({
            dishCode : "G001",
            quantity:5,
            note:""
        });
        inputT1[1] = inputB2;
        OrderInput memory inputG1 = OrderInput({
            dishCode : "B001",
            quantity:2,
            note:"medium"
        });
        inputT1[2] = inputG1;
        bytes32 orderId1T1 = ORDER.MakeOrder(
            1,
            inputT1
        );
        bytes memory bytesCodeCall = abi.encodeCall(
            ORDER.MakeOrder,
            (
                1,
                inputT1  
            )
        );
        console.log("MakeOrder 1 table 1:");
        console.logBytes(bytesCodeCall);
        console.log(
            "-----------------------------------------------------------------------------"
        );  

        //order lan 2 table1
        inputT1 = new OrderInput[](1);
        OrderInput memory inputG2 = OrderInput({
            dishCode : "G001",
            quantity:10,
            note:""
        });
        inputT1[0] = inputG2;
        bytes32 orderId2T1 = ORDER.MakeOrder(
            1,
            inputT1
        );
        // bytesCodeCall = abi.encodeCall(
        //     ORDER.MakeOrder,
        //     (
        //         1,
        //         inputT1  
        //     )
        // );
        // console.log("MakeOrder 2 table 1:");
        // console.logBytes(bytesCodeCall);
        // console.log(
        //     "-----------------------------------------------------------------------------"
        // );  
        //order lan 1 table2
        OrderInput[] memory inputT2 = new OrderInput[](1);
        OrderInput memory inputB3 = OrderInput({
            dishCode : "B001",
            quantity:7,
            note:"rare"
        });
        inputT2[0] = inputB3;
        bytes32 orderId1T2 = ORDER.MakeOrder(
            2,
            inputT2
        );

        //order lan 1 table3
        OrderInput[] memory inputT3 = new OrderInput[](1);
        OrderInput memory inputB4 = OrderInput({
            dishCode : "B001",
            quantity:4,
            note:""
        });
        inputT3[0] = inputB4;
        bytes32 orderId1T3 = ORDER.MakeOrder(
            3,
            inputT3
        );
        //get orders
        Order[] memory orders1 = ORDER.GetOrders(1);
        assertEq(orders1.length,2,"should be equal");
        Order[] memory orders2 = ORDER.GetOrders(2);
        assertEq(orders2.length,1,"should be equal");
        Order[] memory allOrders = ORDER.GetAllOrders();
        bytesCodeCall = abi.encodeCall(
            ORDER.GetAllOrders,()
        );
        console.log("GetAllOrders:");
        console.logBytes(bytesCodeCall);
        console.log(
            "-----------------------------------------------------------------------------"
        );  

        assertEq(allOrders.length,4,"should be equal");

        //get courses
        Course memory course = ORDER.GetCourseByTableAndIdCourse(1,1);
        assertEq(course.quantity, 2);
        Course[] memory coursesByOrder1 = ORDER.GetCoursesByOrderId(orderId1T1);
        assertEq(coursesByOrder1.length,3,"should be equal");
        Course[] memory coursesByOrder3 = ORDER.GetCoursesByOrderId(orderId1T2);
        assertEq(coursesByOrder3.length,1,"should be equal");
        Course[] memory coursesByTable1 = ORDER.GetCoursesByTable(1);
        assertEq(coursesByTable1.length,4,"should be equal");
        (Course[]memory allCourses,uint foodCharge,uint tax) = ORDER.GetInfoToPay(1);
        assertEq(foodCharge,4700 * ONE_USDT);
        uint taxPercent = ORDER.GetTax();
        assertEq(tax,4700 * ONE_USDT * taxPercent/100);

        //update order table 1 order 1 more quantity
        assertEq(coursesByTable1[0].quantity,2,"should be equal");
        uint[] memory courseIds = ORDER.GetIdCoursesByTable(1); //[1,2,3,4]
        uint[] memory updateCourseIds = new uint[](1);
        updateCourseIds[0] = courseIds[0];
        uint[] memory updateQuantities = new uint[](1);
        updateQuantities[0]  = 3;
        ORDER.UpdateOrder(1,orderId1T1,updateCourseIds,updateQuantities);
        // bytesCodeCall = abi.encodeCall(
        //     ORDER.UpdateOrder,
        //     (
        //         1,orderId1T1,updateCourseIds,updateQuantities
        //     )
        // );
        // console.log("UpdateOrder table 1 order 1:");
        // console.logBytes(bytesCodeCall);
        // console.log(
        //     "-----------------------------------------------------------------------------"
        // );  

        course = ORDER.GetCourseByTableAndIdCourse(1,1);
        assertEq(course.quantity, 3);
        coursesByOrder1 = ORDER.GetCoursesByOrderId(orderId1T1);
        assertEq(coursesByOrder1[0].quantity,3);
        coursesByTable1 = ORDER.GetCoursesByTable(1);
        assertEq(coursesByTable1[0].quantity,3);
        (allCourses,foodCharge,tax) = ORDER.GetInfoToPay(1);
        assertEq(foodCharge,4750 * ONE_USDT);
        assertEq(tax,4750 * ONE_USDT * taxPercent/100);

        //update order table 1 order 1 less quantity
        updateCourseIds[0] = courseIds[3]; //4
        updateQuantities[0]  = 5;
        ORDER.UpdateOrder(1,orderId2T1,updateCourseIds,updateQuantities);
        (allCourses,foodCharge,tax) = ORDER.GetInfoToPay(1);
        assertEq(foodCharge,3250* ONE_USDT); //=(4750- 5*300)
        assertEq(tax,260* ONE_USDT); //=3250*8/100

        //pay by usdt table 1
        vm.startPrank(customer);
        USDT_ERC.approve(address(ORDER),1_000_000*ONE_USDT);
        uint tip = 5 *ONE_USDT;
        bytes32 idPayment = ORDER.PayUSDT(1,"KM20",tip);
        uint paymentAmount1 = foodCharge*80/100 +tax+ tip;
        assertEq(USDT_ERC.balanceOf(address(MONEY_POOL)),paymentAmount1);
        vm.stopPrank();
        bytesCodeCall = abi.encodeCall(
            ORDER.PayUSDT,
            (
                1,"KM20",tip
            )
        );
        console.log("PayUSDT table 1:");
        console.logBytes(bytesCodeCall);
        console.log(
            "-----------------------------------------------------------------------------"
        );  

        //pay by visa table 2
        vm.startPrank(pos);
        bytes32 idCalldata = ORDER.SetCallData(2,"KM20",tip);
        uint256 paymentAmount2 = (7*50*(80/100 + 8/100) + 5)*ONE_USDT;
        bytes memory getCallData = ORDER.GetCallData(idCalldata);
        ORDER.ExecuteOrder(getCallData,idCalldata,paymentAmount2);
        vm.stopPrank();

        //staff comfirm payment 1,2
        vm.startPrank(staff1);
        ORDER.ComfirmPayment(1,idPayment,"paid");
        Payment memory payment = ORDER.GetPaymentById(idPayment);
        assertEq(payment.staffComfirm,staff1);
        assertEq(payment.reasonComfirm,"paid");
        assertEq(payment.total,paymentAmount1,"total payment1 should be equal");
        vm.stopPrank();
        vm.startPrank(staff2);
        bytes32 idPayment2 = ORDER.GetLastIdPaymentByTable(2);
        ORDER.ComfirmPayment(2,idPayment2,"paid");
        payment = ORDER.GetPaymentById(idPayment2);
        assertEq(payment.staffComfirm,staff2);
        assertEq(payment.reasonComfirm,"paid");
        assertEq(payment.total,paymentAmount2,"total payment2 should be equal");

        //staff update course status
        uint _numTable = 3;
        bytes32 _orderId = orderId1T3;
        uint _courseId = 1;   
        ORDER.UpdateCourseStatus(_numTable,_orderId,_courseId,COURSE_STATUS.PREPARING);
        Course[] memory coursesByOrder4 = ORDER.GetCoursesByOrderId(orderId1T3);
        assertEq(uint(coursesByOrder4[0].status),uint(COURSE_STATUS.PREPARING),"should equal");
        coursesByOrder4 = ORDER.GetCoursesByTable(3);
        assertEq(uint(coursesByOrder4[0].status),uint(COURSE_STATUS.PREPARING),"should equal");
        Course memory courseByOrder4 = ORDER.GetCourseByTableAndIdCourse(3,1);
        assertEq(uint(courseByOrder4.status),uint(COURSE_STATUS.PREPARING),"should equal");
        vm.stopPrank();

        //get history payments
        Payment[] memory payments = ORDER.GetPaymentHistory();
        assertEq(payments.length,2,"should equal");
        assertEq(payments[0].total,paymentAmount1,"total payment1 should be equal");
        assertEq(payments[1].total,paymentAmount2,"total payment2 should be equal");
        Course[] memory courseArr = ORDER.GetCoursesByPaymentId(payments[0].id);
        assertEq(courseArr.length,4,"should be equal");
        courseArr = ORDER.GetCoursesByPaymentId(payments[1].id);
        assertEq(courseArr.length,1,"should be equal");

        //customer review 
        vm.startPrank(customer);
        bytes32 _idPayment = payments[0].id;
        uint8 _serviceQuality = 4;
        uint8 _foodQuality = 5;
        string memory _contribution = "improve attitude";
        string memory _needAprove = "improve decoration";
        ORDER.MakeReview(_idPayment,_serviceQuality,_foodQuality,_contribution,_needAprove);
        vm.stopPrank();
    }

}