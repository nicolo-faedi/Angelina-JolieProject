include "console.iol"
include "string_utils.iol"


interface Interfaccia {
  RequestResponse: getLastModString(string)(string)
}

outputPort Javone {
	Interfaces: Interfaccia
}

embedded {
  Java: "example.Info" in Javone
}

main
{
	getLastModString@Javone("untitled")(res);
	var = long(res);
	println@Console( var )()
}