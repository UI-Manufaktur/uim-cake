module uim.baklava.Routing;

import uim.baklava.core.Configure;
import uim.baklava.core.Plugin;
import uim.baklava.utikities.Inflector;

/**
 * Class for generating asset URLs.
 */
class Asset
{
    /**
     * Inflection type.
     *
     * @var string
     */
    protected static $inflectionType = 'underscore';

    /**
     * Set inflection type to use when inflecting plugin/theme name.
     *
     * @param string $inflectionType Inflection type. Value should be a valid
     *  method name of `Inflector` class like `'dasherize'` or `'underscore`'`.
     * @return void
     */
    static auto setInflectionType(string $inflectionType): void
    {
        static::$inflectionType = $inflectionType;
    }

    /**
     * Generates URL for given image file.
     *
     * Depending on options passed provides full URL with domain name. Also calls
     * `Asset::assetTimestamp()` to add timestamp to local files.
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
    static function imageUrl(string myPath, array myOptions = []): string
    {
        myPathPrefix = Configure::read('App.imageBaseUrl');

        return static::url(myPath, myOptions + compact('pathPrefix'));
    }

    /**
     * Generates URL for given CSS file.
     *
     * Depending on options passed provides full URL with domain name. Also calls
     * `Asset::assetTimestamp()` to add timestamp to local files.
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
    static function cssUrl(string myPath, array myOptions = []): string
    {
        myPathPrefix = Configure::read('App.cssBaseUrl');
        $ext = '.css';

        return static::url(myPath, myOptions + compact('pathPrefix', 'ext'));
    }

    /**
     * Generates URL for given javascript file.
     *
     * Depending on options passed provides full URL with domain name. Also calls
     * `Asset::assetTimestamp()` to add timestamp to local files.
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
    static function scriptUrl(string myPath, array myOptions = []): string
    {
        myPathPrefix = Configure::read('App.jsBaseUrl');
        $ext = '.js';

        return static::url(myPath, myOptions + compact('pathPrefix', 'ext'));
    }

    /**
     * Generates URL for given asset file.
     *
     * Depending on options passed provides full URL with domain name. Also calls
     * `Asset::assetTimestamp()` to add timestamp to local files.
     *
     * ### Options:
     *
     * - `fullBase` Boolean true or a string (e.g. https://example) to
     *    return full URL with protocol and domain name.
     * - `pathPrefix` Path prefix for relative URLs
     * - `ext` Asset extension to append
     * - `plugin` False value will prevent parsing path as a plugin
     * - `theme` Optional theme name
     * - `timestamp` Overrides the value of `Asset.timestamp` in Configure.
     *    Set to false to skip timestamp generation.
     *    Set to true to apply timestamps when debug is true. Set to 'force' to always
     *    enable timestamping regardless of debug value.
     *
     * @param string myPath Path string or URL array
     * @param array<string, mixed> myOptions Options array.
     * @return string Generated URL
     */
    static function url(string myPath, array myOptions = []): string
    {
        if (preg_match('/^data:[a-z]+\/[a-z]+;/', myPath)) {
            return myPath;
        }

        if (strpos(myPath, '://') !== false || preg_match('/^[a-z]+:/i', myPath)) {
            return ltrim(Router::url(myPath), '/');
        }

        if (!array_key_exists('plugin', myOptions) || myOptions['plugin'] !== false) {
            [myPlugin, myPath] = static::pluginSplit(myPath);
        }
        if (!empty(myOptions['pathPrefix']) && myPath[0] !== '/') {
            myPathPrefix = myOptions['pathPrefix'];
            $placeHolderVal = '';
            if (!empty(myOptions['theme'])) {
                $placeHolderVal = static::inflectString(myOptions['theme']) . '/';
            } elseif (isset(myPlugin)) {
                $placeHolderVal = static::inflectString(myPlugin) . '/';
            }

            myPath = str_replace('{plugin}', $placeHolderVal, myPathPrefix) . myPath;
        }
        if (
            !empty(myOptions['ext']) &&
            strpos(myPath, '?') === false &&
            substr(myPath, -strlen(myOptions['ext'])) !== myOptions['ext']
        ) {
            myPath .= myOptions['ext'];
        }

        // Check again if path has protocol as `pathPrefix` could be for CDNs.
        if (preg_match('|^([a-z0-9]+:)?//|', myPath)) {
            return Router::url(myPath);
        }

        if (isset(myPlugin)) {
            myPath = static::inflectString(myPlugin) . '/' . myPath;
        }

        $optionTimestamp = null;
        if (array_key_exists('timestamp', myOptions)) {
            $optionTimestamp = myOptions['timestamp'];
        }
        $webPath = static::assetTimestamp(
            static::webroot(myPath, myOptions),
            $optionTimestamp
        );

        myPath = static::encodeUrl($webPath);

        if (!empty(myOptions['fullBase'])) {
            $fullBaseUrl = is_string(myOptions['fullBase'])
                ? myOptions['fullBase']
                : Router::fullBaseUrl();
            myPath = rtrim($fullBaseUrl, '/') . '/' . ltrim(myPath, '/');
        }

        return myPath;
    }

    /**
     * Encodes URL parts using rawurlencode().
     *
     * @param string myUrl The URL to encode.
     * @return string
     */
    protected static function encodeUrl(string myUrl): string
    {
        myPath = parse_url(myUrl, PHP_URL_PATH);
        if (myPath === false) {
            myPath = myUrl;
        }

        $parts = array_map('rawurldecode', explode('/', myPath));
        $parts = array_map('rawurlencode', $parts);
        $encoded = implode('/', $parts);

        return str_replace(myPath, $encoded, myUrl);
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
    static function assetTimestamp(string myPath, $timestamp = null): string
    {
        if (strpos(myPath, '?') !== false) {
            return myPath;
        }

        if ($timestamp === null) {
            $timestamp = Configure::read('Asset.timestamp');
        }
        $timestampEnabled = $timestamp === 'force' || ($timestamp === true && Configure::read('debug'));
        if ($timestampEnabled) {
            myfilepath = preg_replace(
                '/^' . preg_quote(static::requestWebroot(), '/') . '/',
                '',
                urldecode(myPath)
            );
            $webrootPath = Configure::read('App.wwwRoot') . str_replace('/', DIRECTORY_SEPARATOR, myfilepath);
            if (is_file($webrootPath)) {
                return myPath . '?' . filemtime($webrootPath);
            }
            // Check for plugins and org prefixed plugins.
            $segments = explode('/', ltrim(myfilepath, '/'));
            myPlugin = Inflector::camelize($segments[0]);
            if (!Plugin::isLoaded(myPlugin) && count($segments) > 1) {
                myPlugin = implode('/', [myPlugin, Inflector::camelize($segments[1])]);
                unset($segments[1]);
            }
            if (Plugin::isLoaded(myPlugin)) {
                unset($segments[0]);
                myPluginPath = Plugin::path(myPlugin)
                    . 'webroot'
                    . DIRECTORY_SEPARATOR
                    . implode(DIRECTORY_SEPARATOR, $segments);
                if (is_file(myPluginPath)) {
                    return myPath . '?' . filemtime(myPluginPath);
                }
            }
        }

        return myPath;
    }

    /**
     * Checks if a file exists when theme is used, if no file is found default location is returned.
     *
     * ### Options:
     *
     * - `theme` Optional theme name
     *
     * @param string myfile The file to create a webroot path to.
     * @param array<string, mixed> myOptions Options array.
     * @return string Web accessible path to file.
     */
    static function webroot(string myfile, array myOptions = []): string
    {
        myOptions += ['theme' => null];
        myRequestWebroot = static::requestWebroot();

        $asset = explode('?', myfile);
        $asset[1] = isset($asset[1]) ? '?' . $asset[1] : '';
        $webPath = myRequestWebroot . $asset[0];
        myfile = $asset[0];

        $themeName = myOptions['theme'];
        if ($themeName) {
            myfile = trim(myfile, '/');
            $theme = static::inflectString($themeName) . '/';

            if (DIRECTORY_SEPARATOR === '\\') {
                myfile = str_replace('/', '\\', myfile);
            }

            if (is_file(Configure::read('App.wwwRoot') . $theme . myfile)) {
                $webPath = myRequestWebroot . $theme . $asset[0];
            } else {
                $themePath = Plugin::path($themeName);
                myPath = $themePath . 'webroot/' . myfile;
                if (is_file(myPath)) {
                    $webPath = myRequestWebroot . $theme . $asset[0];
                }
            }
        }
        if (strpos($webPath, '//') !== false) {
            return str_replace('//', '/', $webPath . $asset[1]);
        }

        return $webPath . $asset[1];
    }

    /**
     * Inflect the theme/plugin name to type set using `Asset::setInflectionType()`.
     *
     * @param string $string String inflected.
     * @return string Inflected name of the theme
     */
    protected static function inflectString(string $string): string
    {
        return Inflector::{static::$inflectionType}($string);
    }

    /**
     * Get webroot from request.
     *
     * @return string
     */
    protected static function requestWebroot(): string
    {
        myRequest = Router::getRequest();
        if (myRequest === null) {
            return '/';
        }

        return myRequest.getAttribute('webroot');
    }

    /**
     * Splits a dot syntax plugin name into its plugin and filename.
     * If myName does not have a dot, then index 0 will be null.
     * It checks if the plugin is loaded, else filename will stay unchanged for filenames containing dot.
     *
     * @param string myName The name you want to plugin split.
     * @return array Array with 2 indexes. 0 => plugin name, 1 => filename.
     * @psalm-return array{string|null, string}
     */
    protected static function pluginSplit(string myName): array
    {
        myPlugin = null;
        [$first, $second] = pluginSplit(myName);
        if ($first && Plugin::isLoaded($first)) {
            myName = $second;
            myPlugin = $first;
        }

        return [myPlugin, myName];
    }
}
