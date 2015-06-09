include "console.iol"
include "file.iol"


interface Interfaccia {
	RequestResponse:	rr( string )( any )
	OneWay: 			add(any)
}


inputPort Input {
Location: "local"
Protocol: sodep
Interfaces: Interfaccia
}

outputPort Locale 
{
	Location: "local"
	Protocol: sodep
	Interfaces: Interfaccia
}

execution{ sequential }



main
{
	add(s) {

	}
  	
}