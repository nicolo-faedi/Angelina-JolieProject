include "console.iol"
include "string_utils.iol"

type Repo: any {
	.repo[0, *]: Repo 
	.file[0, *]: File
	.version?: long
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
	root_path = "EASY/1";
  	fileToValue@Locale(root_path)(res);
  	valueToPrettyString@StringUtils(res)(r);
  	println@Console( "********STRUTTURA" )();
  	println@Console( r )()
  	//println@Console( res )()
}