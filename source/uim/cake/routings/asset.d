/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.Routing;

@safe:
import uim.cake;


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
    protected static $inflectionType = "underscore";

    /**
     * Set inflection type to use when inflecting plugin/theme name.
     *
     * @param string $inflectionType Inflection type. Value should be a valid
     *  method name of `Inflector` class like `"dasherize"` or `"underscore`"`.
     */
    static void setInflectionType(string $inflectionType) {
        static::$inflectionType = $inflectionType;
    }

    /**
     * Generates URL for given image file.
     *
     * Depending on options passed provides full URL with domain name. Also calls
     * `Asset::assetTimestamp()` to add timestamp to local files.
     *
     * @param string $path Path string.
     * @param array<string, mixed> $options Options array. Possible keys:
     *   `fullBase` Return full URL with domain name
     *   `pathPrefix` Path prefix for relative URLs
     *   `plugin` False value will prevent parsing path as a plugin
     *   `timestamp` Overrides the value of `Asset.timestamp` in Configure.
     *        Set to false to skip timestamp generation.
     *        Set to true to apply timestamps when debug is true. Set to "force" to always
     *        enable timestamping regardless of debug value.
     * @return string Generated URL
     */
    static string imageUrl(string $path, STRINGAA someOptions = null) {
        $pathPrefix = Configure::read("App.imageBaseUrl");

        return static::url($path, $options + compact("pathPrefix"));
    }

    /**
     * Generates URL for given CSS file.
     *
     * Depending on options passed provides full URL with domain name. Also calls
     * `Asset::assetTimestamp()` to add timestamp to local files.
     *
     * @param string $path Path string.
     * @param array<string, mixed> $options Options array. Possible keys:
     *   `fullBase` Return full URL with domain name
     *   `pathPrefix` Path prefix for relative URLs
     *   `ext` Asset extension to append
     *   `plugin` False value will prevent parsing path as a plugin
     *   `timestamp` Overrides the value of `Asset.timestamp` in Configure.
     *        Set to false to skip timestamp generation.
     *        Set to true to apply timestamps when debug is true. Set to "force" to always
     *        enable timestamping regardless of debug value.
     * @return string Generated URL
     */
    static string cssUrl(string $path, STRINGAA someOptions = null) {
        $pathPrefix = Configure::read("App.cssBaseUrl");
        $ext = ".css";

        return static::url($path, $options + compact("pathPrefix", "ext"));
    }

    /**
     * Generates URL for given javascript file.
     *
     * Depending on options passed provides full URL with domain name. Also calls
     * `Asset::assetTimestamp()` to add timestamp to local files.
     *
     * @param string $path Path string.
     * @param array<string, mixed> $options Options array. Possible keys:
     *   `fullBase` Return full URL with domain name
     *   `pathPrefix` Path prefix for relative URLs
     *   `ext` Asset extension to append
     *   `plugin` False value will prevent parsing path as a plugin
     *   `timestamp` Overrides the value of `Asset.timestamp` in Configure.
     *        Set to false to skip timestamp generation.
     *        Set to true to apply timestamps when debug is true. Set to "force" to always
     *        enable timestamping regardless of debug value.
     * @return string Generated URL
     */
    static string scriptUrl(string $path, STRINGAA someOptions = null) {
        $pathPrefix = Configure::read("App.jsBaseUrl");
        $ext = ".js";

        return static::url($path, $options + compact("pathPrefix", "ext"));
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
     *    Set to true to apply timestamps when debug is true. Set to "force" to always
     *    enable timestamping regardless of debug value.
     *
     * @param string $path Path string or URL array
     * @param array<string, mixed> $options Options array.
     * @return string Generated URL
     */
    static string url(string $path, STRINGAA someOptions = null) {
        if (preg_match("/^data:[a-z]+\/[a-z]+;/", $path)) {
            return $path;
        }

        if (strpos($path, "://") != false || preg_match("/^[a-z]+:/i", $path)) {
            return ltrim(Router::url($path), "/");
        }

        if (!array_key_exists("plugin", $options) || $options["plugin"] != false) {
            [$plugin, $path] = static::pluginSplit($path);
        }
        if (!empty($options["pathPrefix"]) && $path[0] != "/") {
            $pathPrefix = $options["pathPrefix"];
            $placeHolderVal = "";
            if (!empty($options["theme"])) {
                $placeHolderVal = static::inflectString($options["theme"]) ~ "/";
            } elseif (isset($plugin)) {
                $placeHolderVal = static::inflectString($plugin) ~ "/";
            }

            $path = replace("{plugin}", $placeHolderVal, $pathPrefix) . $path;
        }
        if (
            !empty($options["ext"]) &&
            strpos($path, "?") == false &&
            substr($path, -strlen($options["ext"])) != $options["ext"]
        ) {
            $path ~= $options["ext"];
        }

        // Check again if path has protocol as `pathPrefix` could be for CDNs.
        if (preg_match("|^([a-z0-9]+:)?//|", $path)) {
            return Router::url($path);
        }

        if (isset($plugin)) {
            $path = static::inflectString($plugin) ~ "/" ~ $path;
        }

        $optionTimestamp = null;
        if (array_key_exists("timestamp", $options)) {
            $optionTimestamp = $options["timestamp"];
        }
        $webPath = static::assetTimestamp(
            static::webroot($path, $options),
            $optionTimestamp
        );

        $path = static::encodeUrl($webPath);

        if (!empty($options["fullBase"])) {
            $fullBaseUrl = is_string($options["fullBase"])
                ? $options["fullBase"]
                : Router::fullBaseUrl();
            $path = rtrim($fullBaseUrl, "/") ~ "/" ~ ltrim($path, "/");
        }

        return $path;
    }

    /**
     * Encodes URL parts using rawurlencode().
     *
     * @param string $url The URL to encode.
     * @return string
     */
    protected static string encodeUrl(string $url) {
        $path = parse_url($url, PHP_URL_PATH);
        if ($path == false) {
            $path = $url;
        }

        $parts = array_map("rawurldecode", explode("/", $path));
        $parts = array_map("rawurlencode", $parts);
        $encoded = implode("/", $parts);

        return replace($path, $encoded, $url);
    }

    /**
     * Adds a timestamp to a file based resource based on the value of `Asset.timestamp` in
     * Configure. If Asset.timestamp is true and debug is true, or Asset.timestamp == "force"
     * a timestamp will be added.
     *
     * @param string $path The file path to timestamp, the path must be inside `App.wwwRoot` in Configure.
     * @param string|bool $timestamp If set will overrule the value of `Asset.timestamp` in Configure.
     * @return string Path with a timestamp added, or not.
     */
    static string assetTimestamp(string $path, $timestamp = null) {
        if (strpos($path, "?") != false) {
            return $path;
        }

        if ($timestamp == null) {
            $timestamp = Configure::read("Asset.timestamp");
        }
        $timestampEnabled = $timestamp == "force" || ($timestamp == true && Configure::read("debug"));
        if ($timestampEnabled) {
            $filepath = preg_replace(
                "/^" ~ preg_quote(static::requestWebroot(), "/") ~ "/",
                "",
                urldecode($path)
            );
            $webrootPath = Configure::read("App.wwwRoot") . replace("/", DIRECTORY_SEPARATOR, $filepath);
            if (is_file($webrootPath)) {
                return $path ~ "?" ~ filemtime($webrootPath);
            }
            // Check for plugins and org prefixed plugins.
            $segments = explode("/", ltrim($filepath, "/"));
            $plugin = Inflector::camelize($segments[0]);
            if (!Plugin::isLoaded($plugin) && count($segments) > 1) {
                $plugin = implode("/", [$plugin, Inflector::camelize($segments[1])]);
                unset($segments[1]);
            }
            if (Plugin::isLoaded($plugin)) {
                unset($segments[0]);
                $pluginPath = Plugin::path($plugin)
                    ~ "webroot"
                    . DIRECTORY_SEPARATOR
                    . implode(DIRECTORY_SEPARATOR, $segments);
                if (is_file($pluginPath)) {
                    return $path ~ "?" ~ filemtime($pluginPath);
                }
            }
        }

        return $path;
    }

    /**
     * Checks if a file exists when theme is used, if no file is found default location is returned.
     *
     * ### Options:
     *
     * - `theme` Optional theme name
     *
     * @param string $file The file to create a webroot path to.
     * @param array<string, mixed> $options Options array.
     * @return string Web accessible path to file.
     */
    static string webroot(string $file, STRINGAA someOptions = null) {
        $options += ["theme": null];
        $requestWebroot = static::requestWebroot();

        $asset = explode("?", $file);
        $asset[1] = isset($asset[1]) ? "?" ~ $asset[1] : "";
        $webPath = $requestWebroot . $asset[0];
        $file = $asset[0];

        $themeName = $options["theme"];
        if ($themeName) {
            $file = trim($file, "/");
            $theme = static::inflectString($themeName) ~ "/";

            if (DIRECTORY_SEPARATOR == "\\") {
                $file = replace("/", "\\", $file);
            }

            if (is_file(Configure::read("App.wwwRoot") . $theme . $file)) {
                $webPath = $requestWebroot . $theme . $asset[0];
            } else {
                $themePath = Plugin::path($themeName);
                $path = $themePath ~ "webroot/" ~ $file;
                if (is_file($path)) {
                    $webPath = $requestWebroot . $theme . $asset[0];
                }
            }
        }
        if (strpos($webPath, "//") != false) {
            return replace("//", "/", $webPath . $asset[1]);
        }

        return $webPath . $asset[1];
    }

    /**
     * Inflect the theme/plugin name to type set using `Asset::setInflectionType()`.
     *
     * @param string $string String inflected.
     * @return string Inflected name of the theme
     */
    protected static string inflectString(string $string) {
        return Inflector::{static::$inflectionType}($string);
    }

    /**
     * Get webroot from request.
     *
     * @return string
     */
    protected static string requestWebroot() {
        $request = Router::getRequest();
        if ($request == null) {
            return "/";
        }

        return $request.getAttribute("webroot");
    }

    /**
     * Splits a dot syntax plugin name into its plugin and filename.
     * If $name does not have a dot, then index 0 will be null.
     * It checks if the plugin is loaded, else filename will stay unchanged for filenames containing dot.
     *
     * @param string aName The name you want to plugin split.
     * @return array Array with 2 indexes. 0: plugin name, 1: filename.
     * @psalm-return array{string|null, string}
     */
    protected static array pluginSplit(string aName) {
        $plugin = null;
        [$first, $second] = pluginSplit($name);
        if ($first && Plugin::isLoaded($first)) {
            $name = $second;
            $plugin = $first;
        }

        return [$plugin, $name];
    }
}
