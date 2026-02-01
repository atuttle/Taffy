if (!String.prototype.trim) {
	String.prototype.trim = function () {
		return this.replace(/^[\s\xA0]+|[\s\xA0]+$/g, '');
	};
}

document.addEventListener('DOMContentLoaded', function(){

	// hljs setup (if available)
	if (typeof hljs !== 'undefined') {
		hljs.configure({ ignoreUnescapedHTML: true });

		// Format JSON in sample responses
		document.querySelectorAll('.json-format').forEach(function(el) {
			try {
				var json = JSON.parse(el.textContent);
				el.textContent = JSON.stringify(json, null, 3);
			} catch(e) {}
		});

		hljs.highlightAll();
	}

	// Modal handling (native dialog)
	document.querySelectorAll('[data-modal-target]').forEach(function(el) {
		el.addEventListener('click', function() {
			var modalId = this.dataset.modalTarget;
			document.getElementById(modalId).showModal();
		});
	});

	document.querySelectorAll('.modal .modal-close').forEach(function(el) {
		el.addEventListener('click', function() {
			this.closest('.modal').close();
		});
	});

	// Close modal on backdrop click
	document.querySelectorAll('.modal').forEach(function(modal) {
		modal.addEventListener('click', function(e) {
			if (e.target === this) {
				this.close();
			}
		});
	});

	// Resource accordion
	document.querySelectorAll('.resource-header').forEach(function(el) {
		el.addEventListener('click', function() {
			var targetId = this.dataset.target;
			var content = document.getElementById(targetId);
			var wasOpen = content.classList.contains('open');
			content.classList.toggle('open');

			// On open, show/hide request body based on method
			if (!wasOpen) {
				var resource = content.querySelector('.resource');
				var method = resource.querySelector('.reqMethod option:checked').textContent;
				if (method === 'GET' || method === 'DELETE' || method === 'OPTIONS') {
					resource.querySelector('.reqBody').style.display = 'none';
					resource.querySelector('.queryParams').classList.add('active');
				} else {
					var args = window.taffy.resources[resource.dataset.beanName];
					if (args && args[method.toLowerCase()]) {
						var reqBody = resource.querySelector('.reqBody');
						reqBody.style.display = '';
						var ta = reqBody.querySelector('textarea');
						ta.value = JSON.stringify(args[method.toLowerCase()], null, 3);
					} else {
						resource.querySelector('.reqBody').style.display = '';
					}
					resource.querySelector('.queryParams').classList.remove('active');
				}
			}
		});
	});

	// Doc accordion
	document.querySelectorAll('.doc-accordion-trigger').forEach(function(el) {
		el.addEventListener('click', function() {
			var targetId = this.dataset.target;
			document.getElementById(targetId).classList.toggle('open');
			this.classList.toggle('open');
		});
	});

	// Tab handling
	document.querySelectorAll('.tab-btn').forEach(function(el) {
		el.addEventListener('click', function() {
			var tabGroup = this.closest('.tabs');
			var targetId = this.dataset.tab;

			tabGroup.querySelectorAll('.tab-btn').forEach(function(btn) {
				btn.classList.remove('active');
			});
			this.classList.add('active');

			tabGroup.querySelectorAll('.tab-pane').forEach(function(pane) {
				pane.classList.remove('active');
			});
			document.getElementById(targetId).classList.add('active');
		});
	});

	// Reload button
	var reloadBtn = document.getElementById('reload');
	if (reloadBtn && window.taffy && window.taffy.config) {
		reloadBtn.addEventListener('click', function() {
			var cfg = window.taffy.config;
			var reloadUrl = cfg.scriptName + '?dashboard&' + cfg.reloadKey + '=' + cfg.reloadPassword;
			var btn = this;
			btn.textContent = 'Reloading...';
			btn.disabled = true;

			fetch(reloadUrl)
				.then(function(response) {
					if (response.ok) {
						document.getElementById('alerts').insertAdjacentHTML('beforeend', '<div id="reloadSuccess" class="alert alert-success">API Cache Successfully Reloaded. Refresh to see changes.</div>');
						btn.disabled = false;
						btn.textContent = 'Reload API Cache';
						setTimeout(function() {
							var el = document.getElementById('reloadSuccess');
							if (el) el.remove();
						}, 2000);
					} else {
						throw new Error('Reload failed');
					}
				})
				.catch(function() {
					document.getElementById('alerts').insertAdjacentHTML('beforeend', '<div id="reloadFail" class="alert alert-danger">API Cache Reload Failed!</div>');
					btn.disabled = false;
					btn.textContent = 'Reload API Cache';
					setTimeout(function() {
						var el = document.getElementById('reloadFail');
						if (el) el.remove();
					}, 2000);
				});
		});
	}

	// Resource search
	var searchInput = document.getElementById('resourceSearch');
	if (searchInput) {
		searchInput.addEventListener('keyup', filterResources);
		searchInput.addEventListener('keydown', function(e) {
			if (e.keyCode == 27) {
				this.value = '';
				filterResources();
			}
		});
	}

	// Request body visibility on method change
	document.querySelectorAll(".resource .reqMethod").forEach(function(el) {
		el.addEventListener('change', function(){
			var resource = this.closest('.resource');
			var method = resource.querySelector('.reqMethod option:checked').textContent;
			if (method === 'GET' || method === 'DELETE' || method == 'OPTIONS'){
				resource.querySelector('.reqBody').style.display = 'none';
			}else{
				var args = window.taffy.resources[resource.dataset.beanName][method.toLowerCase()];
				var reqBody = resource.querySelector('.reqBody');
				reqBody.style.display = '';
				var ta = reqBody.querySelector('textarea');
				ta.value = JSON.stringify(args, null, 3);
				resource.querySelectorAll('.queryParams input').forEach(function(inp) {
					inp.value = '';
				});
			}
		});
	});

	document.querySelectorAll(".addParam").forEach(function(el) {
		el.addEventListener('click', function(){
			var resource = this.closest('.resource');
			var params = resource.querySelector('.queryParams');
			var tmpl = '<div class="qparam"><input class="form-input paramName" placeholder="name" /><span class="text-muted">=</span><input class="form-input paramValue" placeholder="value" /><button class="btn btn-ghost delParam" tabindex="-1">-</button></div>';
			params.insertAdjacentHTML('beforeend', tmpl);
		});
	});

	document.querySelectorAll(".resource").forEach(function(resource) {
		resource.addEventListener('click', function(e){
			if (e.target.classList.contains('delParam')) {
				var row = e.target.closest('.qparam');
				row.remove();
			}
		});
	});

	//interpolate resource uri token values as they're typed
	document.querySelectorAll(".resource").forEach(function(resource) {
		resource.addEventListener('keyup', function(e){
			if (!e.target.matches('input')) return;
			var form = resource.querySelector('.reqTokens form');
			var tokens = form ? params(new FormData(form)) : {};
			var q = qParams(resource);
			var uri = resource.dataset.uri;

			for (var t in tokens){
				if (tokens[t] === '')
					delete tokens[t];
			}
			var result = uri.supplant(tokens);
			result += (q.length) ? '?' + q : '';
			resource.querySelector('.resourceUri').value = result;
		});
	});

	document.querySelectorAll(".submitRequest").forEach(function(el) {
		el.addEventListener('click', function(){
			var submit = this;
			var resource = submit.closest('.resource');
			var reset = resource.querySelector('.resetRequest');
			var loading = resource.querySelector('.progress');
			var response = resource.querySelector('.response');
			var basicAuth = resource.querySelector(".basicAuth");

			//validate tokens
			resource.querySelectorAll('.has-error').forEach(function(el) {
				el.classList.remove('has-error');
			});
			var tokenErrors = resource.querySelector('.tokenErrors');
			var tokens = resource.querySelectorAll('.reqTokens input');
			if (tokenErrors) tokenErrors.innerHTML = '';
			for (var t=0;t<tokens.length;t++){
				var tok = tokens[t];
				if (tok.value.length === 0){
					tok.closest('.token-row').classList.add('has-error');
					tok.focus();
					if (tokenErrors) tokenErrors.insertAdjacentHTML('beforeend', '<div class="alert alert-danger">' + tok.name + ' is required</div>');
				}
			}
			if (resource.querySelectorAll('.reqTokens .has-error').length > 0){
				return false;
			}

			loading.classList.add('show');
			submit.disabled = true;

			response.classList.remove('show');

			//interpolate the full request path
			var uri = resource.dataset.uri;
			var form = resource.querySelector('.reqTokens form');
			var formParams = form ? params(new FormData(form)) : {};
			var path = uri.supplant(formParams);

			var verb = resource.querySelector('.reqMethod option:checked').value;
			var body = (verb === 'GET' || verb === 'DELETE') ? qParams(resource) : resource.querySelector('.reqBody textarea').value;
			var reqHeaders = resource.querySelector('.requestHeaders').value.replace(/\r/g, '').split('\n');
			var headers = {
				Accept: resource.querySelector('.reqFormat option:checked').value
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

			var basicAuthUsername = basicAuth.querySelector("input[name=username]").value;
			var basicAuthPassword = basicAuth.querySelector("input[name=password]").value;

			if(basicAuthUsername.length && basicAuthPassword.length){
				headers["Authorization"] =  "Basic " + Base64.encode(basicAuthUsername + ":" + basicAuthPassword);
			}

			submitRequest(verb, path, headers, body, function(timeSpent, status, headers, body){
				loading.classList.remove('show');
				submit.disabled = false;
				reset.style.display = '';
				headers = parseHeaders(headers);

				if (headers['content-type'] && (headers['content-type'].indexOf('application/json') > -1 || headers['content-type'].indexOf('text/json') > -1 || headers['content-type'].indexOf('application/vnd.api+json') > -1)){
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
							body = hljs.highlight(body, {language: "json"}).value;
							body = body.split('\n')
										.join('<br/>')
										.replace(/(\<br\/\>)(\s+)/g, function(match, p1, p2, offset, string){
											return [p1, p2.replace(/\s/g,'&nbsp;')].join('');
										});
						}
					}
				}

				var headerRow = response.querySelector('.response-headers');
				headerRow.innerHTML = '';
				response.classList.add('show');
				var sortable = [];
				for (var h in headers){
					sortable.push(h);
				}
				sortable.sort();
				for (var h in sortable){
					headerRow.insertAdjacentHTML('beforeend', '<div><strong>' + sortable[h] + ':</strong> ' + headers[sortable[h]] + '</div>');
				}

				response.querySelector('.response-time').innerHTML = 'Request took ' + timeSpent + 'ms';
				response.querySelector('.response-status').innerHTML = status;
				response.querySelector('.responseBody').innerHTML = body;
			});

		});
	});

	document.querySelectorAll(".resetRequest").forEach(function(el) {
		el.addEventListener('click', function(){
			var reset = this;
			var resource = reset.closest('.resource');
			var response = resource.querySelector('.response');
			var tokens = resource.querySelectorAll('.reqTokens form input');
			var paramInputs = resource.querySelectorAll('.queryParams input');
			var uri = resource.dataset.uri;

			response.classList.remove('show');
			reset.style.display = 'none';
			resource.querySelector('.resourceUri').value = uri;

			tokens.forEach(function(inp){
				inp.value = '';
			});
			paramInputs.forEach(function(inp){
				inp.value = '';
			});
		});
	});

});

function qParams(resource){
	var validParams = [];
	resource.querySelectorAll('.qparam').forEach(function(el){
		var n = el.querySelector('.paramName'), v = el.querySelector('.paramValue');
		var nameLen = n.value.length, valLen = v.value.length;
		if (nameLen && valLen){
			validParams.push(encodeURIComponent(n.value) + '=' + encodeURIComponent(v.value));
			el.classList.remove('has-error');
		}else{
			el.classList.add('has-error');
		}
	});
	return validParams.join('&');
}

function toggleStackTrace(id){
	var el = document.getElementById(id);
	if (el) el.classList.toggle('show');
}

function filterResources(){
	var filter = document.getElementById('resourceSearch').value.toUpperCase();
	document.querySelectorAll('.resource-panel').forEach(function(panel) {
		var text = panel.querySelector('.resource-name').textContent;
		panel.style.display = text.toUpperCase().indexOf(filter) > -1 ? '' : 'none';
	});
}

function getCookie(name) {
	var nameEQ = name + '=', ca = document.cookie.split(';'), i = 0, c;
	for(;i < ca.length;i++) {
		c = ca[i];
		while (c[0]==' ') c = c.substring(1);
		if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length);
	}
	return null;
}

function submitRequest(verb, resource, headers, body, callback){
	var cfg = window.taffy.config;
	var url = window.location.protocol + '//' + window.location.host;
	var endpointURLParam = cfg.endpointURLParam;
	var endpoint = resource.split('?')[0];
	var contentType = null;

	if (cfg.csrfCookieName && cfg.csrfHeaderName) {
		var csrfCookie = getCookie(cfg.csrfCookieName);
		if (csrfCookie) {
			headers[cfg.csrfHeaderName] = csrfCookie;
		}
	}

	url += cfg.scriptName + '?' + endpointURLParam + '=' + encodeURIComponent(endpoint);
	if (resource.indexOf('?') && resource.split('?')[1]) {
		url += '&' + resource.split('?')[1];
	}

	if (body && typeof body === 'string') {
		try {
			JSON.parse(body);
			contentType = "application/json";
		} catch (e) {}
	}

	var before = Date.now();

	var fetchOptions = {
		method: verb,
		headers: headers,
		cache: 'no-store'
	};

	if (body && verb !== 'GET' && verb !== 'HEAD') {
		fetchOptions.body = body;
		if (contentType) {
			fetchOptions.headers['Content-Type'] = contentType;
		}
	}

	fetch(url, fetchOptions)
		.then(function(response) {
			return response.text().then(function(text) {
				var after = Date.now(), t = after - before;
				var headersStr = '';
				response.headers.forEach(function(value, key) {
					headersStr += key + ': ' + value + '\n';
				});
				callback(t, response.status + " " + response.statusText, headersStr, text);
			});
		})
		.catch(function(error) {
			var after = Date.now(), t = after - before;
			callback(t, "0 Network Error", "", error.message || "Request failed");
		});
}

function params(formData){
	var parameters = {};
	if (formData instanceof FormData) {
		formData.forEach(function(value, key) {
			parameters[key] = value;
		});
	} else if (typeof formData === 'string' && formData.length > 1) {
		var query = formData.split('&');
		for (var i = 0; i < query.length; i++) {
			var parameter = query[i].split("=");
			if (parameter.length === 1) { parameter[1] = ""; }
			parameters[decodeURIComponent(parameter[0])] = decodeURIComponent(parameter[1]);
		}
	}
	return parameters;
}

function parseHeaders(h){
	var out = {};
	if (!h) return out;
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
		document.querySelectorAll('input,select,textarea,button').forEach(function(elem){
			if (elem.type === 'hidden') return;
			var invisibleParent = elem.closest(invisible_parent_class);
			if (invisibleParent){
				//could be invisible...
				if (invisibleParent.classList.contains('active')){
					//is visible, give it a tab index
					elem.tabIndex = nextTabIndex;
					nextTabIndex++;
				}
			}else{
				elem.tabIndex = nextTabIndex;
				nextTabIndex++;
			}
		});
	}

	var handleExpansion = function(e){
		var el = this;
		var target = document.querySelector(el.dataset.target);
		if (!target) return;
		var isVisible = target.classList.contains('active');

		if (el.tagName === 'A'){
			e.preventDefault();
			if (isVisible){
				target.classList.remove('active');
				var hideOnExpand = el.closest('.hide-on-expand');
				if (hideOnExpand) hideOnExpand.style.display = '';
			}else{
				target.classList.add('active');
				var hideOnExpand = el.closest('.hide-on-expand');
				if (hideOnExpand) hideOnExpand.style.display = 'none';
			}
			updateTabindexes();
			return false;

		}else if (el.type === 'checkbox'){
			if (el.checked){
				target.classList.add('active');
			}else{
				target.classList.remove('active');
			}

		}else if (el.type === 'radio'){
			var expand = el.dataset.expand && el.checked;
			if (expand){
				target.classList.add('active');
			}else{
				target.classList.remove('active');
			}

		}else if (el.tagName === 'SELECT'){
			var selectedOption = el.options[el.selectedIndex];
			var expand = selectedOption && selectedOption.dataset.expand;
			if (expand){
				target.classList.add('active');
			}else{
				target.classList.remove('active');
			}

		}else if (el.type === 'text'){
			if (el.value.trim().length > 0){
				target.classList.add('active');
			}else{
				target.classList.remove('active');
			}
		}

		updateTabindexes();
	}

	document.querySelectorAll('a.expander').forEach(function(el) {
		el.addEventListener('click', handleExpansion);
	});
	document.querySelectorAll('input.expander,select.expander').forEach(function(el) {
		el.addEventListener('keyup', handleExpansion);
		el.addEventListener('change', handleExpansion);
		// initialize starting state
		handleExpansion.call(el);
	});
}
expandingFormElements();
