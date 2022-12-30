

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice
 *

 * @since         3.7.0

 */module uim.cake.consoles.TestSuite\Constraint;

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
