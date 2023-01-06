
module uim.cake.http.Middleware;

import uim.cake.core.InstanceConfigTrait;
use ParagonIE\CSPBuilder\CSPBuilder;
use Psr\Http\messages.IResponse;
use Psr\Http\messages.IServerRequest;
use Psr\Http\servers.IMiddleware;
use Psr\Http\servers.RequestHandlerInterface;
use RuntimeException;

/**
 * Content Security Policy Middleware
 *
 * ### Options
 *
 * - `scriptNonce` Enable to have a nonce policy added to the script-src directive.
 * - `styleNonce` Enable to have a nonce policy added to the style-src directive.
 */
class CspMiddleware : IMiddleware
{
    use InstanceConfigTrait;

    /**
     * CSP Builder
     *
     * @var \ParagonIE\CSPBuilder\CSPBuilder $csp CSP Builder or config array
     */
    protected $csp;

    /**
     * Configuration options.
     *
     * @var array<string, mixed>
     */
    protected $_defaultConfig = [
        "scriptNonce": false,
        "styleNonce": false,
    ];

    /**
     * Constructor
     *
     * @param \ParagonIE\CSPBuilder\CSPBuilder|array $csp CSP object or config array
     * @param array<string, mixed> aConfig Configuration options.
     * @throws \RuntimeException
     */
    this($csp, Json aConfig = []) {
        if (!class_exists(CSPBuilder::class)) {
            throw new RuntimeException("You must install paragonie/csp-builder to use CspMiddleware");
        }
        this.setConfig(aConfig);

        if (!$csp instanceof CSPBuilder) {
            $csp = new CSPBuilder($csp);
        }

        this.csp = $csp;
    }

    /**
     * Add nonces (if enabled) to the request and apply the CSP header to the response.
     *
     * @param \Psr\Http\messages.IServerRequest $request The request.
     * @param \Psr\Http\servers.RequestHandlerInterface $handler The request handler.
     * @return \Psr\Http\messages.IResponse A response.
     */
    function process(IServerRequest $request, RequestHandlerInterface $handler): IResponse
    {
        if (this.getConfig("scriptNonce")) {
            $request = $request.withAttribute("cspScriptNonce", this.csp.nonce("script-src"));
        }
        if (this.getconfig("styleNonce")) {
            $request = $request.withAttribute("cspStyleNonce", this.csp.nonce("style-src"));
        }
        $response = $handler.handle($request);

        /** @var \Psr\Http\messages.IResponse */
        return this.csp.injectCSPHeader($response);
    }
}
