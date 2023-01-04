module uim.cake.mailers.Transport;

import uim.cake.mailers.AbstractTransport;
import uim.cake.mailers.Message;
import uim.cake.Network\exceptions.SocketException;
import uim.cake.Network\Socket;
use Exception;
use RuntimeException;

/**
 * Send mail using SMTP protocol
 */
class SmtpTransport : AbstractTransport
{
    protected const AUTH_PLAIN = "PLAIN";
    protected const AUTH_LOGIN = "LOGIN";

    /**
     * Default config for this class
     *
     * @var array<string, mixed>
     */
    protected $_defaultConfig = [
        "host": "localhost",
        "port": 25,
        "timeout": 30,
        "username": null,
        "password": null,
        "client": null,
        "tls": false,
        "keepAlive": false,
    ];

    /**
     * Socket to SMTP server
     *
     * @var uim.cake.Network\Socket|null
     */
    protected $_socket;

    /**
     * Content of email to return
     *
     * @var array<string, string>
     */
    protected $_content = [];

    /**
     * The response of the last sent SMTP command.
     *
     * @var array
     */
    protected $_lastResponse = [];

    /**
     * Detected authentication type.
     *
     * @var string|null
     */
    protected $authType = null;

    /**
     * Destructor
     *
     * Tries to disconnect to ensure that the connection is being
     * terminated properly before the socket gets closed.
     */
    function __destruct() {
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
     */
    void __wakeup() {
        _socket = null;
    }

    /**
     * Connect to the SMTP server.
     *
     * This method tries to connect only in case there is no open
     * connection available already.
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
        return _socket != null && _socket.isConnected();
    }

    /**
     * Disconnect from the SMTP server.
     *
     * This method tries to disconnect only in case there is an open
     * connection available.
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
     *         "code": "250",
     *         "message": "mail.example.com"
     *     ],
     *     [
     *         "code": "250",
     *         "message": "PIPELINING"
     *     ],
     *     [
     *         "code": "250",
     *         "message": "8BITMIME"
     *     ],
     *     // etc...
     * ]
     * ```
     */
    array getLastResponse(): array
    {
        return _lastResponse;
    }

    /**
     * Send mail
     *
     * @param uim.cake.mailers.Message $message Message instance
     * @return array{headers: string, message: string}
     * @throws uim.cake.Network\exceptions.SocketException
     */
    function send(Message $message): array
    {
        this.checkRecipient($message);

        if (!this.connected()) {
            _connect();
            _auth();
        } else {
            _smtpSend("RSET");
        }

        _sendRcpt($message);
        _sendData($message);

        if (!_config["keepAlive"]) {
            _disconnect();
        }

        return _content;
    }

    /**
     * Parses and stores the response lines in `"code": "message"` format.
     *
     * @param array<string> $responseLines Response lines to parse.
     */
    protected void _bufferResponseLines(array $responseLines) {
        $response = [];
        foreach ($responseLines as $responseLine) {
            if (preg_match("/^(\d{3})(?:[ -]+(.*))?$/", $responseLine, $match)) {
                $response[] = [
                    "code": $match[1],
                    "message": $match[2] ?? null,
                ];
            }
        }
        _lastResponse = array_merge(_lastResponse, $response);
    }

    /**
     * Parses the last response line and extract the preferred authentication type.
     */
    protected void _parseAuthType() {
        this.authType = null;

        $auth = "";
        foreach (_lastResponse as $line) {
            if (strlen($line["message"]) == 0 || substr($line["message"], 0, 5) == "AUTH ") {
                $auth = $line["message"];
                break;
            }
        }

        if (strpos($auth, self::AUTH_PLAIN) != false) {
            this.authType = self::AUTH_PLAIN;

            return;
        }

        if (strpos($auth, self::AUTH_LOGIN) != false) {
            this.authType = self::AUTH_LOGIN;

            return;
        }
    }

    /**
     * Connect to SMTP Server
     *
     * @return void
     * @throws uim.cake.Network\exceptions.SocketException
     */
    protected void _connect() {
        _generateSocket();
        if (!_socket().connect()) {
            throw new SocketException("Unable to connect to SMTP server.");
        }
        _smtpSend(null, "220");

        $config = _config;

        $host = "localhost";
        if (isset($config["client"])) {
            if (empty($config["client"])) {
                throw new SocketException("Cannot use an empty client name.");
            }
            $host = $config["client"];
        } else {
            /** @var string $httpHost */
            $httpHost = env("HTTP_HOST");
            if ($httpHost) {
                [$host] = explode(":", $httpHost);
            }
        }

        try {
            _smtpSend("EHLO {$host}", "250");
            if ($config["tls"]) {
                _smtpSend("STARTTLS", "220");
                _socket().enableCrypto("tls");
                _smtpSend("EHLO {$host}", "250");
            }
        } catch (SocketException $e) {
            if ($config["tls"]) {
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

        _parseAuthType();
    }

    /**
     * Send authentication
     *
     * @return void
     * @throws uim.cake.Network\exceptions.SocketException
     */
    protected void _auth() {
        if (!isset(_config["username"], _config["password"])) {
            return;
        }

        $username = _config["username"];
        $password = _config["password"];
        if (empty(this.authType)) {
            $replyCode = _authPlain($username, $password);
            if ($replyCode == "235") {
                return;
            }

            _authLogin($username, $password);

            return;
        }

        if (this.authType == self::AUTH_PLAIN) {
            _authPlain($username, $password);

            return;
        }

        if (this.authType == self::AUTH_LOGIN) {
            _authLogin($username, $password);

            return;
        }
    }

    /**
     * Authenticate using AUTH PLAIN mechanism.
     *
     * @param string $username Username.
     * @param string $password Password.
     * @return string|null Response code for the command.
     */
    protected function _authPlain(string $username, string $password): ?string
    {
        return _smtpSend(
            sprintf(
                "AUTH PLAIN %s",
                base64_encode(chr(0) . $username . chr(0) . $password)
            ),
            "235|504|534|535"
        );
    }

    /**
     * Authenticate using AUTH LOGIN mechanism.
     *
     * @param string $username Username.
     * @param string $password Password.
     */
    protected void _authLogin(string $username, string $password) {
        $replyCode = _smtpSend("AUTH LOGIN", "334|500|502|504");
        if ($replyCode == "334") {
            try {
                _smtpSend(base64_encode($username), "334");
            } catch (SocketException $e) {
                throw new SocketException("SMTP server did not accept the username.", null, $e);
            }
            try {
                _smtpSend(base64_encode($password), "235");
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
     * @param string $message The email address to send with the command.
     */
    protected string _prepareFromCmd(string $message) {
        return "MAIL FROM:<" ~ $message ~ ">";
    }

    /**
     * Prepares the `RCPT TO` SMTP command.
     *
     * @param string $message The email address to send with the command.
     */
    protected string _prepareRcptCmd(string $message) {
        return "RCPT TO:<" ~ $message ~ ">";
    }

    /**
     * Prepares the `from` email address.
     *
     * @param uim.cake.mailers.Message $message Message instance
     */
    protected array _prepareFromAddress(Message $message): array
    {
        $from = $message.getReturnPath();
        if (empty($from)) {
            $from = $message.getFrom();
        }

        return $from;
    }

    /**
     * Prepares the recipient email addresses.
     *
     * @param uim.cake.mailers.Message $message Message instance
     */
    protected array _prepareRecipientAddresses(Message $message): array
    {
        $to = $message.getTo();
        $cc = $message.getCc();
        $bcc = $message.getBcc();

        return array_merge(array_keys($to), array_keys($cc), array_keys($bcc));
    }

    /**
     * Prepares the message body.
     *
     * @param uim.cake.mailers.Message $message Message instance
     */
    protected string _prepareMessage(Message $message) {
        $lines = $message.getBody();
        $messages = [];
        foreach ($lines as $line) {
            if (!empty($line) && ($line[0] == ".")) {
                $messages[] = "." ~ $line;
            } else {
                $messages[] = $line;
            }
        }

        return implode("\r\n", $messages);
    }

    /**
     * Send emails
     *
     * @param uim.cake.mailers.Message $message Message instance
     * @throws uim.cake.Network\exceptions.SocketException
     */
    protected void _sendRcpt(Message $message) {
        $from = _prepareFromAddress($message);
        _smtpSend(_prepareFromCmd(key($from)));

        $messages = _prepareRecipientAddresses($message);
        foreach ($messages as $mail) {
            _smtpSend(_prepareRcptCmd($mail));
        }
    }

    /**
     * Send Data
     *
     * @param uim.cake.mailers.Message $message Message instance
     * @return void
     * @throws uim.cake.Network\exceptions.SocketException
     */
    protected void _sendData(Message $message) {
        _smtpSend("DATA", "354");

        $headers = $message.getHeadersString([
            "from",
            "sender",
            "replyTo",
            "readReceipt",
            "to",
            "cc",
            "subject",
            "returnPath",
        ]);
        $message = _prepareMessage($message);

        _smtpSend($headers ~ "\r\n\r\n" ~ $message ~ "\r\n\r\n\r\n.");
        _content = ["headers": $headers, "message": $message];
    }

    /**
     * Disconnect
     *
     * @return void
     * @throws uim.cake.Network\exceptions.SocketException
     */
    protected void _disconnect() {
        _smtpSend("QUIT", false);
        _socket().disconnect();
        this.authType = null;
    }

    /**
     * Helper method to generate socket
     *
     * @return void
     * @throws uim.cake.Network\exceptions.SocketException
     */
    protected void _generateSocket() {
        _socket = new Socket(_config);
    }

    /**
     * Protected method for sending data to SMTP connection
     *
     * @param string|null $data Data to be sent to SMTP server
     * @param string|false $checkCode Code to check for in server response, false to skip
     * @return string|null The matched code, or null if nothing matched
     * @throws uim.cake.Network\exceptions.SocketException
     */
    protected function _smtpSend(?string $data, $checkCode = "250"): ?string
    {
        _lastResponse = [];

        if ($data != null) {
            _socket().write($data ~ "\r\n");
        }

        $timeout = _config["timeout"];

        while ($checkCode != false) {
            $response = "";
            $startTime = time();
            while (substr($response, -2) != "\r\n" && (time() - $startTime < $timeout)) {
                $bytes = _socket().read();
                if ($bytes == null) {
                    break;
                }
                $response .= $bytes;
            }
            // Catch empty or malformed responses.
            if (substr($response, -2) != "\r\n") {
                // Use response message or assume operation timed out.
                throw new SocketException($response ?: "SMTP timeout.");
            }
            $responseLines = explode("\r\n", rtrim($response, "\r\n"));
            $response = end($responseLines);

            _bufferResponseLines($responseLines);

            if (preg_match("/^(" ~ $checkCode ~ ")(.)/", $response, $code)) {
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
     * @return uim.cake.Network\Socket
     * @throws \RuntimeException If socket is not set.
     */
    protected function _socket(): Socket
    {
        if (_socket == null) {
            throw new RuntimeException("Socket is null, but must be set.");
        }

        return _socket;
    }
}
