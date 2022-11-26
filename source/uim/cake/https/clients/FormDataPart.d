

/**

 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://UIM.org UIM(tm) Project
 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.https.clients;

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
     * @param string myName The name of the data.
     * @param string myValue The value of the data.
     * @param string $disposition The type of disposition to use, defaults to form-data.
     * @param string|null $charset The charset of the data.
     */
    this(string myName, string myValue, string $disposition = "form-data", Nullable!string $charset = null) {
        this._name = myName;
        this._value = myValue;
        this._disposition = $disposition;
        this._charset = $charset;
    }

    /**
     * Get/set the disposition type
     *
     * By passing in `false` you can disable the disposition
     * header from being added.
     *
     * @param string|null $disposition Use null to get/string to set.
     */
    string disposition(Nullable!string $disposition = null) {
        if ($disposition === null) {
            return this._disposition;
        }

        return this._disposition = $disposition;
    }

    /**
     * Get/set the contentId for a part.
     *
     * @param string|null $id The content id.
     * @return string|null
     */
    function contentId(Nullable!string $id = null): Nullable!string
    {
        if ($id === null) {
            return this._contentId;
        }

        return this._contentId = $id;
    }

    /**
     * Get/set the filename.
     *
     * Setting the filename to `false` will exclude it from the
     * generated output.
     *
     * @param string|null myfilename Use null to get/string to set.
     * @return string|null
     */
    string filename(Nullable!string myfilename = null) {
        if (myfilename === null) {
            return this._filename;
        }

        return this._filename = myfilename;
    }

    /**
     * Get/set the content type.
     *
     * @param string|null myType Use null to get/string to set.
     * @return string|null
     */
    string type(Nullable!string myType) {
        if (myType === null) {
            return this._type;
        }

        return this._type = myType;
    }

    /**
     * Set the transfer-encoding for multipart.
     *
     * Useful when content bodies are in encodings like base64.
     *
     * @param string|null myType The type of encoding the value has.
     * @return string|null
     */
    function transferEncoding(Nullable!string myType): Nullable!string
    {
        if (myType === null) {
            return this._transferEncoding;
        }

        return this._transferEncoding = myType;
    }

    /**
     * Get the part name.
     */
    string name() {
        return this._name;
    }

    /**
     * Get the value.
     */
    string value() {
        return this._value;
    }

    /**
     * Convert the part into a string.
     *
     * Creates a string suitable for use in HTTP requests.
     */
    string __toString() {
        $out = "";
        if (this._disposition) {
            $out .= "Content-Disposition: " . this._disposition;
            if (this._name) {
                $out .= "; " . this._headerParameterToString("name", this._name);
            }
            if (this._filename) {
                $out .= "; " . this._headerParameterToString("filename", this._filename);
            }
            $out .= "\r\n";
        }
        if (this._type) {
            $out .= "Content-Type: " . this._type . "\r\n";
        }
        if (this._transferEncoding) {
            $out .= "Content-Transfer-Encoding: " . this._transferEncoding . "\r\n";
        }
        if (this._contentId) {
            $out .= "Content-ID: <" . this._contentId . ">\r\n";
        }
        $out .= "\r\n";
        $out .= this._value;

        return $out;
    }

    /**
     * Get the string for the header parameter.
     *
     * If the value contains non-ASCII letters an additional header indicating
     * the charset encoding will be set.
     *
     * @param string myName The name of the header parameter
     * @param string myValue The value of the header parameter
     * @return string
     */
    protected string _headerParameterToString(string myName, string myValue) {
        $transliterated = Text::transliterate(str_replace(""", "", myValue));
        $return = sprintf("%s="%s"", myName, $transliterated);
        if (this._charset !== null && myValue !== $transliterated) {
            $return .= sprintf("; %s*=%s""%s", myName, strtolower(this._charset), rawurlencode(myValue));
        }

        return $return;
    }
}
