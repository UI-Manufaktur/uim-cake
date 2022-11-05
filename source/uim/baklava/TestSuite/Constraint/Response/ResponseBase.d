

/**
 * CakePHP(tm) : Rapid Development Framework (http://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (http://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (http://cakefoundation.org)
 * @since         3.7.0
 * @license       http://www.opensource.org/licenses/mit-license.php MIT License
 */module uim.baklava.TestSuite\Constraint\Response;

use PHPUnit\Framework\AssertionFailedError;
use PHPUnit\Framework\Constraint\Constraint;
use Psr\Http\Message\IResponse;

/**
 * Base constraint for response constraints
 *
 * @internal
 */
abstract class ResponseBase : Constraint
{
    /**
     * @var \Psr\Http\Message\IResponse
     */
    protected $response;

    /**
     * Constructor
     *
     * @param \Psr\Http\Message\IResponse|null $response Response
     */
    this(?IResponse $response) {
        if (!$response) {
            throw new AssertionFailedError('No response set, cannot assert content.');
        }

        this.response = $response;
    }

    /**
     * Get the response body as string
     *
     * @return string The response body.
     */
    protected auto _getBodyAsString(): string
    {
        return (string)this.response.getBody();
    }
}