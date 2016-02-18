# test-api

API that supports creation, retrieval, and deletion of two types of objects: Assets and Notes. Assets have two fields: uri and name. Notes are attached to Assets and only have a note field.

To run server listening on localhost at port 5000: 
perl Server.pl 5000

The server will now respond to API requests to 127.0.0.1:5000, such as ‘curl --verbose 127.0.0.1:5000 /assets’.

Resources are identified by the requested endpoint and HTTP verbs are used to signify the desired action. Exchanged data is utf8 and json encoded. The implementation is in Perl 5 and was developed using Perl 5.16.3.

In order to simulate a webservice, Server.pl listens to requests on a specified port on the local host. These requests get funneled to the API which performs the requested operation and returns an HTTP response. The API code uses an in-memory datastore. To run the server listening to port 5000, run 'perl Server.pl 5000' from Server.pl's directory. You should receive a message stating that the server is listening on the specified port. It will now respond to HTTP requests. Here are some example curl requests:

create an asset with URI 'www.example.com' and name 'this is a name'
curl localhost:5000/assets -d'{"uri":"www.example.com","name":"this is a name"}'

list all assets
curl localhost:5000/assets

list asset with assetid == 2
curl localhost:5000/assets/2

search for asset with URI == 'www.example.com'
curl localhost:5000/assets?asset_uri=www.example.com

create a note for asset with assetid == 2
curl localhost:5000/assets/2/notes -d'{"note":"a2ndnote"}'

list all notes for asset with assetid == 2
curl localhost:5000/assets/2/notes 

delete asset with assetid == 2
curl localhost:5000/assets/2 -XDELETE

### Class overview 

Note that all concrete classes have associated unit test files (.t files) that can be run as perl scripts, e.g. ‘perl lib/AssetAPI.t’

*Server.pl* <port> <max queue size>: opens socket on specified port and services HTTP requests using AssetServer object

*AssetServer.pm*: thin layer to parse an HTTP request into HTTP method, URI, and request body. Uses AssetAPI to service the request and returns a string representation of an HTTP response.

*AssetAPI.pm*: business logic to handle API requests

*DataObject* and subclasses *DataObject/Asset.pm* and *DataObject/AssetNote.pm*: data model classes for Asset and Notes

*Datastore/Memory.pm*: in-memory datastore

*HTTPMessage.pm* and subclasses *HTTPMessage/Request.pm* and *HTTPMessage/Response.pm*: classes to handle parsing and building of HTTP requests and responses
