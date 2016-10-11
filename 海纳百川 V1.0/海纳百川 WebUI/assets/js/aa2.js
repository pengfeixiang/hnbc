function memApply() {
	var param = document.getElementById('memApply').value;
	var res = contracts['Hnbc'].contract.createCommonUser(param);
	if(res){
		alter("成功");
	}else{
		alter("申请失败，请重试");
	}
}

function inPay() {
	var param = document.getElementById('inPay').value;
	var res = contracts['Hnbc'].contract.payTicket(param);
	if(res){
		alter("缴费成功");
	}else{
		alter("缴费失败");
	}
}

function periodApply(){
	var param = document.getElementById('periodApply').value;
	var res = contracts['Hnbc'].contract.applyFinancing(param);
    alter(res);
}

function memRepay(){
	var param1 = document.getElementById('memRepay1').value;
	var param2 = document.getElementById('memRepay2').value;
	var res = contracts['Hnbc'].contract.returnFinancingMoney(param1，param2);
    if(res){
		alter("还款成功");
	}else{
		alter("还款失败");
	}
}

function myMoney2(){
	var param = document.getElementById('myMoney3').value;
	var res = contracts['Hnbc'].contract.showUserFinancingMoney(param);
    alter(res);
}