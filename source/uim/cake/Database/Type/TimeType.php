


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)

 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.databases.Type;

import uim.cake.I18n\I18nDateTimeInterface;

/**
 * Time type converter.
 *
 * Use to convert time instances to strings & back.
 */
class TimeType : DateTimeType
{
    /**
     * @inheritDoc
     */
    protected $_format = 'H:i:s';

    /**
     * @inheritDoc
     */
    protected $_marshalFormats = [
        'H:i:s',
        'H:i',
    ];

    /**
     * @inheritDoc
     */
    protected function _parseLocaleValue(string $value): ?I18nDateTimeInterface
    {
        /** @psalm-var class-string<\Cake\I18n\I18nDateTimeInterface> $class */
        $class = _className;

        /** @psalm-suppress PossiblyInvalidArgument */
        return $class::parseTime($value, _localeMarshalFormat);
    }
}
