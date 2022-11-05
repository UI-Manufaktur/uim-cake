

/**

 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.baklava.views.exceptions;

import uim.baklava.core.Exception\CakeException;
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
    protected myfilename;

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
     * @param array<string>|string myfile Either the file name as a string, or in an array for backwards compatibility.
     * @param array<string> myPaths The path list that template could not be found in.
     * @param int|null $code The code of the error.
     * @param \Throwable|null $previous the previous exception.
     */
    this(myfile, array myPaths = [], Nullable!int $code = null, ?Throwable $previous = null) {
        if (is_array(myfile)) {
            this.filename = array_pop(myfile);
            this.templateName = array_pop(myfile);
        } else {
            this.filename = myfile;
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