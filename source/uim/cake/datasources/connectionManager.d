/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.datasources;

import uim.cake.core.StaticConfigTrait;
import uim.cake.databases.Connection;
import uim.cake.databases.Driver\Mysql;
import uim.cake.databases.Driver\Postgres;
import uim.cake.databases.Driver\Sqlite;
import uim.cake.databases.Driver\Sqlserver;
import uim.datasources.exceptions.MissingDatasourceConfigException;

