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
	.repo[0,*]: Repo
	.file[0,*]: File
}

type File: void {
	.name: string
	.verison: long
	.data: raw
}

interface ClientInterface {
  	RequestResponse:	addServer( Server )( bool )
}

interface LocalInterface {
  	RequestResponse: 	readXml( string )( ServerList ),
    	               	updateXml( ServerList )( void ),
        	          	input( string )( any ) 
}