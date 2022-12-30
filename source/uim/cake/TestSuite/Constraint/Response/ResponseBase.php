

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice
 *

 * @since         3.7.0

 */module uim.cake.TestSuite\Constraint\Response;

use PHPUnit\Framework\AssertionFailedError;
use PHPUnit\Framework\Constraint\Constraint;
use Psr\Http\messages.IResponse;

/**
 * Base constraint for response constraints
 *
 * @internal
 */
abstract class ResponseBase : Constraint
{
    /**
     * @var \Psr\Http\messages.IResponse
     */
    protected $response;

    /**
     * Constructor
     *
     * @param \Psr\Http\messages.IResponse|null $response Response
     */
    this(?IResponse $response) {
        if (!$response) {
            throw new AssertionFailedError("No response set, cannot assert content.");
        }

        this.response = $response;
    }

    /**
     * Get the response body as string
     *
     * @return string The response body.
     */
    protected function _getBodyAsString(): string
    {
        return (string)this.response.getBody();
    }
}
