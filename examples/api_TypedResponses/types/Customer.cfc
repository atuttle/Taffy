<cfcomponent extends="taffy.core.type">

	<cfset variables.columns = [
		{ name: 'id', type: 'int', hint: 'Unique Identifier' },
		{ name: 'Name', type: 'string', maxLength: 100, hint: 'Customer display name' },
		{ name: 'dateTimeCreated', type: 'dateTime', mask: 'yyyy-mm-dd HH:nn:sstt', hint='Customer creation timestamp' }
	] />

</cfcomponent>
