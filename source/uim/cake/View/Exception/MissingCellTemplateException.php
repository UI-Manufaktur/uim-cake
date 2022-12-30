

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *


  */
module uim.cake.View\Exception;

use Throwable;

/**
 * Used when a template file for a cell cannot be found.
 */
class MissingCellTemplateException : MissingTemplateException
{
    /**
     */
    protected string $name;

    /**
     */
    protected string $type = "Cell template";

    /**
     * Constructor
     *
     * @param string $name The Cell name that is missing a view.
     * @param string $file The view filename.
     * @param array<string> $paths The path list that template could not be found in.
     * @param int|null $code The code of the error.
     * @param \Throwable|null $previous the previous exception.
     */
    this(
        string $name,
        string $file,
        array $paths = [],
        ?int $code = null,
        ?Throwable $previous = null
    ) {
        this.name = $name;

        super(($file, $paths, $code, $previous);
    }

    /**
     * Get the passed in attributes
     *
     * @return array
     * @psalm-return array{name: string, file: string, paths: array}
     */
    function getAttributes(): array
    {
        return [
            "name": this.name,
            "file": this.file,
            "paths": this.paths,
        ];
    }
}
