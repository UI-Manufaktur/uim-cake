


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)

 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.databases.Statement;

/**
 * Contains a setter for marking a Statement as buffered
 *
 * @internal
 */
trait BufferResultsTrait
{
    /**
     * Whether to buffer results in php
     *
     * @var bool
     */
    protected $_bufferResults = true;

    /**
     * Whether to buffer results in php
     *
     * @param bool $buffer Toggle buffering
     * @return this
     */
    function bufferResults(bool $buffer) {
        _bufferResults = $buffer;

        return this;
    }
}
