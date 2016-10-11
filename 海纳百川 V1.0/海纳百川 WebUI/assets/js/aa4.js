function memApply() {
	var param = document.getElementById('memApply').value;
	var res = contracts['Hnbc'].contract.createCreditEvaluaters(param);
	if(res){
		alter("≥…π¶");
	}else{
		alter("…Í«Î ß∞‹£¨«Î÷ÿ ‘");
	}
}

function fileEva() {
	var param1 = document.getElementById('fileEva1').value;
	var param2 = document.getElementById('fileEva2').value;
	var param3 = document.getElementById('fileEva3').value;
	var param4 = document.getElementById('fileEva4').value;
	var param5 = document.getElementById('fileEva5').value;
	var res = contracts['Hnbc'].contract.evaluaterCreditFiles(param1,param2,param3,param4,param5);
	if(res){
		alter("∆¿π¿Õ®π˝");
	}else{
		alter("∆¿π¿ ß∞‹");
	}
}