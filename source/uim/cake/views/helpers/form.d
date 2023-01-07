module uim.cake.views.Helper;

@safe:
import uim.cake;

/**
 * Form helper library.
 *
 * Automatic generation of HTML FORMs from given data.
 *
 * @method string text(string myFieldName, array myOptions = []) Creates input of type text.
 * @method string number(string myFieldName, array myOptions = []) Creates input of type number.
 * @method string email(string myFieldName, array myOptions = []) Creates input of type email.
 * @method string password(string myFieldName, array myOptions = []) Creates input of type password.
 * @method string search(string myFieldName, array myOptions = []) Creates input of type search.
 * @property uim.cake.View\Helper\HtmlHelper $Html
 * @property uim.cake.View\Helper\UrlHelper myUrl
 * @link https://book.UIM.org/4/en/views/helpers/form.html
 */
class FormHelper : Helper
{
    use IdGeneratorTrait;
    use StringTemplateTrait;

    /**
     * Other helpers used by FormHelper
     *
     * @var array
     */
    protected helpers = ["Url", "Html"];

    /**
     * Default config for the helper.
     *
     * @var array<string, mixed>
     */
    protected STRINGAA _defaultConfig = [
        "idPrefix": null,
        "errorClass": "form-error",
        "typeMap": [
            "string": "text",
            "text": "textarea",
            "uuid": "string",
            "datetime": "datetime",
            "datetimefractional": "datetime",
            "timestamp": "datetime",
            "timestampfractional": "datetime",
            "timestamptimezone": "datetime",
            "date": "date",
            "time": "time",
            "year": "year",
            "boolean": "checkbox",
            "float": "number",
            "integer": "number",
            "tinyinteger": "number",
            "smallinteger": "number",
            "decimal": "number",
            "binary": "file",
        ],
        "templates": [
            // Used for button elements in button().
            "button": "<button{{attrs}}>{{text}}</button>",
            // Used for checkboxes in checkbox() and multiCheckbox().
            "checkbox": "<input type="checkbox" name="{{name}}" value="{{value}}"{{attrs}}>",
            // Input group wrapper for checkboxes created via control().
            "checkboxFormGroup": "{{label}}",
            // Wrapper container for checkboxes.
            "checkboxWrapper": "<div class="checkbox">{{label}}</div>",
            // Error message wrapper elements.
            "error": "<div class="error-message" id="{{id}}">{{content}}</div>",
            // Container for error items.
            "errorList": "<ul>{{content}}</ul>",
            // Error item wrapper.
            "errorItem": "<li>{{text}}</li>",
            // File input used by file().
            "file": "<input type="file" name="{{name}}"{{attrs}}>",
            // Fieldset element used by allControls().
            "fieldset": "<fieldset{{attrs}}>{{content}}</fieldset>",
            // Open tag used by create().
            "formStart": "<form{{attrs}}>",
            // Close tag used by end().
            "formEnd": "</form>",
            // General grouping container for control(). Defines input/label ordering.
            "formGroup": "{{label}}{{input}}",
            // Wrapper content used to hide other content.
            "hiddenBlock": "<div style="display:none;">{{content}}</div>",
            // Generic input element.
            "input": "<input type="{{type}}" name="{{name}}"{{attrs}}/>",
            // Submit input element.
            "inputSubmit": "<input type="{{type}}"{{attrs}}/>",
            // Container element used by control().
            "inputContainer": "<div class="input {{type}}{{required}}">{{content}}</div>",
            // Container element used by control() when a field has an error.
            "inputContainerError": "<div class="input {{type}}{{required}} error">{{content}}{{error}}</div>",
            // Label element when inputs are not nested inside the label.
            "label": "<label{{attrs}}>{{text}}</label>",
            // Label element used for radio and multi-checkbox inputs.
            "nestingLabel": "{{hidden}}<label{{attrs}}>{{input}}{{text}}</label>",
            // Legends created by allControls()
            "legend": "<legend>{{text}}</legend>",
            // Multi-Checkbox input set title element.
            "multicheckboxTitle": "<legend>{{text}}</legend>",
            // Multi-Checkbox wrapping container.
            "multicheckboxWrapper": "<fieldset{{attrs}}>{{content}}</fieldset>",
            // Option element used in select pickers.
            "option": "<option value="{{value}}"{{attrs}}>{{text}}</option>",
            // Option group element used in select pickers.
            "optgroup": "<optgroup label="{{label}}"{{attrs}}>{{content}}</optgroup>",
            // Select element,
            "select": "<select name="{{name}}"{{attrs}}>{{content}}</select>",
            // Multi-select element,
            "selectMultiple": "<select name="{{name}}[]" multiple="multiple"{{attrs}}>{{content}}</select>",
            // Radio input element,
            "radio": "<input type="radio" name="{{name}}" value="{{value}}"{{attrs}}>",
            // Wrapping container for radio input/label,
            "radioWrapper": "{{label}}",
            // Textarea input element,
            "textarea": "<textarea name="{{name}}"{{attrs}}>{{value}}</textarea>",
            // Container for submit buttons.
            "submitContainer": "<div class="submit">{{content}}</div>",
            // Confirm javascript template for postLink()
            "confirmJs": "{{confirm}}",
            // selected class
            "selectedClass": "selected",
        ],
        // set HTML5 validation message to custom required/empty messages
        "autoSetCustomValidity": true,
    ];

    /**
     * Default widgets
     *
     * @var array<string, array<string>>
     */
    protected _defaultWidgets = [
        "button": ["Button"],
        "checkbox": ["Checkbox"],
        "file": ["File"],
        "label": ["Label"],
        "nestingLabel": ["NestingLabel"],
        "multicheckbox": ["MultiCheckbox", "nestingLabel"],
        "radio": ["Radio", "nestingLabel"],
        "select": ["SelectBox"],
        "textarea": ["Textarea"],
        "datetime": ["DateTime", "select"],
        "year": ["Year", "select"],
        "_default": ["Basic"],
    ];

    /**
     * Constant used internally to skip the securing process,
     * and neither add the field to the hash or to the unlocked fields.
     */
    const string SECURE_SKIP = "skip";

    /**
     * Defines the type of form being created. Set by FormHelper::create().
     *
     * @var string|null
     */
    myRequestType;

    /**
     * Locator for input widgets.
     *
     * @var uim.cake.View\Widget\WidgetLocator
     */
    protected _locator;

    /**
     * Context for the current form.
     *
     * @var uim.cake.View\Form\IContext|null
     */
    protected _context;

    /**
     * Context factory.
     *
     * @var uim.cake.View\Form\ContextFactory|null
     */
    protected _contextFactory;

    /**
     * The action attribute value of the last created form.
     * Used to make form/request specific hashes for form tampering protection.
     */
    protected string _lastAction = "";

    /**
     * The supported sources that can be used to populate input values.
     *
     * `context` - Corresponds to `IContext` instances.
     * `data` - Corresponds to request data (POST/PUT).
     * `query` - Corresponds to request"s query string.
     *
     * @var array<string>
     */
    protected supportedValueSources = ["context", "data", "query"];

    /**
     * The default sources.
     *
     * @see FormHelper::$supportedValueSources for valid values.
     * @var array<string>
     */
    protected _valueSources = ["data", "context"];

    /**
     * Grouped input types.
     *
     * @var array<string>
     */
    protected _groupedInputTypes = ["radio", "multicheckbox"];

    /**
     * Form protector
     *
     * @var uim.cake.Form\FormProtector|null
     */
    protected formProtector;

    /**
     * Construct the widgets and binds the default context providers
     *
     * @param uim.cake.View\View $view The View this helper is being attached to.
     * @param array<string, mixed> myConfig Configuration settings for the helper.
     */
    this(View $view, array myConfig = []) {
        $locator = null;
        $widgets = _defaultWidgets;
        if (isset(myConfig["locator"])) {
            $locator = myConfig["locator"];
            unset(myConfig["locator"]);
        }
        if (isset(myConfig["widgets"])) {
            if (is_string(myConfig["widgets"])) {
                myConfig["widgets"] = (array)myConfig["widgets"];
            }
            $widgets = myConfig["widgets"] + $widgets;
            unset(myConfig["widgets"]);
        }

        if (isset(myConfig["groupedInputTypes"])) {
            _groupedInputTypes = myConfig["groupedInputTypes"];
            unset(myConfig["groupedInputTypes"]);
        }

        super.this($view, myConfig);

        if (!$locator) {
            $locator = new WidgetLocator(this.templater(), _View, $widgets);
        }
        this.setWidgetLocator($locator);
        _idPrefix = this.getConfig("idPrefix");
    }

    /**
     * Get the widget locator currently used by the helper.
     *
     * @return uim.cake.View\Widget\WidgetLocator Current locator instance

     */
    auto getWidgetLocator(): WidgetLocator
    {
        return _locator;
    }

    /**
     * Set the widget locator the helper will use.
     *
     * @param uim.cake.View\Widget\WidgetLocator $instance The locator instance to set.
     * @return this

     */
    auto setWidgetLocator(WidgetLocator $instance) {
        _locator = $instance;

        return this;
    }

    /**
     * Set the context factory the helper will use.
     *
     * @param uim.cake.View\Form\ContextFactory|null $instance The context factory instance to set.
     * @param array $contexts An array of context providers.
     * @return uim.cake.View\Form\ContextFactory
     */
    ContextFactory contextFactory(?ContextFactory $instance = null, array $contexts = []) {
        if ($instance is null) {
            if (_contextFactory is null) {
                _contextFactory = ContextFactory::createWithDefaults($contexts);
            }

            return _contextFactory;
        }
        _contextFactory = $instance;

        return _contextFactory;
    }

    /**
     * Returns an HTML form element.
     *
     * ### Options:
     *
     * - `type` Form method defaults to autodetecting based on the form context. If
     *   the form context"s isCreate() method returns false, a PUT request will be done.
     * - `method` Set the form"s method attribute explicitly.
     * - `url` The URL the form submits to. Can be a string or a URL array.
     * - `encoding` Set the accept-charset encoding for the form. Defaults to `Configure::read("App.encoding")`
     * - `enctype` Set the form encoding explicitly. By default `type: file` will set `enctype`
     *   to `multipart/form-data`.
     * - `templates` The templates you want to use for this form. Any templates will be merged on top of
     *   the already loaded templates. This option can either be a filename in /config that contains
     *   the templates you want to load, or an array of templates to use.
     * - `context` Additional options for the context class. For example the EntityContext accepts a "table"
     *   option that allows you to set the specific Table class the form should be based on.
     * - `idPrefix` Prefix for generated ID attributes.
     * - `valueSources` The sources that values should be read from. See FormHelper::setValueSources()
     * - `templateVars` Provide template variables for the formStart template.
     *
     * @param mixed $context The context for which the form is being defined.
     *   Can be a IContext instance, ORM entity, ORM resultset, or an
     *   array of meta data. You can use `null` to make a context-less form.
     * @param array<string, mixed> myOptions An array of html attributes and options.
     * @return string An formatted opening FORM tag.
     * @link https://book.UIM.org/4/en/views/helpers/form.html#Cake\View\Helper\FormHelper::create
     */
    string create($context = null, array myOptions = []) {
        $append = "";

        if ($context instanceof IContext) {
            this.context($context);
        } else {
            if (empty(myOptions["context"])) {
                myOptions["context"] = [];
            }
            myOptions["context"]["entity"] = $context;
            $context = _getContext(myOptions["context"]);
            unset(myOptions["context"]);
        }

        $isCreate = $context.isCreate();

        myOptions += [
            "type": $isCreate ? "post" : "put",
            "url": null,
            "encoding": strtolower(Configure::read("App.encoding")),
            "templates": null,
            "idPrefix": null,
            "valueSources": null,
        ];

        if (isset(myOptions["valueSources"])) {
            this.setValueSources(myOptions["valueSources"]);
            unset(myOptions["valueSources"]);
        }

        if (myOptions["idPrefix"]  !is null) {
            _idPrefix = myOptions["idPrefix"];
        }
        myTemplater = this.templater();

        if (!empty(myOptions["templates"])) {
            myTemplater.push();
            $method = is_string(myOptions["templates"]) ? "load" : "add";
            myTemplater.{$method}(myOptions["templates"]);
        }
        unset(myOptions["templates"]);

        if (myOptions["url"] == false) {
            myUrl = _View.getRequest().getRequestTarget();
            $action = null;
        } else {
            myUrl = _formUrl($context, myOptions);
            $action = this.Url.build(myUrl);
        }

        _lastAction(myUrl);
        unset(myOptions["url"], myOptions["idPrefix"]);

        $htmlAttributes = [];
        switch (strtolower(myOptions["type"])) {
            case "get":
                $htmlAttributes["method"] = "get";
                break;
            // Set enctype for form
            case "file":
                $htmlAttributes["enctype"] = "multipart/form-data";
                myOptions["type"] = $isCreate ? "post" : "put";
            // Move on
            case "put":
            // Move on
            case "delete":
            // Set patch method
            case "patch":
                $append ~= this.hidden("_method", [
                    "name": "_method",
                    "value": strtoupper(myOptions["type"]),
                    "secure": static::SECURE_SKIP,
                ]);
            // Default to post method
            default:
                $htmlAttributes["method"] = "post";
        }
        if (isset(myOptions["method"])) {
            $htmlAttributes["method"] = strtolower(myOptions["method"]);
        }
        if (isset(myOptions["enctype"])) {
            $htmlAttributes["enctype"] = strtolower(myOptions["enctype"]);
        }

        this.requestType = strtolower(myOptions["type"]);

        if (!empty(myOptions["encoding"])) {
            $htmlAttributes["accept-charset"] = myOptions["encoding"];
        }
        unset(myOptions["type"], myOptions["encoding"]);

        $htmlAttributes += myOptions;

        if (this.requestType != "get") {
            $formTokenData = _View.getRequest().getAttribute("formTokenData");
            if ($formTokenData  !is null) {
                this.formProtector = this.createFormProtector($formTokenData);
            }

            $append ~= _csrfField();
        }

        if (!empty($append)) {
            $append = myTemplater.format("hiddenBlock", ["content": $append]);
        }

        $actionAttr = myTemplater.formatAttributes(["action": $action, "escape": false]);

        return this.formatTemplate("formStart", [
            "attrs": myTemplater.formatAttributes($htmlAttributes) . $actionAttr,
            "templateVars": myOptions["templateVars"] ?? [],
        ]) . $append;
    }

    /**
     * Create the URL for a form based on the options.
     *
     * @param uim.cake.View\Form\IContext $context The context object to use.
     * @param array<string, mixed> myOptions An array of options from create()
     * @return array|string The action attribute for the form.
     */
    protected auto _formUrl(IContext $context, array myOptions) {
        myRequest = _View.getRequest();

        if (myOptions["url"] is null) {
            return myRequest.getRequestTarget();
        }

        if (
            is_string(myOptions["url"]) ||
            (is_array(myOptions["url"]) &&
            isset(myOptions["url"]["_name"]))
        ) {
            return myOptions["url"];
        }

        $actionDefaults = [
            "plugin": _View.getPlugin(),
            "controller": myRequest.getParam("controller"),
            "action": myRequest.getParam("action"),
        ];

        $action = (array)myOptions["url"] + $actionDefaults;

        return $action;
    }

    /**
     * Correctly store the last created form action URL.
     *
     * @param array|string|null myUrl The URL of the last form.
     */
    protected void _lastAction(myUrl = null) {
        $action = Router::url(myUrl, true);
        myQuery = parse_url($action, PHP_URL_QUERY);
        myQuery = myQuery ? "?" ~ myQuery : "";

        myPath = parse_url($action, PHP_URL_PATH) ?: "";
        _lastAction = myPath . myQuery;
    }

    /**
     * Return a CSRF input if the request data is present.
     * Used to secure forms in conjunction with CsrfMiddleware.
     */
    protected string _csrfField() {
        myRequest = _View.getRequest();

        $csrfToken = myRequest.getAttribute("csrfToken");
        if (!$csrfToken) {
            return "";
        }

        return this.hidden("_csrfToken", [
            "value": $csrfToken,
            "secure": static::SECURE_SKIP,
            "autocomplete": "off",
        ]);
    }

    /**
     * Closes an HTML form, cleans up values set by FormHelper::create(), and writes hidden
     * input fields where appropriate.
     *
     * Resets some parts of the state, shared among multiple FormHelper::create() calls, to defaults.
     *
     * @param array<string, mixed> $secureAttributes Secure attributes which will be passed as HTML attributes
     *   into the hidden input elements generated for the Security Component.
     * @return string A closing FORM tag.
     * @link https://book.UIM.org/4/en/views/helpers/form.html#closing-the-form
     */
    string end(array $secureAttributes = []) {
        $out = "";

        if (this.requestType != "get" && _View.getRequest().getAttribute("formTokenData")  !is null) {
            $out ~= this.secure([], $secureAttributes);
        }
        $out ~= this.formatTemplate("formEnd", []);

        this.templater().pop();
        this.requestType = null;
        _context = null;
        _valueSources = ["data", "context"];
        _idPrefix = this.getConfig("idPrefix");
        this.formProtector = null;

        return $out;
    }

    /**
     * Generates a hidden field with a security hash based on the fields used in
     * the form.
     *
     * If $secureAttributes is set, these HTML attributes will be merged into
     * the hidden input tags generated for the Security Component. This is
     * especially useful to set HTML5 attributes like "form".
     *
     * @param array myFields If set specifies the list of fields to be added to
     *    FormProtector for generating the hash.
     * @param array<string, mixed> $secureAttributes will be passed as HTML attributes into the hidden
     *    input elements generated for the Security Component.
     * @return string A hidden input field with a security hash, or empty string when
     *   secured forms are not in use.
     */
    string secure(array myFields = [], array $secureAttributes = []) {
        if (!this.formProtector) {
            return "";
        }

        foreach (myFields as myField: myValue) {
            if (is_int(myField)) {
                myField = myValue;
                myValue = null;
            }
            this.formProtector.addField(myField, true, myValue);
        }

        $debugSecurity = (bool)Configure::read("debug");
        if (isset($secureAttributes["debugSecurity"])) {
            $debugSecurity = $debugSecurity && $secureAttributes["debugSecurity"];
            unset($secureAttributes["debugSecurity"]);
        }
        $secureAttributes["secure"] = static::SECURE_SKIP;
        $secureAttributes["autocomplete"] = "off";

        $tokenData = this.formProtector.buildTokenData(
            _lastAction,
            _View.getRequest().getSession().id()
        );
        $tokenFields = array_merge($secureAttributes, [
            "value": $tokenData["fields"],
        ]);
        $out = this.hidden("_Token.fields", $tokenFields);
        $tokenUnlocked = array_merge($secureAttributes, [
            "value": $tokenData["unlocked"],
        ]);
        $out ~= this.hidden("_Token.unlocked", $tokenUnlocked);
        if ($debugSecurity) {
            $tokenDebug = array_merge($secureAttributes, [
                "value": $tokenData["debug"],
            ]);
            $out ~= this.hidden("_Token.debug", $tokenDebug);
        }

        return this.formatTemplate("hiddenBlock", ["content": $out]);
    }

    /**
     * Add to the list of fields that are currently unlocked.
     *
     * Unlocked fields are not included in the form protection field hash.
     *
     * @param string myName The dot separated name for the field.
     * @return this
     */
    function unlockField(string myName) {
        this.getFormProtector().unlockField(myName);

        return this;
    }

    /**
     * Create FormProtector instance.
     *
     * @param array<string, mixed> $formTokenData Token data.
     * @return uim.cake.Form\FormProtector
     */
    protected FormProtector createFormProtector(array $formTokenData) {
        $session = _View.getRequest().getSession();
        $session.start();

        return new FormProtector(
            $formTokenData
        );
    }

    /**
     * Get form protector instance.
     *
     * @return uim.cake.Form\FormProtector
     * @throws uim.cake.Core\exceptions.UIMException
     */
    FormProtector getFormProtector(): 
    {
        if (this.formProtector is null) {
            throw new UIMException(
                "`FormProtector` instance has not been created. Ensure you have loaded the `FormProtectionComponent`"
                ~ " in your controller and called `FormHelper::create()` before calling `FormHelper::unlockField()`."
            );
        }

        return this.formProtector;
    }

    /**
     * Returns true if there is an error for the given field, otherwise false
     *
     * @param string myField This should be "modelname.fieldname"
     * @return bool If there are errors this method returns true, else false.
     * @link https://book.UIM.org/4/en/views/helpers/form.html#displaying-and-checking-errors
     */
    bool isFieldError(string myField) {
        return _getContext().hasError(myField);
    }

    /**
     * Returns a formatted error message for given form field, "" if no errors.
     *
     * Uses the `error`, `errorList` and `errorItem` templates. The `errorList` and
     * `errorItem` templates are used to format multiple error messages per field.
     *
     * ### Options:
     *
     * - `escape` boolean - Whether to html escape the contents of the error.
     *
     * @param string myField A field name, like "modelname.fieldname"
     * @param array|string|null $text Error message as string or array of messages. If an array,
     *   it should be a hash of key names: messages.
     * @param array<string, mixed> myOptions See above.
     * @return string Formatted errors or "".
     * @link https://book.UIM.org/4/en/views/helpers/form.html#displaying-and-checking-errors
     */
    string error(string myField, $text = null, array myOptions = []) {
        if (substr(myField, -5) == "._ids") {
            myField = substr(myField, 0, -5);
        }
        myOptions += ["escape": true];

        $context = _getContext();
        if (!$context.hasError(myField)) {
            return "";
        }
        myError = $context.error(myField);

        if (is_array($text)) {
            $tmp = [];
            foreach (myError as $k: $e) {
                if (isset($text[$k])) {
                    $tmp[] = $text[$k];
                } elseif (isset($text[$e])) {
                    $tmp[] = $text[$e];
                } else {
                    $tmp[] = $e;
                }
            }
            $text = $tmp;
        }

        if ($text  !is null) {
            myError = $text;
        }

        if (myOptions["escape"]) {
            myError = h(myError);
            unset(myOptions["escape"]);
        }

        if (is_array(myError)) {
            if (count(myError) > 1) {
                myErrorText = [];
                foreach (myError as $err) {
                    myErrorText[] = this.formatTemplate("errorItem", ["text": $err]);
                }
                myError = this.formatTemplate("errorList", [
                    "content": implode("", myErrorText),
                ]);
            } else {
                myError = array_pop(myError);
            }
        }

        return this.formatTemplate("error", [
            "content": myError,
            "id": _domId(myField) ~ "-error",
        ]);
    }

    /**
     * Returns a formatted LABEL element for HTML forms.
     *
     * Will automatically generate a `for` attribute if one is not provided.
     *
     * ### Options
     *
     * - `for` - Set the for attribute, if its not defined the for attribute
     *   will be generated from the myFieldName parameter using
     *   FormHelper::_domId().
     * - `escape` - Set to `false` to turn off escaping of label text.
     *   Defaults to `true`.
     *
     * Examples:
     *
     * The text and for attribute are generated off of the fieldname
     *
     * ```
     * echo this.Form.label("published");
     * <label for="PostPublished">Published</label>
     * ```
     *
     * Custom text:
     *
     * ```
     * echo this.Form.label("published", "Publish");
     * <label for="published">Publish</label>
     * ```
     *
     * Custom attributes:
     *
     * ```
     * echo this.Form.label("published", "Publish", [
     *   "for": "post-publish"
     * ]);
     * <label for="post-publish">Publish</label>
     * ```
     *
     * Nesting an input tag:
     *
     * ```
     * echo this.Form.label("published", "Publish", [
     *   "for": "published",
     *   "input": this.text("published"),
     * ]);
     * <label for="post-publish">Publish <input type="text" name="published"></label>
     * ```
     *
     * If you want to nest inputs in the labels, you will need to modify the default templates.
     *
     * @param string myFieldName This should be "modelname.fieldname"
     * @param string|null $text Text that will appear in the label field. If
     *   $text is left undefined the text will be inflected from the
     *   fieldName.
     * @param array<string, mixed> myOptions An array of HTML attributes.
     * @return string The formatted LABEL element
     * @link https://book.UIM.org/4/en/views/helpers/form.html#creating-labels
     */
    string label(string myFieldName, Nullable!string text = null, array myOptions = []) {
        if ($text is null) {
            $text = myFieldName;
            if (substr($text, -5) == "._ids") {
                $text = substr($text, 0, -5);
            }
            if (indexOf($text, ".") != false) {
                myFieldElements = explode(".", $text);
                $text = array_pop(myFieldElements);
            }
            if (substr($text, -3) == "_id") {
                $text = substr($text, 0, -3);
            }
            $text = __(Inflector::humanize(Inflector::underscore($text)));
        }

        if (isset(myOptions["for"])) {
            $labelFor = myOptions["for"];
            unset(myOptions["for"]);
        } else {
            $labelFor = _domId(myFieldName);
        }
        $attrs = myOptions + [
            "for": $labelFor,
            "text": $text,
        ];
        if (isset(myOptions["input"])) {
            if (is_array(myOptions["input"])) {
                $attrs = myOptions["input"] + $attrs;
            }

            return this.widget("nestingLabel", $attrs);
        }

        return this.widget("label", $attrs);
    }

    /**
     * Generate a set of controls for `myFields`. If myFields is empty the fields
     * of current model will be used.
     *
     * You can customize individual controls through `myFields`.
     * ```
     * this.Form.allControls([
     *   "name": ["label": "custom label"]
     * ]);
     * ```
     *
     * You can exclude fields by specifying them as `false`:
     *
     * ```
     * this.Form.allControls(["title": false]);
     * ```
     *
     * In the above example, no field would be generated for the title field.
     *
     * @param array myFields An array of customizations for the fields that will be
     *   generated. This array allows you to set custom types, labels, or other options.
     * @param array<string, mixed> myOptions Options array. Valid keys are:
     *
     * - `fieldset` Set to false to disable the fieldset. You can also pass an array of params to be
     *    applied as HTML attributes to the fieldset tag. If you pass an empty array, the fieldset will
     *    be enabled
     * - `legend` Set to false to disable the legend for the generated control set. Or supply a string
     *    to customize the legend text.
     * @return string Completed form controls.
     * @link https://book.UIM.org/4/en/views/helpers/form.html#generating-entire-forms
     */
    string allControls(array myFields = [], array myOptions = []) {
        $context = _getContext();

        myModelFields = $context.fieldNames();

        myFields = array_merge(
            Hash::normalize(myModelFields),
            Hash::normalize(myFields)
        );

        return this.controls(myFields, myOptions);
    }

    /**
     * Generate a set of controls for `myFields` wrapped in a fieldset element.
     *
     * You can customize individual controls through `myFields`.
     * ```
     * this.Form.controls([
     *   "name": ["label": "custom label"],
     *   "email"
     * ]);
     * ```
     *
     * @param array myFields An array of the fields to generate. This array allows
     *   you to set custom types, labels, or other options.
     * @param array<string, mixed> myOptions Options array. Valid keys are:
     *
     * - `fieldset` Set to false to disable the fieldset. You can also pass an
     *    array of params to be applied as HTML attributes to the fieldset tag.
     *    If you pass an empty array, the fieldset will be enabled.
     * - `legend` Set to false to disable the legend for the generated input set.
     *    Or supply a string to customize the legend text.
     * @return string Completed form inputs.
     * @link https://book.UIM.org/4/en/views/helpers/form.html#generating-entire-forms
     */
    string controls(array myFields, array myOptions = []) {
        myFields = Hash::normalize(myFields);

        $out = "";
        foreach (myFields as myName: $opts) {
            if ($opts == false) {
                continue;
            }

            $out ~= this.control(myName, (array)$opts);
        }

        return this.fieldset($out, myOptions);
    }

    /**
     * Wrap a set of inputs in a fieldset
     *
     * @param string myFields the form inputs to wrap in a fieldset
     * @param array<string, mixed> myOptions Options array. Valid keys are:
     *
     * - `fieldset` Set to false to disable the fieldset. You can also pass an array of params to be
     *    applied as HTML attributes to the fieldset tag. If you pass an empty array, the fieldset will
     *    be enabled
     * - `legend` Set to false to disable the legend for the generated input set. Or supply a string
     *    to customize the legend text.
     * @return string Completed form inputs.
     */
    string fieldset(string myFields = "", array myOptions = []) {
        $legend = myOptions["legend"] ?? true;
        myFieldset = myOptions["fieldset"] ?? true;
        $context = _getContext();
        $out = myFields;

        if ($legend == true) {
            $isCreate = $context.isCreate();
            myModelName = Inflector::humanize(
                Inflector::singularize(_View.getRequest().getParam("controller"))
            );
            if (!$isCreate) {
                $legend = __d("cake", "Edit {0}", myModelName);
            } else {
                $legend = __d("cake", "New {0}", myModelName);
            }
        }

        if (myFieldset != false) {
            if ($legend) {
                $out = this.formatTemplate("legend", ["text": $legend]) . $out;
            }

            myFieldsetParams = ["content": $out, "attrs": ""];
            if (is_array(myFieldset) && !empty(myFieldset)) {
                myFieldsetParams["attrs"] = this.templater().formatAttributes(myFieldset);
            }
            $out = this.formatTemplate("fieldset", myFieldsetParams);
        }

        return $out;
    }

    /**
     * Generates a form control element complete with label and wrapper div.
     *
     * ### Options
     *
     * See each field type method for more information. Any options that are part of
     * $attributes or myOptions for the different **type** methods can be included in `myOptions` for control().
     * Additionally, any unknown keys that are not in the list below, or part of the selected type"s options
     * will be treated as a regular HTML attribute for the generated input.
     *
     * - `type` - Force the type of widget you want. e.g. `type: "select"`
     * - `label` - Either a string label, or an array of options for the label. See FormHelper::label().
     * - `options` - For widgets that take options e.g. radio, select.
     * - `error` - Control the error message that is produced. Set to `false` to disable any kind of error reporting
     *   (field error and error messages).
     * - `empty` - String or boolean to enable empty select box options.
     * - `nestedInput` - Used with checkbox and radio inputs. Set to false to render inputs outside of label
     *   elements. Can be set to true on any input to force the input inside the label. If you
     *   enable this option for radio buttons you will also need to modify the default `radioWrapper` template.
     * - `templates` - The templates you want to use for this input. Any templates will be merged on top of
     *   the already loaded templates. This option can either be a filename in /config that contains
     *   the templates you want to load, or an array of templates to use.
     * - `labelOptions` - Either `false` to disable label around nestedWidgets e.g. radio, multicheckbox or an array
     *   of attributes for the label tag. `selected` will be added to any classes e.g. `class: "myclass"` where
     *   widget is checked
     *
     * @param string myFieldName This should be "modelname.fieldname"
     * @param array<string, mixed> myOptions Each type of input takes different options.
     * @return string Completed form widget.
     * @link https://book.UIM.org/4/en/views/helpers/form.html#creating-form-inputs
     * @psalm-suppress InvalidReturnType
     * @psalm-suppress InvalidReturnStatement
     */
    string control(string myFieldName, array myOptions = []) {
        myOptions += [
            "type": null,
            "label": null,
            "error": null,
            "required": null,
            "options": null,
            "templates": [],
            "templateVars": [],
            "labelOptions": true,
        ];
        myOptions = _parseOptions(myFieldName, myOptions);
        myOptions += ["id": _domId(myFieldName)];

        myTemplater = this.templater();
        $newTemplates = myOptions["templates"];

        if ($newTemplates) {
            myTemplater.push();
            myTemplateMethod = is_string(myOptions["templates"]) ? "load" : "add";
            myTemplater.{myTemplateMethod}(myOptions["templates"]);
        }
        unset(myOptions["templates"]);

        // Hidden inputs don"t need aria.
        // Multiple checkboxes can"t have aria generated for them at this layer.
        if (myOptions["type"] != "hidden" && (myOptions["type"] != "select" && !isset(myOptions["multiple"]))) {
            $isFieldError = this.isFieldError(myFieldName);
            myOptions += [
                "aria-required": myOptions["required"] == true ? "true" : null,
                "aria-invalid": $isFieldError ? "true" : null,
            ];
            // Don"t include aria-describedby unless we have a good chance of
            // having error message show up.
            if (
                indexOf(myTemplater.get("error"), "{{id}}") != false &&
                indexOf(myTemplater.get("inputContainerError"), "{{error}}") != false
            ) {
                myOptions += [
                   "aria-describedby": $isFieldError ? _domId(myFieldName) ~ "-error" : null,
                ];
            }
            if (isset(myOptions["placeholder"]) && myOptions["label"] == false) {
                myOptions += [
                    "aria-label": myOptions["placeholder"],
                ];
            }
        }

        myError = null;
        myErrorSuffix = "";
        if (myOptions["type"] != "hidden" && myOptions["error"] != false) {
            if (is_array(myOptions["error"])) {
                myError = this.error(myFieldName, myOptions["error"], myOptions["error"]);
            } else {
                myError = this.error(myFieldName, myOptions["error"]);
            }
            myErrorSuffix = empty(myError) ? "" : "Error";
            unset(myOptions["error"]);
        }

        $label = myOptions["label"];
        unset(myOptions["label"]);

        $labelOptions = myOptions["labelOptions"];
        unset(myOptions["labelOptions"]);

        $nestedInput = false;
        if (myOptions["type"] == "checkbox") {
            $nestedInput = true;
        }
        $nestedInput = myOptions["nestedInput"] ?? $nestedInput;
        unset(myOptions["nestedInput"]);

        if (
            $nestedInput == true
            && myOptions["type"] == "checkbox"
            && !array_key_exists("hiddenField", myOptions)
            && $label != false
        ) {
            myOptions["hiddenField"] = "_split";
        }

        $input = _getInput(myFieldName, myOptions + ["labelOptions": $labelOptions]);
        if (myOptions["type"] == "hidden" || myOptions["type"] == "submit") {
            if ($newTemplates) {
                myTemplater.pop();
            }

            return $input;
        }

        $label = _getLabel(myFieldName, compact("input", "label", "error", "nestedInput") + myOptions);
        if ($nestedInput) {
            myResult = _groupTemplate(compact("label", "error", "options"));
        } else {
            myResult = _groupTemplate(compact("input", "label", "error", "options"));
        }
        myResult = _inputContainerTemplate([
            "content": myResult,
            "error": myError,
            "errorSuffix": myErrorSuffix,
            "options": myOptions,
        ]);

        if ($newTemplates) {
            myTemplater.pop();
        }

        return myResult;
    }

    /**
     * Generates an group template element
     *
     * @param array<string, mixed> myOptions The options for group template
     * @return string The generated group template
     */
    protected string _groupTemplate(array myOptions) {
        myGroupTemplate = myOptions["options"]["type"] ~ "FormGroup";
        if (!this.templater().get(myGroupTemplate)) {
            myGroupTemplate = "formGroup";
        }

        return this.formatTemplate(myGroupTemplate, [
            "input": myOptions["input"] ?? [],
            "label": myOptions["label"],
            "error": myOptions["error"],
            "templateVars": myOptions["options"]["templateVars"] ?? [],
        ]);
    }

    /**
     * Generates an input container template
     *
     * @param array<string, mixed> myOptions The options for input container template
     * @return string The generated input container template
     */
    protected string _inputContainerTemplate(array myOptions) {
        $inputContainerTemplate = myOptions["options"]["type"] ~ "Container" ~ myOptions["errorSuffix"];
        if (!this.templater().get($inputContainerTemplate)) {
            $inputContainerTemplate = "inputContainer" ~ myOptions["errorSuffix"];
        }

        return this.formatTemplate($inputContainerTemplate, [
            "content": myOptions["content"],
            "error": myOptions["error"],
            "required": myOptions["options"]["required"] ? " required" : "",
            "type": myOptions["options"]["type"],
            "templateVars": myOptions["options"]["templateVars"] ?? [],
        ]);
    }

    /**
     * Generates an input element
     *
     * @param string myFieldName the field name
     * @param array<string, mixed> myOptions The options for the input element
     * @return array|string The generated input element string
     *  or array if checkbox() is called with option "hiddenField" set to "_split".
     */
    protected auto _getInput(string myFieldName, array myOptions) {
        $label = myOptions["labelOptions"];
        unset(myOptions["labelOptions"]);
        switch (strtolower(myOptions["type"])) {
            case "select":
            case "radio":
            case "multicheckbox":
                $opts = myOptions["options"];
                if ($opts is null) {
                    $opts = [];
                }
                unset(myOptions["options"]);

                return this.{myOptions["type"]}(myFieldName, $opts, myOptions + ["label": $label]);
            case "input":
                throw new RuntimeException("Invalid type "input" used for field "myFieldName"");

            default:
                return this.{myOptions["type"]}(myFieldName, myOptions);
        }
    }

    /**
     * Generates input options array
     *
     * @param string myFieldName The name of the field to parse options for.
     * @param array<string, mixed> myOptions Options list.
     * @return array<string, mixed> Options
     */
    protected auto _parseOptions(string myFieldName, array myOptions)array
    {
        $needsMagicType = false;
        if (empty(myOptions["type"])) {
            $needsMagicType = true;
            myOptions["type"] = _inputType(myFieldName, myOptions);
        }

        myOptions = _magicOptions(myFieldName, myOptions, $needsMagicType);

        return myOptions;
    }

    /**
     * Returns the input type that was guessed for the provided fieldName,
     * based on the internal type it is associated too, its name and the
     * variables that can be found in the view template
     *
     * @param string myFieldName the name of the field to guess a type for
     * @param array<string, mixed> myOptions the options passed to the input method
     * @return string
     */
    protected string _inputType(string myFieldName, array myOptions) {
        $context = _getContext();

        if ($context.isPrimaryKey(myFieldName)) {
            return "hidden";
        }

        if (substr(myFieldName, -3) == "_id") {
            return "select";
        }

        myType = "text";
        $internalType = $context.type(myFieldName);
        $map = _config["typeMap"];
        if ($internalType  !is null && isset($map[$internalType])) {
            myType = $map[$internalType];
        }
        myFieldName = array_slice(explode(".", myFieldName), -1)[0];

        switch (true) {
            case isset(myOptions["checked"]):
                return "checkbox";
            case isset(myOptions["options"]):
                return "select";
            case in_array(myFieldName, ["passwd", "password"], true):
                return "password";
            case in_array(myFieldName, ["tel", "telephone", "phone"], true):
                return "tel";
            case myFieldName == "email":
                return "email";
            case isset(myOptions["rows"]) || isset(myOptions["cols"]):
                return "textarea";
            case myFieldName == "year":
                return "year";
        }

        return myType;
    }

    /**
     * Selects the variable containing the options for a select field if present,
     * and sets the value to the "options" key in the options array.
     *
     * @param string myFieldName The name of the field to find options for.
     * @param array<string, mixed> myOptions Options list.
     * @return array
     */
    protected array _optionsOptions(string myFieldName, array myOptions) {
        if (isset(myOptions["options"])) {
            return myOptions;
        }

        $pluralize = true;
        if (substr(myFieldName, -5) == "._ids") {
            myFieldName = substr(myFieldName, 0, -5);
            $pluralize = false;
        } elseif (substr(myFieldName, -3) == "_id") {
            myFieldName = substr(myFieldName, 0, -3);
        }
        myFieldName = array_slice(explode(".", myFieldName), -1)[0];

        $varName = Inflector::variable(
            $pluralize ? Inflector::pluralize(myFieldName) : myFieldName
        );
        $varOptions = _View.get($varName);
        if (!is_iterable($varOptions)) {
            return myOptions;
        }
        if (myOptions["type"] != "radio") {
            myOptions["type"] = "select";
        }
        myOptions["options"] = $varOptions;

        return myOptions;
    }

    /**
     * Magically set option type and corresponding options
     *
     * @param string myFieldName The name of the field to generate options for.
     * @param array<string, mixed> myOptions Options list.
     * @param bool $allowOverride Whether it is allowed for this method to
     * overwrite the "type" key in options.
     * @return array<string, mixed>
     */
    protected array _magicOptions(string myFieldName, array myOptions, bool $allowOverride) {
        myOptions += [
            "templateVars": [],
        ];

        myOptions = this.setRequiredAndCustomValidity(myFieldName, myOptions);

        myTypesWithOptions = ["text", "number", "radio", "select"];
        $magicOptions = (in_array(myOptions["type"], ["radio", "select"], true) || $allowOverride);
        if ($magicOptions && in_array(myOptions["type"], myTypesWithOptions, true)) {
            myOptions = _optionsOptions(myFieldName, myOptions);
        }

        if ($allowOverride && substr(myFieldName, -5) == "._ids") {
            myOptions["type"] = "select";
            if (!isset(myOptions["multiple"]) || (myOptions["multiple"] && myOptions["multiple"] != "checkbox")) {
                myOptions["multiple"] = true;
            }
        }

        return myOptions;
    }

    /**
     * Set required attribute and custom validity JS.
     *
     * @param string myFieldName The name of the field to generate options for.
     * @param array<string, mixed> myOptions Options list.
     * @return array<string, mixed> Modified options list.
     */
    protected auto setRequiredAndCustomValidity(string myFieldName, array myOptions) {
        $context = _getContext();

        if (!isset(myOptions["required"]) && myOptions["type"] != "hidden") {
            myOptions["required"] = $context.isRequired(myFieldName);
        }

        myMessage = $context.getRequiredMessage(myFieldName);
        myMessage = h(myMessage);

        if (myOptions["required"] && myMessage) {
            myOptions["templateVars"]["customValidityMessage"] = myMessage;

            if (this.getConfig("autoSetCustomValidity")) {
                myOptions["data-validity-message"] = myMessage;
                myOptions["oninvalid"] = "this.setCustomValidity(""); "
                    ~ "if (!this.value) this.setCustomValidity(this.dataset.validityMessage)";
                myOptions["oninput"] = "this.setCustomValidity("")";
            }
        }

        return myOptions;
    }

    /**
     * Generate label for input
     *
     * @param string myFieldName The name of the field to generate label for.
     * @param array<string, mixed> myOptions Options list.
     * @return string|false Generated label element or false.
     */
    protected auto _getLabel(string myFieldName, array myOptions) {
        if (myOptions["type"] == "hidden") {
            return false;
        }

        $label = myOptions["label"] ?? null;

        if ($label == false && myOptions["type"] == "checkbox") {
            return myOptions["input"];
        }
        if ($label == false) {
            return false;
        }

        return _inputLabel(myFieldName, $label, myOptions);
    }

    /**
     * Extracts a single option from an options array.
     *
     * @param string myName The name of the option to pull out.
     * @param array<string, mixed> myOptions The array of options you want to extract.
     * @param mixed $default The default option value
     * @return mixed the contents of the option or default
     */
    protected auto _extractOption(string myName, array myOptions, $default = null) {
        if (array_key_exists(myName, myOptions)) {
            return myOptions[myName];
        }

        return $default;
    }

    /**
     * Generate a label for an input() call.
     *
     * myOptions can contain a hash of id overrides. These overrides will be
     * used instead of the generated values if present.
     *
     * @param string myFieldName The name of the field to generate label for.
     * @param array<string, mixed>|string|null $label Label text or array with label attributes.
     * @param array<string, mixed> myOptions Options for the label element.
     * @return string Generated label element
     */
    protected string _inputLabel(string myFieldName, $label = null, array myOptions = []) {
        myOptions += ["id": null, "input": null, "nestedInput": false, "templateVars": []];
        $labelAttributes = ["templateVars": myOptions["templateVars"]];
        if (is_array($label)) {
            $labelText = null;
            if (isset($label["text"])) {
                $labelText = $label["text"];
                unset($label["text"]);
            }
            $labelAttributes = array_merge($labelAttributes, $label);
        } else {
            $labelText = $label;
        }

        $labelAttributes["for"] = myOptions["id"];
        if (in_array(myOptions["type"], _groupedInputTypes, true)) {
            $labelAttributes["for"] = false;
        }
        if (myOptions["nestedInput"]) {
            $labelAttributes["input"] = myOptions["input"];
        }
        if (isset(myOptions["escape"])) {
            $labelAttributes["escape"] = myOptions["escape"];
        }

        return this.label(myFieldName, $labelText, $labelAttributes);
    }

    /**
     * Creates a checkbox input widget.
     *
     * ### Options:
     *
     * - `value` - the value of the checkbox
     * - `checked` - boolean indicate that this checkbox is checked.
     * - `hiddenField` - boolean to indicate if you want the results of checkbox() to include
     *    a hidden input with a value of "".
     * - `disabled` - create a disabled input.
     * - `default` - Set the default value for the checkbox. This allows you to start checkboxes
     *    as checked, without having to check the POST data. A matching POST data value, will overwrite
     *    the default value.
     *
     * @param string myFieldName Name of a field, like this "modelname.fieldname"
     * @param array<string, mixed> myOptions Array of HTML attributes.
     * @link https://book.UIM.org/4/en/views/helpers/form.html#creating-checkboxes
     */
    string[] checkbox(string myFieldName, array myOptions = []) {
        myOptions += ["hiddenField": true, "value": 1];

        // Work around value=>val translations.
        myValue = myOptions["value"];
        unset(myOptions["value"]);
        myOptions = _initInputField(myFieldName, myOptions);
        myOptions["value"] = myValue;

        $output = "";
        if (myOptions["hiddenField"]) {
            myHiddenOptions = [
                "name": myOptions["name"],
                "value": myOptions["hiddenField"] != true
                    && myOptions["hiddenField"] != "_split"
                    ? myOptions["hiddenField"] : "0",
                "form": myOptions["form"] ?? null,
                "secure": false,
            ];
            if (isset(myOptions["disabled"]) && myOptions["disabled"]) {
                myHiddenOptions["disabled"] = "disabled";
            }
            $output = this.hidden(myFieldName, myHiddenOptions);
        }

        if (myOptions["hiddenField"] == "_split") {
            unset(myOptions["hiddenField"], myOptions["type"]);

            return ["hidden": $output, "input": this.widget("checkbox", myOptions)];
        }
        unset(myOptions["hiddenField"], myOptions["type"]);

        return $output . this.widget("checkbox", myOptions);
    }

    /**
     * Creates a set of radio widgets.
     *
     * ### Attributes:
     *
     * - `value` - Indicates the value when this radio button is checked.
     * - `label` - Either `false` to disable label around the widget or an array of attributes for
     *    the label tag. `selected` will be added to any classes e.g. `"class": "myclass"` where widget
     *    is checked
     * - `hiddenField` - boolean to indicate if you want the results of radio() to include
     *    a hidden input with a value of "". This is useful for creating radio sets that are non-continuous.
     * - `disabled` - Set to `true` or `disabled` to disable all the radio buttons. Use an array of
     *   values to disable specific radio buttons.
     * - `empty` - Set to `true` to create an input with the value "" as the first option. When `true`
     *   the radio label will be "empty". Set this option to a string to control the label value.
     *
     * @param string myFieldName Name of a field, like this "modelname.fieldname"
     * @param iterable myOptions Radio button options array.
     * @param array<string, mixed> $attributes Array of attributes.
     * @return string Completed radio widget set.
     * @link https://book.UIM.org/4/en/views/helpers/form.html#creating-radio-buttons
     */
    string radio(string myFieldName, iterable myOptions = [], array $attributes = []) {
        $attributes["options"] = myOptions;
        $attributes["idPrefix"] = _idPrefix;
        $attributes = _initInputField(myFieldName, $attributes);

        myHiddenField = $attributes["hiddenField"] ?? true;
        unset($attributes["hiddenField"]);

        $radio = this.widget("radio", $attributes);

        myHidden = "";
        if (myHiddenField) {
            myHidden = this.hidden(myFieldName, [
                "value": myHiddenField == true ? "" : myHiddenField,
                "form": $attributes["form"] ?? null,
                "name": $attributes["name"],
            ]);
        }

        return myHidden . $radio;
    }

    /**
     * Missing method handler - : various simple input types. Is used to create inputs
     * of various types. e.g. `this.Form.text();` will create `<input type="text"/>` while
     * `this.Form.range();` will create `<input type="range"/>`
     *
     * ### Usage
     *
     * ```
     * this.Form.search("User.query", ["value": "test"]);
     * ```
     *
     * Will make an input like:
     *
     * `<input type="search" id="UserQuery" name="User[query]" value="test"/>`
     *
     * The first argument to an input type should always be the fieldname, in `Model.field` format.
     * The second argument should always be an array of attributes for the input.
     *
     * @param string method Method name / input type to make.
     * @param array myParams Parameters for the method call
     * @return string Formatted input method.
     * @throws uim.cake.Core\exceptions.UIMException When there are no params for the method call.
     */
    auto __call(string method, array myParams) {
        if (empty(myParams)) {
            throw new UIMException(sprintf("Missing field name for FormHelper::%s", $method));
        }
        myOptions = myParams[1] ?? [];
        myOptions["type"] = myOptions["type"] ?? $method;
        myOptions = _initInputField(myParams[0], myOptions);

        return this.widget(myOptions["type"], myOptions);
    }

    /**
     * Creates a textarea widget.
     *
     * ### Options:
     *
     * - `escape` - Whether the contents of the textarea should be escaped. Defaults to true.
     *
     * @param string myFieldName Name of a field, in the form "modelname.fieldname"
     * @param array<string, mixed> myOptions Array of HTML attributes, and special options above.
     * @return string A generated HTML text input element
     * @link https://book.UIM.org/4/en/views/helpers/form.html#creating-textareas
     */
    string textarea(string myFieldName, array myOptions = []) {
        myOptions = _initInputField(myFieldName, myOptions);
        unset(myOptions["type"]);

        return this.widget("textarea", myOptions);
    }

    /**
     * Creates a hidden input field.
     *
     * @param string myFieldName Name of a field, in the form of "modelname.fieldname"
     * @param array<string, mixed> myOptions Array of HTML attributes.
     * @return string A generated hidden input
     * @link https://book.UIM.org/4/en/views/helpers/form.html#creating-hidden-inputs
     */
    string hidden(string myFieldName, array myOptions = []) {
        myOptions += ["required": false, "secure": true];

        $secure = myOptions["secure"];
        unset(myOptions["secure"]);

        myOptions = _initInputField(myFieldName, array_merge(
            myOptions,
            ["secure": static::SECURE_SKIP]
        ));

        if ($secure == true && this.formProtector) {
            this.formProtector.addField(
                myOptions["name"],
                true,
                myOptions["val"] == false ? "0" : (string)myOptions["val"]
            );
        }

        myOptions["type"] = "hidden";

        return this.widget("hidden", myOptions);
    }

    /**
     * Creates file input widget.
     *
     * @param string myFieldName Name of a field, in the form "modelname.fieldname"
     * @param array<string, mixed> myOptions Array of HTML attributes.
     * @return string A generated file input.
     * @link https://book.UIM.org/4/en/views/helpers/form.html#creating-file-inputs
     */
    string file(string myFieldName, array myOptions = []) {
        myOptions += ["secure": true];
        myOptions = _initInputField(myFieldName, myOptions);

        unset(myOptions["type"]);

        return this.widget("file", myOptions);
    }

    /**
     * Creates a `<button>` tag.
     *
     * ### Options:
     *
     * - `type` - Value for "type" attribute of button. Defaults to "submit".
     * - `escapeTitle` - HTML entity encode the title of the button. Defaults to true.
     * - `escape` - HTML entity encode the attributes of button tag. Defaults to true.
     * - `confirm` - Confirm message to show. Form execution will only continue if confirmed then.
     *
     * @param string title The button"s caption. Not automatically HTML encoded
     * @param array<string, mixed> myOptions Array of options and HTML attributes.
     * @return string A HTML button tag.
     * @link https://book.UIM.org/4/en/views/helpers/form.html#creating-button-elements
     */
    string button(string title, array myOptions = []) {
        myOptions += [
            "type": "submit",
            "escapeTitle": true,
            "escape": true,
            "secure": false,
            "confirm": null,
        ];
        myOptions["text"] = $title;

        $confirmMessage = myOptions["confirm"];
        unset(myOptions["confirm"]);
        if ($confirmMessage) {
            $confirm = _confirm("return true;", "return false;");
            myOptions["data-confirm-message"] = $confirmMessage;
            myOptions["onclick"] = this.templater().format("confirmJs", [
                "confirmMessage": h($confirmMessage),
                "confirm": $confirm,
            ]);
        }

        return this.widget("button", myOptions);
    }

    /**
     * Create a `<button>` tag with a surrounding `<form>` that submits via POST as default.
     *
     * This method creates a `<form>` element. So do not use this method in an already opened form.
     * Instead use FormHelper::submit() or FormHelper::button() to create buttons inside opened forms.
     *
     * ### Options:
     *
     * - `data` - Array with key/value to pass in input hidden
     * - `method` - Request method to use. Set to "delete" or others to simulate
     *   HTTP/1.1 DELETE (or others) request. Defaults to "post".
     * - `form` - Array with any option that FormHelper::create() can take
     * - Other options is the same of button method.
     * - `confirm` - Confirm message to show. Form execution will only continue if confirmed then.
     *
     * @param string title The button"s caption. Not automatically HTML encoded
     * @param array|string myUrl URL as string or array
     * @param array<string, mixed> myOptions Array of options and HTML attributes.
     * @return string A HTML button tag.
     * @link https://book.UIM.org/4/en/views/helpers/form.html#creating-standalone-buttons-and-post-links
     */
    string postButton(string title, myUrl, array myOptions = []) {
        $formOptions = ["url": myUrl];
        if (isset(myOptions["method"])) {
            $formOptions["type"] = myOptions["method"];
            unset(myOptions["method"]);
        }
        if (isset(myOptions["form"]) && is_array(myOptions["form"])) {
            $formOptions = myOptions["form"] + $formOptions;
            unset(myOptions["form"]);
        }
        $out = this.create(null, $formOptions);
        if (isset(myOptions["data"]) && is_array(myOptions["data"])) {
            foreach (Hash::flatten(myOptions["data"]) as myKey: myValue) {
                $out ~= this.hidden(myKey, ["value": myValue]);
            }
            unset(myOptions["data"]);
        }
        $out ~= this.button($title, myOptions);
        $out ~= this.end();

        return $out;
    }

    /**
     * Creates an HTML link, but access the URL using the method you specify
     * (defaults to POST). Requires javascript to be enabled in browser.
     *
     * This method creates a `<form>` element. If you want to use this method inside of an
     * existing form, you must use the `block` option so that the new form is being set to
     * a view block that can be rendered outside of the main form.
     *
     * If all you are looking for is a button to submit your form, then you should use
     * `FormHelper::button()` or `FormHelper::submit()` instead.
     *
     * ### Options:
     *
     * - `data` - Array with key/value to pass in input hidden
     * - `method` - Request method to use. Set to "delete" to simulate
     *   HTTP/1.1 DELETE request. Defaults to "post".
     * - `confirm` - Confirm message to show. Form execution will only continue if confirmed then.
     * - `block` - Set to true to append form to view block "postLink" or provide
     *   custom block name.
     * - Other options are the same of HtmlHelper::link() method.
     * - The option `onclick` will be replaced.
     *
     * @param string title The content to be wrapped by <a> tags.
     * @param array|string|null myUrl Cake-relative URL or array of URL parameters, or
     *   external URL (starts with http://)
     * @param array<string, mixed> myOptions Array of HTML attributes.
     * @return string An `<a />` element.
     * @link https://book.UIM.org/4/en/views/helpers/form.html#creating-standalone-buttons-and-post-links
     */
    string postLink(string title, myUrl = null, array myOptions = []) {
        myOptions += ["block": null, "confirm": null];

        myRequestMethod = "POST";
        if (!empty(myOptions["method"])) {
            myRequestMethod = strtoupper(myOptions["method"]);
            unset(myOptions["method"]);
        }

        $confirmMessage = myOptions["confirm"];
        unset(myOptions["confirm"]);

        $formName = str_replace(".", "", uniqid("post_", true));
        $formOptions = [
            "name": $formName,
            "style": "display:none;",
            "method": "post",
        ];
        if (isset(myOptions["target"])) {
            $formOptions["target"] = myOptions["target"];
            unset(myOptions["target"]);
        }
        myTemplater = this.templater();

        $restoreAction = _lastAction;
        _lastAction(myUrl);
        $restoreFormProtector = this.formProtector;

        $action = myTemplater.formatAttributes([
            "action": this.Url.build(myUrl),
            "escape": false,
        ]);

        $out = this.formatTemplate("formStart", [
            "attrs": myTemplater.formatAttributes($formOptions) . $action,
        ]);
        $out ~= this.hidden("_method", [
            "value": myRequestMethod,
            "secure": static::SECURE_SKIP,
        ]);
        $out ~= _csrfField();

        $formTokenData = _View.getRequest().getAttribute("formTokenData");
        if ($formTokenData  !is null) {
            this.formProtector = this.createFormProtector($formTokenData);
        }

        myFields = [];
        if (isset(myOptions["data"]) && is_array(myOptions["data"])) {
            foreach (Hash::flatten(myOptions["data"]) as myKey: myValue) {
                myFields[myKey] = myValue;
                $out ~= this.hidden(myKey, ["value": myValue, "secure": static::SECURE_SKIP]);
            }
            unset(myOptions["data"]);
        }
        $out ~= this.secure(myFields);
        $out ~= this.formatTemplate("formEnd", []);

        _lastAction = $restoreAction;
        this.formProtector = $restoreFormProtector;

        if (myOptions["block"]) {
            if (myOptions["block"] == true) {
                myOptions["block"] = __FUNCTION__;
            }
            _View.append(myOptions["block"], $out);
            $out = "";
        }
        unset(myOptions["block"]);

        myUrl = "#";
        $onClick = "document." ~ $formName ~ ".submit();";
        if ($confirmMessage) {
            $onClick = _confirm($onClick, "");
            $onClick = $onClick ~ "event.returnValue = false; return false;";
            $onClick = this.templater().format("confirmJs", [
                "confirmMessage": h($confirmMessage),
                "formName": $formName,
                "confirm": $onClick,
            ]);
            myOptions["data-confirm-message"] = $confirmMessage;
        } else {
            $onClick ~= " event.returnValue = false; return false;";
        }
        myOptions["onclick"] = $onClick;

        $out ~= this.Html.link($title, myUrl, myOptions);

        return $out;
    }

    /**
     * Creates a submit button element. This method will generate `<input />` elements that
     * can be used to submit, and reset forms by using myOptions. image submits can be created by supplying an
     * image path for $caption.
     *
     * ### Options
     *
     * - `type` - Set to "reset" for reset inputs. Defaults to "submit"
     * - `templateVars` - Additional template variables for the input element and its container.
     * - Other attributes will be assigned to the input element.
     *
     * @param string|null $caption The label appearing on the button OR if string contains :// or the
     *  extension .jpg, .jpe, .jpeg, .gif, .png use an image if the extension
     *  exists, AND the first character is /, image is relative to webroot,
     *  OR if the first character is not /, image is relative to webroot/img.
     * @param array<string, mixed> myOptions Array of options. See above.
     * @return string A HTML submit button
     * @link https://book.UIM.org/4/en/views/helpers/form.html#creating-buttons-and-submit-elements
     */
    string submit(Nullable!string caption = null, array myOptions = []) {
        if ($caption is null) {
            $caption = __d("cake", "Submit");
        }
        myOptions += [
            "type": "submit",
            "secure": false,
            "templateVars": [],
        ];

        if (isset(myOptions["name"]) && this.formProtector) {
            this.formProtector.addField(
                myOptions["name"],
                myOptions["secure"]
            );
        }
        unset(myOptions["secure"]);

        $isUrl = indexOf($caption, "://") != false;
        $isImage = preg_match("/\.(jpg|jpe|jpeg|gif|png|ico)$/", $caption);

        myType = myOptions["type"];
        unset(myOptions["type"]);

        if ($isUrl || $isImage) {
            myType = "image";

            if (this.formProtector) {
                $unlockFields = ["x", "y"];
                if (isset(myOptions["name"])) {
                    $unlockFields = [
                        myOptions["name"] ~ "_x",
                        myOptions["name"] ~ "_y",
                    ];
                }
                foreach ($unlockFields as $ignore) {
                    this.unlockField($ignore);
                }
            }
        }

        if ($isUrl) {
            myOptions["src"] = $caption;
        } elseif ($isImage) {
            if ($caption[0] != "/") {
                myUrl = this.Url.webroot(Configure::read("App.imageBaseUrl") . $caption);
            } else {
                myUrl = this.Url.webroot(trim($caption, "/"));
            }
            myUrl = this.Url.assetTimestamp(myUrl);
            myOptions["src"] = myUrl;
        } else {
            myOptions["value"] = $caption;
        }

        $input = this.formatTemplate("inputSubmit", [
            "type": myType,
            "attrs": this.templater().formatAttributes(myOptions),
            "templateVars": myOptions["templateVars"],
        ]);

        return this.formatTemplate("submitContainer", [
            "content": $input,
            "templateVars": myOptions["templateVars"],
        ]);
    }

    /**
     * Returns a formatted SELECT element.
     *
     * ### Attributes:
     *
     * - `multiple` - show a multiple select box. If set to "checkbox" multiple checkboxes will be
     *   created instead.
     * - `empty` - If true, the empty select option is shown. If a string,
     *   that string is displayed as the empty element.
     * - `escape` - If true contents of options will be HTML entity encoded. Defaults to true.
     * - `val` The selected value of the input.
     * - `disabled` - Control the disabled attribute. When creating a select box, set to true to disable the
     *   select box. Set to an array to disable specific option elements.
     *
     * ### Using options
     *
     * A simple array will create normal options:
     *
     * ```
     * myOptions = [1: "one", 2: "two"];
     * this.Form.select("Model.field", myOptions));
     * ```
     *
     * While a nested options array will create optgroups with options inside them.
     * ```
     * myOptions = [
     *  1: "bill",
     *     "fred": [
     *         2: "fred",
     *         3: "fred jr."
     *     ]
     * ];
     * this.Form.select("Model.field", myOptions);
     * ```
     *
     * If you have multiple options that need to have the same value attribute, you can
     * use an array of arrays to express this:
     *
     * ```
     * myOptions = [
     *     ["text": "United states", "value": "USA"],
     *     ["text": "USA", "value": "USA"],
     * ];
     * ```
     *
     * @param string myFieldName Name attribute of the SELECT
     * @param iterable myOptions Array of the OPTION elements (as "value"=>"Text" pairs) to be used in the
     *   SELECT element
     * @param array<string, mixed> $attributes The HTML attributes of the select element.
     * @return string Formatted SELECT element
     * @see uim.cake.View\Helper\FormHelper::multiCheckbox() for creating multiple checkboxes.
     * @link https://book.UIM.org/4/en/views/helpers/form.html#creating-select-pickers
     */
    string select(string myFieldName, iterable myOptions = [], array $attributes = []) {
        $attributes += [
            "disabled": null,
            "escape": true,
            "hiddenField": true,
            "multiple": null,
            "secure": true,
            "empty": null,
        ];

        if ($attributes["empty"] is null && $attributes["multiple"] != "checkbox") {
            $required = _getContext().isRequired(myFieldName);
            $attributes["empty"] = $required is null ? false : !$required;
        }

        if ($attributes["multiple"] == "checkbox") {
            unset($attributes["multiple"], $attributes["empty"]);

            return this.multiCheckbox(myFieldName, myOptions, $attributes);
        }

        unset($attributes["label"]);

        // Secure the field if there are options, or it"s a multi select.
        // Single selects with no options don"t submit, but multiselects do.
        if (
            $attributes["secure"] &&
            empty(myOptions) &&
            empty($attributes["empty"]) &&
            empty($attributes["multiple"])
        ) {
            $attributes["secure"] = false;
        }

        $attributes = _initInputField(myFieldName, $attributes);
        $attributes["options"] = myOptions;

        myHidden = "";
        if ($attributes["multiple"] && $attributes["hiddenField"]) {
            myHiddenAttributes = [
                "name": $attributes["name"],
                "value": "",
                "form": $attributes["form"] ?? null,
                "secure": false,
            ];
            myHidden = this.hidden(myFieldName, myHiddenAttributes);
        }
        unset($attributes["hiddenField"], $attributes["type"]);

        return myHidden . this.widget("select", $attributes);
    }

    /**
     * Creates a set of checkboxes out of options.
     *
     * ### Options
     *
     * - `escape` - If true contents of options will be HTML entity encoded. Defaults to true.
     * - `val` The selected value of the input.
     * - `class` - When using multiple = checkbox the class name to apply to the divs. Defaults to "checkbox".
     * - `disabled` - Control the disabled attribute. When creating checkboxes, `true` will disable all checkboxes.
     *   You can also set disabled to a list of values you want to disable when creating checkboxes.
     * - `hiddenField` - Set to false to remove the hidden field that ensures a value
     *   is always submitted.
     * - `label` - Either `false` to disable label around the widget or an array of attributes for
     *   the label tag. `selected` will be added to any classes e.g. `"class": "myclass"` where
     *   widget is checked
     *
     * Can be used in place of a select box with the multiple attribute.
     *
     * @param string myFieldName Name attribute of the SELECT
     * @param iterable myOptions Array of the OPTION elements
     *   (as "value"=>"Text" pairs) to be used in the checkboxes element.
     * @param array<string, mixed> $attributes The HTML attributes of the select element.
     * @return string Formatted SELECT element
     * @see uim.cake.View\Helper\FormHelper::select() for supported option formats.
     */
    string multiCheckbox(string myFieldName, iterable myOptions, array $attributes = []) {
        $attributes += [
            "disabled": null,
            "escape": true,
            "hiddenField": true,
            "secure": true,
        ];
        $attributes = _initInputField(myFieldName, $attributes);
        $attributes["options"] = myOptions;
        $attributes["idPrefix"] = _idPrefix;

        myHidden = "";
        if ($attributes["hiddenField"]) {
            myHiddenAttributes = [
                "name": $attributes["name"],
                "value": "",
                "secure": false,
                "disabled": $attributes["disabled"] == true || $attributes["disabled"] == "disabled",
            ];
            myHidden = this.hidden(myFieldName, myHiddenAttributes);
        }
        unset($attributes["hiddenField"]);

        return myHidden . this.widget("multicheckbox", $attributes);
    }

    /**
     * Returns a SELECT element for years
     *
     * ### Attributes:
     *
     * - `empty` - If true, the empty select option is shown. If a string,
     *   that string is displayed as the empty element.
     * - `order` - Ordering of year values in select options.
     *   Possible values "asc", "desc". Default "desc"
     * - `value` The selected value of the input.
     * - `max` The max year to appear in the select element.
     * - `min` The min year to appear in the select element.
     *
     * @param string myFieldName The field name.
     * @param array<string, mixed> myOptions Options & attributes for the select elements.
     * @return string Completed year select input
     * @link https://book.UIM.org/4/en/views/helpers/form.html#creating-year-inputs
     */
    string year(string myFieldName, array myOptions = []) {
        myOptions += [
            "empty": true,
        ];
        myOptions = _initInputField(myFieldName, myOptions);
        unset(myOptions["type"]);

        return this.widget("year", myOptions);
    }

    /**
     * Generate an input tag with type "month".
     *
     * ### Options:
     *
     * See dateTime() options.
     *
     * @param string myFieldName The field name.
     * @param array<string, mixed> myOptions Array of options or HTML attributes.
     */
    string month(string myFieldName, array myOptions = []) {
        myOptions += [
            "value": null,
        ];

        myOptions = _initInputField(myFieldName, myOptions);
        myOptions["type"] = "month";

        return this.widget("datetime", myOptions);
    }

    /**
     * Generate an input tag with type "datetime-local".
     *
     * ### Options:
     *
     * - `value` | `default` The default value to be used by the input.
     *   If set to `true` current datetime will be used.
     *
     * @param string myFieldName The field name.
     * @param array<string, mixed> myOptions Array of options or HTML attributes.
     */
    string dateTime(string myFieldName, array myOptions = []) {
        myOptions += [
            "value": null,
        ];
        myOptions = _initInputField(myFieldName, myOptions);
        myOptions["type"] = "datetime-local";
        myOptions["fieldName"] = myFieldName;

        return this.widget("datetime", myOptions);
    }

    /**
     * Generate an input tag with type "time".
     *
     * ### Options:
     *
     * See dateTime() options.
     *
     * @param string myFieldName The field name.
     * @param array<string, mixed> myOptions Array of options or HTML attributes.
     */
    string time(string myFieldName, array myOptions = []) {
        myOptions += [
            "value": null,
        ];
        myOptions = _initInputField(myFieldName, myOptions);
        myOptions["type"] = "time";

        return this.widget("datetime", myOptions);
    }

    /**
     * Generate an input tag with type "date".
     *
     * ### Options:
     *
     * See dateTime() options.
     *
     * @param string myFieldName The field name.
     * @param array<string, mixed> myOptions Array of options or HTML attributes.
     */
    string date(string myFieldName, array myOptions = []) {
        myOptions += [
            "value": null,
        ];

        myOptions = _initInputField(myFieldName, myOptions);
        myOptions["type"] = "date";

        return this.widget("datetime", myOptions);
    }

    /**
     * Sets field defaults and adds field to form security input hash.
     * Will also add the error class if the field contains validation errors.
     *
     * ### Options
     *
     * - `secure` - boolean whether the field should be added to the security fields.
     *   Disabling the field using the `disabled` option, will also omit the field from being
     *   part of the hashed key.
     * - `default` - mixed - The value to use if there is no value in the form"s context.
     * - `disabled` - mixed - Either a boolean indicating disabled state, or the string in
     *   a numerically indexed value.
     * - `id` - mixed - If `true` it will be auto generated based on field name.
     *
     * This method will convert a numerically indexed "disabled" into an associative
     * array value. FormHelper"s internals expect associative options.
     *
     * The output of this bool is a more complete set of input attributes that
     * can be passed to a form widget to generate the actual input.
     *
     * @param string myField Name of the field to initialize options for.
     * @param array<string, mixed>|array<string> myOptions Array of options to append options into.
     * @return array<string, mixed> Array of options for the input.
     */
    protected array _initInputField(string myField, array myOptions = []) {
        myOptions += ["fieldName": myField];

        if (!isset(myOptions["secure"])) {
            myOptions["secure"] = _View.getRequest().getAttribute("formTokenData") is null ? false : true;
        }
        $context = _getContext();

        if (isset(myOptions["id"]) && myOptions["id"] == true) {
            myOptions["id"] = _domId(myField);
        }

        $disabledIndex = array_search("disabled", myOptions, true);
        if (is_int($disabledIndex)) {
            deprecationWarning("Using non-associative options is deprecated, use `\"disabled\": true` instead.");
            unset(myOptions[$disabledIndex]);
            myOptions["disabled"] = true;
        }

        if (!isset(myOptions["name"])) {
            $endsWithBrackets = "";
            if (substr(myField, -2) == "[]") {
                myField = substr(myField, 0, -2);
                $endsWithBrackets = "[]";
            }
            $parts = explode(".", myField);
            $first = array_shift($parts);
            myOptions["name"] = $first . (!empty($parts) ? "[" ~ implode("][", $parts) ~ "]" : "") . $endsWithBrackets;
        }

        if (isset(myOptions["value"]) && !isset(myOptions["val"])) {
            myOptions["val"] = myOptions["value"];
            unset(myOptions["value"]);
        }
        if (!isset(myOptions["val"])) {
            $valOptions = [
                "default": myOptions["default"] ?? null,
                "schemaDefault": myOptions["schemaDefault"] ?? true,
            ];
            myOptions["val"] = this.getSourceValue(myField, $valOptions);
        }
        if (!isset(myOptions["val"]) && isset(myOptions["default"])) {
            myOptions["val"] = myOptions["default"];
        }
        unset(myOptions["value"], myOptions["default"]);

        if ($context.hasError(myField)) {
            myOptions = this.addClass(myOptions, _config["errorClass"]);
        }
        $isDisabled = _isDisabled(myOptions);
        if ($isDisabled) {
            myOptions["secure"] = self::SECURE_SKIP;
        }

        return myOptions;
    }

    /**
     * Determine if a field is disabled.
     *
     * @param array<string, mixed> myOptions The option set.
     * @return bool Whether the field is disabled.
     */
    protected bool _isDisabled(array myOptions) {
        if (!isset(myOptions["disabled"])) {
            return false;
        }
        if (is_scalar(myOptions["disabled"])) {
            return myOptions["disabled"] == true || myOptions["disabled"] == "disabled";
        }
        if (!isset(myOptions["options"])) {
            return false;
        }
        if (is_array(myOptions["options"])) {
            // Simple list options
            $first = myOptions["options"][array_keys(myOptions["options"])[0]];
            if (is_scalar($first)) {
                return array_diff(myOptions["options"], myOptions["disabled"]) == [];
            }
            // Complex option types
            if (is_array($first)) {
                $disabled = array_filter(myOptions["options"], function ($i) use (myOptions) {
                    return in_array($i["value"], myOptions["disabled"], true);
                });

                return count($disabled) > 0;
            }
        }

        return false;
    }

    /**
     * Add a new context type.
     *
     * Form context types allow FormHelper to interact with
     * data providers that come from outside UIM. For example
     * if you wanted to use an alternative ORM like Doctrine you could
     * create and connect a new context class to allow FormHelper to
     * read metadata from doctrine.
     *
     * @param string myType The type of context. This key
     *   can be used to overwrite existing providers.
     * @param callable $check A callable that returns an object
     *   when the form context is the correct type.
     */
    void addContextProvider(string myType, callable $check) {
        this.contextFactory().addProvider(myType, $check);
    }

    /**
     * Get the context instance for the current form set.
     *
     * If there is no active form null will be returned.
     *
     * @param uim.cake.View\Form\IContext|null $context Either the new context when setting, or null to get.
     * @return uim.cake.View\Form\IContext The context for the form.
     */
    IContext context(?IContext $context = null) {
        if ($context instanceof IContext) {
            _context = $context;
        }

        return _getContext();
    }

    /**
     * Find the matching context provider for the data.
     *
     * If no type can be matched a NullContext will be returned.
     *
     * @param mixed myData The data to get a context provider for.
     * @return uim.cake.View\Form\IContext Context provider.
     * @throws \RuntimeException when the context class does not implement the
     *   IContext.
     */
    protected IContext _getContext(myData = []) {
        if (isset(_context) && empty(myData)) {
            return _context;
        }
        myData += ["entity": null];

        return _context = this.contextFactory()
            .get(_View.getRequest(), myData);
    }

    /**
     * Add a new widget to FormHelper.
     *
     * Allows you to add or replace widget instances with custom code.
     *
     * @param string myName The name of the widget. e.g~ "text".
     * @param uim.cake.View\Widget\IWidget|array $spec Either a string class
     *   name or an object implementing the IWidget.
     */
    void addWidget(string myName, $spec) {
        _locator.add([myName: $spec]);
    }

    /**
     * Render a named widget.
     *
     * This is a lower level method. For built-in widgets, you should be using
     * methods like `text`, `hidden`, and `radio`. If you are using additional
     * widgets you should use this method render the widget without the label
     * or wrapping div.
     *
     * @param string myName The name of the widget. e.g~ "text".
     * @param array myData The data to render.
     */
    string widget(string myName, array myData = []) {
        $secure = null;
        if (isset(myData["secure"])) {
            $secure = myData["secure"];
            unset(myData["secure"]);
        }
        $widget = _locator.get(myName);
        $out = $widget.render(myData, this.context());
        if (
            this.formProtector  !is null &&
            isset(myData["name"]) &&
            $secure  !is null &&
            $secure != self::SECURE_SKIP
        ) {
            foreach ($widget.secureFields(myData) as myField) {
                this.formProtector.addField(myField, $secure);
            }
        }

        return $out;
    }

    /**
     * Restores the default values built into FormHelper.
     *
     * This method will not reset any templates set in custom widgets.
     */
    void resetTemplates() {
        this.setTemplates(_defaultConfig["templates"]);
    }

    /**
     * Event listeners.
     *
     * @return array<string, mixed>
     */
    array implementedEvents() {
        return [];
    }

    /**
     * Gets the value sources.
     *
     * Returns a list, but at least one item, of valid sources, such as: `"context"`, `"data"` and `"query"`.
     *
     * @return List of value sources.
     */
    string[] getValueSources() {
        return _valueSources;
    }

    /**
     * Validate value sources.
     *
     * @param array<string> $sources A list of strings identifying a source.
     * @return void
     * @throws \InvalidArgumentException If sources list contains invalid value.
     */
    protected void validateValueSources(array $sources) {
        $diff = array_diff($sources, this.supportedValueSources);

        if ($diff) {
            throw new InvalidArgumentException(sprintf(
                "Invalid value source(s): %s. Valid values are: %s",
                implode(", ", $diff),
                implode(", ", this.supportedValueSources)
            ));
        }
    }

    /**
     * Sets the value sources.
     *
     * You need to supply one or more valid sources, as a list of strings.
     * Order sets priority.
     *
     * @see FormHelper::$supportedValueSources for valid values.
     * @param array<string>|string sources A string or a list of strings identifying a source.
     * @return this
     * @throws \InvalidArgumentException If sources list contains invalid value.
     */
    auto setValueSources($sources) {
        $sources = (array)$sources;

        this.validateValueSources($sources);
        _valueSources = $sources;

        return this;
    }

    /**
     * Gets a single field value from the sources available.
     *
     * @param string myFieldname The fieldname to fetch the value for.
     * @param array<string, mixed> myOptions The options containing default values.
     * @return mixed Field value derived from sources or defaults.
     */
    auto getSourceValue(string myFieldname, array myOptions = []) {
        myValueMap = [
            "data": "getData",
            "query": "getQuery",
        ];
        foreach (this.getValueSources() as myValuesSource) {
            if (myValuesSource == "context") {
                $val = _getContext().val(myFieldname, myOptions);
                if ($val  !is null) {
                    return $val;
                }
            }
            if (isset(myValueMap[myValuesSource])) {
                $method = myValueMap[myValuesSource];
                myValue = _View.getRequest().{$method}(myFieldname);
                if (myValue  !is null) {
                    return myValue;
                }
            }
        }

        return null;
    }
}
