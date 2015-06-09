include "console.iol"
include "string_utils.iol"

type Repo: string {
	.repo[0, *]: Repo 
	.file[0, *]: File
}

type File: string {
	.version?: long
}

interface me {
	RequestResponse:	rr(Repo)(any)
}

outputPort Locale 
{
	Location: "local"
	Protocol: sodep
	Interfaces: me
}

embedded {
  Jolie: "Ricorsione.ol" in Locale
}

main
{
	repo = "EASY";
  	rr@Locale(repo)(res);
  	valueToPrettyString@StringUtils(res)(r);
  	println@Console( "*****STRUTTURA" )();
  	println@Console( r )()
  	//println@Console( res )()
}