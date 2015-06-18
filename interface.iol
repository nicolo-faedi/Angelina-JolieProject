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
	.path: string
	.serverName: string
	.serverAddress: string
}

type Repo: string {
	.repo[0 , *]: Repo 
	.file[0 , *]: File
	.relativePath: string
	
}

type File: string {
	.relativePath: string
	.version: long
}

type PushList: void {
	.fileToPush[0 , *]: string
	.fileToPull[0 , *]: any
}

interface ClientInterface {
  	RequestResponse:	addServer( Server )( bool ),
  						getServerRepoList( void )( Struttura ),
  						versionStruttura( Repo )( PushList )

  	OneWay:				addRepository( RegRepo )
}

interface LocalInterface {
  	RequestResponse: 	readXml( string )( Struttura ),
    	               	updateXml( Struttura )( void ),
        	          	input( string )( void ),
        	          	fileToValue( Repo )( Repo ),
						getLastModString( string )( string )
}