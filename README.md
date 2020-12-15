# openresty-filebrowser
Fileserver API for OpenResty

#### Dependencies 

 - luafilesystem
 - lua-resty-post
 
### Configuring openresty-filebrowser

While configuring your nginx, you will need to specify the _mediaPath_ value, so the API would know from where to serve your content.

```nginx
set $mediaPath '/hpfs/files';
```

This variable will be used in _media.conf_ file and in API itself.

 
### Browsing directory content

```
GET /media{path}
```
Returns a list of directories and files from your _mediaPath/{path}_ path in JSON format

Example: browsing /demo/ directory:

```
GET /media/demo
```

Response

```json
{
  "result":[
    {
      "mode": "directory",
      "item": "demo",
      "timestamp": 1607885051
    },
    {
      "mode": "file",
      "item": ".DS_Store",
      "timestamp": 1603740766,
      "size": 6148
    }
  ]
}
```
and 
API returns only resources of type _directory_ or _file_. Size information is available only for items of type _file_

### Getting the file

```
GET /media{path}{file}
```

### Uploading file

```
POST /media{pah}
```

Uploading file into mediaPath/{path}. If _path_ is not found it will be created within _mediaPath_ location.

### Renaming path

```
PUT /media{path}
```

Payload: 

```json
{
  "target": "{new_name}"
}
```

For example you want to rename directory _demo_ into _prod_, to make it happen, just send the follwoing PUT request:

```
PUT /media/demo
```
 
with payload
 
```json
{
  "target": "prod"
}
```
 

### Deleting file or directory

```
DELETE /media/{path}
```
