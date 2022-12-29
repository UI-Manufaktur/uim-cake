
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
