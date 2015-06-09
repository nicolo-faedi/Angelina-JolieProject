include "console.iol"
include "file.iol"
include "string_utils.iol"


type Repo: string {
	.repo[0, *]: Repo 
	.file[0, *]: File
}

type File: string {
	.version?: long
}

interface Interfaccia {
	RequestResponse:	rr( Repo )( any )
}

outputPort Out {
	Location: "local"
	Protocol: sodep
	Interfaces: Interfaccia
}

inputPort In {
	Location: "local"
	Protocol: sodep
	Interfaces: Interfaccia
}

embedded {
  Jolie: "Ricorsione.ol" in Out
}

execution{ concurrent }

main
{
	rr(repo)(res){

		listRequest.directory = repo;
	 	list@File(listRequest)(listResponse);
		for(i=0, i<#listResponse.result, i++)
	 	{
	 		isDirectory@File(repo+"/"+listResponse.result[i])(r);
	 		if(r)
	 		{
	 			println@Console("FOLDER: "+repo+"/"+listResponse.result[i] )();
	 			
	 			repo.repo[#repo.repo] = repo+"/"+listResponse.result[i];
	 			rr@Out(repo.repo[#repo.repo])(res)
	 		}
			else
 			{
 				println@Console("FILE: "+repo+"/"+listResponse.result[i] )();
 				repo.file[#repo.file] = repo+"/"+listResponse.result[i];
 				res << repo.file[#repo.file]
 				
	 		}
 		}
 	}
}