include "console.iol"
include "file.iol"
include "Interface.iol"
include "semaphore_utils.iol"
include "time.iol"
include "string_utils.iol"
include "queue_utils.iol"

constants {
	S_LOCATION = "socket://localhost:8000",
	S_NAME = "Server1",
	Timer_wait = 0
}

interface Interfaccia {
    RequestResponse:    setLastMod( SetVersion )( string ),
    					fileToValue( Repo )( Repo )
}

outputPort Locale {
	Protocol: sodep
	Interfaces: LocalInterface
}

inputPort Input {
	Location: S_LOCATION
	Protocol: sodep
	Interfaces: ClientInterface
}

outputPort JavaService {
	Interfaces: LocalInterface
}

embedded {
  Jolie: "FileManager.ol" in Locale,
  Java: "example.Info" in JavaService
}


init
{
	global.requests = 0;
	readXml@Locale( "Servers/"+S_NAME )( tree );
	global.root << tree;


	println@Console("SERVER AVVIATO
>Name: "+S_NAME+"
>Address: "+S_LOCATION+"
>Repositories: "+#global.root.repo+"
Attendo richieste...")();

	semafori
	

}

define semafori
{
  	//SEMAFORI
	sRequest.name = "xmlRes";
	sRequest.permits = 1;
	release@SemaphoreUtils(sRequest)(sResponse)

}

execution { concurrent }

main 
{  
	/* 	Riceve la richiesta di aggiunta server, ritorna true */
	[ addServer( server )( connection_response ){
		connection_response = true
	} ] { 
		global.request++;
		println@Console("Request#"+global.request+" : Un nuovo utente ha aggiunto il server")() }



	/* 	Riceve una repository da aggiungere.
		1. Controlla se la repo è già presente
		2. Se non è presente, aggiunge la repo alla struttura e all'xml.
		Gestisce la concorrenza sulla struttura global.root e sulla scrittura
		su xml. */
	[ addRepository( regRepo ) ]{
		//Partiamo dal presupposto che la repo non esista
		

		//Se è verificato, continuo
		
			regRepo.path = "Servers/"+S_NAME+"/"+regRepo.name;
			//Verifico se posso acquisire il semaforo
			flag = false;
			while(!flag)
			{
				acquire@SemaphoreUtils(sRequest)(sResponse);
				if(sResponse)
				{
					sleep@Time(Timer_wait)();
					a = false;
					for(i=0, i<#global.root.repo && !a, i++)
					{
						if(global.root.repo[i].name == regRepo.name)
						{
							a = true
						}
					};
				
					if(!a)
					{
						global.root.repo[#global.root.repo] << regRepo;
						updateXml@Locale(global.root)(r);
						mkdir@File( regRepo.path )( response );
						global.request++;
						println@Console("Request#"+global.request+" : Un utente ha aggiunto una nuova repository '"+regRepo.name+"'" )()
						
					}
					else
					{
						global.request++;
						println@Console("Request#"+global.request+" : Un utente ha provato ad aggiungere una repository già presente" )()
					};

					release@SemaphoreUtils(sRequest)(sResponse);
					flag = true
				}
			}
	} 


	
	/*

	*/
	[ getServerRepoList()( newRepoList ) {

		newRepoList << global.root
	}]



	/*

	*/
	[ versionStruttura( repo_tree )( list ) {
		flag = false;
		//Ottengo la struttura relativa alla repo inviata dal client
		//Cerco tra le regRepos Server
		for(i=0, i<#global.root.repo && !flag, i++)
		{
			if(repo_tree == global.root.repo[i].name)
			{
				flag = true
			}
		};


		//Se la trovo
		if(flag)
		{
			//Visita in ampiezza della repo_tree inviata dal client
			coda[0] << repo_tree;
			dim = #coda;

			while(dim > 0)
			{
				undef(tmpRoot);
				tmpRoot << coda[0];

				undef( coda[0] );
				dim = #tmpRoot;

				{
					for(i=0, i<#tmpRoot.repo, i++)
					{
						coda[#coda] << tmpRoot.repo[i];

						repo_path = "Servers/"+S_NAME+"/"+tmpRoot.repo[i].relativePath;
						exists@File(repo_path)(esiste);
						if(!esiste)
						{
							mkdir@File(repo_path)(mk_response)
						}
					} |

					for(j=0, j<#tmpRoot.file, j++)
					{
						file_path = "Servers/"+S_NAME+"/"+tmpRoot.file[j].relativePath;
						exists@File(file_path)(esiste);
						if(esiste)
						{
							getLastModString@JavaService(file_path)(s_version);
							server_version = long(s_version);

							if(server_version < tmpRoot.file[j].version)
							{
								list.fileToPush[#list.fileToPush] = tmpRoot.file[j].relativePath
							}
							else if (server_version > tmpRoot.file[j].version)
							{
								list.fileToPull[#list.fileToPull] = tmpRoot.file[j].relativePath
							}
						}
						else
						{
							list.fileToPush[#list.fileToPush] = tmpRoot.file[j].relativePath
						}
					}
				};
				dim = #coda
			}	
		}
	}] {
		global.request++;
		println@Console("Request#"+global.request+" : Effettuo il versioning di una nuova richiesta di push repository " )()
	}


	[ delete( repoName ) ] {
		repoTrovata = false;
		for( i=0 , i<#global.root.repo && !repoTrovata, i++)
		{
			if(global.root.repo[i].name == repoName)
			{
				repoTrovata = true;

				tempName = global.root.repo[i].name;
				tempRelativePath = "Servers/"+S_NAME+"/"+tempName;
				
				undef( global.root.repo[i] );
				updateXml@Locale(global.root)(r);

				deleteDir@File(tempRelativePath)(deleteRes);
				if(deleteRes)
				{
					global.request++;
					println@Console("Request#"+global.request+" : Un utene ha eliminato la repository "+tempName )()
				}
			}
		}
	}

	/*

	*/
	[ push( push_rawList ) ]{

		for(i=0, i<#push_rawList.file, i++)
		{
			push_rawList.file[i].filename = "Servers/"+S_NAME+"/"+push_rawList.file[i].filename;

			clientVersion.path = push_rawList.file[i].filename;
			clientVersion.version = push_rawList.file[i].version;
			undef(push_rawList.file[i].version);

			writeFile@File(push_rawList.file[i])();
			setLastMod@JavaService(clientVersion)(r)
		};
		println@Console("[SUCCESSO] : Push della repository è stata eseguita correttamente" )()		
	}



	[ pullRequest ( repoToPullName )( StrutturaRepoServer ) {

		repoTrovata = false;
		// Cerco se la repo è presente tra quelle del server
		for(j=0, j<#global.root.repo && !repoTrovata, j++)
        {
            if(global.root.repo[j].name == repoToPullName )
            {
                repoTrovata = true
            }
        };
        
        if ( !repoTrovata )
        {
        	StrutturaRepoServer = "NonTrovata";
        	StrutturaRepoServer.relativePath = ""
        }
        else 
        {
        	currentRepo = global.root.repo[ j -1 ].path;
        	currentRepo.relativePath = repoToPullName;
        	fileToValue@Locale( currentRepo )( StrutturaRepo );
        	StrutturaRepoServer << StrutturaRepo
        }


	}]

	
	[ pull( PullList )( pull_rawList ) {
		for( i = 0, i < #PullList.fileToPull, i++ ){
			// Assegno a filename il path assoluto su server
			file.filename = "Servers/"+S_NAME+"/"+PullList.fileToPull[ i ];
			// Assegno format per trasformare in raw
			file.format = format = "binary"; 
			readFile@File(file)( file.content );

			undef( file.format );

			getLastModString@JavaService ( file.filename )( version );
			file.version = long( version );
			file.filename = PullList.fileToPull[ i ];

			pull_rawList.file[ #pull_rawList.file ] << file;

			//Rimuovo i campi non voluti dal servizio ReadFile@File
            undef( file.content );
            undef( file.version )

		}
		
	}]


}
