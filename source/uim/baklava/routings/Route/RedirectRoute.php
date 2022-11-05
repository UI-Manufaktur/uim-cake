module uim.baklava.Routing\Route;

import uim.baklava.https\Exception\RedirectException;
import uim.baklava.Routing\Router;

/**
 * Redirect route will perform an immediate redirect. Redirect routes
 * are useful when you want to have Routing layer redirects occur in your
 * application, for when URLs move.
 *
 * Redirection is signalled by an exception that halts route matching and
 * defines the redirect URL and status code.
 */
class RedirectRoute : Route
{
    /**
     * The location to redirect to.
     *
     * @var array
     */
    public $redirect;

    /**
     * Constructor
     *
     * @param string myTemplate Template string with parameter placeholders
     * @param array $defaults Defaults for the route. Either a redirect=>value array or a CakePHP array URL.
     * @param array<string, mixed> myOptions Array of additional options for the Route
     */
    this(string myTemplate, array $defaults = [], array myOptions = []) {
        super.this(myTemplate, $defaults, myOptions);
        if (isset($defaults['redirect'])) {
            $defaults = (array)$defaults['redirect'];
        }
        this.redirect = $defaults;
    }

    /**
     * Parses a string URL into an array. Parsed URLs will result in an automatic
     * redirection.
     *
     * @param string myUrl The URL to parse.
     * @param string $method The HTTP method being used.
     * @return array|null Null on failure. An exception is raised on a successful match. Array return type is unused.
     * @throws \Cake\Http\Exception\RedirectException An exception is raised on successful match.
     *   This is used to halt route matching and signal to the middleware that a redirect should happen.
     */
    function parse(string myUrl, string $method = ''): ?array
    {
        myParams = super.parse(myUrl, $method);
        if (!myParams) {
            return null;
        }
        $redirect = this.redirect;
        if (this.redirect && count(this.redirect) === 1 && !isset(this.redirect['controller'])) {
            $redirect = this.redirect[0];
        }
        if (isset(this.options['persist']) && is_array($redirect)) {
            $redirect += ['pass' => myParams['pass'], 'url' => []];
            if (is_array(this.options['persist'])) {
                foreach (this.options['persist'] as $elem) {
                    if (isset(myParams[$elem])) {
                        $redirect[$elem] = myParams[$elem];
                    }
                }
            }
            $redirect = Router::reverseToArray($redirect);
        }
        $status = 301;
        if (isset(this.options['status']) && (this.options['status'] >= 300 && this.options['status'] < 400)) {
            $status = this.options['status'];
        }
        throw new RedirectException(Router::url($redirect, true), $status);
    }

    /**
     * There is no reverse routing redirection routes.
     *
     * @param array myUrl Array of parameters to convert to a string.
     * @param array $context Array of request context parameters.
     * @return string|null Always null, string return result unused.
     */
    function match(array myUrl, array $context = []): Nullable!string
    {
        return null;
    }

    /**
     * Sets the HTTP status
     *
     * @param int $status The status code for this route
     * @return this
     */
    auto setStatus(int $status) {
        this.options['status'] = $status;

        return this;
    }
}
