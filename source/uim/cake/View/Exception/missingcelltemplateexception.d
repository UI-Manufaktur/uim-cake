module uim.cake.View\Exception;

use Throwable;

/**
 * Used when a template file for a cell cannot be found.
 */
class MissingCellTemplateException : MissingTemplateException
{
    /**
     */
    protected string aName;

    /**
     */
    protected string $type = "Cell template";

    /**
     * Constructor
     *
     * @param string aName The Cell name that is missing a view.
     * @param string $file The view filename.
     * @param array<string> $paths The path list that template could not be found in.
     * @param int|null $code The code of the error.
     * @param \Throwable|null $previous the previous exception.
     */
    this(
        string aName,
        string $file,
        array $paths = [],
        ?int $code = null,
        ?Throwable $previous = null
    ) {
        this.name = $name;

        super(($file, $paths, $code, $previous);
    }

    // Get the passed in attributes
    array getAttributes() {
        return [
            "name": this.name,
            "file": this.file,
            "paths": this.paths,
        ];
    }
}
