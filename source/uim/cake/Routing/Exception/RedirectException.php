


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.2.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Routing\Exception;

import uim.cake.Core\Exception\CakeException;

/**
 * An exception subclass used by the routing layer to indicate
 * that a route has resolved to a redirect.
 *
 * The URL and status code are provided as constructor arguments.
 *
 * ```
 * throw new RedirectException("http://example.com/some/path", 301);
 * ```
 *
 * If you need a more general purpose redirect exception use
 * {@link \Cake\Http\Exception\RedirectException} instead of this class.
 *
 * @deprecated 4.1.0 Use {@link \Cake\Http\Exception\RedirectException} instead.
 */
class RedirectException : CakeException
{
    /**
     * @inheritDoc
     */
    protected $_defaultCode = 302;
}
