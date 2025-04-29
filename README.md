# Phonebook gRPC Service

The gRPC Phonebook System for adding, getting, deleting and listing contacts 

## 1. Project structure
```
.
├── gRPC.proto            # Protocol Buffer definition
├── client.py             # CLI client implementation
├── server.py             # gRPC server implementation
├── requirements.txt      # Python dependencies
└── contacts.json         # Generated data storage file
```

## 2. Usage
Installing dependencies:
```
pip install -r requirements.txt
```

In one terminal you should run:
```
python server/server.py
```

In other:
```
python client/client.py
```

Add a contact:

```
> add john 1234567890
Contact john added.
```

List contacts:

```
> list
john: 1234567890
```

Get a contact:

```
> get john
john: 1234567890
```

Delete a contact:

```
> delete john
Contact john deleted
```
