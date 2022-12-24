

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
module uim.cake.Validation;

/**
 * Describes objects that can be validated by passing a Validator object.
 *
 * @deprecated 4.4.5 This interface is unused.
 */
interface ValidatableInterface
{
    /**
     * Validates the internal properties using a validator object and returns any
     * validation errors found.
     *
     * @param \Cake\Validation\Validator $validator The validator to use when validating the entity.
     * @return array
     */
    function validate(Validator $validator): array;
}
