/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.http.Client;

use Psr\Http\messages.RequestInterface;

/**
 * Http client adapter interface.
 */
interface AdapterInterface
{
    /**
     * Send a request and get a response back.
     *
     * @param \Psr\Http\messages.RequestInterface $request The request object to send.
     * @param array<string, mixed> $options Array of options for the stream.
     * @return array<uim.cake.Http\Client\Response> Array of populated Response objects
     */
    array send(RequestInterface $request, STRINGAA someOptions);
}
