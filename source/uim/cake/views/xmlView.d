module uim.cake.views;

@safe:
import uim.cake

/* import uim.cake.core.Configure;
import uim.cakeility\Hash;
import uim.cakeility\Xml; */

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
 * this.set(["posts" => $posts]);
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
     * Response type.
     */
    protected string $_responseType = "xml";

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
     *   For e.g. "format" as "attributes" instead of "tags".
     * - `rootNode`: Root node name. Defaults to "response".
     *
     * @var array<string, mixed>
     */
    protected STRINGAA _defaultConfig = [
        "serialize" => null,
        "xmlOptions" => null,
        "rootNode" => null,
    ];

    /**
     * @inheritDoc
     */
    protected string _serialize($serialize)
    {
        $rootNode = this.getConfig("rootNode", "response");

        if (is_array($serialize)) {
            if (empty($serialize)) {
                $serialize = "";
            } elseif (count($serialize) == 1) {
                $serialize = current($serialize);
            }
        }

        if (is_array($serialize)) {
            myData = [$rootNode => []];
            foreach ($serialize as myAlias => myKey) {
                if (is_numeric(myAlias)) {
                    myAlias = myKey;
                }
                if (array_key_exists(myKey, this.viewVars)) {
                    myData[$rootNode][myAlias] = this.viewVars[myKey];
                }
            }
        } else {
            myData = this.viewVars[$serialize] ?? [];
            if (
                myData &&
                (!is_array(myData) || Hash::numeric(array_keys(myData)))
            ) {
                /** @psalm-suppress InvalidArrayOffset */
                myData = [$rootNode => [$serialize => myData]];
            }
        }

        myOptions = this.getConfig("xmlOptions", []);
        if (Configure::read("debug")) {
            myOptions["pretty"] = true;
        }

        return Xml::fromArray(myData, myOptions).saveXML();
    }
}
