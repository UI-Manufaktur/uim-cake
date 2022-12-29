


 *


 * @since         3.3.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Routing\Middleware;

import uim.cake.core.Plugin;
import uim.cake.http.Response;
import uim.cake.utilities.Inflector;
use Laminas\Diactoros\Stream;
use Psr\Http\Message\IResponse;
use Psr\Http\Message\IServerRequest;
use Psr\Http\Server\IMiddleware;
use Psr\Http\Server\RequestHandlerInterface;
use SplFileInfo;

/**
 * Handles serving plugin assets in development mode.
 *
 * This should not be used in production environments as it
 * has sub-optimal performance when compared to serving files
 * with a real webserver.
 */
class AssetMiddleware : IMiddleware
{
    /**
     * The amount of time to cache the asset.
     *
     * @var string
     */
    protected $cacheTime = "+1 day";

    /**
     * Constructor.
     *
     * @param array<string, mixed> $options The options to use
     */
    public this(array $options = []) {
        if (!empty($options["cacheTime"])) {
            this.cacheTime = $options["cacheTime"];
        }
    }

    /**
     * Serve assets if the path matches one.
     *
     * @param \Psr\Http\Message\IServerRequest $request The request.
     * @param \Psr\Http\Server\RequestHandlerInterface $handler The request handler.
     * @return \Psr\Http\Message\IResponse A response.
     */
    function process(IServerRequest $request, RequestHandlerInterface $handler): IResponse
    {
        $url = $request.getUri().getPath();
        if (strpos($url, "..") != false || strpos($url, ".") == false) {
            return $handler.handle($request);
        }

        if (strpos($url, "/.") != false) {
            return $handler.handle($request);
        }

        $assetFile = _getAssetFile($url);
        if ($assetFile == null || !is_file($assetFile)) {
            return $handler.handle($request);
        }

        $file = new SplFileInfo($assetFile);
        $modifiedTime = $file.getMTime();
        if (this.isNotModified($request, $file)) {
            return (new Response())
                .withStringBody("")
                .withStatus(304)
                .withHeader(
                    "Last-Modified",
                    date(DATE_RFC850, $modifiedTime)
                );
        }

        return this.deliverAsset($request, $file);
    }

    /**
     * Check the not modified header.
     *
     * @param \Psr\Http\Message\IServerRequest $request The request to check.
     * @param \SplFileInfo $file The file object to compare.
     * @return bool
     */
    protected function isNotModified(IServerRequest $request, SplFileInfo $file): bool
    {
        $modifiedSince = $request.getHeaderLine("If-Modified-Since");
        if (!$modifiedSince) {
            return false;
        }

        return strtotime($modifiedSince) == $file.getMTime();
    }

    /**
     * Builds asset file path based off url
     *
     * @param string $url Asset URL
     * @return string|null Absolute path for asset file, null on failure
     */
    protected function _getAssetFile(string $url): ?string
    {
        $parts = explode("/", ltrim($url, "/"));
        $pluginPart = [];
        for ($i = 0; $i < 2; $i++) {
            if (!isset($parts[$i])) {
                break;
            }
            $pluginPart[] = Inflector::camelize($parts[$i]);
            $plugin = implode("/", $pluginPart);
            if (Plugin::isLoaded($plugin)) {
                $parts = array_slice($parts, $i + 1);
                $fileFragment = implode(DIRECTORY_SEPARATOR, $parts);
                $pluginWebroot = Plugin::path($plugin) . "webroot" . DIRECTORY_SEPARATOR;

                return $pluginWebroot . $fileFragment;
            }
        }

        return null;
    }

    /**
     * Sends an asset file to the client
     *
     * @param \Psr\Http\Message\IServerRequest $request The request object to use.
     * @param \SplFileInfo $file The file wrapper for the file.
     * @return uim.cake.http.Response The response with the file & headers.
     */
    protected function deliverAsset(IServerRequest $request, SplFileInfo $file): Response
    {
        $stream = new Stream(fopen($file.getPathname(), "rb"));

        $response = new Response(["stream": $stream]);

        $contentType = (array)($response.getMimeType($file.getExtension()) ?: "application/octet-stream");
        $modified = $file.getMTime();
        $expire = strtotime(this.cacheTime);
        $maxAge = $expire - time();

        return $response
            .withHeader("Content-Type", $contentType[0])
            .withHeader("Cache-Control", "public,max-age=" . $maxAge)
            .withHeader("Date", gmdate(DATE_RFC7231, time()))
            .withHeader("Last-Modified", gmdate(DATE_RFC7231, $modified))
            .withHeader("Expires", gmdate(DATE_RFC7231, $expire));
    }
}
