module uim.cakeews\Helper;

import uim.cake.core.App;
import uim.cake.core.exceptions\CakeException;
import uim.cakeutings\Asset;
import uim.cakeutings\Router;
import uim.cakeews\Helper;

/**
 * UrlHelper class for generating URLs.
 */
class UrlHelper : Helper
{
    /**
     * Default config for this class
     *
     * @var array<string, mixed>
     */
    protected STRINGAA _defaultConfig = [
        'assetUrlClassName': Asset::class,
    ];

    /**
     * Asset URL engine class name
     *
     * @var string
     * @psalm-var class-string<\Cake\Routing\Asset>
     */
    protected $_assetUrlClassName;

    /**
     * Check proper configuration
     *
     * @param array<string, mixed> myConfig The configuration settings provided to this helper.
     * @return void
     */
    function initialize(array myConfig): void
    {
        super.initialize(myConfig);
        $engineClassConfig = this.getConfig('assetUrlClassName');

        /** @psalm-var class-string<\Cake\Routing\Asset>|null $engineClass */
        $engineClass = App::className($engineClassConfig, 'Routing');
        if ($engineClass === null) {
            throw new CakeException(sprintf('Class for %s could not be found', $engineClassConfig));
        }

        this._assetUrlClassName = $engineClass;
    }

    /**
     * Returns a URL based on provided parameters.
     *
     * ### Options:
     *
     * - `escape`: If false, the URL will be returned unescaped, do only use if it is manually
     *    escaped afterwards before being displayed.
     * - `fullBase`: If true, the full base URL will be prepended to the result
     *
     * @param array|string|null myUrl Either a relative string URL like `/products/view/23` or
     *    an array of URL parameters. Using an array for URLs will allow you to leverage
     *    the reverse routing features of UIM.
     * @param array<string, mixed> myOptions Array of options.
     * @return string Full translated URL with base path.
     */
    function build(myUrl = null, array myOptions = []): string
    {
        $defaults = [
            'fullBase': false,
            'escape': true,
        ];
        myOptions += $defaults;

        myUrl = Router::url(myUrl, myOptions['fullBase']);
        if (myOptions['escape']) {
            /** @var string myUrl */
            myUrl = h(myUrl);
        }

        return myUrl;
    }

    /**
     * Returns a URL from a route path string.
     *
     * ### Options:
     *
     * - `escape`: If false, the URL will be returned unescaped, do only use if it is manually
     *    escaped afterwards before being displayed.
     * - `fullBase`: If true, the full base URL will be prepended to the result
     *
     * @param string myPath Cake-relative route path.
     * @param array myParams An array specifying any additional parameters.
     *   Can be also any special parameters supported by `Router::url()`.
     * @param array<string, mixed> myOptions Array of options.
     * @return string Full translated URL with base path.
     * @see \Cake\Routing\Router::pathUrl()
     */
    function buildFromPath(string myPath, array myParams = [], array myOptions = []): string
    {
        return this.build(['_path': myPath] + myParams, myOptions);
    }

    /**
     * Generates URL for given image file.
     *
     * Depending on options passed provides full URL with domain name. Also calls
     * `Helper::assetTimestamp()` to add timestamp to local files.
     *
     * @param string myPath Path string.
     * @param array<string, mixed> myOptions Options array. Possible keys:
     *   `fullBase` Return full URL with domain name
     *   `pathPrefix` Path prefix for relative URLs
     *   `plugin` False value will prevent parsing path as a plugin
     *   `timestamp` Overrides the value of `Asset.timestamp` in Configure.
     *        Set to false to skip timestamp generation.
     *        Set to true to apply timestamps when debug is true. Set to 'force' to always
     *        enable timestamping regardless of debug value.
     * @return string Generated URL
     */
    function image(string myPath, array myOptions = []): string
    {
        myOptions += ['theme': this._View.getTheme()];

        return h(this._assetUrlClassName::imageUrl(myPath, myOptions));
    }

    /**
     * Generates URL for given CSS file.
     *
     * Depending on options passed provides full URL with domain name. Also calls
     * `Helper::assetTimestamp()` to add timestamp to local files.
     *
     * @param string myPath Path string.
     * @param array<string, mixed> myOptions Options array. Possible keys:
     *   `fullBase` Return full URL with domain name
     *   `pathPrefix` Path prefix for relative URLs
     *   `ext` Asset extension to append
     *   `plugin` False value will prevent parsing path as a plugin
     *   `timestamp` Overrides the value of `Asset.timestamp` in Configure.
     *        Set to false to skip timestamp generation.
     *        Set to true to apply timestamps when debug is true. Set to 'force' to always
     *        enable timestamping regardless of debug value.
     * @return string Generated URL
     */
    function css(string myPath, array myOptions = []): string
    {
        myOptions += ['theme': this._View.getTheme()];

        return h(this._assetUrlClassName::cssUrl(myPath, myOptions));
    }

    /**
     * Generates URL for given javascript file.
     *
     * Depending on options passed provides full URL with domain name. Also calls
     * `Helper::assetTimestamp()` to add timestamp to local files.
     *
     * @param string myPath Path string.
     * @param array<string, mixed> myOptions Options array. Possible keys:
     *   `fullBase` Return full URL with domain name
     *   `pathPrefix` Path prefix for relative URLs
     *   `ext` Asset extension to append
     *   `plugin` False value will prevent parsing path as a plugin
     *   `timestamp` Overrides the value of `Asset.timestamp` in Configure.
     *        Set to false to skip timestamp generation.
     *        Set to true to apply timestamps when debug is true. Set to 'force' to always
     *        enable timestamping regardless of debug value.
     * @return string Generated URL
     */
    function script(string myPath, array myOptions = []): string
    {
        myOptions += ['theme': this._View.getTheme()];

        return h(this._assetUrlClassName::scriptUrl(myPath, myOptions));
    }

    /**
     * Generates URL for given asset file.
     *
     * Depending on options passed provides full URL with domain name. Also calls
     * `Helper::assetTimestamp()` to add timestamp to local files.
     *
     * ### Options:
     *
     * - `fullBase` Boolean true or a string (e.g. https://example) to
     *    return full URL with protocol and domain name.
     * - `pathPrefix` Path prefix for relative URLs
     * - `ext` Asset extension to append
     * - `plugin` False value will prevent parsing path as a plugin
     * - `timestamp` Overrides the value of `Asset.timestamp` in Configure.
     *    Set to false to skip timestamp generation.
     *    Set to true to apply timestamps when debug is true. Set to 'force' to always
     *    enable timestamping regardless of debug value.
     *
     * @param string myPath Path string or URL array
     * @param array<string, mixed> myOptions Options array.
     * @return string Generated URL
     */
    function assetUrl(string myPath, array myOptions = []): string
    {
        myOptions += ['theme': this._View.getTheme()];

        return h(this._assetUrlClassName::url(myPath, myOptions));
    }

    /**
     * Adds a timestamp to a file based resource based on the value of `Asset.timestamp` in
     * Configure. If Asset.timestamp is true and debug is true, or Asset.timestamp === 'force'
     * a timestamp will be added.
     *
     * @param string myPath The file path to timestamp, the path must be inside `App.wwwRoot` in Configure.
     * @param string|bool $timestamp If set will overrule the value of `Asset.timestamp` in Configure.
     * @return string Path with a timestamp added, or not.
     */
    function assetTimestamp(string myPath, $timestamp = null): string
    {
        return h(this._assetUrlClassName::assetTimestamp(myPath, $timestamp));
    }

    /**
     * Checks if a file exists when theme is used, if no file is found default location is returned
     *
     * @param string myfile The file to create a webroot path to.
     * @return string Web accessible path to file.
     */
    function webroot(string myfile): string
    {
        myOptions = ['theme': this._View.getTheme()];

        return h(this._assetUrlClassName::webroot(myfile, myOptions));
    }

    /**
     * Event listeners.
     *
     * @return array<string, mixed>
     */
    function implementedEvents(): array
    {
        return [];
    }
}
