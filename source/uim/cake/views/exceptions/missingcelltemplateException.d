

/**

 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cakeews\Exception;

use Throwable;

/**
 * Used when a template file for a cell cannot be found.
 */
class MissingCellTemplateException : MissingTemplateException
{
    /**
     * @var string
     */
    protected string myName;

    /**
     * @var string
     */
    protected myType = 'Cell template';

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
            'name' => this.name,
            'file' => this.file,
            'paths' => this.paths,
        ];
    }
}
