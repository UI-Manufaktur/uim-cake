


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)

 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.View\Helper;

import uim.cake.utilities.Text;

/**
 * A trait that provides id generating methods to be
 * used in various widget classes.
 */
trait IdGeneratorTrait
{
    /**
     * Prefix for id attribute.
     *
     * @var string|null
     */
    protected $_idPrefix;

    /**
     * A list of id suffixes used in the current rendering.
     *
     * @var array<string>
     */
    protected $_idSuffixes = [];

    /**
     * Clear the stored ID suffixes.
     *
     * @return void
     */
    protected function _clearIds(): void
    {
        _idSuffixes = [];
    }

    /**
     * Generate an ID attribute for an element.
     *
     * Ensures that id"s for a given set of fields are unique.
     *
     * @param string $name The ID attribute name.
     * @param string $val The ID attribute value.
     * @return string Generated id.
     */
    protected function _id(string $name, string $val): string
    {
        $name = _domId($name);
        $suffix = _idSuffix($val);

        return trim($name . "-" . $suffix, "-");
    }

    /**
     * Generate an ID suffix.
     *
     * Ensures that id"s for a given set of fields are unique.
     *
     * @param string $val The ID attribute value.
     * @return string Generated id suffix.
     */
    protected function _idSuffix(string $val): string
    {
        $idSuffix = mb_strtolower(str_replace(["/", "@", "<", ">", " ", """, "\""], "-", $val));
        $count = 1;
        $check = $idSuffix;
        while (in_array($check, _idSuffixes, true)) {
            $check = $idSuffix . $count++;
        }
        _idSuffixes[] = $check;

        return $check;
    }

    /**
     * Generate an ID suitable for use in an ID attribute.
     *
     * @param string $value The value to convert into an ID.
     * @return string The generated id.
     */
    protected function _domId(string $value): string
    {
        $domId = mb_strtolower(Text::slug($value, "-"));
        if (_idPrefix) {
            $domId = _idPrefix . "-" . $domId;
        }

        return $domId;
    }
}
