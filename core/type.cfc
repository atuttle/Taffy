<cfcomponent accessors="true">

	<!---
		Your types will inherit from this class.
		You specify columns with an instance variable named "columns".

		By default, Taffy will map columns in the query to fields with
		these names if they match (case-insensitive).
	--->
	<cfset variables.columns = arrayNew(1) />

	<cffunction name="fromQuery" returntype="array" access="public" output="false">
		<cfargument name="q" />
		<cfargument name="cb" />
		<cfscript>
			var local = {};
			local.typeCols = arrayMap(variables.columns, function(c){ return c.name; });

			if (structKeyExists(server, "railo") or structKeyExists(server, "lucee")) {
				local.qColumns = listToArray(arguments.q.getColumnList(false));
			}
			else {
				local.qColumns = arguments.q.getMetaData().getColumnLabels();
			}
			local.QueryArray = ArrayNew(1);
			for (local.RowIndex = 1; local.RowIndex <= arguments.q.RecordCount; local.RowIndex++){
				local.Row = {};
				local.numCols = ArrayLen( local.qColumns );
				for (local.ColumnIndex = 1; local.ColumnIndex <= local.numCols; local.ColumnIndex++){
					local.sqlColumnName = local.qColumns[ local.ColumnIndex ];

					//if not defined in the type, blanks out the col name
					local.ColumnName = checkColumnName( local.sqlColumnName );
					if ( local.ColumnName neq "" ){
						setVal(local.Row, local.ColumnName, arguments.q[ local.ColumnName ][ local.RowIndex ]);
					}
				}
				if ( structKeyExists( arguments, "cb" ) ) {
					local.Row = cb( local.Row );
				}
				ArrayAppend( local.QueryArray, local.Row );
			}
			return( local.QueryArray );
		</cfscript>

	</cffunction>

	<cfscript>
		string function checkColumnName(col){
			local.c = findCol( col );
			if ( isDefined("local.c") ){
				return local.c.name;
			}
			return "";
		}

		void function setVal(row, col, val){
			//TODO: handle custom setter implementations
			arguments.row[ arguments.col ] = enforceConstraints(arguments.col, arguments.val);
		}

		any function enforceConstraints( col, val ){
			var colDef = findCol( arguments.col );
			var result = val;

			if ( colDef.keyExists('type') ){
				switch(colDef.type){
					case 'string':
						if ( colDef.keyExists( 'maxLength' ) ){
							result = left( result, colDef.maxLength );
						}
						if ( colDef.keyExists( 'minLength' ) ){
							if ( len(result) < colDef.minLength ){
								throw( type: "Taffy.Type.ConstraintViolation", message: "Minimum length not met for column `#colDef.name#`" );
							}
						}
						result = forceString(result);
						break;
					case 'integer':
					case 'int':
						if ( colDef.keyExists( 'min' ) ){
							if ( result < colDef.min ){
								throw( type: "Taffy.Type.ConstraintViolation", message: "Value less than min constraint for column `#colDef.name#`" );
							}
						}
						if ( colDef.keyExists( 'min' ) ){
							if ( result > colDef.max ){
								throw( type: "Taffy.Type.ConstraintViolation", message: "Value greater than max constraint for column `#colDef.name#`" );
							}
						}
						//round any float/double precision down to integer
						result = round(result);
						break;
					case 'float':
					case 'double':
						if ( colDef.keyExists( 'min' ) ){
							if ( result < colDef.min ){
								throw( type: "Taffy.Type.ConstraintViolation", message: "Value less than min constraint for column `#colDef.name#`" );
							}
						}
						if ( colDef.keyExists( 'min' ) ){
							if ( result > colDef.max ){
								throw( type: "Taffy.Type.ConstraintViolation", message: "Value greater than max constraint for column `#colDef.name#`" );
							}
						}
						break;
					case 'timestamp':
					case 'datetime':
					case 'date':
					case 'time':
						if ( colDef.keyExists( 'mask' ) ){
							result = dateTimeFormat( result, colDef.mask );
						}
						break;
					default:
						throw(message: "Unrecognized column type: `#colDef.type#`");
				}
			}

			return result;
		}

		// returns struct when found, else void
		any function findCol( col ){
			for ( var c in variables.columns ){
				if ( c.name == arguments.col ){
					return c;
				}
			}
			return;
		}
	</cfscript>

	<cffunction name="forceString">
		<cfargument name="data" required="true" hint="the data that is being forced to serialize as a string" />
		<cfreturn chr(2) & arguments.data />
	</cffunction>

</cfcomponent>
