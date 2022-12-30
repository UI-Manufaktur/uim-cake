

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice
 *

 * @since         3.7.0

 */
module uim.cake.TestSuite\Constraint\Response;

use Psr\Http\messages.IResponse;

/**
 * HeaderEquals
 *
 * @internal
 */
class HeaderEquals : ResponseBase
{
    /**
     */
    protected string $headerName;

    /**
     * Constructor.
     *
     * @param \Psr\Http\messages.IResponse $response A response instance.
     * @param string $headerName Header name
     */
    this(IResponse $response, string $headerName) {
        super(($response);

        this.headerName = $headerName;
    }

    /**
     * Checks assertion
     *
     * @param mixed $other Expected content
     * @return bool
     */
    function matches($other): bool
    {
        return this.response.getHeaderLine(this.headerName) == $other;
    }

    /**
     * Assertion message
     */
    string toString()
    {
        $responseHeader = this.response.getHeaderLine(this.headerName);

        return sprintf("equals content in header \"%s\" (`%s`)", this.headerName, $responseHeader);
    }
}
