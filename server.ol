include "console.iol"
include "file.iol"
include "Interface.iol"
include "semaphore_utils.iol"
include "time.iol"

constants {
	S_LOCATION = "socket://localhost:8000",
	S_NAME = "Server1",
	Timer_wait = 10000
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

embedded {
  Jolie: "FileManager.ol" in Locale
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


	[ versionStruttura( repo_tree )( update_tree ) {

		//Ottengo la struttura relativa alla repo inviata dal client
		for(i=0, i<#global.root.repo, i++)
		{
			if(repo_tree.name == global.root.repo[i].name)
			{
				listRequest.directory = global.root.repo[i].path;
				println@Console( global.root.repo[i].path )();
				list@File(listRequest)(listResponse);

				println@Console( "CLIENT: "+#repo_tree.repo )();
				println@Console( "SERVER: "+#listResponse.result )()
			}
		}
	}]
}

