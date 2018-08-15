if (!String.prototype.trim) {
	String.prototype.trim = function () {
		return this.replace(/^[\s\xA0]+|[\s\xA0]+$/g, '');
	};
}

$(function(){

	//hide request body form field for GET/DELETE on accordion open
	$("#resources").on('shown.bs.collapse', function(e){
		var resource = $("#resources .in .resource");
		var method = resource.find('.reqMethod option:checked').html();
		if (method === 'GET' || method === 'DELETE'){
			resource.find('.reqBody').hide('fast');
			resource.find('.queryParams').addClass('active');
		}else{
			var args = window.taffy.resources[resource.data('beanName')][method.toLowerCase()];
			var ta = resource.find('.reqBody').show('fast').find('textarea');
			ta.val(JSON.stringify(args, null, 3));
			resource.find('.queryParams').removeClass('active');
		}
	});
	//hide request body form field for GET/DELETE on method change
	$(".resource .reqMethod").on('change', function(){
		var resource = $(this).closest('.resource');
		var method = resource.find('.reqMethod option:checked').html();
		if (method === 'GET' || method === 'DELETE' || method == 'OPTIONS'){
			resource.find('.reqBody').hide('fast');
		}else{
			var args = window.taffy.resources[resource.data('beanName')][method.toLowerCase()];
			var ta = resource.find('.reqBody').show('fast').find('textarea');
			ta.val(JSON.stringify(args, null, 3));
			resource.find('.queryParams').find('input').val('');
		}
	});

	$(".addParam").click(function(){
		var resource = $(this).closest('.resource')
			,params = resource.find('.queryParams');
		var tmpl = '<div class="qparam row form-group"><div class="col-md-4"><input class="form-control input-small paramName" /></div><div class="col-md-1 micro">=</div><div class="col-md-4"><input class="form-control input-small paramValue" /></div><div class="col-md-2"><button class="btn delParam" tabindex="-1">-</button></div></div>';
		params.append(tmpl);
	});

	$(".resource").on('click', '.delParam', function(){
		var row = $(this).closest('.row');
		row.remove();
	});

	//interpolate resource uri token values as they're typed
	$(".resource").on('keyup', 'input', function(e){
		var $this = $(this)
			,resource = $this.closest('.resource')
			,tokens = params( resource.find('.reqTokens form').serialize() )
			,q = qParams(resource)
			,uri = resource.data('uri')

		for (var t in tokens){
			if (tokens[t] === '')
				delete tokens[t];
		}
		var result = uri.supplant(tokens);
		result += (q.length) ? '?' + q : '';
		resource.find('.resourceUri').val(result);
	});

	$(".submitRequest").click(function(){
		var submit = $(this)
			,resource = submit.closest('.resource')
			,reset = resource.find('.resetRequest')
			,loading = resource.find('.progress')
			,response = resource.find('.response')
			,basicAuth = resource.find(".basicAuth");

		//validate tokens
		resource.find('.has-error').removeClass('has-error');
		var tokenErrors = resource.find('.tokenErrors');
		var tokens = resource.find('.reqTokens input');
		tokenErrors.empty();
		for (var t=0;t<tokens.length;t++){
			var tok = $(tokens[t]);
			if (tok.val().length === 0){
				tok.closest('.form-group').addClass('has-error').focus();
				tokenErrors.append('<div class="alert alert-danger">' + tok.attr('name') + ' is required</div>');
			}
		}
		if (resource.find('.reqTokens .has-error').length > 0){
			return false;
		}

		loading.show();
		submit.attr('disabled','disabled');

		response.hide();

		//interpolate the full request path
		var uri = resource.data('uri')
			,form = params( resource.find('.reqTokens form').serialize() )
			,path = uri.supplant(form);

		var verb = resource.find('.reqMethod option:checked').val();
		var body = (verb === 'GET' || verb === 'DELETE') ? qParams(resource) : resource.find('.reqBody textarea').val();
		var reqHeaders = resource.find('.requestHeaders').val().replace(/\r/g, '').split('\n');
		var headers = {
			Accept: resource.find('.reqFormat option:checked').val()
			,"Content-Type": (verb === 'GET' || verb === 'DELETE') ? "application/x-www-form-urlencoded" : "application/json"
		};
		for (var h in reqHeaders){
			var kv = reqHeaders[h].trim().split(':');
			if (kv[0].trim().length == 0){
				continue;
			}
			if (kv.length == 2){
				headers[ kv[0].trim() ] = kv[1].trim();
			}else if (kv.length == 1){
				headers [kv[0].trim() ] = "";
			}else{
				var k = kv.shift().trim();
				var v = kv.join(':').trim();
				headers[ k ] = v;
			}
		}

		var basicAuthUsername = basicAuth.find("input[name=username]").val();
		var basicAuthPassword = basicAuth.find("input[name=password]").val();

		if(basicAuthUsername.length && basicAuthPassword.length){
			headers["Authorization"] =  "Basic " + Base64.encode(basicAuthUsername + ":" + basicAuthPassword);
		}

		submitRequest(verb, path, headers, body, function(timeSpent, status, headers, body){
			loading.hide();
			submit.removeAttr('disabled');
			reset.show();
			headers = parseHeaders(headers);

			if (headers['content-type'].indexOf('application/json') > -1 || headers['content-type'].indexOf('text/json') > -1 || headers['content-type'].indexOf('application/vnd.api+json') > -1){
				//indentation!
				if (body.length){
					body = JSON.stringify(JSON.parse(body), null, 3);
					// only do syntax highlighting if hljs is defined
					if (typeof hljs === 'undefined') {
						body = body.split('\n')
									.join('<br/>')
									.replace(/\s/g,'&nbsp;');
					} else {
						// syntax highlight json and then replace spaces at the start of each line (or after <br/>) with &nbsp;
						body = hljs.highlight("json", body).value;
						body = body.split('\n')
									.join('<br/>')
									.replace(/(\<br\/\>)(\s+)/g, function(match, p1, p2, offset, string){
										return [p1, p2.replace(/\s/g,'&nbsp;')].join('');
									});
					}
				}
			}

			var headerRow = response.find('.responseHeaders');
			headerRow.empty();
			response.show();
			var sortable = [];
			for (var h in headers){
				sortable.push(h);
			}
			sortable.sort();
			for (var h in sortable){
				headerRow.append('<div class="row"><div class="col-md-5 headerName">' + sortable[h] + ':</div><div class="col-md-7 headerVal">' + headers[sortable[h]] + '</div></div>');
			}

			response.find('.responseTime').html('Request took ' + timeSpent + 'ms');
			response.find('.responseStatus').html(status);
			response.find('.responseBody').html(body);
		});

	});

	$(".resetRequest").click(function(){
		var reset = $(this)
			,resource = reset.closest('.resource')
			,response = resource.find('.response')
			,tokens = resource.find('.reqTokens form input')
			,params = resource.find('.queryParams input')
			,uri = resource.data('uri');

		response.hide();
		reset.hide();
		resource.find('.resourceUri').val(uri);

		tokens.each(function(){
			$(this).val('');
		});
		params.each(function(){
			$(this).val('');
		})
	});

});

function qParams(resource){
	var validParams = [];
	resource.find('.qparam').each(function(){
		var $this = $(this), n = $this.find('.paramName'), v = $this.find('.paramValue');
		var nameLen = n.val().length, valLen = v.val().length;
		if (nameLen && valLen){
			validParams.push(encodeURIComponent(n.val()) + '=' + encodeURIComponent(v.val()));
			$this.removeClass('has-error');
		}else{
			$this.addClass('has-error');
		}
	});
	return validParams.join('&');
}

function toggleStackTrace(id){
	console.log('toggling %s', id);
	$('#' + id).toggle();
}

function params(query){
	var parameters = {}, parameter;
	if (query.length > 1){
		query = query.split('&');
		for (var i = 0; i < query.length; i++) {
			parameter = query[i].split("=");
			if (parameter.length === 1) { parameter[1] = ""; }
			parameters[decodeURIComponent(parameter[0])] = decodeURIComponent(parameter[1]);
		}
	}
	return parameters;
}

function parseHeaders(h){
	var out = {};
	var chunks = h.toLowerCase().split('\n');
	for (var i=0,j=chunks.length; i<j; i++){
		var bits = chunks[i].split(': ');
		if (bits[0].length)
			out[bits[0].toLowerCase()] = bits[1];
	}
	return out;
}

String.prototype.supplant = function (o) {
	return this.replace(/{(.*?)(}(?=\/)|}$)/g,
		function (a, b) {
			// We need to split on the : if we're using custom token regular expressions.
			var r = o[ b.split(':')[ 0 ] ];
			return typeof r === 'string' || typeof r === 'number' ? r : a;
		}
	);
};

/**
*
*  Base64 encode / decode
*  http://www.webtoolkit.info/
*
**/
var Base64 = {

	// private property
	_keyStr : "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=",

	// public method for encoding
	encode : function (input) {
		var output = "";
		var chr1, chr2, chr3, enc1, enc2, enc3, enc4;
		var i = 0;

		input = Base64._utf8_encode(input);

		while (i < input.length) {

			chr1 = input.charCodeAt(i++);
			chr2 = input.charCodeAt(i++);
			chr3 = input.charCodeAt(i++);

			enc1 = chr1 >> 2;
			enc2 = ((chr1 & 3) << 4) | (chr2 >> 4);
			enc3 = ((chr2 & 15) << 2) | (chr3 >> 6);
			enc4 = chr3 & 63;

			if (isNaN(chr2)) {
				enc3 = enc4 = 64;
			} else if (isNaN(chr3)) {
				enc4 = 64;
			}

			output = output +
			this._keyStr.charAt(enc1) + this._keyStr.charAt(enc2) +
			this._keyStr.charAt(enc3) + this._keyStr.charAt(enc4);

		}

		return output;
	},

	// public method for decoding
	decode : function (input) {
		var output = "";
		var chr1, chr2, chr3;
		var enc1, enc2, enc3, enc4;
		var i = 0;

		input = input.replace(/[^A-Za-z0-9\+\/\=]/g, "");

		while (i < input.length) {

			enc1 = this._keyStr.indexOf(input.charAt(i++));
			enc2 = this._keyStr.indexOf(input.charAt(i++));
			enc3 = this._keyStr.indexOf(input.charAt(i++));
			enc4 = this._keyStr.indexOf(input.charAt(i++));

			chr1 = (enc1 << 2) | (enc2 >> 4);
			chr2 = ((enc2 & 15) << 4) | (enc3 >> 2);
			chr3 = ((enc3 & 3) << 6) | enc4;

			output = output + String.fromCharCode(chr1);

			if (enc3 != 64) {
				output = output + String.fromCharCode(chr2);
			}
			if (enc4 != 64) {
				output = output + String.fromCharCode(chr3);
			}

		}

		output = Base64._utf8_decode(output);

		return output;
	},

	// private method for UTF-8 encoding
	_utf8_encode : function (string) {
		string = string.replace(/\r\n/g,"\n");
		var utftext = "";

		for (var n = 0; n < string.length; n++) {

			var c = string.charCodeAt(n);

			if (c < 128) {
				utftext += String.fromCharCode(c);
			}
			else if((c > 127) && (c < 2048)) {
				utftext += String.fromCharCode((c >> 6) | 192);
				utftext += String.fromCharCode((c & 63) | 128);
			}
			else {
				utftext += String.fromCharCode((c >> 12) | 224);
				utftext += String.fromCharCode(((c >> 6) & 63) | 128);
				utftext += String.fromCharCode((c & 63) | 128);
			}

		}

		return utftext;
	},

	// private method for UTF-8 decoding
	_utf8_decode : function (utftext) {
		var string = "";
		var i = 0;
		var c = c1 = c2 = 0;

		while ( i < utftext.length ) {

			c = utftext.charCodeAt(i);

			if (c < 128) {
				string += String.fromCharCode(c);
				i++;
			}
			else if((c > 191) && (c < 224)) {
				c2 = utftext.charCodeAt(i+1);
				string += String.fromCharCode(((c & 31) << 6) | (c2 & 63));
				i += 2;
			}
			else {
				c2 = utftext.charCodeAt(i+1);
				c3 = utftext.charCodeAt(i+2);
				string += String.fromCharCode(((c & 15) << 12) | ((c2 & 63) << 6) | (c3 & 63));
				i += 3;
			}

		}

		return string;
	}
}

function expandingFormElements(){

	var updateTabindexes = function(){
		var invisible_parent_class = '.expandable';
		var parent_visible_modifier_class = '.active';

		var nextTabIndex = 1;
		$('input,select,textarea,button').not('[type=hidden]').each(function(elem){
			var $elem = $( this );
			if ( $elem.parents( invisible_parent_class ).length > 0 ){
				//could be invisible...
				if ( $elem.parents( invisible_parent_class + parent_visible_modifier_class ).length > 0 ){
					//is visible, give it a tab index
					$elem.attr( 'tabindex', nextTabIndex );
					nextTabIndex++;
				}
			}else{
				$elem.attr( 'tabindex', nextTabIndex );
				nextTabIndex++;
			}
		});
	}

	var handleExpansion = function(e){
		var $this = $(this)
		   ,$target = $( $this.data('target') )
		   ,isVisible = $target.hasClass('active');

		if ( $this.is('a') ){

			e.preventDefault();
			if (isVisible){
				$target.removeClass('active');
				$this.closest('.hide-on-expand').show('fast');
			}else{
				$target.addClass('active');
				$this.closest('.hide-on-expand').hide('fast');
			}
			updateTabindexes();
			return false;

		}else if ( $this.is('input[type=checkbox]') ){

			if ( $this.prop('checked') ){
				$target.addClass('active');
			}else{
				$target.removeClass('active');
			}

		}else if ( $this.is('input[type=radio]') ){

			var expand = $this.data('expand') && $this.is(':checked');

			if ( expand ){
				$target.addClass('active');
			}else{
				$target.removeClass('active');
			}

		}else if ( $this.is('select') ){

			var selectedOption = $this.find('option:selected');
			var expand = selectedOption.data('expand');

			if ( expand ){
				$target.addClass('active');
			}else{
				$target.removeClass('active');
			}

		}else if ( $this.is('input[type=text]') ){

			if ( $this.val().trim().length > 0 ){
				$target.addClass('active');
			}else{
				$target.removeClass('active');
			}

		}

		updateTabindexes();
	}

	$('a.expander').on('click', handleExpansion);
	$('input.expander,select.expander').on('keyup change', handleExpansion);

	//initialize starting state of text fields
	$('input.expander,select.expander').each(function(){
		handleExpansion.apply(this);
	});
}
expandingFormElements();
