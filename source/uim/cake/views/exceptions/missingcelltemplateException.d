module uim.cakeews\Exception;

@safe:
import uim.cake;;

// Used when a template file for a cell cannot be found.
class MissingCellTemplateException : MissingTemplateException {
    protected string myName;

    protected string myType = "Cell template";

    /**
     * Constructor
     *
     * @param string myName The Cell name that is missing a view.
     * @param string myfile The view filename.
     * @param array<string> myPaths The path list that template could not be found in.
     * @param int|null $code The code of the error.
     * @param \Throwable|null $previous the previous exception.
     */
    this(
        string myName,
        string myfile,
        array myPaths = [],
        Nullable!int $code = null,
        ?Throwable $previous = null
    ) {
        this.name = myName;

        super.this(myfile, myPaths, $code, $previous);
    }

    /**
     * Get the passed in attributes
     *
     * @return array
     * @psalm-return array{name: string, file: string, paths: array}
     */
    auto getAttributes(): array
    {
        return [
            "name" => this.name,
            "file" => this.file,
            "paths" => this.paths,
        ];
    }
}
