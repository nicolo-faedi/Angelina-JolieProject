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
	Timer_wait = 6000
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

	global.rootReaderCount = 0;

	readXml@Locale( "Servers/"+S_NAME )( global.root );
	semafori;

	println@Console("SERVER AVVIATO

>Name: "+S_NAME+"
>Address: "+S_LOCATION+"
>Repositories: "+#global.root.repo+"

Attendo richieste...")()
}

define semafori
{
	//Creo un semaforo per la concorrenza sull'intera lista global.root
	//Un secondo semaforo per la concorrenza sul rootReaderCount
	{
		sRootRequest.name = "rootRes";
		sRootRequest.permits = 1;
		release@SemaphoreUtils(sRootRequest)(sRootResponse);

		sRootMutex.name = "rootMutex";
		sRootMutex.permits = 0;
		release@SemaphoreUtils(sRootMutex)(sRootResponse)
	}
		|

	//Creo un semaforo associato ad ogni RegRepo (global.root.repo)
	{
	  	for(i=0, i<#global.root.repo, i++)
	  	{
	  		global.root.repo[i].sDB.name = global.root.repo[i].name;
	  		global.root.repo[i].sDB.permits = 1;
	  		release@SemaphoreUtils(global.root.repo[i].sDB)(sResponse);

  		  	global.root.repo[i].sMutex.name = global.root.repo[i].name+"-mutex";
  		 	global.root.repo[i].sMutex.permits = 1;
  		  	release@SemaphoreUtils(global.root.repo[i].sMutex)(sResponse);

  		  	global.root.repo[i].readerCount = 0
	  	}
	}
}

define startReadRoot
{
	acquire@SemaphoreUtils(sRootMutex)(sRootResponse);
	global.rootReaderCount++;
	if(global.rootReaderCount == 1)
	{
		acquire@SemaphoreUtils(sRootRequest)(sRootResponse)
	};
	release@SemaphoreUtils(sRootMutex)(sRootResponse)
}

define endReadRoot
{
	acquire@SemaphoreUtils(sRootMutex)(sRootResponse);
	global.rootReaderCount--;
	if(global.rootReaderCount == 0)
	{
		release@SemaphoreUtils(sRootRequest)(sRootResponse)
	};
	release@SemaphoreUtils(sRootMutex)(sRootResponse)
}

define startWriteRoot
{

	acquire@SemaphoreUtils(sRootRequest)(sRootResponse)
}

define endWriteRoot
{

	release@SemaphoreUtils(sRootRequest)(sRootResponse)
}

define startReadRepo
{
	acquire@SemaphoreUtils(global.root.repo[i].sMutex)(sRepoResponse);
	global.root.repo[i].readerCount++;
	if(global.root.repo[i].readerCount == 1)
	{
		acquire@SemaphoreUtils(global.root.repo[i].sDB)(sRepoResponse)
	};
	release@SemaphoreUtils(global.root.repo[i].sMutex)(sRepoResponse)
}

define endReadRepo
{
  	acquire@SemaphoreUtils(global.root.repo[i].sMutex)(sRepoResponse);
  	global.root.repo[i].readerCount--;
  	if(global.root.repo[i].readerCount == 0)
  	{
  		release@SemaphoreUtils(global.root.repo[i].sDB)(sRepoResponse)
  	};
  	release@SemaphoreUtils(global.root.repo[i].sMutex)(sRepoResponse)
}

define startWriteRepo
{

  	acquire@SemaphoreUtils(global.root.repo[i].sDB)(sRepoResponse)
}

define endWriteRepo
{

	release@SemaphoreUtils(tempSemaforo)(sRepoResponse)
}

execution { concurrent }

main 
{  
	/* 	Riceve la richiesta di aggiunta server, ritorna true */
	[ addServer( server )( connection_response )
	{
		connection_response = true
	} ] 
		{
			println@Console("Un nuovo utente ha aggiunto il server")() 
		}



	/* 	Riceve una repository da aggiungere.
		1. Controlla se la repo è già presente
		2. Se non è presente, aggiunge la repo alla struttura e all'xml.
		Gestisce la concorrenza sulla struttura global.root e sulla scrittura
		su xml. */
	[ addRepository( regRepo ) ]
	{

		regRepo.path = "Servers/"+S_NAME+"/"+regRepo.name;

		//Acquisisco il lock per poter scrivere in global.root
		startWriteRoot;

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
			//Creo il nuovo semaforo per la nuova repository
			regRepo.sDB.name = regRepo.name;
			regRepo.sDB.permits = 1;
			release@SemaphoreUtils(regRepo.sDB)(sRepoResponse);

			regRepo.sMutex.name = regRepo.name+"-mutex";
			regRepo.sMutex.permits = 1;
			release@SemaphoreUtils(regRepo.sMutex)(sRepoResponse);

			sleep@Time(Timer_wait)();

			//Creo il path della repository
			mkdir@File( regRepo.path )( response );
			//Faccio un ulteriore controllo per evitare doppioni in global.root e nel XML
			if(response)
			{
				//Aggiungo la repository alla struttura
				global.root.repo[#global.root.repo] << regRepo;
				//Aggiorno l'xml
				updateXml@Locale(global.root)(r);
				
				println@Console("Un utente ha aggiunto una nuova repository '" +regRepo.name+ "'" )()
			}
			else
			{
				println@Console("Un utente ha provato ad aggiungere una repository appena creata da un altro utente" )()
			}
		}
		else
		{
			println@Console("Un utente ha provato ad aggiungere una repository già presente" )()
		};

		//Rilascio il lock a scrittura ultimata
		endWriteRoot
	} 

	
	/*

	*/
	[ getServerRepoList()( newRepoList ) 
	{
		startReadRoot;
		sleep@Time(Timer_wait)();
		newRepoList << global.root;
		endReadRoot;
		println@Console("Un utente ha richiesto la Server RegRepo List" )()
	} ]



	/*

	*/
	[ pushRequest( repo_tree )( list ) 
	{
		flag = false;
		//Ottengo la struttura relativa alla repo inviata dal client
		
		//Verifico se posso acquisire il semaforo su global.root
		startReadRoot;
		//Cerco tra le regRepos Server
		for(i=0, i<#global.root.repo && !flag, i++)
		{
			if(repo_tree == global.root.repo[i].name)
			{
				//Verifico se posso acquisire il lock sulla repo da aggiornare
				startWriteRepo;

				endReadRoot;

				sleep@Time(Timer_wait)();
				flag = true;
				//Rilascio il semaforo sul reader di global.root
				
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
						for(k=0, k<#tmpRoot.repo, k++)
						{
							coda[#coda] << tmpRoot.repo[k];

							repo_path = "Servers/"+S_NAME+"/"+tmpRoot.repo[k].relativePath;
							exists@File(repo_path)(esiste);
							if(!esiste)
							{
								mkdir@File(repo_path)(mk_response)
							}
						}
							|

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
		};
		//Rilascio il semaforo sul reader di global.root
		endReadRoot;
		list = repo_tree

	} ]

	/*

	*/
	[ push( push_rawList ) ]{

		if(#push_rawList.file != 0)
		{
			for(i=0, i<#push_rawList.file, i++)
			{
				push_rawList.file[i].filename = "Servers/"+S_NAME+"/"+push_rawList.file[i].filename;

				clientVersion.path = push_rawList.file[i].filename;
				clientVersion.version = push_rawList.file[i].version;
				undef(push_rawList.file[i].version);

				writeFile@File(push_rawList.file[i])();
				setLastMod@JavaService(clientVersion)(r)
			}
		};


		tempSemaforo.name = push_rawList;
		tempSemaforo.permits = 1;

		endWriteRepo;
		println@Console("Push della repository " + push_rawList + " eseguita correttamente" )()		
	}


	[ pullRequest ( repoToPullName )( StrutturaRepoServer ) {

		repoTrovata = false;

		//Verifico se posso acquisire il semaforo su global.root
		startReadRoot;

		// Cerco se la repo è presente tra quelle del server
		for(i=0, i<#global.root.repo && !repoTrovata, i++)
        {
            if(global.root.repo[i].name == repoToPullName )
            {
            	startReadRepo;
                repoTrovata = true
            }
        };

        endReadRoot;

        if ( !repoTrovata )
        {
        	StrutturaRepoServer = "NonTrovata";
        	StrutturaRepoServer.relativePath = ""
        }
        else 
        {
        	currentRepo = global.root.repo[ i-1 ].path;
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
		};

		pull_rawList = PullList;

		trovata = false;
		for (i = 0, i <#global.root.repo && !trovata, i++)
		{
			if (global.root.repo[i].name == PullList)
			{
				endReadRepo;
				trovata = true
			}
		}
	} ]
		{
			println@Console("Pull della repository "+ PullList +" eseguita correttamente")()
		}

	[ delete( repoName ) ] {
		repoTrovata = false;
		
		startWriteRoot;
		sleep@Time(Timer_wait)();
		for( i=0 , i<#global.root.repo && !repoTrovata, i++)
		{
			if(global.root.repo[i].name == repoName)
			{
				startWriteRepo;

				repoTrovata = true;

				tempName = global.root.repo[i].name;
				tempRelativePath = "Servers/"+S_NAME+"/"+tempName;
				
				undef( global.root.repo[i] );

				updateXml@Locale(global.root)(r);

				deleteDir@File(tempRelativePath)(deleteRes);
				if(deleteRes)
				{
					println@Console("Un utene ha eliminato la repository "+tempName )()
				}
			}
		};
		endWriteRoot
	}

}
