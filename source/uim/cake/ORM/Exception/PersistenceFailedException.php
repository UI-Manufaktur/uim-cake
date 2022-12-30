

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *

 * @since         3.4.0
  */module uim.cake.orm.Exception;

import uim.cake.core.exceptions.CakeException;
import uim.cake.datasources.EntityInterface;
import uim.cake.utilities.Hash;
use Throwable;

/**
 * Used when a strict save or delete fails
 */
class PersistenceFailedException : CakeException
{
    /**
     * The entity on which the persistence operation failed
     *
     * @var uim.cake.datasources.EntityInterface
     */
    protected $_entity;


    protected $_messageTemplate = "Entity %s failure.";

    /**
     * Constructor.
     *
     * @param uim.cake.Datasource\EntityInterface $entity The entity on which the persistence operation failed
     * @param array<string>|string $message Either the string of the error message, or an array of attributes
     *   that are made available in the view, and sprintf()"d into Exception::$_messageTemplate
     * @param int|null $code The code of the error, is also the HTTP status code for the error.
     * @param \Throwable|null $previous the previous exception.
     */
    this(EntityInterface $entity, $message, ?int $code = null, ?Throwable $previous = null) {
        _entity = $entity;
        if (is_array($message)) {
            $errors = [];
            foreach (Hash::flatten($entity.getErrors()) as $field: $error) {
                $errors[] = $field . ": "" . $error . """;
            }
            if ($errors) {
                $message[] = implode(", ", $errors);
                _messageTemplate = "Entity %s failure. Found the following errors (%s).";
            }
        }
        super(($message, $code, $previous);
    }

    /**
     * Get the passed in entity
     *
     * @return uim.cake.Datasource\EntityInterface
     */
    function getEntity(): EntityInterface
    {
        return _entity;
    }
}
