module uim.cake.views\Exception;

/**
 * Used when an element file cannot be found.
 */
class MissingElementException : MissingTemplateException {
    /**
     */
    protected string $type = "Element";
}
