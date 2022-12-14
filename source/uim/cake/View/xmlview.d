


 *


 * @since         2.1.0
  */module uim.cake.views;

import uim.cake.core.Configure;
import uim.cake.utilities.Hash;
import uim.cake.utilities.Xml;

/**
 * A view class that is used for creating XML responses.
 *
 * By setting the "serialize" option in view builder of your controller, you can specify
 * a view variable that should be serialized to XML and used as the response for the request.
 * This allows you to omit views + layouts, if your just need to emit a single view
 * variable as the XML response.
 *
 * In your controller, you could do the following:
 *
 * ```
 * this.set(["posts": $posts]);
 * this.viewBuilder().setOption("serialize", true);
 * ```
 *
 * When the view is rendered, the `$posts` view variable will be serialized
 * into XML.
 *
 * **Note** The view variable you specify must be compatible with Xml::fromArray().
 *
 * You can also set `"serialize"` as an array. This will create an additional
 * top level element named `<response>` containing all the named view variables:
 *
 * ```
 * this.set(compact("posts", "users", "stuff"));
 * this.viewBuilder().setOption("serialize", true);
 * ```
 *
 * The above would generate a XML object that looks like:
 *
 * `<response><posts>...</posts><users>...</users></response>`
 *
 * You can also set `"serialize"` to a string or array to serialize only the
 * specified view variables.
 *
 * If you don"t set the `serialize` option, you will need a view. You can use extended
 * views to provide layout like functionality.
 */
class XmlView : SerializedView
{
    /**
     * XML layouts are located in the `layouts/xml/` subdirectory
     */
    protected string $layoutPath = "xml";

    /**
     * XML views are located in the "xml" subdirectory for controllers" views.
     */
    protected string $subDir = "xml";

    /**
     * Default config options.
     *
     * Use ViewBuilder::setOption()/setOptions() in your controller to set these options.
     *
     * - `serialize`: Option to convert a set of view variables into a serialized response.
     *   Its value can be a string for single variable name or array for multiple
     *   names. If true all view variables will be serialized. If null or false
     *   normal view template will be rendered.
     * - `xmlOptions`: Option to allow setting an array of custom options for Xml::fromArray().
     *   For e.g~ "format" as "attributes" instead of "tags".
     * - `rootNode`: Root node name. Defaults to "response".
     *
     * @var array<string, mixed>
     */
    protected _defaultConfig = [
        "serialize": null,
        "xmlOptions": null,
        "rootNode": null,
    ];

    /**
     * Mime-type this view class renders as.
     *
     * @return string The JSON content type.
     */
    static string contentType() {
        return "application/xml";
    }


    protected string _serialize($serialize) {
        $rootNode = this.getConfig("rootNode", "response");

        if (is_array($serialize)) {
            if (empty($serialize)) {
                $serialize = "";
            } elseif (count($serialize) == 1) {
                $serialize = current($serialize);
            }
        }

        if (is_array($serialize)) {
            $data = [$rootNode: []];
            foreach ($serialize as $alias: $key) {
                if (is_numeric($alias)) {
                    $alias = $key;
                }
                if (array_key_exists($key, this.viewVars)) {
                    $data[$rootNode][$alias] = this.viewVars[$key];
                }
            }
        } else {
            $data = this.viewVars[$serialize] ?? [];
            if (
                $data &&
                (!is_array($data) || Hash::numeric(array_keys($data)))
            ) {
                /** @psalm-suppress InvalidArrayOffset */
                $data = [$rootNode: [$serialize: $data]];
            }
        }

        $options = this.getConfig("xmlOptions", []);
        if (Configure::read("debug")) {
            $options["pretty"] = true;
        }

        return Xml::fromArray($data, $options).saveXML();
    }
}
