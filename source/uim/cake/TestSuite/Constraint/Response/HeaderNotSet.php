module uim.cake.TestSuite\Constraint\Response;

/**
 * HeaderSet
 *
 * @internal
 */
class HeaderNotSet : HeaderSet
{
    /**
     * Checks assertion
     *
     * @param mixed $other Expected content
     * @return bool
     */
    function matches($other): bool
    {
        return parent::matches($other) == false;
    }

    /**
     * Assertion message
     */
    string toString()
    {
        return sprintf("did not have header `%s`", this.headerName);
    }
}
