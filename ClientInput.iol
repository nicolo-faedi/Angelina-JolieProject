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
    //root contiene .server (lista dei server registrati) e .repo(lista delle repo registrate)
    global.root = ""
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
            global.user = command.result[1];
            readXml@Locale(path)(tree);
            global.root << tree;
            if(response == void)
            {
                println@Console( "Ciao "+command.result[1]+", hai attualmente "+#global.root.server+" server e "+#global.root.repo+" repositories registrati.\nDigita 'help' per la lista dei comandi disponibili" )()
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
  		
        /* FATTO */
        else if ( command.result[0] +" "+ command.result[1] == "list servers") 
  		{
  		    if(#global.root.server != 0)
  		    {
                println@Console( "[Servers Registrati]" )();
  		        for(i=0, i<#global.root.server, i++) {
  		            println@Console("ServerName: "+global.root.server[i].name +"\tServerAddress: "+global.root.server[i].address)()
  		        }
  		    }
  		    else
  		    {
  		        println@Console("Attenzione: Nessun server salvato\n")()
  		    }
  		}
  		
        /* FATTO */
        else if ( command.result[0]+" "+command.result[1] == "list reg_repos") 
  		{
  		    if(#global.root.repo != 0)
  		    {
                println@Console( "[Repositories Registrate]" )();
  		        for(i=0, i<#global.root.repo, i++)
  		        {
  		            println@Console("RepoName: "+global.root.repo[i].name+" @ "+global.root.repo[i].serverName)()
  		        }
  		    }
  		    else
  		    {
  		      println@Console("Attenzione: Nessun repo salvato")()
  		    }
        }
  		  
        /* FATTO */
        else if ( command.result[0] == "addServer") 
  		{
            s.name = command.result[1];
            s.address = command.result[2];
  		    flag = true;

            //Controllo se ho già registrato il server 
  		    for(i=0, i<#global.root.server, i++)
  		    {
  		        if(global.root.server[i].address == s.address)
  		        {
  		            flag = false
  		        }
  		    };

            //Se non l'ho registrato, provo un handshake
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
  		            global.root.server[#global.root.server] << s;
  		            updateXml@Locale(global.root)();
  		            println@Console( "Successo: Server aggiunto" )()
  		        }
  		    }
  		    else
  		    {
  		        println@Console( "Attenzione: Server già presente nella list servers" )()
  		    }
  		      
  		}

        /* FATT0 */
        else if ( command.result[0] == "removeServer") 
  		{
  		    name = command.result[1];

  		    flag = false;
  		    for(i=0, i<#global.root.server, i++)
  		    {
  		        if(global.root.server[i].name == name)
  		        {
      		        flag = true;
      		        undef(global.root.server[i]);
      		        updateXml@Locale(global.root)();
      		        println@Console( "Successo: Server '"+name+"' eliminato" )()
      		    }
  		    };
  		    if(!flag)
  		    {
  		        println@Console( "Attenzione: Server '"+name+"' non trovato" )()
  		    }
  		}
        /* */

        else if (command.result[0] == "addRepository")
        {
            tmpServerName = command.result[1];
            tmpRepoName = command.result[2];
            localPath = command.result[3];
            
             
            //Controllo in concorrenza se ho il server e il repo richiesti
            a = false;
            b = true;

            tmpServer = "";

            {
                for(i=0, i<#global.root.server && !a, i++)
                {
                    if(global.root.server[i].name == tmpServerName)
                    {
                        tmpServer << global.root.server[i];
                        a = true
                    }
                } |
                for(j=0, j<#global.root.repo && b, j++)
                {
                    if(global.root.repo[j].name == tmpRepoName)
                    {
                        b = false
                    }
                }
            };   
        
            if(a && b)
            {
                tmp.name = tmpRepoName;
                tmp.path = localPath;
                tmp.serverName = tmpServerName;

                //controllo che il server sia online gestendo l'eccezione
                {
                    scope (fault_connection)
                    {
                        install ( IOException => println@Console( "IOException: Non è possibile raggiungere il server" )() );
                        Server.location = tmpServer.address;
                        addRepository@Server(tmp)()
                    } |

                    {
                        exists@File(tmp.path)(res);
                        global.root.repo[#global.root.repo] << tmp;
                        if(res)
                        {
                            println@Console( "Successo: Ho registrato '"+tmp+"'' ")()
                        }
                        else
                        {
                            mkdir@File( tmp.path )( response );
                            println@Console( "Attenzione: Non ho trovato '"+tmp.path+"', ho comunque creato la repository" )()
                        };
                        updateXml@Locale(global.root)(r)
                    }
                }
            }
            else if(!a)
            {
                println@Console( "Attenzione: Server non presente tra quelli registrati" )()
            }
            else if(!b)
            {
                println@Console( "Attenzione: Repositories già presente tra quelle registrate" )()
            }

            /*with(command)
            {
                for(i=0, i<#root.server, i++) 
                {
                   if(root.server[i].name == .result[1]) 
                    {
                        Server.location = root.server[i].address
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
            }*/
        }
  		else
  		{
  		    println@Console( "Comando non riconosciuto, digita 'help' per la lista dei comandi" )()
  		}
    }
}