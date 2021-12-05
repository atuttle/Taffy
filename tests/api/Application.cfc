component extends="core.api" {

	this.name = "TaffyTests";

	this.rootFolder = reReplace( getDirectoryFromPath( getCurrentTemplatePath() ), '\/tests\/api\/?$', '' );
	this.mappings[ "/taffy" ] = this.rootFolder;
	this.mappings[ "/resources" ] = this.rootFolder & '/tests/api/resources';

}
