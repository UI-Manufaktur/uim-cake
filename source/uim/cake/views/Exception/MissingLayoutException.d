module uim.cake.views\Exception;

/**
 * Used when a layout file cannot be found.
 */
class MissingLayoutException : MissingTemplateException {
    protected string myType = 'Layout';
}
