


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)

 * @since         2.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Error;

import uim.cake.errors.Renderer\WebExceptionRenderer;

/**
 * Backwards compatible Exception Renderer.
 *
 * @deprecated 4.4.0 Use `Cake\Error\Renderer\WebExceptionRenderer` instead.
 */
class ExceptionRenderer : WebExceptionRenderer
{
}
