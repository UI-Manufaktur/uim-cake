module uim.cake.views.Helper;

@safe:
import uim.cake;

/**
 * A trait that provides id generating methods to be
 * used in various widget classes.
 */
trait IdGeneratorTrait
{
    // Prefix for id attribute.
    protected string _idPrefix;

    // A list of id suffixes used in the current rendering.
    protected string[] _idSuffixes = null;

    /**
     * Clear the stored ID suffixes.
     */
    protected void _clearIds() {
        _idSuffixes = null;
    }

    /**
     * Generate an ID attribute for an element.
     *
     * Ensures that id"s for a given set of fields are unique.
     *
     * @param string myName The ID attribute name.
     * @param string val The ID attribute value.
     * @return string Generated id.
     */
    protected string _id(string myName, string val) {
        myName = _domId(myName);
        $suffix = _idSuffix($val);

        return trim(myName ~ "-" ~ $suffix, "-");
    }

    /**
     * Generate an ID suffix.
     *
     * Ensures that id"s for a given set of fields are unique.
     *
     * @param string val The ID attribute value.
     * @return string Generated id suffix.
     */
    protected string _idSuffix(string val) {
        $idSuffix = mb_strtolower(replace(["/", "@", "<", ">", " ", """, "\""], "-", $val));
        myCount = 1;
        $check = $idSuffix;
        while (hasAllValues($check, _idSuffixes, true)) {
            $check = $idSuffix . myCount++;
        }
        _idSuffixes[] = $check;

        return $check;
    }

    /**
     * Generate an ID suitable for use in an ID attribute.
     *
     * @param string myValue The value to convert into an ID.
     * @return string The generated id.
     */
    protected string _domId(string myValue) {
        $domId = mb_strtolower(Text::slug(myValue, "-"));
        if (_idPrefix) {
            $domId = _idPrefix ~ "-" ~ $domId;
        }

        return $domId;
    }
}
