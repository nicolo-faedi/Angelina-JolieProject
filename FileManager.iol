include "file.iol"
include "console.iol"
include "xml_utils.iol"
include "interface.iol"

inputPort Input {
	Location: "local"
	Interfaces: LocalInterface
}

init
{
  	global.path = ""
}

execution{ sequential }

main
{
	/*	Leggo da file xml e inserisce i dati in un tree,
		Se il file xml non esiste, lo crea e restituisce il tree vuoto.
		Se esiste, controllo se esistono ancora tutti i path delle repository,
		e se non esistono, avverto l'utente.
		Alla sovrascrittura dell'xml, FileManager non avviserà più del path non trovato. */
	[ readXml( dir )( root ) {
		global.path = dir;

		exists@File(global.path)(esiste);
		//Se esiste 
		if(esiste)
		{
			//Leggo da file xml e inserisco la struttura in un tree
			f.filename = global.path+"/config.xml";
			readFile@File(f)(file);
			file.options.charset = "UTF-8";
			file.options.schemaLanguage = "it";
			xmlToValue@XmlUtils( file )( tree );

			//CONTROLLO I PATH DELLE REPO, se non esistono, le rimuovo dalla struttura
			for(i=0, i<#tree.repo, i++)
			{
				exists@File(tree.repo[i].path)(e);
				if(!e)
				{
					println@Console( "FILE MANAGER: "+tree.repo[i].path+" non trovato" )();
					undef( tree.repo[i] )
				}
			};

			//Il response restituisce un tree con i dati letti
			root << tree
		}
		//Se non esiste
		else
		{
			//Creo la directory
			mkdir@File( global.path )( response );
			//Creo il file client_config.xml
			f.filename = global.path+"/config.xml";
			f.content = "<root />";
			writeFile@File( f )( void );
			//ritorno l'albero vuoto
			root = void
		}
	} ] 

	/*	Accetta in ingresso una struttura e la trasferisce sul file xml. */
	[ updateXml( root )( xmlUpdate_res ) {
      	request.rootNodeName = "root";
      	request.indent = true;
      	request.root << root;
      	//Ottengo il file xml
      	valueToXml@XmlUtils( request )( response );
      	//Scrivo su file
      	f.filename = global.path+"/config.xml";
      	f.content = response;
      	writeFile@File( f )( void )
	} ]
}