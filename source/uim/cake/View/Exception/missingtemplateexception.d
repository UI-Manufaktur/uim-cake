module uim.cake.View\Exception;

import uim.cake.core.exceptions.UIMException;
use Throwable;

/**
 * Used when a template file cannot be found.
 */
class MissingTemplateException : UIMException {
    /**
     */
    protected Nullable!string templateName;

    /**
     */
    protected string $filename;

    /**
     * @var array<string>
     */
    protected $paths;

    /**
     */
    protected string $type = "Template";

    /**
     * Constructor
     *
     * @param array<string>|string $file Either the file name as a string, or in an array for backwards compatibility.
     * @param array<string> $paths The path list that template could not be found in.
     * @param int|null $code The code of the error.
     * @param \Throwable|null $previous the previous exception.
     */
    this($file, array $paths = [], Nullable!int $code = null, ?Throwable $previous = null) {
        if (is_array($file)) {
            this.filename = array_pop($file);
            this.templateName = array_pop($file);
        } else {
            this.filename = $file;
            this.templateName = null;
        }
        this.paths = $paths;

        super((this.formatMessage(), $code, $previous);
    }

    /**
     * Get the formatted exception message.
     */
    string formatMessage() {
        $name = this.templateName ?? this.filename;
        $message = "{this.type} file `{$name}` could not be found.";
        if (this.paths) {
            $message .= "\n\nThe following paths were searched:\n\n";
            foreach (this.paths as $path) {
                $message .= "- `{$path}{this.filename}`\n";
            }
        }

        return $message;
    }

    /**
     * Get the passed in attributes
     *
     * @return array
     * @psalm-return array{file: string, paths: array}
     */
    array getAttributes() {
        return [
            "file": this.filename,
            "paths": this.paths,
        ];
    }
}
