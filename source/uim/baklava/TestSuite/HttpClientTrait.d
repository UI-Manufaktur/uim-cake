

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         4.3.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.baklava.TestSuite;

import uim.baklava.https\Client;
import uim.baklava.https\Client\Response;

/**
 * Define mock responses and have mocks automatically cleared.
 */
trait HttpClientTrait
{
    /**
     * Resets mocked responses
     *
     * @after
     * @return void
     */
    function cleanupMockResponses(): void
    {
        Client::clearMockResponses();
    }

    /**
     * Create a new response.
     *
     * @param int $code The response code to use. Defaults to 200
     * @param array<string> $headers A list of headers for the response. Example `Content-Type: application/json`
     * @param string $body The body for the response.
     * @return \Cake\Http\Client\Response
     */
    function newClientResponse(int $code = 200, array $headers = [], string $body = ''): Response
    {
        $headers = array_merge(["HTTP/1.1 {$code}"], $headers);

        return new Response($headers, $body);
    }

    /**
     * Add a mock response for a POST request.
     *
     * @param string myUrl The URL to mock
     * @param \Cake\Http\Client\Response $response The response for the mock.
     * @param array<string, mixed> myOptions Additional options. See Client::addMockResponse()
     * @return void
     */
    function mockClientPost(string myUrl, Response $response, array myOptions = []): void
    {
        Client::addMockResponse('POST', myUrl, $response, myOptions);
    }

    /**
     * Add a mock response for a GET request.
     *
     * @param string myUrl The URL to mock
     * @param \Cake\Http\Client\Response $response The response for the mock.
     * @param array<string, mixed> myOptions Additional options. See Client::addMockResponse()
     * @return void
     */
    function mockClientGet(string myUrl, Response $response, array myOptions = []): void
    {
        Client::addMockResponse('GET', myUrl, $response, myOptions);
    }

    /**
     * Add a mock response for a PATCH request.
     *
     * @param string myUrl The URL to mock
     * @param \Cake\Http\Client\Response $response The response for the mock.
     * @param array<string, mixed> myOptions Additional options. See Client::addMockResponse()
     * @return void
     */
    function mockClientPatch(string myUrl, Response $response, array myOptions = []): void
    {
        Client::addMockResponse('PATCH', myUrl, $response, myOptions);
    }

    /**
     * Add a mock response for a PUT request.
     *
     * @param string myUrl The URL to mock
     * @param \Cake\Http\Client\Response $response The response for the mock.
     * @param array<string, mixed> myOptions Additional options. See Client::addMockResponse()
     * @return void
     */
    function mockClientPut(string myUrl, Response $response, array myOptions = []): void
    {
        Client::addMockResponse('PUT', myUrl, $response, myOptions);
    }

    /**
     * Add a mock response for a DELETE request.
     *
     * @param string myUrl The URL to mock
     * @param \Cake\Http\Client\Response $response The response for the mock.
     * @param array<string, mixed> myOptions Additional options. See Client::addMockResponse()
     * @return void
     */
    function mockClientDelete(string myUrl, Response $response, array myOptions = []): void
    {
        Client::addMockResponse('DELETE', myUrl, $response, myOptions);
    }
}
