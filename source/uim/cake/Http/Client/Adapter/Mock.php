

/**

 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         4.3.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.Http\Client\Adapter;

import uim.cake.Http\Client\AdapterInterface;
import uim.cake.Http\Client\Exception\MissingResponseException;
import uim.cake.Http\Client\Response;
use Closure;
use InvalidArgumentException;
use Psr\Http\Message\RequestInterface;

/**
 * : sending requests to an array of stubbed responses
 *
 * This adapter is not intended for production use. Instead
 * it is the backend used by `Client::addMockResponse()`
 *
 * @internal
 */
class Mock : AdapterInterface
{
    /**
     * List of mocked responses.
     *
     * @var array
     */
    protected $responses = [];

    /**
     * Add a mocked response.
     *
     * ### Options
     *
     * - `match` An additional closure to match requests with.
     *
     * @param \Psr\Http\Message\RequestInterface myRequest A partial request to use for matching.
     * @param \Cake\Http\Client\Response $response The response that matches the request.
     * @param array<string, mixed> myOptions See above.
     * @return void
     */
    void addResponse(RequestInterface myRequest, Response $response, array myOptions)
    {
        if (isset(myOptions['match']) && !(myOptions['match'] instanceof Closure)) {
            myType = getTypeName(myOptions['match']);
            throw new InvalidArgumentException("The `match` option must be a `Closure`. Got `{myType}`.");
        }
        this.responses[] = [
            'request' => myRequest,
            'response' => $response,
            'options' => myOptions,
        ];
    }

    /**
     * Find a response if one exists.
     *
     * @param \Psr\Http\Message\RequestInterface myRequest The request to match
     * @param array<string, mixed> myOptions Unused.
     * @return \Cake\Http\Client\Response[] The matched response or an empty array for no matches.
     */
    function send(RequestInterface myRequest, array myOptions): array
    {
        $found = null;
        $method = myRequest.getMethod();
        myRequestUri = (string)myRequest.getUri();

        foreach (this.responses as $index => $mock) {
            if ($method !== $mock['request'].getMethod()) {
                continue;
            }
            if (!this.urlMatches(myRequestUri, $mock['request'])) {
                continue;
            }
            if (isset($mock['options']['match'])) {
                $match = $mock['options']['match'](myRequest);
                if (!is_bool($match)) {
                    throw new InvalidArgumentException('Match callback must return a boolean value.');
                }
                if (!$match) {
                    continue;
                }
            }
            $found = $index;
            break;
        }
        if ($found !== null) {
            // Move the current mock to the end so that when there are multiple
            // matches for a URL the next match is used on subsequent requests.
            $mock = this.responses[$found];
            unset(this.responses[$found]);
            this.responses[] = $mock;

            return [$mock['response']];
        }

        throw new MissingResponseException(['method' => $method, 'url' => myRequestUri]);
    }

    /**
     * Check if the request URI matches the mock URI.
     *
     * @param string myRequestUri The request being sent.
     * @param \Psr\Http\Message\RequestInterface $mock The request being mocked.
     * @return bool
     */
    protected auto urlMatches(string myRequestUri, RequestInterface $mock): bool
    {
        $mockUri = (string)$mock.getUri();
        if (myRequestUri === $mockUri) {
            return true;
        }
        $starPosition = strrpos($mockUri, '/%2A');
        if ($starPosition === strlen($mockUri) - 4) {
            $mockUri = substr($mockUri, 0, $starPosition);

            return strpos(myRequestUri, $mockUri) === 0;
        }

        return false;
    }
}
