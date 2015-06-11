include "console.iol"
include "string_utils.iol"

main
{
	serverRoot.repo[0] = "Repo1";
	serverRoot.repo[1] = "Repo34";
	serverRoot.repo[2] = "Repositoto";
	serverRoot.repo[3] = "Reppo";
	serverRoot.repo[0].repo = "Funziona";

	serverRoot.repo[0].repo.repo = "FunzionaBis";
	
		//test = "repo";
		valueToPrettyString@StringUtils(serverRoot)(r);
		println@Console( "********STRUTTURA" )();
		println@Console( r )();

			serverRoot << serverRoot.repo[i];

		with(serverRoot) {
				println@Console( .repo )();
				valueToPrettyString@StringUtils(serverRoot)(r);
				println@Console( "********STRUTTURA" )();
				println@Console( r )()
			};

			serverRoot << serverRoot.repo[i];

		with(serverRoot) {
				println@Console( .repo )();
				valueToPrettyString@StringUtils(serverRoot)(r);
				println@Console( "********STRUTTURA" )();
				println@Console( r )()
			}

		/*test = "serverRoot.repo[0]";

		with(test) {
			println@Console( .repo )()
		}*/
}