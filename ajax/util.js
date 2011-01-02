
function clearselect(sel, dis) {
    var obj = document.getElementById(sel);
    
    obj.selectedIndex = -1;
    for (i = obj.options.length -1; i >= 0; i--){
	obj.remove(i);
    }

    obj.disabled = dis;
}


var last_value = new Array();
var delay_timeouts   = new Array();

function delay_ajax(ident, handler, millisecs) {
    if (delay_timeouts[ident]) {
    	window.clearTimeout(delay_timeouts[ident]);
    }
    //   delay_timeouts[ident] = window.setTimeout( "_fire_ajax('" + ident + "', '" + handler + "')", millisecs);
    delay_timeouts[ident] = window.setTimeout( "_fire_ajax('" + ident +  "', '" + handler + "')", millisecs); 

}

function _fire_ajax(ident, handler) {
    var obj = document.getElementById(ident);


    if (last_value[ident] && last_value[ident] == obj.value) {
	// Do nothing
    }
    else {
	last_value[ident] = obj.value;

	OpenThought.CallUrl('ajax/' + handler + '.pl', ident);
    }
}