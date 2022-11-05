module uim.baklava.views\Helper;

import uim.baklava.utikities.Text;

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
    protected auto _clearIds(): void
    {
        this._idSuffixes = [];
    }

    /**
     * Generate an ID attribute for an element.
     *
     * Ensures that id's for a given set of fields are unique.
     *
     * @param string myName The ID attribute name.
     * @param string $val The ID attribute value.
     * @return string Generated id.
     */
    protected auto _id(string myName, string $val): string
    {
        myName = this._domId(myName);
        $suffix = this._idSuffix($val);

        return trim(myName . '-' . $suffix, '-');
    }

    /**
     * Generate an ID suffix.
     *
     * Ensures that id's for a given set of fields are unique.
     *
     * @param string $val The ID attribute value.
     * @return string Generated id suffix.
     */
    protected auto _idSuffix(string $val): string
    {
        $idSuffix = mb_strtolower(str_replace(['/', '@', '<', '>', ' ', '"', '\''], '-', $val));
        myCount = 1;
        $check = $idSuffix;
        while (in_array($check, this._idSuffixes, true)) {
            $check = $idSuffix . myCount++;
        }
        this._idSuffixes[] = $check;

        return $check;
    }

    /**
     * Generate an ID suitable for use in an ID attribute.
     *
     * @param string myValue The value to convert into an ID.
     * @return string The generated id.
     */
    protected auto _domId(string myValue): string
    {
        $domId = mb_strtolower(Text::slug(myValue, '-'));
        if (this._idPrefix) {
            $domId = this._idPrefix . '-' . $domId;
        }

        return $domId;
    }
}
