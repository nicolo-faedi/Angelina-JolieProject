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
  		      addRepository' [serverName] [repoName] [localPath]  Aggiunge una repository ai repo registrati. (Es. dal desktop)
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

        /*  Da testare if(repo != void)
            Da gestire l'errore di Connection Refused */
        else if ( command.result[0] +" "+ command.result[1] == "list new_repos" ) 
        {
            for(i=0, i<#global.serverList.server, i++) {
                Server.location = global.serverList.server[i].address;
                getListRepo@Server( )( repo );
                for(j=0, j<#repo, j++) 
                {
                    if(repo != void )
                    {
                        for(k = 0, k < #global.serverList.server[i].repo, k++) {
                            if(repo[j].name != global.serverList.server[i].repo[k].name) {
                                println@Console("SERVER: "+global.serverList.server[i].name+"\nREPO["+j+"] "+repo[j].name )()
                            }
                        }
                    }
                    else
                    {
                        println@Console("Attenzione: "+global.serverList.server[i].name+" Non ha repository nuove")()
                    }
                }
            }
          
        }
  		
        /* Da testare if(size!= 0)*/
        else if ( command.result[0]+" "+command.result[1] == "list reg_repos") 
  		{
  		    print@Console( "\n" )();
  		    size = #global.serverList.server.repo;
  		    if(size != 0)
  		    {
  		      for(i=0, i<#global.serverList.server, i++)
  		      {
  		        println@Console(global.serverList.server[i].name+"\t"+global.serverList.server[i].address)();
  		        for(j=0, j<#global.serverList.server[i].repo, j++)
  		        {
  		          println@Console("\t"+j+"\t"+global.serverList.server[i].repo[j].name+"\t"+global.serverList.server[i].repo[j].date+"\t"+global.serverList.server[i].repo[j].version)()
  		        };
  		        print@Console( "\n" )()
  		      }
  		    }
  		    else
  		    {
  		      println@Console("Attenzione: Nessun repo salvato\n")()
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
        /* */
        else if (command.result[0] == "addRepository")
        {

            with(command)
            {
                for(i=0, i<#serverList.server, i++) 
                {
                   if(serverList.server[i].name == .result[1]) 
                    {
                        Server.location = serverList.server[i].address
                    }
                };
                repo.name = .result[2];
                addRepository@Server(repo)(res);
                if(res)
                {
                    println@Console( "Il file esiste già sul server" )()
                }
                else
                {
                    println@Console( "Il file non esiste sul server, dunque lo sta creando" )()
                }
            }
        }
  		else
  		{
  		    println@Console( "Comando non riconosciuto, digita 'help' per la lista dei comandi" )()
  		}
    }
}