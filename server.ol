include "console.iol"
include "file.iol"
include "interface.iol"
include "semaphore_utils.iol"
include "time.iol"

outputPort Locale {
	Protocol: sodep
	Interfaces: LocalInterface
}

inputPort Input {
	Location: "socket://localhost:8002"
	Protocol: sodep
	Interfaces: ClientInterface
}

embedded {
  Jolie: "FileManager.iol" in Locale
}


init
{
	global.name = "Server1";
	global.requests = 0;
	readXml@Locale( "Servers/"+global.name )( tree );
	global.root << tree;
	println@Console("SERVER AVVIATO
>Name: "+global.name+"
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
	[ addRepository( regRepo )(){
		//Partiamo dal presupposto che la repo non esista
		a = false;
		for(i=0, i<#global.root.repo && !a, i++)
		{
			if(global.root.repo[i].name == regRepo.name)
			{
				a = true
			}
		};

		//Se è verificato, continuo
		if(!a)
		{
			regRepo.path = "Servers/"+global.name+"/"+regRepo.name;
			flag = false;
			while(!flag)
			{
				acquire@SemaphoreUtils(sRequest)(sResponse);
				if(sResponse)
				{
					//sleep@Time(20000)();
					global.root.repo[#global.root.repo] << regRepo;
					updateXml@Locale(global.root)(r);

					release@SemaphoreUtils(sRequest)(sResponse);
					mkdir@File( regRepo.path )( response );

					global.request++;
					println@Console("Request#"+global.request+"] Un utente ha aggiunto una nuova repository '"+regRepo.name+"'" )();
					flag = true
				}
				else 
				{
					println@Console( "LA RISORSA NON E' DISPONIBILE" )()
				}
			}
			
		}
		else
		{
			global.request++;
			println@Console("Request#"+global.request+"] Un utente ha provato ad aggiungere una repository già presente" )()
		}

	} ]


}
