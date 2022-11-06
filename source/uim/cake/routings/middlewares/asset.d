module uim.cakeutings.middlewares;

import uim.cakere.Plugin;
import uim.caketps\Response;
import uim.cakeilities.Inflector;
use Laminas\Diactoros\Stream;
use Psr\Http\Message\IResponse;
use Psr\Http\Message\IServerRequest;
use Psr\Http\Server\MiddlewareInterface;
use Psr\Http\Server\RequestHandlerInterface;
use SplFileInfo;

/**
 * Handles serving plugin assets in development mode.
 *
 * This should not be used in production environments as it
 * has sub-optimal performance when compared to serving files
 * with a real webserver.
 */
class AssetMiddleware : MiddlewareInterface
{
    /**
     * The amount of time to cache the asset.
     *
     * @var string
     */
    protected $cacheTime = '+1 day';

    /**
     * Constructor.
     *
     * @param array<string, mixed> myOptions The options to use
     */
    this(array myOptions = []) {
        if (!empty(myOptions['cacheTime'])) {
            this.cacheTime = myOptions['cacheTime'];
        }
    }

    /**
     * Serve assets if the path matches one.
     *
     * @param \Psr\Http\Message\IServerRequest myRequest The request.
     * @param \Psr\Http\Server\RequestHandlerInterface $handler The request handler.
     * @return \Psr\Http\Message\IResponse A response.
     */
    function process(IServerRequest myRequest, RequestHandlerInterface $handler): IResponse
    {
        myUrl = myRequest.getUri().getPath();
        if (strpos(myUrl, '..') !== false || strpos(myUrl, '.') === false) {
            return $handler.handle(myRequest);
        }

        if (strpos(myUrl, '/.') !== false) {
            return $handler.handle(myRequest);
        }

        $assetFile = this._getAssetFile(myUrl);
        if ($assetFile === null || !is_file($assetFile)) {
            return $handler.handle(myRequest);
        }

        myfile = new SplFileInfo($assetFile);
        $modifiedTime = myfile.getMTime();
        if (this.isNotModified(myRequest, myfile)) {
            return (new Response())
                .withStringBody('')
                .withStatus(304)
                .withHeader(
                    'Last-Modified',
                    date(DATE_RFC850, $modifiedTime)
                );
        }

        return this.deliverAsset(myRequest, myfile);
    }

    /**
     * Check the not modified header.
     *
     * @param \Psr\Http\Message\IServerRequest myRequest The request to check.
     * @param \SplFileInfo myfile The file object to compare.
     * @return bool
     */
    protected auto isNotModified(IServerRequest myRequest, SplFileInfo myfile): bool
    {
        $modifiedSince = myRequest.getHeaderLine('If-Modified-Since');
        if (!$modifiedSince) {
            return false;
        }

        return strtotime($modifiedSince) === myfile.getMTime();
    }

    /**
     * Builds asset file path based off url
     *
     * @param string myUrl Asset URL
     * @return string|null Absolute path for asset file, null on failure
     */
    protected auto _getAssetFile(string myUrl): Nullable!string
    {
        $parts = explode('/', ltrim(myUrl, '/'));
        myPluginPart = [];
        for ($i = 0; $i < 2; $i++) {
            if (!isset($parts[$i])) {
                break;
            }
            myPluginPart[] = Inflector::camelize($parts[$i]);
            myPlugin = implode('/', myPluginPart);
            if (Plugin::isLoaded(myPlugin)) {
                $parts = array_slice($parts, $i + 1);
                myfileFragment = implode(DIRECTORY_SEPARATOR, $parts);
                myPluginWebroot = Plugin::path(myPlugin) . 'webroot' . DIRECTORY_SEPARATOR;

                return myPluginWebroot . myfileFragment;
            }
        }

        return null;
    }

    /**
     * Sends an asset file to the client
     *
     * @param \Psr\Http\Message\IServerRequest myRequest The request object to use.
     * @param \SplFileInfo myfile The file wrapper for the file.
     * @return \Cake\Http\Response The response with the file & headers.
     */
    protected auto deliverAsset(IServerRequest myRequest, SplFileInfo myfile): Response
    {
        $stream = new Stream(fopen(myfile.getPathname(), 'rb'));

        $response = new Response(['stream' => $stream]);

        myContentsType = $response.getMimeType(myfile.getExtension()) ?: 'application/octet-stream';
        $modified = myfile.getMTime();
        $expire = strtotime(this.cacheTime);
        $maxAge = $expire - time();

        return $response
            .withHeader('Content-Type', myContentsType)
            .withHeader('Cache-Control', 'public,max-age=' . $maxAge)
            .withHeader('Date', gmdate(DATE_RFC7231, time()))
            .withHeader('Last-Modified', gmdate(DATE_RFC7231, $modified))
            .withHeader('Expires', gmdate(DATE_RFC7231, $expire));
    }
}
