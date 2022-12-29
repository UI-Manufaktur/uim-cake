module uim.cake.collections;

@safe:
import uim.cake;

/**
 * Offers a handful of methods to manipulate iterators
 */
trait CollectionTrait
{
    use ExtractTrait;

    /**
     * Returns a new collection.
     *
     * Allows classes which use this trait to determine their own
     * type of returned collection interface
     *
     * @param mixed ...$args Constructor arguments.
     * @return \Cake\Collection\ICollection
     */
    protected ICollection newCollection(...$args) {
        return new Collection(...$args);
    }


    function each(callable $callback) {
        foreach ($k, $v; this.optimizeUnwrap()) {
            $callback($v, $k);
        }

        return this;
    }


    ICollection filter(?callable $callback = null) {
        if ($callback is null) {
            $callback = function ($v) {
                return (bool)$v;
            };
        }

        return new FilterIterator(this.unwrap(), $callback);
    }


    ICollection reject(callable $callback) {
        return new FilterIterator(this.unwrap(), function (myKey, myValue, myItems) use ($callback) {
            return !$callback(myKey, myValue, myItems);
        });
    }


    bool every(callable $callback) {
        foreach (this.optimizeUnwrap() as myKey: myValue) {
            if (!$callback(myValue, myKey)) {
                return false;
            }
        }

        return true;
    }


    bool some(callable $callback) {
        foreach (myKey, myValue; this.optimizeUnwrap()) {
            if ($callback(myValue, myKey) == true) {
                return true;
            }
        }

        return false;
    }


    bool contains(myValue) {
        foreach ($v; this.optimizeUnwrap()) {
            if (myValue == $v) {
                return true;
            }
        }

        return false;
    }


    ICollection map(callable $callback) {
        return new ReplaceIterator(this.unwrap(), $callback);
    }


    function reduce(callable $callback, $initial = null) {
        $isFirst = false;
        if (func_num_args() < 2) {
            $isFirst = true;
        }

        myResult = $initial;
        foreach (this.optimizeUnwrap() as $k: myValue) {
            if ($isFirst) {
                myResult = myValue;
                $isFirst = false;
                continue;
            }
            myResult = $callback(myResult, myValue, $k);
        }

        return myResult;
    }


    ICollection extract(myPath) {
        $extractor = new ExtractIterator(this.unwrap(), myPath);
        if (is_string(myPath) && indexOf(myPath, "{*}") != false) {
            $extractor = $extractor
                .filter(function (myData) {
                    return myData  !is null && (myData instanceof Traversable || is_array(myData));
                })
                .unfold();
        }

        return $extractor;
    }


    function max(myPath, int $sort = \SORT_NUMERIC) {
        return (new SortIterator(this.unwrap(), myPath, \SORT_DESC, $sort)).first();
    }


    function min(myPath, int $sort = \SORT_NUMERIC) {
        return (new SortIterator(this.unwrap(), myPath, \SORT_ASC, $sort)).first();
    }


    function avg(myPath = null) {
        myResult = this;
        if (myPath  !is null) {
            myResult = myResult.extract(myPath);
        }
        myResult = myResult
            .reduce(function ($acc, $current) {
                [myCount, $sum] = $acc;

                return [myCount + 1, $sum + $current];
            }, [0, 0]);

        if (myResult[0] == 0) {
            return null;
        }

        return myResult[1] / myResult[0];
    }


    function median(myPath = null) {
        myItems = this;
        if (myPath  !is null) {
            myItems = myItems.extract(myPath);
        }
        myValues = myItems.toList();
        sort(myValues);
        myCount = count(myValues);

        if (myCount == 0) {
            return null;
        }

        $middle = (int)(myCount / 2);

        if (myCount % 2) {
            return myValues[$middle];
        }

        return (myValues[$middle - 1] + myValues[$middle]) / 2;
    }


    ICollection sortBy(myPath, int $order = \SORT_DESC, int $sort = \SORT_NUMERIC) {
        return new SortIterator(this.unwrap(), myPath, $order, $sort);
    }


    ICollection groupBy(myPath) {
        $callback = _propertyExtractor(myPath);
        myGroup = [];
        foreach (this.optimizeUnwrap() as myValue) {
            myPathValue = $callback(myValue);
            if (myPathValue is null) {
                throw new InvalidArgumentException(
                    "Cannot group by path that does not exist or contains a null value. " .
                    "Use a callback to return a default value for that path."
                );
            }
            myGroup[myPathValue][] = myValue;
        }

        return this.newCollection(myGroup);
    }


    ICollection indexBy(myPath) {
        $callback = _propertyExtractor(myPath);
        myGroup = [];
        foreach (this.optimizeUnwrap() as myValue) {
            myPathValue = $callback(myValue);
            if (myPathValue is null) {
                throw new InvalidArgumentException(
                    "Cannot index by path that does not exist or contains a null value. " .
                    "Use a callback to return a default value for that path."
                );
            }
            myGroup[myPathValue] = myValue;
        }

        return this.newCollection(myGroup);
    }


    ICollection countBy(myPath) {
        $callback = _propertyExtractor(myPath);

        $mapper = void (myValue, myKey, $mr) use ($callback) {
            /** @var uim.cake.collection.iIterator\MapReduce $mr */
            $mr.emitIntermediate(myValue, $callback(myValue));
        };

        $reducer = void (myValues, myKey, $mr) {
            /** @var uim.cake.collection.iIterator\MapReduce $mr */
            $mr.emit(count(myValues), myKey);
        };

        return this.newCollection(new MapReduce(this.unwrap(), $mapper, $reducer));
    }


    function sumOf(myPath = null) {
        if (myPath is null) {
            return array_sum(this.toList());
        }

        $callback = _propertyExtractor(myPath);
        $sum = 0;
        foreach ($k, $v; this.optimizeUnwrap()) {
            $sum += $callback($v, $k);
        }

        return $sum;
    }


    ICollection shuffle() {
        myItems = this.toList();
        shuffle(myItems);

        return this.newCollection(myItems);
    }


    ICollection sample(int $length = 10) {
        return this.newCollection(new LimitIterator(this.shuffle(), 0, $length));
    }


    ICollection take(int $length = 1, int $offset = 0) {
        return this.newCollection(new LimitIterator(this, $offset, $length));
    }


    ICollection skip(int $length) {
        return this.newCollection(new LimitIterator(this, $length));
    }


    ICollection match(array $conditions) {
        return this.filter(_createMatcherFilter($conditions));
    }


    function firstMatch(array $conditions) {
        return this.match($conditions).first();
    }


    function first() {
        $iterator = new LimitIterator(this, 0, 1);
        foreach ($iterator as myResult) {
            return myResult;
        }
    }


    function last() {
        $iterator = this.optimizeUnwrap();
        if (is_array($iterator)) {
            return array_pop($iterator);
        }

        if ($iterator instanceof Countable) {
            myCount = count($iterator);
            if (myCount == 0) {
                return null;
            }
            /** @var iterable $iterator */
            $iterator = new LimitIterator($iterator, myCount - 1, 1);
        }

        myResult = null;
        foreach ($iterator as myResult) {
            // No-op
        }

        return myResult;
    }


    ICollection takeLast(int $length) {
        if ($length < 1) {
            throw new InvalidArgumentException("The takeLast method requires a number greater than 0.");
        }

        $iterator = this.optimizeUnwrap();
        if (is_array($iterator)) {
            return this.newCollection(array_slice($iterator, $length * -1));
        }

        if ($iterator instanceof Countable) {
            myCount = count($iterator);

            if (myCount == 0) {
                return this.newCollection([]);
            }

            $iterator = new LimitIterator($iterator, max(0, myCount - $length), $length);

            return this.newCollection($iterator);
        }

        $generator = function ($iterator, $length) {
            myResult = [];
            $bucket = 0;
            $offset = 0;

            /**
             * Consider the collection of elements [1, 2, 3, 4, 5, 6, 7, 8, 9], in order
             * to get the last 4 elements, we can keep a buffer of 4 elements and
             * fill it circularly using modulo logic, we use the $bucket variable
             * to track the position to fill next in the buffer. This how the buffer
             * looks like after 4 iterations:
             *
             * 0) 1 2 3 4 -- $bucket now goes back to 0, we have filled 4 elementes
             * 1) 5 2 3 4 -- 5th iteration
             * 2) 5 6 3 4 -- 6th iteration
             * 3) 5 6 7 4 -- 7th iteration
             * 4) 5 6 7 8 -- 8th iteration
             * 5) 9 6 7 8
             *
             *  We can see that at the end of the iterations, the buffer contains all
             *  the last four elements, just in the wrong order. How do we keep the
             *  original order? Well, it turns out that the number of iteration also
             *  give us a clue on what"s going on, Let"s add a marker for it now:
             *
             * 0) 1 2 3 4
             *    ^ -- The 0) above now becomes the $offset variable
             * 1) 5 2 3 4
             *      ^ -- $offset = 1
             * 2) 5 6 3 4
             *        ^ -- $offset = 2
             * 3) 5 6 7 4
             *          ^ -- $offset = 3
             * 4) 5 6 7 8
             *    ^  -- We use module logic for $offset too
             *          and as you can see each time $offset is 0, then the buffer
             *          is sorted exactly as we need.
             * 5) 9 6 7 8
             *      ^ -- $offset = 1
             *
             * The $offset variable is a marker for splitting the buffer in two,
             * elements to the right for the marker are the head of the final result,
             * whereas the elements at the left are the tail. For example consider step 5)
             * which has an offset of 1:
             *
             * - $head = elements to the right = [6, 7, 8]
             * - $tail = elements to the left =  [9]
             * - myResult = $head + $tail = [6, 7, 8, 9]
             *
             * The logic above applies to collections of any size.
             */

            foreach ($k, $item; $iterator) {
                myResult[$bucket] = [$k, $item];
                $bucket = (++$bucket) % $length;
                $offset++;
            }

            $offset = $offset % $length;
            $head = array_slice(myResult, $offset);
            $tail = array_slice(myResult, 0, $offset);

            foreach ($v; $head) {
                yield $v[0]: $v[1];
            }

            foreach ($v; $tail) {
                yield $v[0]: $v[1];
            }
        };

        return this.newCollection($generator($iterator, $length));
    }


    ICollection append(myItems) {
      auto myList = new AppendIterator();
      myList.append(this.unwrap());
      myList.append(this.newCollection(myItems).unwrap());

      return this.newCollection(myList;
    }


    ICollection appendItem($item, myKey = null) {
        if (myKey  !is null) {
            myData = [myKey: $item];
        } else {
            myData = [$item];
        }

        return this.append(myData);
    }


    ICollection prepend(myItems) {
        return this.newCollection(myItems).append(this);
    }


    ICollection prependItem($item, myKey = null) {
        if (myKey  !is null) {
            myData = [myKey: $item];
        } else {
            myData = [$item];
        }

        return this.prepend(myData);
    }


    ICollection combine(myKeyPath, myValuePath, myGroupPath = null) {
        myOptions = [
            "keyPath":_propertyExtractor(myKeyPath),
            "valuePath":_propertyExtractor(myValuePath),
            "groupPath":myGroupPath ? _propertyExtractor(myGroupPath) : null,
        ];

        $mapper = function (myValue, myKey, MapReduce $mapReduce) use (myOptions) {
            $rowKey = myOptions["keyPath"];
            $rowVal = myOptions["valuePath"];

            if (!myOptions["groupPath"]) {
                $mapReduce.emit($rowVal(myValue, myKey), $rowKey(myValue, myKey));

                return null;
            }

            myKey = myOptions["groupPath"](myValue, myKey);
            $mapReduce.emitIntermediate(
                [$rowKey(myValue, myKey): $rowVal(myValue, myKey)],
                myKey
            );
        };

        $reducer = void (myValues, myKey, MapReduce $mapReduce) {
            myResult = [];
            foreach (myValues as myValue) {
                myResult += myValue;
            }
            $mapReduce.emit(myResult, myKey);
        };

        return this.newCollection(new MapReduce(this.unwrap(), $mapper, $reducer));
    }


    ICollection nest($idPath, $parentPath, string nestingKey = "children") {
        $parents = [];
        $idPath = _propertyExtractor($idPath);
        $parentPath = _propertyExtractor($parentPath);
        $isObject = true;

        $mapper = void ($row, myKey, MapReduce $mapReduce) use (&$parents, $idPath, $parentPath, $nestingKey) {
            $row[$nestingKey] = [];
            $id = $idPath($row, myKey);
            $parentId = $parentPath($row, myKey);
            $parents[$id] = &$row;
            $mapReduce.emitIntermediate($id, $parentId);
        };

        $reducer = function (myValues, myKey, MapReduce $mapReduce) use (&$parents, &$isObject, $nestingKey) {
            static $foundOutType = false;
            if (!$foundOutType) {
                $isObject = is_object(current($parents));
                $foundOutType = true;
            }
            if (empty(myKey) || !isset($parents[myKey])) {
                foreach ($id; myValues) {
                    /** @psalm-suppress PossiblyInvalidArgument */
                    $parents[$id] = $isObject ? $parents[$id] : new ArrayIterator($parents[$id], 1);
                    $mapReduce.emit($parents[$id]);
                }

                return null;
            }

            $children = [];
            foreach ($id; myValues) {
                $children[] = &$parents[$id];
            }
            $parents[myKey][$nestingKey] = $children;
        };

        return this.newCollection(new MapReduce(this.unwrap(), $mapper, $reducer))
            .map(function (myValue) use (&$isObject) {
                /** @var \ArrayIterator myValue */
                return $isObject ? myValue : myValue.getArrayCopy();
            });
    }

    ICollection insert(string myPath, myValues) {
        return new InsertIterator(this.unwrap(), myPath, myValues);
    }

    array toArray(bool $keepKeys = true) {
        $iterator = this.unwrap();
        if ($iterator instanceof ArrayIterator) {
            myItems = $iterator.getArrayCopy();

            return $keepKeys ? myItems : array_values(myItems);
        }
        // RecursiveIteratorIterator can return duplicate key values causing
        // data loss when converted into an array
        if ($keepKeys && get_class($iterator) == RecursiveIteratorIterator::class) {
            $keepKeys = false;
        }

        return iterator_to_array(this, $keepKeys);
    }


    array toList() {
        return this.toArray(false);
    }


    array jsonSerialize() {
        return this.toArray();
    }


    ICollection compile(bool $keepKeys = true) {
        return this.newCollection(this.toArray($keepKeys));
    }


    ICollection lazy() {
        $generator = function () {
            foreach ($k; $v; this.unwrap()) {
                yield $k: $v;
            }
        };

        return this.newCollection($generator());
    }


    ICollection buffered() {
        return new BufferedIterator(this.unwrap());
    }


    ICollection listNested($order = "desc", $nestingKey = "children") {
        if (is_string($order)) {
            $order = strtolower($order);
            myModes = [
                "desc":RecursiveIteratorIterator::SELF_FIRST,
                "asc":RecursiveIteratorIterator::CHILD_FIRST,
                "leaves":RecursiveIteratorIterator::LEAVES_ONLY,
            ];

            if (!isset(myModes[$order])) {
                throw new RuntimeException(sprintf(
                    "Invalid direction `%s` provided. Must be one of: "desc", "asc", "leaves"",
                    $order
                ));
            }
            $order = myModes[$order];
        }

        return new TreeIterator(
            new NestIterator(this, $nestingKey),
            $order
        );
    }


    ICollection stopWhen($condition) {
        if (!is_callable($condition)) {
            $condition = _createMatcherFilter($condition);
        }

        return new StoppableIterator(this.unwrap(), $condition);
    }


    ICollection unfold(?callable $callback = null) {
        if ($callback is null) {
            $callback = function ($item) {
                return $item;
            };
        }

        return this.newCollection(
            new RecursiveIteratorIterator(
                new UnfoldIterator(this.unwrap(), $callback),
                RecursiveIteratorIterator::LEAVES_ONLY
            )
        );
    }


    ICollection through(callable $callback) {
        myResult = $callback(this);

        return myResult instanceof ICollection ? myResult : this.newCollection(myResult);
    }


    ICollection zip(iterable myItems) {
        return new ZipIterator(array_merge([this.unwrap()], func_get_args()));
    }


    ICollection zipWith(iterable myItems, $callback) {
        if (func_num_args() > 2) {
            myItems = func_get_args();
            $callback = array_pop(myItems);
        } else {
            myItems = [myItems];
        }

        return new ZipIterator(array_merge([this.unwrap()], myItems), $callback);
    }


    ICollection chunk(int $chunkSize) {
        return this.map(function ($v, $k, $iterator) use ($chunkSize) {
            myValues = [$v];
            for ($i = 1; $i < $chunkSize; $i++) {
                $iterator.next();
                if (!$iterator.valid()) {
                    break;
                }
                myValues[] = $iterator.current();
            }

            return myValues;
        });
    }


    ICollection chunkWithKeys(int $chunkSize, bool $keepKeys = true) {
        return this.map(function ($v, $k, $iterator) use ($chunkSize, $keepKeys) {
            myKey = 0;
            if ($keepKeys) {
                myKey = $k;
            }
            myValues = [myKey: $v];
            for ($i = 1; $i < $chunkSize; $i++) {
                $iterator.next();
                if (!$iterator.valid()) {
                    break;
                }
                if ($keepKeys) {
                    myValues[$iterator.key()] = $iterator.current();
                } else {
                    myValues[] = $iterator.current();
                }
            }

            return myValues;
        });
    }


    bool isEmpty() {
        foreach ($el; this) {
            return false;
        }

        return true;
    }


    Traversable unwrap() {
        $iterator = this;
        while (
            get_class($iterator) == Collection::class
            && $iterator instanceof OuterIterator
        ) {
            $iterator = $iterator.getInnerIterator();
        }

        if ($iterator != this && $iterator instanceof ICollection) {
            $iterator = $iterator.unwrap();
        }

        return $iterator;
    }

    /**
     * {@inheritDoc}
     *
     * @param callable|null $operation A callable that allows you to customize the product result.
     * @param callable|null $filter A filtering callback that must return true for a result to be part
     *   of the final results.
     * @return \Cake\Collection\ICollection
     * @throws \LogicException
     */
    ICollection cartesianProduct(?callable $operation = null, ?callable $filter = null) {
        if (this.isEmpty()) {
            return this.newCollection([]);
        }

        myCollectionArrays = [];
        myCollectionArraysKeys = [];
        myCollectionArraysCounts = [];

        foreach (myValue; this.toList()) {
            myValueCount = count(myValue);
            if (myValueCount != count(myValue, COUNT_RECURSIVE)) {
                throw new LogicException("Cannot find the cartesian product of a multidimensional array");
            }

            myCollectionArraysKeys[] = array_keys(myValue);
            myCollectionArraysCounts[] = myValueCount;
            myCollectionArrays[] = myValue;
        }

        myResult = [];
        $lastIndex = count(myCollectionArrays) - 1;
        // holds the indexes of the arrays that generate the current combination
        $currentIndexes = array_fill(0, $lastIndex + 1, 0);

        $changeIndex = $lastIndex;

        while (!($changeIndex == 0 && $currentIndexes[0] == myCollectionArraysCounts[0])) {
            $currentCombination = array_map(function (myValue, myKeys, $index) {
                return myValue[myKeys[$index]];
            }, myCollectionArrays, myCollectionArraysKeys, $currentIndexes);

            if ($filter is null || $filter($currentCombination)) {
                myResult[] = $operation is null ? $currentCombination : $operation($currentCombination);
            }

            $currentIndexes[$lastIndex]++;

            for (
                $changeIndex = $lastIndex;
                $currentIndexes[$changeIndex] == myCollectionArraysCounts[$changeIndex] && $changeIndex > 0;
                $changeIndex--
            ) {
                $currentIndexes[$changeIndex] = 0;
                $currentIndexes[$changeIndex - 1]++;
            }
        }

        return this.newCollection(myResult);
    }

    /**
     * {@inheritDoc}
     *
     * @return \Cake\Collection\ICollection
     * @throws \LogicException
     */
    ICollection transpose() {
        $arrayValue = this.toList();
        $length = count(current($arrayValue));
        myResult = [];
        foreach ($row; $arrayValue) {
            if (count($row) != $length) {
                throw new LogicException("Child arrays do not have even length");
            }
        }

        for ($column = 0; $column < $length; $column++) {
            myResult[] = array_column($arrayValue, $column);
        }

        return this.newCollection(myResult);
    }


    int count() {
        myTraversable = this.optimizeUnwrap();

        if (is_array(myTraversable)) {
            return count(myTraversable);
        }

        return iterator_count(myTraversable);
    }


    int countKeys() {
        return count(this.toArray());
    }

    /**
     * Unwraps this iterator and returns the simplest
     * traversable that can be used for getting the data out
     *
     * @return iterable
     */
    protected auto optimizeUnwrap(): iterable
    {
        /** @var \ArrayObject $iterator */
        $iterator = this.unwrap();

        if (get_class($iterator) == ArrayIterator::class) {
            $iterator = $iterator.getArrayCopy();
        }

        return $iterator;
    }
}
