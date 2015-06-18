include "console.iol"
include "file.iol"
include "Interface.iol"
include "string_utils.iol"




interface Interfaccia {
	RequestResponse:	fileToValue( Repo )( Repo ),
						getLastModString(string)(string)
}

outputPort Out {
	Location: "local"
	Interfaces: LocalInterface
}

outputPort JavaService {
	Interfaces: LocalInterface
}

inputPort In {
	Location: "local"
	Interfaces: LocalInterface
}

embedded {
  Jolie: "FileToValue.ol" in Out,
  Java: "example.Info" in JavaService
}

execution{ concurrent }

main
{

	fileToValue(repo)(res){

		//Ottengo il lastModified della repo corrente
		getLastModString@JavaService( repo )( modRes );
		repo.version = long( modRes );

		with( listRequest ){
			.directory = repo;
			.dirsOnly = true	  
		};

		//Ottengo la lista dei File/Folder della repo corrente
		list@File(listRequest)(listResponse);

		//Se non ho cartelle
		if(#listResponse.result == 0) 
		{
			listRequest.dirsOnly = false;
			list@File(listRequest)(listResponse);
			//Se ho file
			res << repo;

			for(i=0, i<#listResponse.result, i++) 
			{
				//Qui ottengo i file
				//println@Console( "FILE: "+listResponse.result[i] )();
				if(listResponse.result[i] != ".DS_Store")
				{
					//Aggiungo alla struttura il file e ottengo l'ultima modifica effettuata sul file
					res.file[#res.file] = listResponse.result[i];
					getLastModString@JavaService( res+"/"+listResponse.result[i] )( modRes );
					res.file[#res.file-1].version = long(modRes)
				}
				
			}
			//println@Console( "RES1: " +res )()
		}
		//Se ho cartelle
		else
		{
			listRequest.dirsOnly = false;
			list@File(listRequest)(listResponse);
			j = 0;
			for(i=0, i<#listResponse.result, i++)
			{
				res << repo;

				isDirectory@File(res+"/"+listResponse.result[i])(r);
				if(r)
				{
					//println@Console( "FOLDER: "+listResponse.result[i] )();
					fileToValue@Out(res+"/"+listResponse.result[i])(res2);
					//res2 = repo+"/"+listResponse.result[i];
					//println@Console( "RES2: "+res2 )();
					
					with(res)
					{
						.repo[j] << res2;
						.repo[j] = listResponse.result[i]
						//getLastModString@JavaService( res2 )( modRes );
						//.version = long(modRes)
					};
					j++

				}
				else
				{
					if(listResponse.result[i] != ".DS_Store")
					{
						//Aggiungo alla struttura il file e ottengo l'ultima modifica effettuata sul file
						res.file[#res.file] = listResponse.result[i];
						getLastModString@JavaService( res+"/"+listResponse.result[i] )( modRes );
						res.file[#res.file-1].version = long(modRes)
					}
				}
			}
		}
	}
}