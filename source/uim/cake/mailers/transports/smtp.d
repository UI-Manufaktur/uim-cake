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
    protected STRINGAA _defaultConfig = [
        "host":"localhost",
        "port":25,
        "timeout":30,
        "username":null,
        "password":null,
        "client":null,
        "tls":false,
        "keepAlive":false,
    ];

    /**
     * Socket to SMTP server
     *
     * @var \Cake\Network\Socket|null
     */
    protected _socket;

    /**
     * Content of email to return
     *
     * @var array
     */
    protected _content = [];

    /**
     * The response of the last sent SMTP command.
     *
     * @var array
     */
    protected _lastResponse = [];

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
     * Ensure that the socket property isn"t reinitialized in a broken state.
     *
     * @return void
     */
    void __wakeup() {
        _socket = null;
    }

    /**
     * Connect to the SMTP server.
     *
     * This method tries to connect only in case there is no open
     * connection available already.
     *
     * @return void
     */
    void connect() {
        if (!this.connected()) {
            _connect();
            _auth();
        }
    }

    /**
     * Check whether an open connection to the SMTP server is available.
     */
    bool connected() {
        return _socket  !is null && _socket.isConnected();
    }

    /**
     * Disconnect from the SMTP server.
     *
     * This method tries to disconnect only in case there is an open
     * connection available.
     *
     * @return void
     */
    void disconnect() {
        if (!this.connected()) {
            return;
        }

        _disconnect();
    }

    /**
     * Returns the response of the last sent SMTP command.
     *
     * A response consists of one or more lines containing a response
     * code and an optional response message text:
     * ```
     * [
     *     [
     *         "code":"250",
     *         "message":"mail.example.com"
     *     ],
     *     [
     *         "code":"250",
     *         "message":"PIPELINING"
     *     ],
     *     [
     *         "code":"250",
     *         "message":"8BITMIME"
     *     ],
     *     // etc...
     * ]
     * ```
     *
     * @return array
     */
    array getLastResponse() {
        return _lastResponse;
    }

    /**
     * Send mail
     *
     * @param \Cake\Mailer\Message myMessage Message instance
     * @return array
     * @throws \Cake\Network\Exception\SocketException
     * @psalm-return array{headers: string, message: string}
     */
    array send(Message myMessage) {
        this.checkRecipient(myMessage);

        if (!this.connected()) {
            _connect();
            _auth();
        } else {
            _smtpSend("RSET");
        }

        _sendRcpt(myMessage);
        _sendData(myMessage);

        if (!_config["keepAlive"]) {
            _disconnect();
        }

        return _content;
    }

    /**
     * Parses and stores the response lines in `"code":"message"` format.
     *
     * @param $responseLines Response lines to parse.
     * @return void
     */
    protected void _bufferResponseLines(string[] $responseLines) {
        $response = [];
        foreach ($responseLines as $responseLine) {
            if (preg_match("/^(\d{3})(?:[ -]+(.*))?$/", $responseLine, $match)) {
                $response[] = [
                    "code":$match[1],
                    "message":$match[2] ?? null,
                ];
            }
        }
        _lastResponse = array_merge(_lastResponse, $response);
    }

    /**
     * Connect to SMTP Server
     *
     * @return void
     * @throws \Cake\Network\Exception\SocketException
     */
    protected void _connect() {
        _generateSocket();
        if (!_socket().connect()) {
            throw new SocketException("Unable to connect to SMTP server.");
        }
        _smtpSend(null, "220");

        myConfig = _config;

        $host = "localhost";
        if (isset(myConfig["client"])) {
            if (empty(myConfig["client"])) {
                throw new SocketException("Cannot use an empty client name.");
            }
            $host = myConfig["client"];
        } else {
            /** @var string httpHost */
            $httpHost = env("HTTP_HOST");
            if ($httpHost) {
                [$host] = explode(":", $httpHost);
            }
        }

        try {
            _smtpSend("EHLO {$host}", "250");
            if (myConfig["tls"]) {
                _smtpSend("STARTTLS", "220");
                _socket().enableCrypto("tls");
                _smtpSend("EHLO {$host}", "250");
            }
        } catch (SocketException $e) {
            if (myConfig["tls"]) {
                throw new SocketException(
                    "SMTP server did not accept the connection or trying to connect to non TLS SMTP server using TLS.",
                    null,
                    $e
                );
            }
            try {
                _smtpSend("HELO {$host}", "250");
            } catch (SocketException $e2) {
                throw new SocketException("SMTP server did not accept the connection.", null, $e2);
            }
        }
    }

    /**
     * Send authentication
     *
     * @throws \Cake\Network\Exception\SocketException
     */
    protected void _auth() {
        if (!isset(_config["username"], _config["password"])) {
            return;
        }

        myUsername = _config["username"];
        myPassword = _config["password"];

        $replyCode = _authPlain(myUsername, myPassword);
        if ($replyCode == "235") {
            return;
        }

        _authLogin(myUsername, myPassword);
    }

    /**
     * Authenticate using AUTH PLAIN mechanism.
     *
     * @param string myUsername Username.
     * @param string myPassword Password.
     * @return string|null Response code for the command.
     */
    protected Nullable!string _authPlain(string myUsername, string myPassword) {
        return _smtpSend(
            sprintf(
                "AUTH PLAIN %s",
                base64_encode(chr(0) . myUsername . chr(0) . myPassword)
            ),
            "235|504|534|535"
        );
    }

    /**
     * Authenticate using AUTH LOGIN mechanism.
     *
     * @param string myUsername Username.
     * @param string myPassword Password.
     * @return void
     */
    protected void _authLogin(string myUsername, string myPassword) {
        $replyCode = _smtpSend("AUTH LOGIN", "334|500|502|504");
        if ($replyCode == "334") {
            try {
                _smtpSend(base64_encode(myUsername), "334");
            } catch (SocketException $e) {
                throw new SocketException("SMTP server did not accept the username.", null, $e);
            }
            try {
                _smtpSend(base64_encode(myPassword), "235");
            } catch (SocketException $e) {
                throw new SocketException("SMTP server did not accept the password.", null, $e);
            }
        } elseif ($replyCode == "504") {
            throw new SocketException("SMTP authentication method not allowed, check if SMTP server requires TLS.");
        } else {
            throw new SocketException(
                "AUTH command not recognized or not implemented, SMTP server may not require authentication."
            );
        }
    }

    /**
     * Prepares the `MAIL FROM` SMTP command.
     *
     * @param string myMessage The email address to send with the command.
     * @return string
     */
    protected string _prepareFromCmd(string myMessage) {
        return "MAIL FROM:<" . myMessage . ">";
    }

    /**
     * Prepares the `RCPT TO` SMTP command.
     *
     * @param string myMessage The email address to send with the command.
     * @return string
     */
    protected string _prepareRcptCmd(string myMessage) {
        return "RCPT TO:<" . myMessage . ">";
    }

    /**
     * Prepares the `from` email address.
     *
     * @param \Cake\Mailer\Message myMessage Message instance
     * @return array
     */
    protected array _prepareFromAddress(Message myMessage) {
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
    protected array _prepareRecipientAddresses(Message myMessage) {
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
    protected string _prepareMessage(Message myMessage) {
        $lines = myMessage.getBody();
        myMessages = [];
        foreach ($lines as $line) {
            if (!empty($line) && ($line[0] == ".")) {
                myMessages[] = "." . $line;
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
    protected void _sendRcpt(Message myMessage) {
        $from = _prepareFromAddress(myMessage);
        _smtpSend(_prepareFromCmd(key($from)));

        myMessages = _prepareRecipientAddresses(myMessage);
        foreach (myMessages as $mail) {
            _smtpSend(_prepareRcptCmd($mail));
        }
    }

    /**
     * Send Data
     *
     * @param \Cake\Mailer\Message myMessage Message message
     * @return void
     * @throws \Cake\Network\Exception\SocketException
     */
    protected void _sendData(Message myMessage) {
        _smtpSend("DATA", "354");

        $headers = myMessage.getHeadersString([
            "from",
            "sender",
            "replyTo",
            "readReceipt",
            "to",
            "cc",
            "subject",
            "returnPath",
        ]);
        myMessage = _prepareMessage(myMessage);

        _smtpSend($headers . "\r\n\r\n" . myMessage . "\r\n\r\n\r\n.");
        _content = ["headers":$headers, "message":myMessage];
    }

    /**
     * Disconnect
     *
     * @throws \Cake\Network\Exception\SocketException
     */
    protected void _disconnect() {
        _smtpSend("QUIT", false);
        _socket().disconnect();
    }

    /**
     * Helper method to generate socket
     *
     * @return void
     * @throws \Cake\Network\Exception\SocketException
     */
    protected void _generateSocket() {
        _socket = new Socket(_config);
    }

    /**
     * Protected method for sending data to SMTP connection
     *
     * @param string|null myData Data to be sent to SMTP server
     * @param string|false $checkCode Code to check for in server response, false to skip
     * @return string|null The matched code, or null if nothing matched
     * @throws \Cake\Network\Exception\SocketException
     */
    protected Nullable!string _smtpSend(Nullable!string myData, $checkCode = "250") {
        _lastResponse = [];

        if (myData  !is null) {
            _socket().write(myData . "\r\n");
        }

        $timeout = _config["timeout"];

        while ($checkCode !== false) {
            $response = "";
            $startTime = time();
            while (substr($response, -2) !== "\r\n" && (time() - $startTime < $timeout)) {
                $bytes = _socket().read();
                if ($bytes is null) {
                    break;
                }
                $response .= $bytes;
            }
            // Catch empty or malformed responses.
            if (substr($response, -2) !== "\r\n") {
                // Use response message or assume operation timed out.
                throw new SocketException($response ?: "SMTP timeout.");
            }
            $responseLines = explode("\r\n", rtrim($response, "\r\n"));
            $response = end($responseLines);

            _bufferResponseLines($responseLines);

            if (preg_match("/^(" . $checkCode . ")(.)/", $response, $code)) {
                if ($code[2] == "-") {
                    continue;
                }

                return $code[1];
            }
            throw new SocketException(sprintf("SMTP Error: %s", $response));
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
        if (_socket is null) {
            throw new RuntimeException("Socket is null, but must be set.");
        }

        return _socket;
    }
}
