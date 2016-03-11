component extends="taffy.core.api" {
	this.name = "rate_limiting_example";

	function onApplicationStart(){
		application.accessLog = queryNew('apiKey,accessTime','varchar,time');
		application.accessLimit = 100; //requests
		application.accessPeriod = 60; //seconds

		return super.onApplicationStart();
	}

	function onTaffyRequest(verb, cfc, requestArguments, mimeExt){
		var usage = 0;
		//require some api key
		if (!structKeyExists(requestArguments, "apiKey")){
			return noData().withStatus(401, "API Key Required");
		}

		//check usage
		usage = getAccessRate(requestArguments.apiKey);
		if (usage lte application.accessLimit){
			logAccess(requestArguments.apiKey);
			return true;
		}else{
			return noData().withStatus(420, "Enhance your calm");
		}

		return true;
	}

	
	private function getAccessRate(apiKey){
		var accessLookup = queryExecute("
			select accessTime
			from application.accessLog
			where apiKey = :k
			and accessTime > :t
		",
		{
			t : dateAdd("s",(-1 * application.accessPeriod),now()),
			k : arguments.apiKey
		},
		{
			dbtype : "query"
		});

		if( local.accessLookup.recordCount gt application.accessLimit ){
			pruneAccessLog();
		}
		return local.accessLookup.recordCount;
	}

	private function logAccess(apiKey){
		lock timeout="10" type="readonly" name="logging"{
			queryAddRow (application.accessLog);
			querySetCell(application.accessLog, "accessTime", now());
			querySetCell(application.accessLog, "apiKey", arguments.apiKey);
		}
	}

	private function pruneAccessLog(){
		lock timeout="10" type="readonly" name="logging"{
			var rest = queryExecute("
				select *
				from application.accessLog
				where accessTime > :t
			",
			{
				t : dateAdd("s",(-1 * application.accessPeriod),now())
			},
			{
				dbtype : "query"
			});
			application.accessLog = rest;
		}
	}

}
