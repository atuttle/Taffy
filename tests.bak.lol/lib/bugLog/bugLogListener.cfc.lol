<cfcomponent displayname="bugLogListener">

	<!---
		bugLogListener.cfc

		This is the main point of entry into the bugLog API. This component is the one that
		actually processes the bug reports, it adds them to the database and is responsible
		for processing any defined rules.

		Created: 2007 - Oscar Arevalo - http://www.oscararevalo.com
	--->

	<cfset variables.startedOn = 0>
	<cfset variables.oDAOFactory = 0>
	<cfset variables.oRuleProcessor = 0>
	<cfset variables.oConfig = 0>
	<cfset variables.msgLog = arrayNew(1)>
	<cfset variables.maxLogSize = 10>
	<cfset variables.instanceName = "">
	<cfset variables.autoCreateDefault = true>

	<cffunction name="init" access="public" returntype="bugLogListener" hint="This is the constructor">
		<cfargument name="config" required="true" type="config">
		<cfargument name="instanceName" type="string" required="true">
		<cfscript>
			var cacheTTL = 300;		// timeout in minutes for cache entries

			variables.oConfig = arguments.config;		// global configuration
			variables.instanceName = arguments.instanceName;

			logMessage("Starting BugLogListener (#instanceName#) service...");

			// load settings
			variables.maxLogSize = arguments.config.getSetting("service.maxLogSize");

			// load DAO Factory
			variables.oDAOFactory = createObject("component","bugLog.components.DAOFactory").init( variables.oConfig );

			// load the finder objects
			variables.oAppFinder = createObject("component","bugLog.components.appFinder").init( variables.oDAOFactory.getDAO("application") );
			variables.oHostFinder = createObject("component","bugLog.components.hostFinder").init( variables.oDAOFactory.getDAO("host") );
			variables.oSeverityFinder = createObject("component","bugLog.components.severityFinder").init( variables.oDAOFactory.getDAO("severity") );
			variables.oSourceFinder = createObject("component","bugLog.components.sourceFinder").init( variables.oDAOFactory.getDAO("source") );
			variables.oUserFinder = createObject("component","bugLog.components.userFinder").init( variables.oDAOFactory.getDAO("user") );

			// load the rule processor
			variables.oRuleProcessor = createObject("component","bugLog.components.ruleProcessor").init();

			// create cache instances
			variables.oAppCache = createObject("component","bugLog.components.lib.cache.cacheService").init(50, cacheTTL, false);
			variables.oHostCache = createObject("component","bugLog.components.lib.cache.cacheService").init(50, cacheTTL, false);
			variables.oSeverityCache = createObject("component","bugLog.components.lib.cache.cacheService").init(10, cacheTTL, false);
			variables.oSourceCache = createObject("component","bugLog.components.lib.cache.cacheService").init(5, cacheTTL, false);
			variables.oUserCache = createObject("component","bugLog.components.lib.cache.cacheService").init(50, cacheTTL, false);

			// load scheduler
			variables.scheduler = createObject("component","bugLog.components.schedulerService").init( variables.oConfig, variables.instanceName );

			// load the mailer service
			variables.mailerService = createObject("component","bugLog.components.MailerService").init( variables.oConfig );

			// load rules
			loadRules();

			// configure history purging
			configureHistoryPurging();

			// configure the digest sender
			configureDigest();

			// record the date at which the service started
			variables.startedOn = Now();

			logMessage("BugLogListener Service (#instanceName#) Started");
		</cfscript>

		<cfreturn this>
	</cffunction>

	<cffunction name="logEntry" access="public" returntype="void" hint="This method adds a bug report entry into BugLog. Bug reports must be passed as RawEntryBeans">
		<cfargument name="entryBean" type="rawEntryBean" required="true">

		<cfscript>
			var bean = arguments.entryBean;
			var oEntry = 0;
			var oApp = 0;
			var oHost = 0;
			var oSeverity = 0;
			var oSource = 0;
			var oDF = variables.oDAOFactory;

			// get autocreate settings
			var autoCreateApp = allowAutoCreate("application");
			var autoCreateHost = allowAutoCreate("host");
			var autoCreateSeverity = allowAutoCreate("severity");
			var autoCreateSource = allowAutoCreate("source");

			// extract related objects from bean
			oApp = getApplicationFromBean( bean, autoCreateApp );
			oHost = getHostFromBean( bean, autoCreateHost );
			oSeverity = getSeverityFromBean( bean, autoCreateSeverity );
			oSource = getSourceFromBean( bean, autoCreateSource );

			// create entry
			oEntry = createObject("component","bugLog.components.entry").init( oDF.getDAO("entry") );
			oEntry.setDateTime(bean.getdateTime());
			oEntry.setMessage(bean.getmessage());
			oEntry.setApplicationID(oApp.getApplicationID());
			oEntry.setSourceID(oSource.getSourceID());
			oEntry.setSeverityID(oSeverity.getSeverityID());
			oEntry.setHostID(oHost.getHostID());
			oEntry.setExceptionMessage(bean.getexceptionMessage());
			oEntry.setExceptionDetails(bean.getexceptionDetails());
			oEntry.setCFID(bean.getcfid());
			oEntry.setCFTOKEN(bean.getcftoken());
			oEntry.setUserAgent(bean.getuserAgent());
			oEntry.setTemplatePath(bean.gettemplate_Path());
			oEntry.setHTMLReport(bean.getHTMLReport());
			oEntry.setCreatedOn(bean.getReceivedOn());

			// save entry
			oEntry.save();

			// process rules
			variables.oRuleProcessor.processRules(bean, oEntry);

		</cfscript>
	</cffunction>

	<cffunction name="getStartedOn" access="public" returntype="date" hint="Returns the date and time where this instance of BugLogListener was created">
		<cfreturn variables.startedOn>
	</cffunction>

	<cffunction name="shutDown" access="public" returntype="void" hint="Performs any clean up action required">
		<cfset logMessage("BugLogListener service stopped.")>
	</cffunction>

	<cffunction name="logMessage" access="public" output="false" returntype="void" hint="this method appends an entry to the messages log as well as displays the message on the console">
		<cfargument name="msg" type="string" required="true" />
		<cfset var System = CreateObject('java','java.lang.System') />
		<cfset var txt = timeFormat(now(), 'HH:mm:ss') & ": " & msg>
		<cfset System.out.println("BugLogListener: " & txt) />
		<cflock name="bugLogListener_logMessage" type="exclusive" timeout="10">
			<cfif arrayLen(variables.msgLog) gt variables.maxLogSize>
				<cfset arrayDeleteAt(variables.msgLog, ArrayLen(variables.msgLog))>
			</cfif>
			<cfset arrayPrepend(variables.msgLog,txt)>
		</cflock>
	</cffunction>

	<cffunction name="getConfig" returnType="any" access="public" hint="returns the config settings">
		<cfreturn variables.oConfig>
	</cffunction>

	<cffunction name="getInstanceName" returnType="any" access="public" hint="returns the current instance name">
		<cfreturn variables.instanceName>
	</cffunction>

	<cffunction name="validate" returntype="boolean" access="public" hint="Validates that a bug report is valid, if not throws an error. This only applies when the requireAPIKey setting is true, otherwise returns True always">
		<cfargument name="entryBean" type="rawEntryBean" required="true">
		<cfargument name="apiKey" type="string" required="true">
		<cfscript>
			// validate API
			if(getConfig().getSetting("service.requireAPIKey",false)) {
				if(arguments.apiKey eq "") {
					throw(message="Invalid API Key",type="bugLog.invalidAPIKey");
				}
				var masterKey = getConfig().getSetting("service.APIKey");
				if(arguments.apiKey neq masterKey) {
					var user = getUserByAPIKey(arguments.apiKey);
					if(!user.getIsAdmin() and arrayLen(user.getAllowedApplications())) {
						// key is good, but since the user is a non-admin
						// we need to validate the user can post bugs to the requested
						// application.
						var app = getApplicationFromBean( entryBean, false );
						if(!user.isApplicationAllowed(app)) {
							throw(message="Application not allowed",type="applicationNotAllowed");
						}
					}
				}
			}

			// validate application
			if(!allowAutoCreate("application")) {
				getApplicationFromBean( entryBean, false );
			}

			// validate host
			if(!allowAutoCreate("host")) {
				getHostFromBean( entryBean, false );
			}

			// validte severity
			if(!allowAutoCreate("severity")) {
				getSeverityFromBean( entryBean, false );
			}

			// validate source
			if(!allowAutoCreate("source")) {
				getSourceFromBean( entryBean, false );
			}

			return true;
		</cfscript>
	</cffunction>

	<cffunction name="reloadRules" access="public" returntype="void" hint="Reloads all rules">
		<cfset loadRules()>
	</cffunction>

	<cffunction name="getMessageLog" access="public" returntype="array">
		<cfreturn variables.msgLog>
	</cffunction>

	<!---- Private Methods ---->

	<cffunction name="getApplicationFromBean" access="private" returntype="app" hint="Uses the information on the rawEntryBean to retrieve the corresponding Application object">
		<cfargument name="entryBean" type="rawEntryBean" required="true">
		<cfargument name="createIfNeeded" type="boolean" default="false">
		<cfscript>
			var key = "";
			var bean = arguments.entryBean;
			var oApp = 0;
			var oDF = variables.oDAOFactory;

			key = bean.getApplicationCode();
			try {
				// first we try to get it from the cache
				oApp = variables.oAppCache.retrieve( key );

			} catch(cacheService.itemNotFound e) {
				// entry not in cache, so we get it from DB
				try {
					oApp = variables.oAppFinder.findByCode( key );

				} catch(appFinderException.ApplicationCodeNotFound e) {
					// code does not exist, so we need to create it (if autocreate enabled)
					if(!arguments.createIfNeeded) throw(message="Invalid Application",type="invalidApplication");
					oApp = createObject("component","bugLog.components.app").init( oDF.getDAO("application") );
					oApp.setCode( key );
					oApp.setName( key );
					oApp.save();
				}

				// store entry in cache
				variables.oAppCache.store( key, oApp );
			}
		</cfscript>
		<cfreturn oApp>
	</cffunction>

	<cffunction name="getHostFromBean" access="private" returntype="host" hint="Uses the information on the rawEntryBean to retrieve the corresponding Host object">
		<cfargument name="entryBean" type="rawEntryBean" required="true">
		<cfargument name="createIfNeeded" type="boolean" default="false">
		<cfscript>
			var key = "";
			var bean = arguments.entryBean;
			var oHost = 0;
			var oDF = variables.oDAOFactory;

			key = bean.getHostName();

			try {
				// first we try to get it from the cache
				oHost = variables.oHostCache.retrieve( key );

			} catch(cacheService.itemNotFound e) {
				// entry not in cache, so we get it from DB
				try {
					oHost = variables.oHostFinder.findByName( key );

				} catch(hostFinderException.HostNameNotFound e) {
					// code does not exist, so we need to create it (if autocreate enabled)
					if(!arguments.createIfNeeded) throw(message="Invalid Host",type="invalidHost");
					oHost = createObject("component","bugLog.components.host").init( oDF.getDAO("host") );
					oHost.setHostName(key);
					oHost.save();
				}

				// store entry in cache
				variables.oHostCache.store( key, oHost );
			}
		</cfscript>
		<cfreturn oHost>
	</cffunction>

	<cffunction name="getSeverityFromBean" access="private" returntype="severity" hint="Uses the information on the rawEntryBean to retrieve the corresponding Severity object">
		<cfargument name="entryBean" type="rawEntryBean" required="true">
		<cfargument name="createIfNeeded" type="boolean" default="false">
		<cfscript>
			var key = "";
			var bean = arguments.entryBean;
			var oSeverity = 0;
			var oDF = variables.oDAOFactory;

			key = bean.getSeverityCode();

			try {
				// first we try to get it from the cache
				oSeverity = variables.oSeverityCache.retrieve( key );

			} catch(cacheService.itemNotFound e) {
				// entry not in cache, so we get it from DB
				try {
					oSeverity = variables.oSeverityFinder.findByCode( key );

				} catch(severityFinderException.codeNotFound e) {
					// code does not exist, so we need to create it (if autocreate enabled)
					if(!arguments.createIfNeeded) throw(message="Invalid Severity",type="invalidSeverity");
					oSeverity = createObject("component","bugLog.components.severity").init( oDF.getDAO("severity") );
					oSeverity.setCode( key );
					oSeverity.setName( key );
					oSeverity.save();
				}

				// store entry in cache
				variables.oSeverityCache.store( key, oSeverity );
			}
		</cfscript>
		<cfreturn oSeverity>
	</cffunction>

	<cffunction name="getUserByAPIKey" access="private" returntype="user" hint="Finds a user object using by its API Key">
		<cfargument name="apiKey" type="string" required="true">
		<cfscript>
			var oUser = 0;

			try {
				// first we try to get it from the cache
				oUser = variables.oUserCache.retrieve( apiKey );

			} catch(cacheService.itemNotFound e) {
				// entry not in cache, so we get it from DB
				try {
					oUser = variables.oUserFinder.findByAPIKey( apiKey );

					var qryUserApps = oDAOFactory.getDAO("userApplication").search(userID = oUser.getUserID());
					var apps = oAppFinder.findByIDList(valueList(qryUserApps.applicationID));
					oUser.setAllowedApplications(apps);

				} catch(sourceFinderException.usernameNotFound e) {
					// code does not exist, so we need to create it (if autocreate enabled)
					throw(message="Invalid API Key",type="bugLog.invalidAPIKey");
				}

				// store entry in cache
				variables.oUserCache.store( key, oUser );
			}

			return oUser;
		</cfscript>
	</cffunction>

	<cffunction name="getSourceFromBean" access="private" returntype="source" hint="Uses the information on the rawEntryBean to retrieve the corresponding Source object">
		<cfargument name="entryBean" type="rawEntryBean" required="true">
		<cfargument name="createIfNeeded" type="boolean" default="false">
		<cfscript>
			var key = "";
			var bean = arguments.entryBean;
			var oSource = 0;
			var oDF = variables.oDAOFactory;

			key = bean.getSourceName();

			try {
				// first we try to get it from the cache
				oSource = variables.oSourceCache.retrieve( key );

			} catch(cacheService.itemNotFound e) {
				// entry not in cache, so we get it from DB
				try {
					oSource = variables.oSourceFinder.findByName( key );

				} catch(sourceFinderException.codeNotFound e) {
					// code does not exist, so we need to create it (if autocreate enabled)
					if(!arguments.createIfNeeded) throw(message="Invalid Source",type="invalidSource");
					oSource = createObject("component","bugLog.components.source").init( oDF.getDAO("source") );
					oSource.setName( key );
					oSource.save();
				}

				// store entry in cache
				variables.oSourceCache.store( key, oSource );
			}
		</cfscript>
		<cfreturn oSource>
	</cffunction>

	<cffunction name="loadRules" access="private" returntype="void" hint="this method loads the rules into the rule processor">
		<cfscript>
			var oRule = 0;
			var oExtensionsService = 0;
			var aRules = arrayNew(1);
			var i = 0;
			var dao = 0;
			var thisRule = 0;

			// clear all existing rules
			variables.oRuleProcessor.flushRules();

			// get the rule definitions from the extensions service
			dao = variables.oDAOFactory.getDAO("extension");
			oExtensionsService = createObject("component","bugLog.components.extensionsService").init( dao );
			aRules = oExtensionsService.getRules();

			// create rule objects and load them into the rule processor
			for(i=1; i lte arrayLen(aRules);i=i+1) {
				thisRule = aRules[i];

				if(thisRule.enabled) {
					oRule =
						thisRule.instance
						.setListener(this)
						.setDAOFactory( variables.oDAOFactory )
						.setMailerService( variables.mailerService );

					// add rule to processor
					variables.oRuleProcessor.addRule(oRule);
				}
			}
		</cfscript>
	</cffunction>

	<cffunction name="configureHistoryPurging" access="private" output="false" returntype="void">
		<cfset var enabled = getConfig().getSetting("purging.enabled")>
		<cfif enabled>
			<cfset scheduler.setupTask("bugLogPurgeHistory",
										"util/purgeHistory.cfm",
										"03:00",
										"daily") />
		<cfelse>
			<cfset scheduler.removeTask("bugLogPurgeHistory") />
		</cfif>
	</cffunction>

	<cffunction name="configureDigest" access="private" output="false" returntype="void">
		<cfset var config = getConfig()>
		<cfset var enabled = config.getSetting("digest.enabled")>
		<cfset var interval = config.getSetting("digest.schedulerIntervalHours")>
		<cfset var startTime = config.getSetting("digest.schedulerStartTime")>

		<cfif enabled>
			<cfset scheduler.setupTask("bugLogSendDigest",
										"util/sendDigest.cfm",
										startTime,
										interval*3600) />
		<cfelse>
			<cfset scheduler.removeTask("bugLogSendDigest") />
		</cfif>
	</cffunction>

	<cffunction name="allowAutoCreate" returnType="boolean" access="private">
		<cfargument name="entityType" type="string" required="true">
		<cfreturn getConfig().getSetting("autocreate." & arguments.entityType, variables.autoCreateDefault)>
	</cffunction>

</cfcomponent>
