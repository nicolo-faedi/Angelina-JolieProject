type ServerList: void {
	.server[0,*]: Server
}

type Server: void {
	.name: string
	.address: string
	.repo[0,*]: Repo 
}

type Repo: void {
	.name: string
	.date: string
	.version: int
}

interface ClientInterface {
  	RequestResponse:	addServer( Server )( bool ),
  					  	readLocalXml( string )( ServerList ),
  					  	updateLocalXml( ServerList )(bool) 					  	
}