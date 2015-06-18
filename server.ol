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
	Timer_wait = 4000
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
		println@Console("Request#"+global.request+"] Un nuovo utente ha aggiunto il server")() }

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
						println@Console("Request#"+global.request+"] Un utente ha aggiunto una nuova repository '"+regRepo.name+"'" )()
						
					}
					else
					{
						global.request++;
						println@Console("Request#"+global.request+"] Un utente ha provato ad aggiungere una repository già presente" )()
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


	[ versionStruttura( repo_tree )( list ) {

		flag = false;
		//Ottengo la struttura relativa alla repo inviata dal client
		for(i=0, i<#global.root.repo && !flag, i++)
		{
			if(repo_tree == global.root.repo[i].name)
			{
				flag = true
			}
		};
		if(flag)
		{
			coda << repo_tree;
			dim = #coda;

			while(dim > 0)
			{
				undef(tmpRoot);
				tmpRoot << coda[0];
				undef( coda[0] );
				dim = #coda;

				for(i=0, i<#tmpRoot.repo, i++)
				{
					coda[#coda] << tmpRoot.repo[i];
					dim = #coda;

					repo_path = "Servers/"+S_NAME+"/"+tmpRoot.repo[i].relativePath;
					exists@File(repo_path)(esiste);
					if(!esiste)
					{
						mkdir@File(repo_path)(mk_response)
					}
				};

				for(j=0, j<#tmpRoot.file, j++)
				{
					file_path = "Servers/"+S_NAME+"/"+tmpRoot.file[i].relativePath;
					exists@File(file_path)(esiste);
					if(esiste)
					{
						getLastModString@JavaService(file_path)(s_version);
						server_version = long(s_version);
						println@Console( "SERVER VERSION: "+server_version + " - CLIENT VERSION: "+ tmpRoot.file[i].version)();
						if(server_version < tmpRoot.file[i].version)
						{
							list.fileToPush[#list.fileToPush] = tmpRoot.file[i].relativePath
						}
						else if (server_version > tmpRoot.file[i].version)
						{
							list.fileToPull[#list.fileToPull] = tmpRoot.file[i].relativePath
						}
					}
					else
					{
						list.fileToPush[#list.fileToPush] = tmpRoot.file[i].relativePath
					}
				}
			}	
		}
	}]


}

