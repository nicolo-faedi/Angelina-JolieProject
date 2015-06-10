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
	RequestResponse:	rr( Repo )( Repo )
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
		listRequest.dirsOnly = true;
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
				println@Console( "FILE: "+listResponse.result[i] )();
				res.file[i] = listResponse.result[i]	
			}
		}
		//Se ho cartelle
		else
		{
			/*
				Va gestito il caso in cui in una cartella ci siano anche i file.
				ListRequest dirsOnly = false, 
				

			*/


			for(i=0, i<#listResponse.result, i++)
			{
				println@Console( "FOLDER: "+listResponse.result[i] )();
				rr@Out(repo+"/"+listResponse.result[i])(res2);
				res2 = repo+"/"+listResponse.result[i];
				res.repo[i] << res2;
				res.repo[i] = listResponse.result[i];
				res = repo
			}

			/*

			listRequest.dirsOnly = false;
			list@File(listRequest)(listResponse);

			j = 0;
			for(i=0, i<#listResponse.result, i++)
			{
				isDirectory@File(repo+"/"+listResponse.result[i])(r);
				if (!r)
				{
					j++;
					res.file[j]= listResponse.result[i]
				}
			} */
		}
	}

	/*rr(repo)(res){
		listRequest.directory = repo;
	 	list@File(listRequest)(listResponse);
		for(i=0, i<#listResponse.result, i++)
	 	{
	 		path = repo+"/"+listResponse.result[i];
	 		isDirectory@File(path)(r);
	 		if(r)
	 		{
	 			println@Console("FOLDER: "+path )();
	 			repo.repo[#repo.repo] = repo+"/"+listResponse.result[i];
	 			//repo.repo[#repo.repo] = listResponse.result[i];

	 			res << repo.repo;
	 			rr@Out(res)(res)
	 		}
			else
 			{
 				println@Console("FILE: "+path )();

 				repo.file[#repo.file] = repo+"/"+listResponse.result[i];

 				res << repo.file
 				
	 		}
 		};

 		
 		valueToPrettyString@StringUtils(res)(r);
  		println@Console( "********STRUTTURA" )();
  		println@Console( r )()
 	}*/
}