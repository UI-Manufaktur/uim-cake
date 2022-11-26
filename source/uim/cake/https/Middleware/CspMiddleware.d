

/**
 * CakePHP(tm) : Rapid Development Framework (http://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (http://cakefoundation.org)
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (http://cakefoundation.org)
 * @link          http://cakephp.org CakePHP(tm) Project
 * @since         4.0.0
 * @license       http://www.opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.https\Middleware;

import uim.cake.core.InstanceConfigTrait;
use ParagonIE\CSPBuilder\CSPBuilder;
use Psr\Http\Message\IResponse;
use Psr\Http\Message\IServerRequest;
use Psr\Http\Server\MiddlewareInterface;
use Psr\Http\Server\RequestHandlerInterface;
use RuntimeException;

/**
 * Content Security Policy Middleware
 *
 * ### Options
 *
 * - `scriptNonce` Enable to have a nonce policy added to the script-src directive.
 * - `styleNonce` Enable to have a nonce policy added to the style-src directive.
 */
class CspMiddleware : MiddlewareInterface
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
    protected STRINGAA _defaultConfig = [
        "scriptNonce":false,
        "styleNonce":false,
    ];

    /**
     * Constructor
     *
     * @param \ParagonIE\CSPBuilder\CSPBuilder|array $csp CSP object or config array
     * @param array<string, mixed> myConfig Configuration options.
     * @throws \RuntimeException
     */
    this($csp, array myConfig = []) {
        if (!class_exists(CSPBuilder::class)) {
            throw new RuntimeException("You must install paragonie/csp-builder to use CspMiddleware");
        }
        this.setConfig(myConfig);

        if (!$csp instanceof CSPBuilder) {
            $csp = new CSPBuilder($csp);
        }

        this.csp = $csp;
    }

    /**
     * Add nonces (if enabled) to the request and apply the CSP header to the response.
     *
     * @param \Psr\Http\Message\IServerRequest myRequest The request.
     * @param \Psr\Http\Server\RequestHandlerInterface $handler The request handler.
     * @return \Psr\Http\Message\IResponse A response.
     */
    function process(IServerRequest myRequest, RequestHandlerInterface $handler): IResponse
    {
        if (this.getConfig("scriptNonce")) {
            myRequest = myRequest.withAttribute("cspScriptNonce", this.csp.nonce("script-src"));
        }
        if (this.getconfig("styleNonce")) {
            myRequest = myRequest.withAttribute("cspStyleNonce", this.csp.nonce("style-src"));
        }
        $response = $handler.handle(myRequest);

        /** @var \Psr\Http\Message\IResponse */
        return this.csp.injectCSPHeader($response);
    }
}
