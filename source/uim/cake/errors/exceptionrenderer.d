module uim.cake.Error;

import uim.cake.errors.rendererss.WebExceptionRenderer;

/**
 * Backwards compatible Exception Renderer.
 *
 * @deprecated 4.4.0 Use `Cake\errors.renderers.WebExceptionRenderer` instead.
 */
class ExceptionRenderer : WebExceptionRenderer
{
}
