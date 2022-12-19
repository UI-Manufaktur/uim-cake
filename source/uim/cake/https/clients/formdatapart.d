/*********************************************************************************************************
*	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        *
*	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  *
*	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      *
**********************************************************************************************************/
module uim.cake.https.clients.formdatapart;

@safe:
import uim.cake;

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
     */
    protected string $_name;

    /**
     * Value to send.
     */
    protected string $_value;

    /**
     * Content type to use
     *
     * @var string|null
     */
    protected $_type;

    /**
     * Disposition to send
     */
    protected string $_disposition;

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
        _name = myName;
        _value = myValue;
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
     */
    string disposition(Nullable!string $disposition = null) {
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
    Nullable!string contentId(Nullable!string $id = null) {
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
     * @param string|null myfilename Use null to get/string to set.
     * @return string|null
     */
    string filename(Nullable!string myfilename = null) {
        if (myfilename == null) {
            return _filename;
        }

        return _filename = myfilename;
    }

    /**
     * Get/set the content type.
     *
     * @param string|null myType Use null to get/string to set.
     * @return string|null
     */
    string type(Nullable!string myType) {
        if (myType == null) {
            return _type;
        }

        return _type = myType;
    }

    /**
     * Set the transfer-encoding for multipart.
     *
     * Useful when content bodies are in encodings like base64.
     *
     * @param string|null myType The type of encoding the value has.
     * @return string|null
     */
    Nullable!string transferEncoding(Nullable!string myType) {
        if (myType == null) {
            return _transferEncoding;
        }

        return _transferEncoding = myType;
    }

    // Get the part name.
    string name() {
        return _name;
    }

    // Get the value.
    string value() {
        return _value;
    }

    /**
     * Convert the part into a string.
     *
     * Creates a string suitable for use in HTTP requests.
     */
    string __toString() {
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
     * @param string myName The name of the header parameter
     * @param string myValue The value of the header parameter
     * @return string
     */
    protected string _headerParameterToString(string myName, string myValue) {
        $transliterated = Text::transliterate(str_replace(""", "", myValue));
        $return = sprintf("%s="%s"", myName, $transliterated);
        if (_charset !== null && myValue !== $transliterated) {
            $return .= sprintf("; %s*=%s""%s", myName, strtolower(_charset), rawurlencode(myValue));
        }

        return $return;
    }
}
