$(function(){

	//hide request body form field for GET/DELETE on accordion open
	$("#resources").on('shown.bs.collapse', function(e){
		var resource = $("#resources .in .resource");
		var method = resource.find('.reqMethod option:checked').html();
		if (method === 'GET' || method === 'DELETE'){
			resource.find('.reqBody').hide();
		}else{
			resource.find('.reqBody').show();
		}
	});
	//hide request body form field for GET/DELETE on method change
	$(".resource .reqMethod").on('change', function(){
		var resource = $(this).closest('.resource');
		var method = resource.find('.reqMethod option:checked').html();
		if (method === 'GET' || method === 'DELETE'){
			resource.find('.reqBody').hide();
		}else{
			resource.find('.reqBody').show();
		}
	});

	$(".submitRequest").click(function(){
		var submit = $(this)
			,resource = submit.closest('.resource')
			,reset = resource.find('.resetRequest')
			,loading = resource.find('.progress')
			,response = resource.find('.response');

		loading.show();
		submit.attr('disabled','disabled');

		//interpolate the full request path
		var uri = resource.data('uri')
			,form = params( resource.find('.reqTokens form').serialize() )
			,path = uri.supplant(form);

		var verb = resource.find('.reqMethod option:checked').val();
		var body = resource.find('.reqBody textarea').val();
		var headers = {
			Accept: resource.find('.reqFormat option:checked').val()
		};

		submitRequest(verb, path, headers, body, function(timeSpent, status, headers, body){
			loading.hide();
			submit.removeAttr('disabled').hide();
			reset.show();
			headers = parseHeaders(headers);

			if (headers['Content-Type'].indexOf('application/json') > -1 || headers['Content-Type'].indexOf('text/json') > -1){
				//indentation!
				body = JSON.stringify( JSON.parse(body), null, 3 )
						 .split('\n')
						 .join('<br/>')
						 .replace(/\s/g,'&nbsp;');
			}

			response.show();
			var headerRow = response.find('.responseHeaders');
			headerRow.empty();
			for (var h in headers){
				headerRow.append('<div class="row"><div class="col-md-4 headerName">' + h + ':</div><div class="col-md-8 headerVal">' + headers[h] + '</div></div>');
			}

			response.find('.responseTime').html('Request took ' + timeSpent + 'ms');
			response.find('.responseStatus').html(status);
			response.find('.responseBody').html(body);
		});

	});

	$(".resetRequest").click(function(){
		var reset = $(this)
			,resource = reset.closest('.resource')
			,submit = resource.find('.submitRequest')
			,response = resource.find('.response')
			,tokens = resource.find('.reqTokens form input');

		response.hide();
		reset.hide();
		submit.show();

		tokens.each(function(){
			$(this).val('');
		});
	});

});

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

// http://javascript.crockford.com/remedial.html
String.prototype.supplant = function (o) {
    return this.replace(/{([^{}]*)}/g,
        function (a, b) {
            var r = o[b];
            return typeof r === 'string' || typeof r === 'number' ? r : a;
        }
    );
};
