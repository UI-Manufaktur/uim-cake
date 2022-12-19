module uim.cake.views;

@safe:
import uim.cake;

/**
 * A view class that is used for JSON responses.
 *
 * It allows you to omit templates if you just need to emit JSON string as response.
 *
 * In your controller, you could do the following:
 *
 * ```
 * this.set(["posts" => $posts]);
 * this.viewBuilder().setOption("serialize", true);
 * ```
 *
 * When the view is rendered, the `$posts` view variable will be serialized
 * into JSON.
 *
 * You can also set multiple view variables for serialization. This will create
 * a top level object containing all the named view variables:
 *
 * ```
 * this.set(compact("posts", "users", "stuff"));
 * this.viewBuilder().setOption("serialize", true);
 * ```
 *
 * The above would generate a JSON object that looks like:
 *
 * `{"posts": [...], "users": [...]}`
 *
 * You can also set `"serialize"` to a string or array to serialize only the
 * specified view variables.
 *
 * If you don"t set the `serialize` option, you will need a view template.
 * You can use extended views to provide layout-like functionality.
 *
 * You can also enable JSONP support by setting `jsonp` option to true or a
 * string to specify custom query string parameter name which will contain the
 * callback function name.
 */
class JsonView : SerializedView {
    /**
     * JSON layouts are located in the JSON subdirectory of `Layouts/`
     */
    protected string $layoutPath = "json";

    /**
     * JSON views are located in the "json" subdirectory for controllers" views.
     */
    protected string $subDir = "json";

    /**
     * Response type.
     */
    protected string $_responseType = "json";

    /**
     * Default config options.
     *
     * Use ViewBuilder::setOption()/setOptions() in your controller to set these options.
     *
     * - `serialize`: Option to convert a set of view variables into a serialized response.
     *   Its value can be a string for single variable name or array for multiple
     *   names. If true all view variables will be serialized. If null or false
     *   normal view template will be rendered.
     * - `jsonOptions`: Options for json_encode(). For e.g. `JSON_HEX_TAG | JSON_HEX_APOS`.
     * - `jsonp`: Enables JSONP support and wraps response in callback function provided in query string.
     *   - Setting it to true enables the default query string parameter "callback".
     *   - Setting it to a string value, uses the provided query string parameter
     *     for finding the JSONP callback name.
     *
     * @var array<string, mixed>
     */
    protected STRINGAA _defaultConfig = [
        "serialize" => null,
        "jsonOptions" => null,
        "jsonp" => null,
    ];

    /**
     * Render a JSON view.
     *
     * @param string|null myTemplate The template being rendered.
     * @param string|false|null $layout The layout being rendered.
     * @return string The rendered view.
     */
    string render(Nullable!string myTemplate = null, $layout = null) {
        $return = super.render(myTemplate, $layout);

        $jsonp = this.getConfig("jsonp");
        if ($jsonp) {
            if ($jsonp == true) {
                $jsonp = "callback";
            }
            if (this.request.getQuery($jsonp)) {
                $return = sprintf("%s(%s)", h(this.request.getQuery($jsonp)), $return);
                this.response = this.response.withType("js");
            }
        }

        return $return;
    }


    protected string _serialize(serializeNames) {
        myData = this._dataToSerialize(serializeNames);

        $jsonOptions = this.getConfig("jsonOptions");
        if ($jsonOptions == null) {
            $jsonOptions = JSON_HEX_TAG | JSON_HEX_APOS | JSON_HEX_AMP | JSON_HEX_QUOT | JSON_PARTIAL_OUTPUT_ON_ERROR;
        } elseif ($jsonOptions == false) {
            $jsonOptions = 0;
        }

        if (Configure::read("debug")) {
            $jsonOptions |= JSON_PRETTY_PRINT;
        }

        if (defined("JSON_THROW_ON_ERROR")) {
            $jsonOptions |= JSON_THROW_ON_ERROR;
        }

        $return = json_encode(myData, $jsonOptions);
        if ($return == false) {
            throw new RuntimeException(json_last_error_msg(), json_last_error());
        }

        return $return;
    }

    /**
     * Returns data to be serialized.
     *
     * @param array|string serializeNames The name(s) of the view variable(s) that need(s) to be serialized.
     * @return mixed The data to serialize.
     */
    protected auto _dataToSerialize(string[] serializeNames...) {
        if (is_array(serializeNames)) {
            myData = [];
            foreach (myAlias => myKey; serializeNames) {
                if (is_numeric(myAlias)) {
                    myAlias = myKey;
                }
                if (array_key_exists(myKey, this.viewVars)) {
                    myData[myAlias] = this.viewVars[myKey];
                }
            }

            return !empty(myData) ? myData : null;
        }

        return this.viewVars[serializeNames] ?? null;
    }
}
