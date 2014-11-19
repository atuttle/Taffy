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
			resource.find('.queryParams').show('fast');
		}else{
			var args = window.taffy.resources[resource.data('beanName')][method.toLowerCase()];
			var ta = resource.find('.reqBody').show('fast').find('textarea');
			ta.val(JSON.stringify(args, null, 3));
			resource.find('.queryParams').hide('fast');
		}
	});
	//hide request body form field for GET/DELETE on method change
	$(".resource .reqMethod").on('change', function(){
		var resource = $(this).closest('.resource');
		var method = resource.find('.reqMethod option:checked').html();
		if (method === 'GET' || method === 'DELETE'){
			resource.find('.reqBody').hide('fast');
			resource.find('.queryParams').show('fast');
		}else{
			var args = window.taffy.resources[resource.data('beanName')][method.toLowerCase()];
			var ta = resource.find('.reqBody').show('fast').find('textarea');
			ta.val(JSON.stringify(args, null, 3));
			resource.find('.queryParams').hide('fast').find('input').val('');
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
			,response = resource.find('.response');

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
		var body = (verb === 'GET' || verb === 'DELETE') ? params(qParams(resource)) : resource.find('.reqBody textarea').val();
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

		submitRequest(verb, path, headers, body, function(timeSpent, status, headers, body){
			loading.hide();
			submit.removeAttr('disabled');
			reset.show();
			headers = parseHeaders(headers);

			if (headers['Content-Type'].indexOf('application/json') > -1 || headers['Content-Type'].indexOf('text/json') > -1){
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
	var chunks = h.split('\n');
	for (var i=0,j=chunks.length; i<j; i++){
		var bits = chunks[i].split(': ');
		if (bits[0].length)
			out[bits[0]] = bits[1];
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

