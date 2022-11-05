module uim.cake.views.exceptions;

/**
 * Used when a layout file cannot be found.
 */
class MissingLayoutException : MissingTemplateException {
    protected string myType = 'Layout';
}
