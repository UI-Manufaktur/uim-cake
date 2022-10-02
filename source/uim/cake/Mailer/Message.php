module uim.cake.Mailer;

import uim.cake.core.Configure;
import uim.cake.core.Exception\CakeException;
import uim.cake.Http\Client\FormDataPart;
import uim.cake.Utility\Hash;
import uim.cake.Utility\Security;
import uim.cake.Utility\Text;
use Closure;
use InvalidArgumentException;
use JsonSerializable;
use Psr\Http\Message\UploadedFileInterface;
use Serializable;
use SimpleXMLElement;

/**
 * Email message class.
 *
 * This class is used for sending Internet Message Format based
 * on the standard outlined in https://www.rfc-editor.org/rfc/rfc2822.txt
 */
class Message : JsonSerializable, Serializable
{
    /**
     * Line length - no should more - RFC 2822 - 2.1.1
     *
     * @var int
     */
    public const LINE_LENGTH_SHOULD = 78;

    /**
     * Line length - no must more - RFC 2822 - 2.1.1
     *
     * @var int
     */
    public const LINE_LENGTH_MUST = 998;

    /**
     * Type of message - HTML
     *
     * @var string
     */
    public const MESSAGE_HTML = 'html';

    /**
     * Type of message - TEXT
     *
     * @var string
     */
    public const MESSAGE_TEXT = 'text';

    /**
     * Type of message - BOTH
     *
     * @var string
     */
    public const MESSAGE_BOTH = 'both';

    /**
     * Holds the regex pattern for email validation
     *
     * @var string
     */
    public const EMAIL_PATTERN = '/^((?:[\p{L}0-9.!#$%&\'*+\/=?^_`{|}~-]+)*@[\p{L}0-9-._]+)$/ui';

    /**
     * Recipient of the email
     *
     * @var array
     */
    protected $to = [];

    /**
     * The mail which the email is sent from
     *
     * @var array
     */
    protected $from = [];

    /**
     * The sender email
     *
     * @var array
     */
    protected $sender = [];

    /**
     * List of email(s) that the recipient will reply to
     *
     * @var array
     */
    protected $replyTo = [];

    /**
     * The read receipt email
     *
     * @var array
     */
    protected $readReceipt = [];

    /**
     * The mail that will be used in case of any errors like
     * - Remote mailserver down
     * - Remote user has exceeded his quota
     * - Unknown user
     *
     * @var array
     */
    protected $returnPath = [];

    /**
     * Carbon Copy
     *
     * List of email's that should receive a copy of the email.
     * The Recipient WILL be able to see this list
     *
     * @var array
     */
    protected $cc = [];

    /**
     * Blind Carbon Copy
     *
     * List of email's that should receive a copy of the email.
     * The Recipient WILL NOT be able to see this list
     *
     * @var array
     */
    protected $bcc = [];

    /**
     * Message ID
     *
     * @var string|bool
     */
    protected myMessageId = true;

    /**
     * Domain for messageId generation.
     * Needs to be manually set for CLI mailing as env('HTTP_HOST') is empty
     *
     * @var string
     */
    protected $domain = '';

    /**
     * The subject of the email
     *
     * @var string
     */
    protected $subject = '';

    /**
     * Associative array of a user defined headers
     * Keys will be prefixed 'X-' as per RFC2822 Section 4.7.5
     *
     * @var array
     */
    protected $headers = [];

    /**
     * Text message
     *
     * @var string
     */
    protected $textMessage = '';

    /**
     * Html message
     *
     * @var string
     */
    protected $htmlMessage = '';

    /**
     * Final message to send
     *
     * @var array
     */
    protected myMessage = [];

    /**
     * Available formats to be sent.
     *
     * @var array<string>
     */
    protected $emailFormatAvailable = [self::MESSAGE_TEXT, self::MESSAGE_HTML, self::MESSAGE_BOTH];

    /**
     * What format should the email be sent in
     *
     * @var string
     */
    protected $emailFormat = self::MESSAGE_TEXT;

    /**
     * Charset the email body is sent in
     *
     * @var string
     */
    protected $charset = 'utf-8';

    /**
     * Charset the email header is sent in
     * If null, the $charset property will be used as default
     *
     * @var string|null
     */
    protected $headerCharset;

    /**
     * The email transfer encoding used.
     * If null, the $charset property is used for determined the transfer encoding.
     *
     * @var string|null
     */
    protected $transferEncoding;

    /**
     * Available encoding to be set for transfer.
     *
     * @var array<string>
     */
    protected $transferEncodingAvailable = [
        '7bit',
        '8bit',
        'base64',
        'binary',
        'quoted-printable',
    ];

    /**
     * The application wide charset, used to encode headers and body
     *
     * @var string|null
     */
    protected $appCharset;

    /**
     * List of files that should be attached to the email.
     *
     * Only absolute paths
     *
     * @var array<string, array>
     */
    protected $attachments = [];

    /**
     * If set, boundary to use for multipart mime messages
     *
     * @var string|null
     */
    protected $boundary;

    /**
     * Contains the optional priority of the email.
     *
     * @var int|null
     */
    protected $priority;

    /**
     * 8Bit character sets
     *
     * @var array<string>
     */
    protected $charset8bit = ['UTF-8', 'SHIFT_JIS'];

    /**
     * Define Content-Type charset name
     *
     * @var array<string, string>
     */
    protected myContentsTypeCharset = [
        'ISO-2022-JP-MS' => 'ISO-2022-JP',
    ];

    /**
     * Regex for email validation
     *
     * If null, filter_var() will be used. Use the emailPattern() method
     * to set a custom pattern.'
     *
     * @var string|null
     */
    protected $emailPattern = self::EMAIL_PATTERN;

    /**
     * Constructor
     *
     * @param array<string,mixed>|null myConfig Array of configs, or string to load configs from app.php
     */
    this(?array myConfig = null)
    {
        this.appCharset = Configure::read('App.encoding');
        if (this.appCharset !== null) {
            this.charset = this.appCharset;
        }
        this.domain = preg_replace('/\:\d+$/', '', (string)env('HTTP_HOST'));
        if (empty(this.domain)) {
            this.domain = php_uname('n');
        }

        if (myConfig) {
            this.setConfig(myConfig);
        }
    }

    /**
     * Sets "from" address.
     *
     * @param array|string $email String with email,
     *   Array with email as key, name as value or email as value (without name)
     * @param string|null myName Name
     * @return this
     * @throws \InvalidArgumentException
     */
    auto setFrom($email, ?string myName = null)
    {
        return this.setEmailSingle('from', $email, myName, 'From requires only 1 email address.');
    }

    /**
     * Gets "from" address.
     *
     * @return array
     */
    auto getFrom(): array
    {
        return this.from;
    }

    /**
     * Sets the "sender" address. See RFC link below for full explanation.
     *
     * @param array|string $email String with email,
     *   Array with email as key, name as value or email as value (without name)
     * @param string|null myName Name
     * @return this
     * @throws \InvalidArgumentException
     * @link https://tools.ietf.org/html/rfc2822.html#section-3.6.2
     */
    auto setSender($email, ?string myName = null)
    {
        return this.setEmailSingle('sender', $email, myName, 'Sender requires only 1 email address.');
    }

    /**
     * Gets the "sender" address. See RFC link below for full explanation.
     *
     * @return array
     * @link https://tools.ietf.org/html/rfc2822.html#section-3.6.2
     */
    auto getSender(): array
    {
        return this.sender;
    }

    /**
     * Sets "Reply-To" address.
     *
     * @param array|string $email String with email,
     *   Array with email as key, name as value or email as value (without name)
     * @param string|null myName Name
     * @return this
     * @throws \InvalidArgumentException
     */
    auto setReplyTo($email, ?string myName = null)
    {
        return this.setEmail('replyTo', $email, myName);
    }

    /**
     * Gets "Reply-To" address.
     *
     * @return array
     */
    auto getReplyTo(): array
    {
        return this.replyTo;
    }

    /**
     * Add "Reply-To" address.
     *
     * @param array|string $email String with email,
     *   Array with email as key, name as value or email as value (without name)
     * @param string|null myName Name
     * @return this
     */
    function addReplyTo($email, ?string myName = null)
    {
        return this.addEmail('replyTo', $email, myName);
    }

    /**
     * Sets Read Receipt (Disposition-Notification-To header).
     *
     * @param array|string $email String with email,
     *   Array with email as key, name as value or email as value (without name)
     * @param string|null myName Name
     * @return this
     * @throws \InvalidArgumentException
     */
    auto setReadReceipt($email, ?string myName = null)
    {
        return this.setEmailSingle(
            'readReceipt',
            $email,
            myName,
            'Disposition-Notification-To requires only 1 email address.'
        );
    }

    /**
     * Gets Read Receipt (Disposition-Notification-To header).
     *
     * @return array
     */
    auto getReadReceipt(): array
    {
        return this.readReceipt;
    }

    /**
     * Sets return path.
     *
     * @param array|string $email String with email,
     *   Array with email as key, name as value or email as value (without name)
     * @param string|null myName Name
     * @return this
     * @throws \InvalidArgumentException
     */
    auto setReturnPath($email, ?string myName = null)
    {
        return this.setEmailSingle('returnPath', $email, myName, 'Return-Path requires only 1 email address.');
    }

    /**
     * Gets return path.
     *
     * @return array
     */
    auto getReturnPath(): array
    {
        return this.returnPath;
    }

    /**
     * Sets "to" address.
     *
     * @param array|string $email String with email,
     *   Array with email as key, name as value or email as value (without name)
     * @param string|null myName Name
     * @return this
     */
    auto setTo($email, ?string myName = null)
    {
        return this.setEmail('to', $email, myName);
    }

    /**
     * Gets "to" address
     *
     * @return array
     */
    auto getTo(): array
    {
        return this.to;
    }

    /**
     * Add "To" address.
     *
     * @param array|string $email String with email,
     *   Array with email as key, name as value or email as value (without name)
     * @param string|null myName Name
     * @return this
     */
    function addTo($email, ?string myName = null)
    {
        return this.addEmail('to', $email, myName);
    }

    /**
     * Sets "cc" address.
     *
     * @param array|string $email String with email,
     *   Array with email as key, name as value or email as value (without name)
     * @param string|null myName Name
     * @return this
     */
    auto setCc($email, ?string myName = null)
    {
        return this.setEmail('cc', $email, myName);
    }

    /**
     * Gets "cc" address.
     *
     * @return array
     */
    auto getCc(): array
    {
        return this.cc;
    }

    /**
     * Add "cc" address.
     *
     * @param array|string $email String with email,
     *   Array with email as key, name as value or email as value (without name)
     * @param string|null myName Name
     * @return this
     */
    function addCc($email, ?string myName = null)
    {
        return this.addEmail('cc', $email, myName);
    }

    /**
     * Sets "bcc" address.
     *
     * @param array|string $email String with email,
     *   Array with email as key, name as value or email as value (without name)
     * @param string|null myName Name
     * @return this
     */
    auto setBcc($email, ?string myName = null)
    {
        return this.setEmail('bcc', $email, myName);
    }

    /**
     * Gets "bcc" address.
     *
     * @return array
     */
    auto getBcc(): array
    {
        return this.bcc;
    }

    /**
     * Add "bcc" address.
     *
     * @param array|string $email String with email,
     *   Array with email as key, name as value or email as value (without name)
     * @param string|null myName Name
     * @return this
     */
    function addBcc($email, ?string myName = null)
    {
        return this.addEmail('bcc', $email, myName);
    }

    /**
     * Charset setter.
     *
     * @param string $charset Character set.
     * @return this
     */
    auto setCharset(string $charset)
    {
        this.charset = $charset;

        return this;
    }

    /**
     * Charset getter.
     *
     * @return string Charset
     */
    auto getCharset(): string
    {
        return this.charset;
    }

    /**
     * HeaderCharset setter.
     *
     * @param string|null $charset Character set.
     * @return this
     */
    auto setHeaderCharset(?string $charset)
    {
        this.headerCharset = $charset;

        return this;
    }

    /**
     * HeaderCharset getter.
     *
     * @return string Charset
     */
    auto getHeaderCharset(): string
    {
        return this.headerCharset ?: this.charset;
    }

    /**
     * TransferEncoding setter.
     *
     * @param string|null $encoding Encoding set.
     * @return this
     * @throws \InvalidArgumentException
     */
    auto setTransferEncoding(?string $encoding)
    {
        if ($encoding !== null) {
            $encoding = strtolower($encoding);
            if (!in_array($encoding, this.transferEncodingAvailable, true)) {
                throw new InvalidArgumentException(
                    sprintf(
                        'Transfer encoding not available. Can be : %s.',
                        implode(', ', this.transferEncodingAvailable)
                    )
                );
            }
        }

        this.transferEncoding = $encoding;

        return this;
    }

    /**
     * TransferEncoding getter.
     *
     * @return string|null Encoding
     */
    auto getTransferEncoding(): ?string
    {
        return this.transferEncoding;
    }

    /**
     * EmailPattern setter/getter
     *
     * @param string|null $regex The pattern to use for email address validation,
     *   null to unset the pattern and make use of filter_var() instead.
     * @return this
     */
    auto setEmailPattern(?string $regex)
    {
        this.emailPattern = $regex;

        return this;
    }

    /**
     * EmailPattern setter/getter
     *
     * @return string|null
     */
    auto getEmailPattern(): ?string
    {
        return this.emailPattern;
    }

    /**
     * Set email
     *
     * @param string $varName Property name
     * @param array|string $email String with email,
     *   Array with email as key, name as value or email as value (without name)
     * @param string|null myName Name
     * @return this
     * @throws \InvalidArgumentException
     */
    protected auto setEmail(string $varName, $email, ?string myName)
    {
        if (!is_array($email)) {
            this.validateEmail($email, $varName);
            this.{$varName} = [$email => myName ?? $email];

            return this;
        }
        $list = [];
        foreach ($email as myKey => myValue) {
            if (is_int(myKey)) {
                myKey = myValue;
            }
            this.validateEmail(myKey, $varName);
            $list[myKey] = myValue ?? myKey;
        }
        this.{$varName} = $list;

        return this;
    }

    /**
     * Validate email address
     *
     * @param string $email Email address to validate
     * @param string $context Which property was set
     * @return void
     * @throws \InvalidArgumentException If email address does not validate
     */
    protected auto validateEmail(string $email, string $context): void
    {
        if (this.emailPattern === null) {
            if (filter_var($email, FILTER_VALIDATE_EMAIL)) {
                return;
            }
        } elseif (preg_match(this.emailPattern, $email)) {
            return;
        }

        $context = ltrim($context, '_');
        if ($email === '') {
            throw new InvalidArgumentException(sprintf('The email set for "%s" is empty.', $context));
        }
        throw new InvalidArgumentException(sprintf('Invalid email set for "%s". You passed "%s".', $context, $email));
    }

    /**
     * Set only 1 email
     *
     * @param string $varName Property name
     * @param array|string $email String with email,
     *   Array with email as key, name as value or email as value (without name)
     * @param string|null myName Name
     * @param string $throwMessage Exception message
     * @return this
     * @throws \InvalidArgumentException
     */
    protected auto setEmailSingle(string $varName, $email, ?string myName, string $throwMessage)
    {
        if ($email === []) {
            this.{$varName} = $email;

            return this;
        }

        $current = this.{$varName};
        this.setEmail($varName, $email, myName);
        if (count(this.{$varName}) !== 1) {
            this.{$varName} = $current;
            throw new InvalidArgumentException($throwMessage);
        }

        return this;
    }

    /**
     * Add email
     *
     * @param string $varName Property name
     * @param array|string $email String with email,
     *   Array with email as key, name as value or email as value (without name)
     * @param string|null myName Name
     * @return this
     * @throws \InvalidArgumentException
     */
    protected auto addEmail(string $varName, $email, ?string myName)
    {
        if (!is_array($email)) {
            this.validateEmail($email, $varName);
            if (myName === null) {
                myName = $email;
            }
            this.{$varName}[$email] = myName;

            return this;
        }
        $list = [];
        foreach ($email as myKey => myValue) {
            if (is_int(myKey)) {
                myKey = myValue;
            }
            this.validateEmail(myKey, $varName);
            $list[myKey] = myValue;
        }
        this.{$varName} = array_merge(this.{$varName}, $list);

        return this;
    }

    /**
     * Sets subject.
     *
     * @param string $subject Subject string.
     * @return this
     */
    auto setSubject(string $subject)
    {
        this.subject = this.encodeForHeader($subject);

        return this;
    }

    /**
     * Gets subject.
     *
     * @return string
     */
    auto getSubject(): string
    {
        return this.subject;
    }

    /**
     * Get original subject without encoding
     *
     * @return string Original subject
     */
    auto getOriginalSubject(): string
    {
        return this.decodeForHeader(this.subject);
    }

    /**
     * Sets headers for the message
     *
     * @param array $headers Associative array containing headers to be set.
     * @return this
     */
    auto setHeaders(array $headers)
    {
        this.headers = $headers;

        return this;
    }

    /**
     * Add header for the message
     *
     * @param array $headers Headers to set.
     * @return this
     */
    function addHeaders(array $headers)
    {
        this.headers = Hash::merge(this.headers, $headers);

        return this;
    }

    /**
     * Get list of headers
     *
     * ### Includes:
     *
     * - `from`
     * - `replyTo`
     * - `readReceipt`
     * - `returnPath`
     * - `to`
     * - `cc`
     * - `bcc`
     * - `subject`
     *
     * @param array<string> $include List of headers.
     * @return array<string>
     */
    auto getHeaders(array $include = []): array
    {
        this.createBoundary();

        if ($include === array_values($include)) {
            $include = array_fill_keys($include, true);
        }
        $defaults = array_fill_keys(
            [
                'from', 'sender', 'replyTo', 'readReceipt', 'returnPath',
                'to', 'cc', 'bcc', 'subject',
            ],
            false
        );
        $include += $defaults;

        $headers = [];
        $relation = [
            'from' => 'From',
            'replyTo' => 'Reply-To',
            'readReceipt' => 'Disposition-Notification-To',
            'returnPath' => 'Return-Path',
            'to' => 'To',
            'cc' => 'Cc',
            'bcc' => 'Bcc',
        ];
        $headersMultipleEmails = ['to', 'cc', 'bcc', 'replyTo'];
        foreach ($relation as $var => $header) {
            if ($include[$var]) {
                if (in_array($var, $headersMultipleEmails)) {
                    $headers[$header] = implode(', ', this.formatAddress(this.{$var}));
                } else {
                    $headers[$header] = (string)current(this.formatAddress(this.{$var}));
                }
            }
        }
        if ($include['sender']) {
            if (key(this.sender) === key(this.from)) {
                $headers['Sender'] = '';
            } else {
                $headers['Sender'] = (string)current(this.formatAddress(this.sender));
            }
        }

        $headers += this.headers;
        if (!isset($headers['Date'])) {
            $headers['Date'] = date(DATE_RFC2822);
        }
        if (this.messageId !== false) {
            if (this.messageId === true) {
                this.messageId = '<' . str_replace('-', '', Text::uuid()) . '@' . this.domain . '>';
            }

            $headers['Message-ID'] = this.messageId;
        }

        if (this.priority) {
            $headers['X-Priority'] = (string)this.priority;
        }

        if ($include['subject']) {
            $headers['Subject'] = this.subject;
        }

        $headers['MIME-Version'] = '1.0';
        if (this.attachments) {
            $headers['Content-Type'] = 'multipart/mixed; boundary="' . (string)this.boundary . '"';
        } elseif (this.emailFormat === static::MESSAGE_BOTH) {
            $headers['Content-Type'] = 'multipart/alternative; boundary="' . (string)this.boundary . '"';
        } elseif (this.emailFormat === static::MESSAGE_TEXT) {
            $headers['Content-Type'] = 'text/plain; charset=' . this.getContentTypeCharset();
        } elseif (this.emailFormat === static::MESSAGE_HTML) {
            $headers['Content-Type'] = 'text/html; charset=' . this.getContentTypeCharset();
        }
        $headers['Content-Transfer-Encoding'] = this.getContentTransferEncoding();

        return $headers;
    }

    /**
     * Get headers as string.
     *
     * @param array<string> $include List of headers.
     * @param string $eol End of line string for concatenating headers.
     * @param \Closure|null $callback Callback to run each header value through before stringifying.
     * @return string
     * @see Message::getHeaders()
     */
    auto getHeadersString(array $include = [], string $eol = "\r\n", ?Closure $callback = null): string
    {
        $lines = this.getHeaders($include);

        if ($callback) {
            $lines = array_map($callback, $lines);
        }

        $headers = [];
        foreach ($lines as myKey => myValue) {
            if (empty(myValue) && myValue !== '0') {
                continue;
            }

            foreach ((array)myValue as $val) {
                $headers[] = myKey . ': ' . $val;
            }
        }

        return implode($eol, $headers);
    }

    /**
     * Format addresses
     *
     * If the address contains non alphanumeric/whitespace characters, it will
     * be quoted as characters like `:` and `,` are known to cause issues
     * in address header fields.
     *
     * @param array $address Addresses to format.
     * @return array
     */
    protected auto formatAddress(array $address): array
    {
        $return = [];
        foreach ($address as $email => myAlias) {
            if ($email === myAlias) {
                $return[] = $email;
            } else {
                $encoded = this.encodeForHeader(myAlias);
                if ($encoded === myAlias && preg_match('/[^a-z0-9 ]/i', $encoded)) {
                    $encoded = '"' . str_replace('"', '\"', $encoded) . '"';
                }
                $return[] = sprintf('%s <%s>', $encoded, $email);
            }
        }

        return $return;
    }

    /**
     * Sets email format.
     *
     * @param string $format Formatting string.
     * @return this
     * @throws \InvalidArgumentException
     */
    auto setEmailFormat(string $format)
    {
        if (!in_array($format, this.emailFormatAvailable, true)) {
            throw new InvalidArgumentException('Format not available.');
        }
        this.emailFormat = $format;

        return this;
    }

    /**
     * Gets email format.
     *
     * @return string
     */
    auto getEmailFormat(): string
    {
        return this.emailFormat;
    }

    /**
     * Gets the body types that are in this email message
     *
     * @return array Array of types. Valid types are Email::MESSAGE_TEXT and Email::MESSAGE_HTML
     */
    auto getBodyTypes(): array
    {
        $format = this.emailFormat;

        if ($format === static::MESSAGE_BOTH) {
            return [static::MESSAGE_HTML, static::MESSAGE_TEXT];
        }

        return [$format];
    }

    /**
     * Sets message ID.
     *
     * @param string|bool myMessage True to generate a new Message-ID, False to ignore (not send in email),
     *   String to set as Message-ID.
     * @return this
     * @throws \InvalidArgumentException
     */
    auto setMessageId(myMessage)
    {
        if (is_bool(myMessage)) {
            this.messageId = myMessage;
        } else {
            if (!preg_match('/^\<.+@.+\>$/', myMessage)) {
                throw new InvalidArgumentException(
                    'Invalid format to Message-ID. The text should be something like "<uuid@server.com>"'
                );
            }
            this.messageId = myMessage;
        }

        return this;
    }

    /**
     * Gets message ID.
     *
     * @return string|bool
     */
    auto getMessageId() {
        return this.messageId;
    }

    /**
     * Sets domain.
     *
     * Domain as top level (the part after @).
     *
     * @param string $domain Manually set the domain for CLI mailing.
     * @return this
     */
    auto setDomain(string $domain)
    {
        this.domain = $domain;

        return this;
    }

    /**
     * Gets domain.
     *
     * @return string
     */
    auto getDomain(): string
    {
        return this.domain;
    }

    /**
     * Add attachments to the email message
     *
     * Attachments can be defined in a few forms depending on how much control you need:
     *
     * Attach a single file:
     *
     * ```
     * this.setAttachments('path/to/file');
     * ```
     *
     * Attach a file with a different filename:
     *
     * ```
     * this.setAttachments(['custom_name.txt' => 'path/to/file.txt']);
     * ```
     *
     * Attach a file and specify additional properties:
     *
     * ```
     * this.setAttachments(['custom_name.png' => [
     *      'file' => 'path/to/file',
     *      'mimetype' => 'image/png',
     *      'contentId' => 'abc123',
     *      'contentDisposition' => false
     *    ]
     * ]);
     * ```
     *
     * Attach a file from string and specify additional properties:
     *
     * ```
     * this.setAttachments(['custom_name.png' => [
     *      'data' => file_get_contents('path/to/file'),
     *      'mimetype' => 'image/png'
     *    ]
     * ]);
     * ```
     *
     * The `contentId` key allows you to specify an inline attachment. In your email text, you
     * can use `<img src="cid:abc123"/>` to display the image inline.
     *
     * The `contentDisposition` key allows you to disable the `Content-Disposition` header, this can improve
     * attachment compatibility with outlook email clients.
     *
     * @param array $attachments Array of filenames.
     * @return this
     * @throws \InvalidArgumentException
     */
    auto setAttachments(array $attachments)
    {
        $attach = [];
        foreach ($attachments as myName => $fileInfo) {
            if (!is_array($fileInfo)) {
                $fileInfo = ['file' => $fileInfo];
            }
            if (!isset($fileInfo['file'])) {
                if (!isset($fileInfo['data'])) {
                    throw new InvalidArgumentException('No file or data specified.');
                }
                if (is_int(myName)) {
                    throw new InvalidArgumentException('No filename specified.');
                }
                $fileInfo['data'] = chunk_split(base64_encode($fileInfo['data']), 76, "\r\n");
            } elseif ($fileInfo['file'] instanceof UploadedFileInterface) {
                $fileInfo['mimetype'] = $fileInfo['file'].getClientMediaType();
                if (is_int(myName)) {
                    /** @var string myName */
                    myName = $fileInfo['file'].getClientFilename();
                }
            } elseif (is_string($fileInfo['file'])) {
                $fileName = $fileInfo['file'];
                $fileInfo['file'] = realpath($fileInfo['file']);
                if ($fileInfo['file'] === false || !file_exists($fileInfo['file'])) {
                    throw new InvalidArgumentException(sprintf('File not found: "%s"', $fileName));
                }
                if (is_int(myName)) {
                    myName = basename($fileInfo['file']);
                }
            } else {
                throw new InvalidArgumentException(sprintf(
                    'File must be a filepath or UploadedFileInterface instance. Found `%s` instead.',
                    gettype($fileInfo['file'])
                ));
            }
            if (
                !isset($fileInfo['mimetype'])
                && isset($fileInfo['file'])
                && is_string($fileInfo['file'])
                && function_exists('mime_content_type')
            ) {
                $fileInfo['mimetype'] = mime_content_type($fileInfo['file']);
            }
            if (!isset($fileInfo['mimetype'])) {
                $fileInfo['mimetype'] = 'application/octet-stream';
            }
            $attach[myName] = $fileInfo;
        }
        this.attachments = $attach;

        return this;
    }

    /**
     * Gets attachments to the email message.
     *
     * @return array<string, array> Array of attachments.
     */
    auto getAttachments(): array
    {
        return this.attachments;
    }

    /**
     * Add attachments
     *
     * @param array $attachments Array of filenames.
     * @return this
     * @throws \InvalidArgumentException
     * @see \Cake\Mailer\Email::setAttachments()
     */
    function addAttachments(array $attachments)
    {
        $current = this.attachments;
        this.setAttachments($attachments);
        this.attachments = array_merge($current, this.attachments);

        return this;
    }

    /**
     * Get generated message body as array.
     *
     * @return array
     */
    auto getBody() {
        if (empty(this.message)) {
            this.message = this.generateMessage();
        }

        return this.message;
    }

    /**
     * Get generated body as string.
     *
     * @param string $eol End of line string for imploding.
     * @return string
     * @see Message::getBody()
     */
    auto getBodyString(string $eol = "\r\n"): string
    {
        $lines = this.getBody();

        return implode($eol, $lines);
    }

    /**
     * Create unique boundary identifier
     *
     * @return void
     */
    protected auto createBoundary(): void
    {
        if (
            this.boundary === null &&
            (
                this.attachments ||
                this.emailFormat === static::MESSAGE_BOTH
            )
        ) {
            this.boundary = md5(Security::randomBytes(16));
        }
    }

    /**
     * Generate full message.
     *
     * @return array<string>
     */
    protected auto generateMessage(): array
    {
        this.createBoundary();
        $msg = [];

        myContentsIds = array_filter((array)Hash::extract(this.attachments, '{s}.contentId'));
        $hasInlineAttachments = count(myContentsIds) > 0;
        $hasAttachments = !empty(this.attachments);
        $hasMultipleTypes = this.emailFormat === static::MESSAGE_BOTH;
        $multiPart = ($hasAttachments || $hasMultipleTypes);

        /** @var string $boundary */
        $boundary = this.boundary;
        $relBoundary = $textBoundary = $boundary;

        if ($hasInlineAttachments) {
            $msg[] = '--' . $boundary;
            $msg[] = 'Content-Type: multipart/related; boundary="rel-' . $boundary . '"';
            $msg[] = '';
            $relBoundary = $textBoundary = 'rel-' . $boundary;
        }

        if ($hasMultipleTypes && $hasAttachments) {
            $msg[] = '--' . $relBoundary;
            $msg[] = 'Content-Type: multipart/alternative; boundary="alt-' . $boundary . '"';
            $msg[] = '';
            $textBoundary = 'alt-' . $boundary;
        }

        if (
            this.emailFormat === static::MESSAGE_TEXT
            || this.emailFormat === static::MESSAGE_BOTH
        ) {
            if ($multiPart) {
                $msg[] = '--' . $textBoundary;
                $msg[] = 'Content-Type: text/plain; charset=' . this.getContentTypeCharset();
                $msg[] = 'Content-Transfer-Encoding: ' . this.getContentTransferEncoding();
                $msg[] = '';
            }
            myContents = explode("\n", this.textMessage);
            $msg = array_merge($msg, myContents);
            $msg[] = '';
            $msg[] = '';
        }

        if (
            this.emailFormat === static::MESSAGE_HTML
            || this.emailFormat === static::MESSAGE_BOTH
        ) {
            if ($multiPart) {
                $msg[] = '--' . $textBoundary;
                $msg[] = 'Content-Type: text/html; charset=' . this.getContentTypeCharset();
                $msg[] = 'Content-Transfer-Encoding: ' . this.getContentTransferEncoding();
                $msg[] = '';
            }
            myContents = explode("\n", this.htmlMessage);
            $msg = array_merge($msg, myContents);
            $msg[] = '';
            $msg[] = '';
        }

        if ($textBoundary !== $relBoundary) {
            $msg[] = '--' . $textBoundary . '--';
            $msg[] = '';
        }

        if ($hasInlineAttachments) {
            $attachments = this.attachInlineFiles($relBoundary);
            $msg = array_merge($msg, $attachments);
            $msg[] = '';
            $msg[] = '--' . $relBoundary . '--';
            $msg[] = '';
        }

        if ($hasAttachments) {
            $attachments = this.attachFiles($boundary);
            $msg = array_merge($msg, $attachments);
        }
        if ($hasAttachments || $hasMultipleTypes) {
            $msg[] = '';
            $msg[] = '--' . $boundary . '--';
            $msg[] = '';
        }

        return $msg;
    }

    /**
     * Attach non-embedded files by adding file contents inside boundaries.
     *
     * @param string|null $boundary Boundary to use. If null, will default to this.boundary
     * @return array<string> An array of lines to add to the message
     */
    protected auto attachFiles(?string $boundary = null): array
    {
        if ($boundary === null) {
            /** @var string $boundary */
            $boundary = this.boundary;
        }

        $msg = [];
        foreach (this.attachments as $filename => $fileInfo) {
            if (!empty($fileInfo['contentId'])) {
                continue;
            }
            myData = $fileInfo['data'] ?? this.readFile($fileInfo['file']);
            $hasDisposition = (
                !isset($fileInfo['contentDisposition']) ||
                $fileInfo['contentDisposition']
            );
            $part = new FormDataPart('', myData, '', this.getHeaderCharset());

            if ($hasDisposition) {
                $part.disposition('attachment');
                $part.filename($filename);
            }
            $part.transferEncoding('base64');
            $part.type($fileInfo['mimetype']);

            $msg[] = '--' . $boundary;
            $msg[] = (string)$part;
            $msg[] = '';
        }

        return $msg;
    }

    /**
     * Attach inline/embedded files to the message.
     *
     * @param string|null $boundary Boundary to use. If null, will default to this.boundary
     * @return array<string> An array of lines to add to the message
     */
    protected auto attachInlineFiles(?string $boundary = null): array
    {
        if ($boundary === null) {
            /** @var string $boundary */
            $boundary = this.boundary;
        }

        $msg = [];
        foreach (this.getAttachments() as $filename => $fileInfo) {
            if (empty($fileInfo['contentId'])) {
                continue;
            }
            myData = $fileInfo['data'] ?? this.readFile($fileInfo['file']);

            $msg[] = '--' . $boundary;
            $part = new FormDataPart('', myData, 'inline', this.getHeaderCharset());
            $part.type($fileInfo['mimetype']);
            $part.transferEncoding('base64');
            $part.contentId($fileInfo['contentId']);
            $part.filename($filename);
            $msg[] = (string)$part;
            $msg[] = '';
        }

        return $msg;
    }

    /**
     * Sets priority.
     *
     * @param int|null $priority 1 (highest) to 5 (lowest)
     * @return this
     */
    auto setPriority(?int $priority)
    {
        this.priority = $priority;

        return this;
    }

    /**
     * Gets priority.
     *
     * @return int|null
     */
    auto getPriority(): ?int
    {
        return this.priority;
    }

    /**
     * Sets the configuration for this instance.
     *
     * @param array<string, mixed> myConfig Config array.
     * @return this
     */
    auto setConfig(array myConfig)
    {
        $simpleMethods = [
            'from', 'sender', 'to', 'replyTo', 'readReceipt', 'returnPath',
            'cc', 'bcc', 'messageId', 'domain', 'subject', 'attachments',
            'emailFormat', 'emailPattern', 'charset', 'headerCharset',
        ];
        foreach ($simpleMethods as $method) {
            if (isset(myConfig[$method])) {
                this.{'set' . ucfirst($method)}(myConfig[$method]);
            }
        }

        if (isset(myConfig['headers'])) {
            this.setHeaders(myConfig['headers']);
        }

        return this;
    }

    /**
     * Set message body.
     *
     * @param array<string, string> myContents Content array with keys "text" and/or "html" with
     *   content string of respective type.
     * @return this
     */
    auto setBody(array myContents)
    {
        foreach (myContents as myType => $text) {
            if (!in_array(myType, this.emailFormatAvailable, true)) {
                throw new InvalidArgumentException(sprintf(
                    'Invalid message type: "%s". Valid types are: "text", "html".',
                    myType
                ));
            }

            $text = str_replace(["\r\n", "\r"], "\n", $text);
            $text = this.encodeString($text, this.getCharset());
            $text = this.wrap($text);
            $text = implode("\n", $text);
            $text = rtrim($text, "\n");

            $property = "{myType}Message";
            this.$property = $text;
        }

        this.boundary = null;
        this.message = [];

        return this;
    }

    /**
     * Set text body for message.
     *
     * @param string myContents Content string
     * @return this
     */
    auto setBodyText(string myContents)
    {
        this.setBody([static::MESSAGE_TEXT => myContents]);

        return this;
    }

    /**
     * Set HTML body for message.
     *
     * @param string myContents Content string
     * @return this
     */
    auto setBodyHtml(string myContents)
    {
        this.setBody([static::MESSAGE_HTML => myContents]);

        return this;
    }

    /**
     * Get text body of message.
     *
     * @return string
     */
    auto getBodyText() {
        return this.textMessage;
    }

    /**
     * Get HTML body of message.
     *
     * @return string
     */
    auto getBodyHtml() {
        return this.htmlMessage;
    }

    /**
     * Translates a string for one charset to another if the App.encoding value
     * differs and the mb_convert_encoding function exists
     *
     * @param string $text The text to be converted
     * @param string $charset the target encoding
     * @return string
     */
    protected auto encodeString(string $text, string $charset): string
    {
        if (this.appCharset === $charset) {
            return $text;
        }

        if (this.appCharset === null) {
            return mb_convert_encoding($text, $charset);
        }

        return mb_convert_encoding($text, $charset, this.appCharset);
    }

    /**
     * Wrap the message to follow the RFC 2822 - 2.1.1
     *
     * @param string|null myMessage Message to wrap
     * @param int $wrapLength The line length
     * @return array<string> Wrapped message
     */
    protected auto wrap(?string myMessage = null, int $wrapLength = self::LINE_LENGTH_MUST): array
    {
        if (myMessage === null || myMessage === '') {
            return [''];
        }
        myMessage = str_replace(["\r\n", "\r"], "\n", myMessage);
        $lines = explode("\n", myMessage);
        $formatted = [];
        $cut = ($wrapLength === static::LINE_LENGTH_MUST);

        foreach ($lines as $line) {
            if (empty($line) && $line !== '0') {
                $formatted[] = '';
                continue;
            }
            if (strlen($line) < $wrapLength) {
                $formatted[] = $line;
                continue;
            }
            if (!preg_match('/<[a-z]+.*>/i', $line)) {
                $formatted = array_merge(
                    $formatted,
                    explode("\n", Text::wordWrap($line, $wrapLength, "\n", $cut))
                );
                continue;
            }

            $tagOpen = false;
            $tmpLine = $tag = '';
            $tmpLineLength = 0;
            for ($i = 0, myCount = strlen($line); $i < myCount; $i++) {
                $char = $line[$i];
                if ($tagOpen) {
                    $tag .= $char;
                    if ($char === '>') {
                        $tagLength = strlen($tag);
                        if ($tagLength + $tmpLineLength < $wrapLength) {
                            $tmpLine .= $tag;
                            $tmpLineLength += $tagLength;
                        } else {
                            if ($tmpLineLength > 0) {
                                $formatted = array_merge(
                                    $formatted,
                                    explode("\n", Text::wordWrap(trim($tmpLine), $wrapLength, "\n", $cut))
                                );
                                $tmpLine = '';
                                $tmpLineLength = 0;
                            }
                            if ($tagLength > $wrapLength) {
                                $formatted[] = $tag;
                            } else {
                                $tmpLine = $tag;
                                $tmpLineLength = $tagLength;
                            }
                        }
                        $tag = '';
                        $tagOpen = false;
                    }
                    continue;
                }
                if ($char === '<') {
                    $tagOpen = true;
                    $tag = '<';
                    continue;
                }
                if ($char === ' ' && $tmpLineLength >= $wrapLength) {
                    $formatted[] = $tmpLine;
                    $tmpLineLength = 0;
                    continue;
                }
                $tmpLine .= $char;
                $tmpLineLength++;
                if ($tmpLineLength === $wrapLength) {
                    $nextChar = $line[$i + 1] ?? '';
                    if ($nextChar === ' ' || $nextChar === '<') {
                        $formatted[] = trim($tmpLine);
                        $tmpLine = '';
                        $tmpLineLength = 0;
                        if ($nextChar === ' ') {
                            $i++;
                        }
                    } else {
                        $lastSpace = strrpos($tmpLine, ' ');
                        if ($lastSpace === false) {
                            continue;
                        }
                        $formatted[] = trim(substr($tmpLine, 0, $lastSpace));
                        $tmpLine = substr($tmpLine, $lastSpace + 1);

                        $tmpLineLength = strlen($tmpLine);
                    }
                }
            }
            if (!empty($tmpLine)) {
                $formatted[] = $tmpLine;
            }
        }
        $formatted[] = '';

        return $formatted;
    }

    /**
     * Reset all the internal variables to be able to send out a new email.
     *
     * @return this
     */
    function reset() {
        this.to = [];
        this.from = [];
        this.sender = [];
        this.replyTo = [];
        this.readReceipt = [];
        this.returnPath = [];
        this.cc = [];
        this.bcc = [];
        this.messageId = true;
        this.subject = '';
        this.headers = [];
        this.textMessage = '';
        this.htmlMessage = '';
        this.message = [];
        this.emailFormat = static::MESSAGE_TEXT;
        this.priority = null;
        this.charset = 'utf-8';
        this.headerCharset = null;
        this.transferEncoding = null;
        this.attachments = [];
        this.emailPattern = static::EMAIL_PATTERN;

        return this;
    }

    /**
     * Encode the specified string using the current charset
     *
     * @param string $text String to encode
     * @return string Encoded string
     */
    protected auto encodeForHeader(string $text): string
    {
        if (this.appCharset === null) {
            return $text;
        }

        /** @var string $restore */
        $restore = mb_internal_encoding();
        mb_internal_encoding(this.appCharset);
        $return = mb_encode_mimeheader($text, this.getHeaderCharset(), 'B');
        mb_internal_encoding($restore);

        return $return;
    }

    /**
     * Decode the specified string
     *
     * @param string $text String to decode
     * @return string Decoded string
     */
    protected auto decodeForHeader(string $text): string
    {
        if (this.appCharset === null) {
            return $text;
        }

        /** @var string $restore */
        $restore = mb_internal_encoding();
        mb_internal_encoding(this.appCharset);
        $return = mb_decode_mimeheader($text);
        mb_internal_encoding($restore);

        return $return;
    }

    /**
     * Read the file contents and return a base64 version of the file contents.
     *
     * @param \Psr\Http\Message\UploadedFileInterface|string $file The absolute path to the file to read
     *   or UploadedFileInterface instance.
     * @return string File contents in base64 encoding
     */
    protected auto readFile($file): string
    {
        if (is_string($file)) {
            myContents = (string)file_get_contents($file);
        } else {
            myContents = (string)$file.getStream();
        }

        return chunk_split(base64_encode(myContents));
    }

    /**
     * Return the Content-Transfer Encoding value based
     * on the set transferEncoding or set charset.
     *
     * @return string
     */
    auto getContentTransferEncoding(): string
    {
        if (this.transferEncoding) {
            return this.transferEncoding;
        }

        $charset = strtoupper(this.charset);
        if (in_array($charset, this.charset8bit, true)) {
            return '8bit';
        }

        return '7bit';
    }

    /**
     * Return charset value for Content-Type.
     *
     * Checks fallback/compatibility types which include workarounds
     * for legacy japanese character sets.
     *
     * @return string
     */
    auto getContentTypeCharset(): string
    {
        $charset = strtoupper(this.charset);
        if (array_key_exists($charset, this.contentTypeCharset)) {
            return strtoupper(this.contentTypeCharset[$charset]);
        }

        return strtoupper(this.charset);
    }

    /**
     * Serializes the email object to a value that can be natively serialized and re-used
     * to clone this email instance.
     *
     * @return array Serializable array of configuration properties.
     * @throws \Exception When a view var object can not be properly serialized.
     */
    function jsonSerialize(): array
    {
        $properties = [
            'to', 'from', 'sender', 'replyTo', 'cc', 'bcc', 'subject',
            'returnPath', 'readReceipt', 'emailFormat', 'emailPattern', 'domain',
            'attachments', 'messageId', 'headers', 'appCharset', 'charset', 'headerCharset',
            'textMessage', 'htmlMessage',
        ];

        $array = [];
        foreach ($properties as $property) {
            $array[$property] = this.{$property};
        }

        array_walk($array['attachments'], function (&$item, myKey): void {
            if (!empty($item['file'])) {
                $item['data'] = this.readFile($item['file']);
                unset($item['file']);
            }
        });

        return array_filter($array, function ($i) {
            return $i !== null && !is_array($i) && !is_bool($i) && strlen($i) || !empty($i);
        });
    }

    /**
     * Configures an email instance object from serialized config.
     *
     * @param array<string, mixed> myConfig Email configuration array.
     * @return this
     */
    function createFromArray(array myConfig)
    {
        foreach (myConfig as $property => myValue) {
            this.{$property} = myValue;
        }

        return this;
    }

    /**
     * Serializes the Email object.
     *
     * @return string
     */
    function serialize(): string
    {
        $array = this.__serialize();

        return serialize($array);
    }

    /**
     * Magic method used for serializing the Message object.
     *
     * @return array
     */
    auto __serialize(): array
    {
        $array = this.jsonSerialize();
        array_walk_recursive($array, function (&$item, myKey): void {
            if ($item instanceof SimpleXMLElement) {
                $item = json_decode(json_encode((array)$item), true);
            }
        });

        /** @psalm-var array */
        return $array;
    }

    /**
     * Unserializes the Message object.
     *
     * @param string myData Serialized string.
     * @return void
     */
    function unserialize(myData)
    {
        $array = unserialize(myData);
        if (!is_array($array)) {
            throw new CakeException('Unable to unserialize message.');
        }

        this.createFromArray($array);
    }

    /**
     * Magic method used to rebuild the Message object.
     *
     * @param array myData Data array.
     * @return void
     */
    auto __unserialize(array myData): void
    {
        this.createFromArray(myData);
    }
}
