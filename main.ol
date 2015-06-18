include "console.iol"
include "string_utils.iol"

type Repo: any {
	.repo[0, *]: Repo 
	.file[0, *]: File
}

type File: string {
	.version: long
}

interface Interfaccia {
	RequestResponse:	fileToValue( Repo )( Repo )
}

outputPort Locale 
{
	Location: "local"
	Protocol: sodep
	Interfaces: Interfaccia
}

embedded {
  Jolie: "FileToValue.ol" in Locale
}

main
{
	root_path = "TEST/EASY";
  	fileToValue@Locale(root_path)(res);
  	valueToPrettyString@StringUtils(res)(r);
  	println@Console( "********STRUTTURA" )();
  	println@Console( r )()
  	//println@Console( res )()
}