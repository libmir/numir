"use strict";
var items = [
{"numir.core" : "numir/core.html"},
{"numir.core.empty" : "numir/core.html#empty"},
{"numir.core.like" : "numir/core.html#like"},
{"numir.core.empty_like" : "numir/core.html#empty_like"},
{"numir.core.ones" : "numir/core.html#ones"},
{"numir.core.ones_like" : "numir/core.html#ones_like"},
{"numir.core.zeros" : "numir/core.html#zeros"},
{"numir.core.zeros_like" : "numir/core.html#zeros_like"},
{"numir.core.eye" : "numir/core.html#eye"},
{"numir.core.identity" : "numir/core.html#identity"},
{"numir.core.rank" : "numir/core/rank.html"},
{"numir.core.NestedElementType" : "numir/core/NestedElementType.html"},
{"numir.core.shapeNested" : "numir/core.html#shapeNested"},
{"numir.core.nparray" : "numir/core.html#nparray"},
{"numir.core.concatenate" : "numir/core.html#concatenate"},
{"numir.core.arange" : "numir/core.html#arange"},
{"numir.core.arange" : "numir/core.html#arange"},
{"numir.core.linspace" : "numir/core.html#linspace"},
{"numir.core.steppedIota" : "numir/core.html#steppedIota"},
{"numir.core.logspace" : "numir/core.html#logspace"},
{"numir.core.diag" : "numir/core.html#diag"},
{"numir.core.dtype" : "numir/core.html#dtype"},
{"numir.core.Ndim" : "numir/core/Ndim.html"},
{"numir.core.ndim" : "numir/core.html#ndim"},
{"numir.core.byteStrides" : "numir/core.html#byteStrides"},
{"numir.core.size" : "numir/core.html#size"},
{"numir.core.view" : "numir/core.html#view"},
{"numir.core.unsqueeze" : "numir/core.html#unsqueeze"},
{"numir.core.squeeze" : "numir/core.html#squeeze"},
{"numir.random" : "numir/random.html"},
{"numir.random.RNG" : "numir/random/RNG.html"},
{"numir.random.RNG.get" : "numir/random/RNG.html#get"},
{"numir.random.RNG.setSeed" : "numir/random/RNG.html#setSeed"},
{"numir.random.rand" : "numir/random.html#rand"},
{"numir.random.normal" : "numir/random.html#normal"},
{"numir.random.uniform" : "numir/random.html#uniform"},
{"numir.random.approxEqual" : "numir/random.html#approxEqual"},
{"numir" : "numir.html"},
];
function search(str) {
	var re = new RegExp(str.toLowerCase());
	var ret = {};
	for (var i = 0; i < items.length; i++) {
		var k = Object.keys(items[i])[0];
		if (re.test(k.toLowerCase()))
			ret[k] = items[i][k];
	}
	return ret;
}

function searchSubmit(value, event) {
	console.log("searchSubmit");
	var resultTable = document.getElementById("results");
	while (resultTable.firstChild)
		resultTable.removeChild(resultTable.firstChild);
	if (value === "" || event.keyCode == 27) {
		resultTable.style.display = "none";
		return;
	}
	resultTable.style.display = "block";
	var results = search(value);
	var keys = Object.keys(results);
	if (keys.length === 0) {
		var row = resultTable.insertRow();
		var td = document.createElement("td");
		var node = document.createTextNode("No results");
		td.appendChild(node);
		row.appendChild(td);
		return;
	}
	for (var i = 0; i < keys.length; i++) {
		var k = keys[i];
		var v = results[keys[i]];
		var link = document.createElement("a");
		link.href = v;
		link.textContent = k;
		link.attributes.id = "link" + i;
		var row = resultTable.insertRow();
		row.appendChild(link);
	}
}

function hideSearchResults(event) {
	if (event.keyCode != 27)
		return;
	var resultTable = document.getElementById("results");
	while (resultTable.firstChild)
		resultTable.removeChild(resultTable.firstChild);
	resultTable.style.display = "none";
}

