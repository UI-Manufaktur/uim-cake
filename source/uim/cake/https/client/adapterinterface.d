

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *



  */module uim.cake.http.Client;

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
    array send(RequestInterface $request, array $options);
}