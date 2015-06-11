include "console.iol"
include "file.iol"
include "string_utils.iol"


type Repo: any {
	.repo[0, *]: Repo 
	.file[0, *]: File
}

type File: string {
	.version?: long
}

interface Interfaccia {
	RequestResponse:	readFile( Repo )( Repo )
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

	readFile(repo)(res){
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
				//println@Console( "FILE: "+listResponse.result[i] )();
				if(listResponse.result[i] != ".DS_Store")
					res.file[#res.file] = listResponse.result[i]	
				
			}
			//println@Console( "RES1: " +res )()
		}
		//Se ho cartelle
		else
		{
			listRequest.dirsOnly = false;
			list@File(listRequest)(listResponse);

			for(i=0, i<#listResponse.result, i++)
			{
				isDirectory@File(repo+"/"+listResponse.result[i])(r);
				res = repo;
				if(r)
				{
					//println@Console( "FOLDER: "+listResponse.result[i] )();
					readFile@Out(repo+"/"+listResponse.result[i])(res2);
					//res2 = repo+"/"+listResponse.result[i];
					//println@Console( "RES2: "+res2 )();
					
					with(res)
					{
						.repo[i] << res2;
						.repo[i] = listResponse.result[i]
					}

				}
				else
				{
					if(listResponse.result[i] != ".DS_Store")
						res.file[#res.file]= listResponse.result[i]
				}
			}
		}
	}
}