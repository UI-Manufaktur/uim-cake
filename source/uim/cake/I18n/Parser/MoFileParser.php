module uim.cake.I18n\Parser;

use RuntimeException;

/**
 * Parses file in MO format
 *
 * @copyright Copyright (c) 2010, Union of RAD http://union-of-rad.org (http://lithify.me/)
 * @copyright Copyright (c) 2014, Fabien Potencier https://github.com/symfony/Translation/blob/master/LICENSE
 */
class MoFileParser
{
    /**
     * Magic used for validating the format of a MO file as well as
     * detecting if the machine used to create that file was little endian.
     *
     * @var int
     */
    public const MO_LITTLE_ENDIAN_MAGIC = 0x950412de;

    /**
     * Magic used for validating the format of a MO file as well as
     * detecting if the machine used to create that file was big endian.
     *
     * @var int
     */
    public const MO_BIG_ENDIAN_MAGIC = 0xde120495;

    /**
     * The size of the header of a MO file in bytes.
     *
     * @var int
     */
    public const MO_HEADER_SIZE = 28;

    /**
     * Parses machine object (MO) format, independent of the machine's endian it
     * was created on. Both 32bit and 64bit systems are supported.
     *
     * @param string $file The file to be parsed.
     * @return array List of messages extracted from the file
     * @throws \RuntimeException If stream content has an invalid format.
     */
    function parse($file): array
    {
        $stream = fopen($file, 'rb');

        $stat = fstat($stream);

        if ($stat['size'] < self::MO_HEADER_SIZE) {
            throw new RuntimeException('Invalid format for MO translations file');
        }
        $magic = unpack('V1', fread($stream, 4));
        $magic = hexdec(substr(dechex(current($magic)), -8));

        if ($magic === self::MO_LITTLE_ENDIAN_MAGIC) {
            $isBigEndian = false;
        } elseif ($magic === self::MO_BIG_ENDIAN_MAGIC) {
            $isBigEndian = true;
        } else {
            throw new RuntimeException('Invalid format for MO translations file');
        }

        // offset formatRevision
        fread($stream, 4);

        myCount = this._readLong($stream, $isBigEndian);
        $offsetId = this._readLong($stream, $isBigEndian);
        $offsetTranslated = this._readLong($stream, $isBigEndian);

        // Offset to start of translations
        fread($stream, 8);
        myMessages = [];

        for ($i = 0; $i < myCount; $i++) {
            $pluralId = null;
            $context = null;
            $plurals = null;

            fseek($stream, $offsetId + $i * 8);

            $length = this._readLong($stream, $isBigEndian);
            $offset = this._readLong($stream, $isBigEndian);

            if ($length < 1) {
                continue;
            }

            fseek($stream, $offset);
            $singularId = fread($stream, $length);

            if (strpos($singularId, "\x04") !== false) {
                [$context, $singularId] = explode("\x04", $singularId);
            }

            if (strpos($singularId, "\000") !== false) {
                [$singularId, $pluralId] = explode("\000", $singularId);
            }

            fseek($stream, $offsetTranslated + $i * 8);
            $length = this._readLong($stream, $isBigEndian);
            $offset = this._readLong($stream, $isBigEndian);
            fseek($stream, $offset);
            $translated = fread($stream, $length);

            if ($pluralId !== null || strpos($translated, "\000") !== false) {
                $translated = explode("\000", $translated);
                $plurals = $pluralId !== null ? $translated : null;
                $translated = $translated[0];
            }

            $singular = $translated;
            if ($context !== null) {
                myMessages[$singularId]['_context'][$context] = $singular;
                if ($pluralId !== null) {
                    myMessages[$pluralId]['_context'][$context] = $plurals;
                }
                continue;
            }

            myMessages[$singularId]['_context'][''] = $singular;
            if ($pluralId !== null) {
                myMessages[$pluralId]['_context'][''] = $plurals;
            }
        }

        fclose($stream);

        return myMessages;
    }

    /**
     * Reads an unsigned long from stream respecting endianess.
     *
     * @param resource $stream The File being read.
     * @param bool $isBigEndian Whether the current platform is Big Endian
     * @return int
     */
    protected auto _readLong($stream, $isBigEndian): int
    {
        myResult = unpack($isBigEndian ? 'N1' : 'V1', fread($stream, 4));
        myResult = current(myResult);

        return (int)substr((string)myResult, -8);
    }
}
