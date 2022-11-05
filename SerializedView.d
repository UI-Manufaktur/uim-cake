module uim.baklava.views;

import uim.baklava.views\Exception\SerializationFailureException;
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
     */
    protected $_responseType;

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
    protected $_defaultConfig = [
        'serialize' => null,
    ];


    override void initialize() {
      super.initialize();
      this.setResponse(this.getResponse().withType(this._responseType));
    }

    /**
     * Load helpers only if serialization is disabled.
     *
     * @return this
     */
    function loadHelpers() {
        if (!this.getConfig('serialize')) {
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
     * @param string|null myTemplate The template being rendered.
     * @param string|false|null $layout The layout being rendered.
     * @return string The rendered view.
     * @throws \Cake\View\Exception\SerializationFailureException When serialization fails.
     */
    string render(?string myTemplate = null, $layout = null) {
        $serialize = this.getConfig('serialize', false);

        if ($serialize === true) {
            myOptions = array_map(
                function ($v) {
                    return '_' . $v;
                },
                array_keys(this._defaultConfig)
            );

            $serialize = array_diff(
                array_keys(this.viewVars),
                myOptions
            );
        }
        if ($serialize !== false) {
            try {
                return this._serialize($serialize);
            } catch (Exception | TypeError $e) {
                throw new SerializationFailureException(
                    'Serialization of View data failed.',
                    null,
                    $e
                );
            }
        }

        return super.render(myTemplate, false);
    }
}
