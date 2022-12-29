

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *



  */
module uim.cake.http.Client;

use Countable;
use finfo;
use Psr\Http\Message\UploadedFileInterface;

/**
 * Provides an interface for building
 * multipart/form-encoded message bodies.
 *
 * Used by Http\Client to upload POST/PUT data
 * and files.
 */
class FormData : Countable
{
    /**
     * Boundary marker.
     *
     * @var string
     */
    protected $_boundary;

    /**
     * Whether this formdata object has attached files.
     *
     * @var bool
     */
    protected $_hasFile = false;

    /**
     * Whether this formdata object has a complex part.
     *
     * @var bool
     */
    protected $_hasComplexPart = false;

    /**
     * The parts in the form data.
     *
     * @var array<\Cake\Http\Client\FormDataPart>
     */
    protected $_parts = [];

    /**
     * Get the boundary marker
     *
     * @return string
     */
    function boundary(): string
    {
        if (_boundary) {
            return _boundary;
        }
        _boundary = md5(uniqid((string)time()));

        return _boundary;
    }

    /**
     * Method for creating new instances of Part
     *
     * @param string $name The name of the part.
     * @param string $value The value to add.
     * @return uim.cake.http.Client\FormDataPart
     */
    function newPart(string $name, string $value): FormDataPart
    {
        return new FormDataPart($name, $value);
    }

    /**
     * Add a new part to the data.
     *
     * The value for a part can be a string, array, int,
     * float, filehandle, or object implementing __toString()
     *
     * If the $value is an array, multiple parts will be added.
     * Files will be read from their current position and saved in memory.
     *
     * @param uim.cake.http.Client\FormDataPart|string $name The name of the part to add,
     *   or the part data object.
     * @param mixed $value The value for the part.
     * @return this
     */
    function add($name, $value = null) {
        if (is_string($name)) {
            if (is_array($value)) {
                this.addRecursive($name, $value);
            } elseif (is_resource($value) || $value instanceof UploadedFileInterface) {
                this.addFile($name, $value);
            } else {
                _parts[] = this.newPart($name, (string)$value);
            }
        } else {
            _hasComplexPart = true;
            _parts[] = $name;
        }

        return this;
    }

    /**
     * Add multiple parts at once.
     *
     * Iterates the parameter and adds all the key/values.
     *
     * @param array $data Array of data to add.
     * @return this
     */
    function addMany(array $data) {
        foreach ($data as $name: $value) {
            this.add($name, $value);
        }

        return this;
    }

    /**
     * Add either a file reference (string starting with @)
     * or a file handle.
     *
     * @param string $name The name to use.
     * @param string|resource|\Psr\Http\Message\UploadedFileInterface $value Either a string filename, or a filehandle,
     *  or a UploadedFileInterface instance.
     * @return uim.cake.http.Client\FormDataPart
     */
    function addFile(string $name, $value): FormDataPart
    {
        _hasFile = true;

        $filename = false;
        $contentType = "application/octet-stream";
        if ($value instanceof UploadedFileInterface) {
            $content = (string)$value.getStream();
            $contentType = $value.getClientMediaType();
            $filename = $value.getClientFilename();
        } elseif (is_resource($value)) {
            $content = stream_get_contents($value);
            if (stream_is_local($value)) {
                $finfo = new finfo(FILEINFO_MIME);
                $metadata = stream_get_meta_data($value);
                $contentType = $finfo.file($metadata["uri"]);
                $filename = basename($metadata["uri"]);
            }
        } else {
            $finfo = new finfo(FILEINFO_MIME);
            $value = substr($value, 1);
            $filename = basename($value);
            $content = file_get_contents($value);
            $contentType = $finfo.file($value);
        }
        $part = this.newPart($name, $content);
        $part.type($contentType);
        if ($filename) {
            $part.filename($filename);
        }
        this.add($part);

        return $part;
    }

    /**
     * Recursively add data.
     *
     * @param string $name The name to use.
     * @param mixed $value The value to add.
     * @return void
     */
    function addRecursive(string $name, $value): void
    {
        foreach ($value as $key: $value) {
            $key = $name . "[" . $key . "]";
            this.add($key, $value);
        }
    }

    /**
     * Returns the count of parts inside this object.
     *
     * @return int
     */
    function count(): int
    {
        return count(_parts);
    }

    /**
     * Check whether the current payload
     * has any files.
     *
     * @return bool Whether there is a file in this payload.
     */
    function hasFile(): bool
    {
        return _hasFile;
    }

    /**
     * Check whether the current payload
     * is multipart.
     *
     * A payload will become multipart when you add files
     * or use add() with a Part instance.
     *
     * @return bool Whether the payload is multipart.
     */
    function isMultipart(): bool
    {
        return this.hasFile() || _hasComplexPart;
    }

    /**
     * Get the content type for this payload.
     *
     * If this object contains files, `multipart/form-data` will be used,
     * otherwise `application/x-www-form-urlencoded` will be used.
     *
     * @return string
     */
    function contentType(): string
    {
        if (!this.isMultipart()) {
            return "application/x-www-form-urlencoded";
        }

        return "multipart/form-data; boundary=" . this.boundary();
    }

    /**
     * Converts the FormData and its parts into a string suitable
     * for use in an HTTP request.
     *
     * @return string
     */
    function __toString(): string
    {
        if (this.isMultipart()) {
            $boundary = this.boundary();
            $out = "";
            foreach (_parts as $part) {
                $out .= "--$boundary\r\n";
                $out .= (string)$part;
                $out .= "\r\n";
            }
            $out .= "--$boundary--\r\n";

            return $out;
        }
        $data = [];
        foreach (_parts as $part) {
            $data[$part.name()] = $part.value();
        }

        return http_build_query($data);
    }
}
