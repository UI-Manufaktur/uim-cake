

/**
 * CakePHP :  Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP Project
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.TestSuite\Stub;

use RuntimeException;

/**
 * Exception class used to indicate missing console input.
 */
class MissingConsoleInputException : RuntimeException
{
    /**
     * Update the exception message with the question text
     *
     * @param string $question The question text.
     * @return void
     */
    auto setQuestion($question) {
        this.message .= "\nThe question asked was: " . $question;
    }
}
