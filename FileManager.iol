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
	//Legge da file xml e inserisce i dati in un tree
	//Se il file xml non esiste, lo crea e restituisce il tree vuoto
	[ readXml( dir )( serverList ) {
		global.path = dir;

		exists@File(global.path)(esiste);
		//Se esiste 
		if(esiste)
		{
			//Leggo da file xml e inserisco la struttura in un tree
			f.filename = global.path+"/local.xml";
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
			//Creo la directory
			mkdir@File( global.path )( response );
			//Creo il file serverList.xml
			f.filename = global.path+"/local.xml";
			f.content = "<root />";
			writeFile@File( f )( void );
			//ritorno l'albero vuoto
			serverList = void
		}
	} ] 

	[ updateXml( serverList )( r ) {
      	request.rootNodeName = "root";
      	request.indent = true;
      	request.root << serverList;
      	//Ottengo il file xml
      	valueToXml@XmlUtils( request )( response );
      	//Scrivo su file
      	f.filename = global.path+"/local.xml";
      	f.content = response;
      	writeFile@File( f )( void )
	} ]
}