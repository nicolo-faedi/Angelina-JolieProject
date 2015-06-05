include "console.iol"
include "interface.iol"

outputPort Locale {
	Protocol: sodep
	Interfaces: LocalInterface
}

inputPort Input {
	Location: "socket://localhost:8002"
	Protocol: sodep
	Interfaces: ClientInterface
}

embedded {
  Jolie: "FileManager.iol" in Locale
}


init
{
	//input.location = "socket://localhost:8000";
	global.name = "Server1";
	readXml@Locale( "Servers/"+global.name )( response );
	global.serverRoot << response;
	println@Console("Nuovo server avviato\n >ServerName: "+global.name+"\n")()

}

execution { concurrent }

main 
{  
	/* Riceve la richiesta di aggiunta server, ritorna true */
	[ addServer( server )( response ){
		response = true
	} ] { println@Console("- Un nuovo utente ha aggiunto il server")() }

	/* ..... */


}
