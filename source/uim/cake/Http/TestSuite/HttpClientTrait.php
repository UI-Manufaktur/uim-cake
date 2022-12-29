


 *


 * @since         4.3.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.https.TestSuite;

import uim.cake.https.Client;
import uim.cake.https.Client\Response;

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
    function newClientResponse(int $code = 200, array $headers = [], string $body = ""): Response
    {
        $headers = array_merge(["HTTP/1.1 {$code}"], $headers);

        return new Response($headers, $body);
    }

    /**
     * Add a mock response for a POST request.
     *
     * @param string $url The URL to mock
     * @param uim.cake.Http\Client\Response $response The response for the mock.
     * @param array<string, mixed> $options Additional options. See Client::addMockResponse()
     * @return void
     */
    function mockClientPost(string $url, Response $response, array $options = []): void
    {
        Client::addMockResponse("POST", $url, $response, $options);
    }

    /**
     * Add a mock response for a GET request.
     *
     * @param string $url The URL to mock
     * @param uim.cake.Http\Client\Response $response The response for the mock.
     * @param array<string, mixed> $options Additional options. See Client::addMockResponse()
     * @return void
     */
    function mockClientGet(string $url, Response $response, array $options = []): void
    {
        Client::addMockResponse("GET", $url, $response, $options);
    }

    /**
     * Add a mock response for a PATCH request.
     *
     * @param string $url The URL to mock
     * @param uim.cake.Http\Client\Response $response The response for the mock.
     * @param array<string, mixed> $options Additional options. See Client::addMockResponse()
     * @return void
     */
    function mockClientPatch(string $url, Response $response, array $options = []): void
    {
        Client::addMockResponse("PATCH", $url, $response, $options);
    }

    /**
     * Add a mock response for a PUT request.
     *
     * @param string $url The URL to mock
     * @param uim.cake.Http\Client\Response $response The response for the mock.
     * @param array<string, mixed> $options Additional options. See Client::addMockResponse()
     * @return void
     */
    function mockClientPut(string $url, Response $response, array $options = []): void
    {
        Client::addMockResponse("PUT", $url, $response, $options);
    }

    /**
     * Add a mock response for a DELETE request.
     *
     * @param string $url The URL to mock
     * @param uim.cake.Http\Client\Response $response The response for the mock.
     * @param array<string, mixed> $options Additional options. See Client::addMockResponse()
     * @return void
     */
    function mockClientDelete(string $url, Response $response, array $options = []): void
    {
        Client::addMockResponse("DELETE", $url, $response, $options);
    }
}
