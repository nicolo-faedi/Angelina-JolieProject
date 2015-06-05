include "file.iol"
include "console.iol"
include "xml_utils.iol"
include "interface.iol"
include "string_utils.iol"

inputPort Input {
	Location: "local"
	Interfaces: LocalInterface
}
outputPort Server {
Protocol: sodep
Interfaces: ClientInterface
}
outputPort Locale {
  Protocol: sodep
  Interfaces: LocalInterface
}

embedded {
  Jolie: "FileManager.iol" in Locale
}  

init
{
  global.serverList = ""
}

execution{ sequential }

main
{
    /* Operazione che riceve dal client un comando, lo splitta se trova più args per 
    la regex = " ". La response è di tipo any*/ 
    input( cmd )( response ) 
    {
        cmd.regex = " ";
        split@StringUtils(cmd)(command);

        /* Termina l'esecuzione del client */
        if ( command.result[0] == "close")
  		{
  		    println@Console("
  		    Disconnessione in corso...
  		    Sessione conclusa.
  		    ")()
  		}

        /* Ricevo nickname seguito dal nome utente per ricercare il folder del client */
        else if(command.result[0] == "nickname")
        {
            path = "Clients/"+command.result[1];
            readXml@Locale(path)(tree);
            global.serverList << tree;
            if(response == void)
            {
                println@Console( "La cartella "+path+" è attualmente vuota\n" )()
            }
        }

        /* Stampo a video i comandi disponibili */
        else if( command.result[0] == "help")
  		{
            //'help'  - fatto
  		    //'list servers' - fatto
  		    //'addServer' - fatto
  		    //'removeServer' - fatto
  		    println@Console("
  		      close                                               Chiude la sessione.
  		      help                                                Stampa la lista dei comandi 
  		      list servers                                        Visualizza la lista di Servers registrati.
  		      list new_repos                                      Visualizza la lista di repositories disponibili nei Server registrati.
  		      list reg_repos                                      Visualizza la lista di tutti i repositories registrati localmente.
  		      addServer [serverName] [serverAddress]              Aggiunge un nuovo Server alla lista dei Servers registrati.        
  		      removeServer [serverName]                           Rimuove 'serverName' dai Servers registrati.
  		      addRepository' [serverName] [repoName] [localPath]  Aggiunge il repository ai repo registrati.
  		      push [serverName] [repoName]                        Fa push dell’ultima versione di 'repoName' locale sul server 'serverName'.
  		      pull [serverName] [repoName]                        Fa pull dell’ultima versione di 'repoName' dal server 'serverName'.        
  		      delete [serverName] [repoName]                      Rimuove il repository dai repo registrati.\n")()
  		} 
  		
        /* */
        else if ( command.result[0] +" "+ command.result[1] == "list servers") 
  		{
  		    print@Console( "\n" )();
  		    size = #global.serverList.server;
  		    if(size != 0)
  		    {
  		        for(i=0, i<size, i++) {
  		            println@Console(global.serverList.server[i].name +"\t"+global.serverList.server[i].address)()
  		        };
  		        print@Console("\n")()
  		    }
  		    else
  		    {
  		        println@Console("Attenzione: Nessun server salvato\n")()
  		    }
  		}
  		
        /* */
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
  		  
        /* */
        else if ( command.result[0] == "addServer") 
  		{
            s.name = command.result[1];
            s.address = command.result[2];
  		    flag = true;

  		    for(i=0, i<#global.serverList.server, i++)
  		    {
  		        if(global.serverList.server[i].address == s.address)
  		        {
  		            flag = false
  		        }
  		    };

  		    if(flag)
  		    {
                scope( fault_connection )
                {
                    install ( IOException => println@Console( "IOException: Non è possibile raggiungere il server" )() );
                    Server.location = s.address;
                    addServer@Server( s )( server_response )
                };
  		      
  		        if( server_response ) 
  		        { 
  		            global.serverList.server[#global.serverList.server] << s;
  		            updateXml@Locale(global.serverList)();
  		            println@Console( "Successo: Server aggiunto" )()
  		        }
  		    }
  		    else
  		    {
  		        println@Console( "Attenzione: Server già presente nella list servers" )()
  		    }
  		      
  		}

        /* */
        else if ( command.result[0] == "removeServer") 
  		{
  		    s.serverName = command.result[1];

  		    flag = false;
  		    for(i=0, i<#global.serverList.server, i++)
  		    {
  		        if(global.serverList.server[i].name == s.serverName)
  		        {
      		        flag = true;
      		        undef(global.serverList.server[i]);
      		        updateXml@Locale(global.serverList)();
      		        println@Console( "Successo: Server "+s.serverName+" eliminato" )()
      		    }
  		    };
  		    if(!flag)
  		    {
  		        println@Console( "Attenzione: Server "+s.serverName+" non trovato" )()
  		    }
  		}
  		else
  		{
  		    println@Console( "Comando non riconosciuto, digita 'help' per la lista dei comandi" )()
  		}
    }
}