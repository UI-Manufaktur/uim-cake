

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *


 * @since         4.3.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.https.Client\Adapter;

import uim.cake.https.Client\AdapterInterface;
import uim.cake.https.Client\Exception\MissingResponseException;
import uim.cake.https.Client\Response;
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
     * @param \Psr\Http\Message\RequestInterface $request A partial request to use for matching.
     * @param uim.cake.Http\Client\Response $response The response that matches the request.
     * @param array<string, mixed> $options See above.
     * @return void
     */
    function addResponse(RequestInterface $request, Response $response, array $options): void
    {
        if (isset($options["match"]) && !($options["match"] instanceof Closure)) {
            $type = getTypeName($options["match"]);
            throw new InvalidArgumentException("The `match` option must be a `Closure`. Got `{$type}`.");
        }
        this.responses[] = [
            "request": $request,
            "response": $response,
            "options": $options,
        ];
    }

    /**
     * Find a response if one exists.
     *
     * @param \Psr\Http\Message\RequestInterface $request The request to match
     * @param array<string, mixed> $options Unused.
     * @return uim.cake.Http\Client\Response[] The matched response or an empty array for no matches.
     */
    function send(RequestInterface $request, array $options): array
    {
        $found = null;
        $method = $request.getMethod();
        $requestUri = (string)$request.getUri();

        foreach (this.responses as $index: $mock) {
            if ($method != $mock["request"].getMethod()) {
                continue;
            }
            if (!this.urlMatches($requestUri, $mock["request"])) {
                continue;
            }
            if (isset($mock["options"]["match"])) {
                $match = $mock["options"]["match"]($request);
                if (!is_bool($match)) {
                    throw new InvalidArgumentException("Match callback must return a boolean value.");
                }
                if (!$match) {
                    continue;
                }
            }
            $found = $index;
            break;
        }
        if ($found != null) {
            // Move the current mock to the end so that when there are multiple
            // matches for a URL the next match is used on subsequent requests.
            $mock = this.responses[$found];
            unset(this.responses[$found]);
            this.responses[] = $mock;

            return [$mock["response"]];
        }

        throw new MissingResponseException(["method": $method, "url": $requestUri]);
    }

    /**
     * Check if the request URI matches the mock URI.
     *
     * @param string $requestUri The request being sent.
     * @param \Psr\Http\Message\RequestInterface $mock The request being mocked.
     * @return bool
     */
    protected function urlMatches(string $requestUri, RequestInterface $mock): bool
    {
        $mockUri = (string)$mock.getUri();
        if ($requestUri == $mockUri) {
            return true;
        }
        $starPosition = strrpos($mockUri, "/%2A");
        if ($starPosition == strlen($mockUri) - 4) {
            $mockUri = substr($mockUri, 0, $starPosition);

            return strpos($requestUri, $mockUri) == 0;
        }

        return false;
    }
}
