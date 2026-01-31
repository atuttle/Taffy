/*
--------------------------------------------------------------------
I configure and load Hoth into the ColdBox cache
--------------------------------------------------------------------
Define settings in ColdBox.cfc for example:
 		interceptors = [
			//Autowire
			{
				class="coldbox.system.interceptors.Autowire",
			 	properties={}
			},
			//SES
			{
				class="coldbox.system.interceptors.SES",
			 	properties={}
			},
			//HothTracker
			{
				class="hoth.extras.ColdBoxInterceptor",
			 	properties={
					EmailNewExceptions = true,
					EmailNewExceptionsFile = true,
					EmailNewExceptionsTo = "kaboom@mysite.com",
					EmailNewExceptionsFrom = "server@mysite.com"
			 	}
			}
		];
--------------------------------------------------------------------
*/
component
{

	/* CONSTRUCTOR 
	------------------------------------------- */

	/**
	* This is the configuration method for the interceptor
	*/
	void function Configure()
	{
		// check for required settings
		if ( !propertyExists( "EmailNewExceptionsTo" ) )
		{
			getPlugin( "logger" ).fatal( "hoth.extras.ColdBoxInterceptor.Configure", "The required 'EmailNewExceptionsTo' property has not been defined" );
			throw(
				type="hoth.extras.ColdBoxInterceptor"
				, message="The required 'EmailNewExceptionsTo' property has not been defined"				
			);
		}
		
		// Use ColdBox settings if not specified 
		if ( !propertyExists( "applicationName" ) )
		{
			setProperty( "applicationName", getSetting( "AppName" ) & " (" & getSetting( "Environment" ) & ")" );
		}
		if ( !propertyExists( "logPath" ) )
		{
			setProperty( "logPath", getSetting( "ApplicationPath" ) & "logs/hoth" );
			setProperty( "logPathIsRelative", false );
		}
		
		// Optional settings
		if ( !propertyExists( "cacheKeyName" ) )
		{
			setProperty( "cacheKeyName", "hothtracker" );
		}
	}
	
	/* INTERCEPTION POINTS 
	------------------------------------------- */

	void function afterAspectsLoad( required any event, required struct interceptData )
	{
		var HothConfig = "";
		var HothTracker = "";
		var key = "";
		var properties = getProperties();

		HothConfig = new hoth.config.HothConfig();
		
		for ( key in properties )
		{
			// use evaluate to dynamically called setters
			if ( StructKeyExists( HothConfig, "set" & key ) )
			{
				evaluate( "HothConfig.set#key#( properties[ key ] )" );
			}
		}
		
		HothTracker = new Hoth.HothTracker( HothConfig );

		// store in ColdBox Cache
		getColdboxOCM().set( getProperty( 'cacheKeyName' ), HothTracker, 0 );
		
		getPlugin( "logger" ).info( "hoth.extras.ColdBoxInterceptor", "HothTracker configured and loaded in ColdBox cache using key '#getProperty( 'cacheKeyName' )#'" );
	}
	
}