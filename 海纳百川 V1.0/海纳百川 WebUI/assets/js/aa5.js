function insureFile() {
	var param1 = document.getElementById('insureFile1').value;
    var param2 = document.getElementById('insureFile2').value;
	var res = contracts['Hnbc'].contract.chargeInsuranceMoney(param1,param2);
	if(res){
		alter("扣费成功");
	}else{
		alter("扣费失败");
	}
}

function periodFile() {
	var param1 = document.getElementById('periodFile1').value;
    var param2 = document.getElementById('periodFile2').value;
	var res = contracts['Hnbc'].contract.chargeFinancingMoney(param1,param2);
	if(res){
		alter("扣费成功");
	}else{
		alter("扣费失败");
	}
}
