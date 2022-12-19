module uim.cake.utilities;

@safe:
import uim.cake;

/**
 * XML handling for UIM.
 *
 * The methods in these classes enable the datasources that use XML to work.
 */
class Xml {
    /**
     * Initialize SimpleXMLElement or DOMDocument from a given XML string, file path, URL or array.
     *
     * ### Usage:
     *
     * Building XML from a string:
     *
     * ```
     * $xml = Xml::build("<example>text</example>");
     * ```
     *
     * Building XML from string (output DOMDocument):
     *
     * ```
     * $xml = Xml::build("<example>text</example>", ["return" => "domdocument"]);
     * ```
     *
     * Building XML from a file path:
     *
     * ```
     * $xml = Xml::build("/path/to/an/xml/file.xml");
     * ```
     *
     * Building XML from a remote URL:
     *
     * ```
     * import uim.caketps\Client;
     *
     * $http = new Client();
     * $response = $http.get("http://example.com/example.xml");
     * $xml = Xml::build($response.body());
     * ```
     *
     * Building from an array:
     *
     * ```
     *  myValue = [
     *      "tags" => [
     *          "tag" => [
     *              [
     *                  "id" => "1",
     *                  "name" => "defect"
     *              ],
     *              [
     *                  "id" => "2",
     *                  "name" => "enhancement"
     *              ]
     *          ]
     *      ]
     *  ];
     * $xml = Xml::build(myValue);
     * ```
     *
     * When building XML from an array ensure that there is only one top level element.
     *
     * ### Options
     *
     * - `return` Can be "simplexml" to return object of SimpleXMLElement or "domdocument" to return DOMDocument.
     * - `loadEntities` Defaults to false. Set to true to enable loading of `<!ENTITY` definitions. This
     *   is disabled by default for security reasons.
     * - `readFile` Set to true to enable file reading. This is disabled by default to prevent
     *   local filesystem access. Only enable this setting when the input is safe.
     * - `parseHuge` Enable the `LIBXML_PARSEHUGE` flag.
     *
     * If using array as input, you can pass `options` from Xml::fromArray.
     *
     * @param object|array|string $input XML string, a path to a file, a URL or an array
     * @param array<string, mixed> myOptions The options to use
     * @return \SimpleXMLElement|\DOMDocument SimpleXMLElement or DOMDocument
     * @throws \Cake\Utility\Exception\XmlException
     */
    static function build($input, array myOptions = []) {
        $defaults = [
            "return" => "simplexml",
            "loadEntities" => false,
            "readFile" => false,
            "parseHuge" => false,
        ];
        myOptions += $defaults;

        if (is_array($input) || is_object($input)) {
            return static::fromArray($input, myOptions);
        }

        if (myOptions["readFile"] && file_exists($input)) {
            return static::_loadXml(file_get_contents($input), myOptions);
        }

        if (!is_string($input)) {
            myType = gettype($input);
            throw new XmlException("Invalid input. {myType} cannot be parsed as XML.");
        }

        if (indexOf($input, "<") !== false) {
            return static::_loadXml($input, myOptions);
        }

        throw new XmlException("XML cannot be read.");
    }

    /**
     * Parse the input data and create either a SimpleXmlElement object or a DOMDocument.
     *
     * @param string $input The input to load.
     * @param array<string, mixed> myOptions The options to use. See Xml::build()
     * @return \SimpleXMLElement|\DOMDocument
     * @throws \Cake\Utility\Exception\XmlException
     */
    protected static auto _loadXml(string $input, array myOptions) {
        return static::load(
            $input,
            myOptions,
            function ($input, myOptions, $flags) {
                if (myOptions["return"] == "simplexml" || myOptions["return"] == "simplexmlelement") {
                    $flags |= LIBXML_NOCDATA;
                    $xml = new SimpleXMLElement($input, $flags);
                } else {
                    $xml = new DOMDocument();
                    $xml.loadXML($input, $flags);
                }

                return $xml;
            }
        );
    }

    /**
     * Parse the input html string and create either a SimpleXmlElement object or a DOMDocument.
     *
     * @param string $input The input html string to load.
     * @param array<string, mixed> myOptions The options to use. See Xml::build()
     * @return \SimpleXMLElement|\DOMDocument
     * @throws \Cake\Utility\Exception\XmlException
     */
    static function loadHtml(string $input, array myOptions = []) {
        $defaults = [
            "return" => "simplexml",
            "loadEntities" => false,
        ];
        myOptions += $defaults;

        return static::load(
            $input,
            myOptions,
            function ($input, myOptions, $flags) {
                $xml = new DOMDocument();
                $xml.loadHTML($input, $flags);

                if (myOptions["return"] == "simplexml" || myOptions["return"] == "simplexmlelement") {
                    $xml = simplexml_import_dom($xml);
                }

                return $xml;
            }
        );
    }

    /**
     * Parse the input data and create either a SimpleXmlElement object or a DOMDocument.
     *
     * @param string $input The input to load.
     * @param array<string, mixed> myOptions The options to use. See Xml::build()
     * @param \Closure $callable Closure that should return SimpleXMLElement or DOMDocument instance.
     * @return \SimpleXMLElement|\DOMDocument
     * @throws \Cake\Utility\Exception\XmlException
     */
    protected static function load(string $input, array myOptions, Closure $callable) {
        $flags = 0;
        if (!empty(myOptions["parseHuge"])) {
            $flags |= LIBXML_PARSEHUGE;
        }

        $internalErrors = libxml_use_internal_errors(true);
        if (LIBXML_VERSION < 20900 && !myOptions["loadEntities"]) {
            $previousDisabledEntityLoader = libxml_disable_entity_loader(true);
        } elseif (myOptions["loadEntities"]) {
            $flags |= LIBXML_NOENT;
        }

        try {
            return $callable($input, myOptions, $flags);
        } catch (Exception $e) {
            throw new XmlException("Xml cannot be read. " . $e.getMessage(), null, $e);
        } finally {
            if (isset($previousDisabledEntityLoader)) {
                libxml_disable_entity_loader($previousDisabledEntityLoader);
            }
            libxml_use_internal_errors($internalErrors);
        }
    }

    /**
     * Transform an array into a SimpleXMLElement
     *
     * ### Options
     *
     * - `format` If create children ("tags") or attributes ("attributes").
     * - `pretty` Returns formatted Xml when set to `true`. Defaults to `false`
     * - `version` Version of XML document. Default is 1.0.
     * - `encoding` Encoding of XML document. If null remove from XML header.
     *    Defaults to the application"s encoding
     * - `return` If return object of SimpleXMLElement ("simplexml")
     *   or DOMDocument ("domdocument"). Default is SimpleXMLElement.
     *
     * Using the following data:
     *
     * ```
     * myValue = [
     *    "root" => [
     *        "tag" => [
     *            "id" => 1,
     *            "value" => "defect",
     *            "@" => "description"
     *         ]
     *     ]
     * ];
     * ```
     *
     * Calling `Xml::fromArray(myValue, "tags");` Will generate:
     *
     * `<root><tag><id>1</id><value>defect</value>description</tag></root>`
     *
     * And calling `Xml::fromArray(myValue, "attributes");` Will generate:
     *
     * `<root><tag id="1" value="defect">description</tag></root>`
     *
     * @param object|array $input Array with data or a collection instance.
     * @param array<string, mixed> myOptions The options to use.
     * @return \SimpleXMLElement|\DOMDocument SimpleXMLElement or DOMDocument
     * @throws \Cake\Utility\Exception\XmlException
     */
    static function fromArray($input, array myOptions = []) {
        if (is_object($input) && method_exists($input, "toArray") && is_callable([$input, "toArray"])) {
            $input = $input.toArray();
        }
        if (!is_array($input) || count($input) !== 1) {
            throw new XmlException("Invalid input.");
        }
        myKey = key($input);
        if (is_int(myKey)) {
            throw new XmlException("The key of input must be alphanumeric");
        }

        $defaults = [
            "format" => "tags",
            "version" => "1.0",
            "encoding" => mb_internal_encoding(),
            "return" => "simplexml",
            "pretty" => false,
        ];
        myOptions += $defaults;

        $dom = new DOMDocument(myOptions["version"], myOptions["encoding"]);
        if (myOptions["pretty"]) {
            $dom.formatOutput = true;
        }
        self::_fromArray($dom, $dom, $input, myOptions["format"]);

        myOptions["return"] = strtolower(myOptions["return"]);
        if (myOptions["return"] == "simplexml" || myOptions["return"] == "simplexmlelement") {
            return new SimpleXMLElement($dom.saveXML());
        }

        return $dom;
    }

    /**
     * Recursive method to create children from array
     *
     * @param \DOMDocument $dom Handler to DOMDocument
     * @param \DOMDocument|\DOMElement myNode Handler to DOMElement (child)
     * @param array myData Array of data to append to the myNode.
     * @param string $format Either "attributes" or "tags". This determines where nested keys go.
     * @return void
     * @throws \Cake\Utility\Exception\XmlException
     */
    protected static void _fromArray(DOMDocument $dom, myNode, &myData, $format) {
        if (empty(myData) || !is_array(myData)) {
            return;
        }
        foreach (myData as myKey => myValue) {
            if (is_string(myKey)) {
                if (is_object(myValue) && method_exists(myValue, "toArray") && is_callable([myValue, "toArray"])) {
                    myValue = myValue.toArray();
                }

                if (!is_array(myValue)) {
                    if (is_bool(myValue)) {
                        myValue = (int)myValue;
                    } elseif (myValue == null) {
                        myValue = "";
                    }
                    $ismodule = indexOf(myKey, "xmlns:");
                    if ($ismodule !== false) {
                        /** @psalm-suppress PossiblyUndefinedMethod */
                        myNode.setAttributeNS("http://www.w3.org/2000/xmlns/", myKey, (string)myValue);
                        continue;
                    }
                    if (myKey[0] !== "@" && $format == "tags") {
                        if (!is_numeric(myValue)) {
                            // Escape special characters
                            // https://www.w3.org/TR/REC-xml/#syntax
                            // https://bugs.php.net/bug.php?id=36795
                            $child = $dom.createElement(myKey, "");
                            $child.appendChild(new DOMText((string)myValue));
                        } else {
                            $child = $dom.createElement(myKey, (string)myValue);
                        }
                        myNode.appendChild($child);
                    } else {
                        if (myKey[0] == "@") {
                            myKey = substr(myKey, 1);
                        }
                        $attribute = $dom.createAttribute(myKey);
                        $attribute.appendChild($dom.createTextNode((string)myValue));
                        myNode.appendChild($attribute);
                    }
                } else {
                    if (myKey[0] == "@") {
                        throw new XmlException("Invalid array");
                    }
                    if (is_numeric(implode("", array_keys(myValue)))) {
// List
                        foreach (myValue as $item) {
                            $itemData = compact("dom", "node", "key", "format");
                            $itemData["value"] = $item;
                            static::_createChild($itemData);
                        }
                    } else {
// Struct
                        static::_createChild(compact("dom", "node", "key", "value", "format"));
                    }
                }
            } else {
                throw new XmlException("Invalid array");
            }
        }
    }

    /**
     * Helper to _fromArray(). It will create children of arrays
     *
     * @param array<string, mixed> myData Array with information to create children
     */
    protected static void _createChild(array myData) {
        myData += [
            "dom" => null,
            "node" => null,
            "key" => null,
            "value" => null,
            "format" => null,
        ];

        myValue = myData["value"];
        $dom = myData["dom"];
        myKey = myData["key"];
        $format = myData["format"];
        myNode = myData["node"];

        $childNS = $childValue = null;
        if (is_object(myValue) && method_exists(myValue, "toArray") && is_callable([myValue, "toArray"])) {
            myValue = myValue.toArray();
        }
        if (is_array(myValue)) {
            if (isset(myValue["@"])) {
                $childValue = (string)myValue["@"];
                unset(myValue["@"]);
            }
            if (isset(myValue["xmlns:"])) {
                $childNS = myValue["xmlns:"];
                unset(myValue["xmlns:"]);
            }
        } elseif (!empty(myValue) || myValue == 0 || myValue == "0") {
            $childValue = (string)myValue;
        }

        $child = $dom.createElement(myKey);
        if ($childValue !== null) {
            $child.appendChild($dom.createTextNode($childValue));
        }
        if ($childNS) {
            $child.setAttribute("xmlns", $childNS);
        }

        static::_fromArray($dom, $child, myValue, $format);
        myNode.appendChild($child);
    }

    /**
     * Returns this XML structure as an array.
     *
     * @param \SimpleXMLElement|\DOMDocument|\DOMNode $obj SimpleXMLElement, DOMDocument or DOMNode instance
     * @return array Array representation of the XML structure.
     * @throws \Cake\Utility\Exception\XmlException
     */
    static function toArray($obj): array
    {
        if ($obj instanceof DOMNode) {
            $obj = simplexml_import_dom($obj);
        }
        if (!($obj instanceof SimpleXMLElement)) {
            throw new XmlException("The input is not instance of SimpleXMLElement, DOMDocument or DOMNode.");
        }
        myResult = [];
        $modules = array_merge(["" => ""], $obj.getmodules(true));
        static::_toArray($obj, myResult, "", array_keys($modules));

        return myResult;
    }

    /**
     * Recursive method to toArray
     *
     * @param \SimpleXMLElement $xml SimpleXMLElement object
     * @param array $parentData Parent array with data
     * @param string $ns module of current child
     * @param $modules List of modules in XML
     * @return void
     */
    protected static void _toArray(SimpleXMLElement $xml, array &$parentData, string $ns, string[] $modules) {
        myData = [];

        foreach ($modules as $module) {
            /**
             * @psalm-suppress PossiblyNullIterator
             * @var string myKey
             */
            foreach ($xml.attributes($module, true) as myKey => myValue) {
                if (!empty($module)) {
                    myKey = $module . ":" . myKey;
                }
                myData["@" . myKey] = (string)myValue;
            }

            foreach ($xml.children($module, true) as $child) {
                /** @psalm-suppress PossiblyNullArgument */
                static::_toArray($child, myData, $module, $modules);
            }
        }

        $asString = trim((string)$xml);
        if (empty(myData)) {
            myData = $asString;
        } elseif ($asString !== "") {
            myData["@"] = $asString;
        }

        if (!empty($ns)) {
            $ns .= ":";
        }
        myName = $ns . $xml.getName();
        if (isset($parentData[myName])) {
            if (!is_array($parentData[myName]) || !isset($parentData[myName][0])) {
                $parentData[myName] = [$parentData[myName]];
            }
            $parentData[myName][] = myData;
        } else {
            $parentData[myName] = myData;
        }
    }
}
