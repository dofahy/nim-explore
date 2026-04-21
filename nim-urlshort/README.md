sudo dnf install sqlite sqlite-devel sqlite-tcl\
nimble install db_connector

rm /tmp/test.db

./urlshort

curl -X POST http://localhost:5000/short -H "Content-Type: application/json" -d '{"url":"example.com"}'

{"id":"tzjgq"}

curl -4 -v http://localhost:5000/tzjgq

output

```
* Host localhost:5000 was resolved.
* IPv6: ::1
* IPv4: 127.0.0.1
*   Trying 127.0.0.1:5000...
* Connected to localhost (127.0.0.1) port 5000
* using HTTP/1.x
> GET /tzjgq HTTP/1.1
> Host: localhost:5000
> User-Agent: curl/8.15.0
> Accept: */*
> 
* Request completely sent off
< HTTP/1.1 302 Found
< location: http://example.com
< Content-Length: 0
< 
* Connection #0 to host localhost left intact

```
