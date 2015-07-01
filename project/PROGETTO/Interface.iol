/*
	Progetto di Sistemi Operativi, Informatica per il Management 2014/15

	#### Team Angelina © ####
	Pietro Tamburini        Matr. 590603
	Nicolò Faedi            Matr. 694919
	Massimo-Maria Barbato   Matr. 732766
*/




/*
	Struttura viene utilizzata sia da client e da server.
	Nel primo caso (client), la struttura ha due liste, 
	una di regServer e una di regRepo. Nel secondo caso (server), 
	la struttura ha una sola lista contentente le regRepo del server.
	Questo tipo di struttura ci permette di utilizzare gli stessi 
	metodi all'interno del FileManager.ol 

*/
type Struttura: void {
	.server[0,*]: RegServer
	.repo[0,*]: RegRepo
}
/*
	RegServer contiene le informazioni relative ad un server registrato.
*/
type RegServer: void {
	.name: string
	.address: string
}

/*
	RegRepo contiene le informazioni relativa ad una repository registrata 
	e il suo server di provenienza. ".path" è il path assoluto locale.
*/
type RegRepo: void {
	.name: string
	.path: string
	.serverName: string
	.serverAddress: string
	//sRequest è il semaforo relativo ad una RegRepo. Non viene utilizzata nel Client Side
	.sDB?: SemaphoreRequest
	.sMutex?: SemaphoreRequest
	.readerCount?: int
}

type SemaphoreRequest: void { 
    .name:string
    .permits?:int
}

/*
	Repo è l'albero di una repository contenente altre repo o file.
	Contiene il suo relativePath che è uguale sia per Server e Clients.
*/
type Repo: string {
	.repo[0 , *]: Repo 
	.file[0 , *]: string {
		.relativePath: string
		.version: long
	}
	.relativePath: string
}

/*
	Contiene l'elenco dei nomi dei file da trasferire tra Client e Server
	FileRequest viene generato dalle operazioni di Push o Pull e contiene 
	le liste di fileToPull e fileToPush.
*/ 

type FileRequest: string {
	.fileToPush[0 , *]: string
	.fileToPull[0 , *]: string
}

/*
	Contiene il file binario(raw) per ogni file elencato nella FileRequest.
	Nel caso di una PushRequest, è il pacchetto di file inviato dal Client al Server.
	Nel caso della PullRequest, è il pacchetto di file inviato dal Server al Client.

	RawList: string --> Utilizzata per la pushrequest per identificare il semaforo associato
	alla repository in esame.
*/
type RawList: string {
	.file[0 , *]: void {
		.filename: string
		.content: raw
		.version: long
	}
}

/*
	SetVersion viene utilizzato per sincornizzare la versione di un file trasferito 
	dal Server al Client e viceversa. Nella pull request, il client si sincronizza 
	con il Server, nella push request, avviene il contrario. 
*/
type SetVersion: void {
	.path: string
	.version: long
}



interface ClientInterface {
  	RequestResponse:	addServer( RegServer )( bool ),
  						getServerRepoList( void )( Struttura ),
  						pushRequest( Repo )( FileRequest ),
  						pullRequest ( string )( Repo ),
  						pull ( FileRequest )( RawList )

  	OneWay:				addRepository( RegRepo ),
  						push( RawList ),
  						delete( string )
}

interface LocalInterface {
  	RequestResponse: 	readXml( string )( Struttura ),
    	               	updateXml( Struttura )( void ),
        	          	fileToValue( Repo )( Repo ),
						getLastModString( string )( string ),
						setLastMod( SetVersion )( string)
}
