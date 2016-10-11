//Hnbc contract
contract Hnbc
{
    //保费对象
    struct Fee {
        uint usertype; //用户状态, 1：普通会员；2：第三方借款会员； 
        uint lastTime; //最后缴费日期
        uint allMoney;  //缴费总金额
        uint insuranceMoney; //申请保费总金额
        uint financingMoney; //理财总金额
        uint leftMoney;//当前余额
        uint exists;//是否存在,1存在
    }

    //申请保费理赔对象
    struct Insurance {   
        address applyAddr; //申请人地址
        uint insuranceApply; //申请保险费总金额
        uint applyState; //申请状态 1，申请；2，申请成功; 3,向该用户支付成功; 4,申请失败
        uint insurancePay;//成功支付金额
        address insuranceChecker; //保费资料审核人地址
        bytes32 applyData; //申请资料信息hash值
        uint exists;//是否存在,1存在
    }
    
    //申请互助借贷对象
    struct Financing {
        address applyAddr; //申请人地址
        uint financingApply; //申请理财总金额
        uint creditMoney; //信用评估后金额
        uint applyState; //申请状态 1，申请；2,担保成功; 3，申请成功; 4,向该用户支付成功; 5,申请失败
        uint financingPay;//成功支付金额
        uint returnMoney; //成功还款金额
        mapping(address => uint) feeInfoByAddr;// 支付人，支付金额
        address[] feeInfoKeys;//支付人的所有地址
        address creditEvaluater; //信用评估人地址
        address assureAddr; // 担保人地址
        bytes32 applyData; //申请资料信息hash值
        uint exists;//是否存在,1存在
    }
    
    //保险审核人对象
    struct InsuranceChecker {
        bytes32[] insurancesKeys;//合约编号
        uint exists;//是否存在,1存在
    }
    
    //信用评估人对象
    struct CreditEvaluater {
        bytes32[] financingKeys;//合约编号
        uint exists;//是否存在,1存在
    }

    address public organizer; //合约创始人
    uint public minTicket;//最小入会费
    uint public minFee;//最小每月会费
    uint public totalAllMoney;  //系统缴费总金额
    uint public totalInsuranceMoney; //系统保费支付总金额
    uint public totalFinancingMoney; //系统借贷支付总金额
    mapping(address => InsuranceChecker) public insuranceCheckers;//用于保存保费索赔资料审核人信息,uint为该审核人已审核人数
    mapping(address => CreditEvaluater) public creditEvaluaters;//用于保存信用评估人信息,uint为该评估人已评估人数
    mapping(address => Fee) public fees;//用于存储用户缴纳保费信息
    address[] feeKeys;//用户存储所有type为1的用户的key值
    
    mapping(bytes32 => Insurance) public insurances;//用于存储申请保费理赔信息
    mapping(bytes32 => Financing) public financings;//用于存储申请借贷信息
    
    function Hnbc(uint _minTicket, uint _minFee) { 
        organizer = msg.sender;
        minTicket = _minTicket;
        minFee = _minFee;
        
        totalAllMoney = 0;
        totalInsuranceMoney = 0;
        totalFinancingMoney = 0;
    }
    
    
    
    //创建用户
    function createCommonUser(uint usertype) public returns (bool success) {
        if (usertype != 1 && usertype != 2){
            return false;
        }
        else if (fees[msg.sender].exists == 0 ){
            if (usertype == 1 || usertype == 2){
                fees[msg.sender].usertype = usertype;
                fees[msg.sender].allMoney = 0;
                fees[msg.sender].insuranceMoney = 0; 
                fees[msg.sender].financingMoney = 0;
                fees[msg.sender].leftMoney = 0;
                fees[msg.sender].exists = 1;
                if (usertype == 1) {
                    feeKeys.push(msg.sender);
                }
                return true;    
            } else {
            return false;
        }
        } else {
            return false;
        }
    }
    
    //创建保险材料审核用户
    function createInsuranceChecker(bytes32 info) public returns (bool success) {
        
        //保险材料审核人需要合约创建者一起加密
        if (info != sha3(organizer, msg.sender)) {
            return false;
        } else if (insuranceCheckers[msg.sender].exists != 0){
            return false;
        } else{
            insuranceCheckers[msg.sender].exists = 1;
            return true;
        }
    }
    
    //创建信用评估料审核用户
    function createCreditEvaluaters(bytes32 info) public returns (bool success) {
        
        //信用评估审核人需要合约创建者一起加密
        if (info != sha3(organizer, msg.sender)) {
            return false;
        } else if (creditEvaluaters[msg.sender].exists != 0){
            return false;
        } else{
            creditEvaluaters[msg.sender].exists = 1;
            return true;
        }
    }
    
    //缴纳入会费
    function payTicket(uint ticket) public returns (bool success) {
        
        if (ticket < minTicket) {
            return false;
        //如果该会员信息不存在或者为非标准会员
        } else if (fees[msg.sender].exists == 0){
            return false;
        } else {
            if (!organizer.send(ticket)) {
                throw;
            }
            fees[msg.sender].exists = 1;
            fees[msg.sender].allMoney = ticket;
            fees[msg.sender].leftMoney = ticket;
            fees[msg.sender].lastTime = now;
            totalAllMoney += ticket;
        }
    }
    

    //每月缴纳会费
    function payFee(uint fee) public returns (bool success)  {
        
        if (fee < minFee) {
            return false;
        } else if (fees[msg.sender].exists == 0 || fees[msg.sender].usertype != 1){
            return false;
            // 中间间隔30天
        } else if (now < fees[msg.sender].lastTime + 30 days){
            return false;
        } else {
            if (!organizer.send(fee)) {
                throw;
            }
            fees[msg.sender].allMoney += fee;
            fees[msg.sender].leftMoney += fee;
            fees[msg.sender].lastTime = now;
            totalAllMoney += fee;
        }
    }
    
    //申请保险理赔费用
    function  applyInsurance(uint insuranceApply) public returns (bytes32 applyId)  {
        
        if (fees[msg.sender].exists == 0){
            return 0;
        } else if (fees[msg.sender].usertype != 1){
            return 0;
        }
        // 必须正常缴费，通过最后缴费时间判断
        else if (now > fees[msg.sender].lastTime + 30 days){
            return 0;
        } else {
            bytes32 insuranceApplyId = sha3(msg.sender, insuranceApply, now);
            if (insurances[insuranceApplyId].exists == 0){
                //创建新保险对象
                insurances[insuranceApplyId].applyAddr = msg.sender;
                insurances[insuranceApplyId].insuranceApply = insuranceApply;
                insurances[insuranceApplyId].applyState = 1;
                insurances[insuranceApplyId].exists = 1;
                return insuranceApplyId;
            } else{
                return 0;
            }    
        }
    }
    
    //保险资料第三方确认审核
    function checkInsuranceFiles(bytes32 insuranceApplyId, address applyAddr, bytes32 applyData, uint applyState) public returns (bool success) {
        
        if (insurances[insuranceApplyId].exists != 1 || insurances[insuranceApplyId].applyState != 1){
            return false;
        } else if (insuranceCheckers[msg.sender].exists == 0){
            return false;
        //检测一下地址是否正确，是否是投保人地址
        } else if (insurances[insuranceApplyId].applyAddr != applyAddr){
            return false;
        } else {
            //applyState 只能为 2成功 或者 4失败
            if (applyState == 2 || applyState == 4){
                insuranceCheckers[msg.sender].insurancesKeys.push(insuranceApplyId);
                insurances[insuranceApplyId].insuranceChecker = msg.sender;
                insurances[insuranceApplyId].applyData = applyData;
                insurances[insuranceApplyId].applyState = applyState;
            }    
        }
    }
    
    //系统对用户进行保险扣费
    function chargeInsuranceMoney(bytes32 insuranceApplyId, address applyAddr) public returns (bool success) {
        
        if (insurances[insuranceApplyId].exists != 1){
            return false;
        } else if (msg.sender != organizer){
            return false;
        //检测一下地址是否正确，是否是投保人地址
        } else if (insurances[insuranceApplyId].applyAddr != applyAddr){
            return false;
        //只有当当前    applyState为2，申请成功的时候才能支付
        } else if (insurances[insuranceApplyId].applyState != 2){
            return false;
        }  else {
            
            Fee fee = fees[applyAddr];
            //计算当前可用投保总金额最高限制，最高个人账户2倍
            uint maxInsurance = (fee.allMoney - fee.insuranceMoney - fee.financingMoney)*2;
            uint availMoney = totalAllMoney - totalInsuranceMoney - totalFinancingMoney;
            //得到实际可以发放的额度，取小的
            uint sendMoney = maxInsurance;
            if (maxInsurance > insurances[insuranceApplyId].insuranceApply){
                sendMoney = insurances[insuranceApplyId].insuranceApply;
            }
            if (sendMoney > 0){
                //计算每个人平摊系数
                uint availTimes = availMoney / sendMoney;
                if (availTimes > 0){
                    //开始对每个人的账户进行扣费    
                    uint insurancePay = 0;
                    for (uint i = 1; i <= feeKeys.length; i++) {
                        address feeKey = feeKeys[i];    
                        //每个人缴费金额为当前余额除以分摊系数
                        uint payMoney = fees[feeKey].leftMoney/availTimes;
                        fees[feeKey].leftMoney -= payMoney;
                        insurancePay += payMoney;        
                    }
                    insurances[insuranceApplyId].applyState = 3;
                    insurances[insuranceApplyId].insurancePay = insurancePay;
                    fees[applyAddr].insuranceMoney += insurancePay;
                    totalInsuranceMoney += insurancePay;
                    applyAddr.send(insurancePay);                
                }
            }
        }
        
    }

    //申请借贷费用
    function  applyFinancing(uint financingApply) public returns (bytes32 applyId)  {
        
        if (fees[msg.sender].exists == 0){
            return 0;
        }
        // 如果type为1，则必须正常缴费，通过最后缴费时间判断
        else if (fees[msg.sender].usertype == 1 && now > fees[msg.sender].lastTime + 30 days){
            return 0;
        } else {
            bytes32 financingApplyId = sha3(msg.sender, financingApply, now);
            if (financings[financingApplyId].exists == 0){
                //创建新理财对象
                financings[financingApplyId].applyAddr = msg.sender;
                financings[financingApplyId].financingApply = financingApply;
                financings[financingApplyId].applyState = 1;
                financings[financingApplyId].exists = 1;
                //如果是普通用户，则自己给自己担保
                if (fees[msg.sender].usertype == 1){
                    financings[financingApplyId].assureAddr = msg.sender;
                    financings[financingApplyId].applyState = 2;
                }
                return financingApplyId;
            } else{
                return 0;
            }    
        }
    }

    //借贷用户第三方担保
    function financingAssure(bytes32 financingApplyId, address applyAddr) public returns (bool success) {
        if (financings[financingApplyId].exists != 1 || financings[financingApplyId].applyState != 1){
            return false;
        }
        //当前担保人必须正常缴费
        else if (now > fees[msg.sender].lastTime + 30 days){
            return false;
        //检测一下地址是否正确，是否是投保人地址
        } else if (financings[financingApplyId].applyAddr != applyAddr){
            return false;
        } else {
            financings[financingApplyId].assureAddr = msg.sender;
            financings[financingApplyId].applyState = 2;
        }
    }
        
    //借贷资料第三方信用评估确认审核
    function evaluaterCreditFiles(bytes32 financingApplyId, address applyAddr, bytes32 applyData, uint applyState, uint creditMoney) public returns (bool success) {
        //担保结束后才能审核
        if (financings[financingApplyId].exists != 1 || financings[financingApplyId].applyState != 2){
            return false;
        } else if (insuranceCheckers[msg.sender].exists == 0){
            return false;
        //检测一下地址是否正确，是否是投保人地址
        } else if (financings[financingApplyId].applyAddr != applyAddr){
            return false;
        } else {
            //applyState 只能为 3成功 或者 5失败
            if (applyState == 3 || applyState == 5){
                creditEvaluaters[msg.sender].financingKeys.push(financingApplyId);
                financings[financingApplyId].creditEvaluater = msg.sender;
                financings[financingApplyId].applyData = applyData;
                financings[financingApplyId].applyState = applyState;
                financings[financingApplyId].creditMoney = creditMoney;
            }    
        }
    }
    
    //系统对用户进行借款扣费
    function chargeFinancingMoney(bytes32 financingApplyId, address applyAddr) public returns (bool success) {
        
        if (financings[financingApplyId].exists != 1){
            return false;
        } else if (msg.sender != organizer){
            return false;
        //检测一下地址是否正确，是否是理财人地址
        } else if (financings[financingApplyId].applyAddr != applyAddr){
            return false;
        //只有当当前    applyState为3，申请成功的时候才能支付
        } else if (financings[financingApplyId].applyState != 3){
            return false;
        } else {
            //使用担保人的额度
            address assureAddr = financings[financingApplyId].assureAddr;
            Fee fee = fees[assureAddr];

            //计算当前可用理财总金额最高限制，最高个人账户5倍
            uint maxFinancing = (fee.allMoney - fee.insuranceMoney - fee.financingMoney)*5;        
            uint availMoney = totalAllMoney - totalInsuranceMoney - totalFinancingMoney;
            //得到实际可以发放的额度，取小的
            uint sendMoney = maxFinancing;
            if (maxFinancing > financings[financingApplyId].financingApply){
                if ( financings[financingApplyId].financingApply > financings[financingApplyId].creditMoney){
                    sendMoney = financings[financingApplyId].creditMoney;
                } else{
                    sendMoney = financings[financingApplyId].financingApply;
                } 
            } else if (maxFinancing  > financings[financingApplyId].creditMoney){
                sendMoney = financings[financingApplyId].creditMoney;
            } 
            
            if (sendMoney > 0){
                uint availTimes = availMoney / sendMoney;
                if (availTimes > 0){
                    //开始对每个人的账户进行扣费    
                    uint financingPay = 0;
                    for (uint i = 1; i <= feeKeys.length; i++) {
                        address feeKey = feeKeys[i];
                        //每个人缴费金额为当前余额除以分摊系数
                        uint payMoney = fees[feeKey].leftMoney/availTimes;
                        //设置每个人的支付金额            
                        financings[financingApplyId].feeInfoByAddr[feeKey] = payMoney;
                        financings[financingApplyId].feeInfoKeys.push(feeKey);                
                        fees[feeKey].leftMoney -= payMoney;
                        financingPay += payMoney;
                    }
                    financings[financingApplyId].applyState = 4;
                    financings[financingApplyId].financingPay = financingPay;
                    financings[financingApplyId].returnMoney = 0;
                    //担保人的额度增加
                    fees[assureAddr].financingMoney += financingPay;
                    totalFinancingMoney += financingPay;
                    applyAddr.send(financingPay);                
                }
            }
        }
        
    }

    //借款用户还款
    function returnFinancingMoney(bytes32 financingApplyId, uint returnMoney) public returns (bool success) {
        
        if (!organizer.send(returnMoney)) {
            throw;
        }
        if (financings[financingApplyId].exists != 1){
            return false;
        //检测一下地址是否正确，是否是借款人地址
        } else if (financings[financingApplyId].applyAddr != msg.sender){
            return false;
        //只有当当前 applyState为4，支付成功的时候才能还款
        } else if (financings[financingApplyId].applyState != 4){
            return false;
        }  else {
            //判断还剩下多少还款金额
            uint leftMoney = financings[financingApplyId].returnMoney;
            uint payMoney = leftMoney - returnMoney;
            //如果payMoney，则表示还清之后还有多余的钱，存入个人账户
            if (payMoney < 0){
                //先还leftMoney到债权人账户
                uint financingPay = 0;
                for (uint i = 1; i <= financings[financingApplyId].feeInfoKeys.length; i++) {
                    address feeKey = financings[financingApplyId].feeInfoKeys[i];
                    uint payReturnMoney = financings[financingApplyId].feeInfoByAddr[feeKey] / financings[financingApplyId].financingPay * leftMoney;
                    fees[feeKey].leftMoney += payReturnMoney;
                    financingPay += payReturnMoney;
                }
                payMoney = returnMoney - financingPay;
                //剩余的存入个人账户
                fees[msg.sender].leftMoney += payMoney;
            } else {
                //都换returnMoney到债权人个人账户
                financingPay = 0;
                i = 1;
                for (; i < financings[financingApplyId].feeInfoKeys.length; i++) {
                    feeKey = financings[financingApplyId].feeInfoKeys[i];
                    payReturnMoney = financings[financingApplyId].feeInfoByAddr[feeKey] / financings[financingApplyId].financingPay * returnMoney;
                    fees[feeKey].leftMoney += payReturnMoney;
                    financingPay += payReturnMoney;
                }        
                feeKey = financings[financingApplyId].feeInfoKeys[i];
                payReturnMoney = returnMoney - financingPay;
                fees[feeKey].leftMoney += payReturnMoney;
            }
            
        }
    }
    
    //查询本人资产情况
    function showUserAllMoney(address applyAddr) public returns (uint allMoney) {
        
        if (msg.sender != applyAddr){
            return 0;
        }
        else if (fees[msg.sender].exists == 0 || fees[msg.sender].usertype != 1){
            return fees[msg.sender].allMoney;
        }else {
            return 0;
        }
    }
    
    //查询本人保费理赔总金额情况
    function showUserInsuranceMoney(address applyAddr) public returns (uint insuranceMoney) {
        
        if (msg.sender != applyAddr){
            return 0;
        }
        else if (fees[msg.sender].exists == 0 || fees[msg.sender].usertype != 1){
            return fees[msg.sender].insuranceMoney;
        }else {
            return 0;
        }
    }
    
    //查询本人借款总金额情况
    function showUserFinancingMoney(address applyAddr) public returns (uint financingMoney) {
        
        if (msg.sender != applyAddr){
            return 0;
        }
        else if (fees[msg.sender].exists == 0 ){
            return fees[msg.sender].financingMoney;
        }else {
            return 0;
        }
    }
    
    //查询本人剩余资产情况
    function showUserLeftMoney(address applyAddr) public returns (uint leftMoney) {
        
        if (msg.sender != applyAddr|| fees[msg.sender].usertype != 1){
            return 0;
        }
        else if (fees[msg.sender].exists == 0 ){
            return fees[msg.sender].leftMoney;
        }else {
            return 0;
        }
    }
    
    function destroy() { // so funds not locked in contract forever
        if (msg.sender == organizer) { 
            suicide(organizer); // send funds to organizer
        }
    }
}