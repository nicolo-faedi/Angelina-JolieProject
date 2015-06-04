include "interface.iol"
include "console.iol"
include "file.iol"
include "xml_utils.iol"
include "string_utils.iol"

outputPort Output {
  Protocol: sodep
  Interfaces: ClientInterface
}

embedded {
  Jolie: "FileManager.ol" in Output
}

init
{
  global.serverList = "";
  global.name = ""
}

define eseguiComando
{
  input.regex = " ";
  split@StringUtils(input)(command);

  if ( command.result[0] == "close")
  {
    println@Console("
      Disconnessione in corso...
      Sessione conclusa.
      ")()
  } 
  else if( command.result[0] == "help")
  {
      //'help'  - fatto
      //'list ervers' - fatto
    println@Console("
      'close'                                               Chiude la sessione.
      'help'                                                Stampa la lista dei comandi 
      'list servers'                                        Visualizza la lista di Servers registrati.
      'list new_repos'                                      Visualizza la lista di repositories disponibili nei Server registrati.
      'list reg_repos' -                                    Visualizza la lista di repositories registrati localmente.
      'addServer [serverName] [serverAddress]               Aggiunge un nuovo Server alla lista dei Servers registrati.        
      'removeServer [serverName]'                           Rimuove 'serverName' dai Servers registrati.
      'addRepository' [serverName] [repoName] [localPath]   Aggiunge il repository ai repo registrati.
      'push [serverName] [repoName]                         Fa push dell’ultima versione di 'repoName' locale sul server 'serverName'.
      'pull [serverName] [repoName]                         Fa pull dell’ultima versione di 'repoName' dal server 'serverName'.        
      'delete [serverName] [repoName]                       Rimuove il repository dai repo registrati.\n")()
  } 
  else if ( command.result[0] +" "+ command.result[1] == "list servers") 
  {
    print@Console( "\n" )();
    size = #serverList.server;
    if(size != 0)
    {
      for(i=0, i<size, i++) {
        println@Console(serverList.server[i].name +"\t"+serverList.server[i].address)()
      };
      print@Console("\n")()
    }
    else
    {
      println@Console("Nessun server salvato\n")()
    }
  }
  else if ( command.result[0]+" "+command.result[1] == "list reg_repos") 
  {
    print@Console( "\n" )();
    size = #serverList.server.repo;
    if(size != 0)
    {
      for(i=0, i<#serverList.server, i++)
      {
        server << serverList.server[i];
        println@Console(server.name+"\t"+server.address)();
        for(j=0, j<#server.repo, j++)
        {
          println@Console("\t"+j+"\t"+server.repo[j].name+"\t"+server.repo[j].date+"\t"+server.repo[j].version)()
        };
        print@Console( "\n" )()
      }
    }
    else
    {
      println@Console("Nessun repo salvato\n")()
    }
  }
  else if ( command.result[0] == "addServer") 
  {
    install ( ConnectException => println@Console( "Connessione Rifiutata, server irraggiungibile" )() );
    s.name = command.result[1];
    s.address = command.result[2];
    Output.location = s.address;
    addServer@Output( s )( response );
    if(response)
    {
      //Aggiungo il server alla struttura
      serverList.server[#server] << s;
      Output.location = "local";
      updateLocalXml@Output(serverList)(r);
      println@Console( "Server aggiunto con successo" )()
    }
  }
  else if ( command.result[0] == "removeServer") 
  {
    s.serverName = command.result[1]
  }
  else if ( command.result[0] == "addRepository") 
  {
    request.serverName = command.result[1];
    request.repoName = command.result[2];
    request.localPath = command.result[3]
  }
  else
  {
    println@Console( "Comando non riconosciuto, digita 'help' per la lista dei comandi" )()
  }
}

main
{
  //Richiedo il nickname per localizzare la propria folder
  print@Console( "Insert Your Nickname > " )();
  registerForInput@Console()();
  in( name );
  //Uso la requestResponse del servizio FileManager.ol per ottenere la struttura del folder in locale
  readLocalXml@Output(name)(response);
  //Se l'albero restituito è vuoto, avviso l'utente
  if(response == void)
  {
    getServiceDirectory@File()(path);
    println@Console( "La cartella "+path+"/"+name+" è attualmente vuota\n" )()
  };
  //In ogni caso, salvo il Tree in una variabile serverList
  serverList << response;
  println@Console("Benvenuto, digita 'help' per visualizzare la lista dei comandi disponibili")();
  
  //Avvio il loop per gli input dell'utente
  while( input != "close")
  {
    print@Console( name+" > " )();
    registerForInput@Console()();
    in( input );
    eseguiComando
  }
}