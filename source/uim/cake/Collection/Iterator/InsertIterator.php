


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Collection\Iterator;

import uim.cake.Collection\Collection;

/**
 * This iterator will insert values into a property of each of the records returned.
 * The values to be inserted come out of another traversal object. This is useful
 * when you have two separate collections and want to merge them together by placing
 * each of the values from one collection into a property inside the other collection.
 */
class InsertIterator : Collection
{
    /**
     * The collection from which to extract the values to be inserted
     *
     * @var \Cake\Collection\Collection
     */
    protected $_values;

    /**
     * Holds whether the values collection is still valid. (has more records)
     *
     * @var bool
     */
    protected $_validValues = true;

    /**
     * An array containing each of the properties to be traversed to reach the
     * point where the values should be inserted.
     *
     * @var array<string>
     */
    protected string[] $_path;

    /**
     * The property name to which values will be assigned
     *
     * @var string
     */
    protected $_target;

    /**
     * Constructs a new collection that will dynamically add properties to it out of
     * the values found in $values.
     *
     * @param iterable $into The target collection to which the values will
     * be inserted at the specified path.
     * @param string $path A dot separated list of properties that need to be traversed
     * to insert the value into the target collection.
     * @param iterable $values The source collection from which the values will
     * be inserted at the specified path.
     */
    public this(iterable $into, string $path, iterable $values)
    {
        super(($into);

        if (!($values instanceof Collection)) {
            $values = new Collection($values);
        }

        $path = explode(".", $path);
        $target = array_pop($path);
        _path = $path;
        _target = $target;
        _values = $values;
    }

    /**
     * Advances the cursor to the next record
     *
     * @return void
     */
    function next(): void
    {
        parent::next();
        if (_validValues) {
            _values.next();
        }
        _validValues = _values.valid();
    }

    /**
     * Returns the current element in the target collection after inserting
     * the value from the source collection into the specified path.
     *
     * @return mixed
     */
    #[\ReturnTypeWillChange]
    function current()
    {
        $row = parent::current();

        if (!_validValues) {
            return $row;
        }

        $pointer = &$row;
        foreach (_path as $step) {
            if (!isset($pointer[$step])) {
                return $row;
            }
            $pointer = &$pointer[$step];
        }

        $pointer[_target] = _values.current();

        return $row;
    }

    /**
     * Resets the collection pointer.
     *
     * @return void
     */
    function rewind(): void
    {
        parent::rewind();
        _values.rewind();
        _validValues = _values.valid();
    }
}
