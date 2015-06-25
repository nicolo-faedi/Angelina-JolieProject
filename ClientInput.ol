include "file.iol"
include "console.iol"
include "xml_utils.iol"
include "Interface.iol"
include "string_utils.iol"
include "exec.iol"

interface Interfaccia {
    RequestResponse:    getLastModString(string)(string)
}

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

outputPort JavaService {
    Interfaces: LocalInterface
}

embedded {
  Jolie: "FileManager.ol" in Locale,
  Java: "example.Info" in JavaService
}  

init
{
    //root contiene .server (lista dei server registrati) e .repo(lista delle repo registrate)
    global.root = ""
}

execution{ sequential }

main
{
    /*  Operazione che riceve dal client un comando, lo splitta se trova più args per 
        la regex = " ".*/
    input( cmd )( ) 
    {
        cmd.regex = " ";
        split@StringUtils(cmd)(command);

        /*  Termina l'esecuzione del client */
        if ( command.result[0] == "close")
  		{
  		    println@Console("Disconnessione in corso...\nSessione conclusa.")()
  		}

        /*  Pulisce la schermata del terminale */
        else if ( command.result[0] == "clear" ) {
            cmdRequest = "clear";
            exec@Exec( cmdRequest )( cmdResponse );
            print@Console( cmdResponse )()
        }

        /*  Ricevo nickname seguito dal nome utente da client.ol per ricercare il folder del client e ottenere la struttura
            da FileManager.ol */
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

        /*  Stampo a video i comandi disponibili */
        else if( command.result[0] == "help")
  		{
  		    println@Console("
                close                                               Chiude la sessione.
                help                                                Stampa la lista dei comandi.
                clear                                               Pulisce il terminale.
                list servers                                        Visualizza la lista di Servers registrati.
                list new_repos                                      Visualizza la lista di repositories disponibili nei Server registrati.
                list reg_repos                                      Visualizza la lista di tutti i repositories registrati localmente.
                addServer [serverName] [serverAddress]              Aggiunge un nuovo Server alla lista dei Servers registrati.        
                removeServer [serverName]                           Rimuove 'serverName' dai Servers registrati.
                addRepository [serverName] [repoName] [localPath]   Aggiunge una repository ai repo registrati. (Es. dal desktop)
                push [serverName] [repoName]                        Fa push dell’ultima versione di 'repoName' locale sul server 'serverName'.
                pull [serverName] [repoName]                        Fa pull dell’ultima versione di 'repoName' dal server 'serverName'.        
                delete [serverName] [repoName]                      Rimuove il repository dai repo registrati.\n")()
  		} 
  		
        /*  Stampo a video la lista dei server contenuti in root.server */
        else if ( command.result[0] +" "+ command.result[1] == "list servers") 
  		{
  		    if(#global.root.server != 0)
  		    {
                println@Console( "[Servers Registrati #"+#global.root.server+"]" )();
  		        for(i=0, i<#global.root.server, i++) {
  		            println@Console("ServerName: "+global.root.server[i].name +"\tServerAddress: "+global.root.server[i].address)()
  		        }
  		    }
  		    else
  		    {
  		        println@Console("[ATTENZIONE]: Nessun server salvato")()
  		    }
  		}


        else if( command.result[0] +" "+ command.result[1] == "list new_repos" )
        {
            if(#global.root.server != 0)
            {
                for(i=0, i<#global.root.server, i++)
                {
                    scope (fault_connection)
                    {
                        install( IOException => println@Console("[ATTENZIONE] : "+global.root.server[i].name+" @ "+global.root.server[i].address+" - Non raggiungibile" )() );
                        Server.location = global.root.server[i].address;
                        getServerRepoList@Server()(newRepoList);
                        if(#newRepoList.repo != 0)
                        {
                            println@Console( global.root.server[i].name+" @ "+global.root.server[i].address)();
                            for(j=0, j<#newRepoList.repo, j++)
                            {
                                println@Console( j+"] "+newRepoList.repo[j].name )()
                            }
                        }
                        else
                        {
                            println@Console( global.root.server[i].name+" @ "+global.root.server[i].address+" Non ha repositories" )()
                        }
                    }
                }
            }
        }
  		
        /*  Stampo a video la lista dei server contenuti in root.repo */
        else if ( command.result[0]+" "+command.result[1] == "list reg_repos") 
  		{
  		    if(#global.root.repo != 0)
  		    {
                println@Console( "[Repositories Registrate #"+#global.root.repo+"]" )();
  		        for(i=0, i<#global.root.repo, i++)
  		        {
  		            println@Console("Repo: "+global.root.repo[i].name+"\t("+global.root.repo[i].path+")\t@ "+global.root.repo[i].serverName)()
  		        }
  		    }
  		    else
  		    {
  		      println@Console("[ATTENZIONE]: Nessun repo salvato")()
  		    }
        }
  		  
        /*  Provo a contattare il server passato dagli args result[1] e [2],
            Se ricevo risposta, aggiungo il server alla struttura e all'xml */
        else if ( command.result[0] == "addServer") 
  		{
            newServer.name = command.result[1];
            newServer.address = command.result[2];
            if(is_defined( newServer.name ) && is_defined( newServer.address ))
            {
      		    flag = true;

                //Controllo se ho già registrato il server 
      		    for(i=0, i<#global.root.server && flag, i++)
      		    {
      		        if(global.root.server[i].address == newServer.address)
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
                        Server.location = newServer.address;
                        addServer@Server( newServer )( server_response )
                    };
      		        //Se ricevo risposta aggiungo il server alla struttura
      		        if( server_response ) 
      		        { 
      		            global.root.server[#global.root.server] << newServer;
      		            updateXml@Locale(global.root)(xmlUpdate_res);
      		            println@Console( "[SUCCESSO]: Server aggiunto" )()
      		        }
      		    }
      		    else
      		    {
      		        println@Console( "[ATTENZIONE]: Server già presente nella list servers" )()
      		    }
            }
            else
            {
                println@Console( "[ATTENZIONE]: Definire correttamente i parametri [serverName] e [serverAddress]" )()
            }
  		}

        /*  Cerco se il server è presente nella struttura, se sì lo elimino e 
            aggiorno il file xml */
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
      		        println@Console( "[SUCCESSO]: Server '"+name+"' eliminato" )()
      		    }
  		    };
  		    if(!flag)
  		    {
  		        println@Console( "[ATTENZIONE]: Server '"+name+"' non trovato" )()
  		    }
  		}
        
        /*  Controllo in parallelo
            - Il server sia presente fra quelli aggiunti
            - La repository non sia già stata aggiunta
            Se passo questo check, sempre in parallelo
            - Contatto il server e gli invio la repository, starà a lui gestirsela
            - Controllo se il path passato esiste, altrimenti lo creo e aggiorno l'xml */
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
                undef( tmp );
                tmp.name = tmpRepoName;
                tmp.path = localPath;
                tmp.serverName = tmpServerName;
                tmp.serverAddress = tmpServer.address;

                //controllo che il server sia online gestendo l'eccezione
                {
                    scope (fault_connection)
                    {
                        install ( IOException => println@Console( "IOException: Non è possibile raggiungere il server" )() );
                        Server.location = tmpServer.address;
                        addRepository@Server(tmp)
                    } |

                    {
                        exists@File(tmp.path)(res);
                        global.root.repo[#global.root.repo] << tmp;
                        if(res)
                        {
                            println@Console( "[SUCCESSO]: Ho registrato '"+tmp.name+"'@ "+tmp.serverName)()
                        }
                        else
                        {
                            mkdir@File( tmp.path )( response );
                            println@Console( "[ATTENZIONE]: Non ho trovato '"+tmp.path+"', ho comunque creato la repository" )()
                        };
                        updateXml@Locale(global.root)(r)
                    }
                }
            }
            else if(!a)
            {
                println@Console( "[ATTENZIONE]: Server non presente tra quelli registrati" )()
            }
            else if(!b)
            {
                println@Console( "[ATTENZIONE]: Repository già presente tra quelle registrate" )()
            }
        }

        /* */
        else if (command.result[0] == "push")
        {

            flag = false;
            //Controllo se la repo è registrata
            for(i=0, i<#global.root.repo && !flag, i++)
            {
                if(global.root.repo[i].name == command.result[2] && global.root.repo[i].serverName == command.result[1])
                {
                    scope( fault_connection )
                    {
                        install( IOException => println@Console( "IOException: Non è possibile raggiungere il server" )() );
                        //Otteniamo la struttura/sottostruttura di quella repo
                        undef( tmpRepo );
                        tmpRepo = global.root.repo[i].path;
                        tmpRepo.relativePath = global.root.repo[i].name; 
                        fileToValue@Locale(tmpRepo)(repo_tree);
                        repo_tree = global.root.repo[i].name;

                        
                        Server.location = global.root.repo[i].serverAddress;
                        versionStruttura@Server( repo_tree )( pushList );
                        //println@Console( "Attendo risposta server.." )();

                        {
                            if(#pushList.fileToPush > 0)
                            {
                            
                                for(k=0, k<#pushList.fileToPush, k++)
                                {
                                    
                                    //Elimino dall'absolute path il reponame e aggiungo il relative path del file
                                    length@StringUtils(global.root.repo[i].path)(absoluteLength);
                                    length@StringUtils(global.root.repo[i].name)(reponameLength);
                                    sub_request = global.root.repo[i].path;
                                    sub_request.begin = 0;
                                    sub_request.end = absoluteLength - reponameLength;
                                    substring@StringUtils(sub_request)(sub_res);

                                    file.filename = sub_res+pushList.fileToPush[k];

                                    //println@Console( file.filename )();
                                    file.format = format = "binary";

                                    readFile@File(file)(file.content);

                                    file.filename = pushList.fileToPush[k];

                                    //Ottengo la versione del file in esame
                                    getLastModString@JavaService (sub_res+pushList.fileToPush[k])( v );
                                    file.version = long(v);

                                    undef( file.format );
                                    rawList.file[#rawList.file] << file;

                                    //println@Console( file.version )();
                                    //Rimuovo i campi non voluti dal servizio ReadFile@File
                                    undef( file.content );
                                    undef( file.version )
                                    
                                }; 
                                //INVIA I FILE AL SERVER
                                push@Server(rawList);
                                println@Console( "[SUCCESSO] : La pushRequest è stata inviata al server" )()
                            }
                            
                            ;
                                
                            if (#pushList.fileToPull>0)
                            {
                                println@Console( "[ATTENZIONE] : Devi effettuare la pull della repository per i seguenti file non aggiornati" )();
                                for(j=0, j<#pushList.fileToPull, j++)
                                {
                                    println@Console(pushList.fileToPull[j] )()
                                    //STAMPO FILE TO PULL
                                }
                            }
                        }                        
                    };
                    
                    flag = true
                }
            };
            //Se NO
            if(!flag)
            {
                println@Console( "[ATTENZIONE]: Repository non trovata tra quelle registrate" )()
            }
        }

        /* */
        else if (command.result[0] == "pull")
        {
            //command.result[1] = serverName;
            //command.result[2] = repoName
            repoFlag = false;
            serverFlag = false;
            for(i=0, i<#global.root.server && !serverFlag, i++)
            {
                if(global.root.server.name == command.result[1])
                {
                    serverFlag = true;
                    scope( fault_connection )
                    {
                        //Contatto il server
                        install( IOException => println@Console( "IOException: Non è possibile raggiungere il server" )() );
                        Server.location = global.root.server.address;
                        //Ottengo la serverRegRepoList
                        getServerRepoList@Server()( serverRepoList );
                        
                        //Cerco la repository pullata sul server
                        for(j=0, j<#serverRepoList.repo && !repoFlag, j++)
                        {
                            if(serverRepoList.repo[j].name == command.result[2])
                            {
                                repoFlag = true
                            }
                        };

                        //Se è presente sul server continuiamo
                        if(repoFlag)
                        {

                            undef( tmpRepo );

                            repoFlag = false;

                            //Controllo se ho la repo registrata localmente
                            for(j=0, j<#global.root.repo && !repoFlag, j++)
                            {
                                if(global.root.repo[j].name == command.result[2])
                                {
                                    tmpRepo = global.root.repo[j].path;
                                    tmpRepo.relativePath = global.root.repo[j].name; 
                                    repoFlag = true
                                }
                            };


                            pullFlag = true;

                            if(!repoFlag)
                            {
                                while( conferma != "Y")
                                {
                                    print@Console( "[ATTENZIONE] : La repo richiesta non è presente localmente, vuoi crearla? [Y/N] \n" )();
                                    registerForInput@Console()();
                                    in( conferma );
                                    println@Console( "CONFERMA : "+conferma )();
                                    if( conferma == "Y")
                                    {
                                        pathFlag = false;
                                        println@Console( "Dove vuoi creare la repository? " )();
                                        while( !pathFlag )
                                        {
                                            print@Console( "Inserisci il path > " )();
                                            in( temp_path );
                                            mkdir@File(temp_path)(pathFlag);

                                            //Se creo correttamente la repository la aggiungo a struttura e aggiorno l'xml
                                            if(pathFlag)
                                            {
                                                tmp.name = command.result[2];
                                                tmp.path = temp_path;
                                                tmp.serverName = command.result[1];
                                                tmp.serverAddress = global.root.server[i].address;
                                                global.root.repo[#global.root.repo] << tmp;
                                                updateXml@Locale(global.root)(xmlUpdate_res);

                                                tmpRepo = global.root.repo[#global.root.repo-1].path;
                                                tmpRepo.relativePath = global.root.repo[#global.root.repo-1].name; 

                                                println@Console( "[SUCCESSO] : La repository è stata creata ('"+temp_path+"')" )()
                                            }
                                            else
                                            {
                                                println@Console( "[ATTENZIONE] : Path non valido" )()
                                            }
                                        }
                                    }
                                    else
                                    {
                                        pullFlag = false
                                    }
                                }
                            };

                            //QUA EFFETTUO LA PULL
                            if(pullFlag)
                            {
                                fileToValue@Locale(tmpRepo)(repoToPull);
                                pull@Server(repoToPull)(pullRawList)

                                //Scrivo i file

                            }
                        }
                        else
                        {
                            println@Console( "[ATTENZIONE] : La repo richiesta non è presente sul server" )()
                        }
                    }
                    
                }
            }
        }

        else if (command.result[0] == "test")
        {
            println@Console( "" )()
        }
        /*  Se non ricevo un comando di quelli definiti, informo l'utente che il comando
            non è stato riconosciuto.   */
  		else
  		{
  		    println@Console( "Comando non riconosciuto, digita 'help' per la lista dei comandi" )()
  		}
    }
}