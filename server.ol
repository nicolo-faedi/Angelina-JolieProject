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
	global.name = "Server666";
	readXml@Locale( "Servers/"+global.name )( response );
	global.root << response;
	println@Console("Nuovo server avviato\n >ServerName: "+global.name+"\n")();


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
	/* Riceve la richiesta di aggiunta server, ritorna true */
	[ addServer( server )( response ){
		response = true
	} ] { println@Console("- Un nuovo utente ha aggiunto il server")() }

	/* ..... */
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
					println@Console( "- Un utente ha aggiunto una repository" )();
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
			println@Console( "- Un utente ha provato ad aggiungere una repository" )()
		}

	} ]


}
