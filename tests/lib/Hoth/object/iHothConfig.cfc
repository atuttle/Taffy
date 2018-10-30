/**
	Aaron Greenlee
	http://aarongreenlee.com/

	This work is licensed under a Creative Commons Attribution-Share-Alike 3.0
	Unported License.

	// Original Info -----------------------------------------------------------
	Author			: Aaron Greenlee
	Created      	: 10/01/2010

	Interface for a Hoth Config Object.

*/
interface  {
	public function init ();
	public string function getLogPathExpanded();
	public string function getPath (name);
}