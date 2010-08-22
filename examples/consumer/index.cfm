<html>
<head>
	<title>Example REST Consumer Application</title>
	<style>
		a.delete, a.update {
			color: blue;
			text-decoration: underline;
			cursor: pointer;
		}
		#add, #update { display: none; }
		#artists td {
			padding: 4px;
		}
	</style>
</head>
<body id="top">

	<h2>Artists</h2>

	<p>This is <em><strong>not</strong></em> a shining example of how to write an ajax-based web application;
	it is strictly intended to demonstrate the use of each of the 4 http verbs with a Taffy API.</p>

	<a href="#new" id="new">Add New Artist</a><br/>
	<form action="/taffy/examples/api/index.cfm/artists" method="post" id="add">
		First Name: <input type="text" name="firstname" /><br/>
		Last Name: <input type="text" name="lastname" /><br/>
		Address: <input type="text" name="address" /><br/>
		City: <input type="text" name="city" /><br/>
		State: <input type="text" name="state" /><br/>
		Postal Code: <input type="text" name="postalcode" /><br/>
		Email: <input type="text" name="email" /><br/>
		Phone: <input type="text" name="phone" /><br/>
		Fax: <input type="text" name="fax" /><br/>
		Password: <input type="text" name="thepassword" /><br/>
		<input type="submit" value="Add Artist" />
		<input type="reset" value="Cancel" id="addCancel" />
	</form>
	<form action="/taffy/examples/api/index.cfm/artist" method="put" id="update">
		First Name: <input type="text" name="firstname" /><br/>
		Last Name: <input type="text" name="lastname" /><br/>
		Address: <input type="text" name="address" /><br/>
		City: <input type="text" name="city" /><br/>
		State: <input type="text" name="state" /><br/>
		Postal Code: <input type="text" name="postalcode" /><br/>
		Email: <input type="text" name="email" /><br/>
		Phone: <input type="text" name="phone" /><br/>
		Fax: <input type="text" name="fax" /><br/>
		Password: <input type="text" name="thepassword" /><br/>
		<input type="hidden" name="debug" value="true" />
		<input type="submit" value="Update Artist" />
		<input type="reset" value="Cancel" id="updateCancel" />
	</form>
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
	<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js"></script>
	<cfoutput>
    	<script type="text/javascript">

			var apiBaseURI = "#application.wsLoc#";

			$(document).ready(function(){


				/* ************* */
				/* LINK HANDLERS */
				/* ************* */

				//delete-link handler
				$("##artists .delete").live('click', function(){
					deleteRow($(this).parent().parent().attr('id'));
				});
				//update-link handler
				$("##artists .update").live('click', function(){
					updateRow($(this).parent().parent().attr('id'));
				});

				//new-record-link handler
				$("##new").click(function(){
					$("##add").show("slow");
				});

				$("##updateCancel").click(function(){
					$("##update").hide("slow");
				});

				$("##addCancel").click(function(){
					$("##add").hide("slow");
				});

				/* ************* */
				/* FORM HANDLERS */
				/* ************* */

				//add-form handler
				submitFrmViaAjax(
					$("##add"),
					function (data, textStatus, xhr){
						console.log(data);
						$("##add").hide();
						reloadData();
					},
					function (xhr, textStatus, err){
						console.log(textStatus);
						console.log(err);
					}
				);
				/*
				$("##add").submit(function(e){
					e.preventDefault();
					var frm = $(this);
					$.ajax({
						url: frm.attr('action'),
						data:{
							firstname: $("##add input[name=firstname]").val(),
							lastname: $("##add input[name=lastname]").val(),
							address: $("##add input[name=address]").val(),
							city: $("##add input[name=city]").val(),
							state: $("##add input[name=state]").val(),
							postalcode: $("##add input[name=postalcode]").val(),
							email: $("##add input[name=email]").val(),
							phone: $("##add input[name=phone]").val(),
							fax: $("##add input[name=fax]").val(),
							thepassword: $("##add input[name=thepassword]").val()
						},
						type: frm.attr('method'),
						dataType: "json",
						contentType: "application/json",
						success: function (data, textStatus, xhr){
							console.log(data);
						},
						error: function (xhr, textStatus, err){
							console.log(textStatus);
							console.log(err);
						}
					});
				});
				*/

				//update-form handler
				submitFrmViaAjax(
					$("##update"),
					function (data, textStatus, xhr){
						console.log(data);
						$("##update").hide();
						reloadData();
					},
					function (xhr, textStatus, err){
						console.log(textStatus);
						console.log(err);
					}
				);
				/*
				$("##update").submit(function(e){
					e.preventDefault();
					var frm = $(this);
					$.ajax({
						url: frm.attr('action'),
						data: {
							firstname: $("##update input[name=firstname]").val(),
				            lastname: $("##update input[name=lastname]").val(),
				            address: $("##update input[name=address]").val(),
				            city: $("##update input[name=city]").val(),
				            state: $("##update input[name=state]").val(),
				            postalcode: $("##update input[name=postalcode]").val(),
				            email: $("##update input[name=email]").val(),
				            phone: $("##update input[name=phone]").val(),
				            fax: $("##update input[name=fax]").val(),
				            thepassword: $("##update input[name=thepassword]").val()
						},
						type: frm.attr('method'),
						dataType: "json",
						success: function (data, textStatus, xhr){
							console.log(data);
							$("##update").hide();
							reloadData();
						},
						error: function (xhr, textStatus, err){
							console.log(textStatus);
							console.log(err);
						}
					});
				});
				*/

				/* ********* */
				/* LOAD DATA */
				/* ********* */
				reloadData();

			});

			/* ************** */
			/* INTERNAL FUNCS */
			/* ************** */

			function reloadData(){
				//remove existing data
				$("##artists .dyn").remove();
				//load table data
				$.ajax({
					url: apiBaseURI + "/artists",
					type: "get",
					dataType: "json",
					success: function(data, textStatus, xhr){
						var rowNum = 0;
						if (data != null) for (rowNum = 0; rowNum < data.DATA.length; rowNum++){
							addRow(
								"##artists",
								data.DATA[rowNum][0],
								data.DATA[rowNum][1],
								data.DATA[rowNum][2],
								data.DATA[rowNum][3],
								data.DATA[rowNum][4],
								data.DATA[rowNum][5],
								data.DATA[rowNum][6],
								data.DATA[rowNum][7],
								data.DATA[rowNum][8],
								data.DATA[rowNum][9],
								data.DATA[rowNum][10]
							);
						}
					},
					error: function(xhr, textStatus, err){
						alert(err & "\n\n" & textStatus);
					}
				});
			}

			function deleteRow(rowId){
				//hide the row
				$("##" + rowId).hide();
				//try to delete the record
				$.ajax({
					url: apiBaseURI + "/artist/" + rowId,
					type: "delete",

					//if delete successful, remove the row
					success: function(){
						$(rowId).remove();
						alert("row deleted!");
					},

					//if delete failed, show the row and alert a message
					error: function(){
						$("##" + rowId).show();
						alert("Unable to delete record!");
					}
				});
			}
			function addRow(tableId, a, b, c, d, e, f, g, h, i, j, k){
				var row = $("<tr class='dyn' id='" + a + "'>"
							+ "<td>" + a + "</td>"
							+ "<td>" + b + "</td>"
							+ "<td>" + c + "</td>"
							+ "<td>" + d + "</td>"
							+ "<td>" + e + "</td>"
							+ "<td>" + f + "</td>"
							+ "<td>" + g + "</td>"
							+ "<td>" + h + "</td>"
							+ "<td>" + i + "</td>"
							+ "<td>" + j + "</td>"
							+ "<td>" + k + "</td>"
							+ "<td><a class='delete' href='##delete'>del</a> - <a href='##update' class='update'>upd</a></td>"
							+ "</tr>");
				$(tableId).append(row);
			}
			function updateRow(recordId){
				$.ajax({
					url: apiBaseURI + "/artist/" + recordId,
					type: "get",

					//if we can get the current status of the record then show the update form
					success: function(data, textStatus, xhr){
						console.log(data.DATA);
						$("##update").attr('action', apiBaseURI + "/artist/" + recordId);
						$("##update input[name='firstname']").val(data.DATA[0][1]);
						$("##update input[name='lastname']").val(data.DATA[0][2]);
						$("##update input[name='address']").val(data.DATA[0][3]);
						$("##update input[name='city']").val(data.DATA[0][4]);
						$("##update input[name='state']").val(data.DATA[0][5]);
						$("##update input[name='postalcode']").val(data.DATA[0][6]);
						$("##update input[name='email']").val(data.DATA[0][7]);
						$("##update input[name='phone']").val(data.DATA[0][8]);
						$("##update input[name='fax']").val(data.DATA[0][9]);
						$("##update input[name='thepassword']").val(data.DATA[0][10]);
						$("##update").show("slow");
					},

					//otherwise, show an error
					error: function(){
						alert('unable to get current status of record, sorry!');
					}
				});
			}
			function submitFrmViaAjax(frm, successCallback, errorCallback){
				frm.submit(function(e){
					e.preventDefault();
					var frm = $(this);
					$.ajax({
						url: frm.attr('action'),
						data: frm.serialize(),
						type: frm.attr('method'),
						success: successCallback,
						error: errorCallback
					});
				});
			}
		</script>
    </cfoutput>
</body>
</html>