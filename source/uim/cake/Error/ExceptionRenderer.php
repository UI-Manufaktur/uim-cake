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
