<html>
<head>
	<title>Example REST Consumer Application</title>
</head>
<body>
	<table id="artists">
		<tr>
			<th>ID</th>
			<th>First Name</th>
			<th>Last Name</th>
			<th>Address</th>
			<th>City</th>
			<th>State</th>
			<th>Postal Code</th>
			<th>Email</th>
			<th>Phone</th>
			<th>Fax</th>
			<th>Password</th>
			<th> </th>
		</tr>
	</table>
	<script type="text/javascript" src="jquery.1.4.2.min.js"></script>
	<cfoutput>
    	<script type="text/javascript">
			$(document).ready(function(){
				$.ajax({
					url: "#application.wsLoc#/artists",
					type: "get",
					dataType: "json",
					success: function(data, textStatus, xhr){
						console.dir(data);
						for (var row = 0; row <= data.len; row++){
							var newRow = $("<tr><td>" + data[row][0] + "</td></tr>");
							console.log(newRow);
						}
					},
					error: function(xhr, textStatus, err){
						alert(err & "\n\n" & textStatus);
					}
				});
			});
		</script>
    </cfoutput>
</body>
</html>