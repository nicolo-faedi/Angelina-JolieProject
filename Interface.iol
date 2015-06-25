type Struttura: void {
	.server[0,*]: Server
	.repo[0,*]: RegRepo
}

type Server: void {
	.name: string
	.address: string
}

//RegRepo è specifica per le repo registrate. Contiene il name.
//Contiene .path assoluto in locale e .serverName di riferimento
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
	.fileToPull[0 , *]: string
}

type RawList: void {
	.file[1 , *]: FileRequestType
}

type FileRequestType: void {
	.filename: string
	.content: raw
	.version: long
}

type SetVersion: void {
	.path: string
	.version: long
}

interface ClientInterface {
  	RequestResponse:	addServer( Server )( bool ),
  						getServerRepoList( void )( Struttura ),
  						versionStruttura( Repo )( PushList ),
  						pull( Repo )( RawList )

  	OneWay:				addRepository( RegRepo ),
  						push( RawList )
}

interface LocalInterface {
  	RequestResponse: 	readXml( string )( Struttura ),
    	               	updateXml( Struttura )( void ),
        	          	fileToValue( Repo )( Repo ),
						getLastModString( string )( string ),
						setLastMod( SetVersion )( string),
						isValidIp(string)(bool)
}
