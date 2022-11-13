

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         0.10.4
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.controllerss.components;

import uim.cake.controllerss.components;
import uim.cake.controllerss.componentsRegistry;
import uim.cake.controllers\Controller;
import uim.cake.core.App;
import uim.cake.core.Configure;
import uim.cakeents\IEvent;
import uim.caketps\Exception\NotFoundException;
import uim.caketps\Response;
import uim.caketps\ServerRequest;
import uim.cakeutings\Router;
import uim.cakeilities.Inflector;

/**
 * Request object handling for alternative HTTP requests.
 *
 * This Component checks for requests for different content types like JSON, XML,
 * XMLHttpRequest(AJAX) and configures the response object and view builder accordingly.
 *
 * It can also check for HTTP caching headers like `Last-Modified`, `If-Modified-Since`
 * etc. and return a response accordingly.
 *
 * @link https://book.cakephp.org/4/en/controllers/components/request-handling.html
 */
class RequestHandlerComponent : Component
{
    /**
     * Contains the file extension parsed out by the Router
     *
     * @var string|null
     * @see \Cake\Routing\Router::extensions()
     */
    protected $ext;

    /**
     * The template type to use when rendering the given content type.
     *
     * @var string|null
     */
    protected $_renderType;

    /**
     * Default config
     *
     * These are merged with user-provided config when the component is used.
     *
     * - `checkHttpCache` - Whether to check for HTTP cache. Default `true`.
     * - `viewClassMap` - Mapping between type and view classes. If undefined
     *   JSON, XML, and AJAX will be mapped. Defining any types will omit the defaults.
     *
     * @var array<string, mixed>
     */
    protected $_defaultConfig = [
        "checkHttpCache" => true,
        "viewClassMap" => [],
    ];

    /**
     * Constructor. Parses the accepted content types accepted by the client using HTTP_ACCEPT
     *
     * @param \Cake\Controller\ComponentRegistry $registry ComponentRegistry object.
     * @param array<string, mixed> myConfig Array of config.
     */
    this(ComponentRegistry $registry, array myConfig = []) {
        myConfig += [
            "viewClassMap" => [
                "json" => "Json",
                "xml" => "Xml",
                "ajax" => "Ajax",
            ],
        ];
        super.this($registry, myConfig);
    }

    /**
     * Events supported by this component.
     *
     * @return array<string, mixed>
     */
    function implementedEvents(): array
    {
        return [
            "Controller.startup" => "startup",
            "Controller.beforeRender" => "beforeRender",
        ];
    }

    /**
     * Set the extension based on the `Accept` header or URL extension.
     *
     * Compares the accepted types and configured extensions.
     * If there is one common type, that is assigned as the ext/content type for the response.
     * The type with the highest weight will be set. If the highest weight has more
     * than one type matching the extensions, the order in which extensions are specified
     * determines which type will be set.
     *
     * If html is one of the preferred types, no content type will be set, this
     * is to avoid issues with browsers that prefer HTML and several other content types.
     *
     * @param \Cake\Http\ServerRequest myRequest The request instance.
     * @param \Cake\Http\Response $response The response instance.
     * @return void
     */
    protected void _setExtension(ServerRequest myRequest, Response $response)
    {
        $accept = myRequest.parseAccept();
        if (empty($accept) || current($accept)[0] === "text/html") {
            return;
        }

        /** @var array $accepts */
        $accepts = $response.mapType($accept);
        $preferredTypes = current($accepts);
        if (array_intersect($preferredTypes, ["html", "xhtml"])) {
            return;
        }

        $extensions = array_unique(
            array_merge(Router::extensions(), array_keys(this.getConfig("viewClassMap")))
        );
        foreach ($accepts as myTypes) {
            $ext = array_intersect($extensions, myTypes);
            if ($ext) {
                this.ext = current($ext);
                break;
            }
        }
    }

    /**
     * The startup method of the RequestHandler enables several automatic behaviors
     * related to the detection of certain properties of the HTTP request, including:
     *
     * If the XML data is POSTed, the data is parsed into an XML object, which is assigned
     * to the myData property of the controller, which can then be saved to a model object.
     *
     * @param \Cake\Event\IEvent myEvent The startup event that was fired.
     * @return void
     */
    void startup(IEvent myEvent)
    {
        $controller = this.getController();
        myRequest = $controller.getRequest();
        $response = $controller.getResponse();

        this.ext = myRequest.getParam("_ext");
        if (!this.ext || in_array(this.ext, ["html", "htm"], true)) {
            this._setExtension(myRequest, $response);
        }

        $isAjax = myRequest.is("ajax");
        $controller.setRequest(myRequest.withAttribute("isAjax", $isAjax));

        if (!this.ext && $isAjax) {
            this.ext = "ajax";
        }
    }

    /**
     * Checks if the response can be considered different according to the request
     * headers, and the caching response headers. If it was not modified, then the
     * render process is skipped. And the client will get a blank response with a
     * "304 Not Modified" header.
     *
     * - If Router::extensions() is enabled, the layout and template type are
     *   switched based on the parsed extension or `Accept` header. For example,
     *   if `controller/action.xml` is requested, the view path becomes
     *   `templates/Controller/xml/action.php`. Also, if `controller/action` is
     *   requested with `Accept: application/xml` in the headers the view
     *   path will become `templates/Controller/xml/action.php`. Layout and template
     *   types will only switch to mime-types recognized by \Cake\Http\Response.
     *   If you need to declare additional mime-types, you can do so using
     *   {@link \Cake\Http\Response::setTypeMap()} in your controller"s beforeFilter() method.
     * - If a helper with the same name as the extension exists, it is added to
     *   the controller.
     * - If the extension is of a type that RequestHandler understands, it will
     *   set that Content-type in the response header.
     *
     * @param \Cake\Event\IEvent myEvent The Controller.beforeRender event.
     * @return void
     * @throws \Cake\Http\Exception\NotFoundException If invoked extension is not configured.
     */
    void beforeRender(IEvent myEvent)
    {
        $controller = this.getController();
        $response = $controller.getResponse();

        if (this.ext && !in_array(this.ext, ["html", "htm"], true)) {
            if (!$response.getMimeType(this.ext)) {
                throw new NotFoundException("Invoked extension not recognized/configured: " . this.ext);
            }

            this.renderAs($controller, this.ext);
            $response = $controller.getResponse();
        } else {
            $response = $response.withCharset(Configure::read("App.encoding"));
        }

        if (
            this._config["checkHttpCache"] &&
            $response.checkNotModified($controller.getRequest())
        ) {
            $controller.setResponse($response);
            myEvent.stopPropagation();

            return;
        }

        $controller.setResponse($response);
    }

    /**
     * Determines which content types the client accepts. Acceptance is based on
     * the file extension parsed by the Router (if present), and by the HTTP_ACCEPT
     * header. Unlike {@link \Cake\Http\ServerRequest::accepts()} this method deals entirely with mapped content types.
     *
     * Usage:
     *
     * ```
     * this.RequestHandler.accepts(["xml", "html", "json"]);
     * ```
     *
     * Returns true if the client accepts any of the supplied types.
     *
     * ```
     * this.RequestHandler.accepts("xml");
     * ```
     *
     * Returns true if the client accepts XML.
     *
     * @param array<string>|string|null myType Can be null (or no parameter), a string type name, or an
     *   array of types
     * @return array|bool|string|null If null or no parameter is passed, returns an array of content
     *   types the client accepts. If a string is passed, returns true
     *   if the client accepts it. If an array is passed, returns true
     *   if the client accepts one or more elements in the array.
     */
    function accepts(myType = null) {
        $controller = this.getController();
        /** @var array $accepted */
        $accepted = $controller.getRequest().accepts();

        if (!myType) {
            return $controller.getResponse().mapType($accepted);
        }

        if (is_array(myType)) {
            foreach (myType as $t) {
                $t = this.mapAlias($t);
                if (in_array($t, $accepted, true)) {
                    return true;
                }
            }

            return false;
        }

        if (is_string(myType)) {
            return in_array(this.mapAlias(myType), $accepted, true);
        }

        return false;
    }

    /**
     * Determines the content type of the data the client has sent (i.e. in a POST request)
     *
     * @param array<string>|string|null myType Can be null (or no parameter), a string type name, or an array of types
     * @return mixed If a single type is supplied a boolean will be returned. If no type is provided
     *   The mapped value of CONTENT_TYPE will be returned. If an array is supplied the first type
     *   in the request content type will be returned.
     */
    function requestedWith(myType = null) {
        $controller = this.getController();
        myRequest = $controller.getRequest();

        if (
            !myRequest.is("post") &&
            !myRequest.is("put") &&
            !myRequest.is("patch") &&
            !myRequest.is("delete")
        ) {
            return null;
        }
        if (is_array(myType)) {
            foreach (myType as $t) {
                if (this.requestedWith($t)) {
                    return $t;
                }
            }

            return false;
        }

        [myContentsType] = explode(";", myRequest.contentType() ?? "");
        if (myType === null) {
            return $controller.getResponse().mapType(myContentsType);
        }

        if (!is_string(myType)) {
            return null;
        }

        return myType === $controller.getResponse().mapType(myContentsType);
    }

    /**
     * Determines which content-types the client prefers. If no parameters are given,
     * the single content-type that the client most likely prefers is returned. If myType is
     * an array, the first item in the array that the client accepts is returned.
     * Preference is determined primarily by the file extension parsed by the Router
     * if provided, and secondarily by the list of content-types provided in
     * HTTP_ACCEPT.
     *
     * @param array<string>|string|null myType An optional array of "friendly" content-type names, i.e.
     *   "html", "xml", "js", etc.
     * @return string|bool|null If myType is null or not provided, the first content-type in the
     *    list, based on preference, is returned. If a single type is provided
     *    a boolean will be returned if that type is preferred.
     *    If an array of types are provided then the first preferred type is returned.
     *    If no type is provided the first preferred type is returned.
     */
    function prefers(myType = null) {
        $controller = this.getController();

        $acceptRaw = $controller.getRequest().parseAccept();
        if (empty($acceptRaw)) {
            return myType ? myType === this.ext : this.ext;
        }

        /** @var array $accepts */
        $accepts = $controller.getResponse().mapType(array_shift($acceptRaw));
        if (!myType) {
            if (empty(this.ext) && !empty($accepts)) {
                return $accepts[0];
            }

            return this.ext;
        }

        myTypes = (array)myType;
        if (count(myTypes) === 1) {
            if (this.ext) {
                return in_array(this.ext, myTypes, true);
            }

            return in_array(myTypes[0], $accepts, true);
        }

        $intersect = array_values(array_intersect($accepts, myTypes));
        if (!$intersect) {
            return false;
        }

        return $intersect[0];
    }

    /**
     * Sets either the view class if one exists or the layout and template path of the view.
     * The names of these are derived from the myType input parameter.
     *
     * ### Usage:
     *
     * Render the response as an "ajax" response.
     *
     * ```
     * this.RequestHandler.renderAs(this, "ajax");
     * ```
     *
     * Render the response as an XML file and force the result as a file download.
     *
     * ```
     * this.RequestHandler.renderAs(this, "xml", ["attachment" => "myfile.xml"];
     * ```
     *
     * @param \Cake\Controller\Controller $controller A reference to a controller object
     * @param string myType Type of response to send (e.g: "ajax")
     * @param array<string, mixed> myOptions Array of options to use
     * @return void
     * @see \Cake\Controller\Component\RequestHandlerComponent::respondAs()
     */
    void renderAs(Controller $controller, string myType, array myOptions = [])
    {
        $defaults = ["charset" => "UTF-8"];
        $viewClassMap = this.getConfig("viewClassMap");

        if (Configure::read("App.encoding") !== null) {
            $defaults["charset"] = Configure::read("App.encoding");
        }
        myOptions += $defaults;

        myBuilder = $controller.viewBuilder();
        if (array_key_exists(myType, $viewClassMap)) {
            $view = $viewClassMap[myType];
        } else {
            $view = Inflector::classify(myType);
        }

        $viewClass = null;
        if (myBuilder.getClassName() === null) {
            $viewClass = App::className($view, "View", "View");
        }

        if ($viewClass) {
            myBuilder.setClassName($viewClass);
        } else {
            if (!this._renderType) {
                myBuilder.setTemplatePath((string)myBuilder.getTemplatePath() . DIRECTORY_SEPARATOR . myType);
            } else {
                myBuilder.setTemplatePath(preg_replace(
                    "/([\/\\\\]{this._renderType})$/",
                    DIRECTORY_SEPARATOR . myType,
                    (string)myBuilder.getTemplatePath()
                ));
            }

            this._renderType = myType;
            myBuilder.setLayoutPath(myType);
        }

        if ($controller.getResponse().getMimeType(myType)) {
            this.respondAs(myType, myOptions);
        }
    }

    /**
     * Sets the response header based on type map index name. This wraps several methods
     * available on {@link \Cake\Http\Response}. It also allows you to use Content-Type aliases.
     *
     * @param string myType Friendly type name, i.e. "html" or "xml", or a full content-type,
     *    like "application/x-shockwave".
     * @param array<string, mixed> myOptions If myType is a friendly type name that is associated with
     *    more than one type of content, $index is used to select which content-type to use.
     * @return bool Returns false if the friendly type name given in myType does
     *    not exist in the type map, or if the Content-type header has
     *    already been set by this method.
     */
    bool respondAs(myType, array myOptions = []) {
        $defaults = ["index" => null, "charset" => null, "attachment" => false];
        myOptions += $defaults;

        $cType = myType;
        $controller = this.getController();
        $response = $controller.getResponse();

        if (strpos(myType, "/") === false) {
            $cType = $response.getMimeType(myType);
        }
        if (is_array($cType)) {
            $cType = $cType[myOptions["index"]] ?? $cType;

            if (this.prefers($cType)) {
                $cType = this.prefers($cType);
            } else {
                $cType = $cType[0];
            }
        }

        if (!$cType) {
            return false;
        }

        /** @psalm-suppress PossiblyInvalidArgument */
        $response = $response.withType($cType);

        if (!empty(myOptions["charset"])) {
            $response = $response.withCharset(myOptions["charset"]);
        }
        if (!empty(myOptions["attachment"])) {
            $response = $response.withDownload(myOptions["attachment"]);
        }
        $controller.setResponse($response);

        return true;
    }

    /**
     * Maps a content type alias back to its mime-type(s)
     *
     * @param array|string myAlias String alias to convert back into a content type. Or an array of aliases to map.
     * @return array|string|null Null on an undefined alias. String value of the mapped alias type. If an
     *   alias maps to more than one content type, the first one will be returned. If an array is provided
     *   for myAlias, an array of mapped types will be returned.
     */
    function mapAlias(myAlias) {
        if (is_array(myAlias)) {
            return array_map([this, "mapAlias"], myAlias);
        }

        myType = this.getController().getResponse().getMimeType(myAlias);
        if (myType) {
            if (is_array(myType)) {
                return myType[0];
            }

            return myType;
        }

        return null;
    }
}
