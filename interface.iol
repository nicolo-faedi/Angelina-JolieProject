type Struttura: void {
	.server[0,*]: Server
	.repo[0,*]: RegRepo
}

type Server: void {
	.name: string
	.address: string
}

//RegRepo è specifica per le repo registrate. Contiene il name.
//Contiene .path locale e .serverName di riferimento
type RegRepo: void {
	.name: string
	.path?: string
	.serverName?: string
}

interface ClientInterface {
  	RequestResponse:	addServer( Server )( bool ),
  						addRepository( RegRepo )( void )
}

interface LocalInterface {
  	RequestResponse: 	readXml( string )( Struttura ),
    	               	updateXml( Struttura )( void ),
        	          	input( string )( void ) 
}