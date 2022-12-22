<?php
declare(strict_types=1);

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
namespace Cake\Collection\Iterator;

use IteratorIterator;
use RecursiveIterator;
use Traversable;

/**
 * An iterator that can be used to generate nested iterators out of a collection
 * of items by applying an function to each of the elements in this iterator.
 *
 * @internal
 * @see \Cake\Collection\Collection::unfold()
 */
class UnfoldIterator extends IteratorIterator implements RecursiveIterator
{
    /**
     * A function that is passed each element in this iterator and
     * must return an array or Traversable object.
     *
     * @var callable
     */
    protected $_unfolder;

    /**
     * A reference to the internal iterator this object is wrapping.
     *
     * @var \Traversable
     */
    protected $_innerIterator;

    /**
     * Creates the iterator that will generate child iterators from each of the
     * elements it was constructed with.
     *
     * @param \Traversable $items The list of values to iterate
     * @param callable $unfolder A callable function that will receive the
     * current item and key. It must return an array or Traversable object
     * out of which the nested iterators will be yielded.
     */
    public this(Traversable $items, callable $unfolder)
    {
        $this->_unfolder = $unfolder;
        parent::__construct($items);
        $this->_innerIterator = $this->getInnerIterator();
    }

    /**
     * Returns true as each of the elements in the array represent a
     * list of items
     *
     * @return bool
     */
    public function hasChildren(): bool
    {
        return true;
    }

    /**
     * Returns an iterator containing the items generated by transforming
     * the current value with the callable function.
     *
     * @return \RecursiveIterator
     */
    public function getChildren(): RecursiveIterator
    {
        $current = $this->current();
        $key = $this->key();
        $unfolder = $this->_unfolder;

        return new NoChildrenIterator($unfolder($current, $key, $this->_innerIterator));
    }
}
