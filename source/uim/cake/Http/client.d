

/**
 * UIM(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *



  */module uim.cake.Http;

import uim.cake.core.App;
import uim.cake.core.exceptions.UIMException;
import uim.cake.core.InstanceConfigTrait;
import uim.cake.http.Client\Adapter\Curl;
import uim.cake.http.Client\Adapter\Mock as MockAdapter;
import uim.cake.http.Client\Adapter\Stream;
import uim.cake.http.Client\AdapterInterface;
import uim.cake.http.Client\Request;
import uim.cake.http.Client\Response;
import uim.cake.http.Cookie\CookieCollection;
import uim.cake.http.Cookie\CookieInterface;
import uim.cake.utilities.Hash;
