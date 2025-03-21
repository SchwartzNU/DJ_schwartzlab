function [] = reauthorize_gcal_connection(connection_name, authentication_code)
conn = fetch(secure.GcalConnection & sprintf('connection_name="%s"', connection_name), '*');

refresh_response = webwrite(...
    'https://oauth2.googleapis.com/token',...
    'grant_type','authorization_code',...
    'client_id',conn.client_id,...
    'client_secret',conn.client_secret,...
    'code',authentication_code,...
    'redirect_uri','urn:ietf:wg:oauth:2.0:oob'...
    );

key_refresh.token = refresh_response.refresh_token;
key_refresh.connection_name = connection_name;
insert(secure.RefreshToken, key_refresh);

key_access.token = refresh_response.access_token;
key_access.connection_name = connection_name;
insert(secure.AccessToken, key_access);
