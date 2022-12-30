module uim.cake.consoles.TestSuite\Constraint;

/**
 * ContentsContainRow
 *
 * @internal
 */
class ContentsContainRow : ContentsRegExp
{
    /**
     * Checks if contents contain expected
     *
     * @param array $other Row
     * @return bool
     * @psalm-suppress MoreSpecificImplementedParamType
     */
    bool matches($other) {
        $row = array_map(function ($cell) {
            return preg_quote($cell, "/");
        }, $other);
        $cells = implode("\s+\|\s+", $row);
        $pattern = "/" . $cells . "/";

        return preg_match($pattern, this.contents) > 0;
    }

    /**
     * Assertion message
     */
    string toString()
    {
        return sprintf("row was in %s", this.output);
    }

    /**
     * @param mixed $other Expected content
     * @return string
     */
    string failureDescription($other)
    {
        return "`" . this.exporter().shortenedExport($other) . "` " . this.toString();
    }
}
