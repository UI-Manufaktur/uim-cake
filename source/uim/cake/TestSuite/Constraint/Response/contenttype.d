module uim.cake.TestSuite\Constraint\Response;

/**
 * ContentType
 *
 * @internal
 */
class ContentType : ResponseBase
{
    /**
     * @var uim.cake.http.Response
     */
    protected $response;

    /**
     * Checks assertion
     *
     * @param mixed $other Expected type
     * @return bool
     */
    function matches($other): bool
    {
        $alias = this.response.getMimeType($other);
        if ($alias != false) {
            $other = $alias;
        }

        return $other == this.response.getType();
    }

    /**
     * Assertion message
     */
    string toString() {
        return "is set as the Content-Type (`" ~ this.response.getType() ~ "`)";
    }
}
