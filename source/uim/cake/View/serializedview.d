module uim.cake.View;

import uim.cake.View\exceptions.SerializationFailureException;
use Exception;
use TypeError;

/**
 * Parent class for view classes generating serialized outputs like JsonView and XmlView.
 */
abstract class SerializedView : View
{
    /**
     * Response type.
     *
     * @var string
     * @deprecated 4.4.0 Implement ``static contentType() : string`` instead.
     */
    protected string _responseType;

    /**
     * Default config options.
     *
     * Use ViewBuilder::setOption()/setOptions() in your controlle to set these options.
     *
     * - `serialize`: Option to convert a set of view variables into a serialized response.
     *   Its value can be a string for single variable name or array for multiple
     *   names. If true all view variables will be serialized. If null or false
     *   normal view template will be rendered.
     *
     * @var array<string, mixed>
     */
    protected _defaultConfig = [
        "serialize": null,
    ];


    void initialize() {
        super.initialize();
        if (_responseType) {
            $response = this.getResponse().withType(_responseType);
            this.setResponse($response);
        }
    }

    /**
     * Load helpers only if serialization is disabled.
     *
     * @return this
     */
    function loadHelpers() {
        if (!this.getConfig("serialize")) {
            super.loadHelpers();
        }

        return this;
    }

    /**
     * Serialize view vars.
     *
     * @param array|string $serialize The name(s) of the view variable(s) that
     *   need(s) to be serialized
     * @return string The serialized data.
     */
    abstract protected string _serialize($serialize);

    /**
     * Render view template or return serialized data.
     *
     * @param string|null $template The template being rendered.
     * @param string|false|null $layout The layout being rendered.
     * @return string The rendered view.
     * @throws uim.cake.View\exceptions.SerializationFailureException When serialization fails.
     */
    string render(Nullable!string $template = null, $layout = null) {
        $serialize = this.getConfig("serialize", false);

        if ($serialize == true) {
            $options = array_map(
                function ($v) {
                    return "_" ~ $v;
                },
                array_keys(_defaultConfig)
            );

            $serialize = array_diff(
                array_keys(this.viewVars),
                $options
            );
        }
        if ($serialize != false) {
            try {
                return _serialize($serialize);
            } catch (Exception | TypeError $e) {
                throw new SerializationFailureException(
                    "Serialization of View data failed.",
                    null,
                    $e
                );
            }
        }

        return super.render($template, false);
    }
}
