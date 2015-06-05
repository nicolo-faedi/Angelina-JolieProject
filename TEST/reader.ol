include "console.iol"
include "file.iol"
include "queue_utils.iol"



main
{
	q_name = "coda";
	new_queue@QueueUtils(q_name)(q_response);
	
	dir = "Clients/Massi";
	q_request.element = dir+"/";
	q_request.queue_name = q_name;
	push@QueueUtils(q_request)(q_response);

	size@QueueUtils(q_name)(dim);

	root = dir;

	while(dim > 0)
	{
		poll@QueueUtils(q_name)(elem);

		println@Console("ELEM: "+elem )();
		listRequest.directory = elem;
		listRequest.order.byname = true;
		list@File(listRequest)(listResponse);


		for(i=0, i<#listResponse.result, i++) 
		{
			if (listResponse.result[i] != ".DS_Store")
			{
  				isDirectory@File(elem+listResponse.result[i])(r);
  				if(r)
  				{
  					println@Console( listResponse.result[i]+" - Il file è una directory" )();
  				
  					q_request.element = elem + listResponse.result[i]+"/";
					q_request.queue_name = q_name;
					push@QueueUtils(q_request)(q_response);

					repo.name = listResponse.result[i]
  				}
  				else
  				{
  					println@Console( listResponse.result[i]+" - Il file non è una directory" )()
  				}
  			}
  		};

  		size@QueueUtils(q_name)(dim)
	}
}