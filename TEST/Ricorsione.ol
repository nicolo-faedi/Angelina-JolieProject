include "console.iol"
include "file.iol"
include "string_utils.iol"


type Repo: any {
	.repo[0, *]: Repo 
	.file[0, *]: File
}

type File: string {
	.version: long
}

interface Interfaccia {
	RequestResponse:	fileToValue( Repo )( Repo ),
						getLastModString(string)(string)
}

outputPort Out {
	Location: "local"
	Protocol: sodep
	Interfaces: Interfaccia
}

outputPort JavaService {
	Interfaces: Interfaccia
}

inputPort In {
	Location: "local"
	Protocol: sodep
	Interfaces: Interfaccia
}

embedded {
  Jolie: "Ricorsione.ol" in Out,
  Java: "example.Info" in JavaService
}

execution{ concurrent }

main
{

	fileToValue(repo)(res){
		with( listRequest ){
			.directory = repo;
			.dirsOnly = true	  
		};
		list@File(listRequest)(listResponse);

		//Se non ho cartelle
		if(#listResponse.result == 0) 
		{
			listRequest.dirsOnly = false;
			list@File(listRequest)(listResponse);
			//Se ho file
			res = repo;

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
				isDirectory@File(repo+"/"+listResponse.result[i])(r);
				res = repo;
				if(r)
				{
					//println@Console( "FOLDER: "+listResponse.result[i] )();
					fileToValue@Out(repo+"/"+listResponse.result[i])(res2);
					//res2 = repo+"/"+listResponse.result[i];
					//println@Console( "RES2: "+res2 )();
					
					with(res)
					{
						.repo[j] << res2;
						.repo[j] = listResponse.result[i]
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