/*********************************************************************************************************
*	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        *
*	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  *
*	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      *
**********************************************************************************************************/
module uim.cake.https.clients;

@safe:
import uim.cake;

// Http client adapter interface.
interface AdapterInterface {
    /**
     * Send a request and get a response back.
     *
     * @param \Psr\Http\Message\RequestInterface myRequest The request object to send.
     * @param array<string, mixed> myOptions Array of options for the stream.
     * @return array<\Cake\Http\Client\Response> Array of populated Response objects
     */
    function send(RequestInterface myRequest, array myOptions): array;
}
