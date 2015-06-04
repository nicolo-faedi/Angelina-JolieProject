include "console.iol"
include "interface.iol"

inputPort input {
	Location: "socket://localhost:8000"
	Protocol: sodep
	Interfaces: ClientInterface
}

init
{
	//input.location = "socket://localhost:8000";
	global.name = "Server1";
	println@Console("Nuovo server avviato\n >ServerName: "+global.name+"\n")()
}

execution { concurrent }

main 
{  
	addServer( server )( response ){
		response = true;
		println@Console("- Un nuovo utente ha aggiunto il server")()
	}
}
