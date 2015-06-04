include "file.iol"
include "console.iol"
include "xml_utils.iol"
include "interface.iol"

inputPort Input {
	Location: "local"
	Interfaces: ClientInterface
}

init
{
	global.name = "" 	
}

main
{
	//Legge da file xml e inserisce i dati in un tree
	//Se il file xml non esiste, lo crea e restituisce il tree vuoto
	readXml( name )( serverList ) {
		global.name = name;
		exists@File(name)(esiste);
		//Se esiste 
		if(esiste)
		{
			//Leggo da file xml e inserisco la struttura in un tree
			f.filename = name+"/serverList.xml";
			readFile@File(f)(file);
			file.options.charset = "UTF-8";
			file.options.schemaLanguage = "it";
			xmlToValue@XmlUtils( file )( tree );
			//Il response restituisce un tree con i dati letti
			serverList << tree
		}
		//Se non esiste
		else
		{
			mkdir@File( name )( response );
			name.file.filename = name+"/serverList.xml";
			name.file.content = "<root />";
			writeFile@File( name.file )( void );
			serverList = void
		}
	};

	updateXml( serverList )( r ) {
      	request.rootNodeName = "serverList";
      	request.indent = true;
      	request.root << serverList;
      	//Ottengo il file xml
      	valueToXml@XmlUtils( request )( response );
      	//Scrivo su file
      	f.filename = name + "/serverList.xml";
      	f.content = response;
      	writeFile@File( f )( void )
	}
}