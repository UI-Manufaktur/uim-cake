module uim.cake.database.Type;

import uim.cake.I18n\I18nIDateTime;

/**
 * Time type converter.
 *
 * Use to convert time instances to strings & back.
 */
class TimeType : DateTimeType
{

    protected $_format = 'H:i:s';


    protected $_marshalFormats = [
        'H:i:s',
        'H:i',
    ];


    protected auto _parseLocaleValue(string myValue): ?I18nIDateTime
    {
        /** @psalm-var class-string<\Cake\I18n\I18nIDateTime> myClass */
        myClass = this._className;

        /** @psalm-suppress PossiblyInvalidArgument */
        return myClass::parseTime(myValue, this._localeMarshalFormat);
    }
}
