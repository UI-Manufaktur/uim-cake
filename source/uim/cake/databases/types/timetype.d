/*********************************************************************************************************
  Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
  License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
  Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.databases.Type;

import uim.cake.I18n\I18nDateTimeInterface;

/**
 * Time type converter.
 *
 * Use to convert time instances to strings & back.
 */
class TimeType : DateTimeType
{

    protected _format = "H:i:s";


    protected _marshalFormats = [
        "H:i:s",
        "H:i",
    ];


    protected function _parseLocaleValue(string aValue): ?I18nDateTimeInterface
    {
        /** @psalm-var class-string<uim.cake.I18n\I18nDateTimeInterface> $class */
        $class = _className;

        /** @psalm-suppress PossiblyInvalidArgument */
        return $class::parseTime($value, _localeMarshalFormat);
    }
}
