module uim.baklava.routings\Exception;

import uim.baklava.core.exceptions\CakeException;

/**
 * An exception subclass used by the routing layer to indicate
 * that a route has resolved to a redirect.
 *
 * The URL and status code are provided as constructor arguments.
 *
 * ```
 * throw new RedirectException('http://example.com/some/path', 301);
 * ```
 *
 * If you need a more general purpose redirect exception use
 * {@link \Cake\Http\Exception\RedirectException} instead of this class.
 *
 * @deprecated 4.1.0 Use {@link \Cake\Http\Exception\RedirectException} instead.
 */
class RedirectException : CakeException
{

    protected $_defaultCode = 302;
}
