/*
	Progetto di Sistemi Operativi, Informatica per il Management 2014/15

	#### Team Angelina © ####
	Pietro Tamburini        Matr. 590603
	Nicolò Faedi            Matr. 694919
	Massimo-Maria Barbato   Matr. 732766
*/
include "console.iol"
include "file.iol"
include "Interface.iol"
include "string_utils.iol"

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
		//getLastModString@JavaService( repo )( modRes );
		//repo.version = long( modRes );

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
					res.file[#res.file-1].version = long( modRes );

					res.file[#res.file-1].relativePath = res.relativePath+"/"+listResponse.result[i]
				}
				
			}
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
					tempRepo = res+"/"+listResponse.result[i];
					tempRepo.relativePath = res.relativePath+"/"+listResponse.result[i];

					fileToValue@Out(tempRepo)(res2);
					
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
						
						res.file[#res.file-1].version = long( modRes );
						//println@Console( res.file[#res.file-1].version )();
						res.file[#res.file-1].relativePath = res.relativePath+"/"+listResponse.result[i]
					}
				}
			}
		}
	}
}