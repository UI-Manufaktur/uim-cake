module uim.cake.Mailer\Transport;

import uim.cake.Mailer\AbstractTransport;
import uim.cake.Mailer\Message;
import uim.cake.Network\Exception\SocketException;
import uim.cake.Network\Socket;
use Exception;
use RuntimeException;

/**
 * Send mail using SMTP protocol
 */
class SmtpTransport : AbstractTransport
{
    /**
     * Default config for this class
     *
     * @var array<string, mixed>
     */
    protected $_defaultConfig = [
        'host' => 'localhost',
        'port' => 25,
        'timeout' => 30,
        'username' => null,
        'password' => null,
        'client' => null,
        'tls' => false,
        'keepAlive' => false,
    ];

    /**
     * Socket to SMTP server
     *
     * @var \Cake\Network\Socket|null
     */
    protected $_socket;

    /**
     * Content of email to return
     *
     * @var array
     */
    protected $_content = [];

    /**
     * The response of the last sent SMTP command.
     *
     * @var array
     */
    protected $_lastResponse = [];

    /**
     * Destructor
     *
     * Tries to disconnect to ensure that the connection is being
     * terminated properly before the socket gets closed.
     */
    auto __destruct() {
        try {
            this.disconnect();
        } catch (Exception $e) {
            // avoid fatal error on script termination
        }
    }

    /**
     * Unserialize handler.
     *
     * Ensure that the socket property isn't reinitialized in a broken state.
     *
     * @return void
     */
    auto __wakeup(): void
    {
        this._socket = null;
    }

    /**
     * Connect to the SMTP server.
     *
     * This method tries to connect only in case there is no open
     * connection available already.
     *
     * @return void
     */
    function connect(): void
    {
        if (!this.connected()) {
            this._connect();
            this._auth();
        }
    }

    /**
     * Check whether an open connection to the SMTP server is available.
     *
     */
    bool connected()
    {
        return this._socket !== null && this._socket.isConnected();
    }

    /**
     * Disconnect from the SMTP server.
     *
     * This method tries to disconnect only in case there is an open
     * connection available.
     *
     * @return void
     */
    function disconnect(): void
    {
        if (!this.connected()) {
            return;
        }

        this._disconnect();
    }

    /**
     * Returns the response of the last sent SMTP command.
     *
     * A response consists of one or more lines containing a response
     * code and an optional response message text:
     * ```
     * [
     *     [
     *         'code' => '250',
     *         'message' => 'mail.example.com'
     *     ],
     *     [
     *         'code' => '250',
     *         'message' => 'PIPELINING'
     *     ],
     *     [
     *         'code' => '250',
     *         'message' => '8BITMIME'
     *     ],
     *     // etc...
     * ]
     * ```
     *
     * @return array
     */
    auto getLastResponse(): array
    {
        return this._lastResponse;
    }

    /**
     * Send mail
     *
     * @param \Cake\Mailer\Message myMessage Message instance
     * @return array
     * @throws \Cake\Network\Exception\SocketException
     * @psalm-return array{headers: string, message: string}
     */
    function send(Message myMessage): array
    {
        this.checkRecipient(myMessage);

        if (!this.connected()) {
            this._connect();
            this._auth();
        } else {
            this._smtpSend('RSET');
        }

        this._sendRcpt(myMessage);
        this._sendData(myMessage);

        if (!this._config['keepAlive']) {
            this._disconnect();
        }

        return this._content;
    }

    /**
     * Parses and stores the response lines in `'code' => 'message'` format.
     *
     * @param array<string> $responseLines Response lines to parse.
     * @return void
     */
    protected auto _bufferResponseLines(array $responseLines): void
    {
        $response = [];
        foreach ($responseLines as $responseLine) {
            if (preg_match('/^(\d{3})(?:[ -]+(.*))?$/', $responseLine, $match)) {
                $response[] = [
                    'code' => $match[1],
                    'message' => $match[2] ?? null,
                ];
            }
        }
        this._lastResponse = array_merge(this._lastResponse, $response);
    }

    /**
     * Connect to SMTP Server
     *
     * @return void
     * @throws \Cake\Network\Exception\SocketException
     */
    protected auto _connect(): void
    {
        this._generateSocket();
        if (!this._socket().connect()) {
            throw new SocketException('Unable to connect to SMTP server.');
        }
        this._smtpSend(null, '220');

        myConfig = this._config;

        $host = 'localhost';
        if (isset(myConfig['client'])) {
            if (empty(myConfig['client'])) {
                throw new SocketException('Cannot use an empty client name.');
            }
            $host = myConfig['client'];
        } else {
            /** @var string $httpHost */
            $httpHost = env('HTTP_HOST');
            if ($httpHost) {
                [$host] = explode(':', $httpHost);
            }
        }

        try {
            this._smtpSend("EHLO {$host}", '250');
            if (myConfig['tls']) {
                this._smtpSend('STARTTLS', '220');
                this._socket().enableCrypto('tls');
                this._smtpSend("EHLO {$host}", '250');
            }
        } catch (SocketException $e) {
            if (myConfig['tls']) {
                throw new SocketException(
                    'SMTP server did not accept the connection or trying to connect to non TLS SMTP server using TLS.',
                    null,
                    $e
                );
            }
            try {
                this._smtpSend("HELO {$host}", '250');
            } catch (SocketException $e2) {
                throw new SocketException('SMTP server did not accept the connection.', null, $e2);
            }
        }
    }

    /**
     * Send authentication
     *
     * @return void
     * @throws \Cake\Network\Exception\SocketException
     */
    protected auto _auth(): void
    {
        if (!isset(this._config['username'], this._config['password'])) {
            return;
        }

        myUsername = this._config['username'];
        myPassword = this._config['password'];

        $replyCode = this._authPlain(myUsername, myPassword);
        if ($replyCode === '235') {
            return;
        }

        this._authLogin(myUsername, myPassword);
    }

    /**
     * Authenticate using AUTH PLAIN mechanism.
     *
     * @param string myUsername Username.
     * @param string myPassword Password.
     * @return string|null Response code for the command.
     */
    protected auto _authPlain(string myUsername, string myPassword): Nullable!string
    {
        return this._smtpSend(
            sprintf(
                'AUTH PLAIN %s',
                base64_encode(chr(0) . myUsername . chr(0) . myPassword)
            ),
            '235|504|534|535'
        );
    }

    /**
     * Authenticate using AUTH LOGIN mechanism.
     *
     * @param string myUsername Username.
     * @param string myPassword Password.
     * @return void
     */
    protected auto _authLogin(string myUsername, string myPassword): void
    {
        $replyCode = this._smtpSend('AUTH LOGIN', '334|500|502|504');
        if ($replyCode === '334') {
            try {
                this._smtpSend(base64_encode(myUsername), '334');
            } catch (SocketException $e) {
                throw new SocketException('SMTP server did not accept the username.', null, $e);
            }
            try {
                this._smtpSend(base64_encode(myPassword), '235');
            } catch (SocketException $e) {
                throw new SocketException('SMTP server did not accept the password.', null, $e);
            }
        } elseif ($replyCode === '504') {
            throw new SocketException('SMTP authentication method not allowed, check if SMTP server requires TLS.');
        } else {
            throw new SocketException(
                'AUTH command not recognized or not implemented, SMTP server may not require authentication.'
            );
        }
    }

    /**
     * Prepares the `MAIL FROM` SMTP command.
     *
     * @param string myMessage The email address to send with the command.
     * @return string
     */
    protected auto _prepareFromCmd(string myMessage): string
    {
        return 'MAIL FROM:<' . myMessage . '>';
    }

    /**
     * Prepares the `RCPT TO` SMTP command.
     *
     * @param string myMessage The email address to send with the command.
     * @return string
     */
    protected auto _prepareRcptCmd(string myMessage): string
    {
        return 'RCPT TO:<' . myMessage . '>';
    }

    /**
     * Prepares the `from` email address.
     *
     * @param \Cake\Mailer\Message myMessage Message instance
     * @return array
     */
    protected auto _prepareFromAddress(Message myMessage): array
    {
        $from = myMessage.getReturnPath();
        if (empty($from)) {
            $from = myMessage.getFrom();
        }

        return $from;
    }

    /**
     * Prepares the recipient email addresses.
     *
     * @param \Cake\Mailer\Message myMessage Message instance
     * @return array
     */
    protected auto _prepareRecipientAddresses(Message myMessage): array
    {
        $to = myMessage.getTo();
        $cc = myMessage.getCc();
        $bcc = myMessage.getBcc();

        return array_merge(array_keys($to), array_keys($cc), array_keys($bcc));
    }

    /**
     * Prepares the message body.
     *
     * @param \Cake\Mailer\Message myMessage Message instance
     * @return string
     */
    protected auto _prepareMessage(Message myMessage): string
    {
        $lines = myMessage.getBody();
        myMessages = [];
        foreach ($lines as $line) {
            if (!empty($line) && ($line[0] === '.')) {
                myMessages[] = '.' . $line;
            } else {
                myMessages[] = $line;
            }
        }

        return implode("\r\n", myMessages);
    }

    /**
     * Send emails
     *
     * @param \Cake\Mailer\Message myMessage Message message
     * @throws \Cake\Network\Exception\SocketException
     * @return void
     */
    protected auto _sendRcpt(Message myMessage): void
    {
        $from = this._prepareFromAddress(myMessage);
        this._smtpSend(this._prepareFromCmd(key($from)));

        myMessages = this._prepareRecipientAddresses(myMessage);
        foreach (myMessages as $mail) {
            this._smtpSend(this._prepareRcptCmd($mail));
        }
    }

    /**
     * Send Data
     *
     * @param \Cake\Mailer\Message myMessage Message message
     * @return void
     * @throws \Cake\Network\Exception\SocketException
     */
    protected auto _sendData(Message myMessage): void
    {
        this._smtpSend('DATA', '354');

        $headers = myMessage.getHeadersString([
            'from',
            'sender',
            'replyTo',
            'readReceipt',
            'to',
            'cc',
            'subject',
            'returnPath',
        ]);
        myMessage = this._prepareMessage(myMessage);

        this._smtpSend($headers . "\r\n\r\n" . myMessage . "\r\n\r\n\r\n.");
        this._content = ['headers' => $headers, 'message' => myMessage];
    }

    /**
     * Disconnect
     *
     * @return void
     * @throws \Cake\Network\Exception\SocketException
     */
    protected auto _disconnect(): void
    {
        this._smtpSend('QUIT', false);
        this._socket().disconnect();
    }

    /**
     * Helper method to generate socket
     *
     * @return void
     * @throws \Cake\Network\Exception\SocketException
     */
    protected auto _generateSocket(): void
    {
        this._socket = new Socket(this._config);
    }

    /**
     * Protected method for sending data to SMTP connection
     *
     * @param string|null myData Data to be sent to SMTP server
     * @param string|false $checkCode Code to check for in server response, false to skip
     * @return string|null The matched code, or null if nothing matched
     * @throws \Cake\Network\Exception\SocketException
     */
    protected auto _smtpSend(Nullable!string myData, $checkCode = '250'): Nullable!string
    {
        this._lastResponse = [];

        if (myData !== null) {
            this._socket().write(myData . "\r\n");
        }

        $timeout = this._config['timeout'];

        while ($checkCode !== false) {
            $response = '';
            $startTime = time();
            while (substr($response, -2) !== "\r\n" && (time() - $startTime < $timeout)) {
                $bytes = this._socket().read();
                if ($bytes === null) {
                    break;
                }
                $response .= $bytes;
            }
            // Catch empty or malformed responses.
            if (substr($response, -2) !== "\r\n") {
                // Use response message or assume operation timed out.
                throw new SocketException($response ?: 'SMTP timeout.');
            }
            $responseLines = explode("\r\n", rtrim($response, "\r\n"));
            $response = end($responseLines);

            this._bufferResponseLines($responseLines);

            if (preg_match('/^(' . $checkCode . ')(.)/', $response, $code)) {
                if ($code[2] === '-') {
                    continue;
                }

                return $code[1];
            }
            throw new SocketException(sprintf('SMTP Error: %s', $response));
        }

        return null;
    }

    /**
     * Get socket instance.
     *
     * @return \Cake\Network\Socket
     * @throws \RuntimeException If socket is not set.
     */
    protected auto _socket(): Socket
    {
        if (this._socket === null) {
            throw new RuntimeException('Socket is null, but must be set.');
        }

        return this._socket;
    }
}
