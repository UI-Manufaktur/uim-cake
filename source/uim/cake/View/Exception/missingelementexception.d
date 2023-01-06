module uim.cake.View\Exception;

/**
 * Used when an element file cannot be found.
 */
class MissingElementException : MissingTemplateException {
    /**
     */
    protected string $type = "Element";
}
