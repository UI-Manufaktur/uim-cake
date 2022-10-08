

/**

 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.views\Exception;

import uim.cake.core.Exception\CakeException;
use Throwable;

/**
 * Used when a template file cannot be found.
 */
class MissingTemplateException : CakeException
{
    /**
     * @var string|null
     */
    protected myTemplateName;

    /**
     * @var string
     */
    protected $filename;

    /**
     * @var array<string>
     */
    protected myPaths;

    /**
     * @var string
     */
    protected myType = 'Template';

    /**
     * Constructor
     *
     * @param array<string>|string $file Either the file name as a string, or in an array for backwards compatibility.
     * @param array<string> myPaths The path list that template could not be found in.
     * @param int|null $code The code of the error.
     * @param \Throwable|null $previous the previous exception.
     */
    this($file, array myPaths = [], ?int $code = null, ?Throwable $previous = null) {
        if (is_array($file)) {
            this.filename = array_pop($file);
            this.templateName = array_pop($file);
        } else {
            this.filename = $file;
            this.templateName = null;
        }
        this.paths = myPaths;

        super.this(this.formatMessage(), $code, $previous);
    }

    /**
     * Get the formatted exception message.
     *
     * @return string
     */
    function formatMessage(): string
    {
        myName = this.templateName ?? this.filename;
        myMessage = "{this.type} file `{myName}` could not be found.";
        if (this.paths) {
            myMessage .= "\n\nThe following paths were searched:\n\n";
            foreach (this.paths as myPath) {
                myMessage .= "- `{myPath}{this.filename}`\n";
            }
        }

        return myMessage;
    }

    /**
     * Get the passed in attributes
     *
     * @return array
     * @psalm-return array{file: string, paths: array}
     */
    auto getAttributes(): array
    {
        return [
            'file' => this.filename,
            'paths' => this.paths,
        ];
    }
}
