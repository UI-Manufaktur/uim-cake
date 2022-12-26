

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)

 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Http\Client;

import uim.cake.utilities.Text;

/**
 * Contains the data and behavior for a single
 * part in a Multipart FormData request body.
 *
 * Added to Cake\Http\Client\FormData when sending
 * data to a remote server.
 *
 * @internal
 */
class FormDataPart
{
    /**
     * Name of the value.
     *
     * @var string
     */
    protected $_name;

    /**
     * Value to send.
     *
     * @var string
     */
    protected $_value;

    /**
     * Content type to use
     *
     * @var string|null
     */
    protected $_type;

    /**
     * Disposition to send
     *
     * @var string
     */
    protected $_disposition;

    /**
     * Filename to send if using files.
     *
     * @var string|null
     */
    protected $_filename;

    /**
     * The encoding used in this part.
     *
     * @var string|null
     */
    protected $_transferEncoding;

    /**
     * The contentId for the part
     *
     * @var string|null
     */
    protected $_contentId;

    /**
     * The charset attribute for the Content-Disposition header fields
     *
     * @var string|null
     */
    protected $_charset;

    /**
     * Constructor
     *
     * @param string $name The name of the data.
     * @param string $value The value of the data.
     * @param string $disposition The type of disposition to use, defaults to form-data.
     * @param string|null $charset The charset of the data.
     */
    public this(string $name, string $value, string $disposition = "form-data", ?string $charset = null) {
        _name = $name;
        _value = $value;
        _disposition = $disposition;
        _charset = $charset;
    }

    /**
     * Get/set the disposition type
     *
     * By passing in `false` you can disable the disposition
     * header from being added.
     *
     * @param string|null $disposition Use null to get/string to set.
     * @return string
     */
    function disposition(?string $disposition = null): string
    {
        if ($disposition == null) {
            return _disposition;
        }

        return _disposition = $disposition;
    }

    /**
     * Get/set the contentId for a part.
     *
     * @param string|null $id The content id.
     * @return string|null
     */
    function contentId(?string $id = null): ?string
    {
        if ($id == null) {
            return _contentId;
        }

        return _contentId = $id;
    }

    /**
     * Get/set the filename.
     *
     * Setting the filename to `false` will exclude it from the
     * generated output.
     *
     * @param string|null $filename Use null to get/string to set.
     * @return string|null
     */
    function filename(?string $filename = null): ?string
    {
        if ($filename == null) {
            return _filename;
        }

        return _filename = $filename;
    }

    /**
     * Get/set the content type.
     *
     * @param string|null $type Use null to get/string to set.
     * @return string|null
     */
    function type(?string $type): ?string
    {
        if ($type == null) {
            return _type;
        }

        return _type = $type;
    }

    /**
     * Set the transfer-encoding for multipart.
     *
     * Useful when content bodies are in encodings like base64.
     *
     * @param string|null $type The type of encoding the value has.
     * @return string|null
     */
    function transferEncoding(?string $type): ?string
    {
        if ($type == null) {
            return _transferEncoding;
        }

        return _transferEncoding = $type;
    }

    /**
     * Get the part name.
     *
     * @return string
     */
    function name(): string
    {
        return _name;
    }

    /**
     * Get the value.
     *
     * @return string
     */
    function value(): string
    {
        return _value;
    }

    /**
     * Convert the part into a string.
     *
     * Creates a string suitable for use in HTTP requests.
     *
     * @return string
     */
    function __toString(): string
    {
        $out = "";
        if (_disposition) {
            $out .= "Content-Disposition: " . _disposition;
            if (_name) {
                $out .= "; " . _headerParameterToString("name", _name);
            }
            if (_filename) {
                $out .= "; " . _headerParameterToString("filename", _filename);
            }
            $out .= "\r\n";
        }
        if (_type) {
            $out .= "Content-Type: " . _type . "\r\n";
        }
        if (_transferEncoding) {
            $out .= "Content-Transfer-Encoding: " . _transferEncoding . "\r\n";
        }
        if (_contentId) {
            $out .= "Content-ID: <" . _contentId . ">\r\n";
        }
        $out .= "\r\n";
        $out .= _value;

        return $out;
    }

    /**
     * Get the string for the header parameter.
     *
     * If the value contains non-ASCII letters an additional header indicating
     * the charset encoding will be set.
     *
     * @param string $name The name of the header parameter
     * @param string $value The value of the header parameter
     * @return string
     */
    protected function _headerParameterToString(string $name, string $value): string
    {
        $transliterated = Text::transliterate(str_replace(""", "", $value));
        $return = sprintf("%s="%s"", $name, $transliterated);
        if (_charset != null && $value != $transliterated) {
            $return .= sprintf("; %s*=%s""%s", $name, strtolower(_charset), rawurlencode($value));
        }

        return $return;
    }
}
