component {

	/**
	 * Walks the metadata chain to check if an object extends a given class.
	 * Works around Lucee's isInstanceOf() bug with mapped paths.
	 */
	public boolean function extendsClass(required any obj, required string className) {
		if (!isObject(arguments.obj)) return false;
		var meta = getMetadata(arguments.obj);
		while (structKeyExists(meta, "name")) {
			if (listLast(meta.name, ".") == listLast(arguments.className, ".")) return true;
			if (!structKeyExists(meta, "extends")) break;
			meta = meta.extends;
		}
		return false;
	}

}
