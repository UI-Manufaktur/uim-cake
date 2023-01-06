module uim.cake.View\Exception;

/**
 * Used when a layout file cannot be found.
 */
class MissingLayoutException : MissingTemplateException {
    /**
     */
    protected string $type = "Layout";
}
