<cfinterface>

	<cffunction name="init" hint="I accept a configuration structure to setup and return myself">
		<cfargument name="config" />
		<cfargument name="tracker" />
	</cffunction>
	<cffunction name="log" hint="I log or otherwise notify you of an exception">
		<cfargument name="exception" />
	</cffunction>

</cfinterface>