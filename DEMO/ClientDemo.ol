include "file.iol"
include "console.iol"
include "xml_utils.iol"
include "Interface.iol"
include "string_utils.iol"
include "exec.iol"
include "time.iol"

constants {
    HELP = "
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
delete [serverName] [repoName]                      Rimuove il repository dai repo registrati.
test\n",
    Timer_wait = 4000
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
    global.root = "";


    //Leggo il file di istruzioni
    readFileRequest.filename = args[0]+"_Instructions";
    readFile@File(readFileRequest)(readFileResponse);
    readFileResponse.regex = "\n";
    split@StringUtils(readFileResponse)(global.instructions)
}

main
{
    /*  Ricevo il nome dell'utente per ricercare il folder del client e ottenere la struttura
        da FileManager.ol */
    clientPath = "Clients/"+args[0];
    readXml@Locale(clientPath)(global.root);

    //Dò il benvenuto all'utente
    println@Console( "Ciao "+args[0]+", hai attualmente "+#global.root.server+" server e "+#global.root.repo+" repositories registrati.\nDigita 'help' per la lista dei comandi disponibili" )();
    
    //Avvio il loop per gli input dell'utente
    while( is_defined( global.instructions.result[0] ))
    {
        //Attendo un comando
        cmd = global.instructions.result[z];
        print@Console( args[0]+" > "+cmd+"\n")();
        sleep@Time(Timer_wait)();
        //Eseguo il comando
        eseguiComando;
        undef( global.instructions.result[0] )
    }
}

define eseguiComando
{
    /*  
        Ricevo dal client un comando ed eseguo uno split per trovare tutti gli args 
    */
    cmd.regex = " ";
    split@StringUtils( cmd )( command );

    /*  
        Termina l'esecuzione del client
    */
    if ( command.result[0] == "close")
    {

        println@Console("Disconnessione in corso...\nSessione conclusa.")()
    }

    /*  
        Pulisce la schermata del terminale 
    */
    else if ( command.result[0] == "clear" ) 
    {

        exec@Exec( command.result[0] )( cmdResponse );
        print@Console( cmdResponse )()
    }

    /*  
        Stampo a video i comandi disponibili 
    */
    else if( command.result[0] == "help")
    {

        println@Console(HELP)()
    } 
        
    /*  
        Stampo a video la lista dei server contenuti in root.server 
    */
    else if ( command.result[0] +" "+ command.result[1] == "list servers") 
    {

        if( #global.root.server != 0 )
        {
            println@Console( "[Servers Registrati #"+#global.root.server+"]" )();
            for( i=0, i<#global.root.server, i++ ) {
                println@Console("ServerName: "+global.root.server[i].name +"\tServerAddress: "+global.root.server[i].address)()
            }
        }
        else
        {
            println@Console("[ATTENZIONE]: Nessun server salvato")()
        }
    }

    /* 
        Stampo a video la lista delle repository presenti sul server passato nell'arg "serverName"
    */
    else if( command.result[0] +" "+ command.result[1] == "list new_repos" )
    {

        if( #global.root.server != 0 )
        {
            for( i=0, i<#global.root.server, i++ )
            {
                scope ( fault_connection )
                {
                    install( IOException => println@Console( "[ATTENZIONE] : "+global.root.server[i].name+" @ "+global.root.server[i].address+" - Non raggiungibile" )() );
                    Server.location = global.root.server[i].address;
                    getServerRepoList@Server()( newRepoList );
                    if( #newRepoList.repo != 0 )
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
        else
        {
            println@Console("[ATTENZIONE] : Nessun server registrato")()
        }
    }

    /*  
        Stampo a video la lista dei server contenuti in root.repo (localmente)
    */
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

    /* 
        Provo a contattare il server passato dagli args result[1] e [2],
        Se ricevo risposta, aggiungo il server alla struttura e al XML
    */
    else if ( command.result[0] == "addServer") 
    {

        if ( is_defined( command.result[1] ) && is_defined( command.result[2] ))
        {
            newServer.name = command.result[1];
            newServer.address = command.result[2];
            regServer = false;

            //Controllo se ho già registrato il server 
            for(i=0, i<#global.root.server && !regServer, i++)
            {
                if( global.root.server[i].address == newServer.address )
                {
                    regServer = true
                }
            };

            //Se non l'ho registrato, provo un handshake
            if( !regServer )
            {
                
                scope( fault_connection )
                {
                    install ( IOException => println@Console( "IOException: Non è possibile raggiungere il server" )() );
                    Server.location = newServer.address;
                    addServer@Server( newServer )( server_response );
                    //Se ricevo risposta aggiungo il server alla struttura
                    if( server_response ) 
                    { 
                        global.root.server[#global.root.server] << newServer;
                        updateXml@Locale( global.root )( xmlUpdate_res );
                        println@Console( "[SUCCESSO]: Server aggiunto" )()
                    }
                }
            }
            else
            {
                println@Console( "[ATTENZIONE]: Server già registrato sotto il nome " + global.root.server[i-1].name)()
            }
        }
        else
        {
            println@Console( "[ATTENZIONE]: Definire correttamente i parametri [serverName] e [serverAddress]" )()
        }
    }

    /*  
        Cerco se il server è presente nella struttura.
        Se è presente lo elimino dalla struttura e aggiorno il file XML
    */
    else if ( command.result[0] == "removeServer") 
    {

        if (is_defined( command.result[1] ))
        {

            regServer = false;
            for(i=0, i<#global.root.server && !regServer, i++)
            {
                if(global.root.server[i].name == command.result[1])
                {
                    regServer = true;
                    undef(global.root.server[i]);
                    updateXml@Locale( global.root )();
                    println@Console( "[SUCCESSO]: Server '" +command.result[1]+ "' eliminato" )()
                }
            };
            if( !regServer )
            {
                println@Console( "[ATTENZIONE]: Server '" +command.result[1]+ "' non trovato" )()
            }
        }
        else
        {
            println@Console( "[ATTENZIONE]: Definire correttamente il parametro [serverName]" )()
        }
    }

    /*  
        Controllo in parallelo
        - Il server sia presente fra quelli aggiunti
        - La repository non sia già stata aggiunta
        Se il controllo va a buon fine, sempre in parallelo
        - Contatto il server e gli invio la repository da gestire
        - Controllo se il path passato esiste, altrimenti lo creo e aggiorno il file XML
    */
    else if (command.result[0] == "addRepository")
    {

        if ( is_defined(command.result[1]) && is_defined(command.result[2]) && is_defined(command.result[3] ))
        {

            //Controllo in parallelo se ho il server e la repo richiesti
            ser = false; //Booleano per dire se il sever è stato trovato o meno
            rep = true; //Booleano per dise se la repo è già stata registrata come repo associata a server specificato

            tmpServer = "";

            {
                //Controllo se il server è presente tra quelli registrati
                for(i=0, i<#global.root.server && !ser, i++)
                {
                    if( global.root.server[i].name == command.result[1] )
                    {
                        tmpServer << global.root.server[i];
                        ser = true
                    }
                } ;
                //Controllo se la repo è già stata registrata come repo associata a server specificato
                for(j=0, j<#global.root.repo && rep, j++)
                {
                    if( ( global.root.repo[j].name == command.result[2] ) && ( global.root.repo[j].serverName == command.result[1] ) )
                    {
                        rep = false
                    }
                }
            };   
        
            if( ser ) //Il server è registrato
            {  
                {
                    addRepo.name = command.result[2];
                    addRepo.path = command.result[3];
                    addRepo.serverName = command.result[1];
                    addRepo.serverAddress = tmpServer.address
                };

                {
                    {
                        scope (fault_connection)
                        {
                            install ( IOException => println@Console( "IOException: Non è stato possibile creare la repository sul server, perché non è raggiungibile" )() );
                            Server.location = tmpServer.address;
                            addRepository@Server( addRepo )
                        }
                    }
                        |
                    {
                        if( rep ) //La repo non è stata registrata localmente
                        {
                            exists@File( addRepo.path )( res );
                            global.root.repo[#global.root.repo] << addRepo;
                            if(res)
                            {
                                println@Console( "[SUCCESSO]: Ho registrato localmente '" +addRepo.name+ "'@ " +addRepo.serverName )()
                            }
                            else
                            {
                                mkdir@File( addRepo.path )( response );
                                println@Console( "[ATTENZIONE]: Non ho trovato '" +addRepo.path+ "', ho comunque creato la repository" )()
                            };
                            updateXml@Locale(global.root)(r)
                        }
                        else //La repo è già stata registrata localmente
                        {
                            println@Console( "[ATTENZIONE]: Repository già presente tra quelle registrate sul server " +addRepo.serverName )()
                        }
                    }
                }
            }
            else //Il server non è tra quelli registrati
            {
                println@Console( "[ATTENZIONE]: Server non presente tra quelli registrati" )()
            }
        }
        else
        {
            println@Console( "[ATTENZIONE]: Definire correttamente i parametri [serverName], [repoName] e [locaPath]" )()
        }
    }

    /* 
        PUSH
        1 - Ottengo dai path delle mie Reg Repos il tree della mia repository
        2 - Invio il tree al server che effettua il versioning
        3 - Effettua automaticamente la Push dei file che hanno verisione > di quella del server
        4 - Ritorna la PULL LIST dei file che hanno versione < di quella del server 
    */
    else if (command.result[0] == "push")
    {

        if (is_defined(command.result[1]) && is_defined(command.result[2]))
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
                        pushRequest@Server( repo_tree )( pushList );

                        rawList = "";
                        
                        for(k=0, k < #pushList.fileToPush, k++)
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

                            //Rimuovo i campi non voluti dal servizio ReadFile@File
                            undef( file.content );
                            undef( file.version );

                            readFile@File(file)(file.content); 

                            file.filename = pushList.fileToPush[k];

                            //Ottengo la versione del file in esame
                            getLastModString@JavaService ( sub_res + pushList.fileToPush[k] )( v );
                            file.version = long(v);

                            undef( file.format );
                            rawList.file[#rawList.file] << file

                            //println@Console( file.version )();
                            
                            
                        };


                        //INVIA I FILE AL SERVER
                        //Aggiungo a rawList la repository in esame, per rilasciare il suo semaforo sul server.
                        rawList = global.root.repo[i].name;
                        push@Server(rawList);

                        undef( rawList );

                        println@Console( "[SUCCESSO] : La pushRequest è stata inviata al server" )();

                        if (#pushList.fileToPull>0)
                        {
                            println@Console( "[ATTENZIONE] : I seguenti file nella repository non sono aggiornati" )();
                            for(j=0, j<#pushList.fileToPull, j++)
                            {
                                //STAMPO FILE TO PULL
                                println@Console(pushList.fileToPull[j] )()
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
        else
        {
            println@Console( "[ATTENZIONE]: Definire correttamente i parametri [serverName] e [repoName]" )()
        }
    }

    /* 

    */
    else if (command.result[0] == "pull")
    {

        if (is_defined(command.result[1]) && is_defined(command.result[2]))
        {
            repoTrovata = false;
            serverTrovato = false;

            // Cerco se esiste il Server
            for(i=0, i<#global.root.server && !serverTrovato, i++)
            {
                // Se il server è registrato
                if(global.root.server[i].name == command.result[1])
                {
                    serverTrovato = true;
                    scope( fault_connection )
                    {
                        //Contatto il server
                        install( IOException => println@Console( "IOException: Non è possibile raggiungere il server" )() );
                        Server.location = global.root.server.address;

                        // Invio una richiesta al server e mi ritorna la sua struttura della repo
                        pullRequest@Server( command.result[2] )( serverRepo_tree );

                        // Se la repo non è presente sul server
                        if (serverRepo_tree != "NonTrovata") {
                            repoServerTrovata = true
                        };

                        //Se è presente sul server continuiamo
                        if(repoServerTrovata)
                        {

                            undef( tmpRepo );

                            repoClientTrovata = false;

                            //Controllo se ho la repo registrata localmente e, se è presente, che sia associata al server specificato
                            for(j=0, j<#global.root.repo && !repoClientTrovata, j++)
                            {
                                if( global.root.repo[j].name == command.result[2] && global.root.repo[j].serverName == command.result[1] )
                                {
                                    tmpRepo = global.root.repo[j].path;
                                    tmpRepo.relativePath = global.root.repo[j].name; 
                                    repoClientTrovata = true
                                }
                            };


                            pullFlag = true;

                            if( !repoClientTrovata )
                            {
                                creazione = false;
                                while( !creazione )
                                {
                                    print@Console( "[ATTENZIONE] : La repo richiesta non è presente localmente, vuoi crearla? [Y/N] \n> " )();
                                    in( conferma );
                                    if( conferma == "Y" || conferma == "y" )
                                    {
                                        creazione = true;
                                        pathFlag = false;

                                        println@Console( "Dove vuoi creare la repository? " )();
                                        while( !pathFlag )
                                        {
                                            print@Console( "Inserisci il path > " )();
                                            in( tmpRepo );
                                            mkdir@File(tmpRepo+"/"+command.result[2])(pathFlag);

                                            //Se creo correttamente la repository la aggiungo a struttura e aggiorno l'xml
                                            if(pathFlag)
                                            {
                                                tmpRepo = tmpRepo+"/"+command.result[2];
                                                tmpRepo.relativePath = command.result[2]; 


                                                with( tmp ){
                                                  .name = tmpRepo.relativePath;
                                                  .path = tmpRepo;
                                                  .serverName = command.result[1];
                                                  .serverAddress = global.root.server[i].address
                                                };

                                                global.root.repo[#global.root.repo] << tmp;
                                                updateXml@Locale(global.root)(xmlUpdate_res);


                                                println@Console( "[SUCCESSO] : La repository è stata creata ('"+tmpRepo+"')" )();
                                                pullFlag = true
                                            }
                                            else
                                            {
                                                println@Console( "[ATTENZIONE] : Path non valido" )()
                                            }
                                        }

                                    }
                                    else if(conferma == "n" || conferma == "N")
                                    {
                                        creazione = true;
                                        pullFlag = false
                                    }
                                }
                            };

                            

                            //QUA EFFETTUO LA PULL
                            if(pullFlag)
                            {   
                                //Elimino dall'absolute path il reponame e aggiungo il relative path del file
                                absPath = tmpRepo;
                                relPath = tmpRepo.relativePath;


                                length@StringUtils( absPath )(absoluteLength);
                                length@StringUtils( relPath )(reponameLength);
                                sub_request = absPath;
                                sub_request.begin = 0;
                                sub_request.end = absoluteLength - reponameLength;
                                substring@StringUtils(sub_request)(sub_res);
                                

                                path = sub_res;

                                // Visita in ampiezza della repo_tree inviata dal server per
                                // creare la fileToPull list
                                coda[0] << serverRepo_tree;
                                dim = #coda;

                                while(dim > 0)
                                {
                                    undef( tmpRoot );
                                    tmpRoot << coda[0];

                                    undef( coda[0] );
                                    dim = #tmpRoot;
                                    {
                                        // Scorro le sottocartelle
                                        for(i=0, i<#tmpRoot.repo, i++)
                                        {
                                            coda[#coda] << tmpRoot.repo[i];
                                            repo_path = path+tmpRoot.repo[i].relativePath;
                                            exists@File(repo_path)(esiste);

                                            // Se la sottodirectory non esiste la creo nella repo del client
                                            if(!esiste)
                                            {
                                                mkdir@File( repo_path )( mkdir_response )
                                            }
                                        }

                                            |

                                        // Scorro tutti i file
                                        for(j=0, j<#tmpRoot.file, j++)
                                        {
                                            // Trasformo il path relativo in assoluto
                                            file_path = path+tmpRoot.file[j].relativePath;

                                            // Verifico l'esistenza del file
                                            exists@File( file_path )( fileEsiste );
                                            if( fileEsiste )
                                            {   
                                                // Ottengo la versione del file in locale e la confronto con quella del server
                                                getLastModString@JavaService( file_path )( c_version );

                                                client_version = long(c_version);
                                                server_version = tmpRoot.file[j].version;

                                                if( client_version < server_version )
                                                {
                                                    list.fileToPull[ #list.fileToPull ] = tmpRoot.file[ j ].relativePath
                                                }

                                                else if ( client_version > server_version )
                                                {
                                                    list.fileToPush[ #list.fileToPush ] = tmpRoot.file[ j ].relativePath
                                                }
                                            }

                                            // Se il file non è c'è in locale del client è sicuramente da pullare
                                            else
                                            {
                                                list.fileToPull[ #list.fileToPull ] = tmpRoot.file[j].relativePath
                                            }

                                        }
                                    };

                                    dim = #coda

                                };


                                clientPullList.fileToPull << list.fileToPull;
                                clientPullList = command.result[2];

                                pull@Server( clientPullList )( rawList );

                                for ( k = 0, k < #rawList.file , k++ )
                                {
                                    rawList.file[k].filename = path+rawList.file[k].filename;

                                    serverVersion.path = rawList.file[k].filename;
                                    serverVersion.version = rawList.file[k].version;
                                    
                                    undef(rawList.file[k].version);
                                    writeFile@File(rawList.file[k])();
                                    setLastMod@JavaService(serverVersion)(r)
                                    
                                };
                                undef( rawList );

                                println@Console( "[SUCCESSO] : Pull effettuata correttamente" )()
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
        else
        {
            println@Console( "[ATTENZIONE]: Definire correttamente i parametri [serverName] e [repoName]" )()
        }
    }

    /* 

    */
    else if ( command.result[0] == "delete" )
    {

        if( is_defined( command.result[1] ) && is_defined( command.result[2] ) )
        {
            repoTrovata = false;
            for( i=0, i<#global.root.repo && !repoTrovata, i++ )
            {
                if( ( global.root.repo[i].serverName == command.result[1] ) && ( global.root.repo[i].name == command.result[2] ) )
                {
                    repoTrovata = true;
                    scope( fault_connection )
                    {
                        install( IOException => println@Console( "[ATTENZIONE] : La repository non è stata rimossa dal server, perché non è raggiungibile. " )() );
                        Server.location = global.root.repo[i].serverAddress;
                        delete@Server(command.result[2])
                    }
                    |
                    {
                        deleteDir@File(global.root.repo[i].path)(deleteRes);
                        if(deleteRes)
                        {
                            undef( global.root.repo[i] );
                            updateXml@Locale(global.root)(r);
                            println@Console( "[SUCCESSO] : La repository è stata eliminata con successo dal computer" )()
                        }
                        else
                        {
                            println@Console( "[ATTENZIONE] : La repository NON è stata eliminata con successo dal computer" )()
                        }
                    }
                }
            };
            if(!repoTrovata)
            {
                println@Console( "[ATTENZIONE] : La repository non è registrata localmente" )()
            }
        }
        else
        {
            println@Console( "[ATTENZIONE]: Definire correttamente i parametri [serverName] e [repoName]" )()
        }
    }

    /* Comando utilizzato soltanto nella demo*/
    else if ( command.result[0] == "createFile" )
    {
        for(i=0, i<#global.root.repo, i++)
        {
            if(global.root.repo[i].name == command.result[1])
            {
                println@Console( "CREO IL FILE 'new_file.txt'" )();
                writeRequest.content = "<vuoto>";
                writeRequest.filename = clientPath+"/"+command.result[1]+"/new_file.txt";
                writeFile@File(writeRequest)(writeResponse)
            }
        }
    }

    /*  
        Se il comando inserito non è tra quelli riconosciuti l'utente ne viene informato   
    */
    else
    {

        println@Console( "Comando non riconosciuto, digita 'help' per la lista dei comandi" )()
    }

}

