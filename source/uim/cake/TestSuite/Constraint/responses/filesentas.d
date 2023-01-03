module uim.cake.TestSuite\Constraint\Response;

/**
 * FileSentAs
 *
 * @internal
 */
class FileSentAs : ResponseBase
{
    /**
     * @var uim.cake.http.Response
     */
    protected $response;

    /**
     * Checks assertion
     *
     * @param mixed $other Expected type
     */
    bool matches($other) {
        $file = this.response.getFile();
        if (!$file) {
            return false;
        }

        return $file.getPathName() == $other;
    }

    /**
     * Assertion message
     */
    string toString() {
        return "file was sent";
    }
}
