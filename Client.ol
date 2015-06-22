include "Interface.iol"
include "console.iol"
include "file.iol"
include "string_utils.iol"

outputPort Locale {
  Location: "local"
  Interfaces: LocalInterface
}

embedded {
  Jolie: "ClientInput.ol" in Locale
}

main
{
    //Richiedo il nickname per localizzare la propria folder
    print@Console( "Insert Your Nickname > " )();
    registerForInput@Console()();
    in( user );

    //Uso la requestResponse del servizio ClientInput.ol per ottenere la struttura del folder in locale
    input@Locale("nickname "+user)(response);
    
    //Avvio il loop per gli input dell'utente
    while( cmd != "close")
    {
        print@Console( user+" > " )();
        registerForInput@Console()();
        in( cmd );
        input@Locale(cmd)()
    }
}