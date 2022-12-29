

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *


 * @since         3.7.0
  */
module uim.cake.http.Client;

use Psr\Http\Message\RequestInterface;

/**
 * Http client adapter interface.
 */
interface AdapterInterface
{
    /**
     * Send a request and get a response back.
     *
     * @param \Psr\Http\Message\RequestInterface $request The request object to send.
     * @param array<string, mixed> $options Array of options for the stream.
     * @return array<uim.cake.Http\Client\Response> Array of populated Response objects
     */
    function send(RequestInterface $request, array $options): array;
}
