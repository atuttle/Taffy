component{
	this.name = "TaffyTests";
	this.sessionManagement = true;

	this.parentFolder = reReplace( getDirectoryFromPath( getCurrentTemplatePath() ), '\/tests\/?$', '' );
	this.mappings[ "/tests" ] = this.parentFolder & '/tests';
	this.mappings[ "/taffy" ] = this.parentFolder;
	this.mappings[ "/resources" ] = this.parentFolder & '/tests/api/resources';
	this.mappings[ "/testbox" ] = this.parentFolder & '/testbox';

}
