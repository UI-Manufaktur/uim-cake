

/**

 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @since         3.4.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.ORM\Exception;

import uim.cake.core.Exception\CakeException;
import uim.cake.Datasource\IEntity;
import uim.cake.Utility\Hash;
use Throwable;

/**
 * Used when a strict save or delete fails
 */
class PersistenceFailedException : CakeException
{
    /**
     * The entity on which the persistence operation failed
     *
     * @var \Cake\Datasource\IEntity
     */
    protected $_entity;


    protected $_messageTemplate = 'Entity %s failure.';

    /**
     * Constructor.
     *
     * @param \Cake\Datasource\IEntity $entity The entity on which the persistence operation failed
     * @param array<string>|string myMessage Either the string of the error message, or an array of attributes
     *   that are made available in the view, and sprintf()'d into Exception::$_messageTemplate
     * @param int|null $code The code of the error, is also the HTTP status code for the error.
     * @param \Throwable|null $previous the previous exception.
     */
    this(IEntity $entity, myMessage, ?int $code = null, ?Throwable $previous = null) {
        this._entity = $entity;
        if (is_array(myMessage)) {
            myErrors = [];
            foreach (Hash::flatten($entity.getErrors()) as myField => myError) {
                myErrors[] = myField . ': "' . myError . '"';
            }
            if (myErrors) {
                myMessage[] = implode(', ', myErrors);
                this._messageTemplate = 'Entity %s failure. Found the following errors (%s).';
            }
        }
        super.this(myMessage, $code, $previous);
    }

    /**
     * Get the passed in entity
     *
     * @return \Cake\Datasource\IEntity
     */
    auto getEntity(): IEntity
    {
        return this._entity;
    }
}
