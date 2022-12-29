

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *

 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Network\Exception;

import uim.cake.cores.exceptions.CakeException;

/**
 * Exception class for Socket. This exception will be thrown from Socket, Email, HttpSocket
 * SmtpTransport, MailTransport and HttpResponse when it encounters an error.
 */
class SocketException : CakeException
{
}
