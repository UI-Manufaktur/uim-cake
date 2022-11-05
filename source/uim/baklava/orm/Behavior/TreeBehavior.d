module uim.baklava.orm.Behavior;

import uim.baklava.collection\ICollection;
import uim.baklava.databases.expressions\IdentifierExpression;
import uim.baklava.Datasource\IEntity;
import uim.baklava.Datasource\Exception\RecordNotFoundException;
import uim.baklava.events\IEvent;
import uim.baklava.orm.Behavior;
import uim.baklava.orm.Query;
use InvalidArgumentException;
use RuntimeException;

/**
 * Makes the table to which this is attached to behave like a nested set and
 * provides methods for managing and retrieving information out of the derived
 * hierarchical structure.
 *
 * Tables attaching this behavior are required to have a column referencing the
 * parent row, and two other numeric columns (lft and rght) where the implicit
 * order will be cached.
 *
 * For more information on what is a nested set and a how it works refer to
 * https://www.sitepoint.com/hierarchical-data-database-2/
 */
class TreeBehavior : Behavior
{
    /**
     * Cached copy of the first column in a table's primary key.
     *
     * @var string
     */
    protected $_primaryKey;

    /**
     * Default config
     *
     * These are merged with user-provided configuration when the behavior is used.
     *
     * @var array<string, mixed>
     */
    protected $_defaultConfig = [
        'implementedFinders' => [
            'path' => 'findPath',
            'children' => 'findChildren',
            'treeList' => 'findTreeList',
        ],
        'implementedMethods' => [
            'childCount' => 'childCount',
            'moveUp' => 'moveUp',
            'moveDown' => 'moveDown',
            'recover' => 'recover',
            'removeFromTree' => 'removeFromTree',
            'getLevel' => 'getLevel',
            'formatTreeList' => 'formatTreeList',
        ],
        'parent' => 'parent_id',
        'left' => 'lft',
        'right' => 'rght',
        'scope' => null,
        'level' => null,
        'recoverOrder' => null,
    ];


    function initialize(array myConfig): void
    {
        this._config['leftField'] = new IdentifierExpression(this._config['left']);
        this._config['rightField'] = new IdentifierExpression(this._config['right']);
    }

    /**
     * Before save listener.
     * Transparently manages setting the lft and rght fields if the parent field is
     * included in the parameters to be saved.
     *
     * @param \Cake\Event\IEvent myEvent The beforeSave event that was fired
     * @param \Cake\Datasource\IEntity $entity the entity that is going to be saved
     * @return void
     * @throws \RuntimeException if the parent to set for the node is invalid
     */
    function beforeSave(IEvent myEvent, IEntity $entity) {
        $isNew = $entity.isNew();
        myConfig = this.getConfig();
        $parent = $entity.get(myConfig['parent']);
        $primaryKey = this._getPrimaryKey();
        $dirty = $entity.isDirty(myConfig['parent']);
        $level = myConfig['level'];

        if ($parent && $entity.get($primaryKey) === $parent) {
            throw new RuntimeException("Cannot set a node's parent as itself");
        }

        if ($isNew && $parent) {
            $parentNode = this._getNode($parent);
            $edge = $parentNode.get(myConfig['right']);
            $entity.set(myConfig['left'], $edge);
            $entity.set(myConfig['right'], $edge + 1);
            this._sync(2, '+', ">= {$edge}");

            if ($level) {
                $entity.set($level, $parentNode[$level] + 1);
            }

            return;
        }

        if ($isNew && !$parent) {
            $edge = this._getMax();
            $entity.set(myConfig['left'], $edge + 1);
            $entity.set(myConfig['right'], $edge + 2);

            if ($level) {
                $entity.set($level, 0);
            }

            return;
        }

        if ($dirty && $parent) {
            this._setParent($entity, $parent);

            if ($level) {
                $parentNode = this._getNode($parent);
                $entity.set($level, $parentNode[$level] + 1);
            }

            return;
        }

        if ($dirty && !$parent) {
            this._setAsRoot($entity);

            if ($level) {
                $entity.set($level, 0);
            }
        }
    }

    /**
     * After save listener.
     *
     * Manages updating level of descendants of currently saved entity.
     *
     * @param \Cake\Event\IEvent myEvent The afterSave event that was fired
     * @param \Cake\Datasource\IEntity $entity the entity that is going to be saved
     * @return void
     */
    function afterSave(IEvent myEvent, IEntity $entity) {
        if (!this._config['level'] || $entity.isNew()) {
            return;
        }

        this._setChildrenLevel($entity);
    }

    /**
     * Set level for descendants.
     *
     * @param \Cake\Datasource\IEntity $entity The entity whose descendants need to be updated.
     * @return void
     */
    protected auto _setChildrenLevel(IEntity $entity): void
    {
        myConfig = this.getConfig();

        if ($entity.get(myConfig['left']) + 1 === $entity.get(myConfig['right'])) {
            return;
        }

        $primaryKey = this._getPrimaryKey();
        $primaryKeyValue = $entity.get($primaryKey);
        $depths = [$primaryKeyValue => $entity.get(myConfig['level'])];

        $children = this._table.find('children', [
            'for' => $primaryKeyValue,
            'fields' => [this._getPrimaryKey(), myConfig['parent'], myConfig['level']],
            'order' => myConfig['left'],
        ]);

        /** @var \Cake\Datasource\IEntity myNode */
        foreach ($children as myNode) {
            $parentIdValue = myNode.get(myConfig['parent']);
            $depth = $depths[$parentIdValue] + 1;
            $depths[myNode.get($primaryKey)] = $depth;

            this._table.updateAll(
                [myConfig['level'] => $depth],
                [$primaryKey => myNode.get($primaryKey)]
            );
        }
    }

    /**
     * Also deletes the nodes in the subtree of the entity to be delete
     *
     * @param \Cake\Event\IEvent myEvent The beforeDelete event that was fired
     * @param \Cake\Datasource\IEntity $entity The entity that is going to be saved
     * @return void
     */
    function beforeDelete(IEvent myEvent, IEntity $entity) {
        myConfig = this.getConfig();
        this._ensureFields($entity);
        $left = $entity.get(myConfig['left']);
        $right = $entity.get(myConfig['right']);
        $diff = $right - $left + 1;

        if ($diff > 2) {
            myQuery = this._scope(this._table.query())
                .delete()
                .where(function ($exp) use (myConfig, $left, $right) {
                    /** @var \Cake\Database\Expression\QueryExpression $exp */
                    return $exp
                        .gte(myConfig['leftField'], $left + 1)
                        .lte(myConfig['leftField'], $right - 1);
                });
            $statement = myQuery.execute();
            $statement.closeCursor();
        }

        this._sync($diff, '-', "> {$right}");
    }

    /**
     * Sets the correct left and right values for the passed entity so it can be
     * updated to a new parent. It also makes the hole in the tree so the node
     * move can be done without corrupting the structure.
     *
     * @param \Cake\Datasource\IEntity $entity The entity to re-parent
     * @param mixed $parent the id of the parent to set
     * @return void
     * @throws \RuntimeException if the parent to set to the entity is not valid
     */
    protected auto _setParent(IEntity $entity, $parent): void
    {
        myConfig = this.getConfig();
        $parentNode = this._getNode($parent);
        this._ensureFields($entity);
        $parentLeft = $parentNode.get(myConfig['left']);
        $parentRight = $parentNode.get(myConfig['right']);
        $right = $entity.get(myConfig['right']);
        $left = $entity.get(myConfig['left']);

        if ($parentLeft > $left && $parentLeft < $right) {
            throw new RuntimeException(sprintf(
                'Cannot use node "%s" as parent for entity "%s"',
                $parent,
                $entity.get(this._getPrimaryKey())
            ));
        }

        // Values for moving to the left
        $diff = $right - $left + 1;
        myTargetLeft = $parentRight;
        myTargetRight = $diff + $parentRight - 1;
        $min = $parentRight;
        $max = $left - 1;

        if ($left < myTargetLeft) {
            // Moving to the right
            myTargetLeft = $parentRight - $diff;
            myTargetRight = $parentRight - 1;
            $min = $right + 1;
            $max = $parentRight - 1;
            $diff *= -1;
        }

        if ($right - $left > 1) {
            // Correcting internal subtree
            $internalLeft = $left + 1;
            $internalRight = $right - 1;
            this._sync(myTargetLeft - $left, '+', "BETWEEN {$internalLeft} AND {$internalRight}", true);
        }

        this._sync($diff, '+', "BETWEEN {$min} AND {$max}");

        if ($right - $left > 1) {
            this._unmarkInternalTree();
        }

        // Allocating new position
        $entity.set(myConfig['left'], myTargetLeft);
        $entity.set(myConfig['right'], myTargetRight);
    }

    /**
     * Updates the left and right column for the passed entity so it can be set as
     * a new root in the tree. It also modifies the ordering in the rest of the tree
     * so the structure remains valid
     *
     * @param \Cake\Datasource\IEntity $entity The entity to set as a new root
     * @return void
     */
    protected auto _setAsRoot(IEntity $entity): void
    {
        myConfig = this.getConfig();
        $edge = this._getMax();
        this._ensureFields($entity);
        $right = $entity.get(myConfig['right']);
        $left = $entity.get(myConfig['left']);
        $diff = $right - $left;

        if ($right - $left > 1) {
            //Correcting internal subtree
            $internalLeft = $left + 1;
            $internalRight = $right - 1;
            this._sync($edge - $diff - $left, '+', "BETWEEN {$internalLeft} AND {$internalRight}", true);
        }

        this._sync($diff + 1, '-', "BETWEEN {$right} AND {$edge}");

        if ($right - $left > 1) {
            this._unmarkInternalTree();
        }

        $entity.set(myConfig['left'], $edge - $diff);
        $entity.set(myConfig['right'], $edge);
    }

    /**
     * Helper method used to invert the sign of the left and right columns that are
     * less than 0. They were set to negative values before so their absolute value
     * wouldn't change while performing other tree transformations.
     *
     * @return void
     */
    protected auto _unmarkInternalTree(): void
    {
        myConfig = this.getConfig();
        this._table.updateAll(
            function ($exp) use (myConfig) {
                /** @var \Cake\Database\Expression\QueryExpression $exp */
                $leftInverse = clone $exp;
                $leftInverse.setConjunction('*').add('-1');
                $rightInverse = clone $leftInverse;

                return $exp
                    .eq(myConfig['leftField'], $leftInverse.add(myConfig['leftField']))
                    .eq(myConfig['rightField'], $rightInverse.add(myConfig['rightField']));
            },
            function ($exp) use (myConfig) {
                /** @var \Cake\Database\Expression\QueryExpression $exp */
                return $exp.lt(myConfig['leftField'], 0);
            }
        );
    }

    /**
     * Custom finder method which can be used to return the list of nodes from the root
     * to a specific node in the tree. This custom finder requires that the key 'for'
     * is passed in the options containing the id of the node to get its path for.
     *
     * @param \Cake\ORM\Query myQuery The constructed query to modify
     * @param array<string, mixed> myOptions the list of options for the query
     * @return \Cake\ORM\Query
     * @throws \InvalidArgumentException If the 'for' key is missing in options
     */
    function findPath(Query myQuery, array myOptions): Query
    {
        if (empty(myOptions['for'])) {
            throw new InvalidArgumentException("The 'for' key is required for find('path')");
        }

        myConfig = this.getConfig();
        [$left, $right] = array_map(
            function (myField) {
                return this._table.aliasField(myField);
            },
            [myConfig['left'], myConfig['right']]
        );

        myNode = this._table.get(myOptions['for'], ['fields' => [$left, $right]]);

        return this._scope(myQuery)
            .where([
                "$left <=" => myNode.get(myConfig['left']),
                "$right >=" => myNode.get(myConfig['right']),
            ])
            .order([$left => 'ASC']);
    }

    /**
     * Get the number of children nodes.
     *
     * @param \Cake\Datasource\IEntity myNode The entity to count children for
     * @param bool $direct whether to count all nodes in the subtree or just
     * direct children
     * @return int Number of children nodes.
     */
    function childCount(IEntity myNode, bool $direct = false): int
    {
        myConfig = this.getConfig();
        $parent = this._table.aliasField(myConfig['parent']);

        if ($direct) {
            return this._scope(this._table.find())
                .where([$parent => myNode.get(this._getPrimaryKey())])
                .count();
        }

        this._ensureFields(myNode);

        return (myNode.get(myConfig['right']) - myNode.get(myConfig['left']) - 1) / 2;
    }

    /**
     * Get the children nodes of the current model
     *
     * Available options are:
     *
     * - for: The id of the record to read.
     * - direct: Boolean, whether to return only the direct (true), or all (false) children,
     *   defaults to false (all children).
     *
     * If the direct option is set to true, only the direct children are returned (based upon the parent_id field)
     *
     * @param \Cake\ORM\Query myQuery Query.
     * @param array<string, mixed> myOptions Array of options as described above
     * @return \Cake\ORM\Query
     * @throws \InvalidArgumentException When the 'for' key is not passed in myOptions
     */
    function findChildren(Query myQuery, array myOptions): Query
    {
        myConfig = this.getConfig();
        myOptions += ['for' => null, 'direct' => false];
        [$parent, $left, $right] = array_map(
            function (myField) {
                return this._table.aliasField(myField);
            },
            [myConfig['parent'], myConfig['left'], myConfig['right']]
        );

        [$for, $direct] = [myOptions['for'], myOptions['direct']];

        if (empty($for)) {
            throw new InvalidArgumentException("The 'for' key is required for find('children')");
        }

        if (myQuery.clause('order') === null) {
            myQuery.order([$left => 'ASC']);
        }

        if ($direct) {
            return this._scope(myQuery).where([$parent => $for]);
        }

        myNode = this._getNode($for);

        return this._scope(myQuery)
            .where([
                "{$right} <" => myNode.get(myConfig['right']),
                "{$left} >" => myNode.get(myConfig['left']),
            ]);
    }

    /**
     * Gets a representation of the elements in the tree as a flat list where the keys are
     * the primary key for the table and the values are the display field for the table.
     * Values are prefixed to visually indicate relative depth in the tree.
     *
     * ### Options
     *
     * - keyPath: A dot separated path to fetch the field to use for the array key, or a closure to
     *   return the key out of the provided row.
     * - valuePath: A dot separated path to fetch the field to use for the array value, or a closure to
     *   return the value out of the provided row.
     * - spacer: A string to be used as prefix for denoting the depth in the tree for each item
     *
     * @param \Cake\ORM\Query myQuery Query.
     * @param array<string, mixed> myOptions Array of options as described above.
     * @return \Cake\ORM\Query
     */
    function findTreeList(Query myQuery, array myOptions): Query
    {
        $left = this._table.aliasField(this.getConfig('left'));

        myResults = this._scope(myQuery)
            .find('threaded', [
                'parentField' => this.getConfig('parent'),
                'order' => [$left => 'ASC'],
            ]);

        return this.formatTreeList(myResults, myOptions);
    }

    /**
     * Formats query as a flat list where the keys are the primary key for the table
     * and the values are the display field for the table. Values are prefixed to visually
     * indicate relative depth in the tree.
     *
     * ### Options
     *
     * - keyPath: A dot separated path to the field that will be the result array key, or a closure to
     *   return the key from the provided row.
     * - valuePath: A dot separated path to the field that is the array's value, or a closure to
     *   return the value from the provided row.
     * - spacer: A string to be used as prefix for denoting the depth in the tree for each item.
     *
     * @param \Cake\ORM\Query myQuery The query object to format.
     * @param array<string, mixed> myOptions Array of options as described above.
     * @return \Cake\ORM\Query Augmented query.
     */
    function formatTreeList(Query myQuery, array myOptions = []): Query
    {
        return myQuery.formatResults(function (ICollection myResults) use (myOptions) {
            myOptions += [
                'keyPath' => this._getPrimaryKey(),
                'valuePath' => this._table.getDisplayField(),
                'spacer' => '_',
            ];

            /** @var \Cake\collection.iIterator\TreeIterator $nested */
            $nested = myResults.listNested();

            return $nested.printer(myOptions['valuePath'], myOptions['keyPath'], myOptions['spacer']);
        });
    }

    /**
     * Removes the current node from the tree, by positioning it as a new root
     * and re-parents all children up one level.
     *
     * Note that the node will not be deleted just moved away from its current position
     * without moving its children with it.
     *
     * @param \Cake\Datasource\IEntity myNode The node to remove from the tree
     * @return \Cake\Datasource\IEntity|false the node after being removed from the tree or
     * false on error
     */
    function removeFromTree(IEntity myNode) {
        return this._table.getConnection().transactional(function () use (myNode) {
            this._ensureFields(myNode);

            return this._removeFromTree(myNode);
        });
    }

    /**
     * Helper function containing the actual code for removeFromTree
     *
     * @param \Cake\Datasource\IEntity myNode The node to remove from the tree
     * @return \Cake\Datasource\IEntity|false the node after being removed from the tree or
     * false on error
     */
    protected auto _removeFromTree(IEntity myNode) {
        myConfig = this.getConfig();
        $left = myNode.get(myConfig['left']);
        $right = myNode.get(myConfig['right']);
        $parent = myNode.get(myConfig['parent']);

        myNode.set(myConfig['parent'], null);

        if ($right - $left === 1) {
            return this._table.save(myNode);
        }

        $primary = this._getPrimaryKey();
        this._table.updateAll(
            [myConfig['parent'] => $parent],
            [myConfig['parent'] => myNode.get($primary)]
        );
        this._sync(1, '-', 'BETWEEN ' . ($left + 1) . ' AND ' . ($right - 1));
        this._sync(2, '-', "> {$right}");
        $edge = this._getMax();
        myNode.set(myConfig['left'], $edge + 1);
        myNode.set(myConfig['right'], $edge + 2);
        myFields = [myConfig['parent'], myConfig['left'], myConfig['right']];

        this._table.updateAll(myNode.extract(myFields), [$primary => myNode.get($primary)]);

        foreach (myFields as myField) {
            myNode.setDirty(myField, false);
        }

        return myNode;
    }

    /**
     * Reorders the node without changing its parent.
     *
     * If the node is the first child, or is a top level node with no previous node
     * this method will return the same node without any changes
     *
     * @param \Cake\Datasource\IEntity myNode The node to move
     * @param int|true $number How many places to move the node, or true to move to first position
     * @throws \Cake\Datasource\Exception\RecordNotFoundException When node was not found
     * @return \Cake\Datasource\IEntity|false myNode The node after being moved or false if `$number` is < 1
     */
    function moveUp(IEntity myNode, $number = 1) {
        if ($number < 1) {
            return false;
        }

        return this._table.getConnection().transactional(function () use (myNode, $number) {
            this._ensureFields(myNode);

            return this._moveUp(myNode, $number);
        });
    }

    /**
     * Helper function used with the actual code for moveUp
     *
     * @param \Cake\Datasource\IEntity myNode The node to move
     * @param int|true $number How many places to move the node, or true to move to first position
     * @return \Cake\Datasource\IEntity myNode The node after being moved
     * @throws \Cake\Datasource\Exception\RecordNotFoundException When node was not found
     */
    protected auto _moveUp(IEntity myNode, $number): IEntity
    {
        myConfig = this.getConfig();
        [$parent, $left, $right] = [myConfig['parent'], myConfig['left'], myConfig['right']];
        [myNodeParent, myNodeLeft, myNodeRight] = array_values(myNode.extract([$parent, $left, $right]));

        myTargetNode = null;
        if ($number !== true) {
            /** @var \Cake\Datasource\IEntity|null myTargetNode */
            myTargetNode = this._scope(this._table.find())
                .select([$left, $right])
                .where(["$parent IS" => myNodeParent])
                .where(function ($exp) use (myConfig, myNodeLeft) {
                    /** @var \Cake\Database\Expression\QueryExpression $exp */
                    return $exp.lt(myConfig['rightField'], myNodeLeft);
                })
                .orderDesc(myConfig['leftField'])
                .offset($number - 1)
                .limit(1)
                .first();
        }
        if (!myTargetNode) {
            /** @var \Cake\Datasource\IEntity|null myTargetNode */
            myTargetNode = this._scope(this._table.find())
                .select([$left, $right])
                .where(["$parent IS" => myNodeParent])
                .where(function ($exp) use (myConfig, myNodeLeft) {
                    /** @var \Cake\Database\Expression\QueryExpression $exp */
                    return $exp.lt(myConfig['rightField'], myNodeLeft);
                })
                .orderAsc(myConfig['leftField'])
                .limit(1)
                .first();

            if (!myTargetNode) {
                return myNode;
            }
        }

        [myTargetLeft] = array_values(myTargetNode.extract([$left, $right]));
        $edge = this._getMax();
        $leftBoundary = myTargetLeft;
        $rightBoundary = myNodeLeft - 1;

        myNodeToEdge = $edge - myNodeLeft + 1;
        $shift = myNodeRight - myNodeLeft + 1;
        myNodeToHole = $edge - $leftBoundary + 1;
        this._sync(myNodeToEdge, '+', "BETWEEN {myNodeLeft} AND {myNodeRight}");
        this._sync($shift, '+', "BETWEEN {$leftBoundary} AND {$rightBoundary}");
        this._sync(myNodeToHole, '-', "> {$edge}");

        myNode.set($left, myTargetLeft);
        myNode.set($right, myTargetLeft + myNodeRight - myNodeLeft);

        myNode.setDirty($left, false);
        myNode.setDirty($right, false);

        return myNode;
    }

    /**
     * Reorders the node without changing the parent.
     *
     * If the node is the last child, or is a top level node with no subsequent node
     * this method will return the same node without any changes
     *
     * @param \Cake\Datasource\IEntity myNode The node to move
     * @param int|true $number How many places to move the node or true to move to last position
     * @throws \Cake\Datasource\Exception\RecordNotFoundException When node was not found
     * @return \Cake\Datasource\IEntity|false the entity after being moved or false if `$number` is < 1
     */
    function moveDown(IEntity myNode, $number = 1) {
        if ($number < 1) {
            return false;
        }

        return this._table.getConnection().transactional(function () use (myNode, $number) {
            this._ensureFields(myNode);

            return this._moveDown(myNode, $number);
        });
    }

    /**
     * Helper function used with the actual code for moveDown
     *
     * @param \Cake\Datasource\IEntity myNode The node to move
     * @param int|true $number How many places to move the node, or true to move to last position
     * @return \Cake\Datasource\IEntity myNode The node after being moved
     * @throws \Cake\Datasource\Exception\RecordNotFoundException When node was not found
     */
    protected auto _moveDown(IEntity myNode, $number): IEntity
    {
        myConfig = this.getConfig();
        [$parent, $left, $right] = [myConfig['parent'], myConfig['left'], myConfig['right']];
        [myNodeParent, myNodeLeft, myNodeRight] = array_values(myNode.extract([$parent, $left, $right]));

        myTargetNode = null;
        if ($number !== true) {
            /** @var \Cake\Datasource\IEntity|null myTargetNode */
            myTargetNode = this._scope(this._table.find())
                .select([$left, $right])
                .where(["$parent IS" => myNodeParent])
                .where(function ($exp) use (myConfig, myNodeRight) {
                    /** @var \Cake\Database\Expression\QueryExpression $exp */
                    return $exp.gt(myConfig['leftField'], myNodeRight);
                })
                .orderAsc(myConfig['leftField'])
                .offset($number - 1)
                .limit(1)
                .first();
        }
        if (!myTargetNode) {
            /** @var \Cake\Datasource\IEntity|null myTargetNode */
            myTargetNode = this._scope(this._table.find())
                .select([$left, $right])
                .where(["$parent IS" => myNodeParent])
                .where(function ($exp) use (myConfig, myNodeRight) {
                    /** @var \Cake\Database\Expression\QueryExpression $exp */
                    return $exp.gt(myConfig['leftField'], myNodeRight);
                })
                .orderDesc(myConfig['leftField'])
                .limit(1)
                .first();

            if (!myTargetNode) {
                return myNode;
            }
        }

        [, myTargetRight] = array_values(myTargetNode.extract([$left, $right]));
        $edge = this._getMax();
        $leftBoundary = myNodeRight + 1;
        $rightBoundary = myTargetRight;

        myNodeToEdge = $edge - myNodeLeft + 1;
        $shift = myNodeRight - myNodeLeft + 1;
        myNodeToHole = $edge - $rightBoundary + $shift;
        this._sync(myNodeToEdge, '+', "BETWEEN {myNodeLeft} AND {myNodeRight}");
        this._sync($shift, '-', "BETWEEN {$leftBoundary} AND {$rightBoundary}");
        this._sync(myNodeToHole, '-', "> {$edge}");

        myNode.set($left, myTargetRight - (myNodeRight - myNodeLeft));
        myNode.set($right, myTargetRight);

        myNode.setDirty($left, false);
        myNode.setDirty($right, false);

        return myNode;
    }

    /**
     * Returns a single node from the tree from its primary key
     *
     * @param mixed $id Record id.
     * @return \Cake\Datasource\IEntity
     * @throws \Cake\Datasource\Exception\RecordNotFoundException When node was not found
     * @psalm-suppress InvalidReturnType
     */
    protected auto _getNode($id): IEntity
    {
        myConfig = this.getConfig();
        [$parent, $left, $right] = [myConfig['parent'], myConfig['left'], myConfig['right']];
        $primaryKey = this._getPrimaryKey();
        myFields = [$parent, $left, $right];
        if (myConfig['level']) {
            myFields[] = myConfig['level'];
        }

        myNode = this._scope(this._table.find())
            .select(myFields)
            .where([this._table.aliasField($primaryKey) => $id])
            .first();

        if (!myNode) {
            throw new RecordNotFoundException("Node \"{$id}\" was not found in the tree.");
        }

        /** @psalm-suppress InvalidReturnStatement */
        return myNode;
    }

    /**
     * Recovers the lft and right column values out of the hierarchy defined by the
     * parent column.
     *
     * @return void
     */
    function recover(): void
    {
        this._table.getConnection().transactional(function (): void {
            this._recoverTree();
        });
    }

    /**
     * Recursive method used to recover a single level of the tree
     *
     * @param int $lftRght The starting lft/rght value
     * @param mixed $parentId the parent id of the level to be recovered
     * @param int $level Node level
     * @return int The next lftRght value
     */
    protected auto _recoverTree(int $lftRght = 1, $parentId = null, $level = 0): int
    {
        myConfig = this.getConfig();
        [$parent, $left, $right] = [myConfig['parent'], myConfig['left'], myConfig['right']];
        $primaryKey = this._getPrimaryKey();
        $order = myConfig['recoverOrder'] ?: $primaryKey;

        myNodes = this._scope(this._table.query())
            .select($primaryKey)
            .where([$parent . ' IS' => $parentId])
            .order($order)
            .disableHydration()
            .all();

        foreach (myNodes as myNode) {
            myNodeLft = $lftRght++;
            $lftRght = this._recoverTree($lftRght, myNode[$primaryKey], $level + 1);

            myFields = [$left => myNodeLft, $right => $lftRght++];
            if (myConfig['level']) {
                myFields[myConfig['level']] = $level;
            }

            this._table.updateAll(
                myFields,
                [$primaryKey => myNode[$primaryKey]]
            );
        }

        return $lftRght;
    }

    /**
     * Returns the maximum index value in the table.
     *
     * @return int
     */
    protected auto _getMax(): int
    {
        myField = this._config['right'];
        $rightField = this._config['rightField'];
        $edge = this._scope(this._table.find())
            .select([myField])
            .orderDesc($rightField)
            .first();

        if ($edge === null || empty($edge[myField])) {
            return 0;
        }

        return $edge[myField];
    }

    /**
     * Auxiliary function used to automatically alter the value of both the left and
     * right columns by a certain amount that match the passed conditions
     *
     * @param int $shift the value to use for operating the left and right columns
     * @param string $dir The operator to use for shifting the value (+/-)
     * @param string $conditions a SQL snipped to be used for comparing left or right
     * against it.
     * @param bool $mark whether to mark the updated values so that they can not be
     * modified by future calls to this function.
     * @return void
     */
    protected auto _sync(int $shift, string $dir, string $conditions, bool $mark = false): void
    {
        myConfig = this._config;

        foreach ([myConfig['leftField'], myConfig['rightField']] as myField) {
            myQuery = this._scope(this._table.query());
            $exp = myQuery.newExpr();

            $movement = clone $exp;
            $movement.add(myField).add((string)$shift).setConjunction($dir);

            $inverse = clone $exp;
            $movement = $mark ?
                $inverse.add($movement).setConjunction('*').add('-1') :
                $movement;

            $where = clone $exp;
            $where.add(myField).add($conditions).setConjunction('');

            myQuery.update()
                .set($exp.eq(myField, $movement))
                .where($where);

            myQuery.execute().closeCursor();
        }
    }

    /**
     * Alters the passed query so that it only returns scoped records as defined
     * in the tree configuration.
     *
     * @param \Cake\ORM\Query myQuery the Query to modify
     * @return \Cake\ORM\Query
     */
    protected auto _scope(Query myQuery): Query
    {
        $scope = this.getConfig('scope');

        if (is_array($scope)) {
            return myQuery.where($scope);
        }
        if (is_callable($scope)) {
            return $scope(myQuery);
        }

        return myQuery;
    }

    /**
     * Ensures that the provided entity contains non-empty values for the left and
     * right fields
     *
     * @param \Cake\Datasource\IEntity $entity The entity to ensure fields for
     * @return void
     */
    protected auto _ensureFields(IEntity $entity): void
    {
        myConfig = this.getConfig();
        myFields = [myConfig['left'], myConfig['right']];
        myValues = array_filter($entity.extract(myFields));
        if (count(myValues) === count(myFields)) {
            return;
        }

        $fresh = this._table.get($entity.get(this._getPrimaryKey()));
        $entity.set($fresh.extract(myFields), ['guard' => false]);

        foreach (myFields as myField) {
            $entity.setDirty(myField, false);
        }
    }

    /**
     * Returns a single string value representing the primary key of the attached table
     *
     * @return string
     */
    protected auto _getPrimaryKey(): string
    {
        if (!this._primaryKey) {
            $primaryKey = (array)this._table.getPrimaryKey();
            this._primaryKey = $primaryKey[0];
        }

        return this._primaryKey;
    }

    /**
     * Returns the depth level of a node in the tree.
     *
     * @param \Cake\Datasource\IEntity|string|int $entity The entity or primary key get the level of.
     * @return int|false Integer of the level or false if the node does not exist.
     */
    auto getLevel($entity) {
        $primaryKey = this._getPrimaryKey();
        $id = $entity;
        if ($entity instanceof IEntity) {
            $id = $entity.get($primaryKey);
        }
        myConfig = this.getConfig();
        $entity = this._table.find('all')
            .select([myConfig['left'], myConfig['right']])
            .where([$primaryKey => $id])
            .first();

        if ($entity === null) {
            return false;
        }

        myQuery = this._table.find('all').where([
            myConfig['left'] . ' <' => $entity[myConfig['left']],
            myConfig['right'] . ' >' => $entity[myConfig['right']],
        ]);

        return this._scope(myQuery).count();
    }
}
