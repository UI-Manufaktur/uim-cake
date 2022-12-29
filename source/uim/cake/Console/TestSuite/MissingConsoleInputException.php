

/**
 * CakePHP :  Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice.
 *

 * @link          https://cakephp.org CakePHP Project
  */
module uim.cake.consoles.TestSuite;

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
    void setQuestion($question) {
        this.message .= "\nThe question asked was: " . $question;
    }
}

// phpcs:disable
class_alias(MissingConsoleInputException::class, "Cake\TestSuite\Stub\MissingConsoleInputException");
// phpcs:enable
