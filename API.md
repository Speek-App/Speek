# Introduction

The Speek-CLI provides an IPC (Inter-Process Communication) API, which enables communication between processes. This API uses QLocalSocket and JSON-formatted data for the communication and allows developers to integrate the functionality of Speek into their own programs and scripts.

Python was chosen for the examples because it is simple and convenient to use for data processing and scripting activities, which makes it a suitable fit for IPC communication. Additionally, it is a well liked option for developers because of its dynamic typing, sizable standard library, and widespread use.

Please note that this feature is still under development, and changes may be made to the API in the future. It is recommended to regularly check this documentation for updates and changes.

## Table of Contents
- [Connecting to the IPC Endpoint](#connecting-to-the-ipc-endpoint)
- [Data Format](#data-format)
- [API Methods](#api-methods)
  - [quit](#quit)
  - [getContacts](#getcontacts)
  - [sendMessage](#sendmessage)
  - [getId](#getid)
  - [createContactRequest](#createcontactrequest)
  - [acceptFileTransfer](#acceptfiletransfer)
  - [cancelFileTransfer](#cancelfiletransfer)
  - [rejectFileTransfer](#rejectfiletransfer)
  - [sendFile](#sendfile)
  - [removeContact](#removecontact)
  - [renameContact](#renamecontact)
  - [setIconContact](#seticoncontact)
  - [acceptContactRequest](#acceptcontactrequest)
  - [refuseContactRequestAndBlockUser](#refusecontactrequestandblockuser)
  - [refuseContactRequest](#refusecontactrequest)
  - [setNickname](#setnickname)
  - [getConfigLocation](#getconfiglocation)
  - [getAllContactRequests](#getallcontactrequests)
  - [getAllMessages](#getallmessages)
  - [getTorManagerInfo](#gettormanagerinfo)
  - [setPruneLimit](#setprunelimit)
  - [exportIdentity](#exportidentity)
  - [Error Handling](#error-handling)
- [Updating Data](#updating-data)
  - [Contact Requests](#contact-requests)
  - [Removing Contact Requests](#removing-contact-requests)
  - [Tor State Changed](#tor-state-changed)
  - [Updating Contact Status](#updating-contact-status)
  - [Messages](#messages)
  - [Enum Explanations](#enum-explanations)
    - [MessageStatus](#messagestatus)
    - [MessageDataType](#messagedatatype)
    - [TransferStatus](#transferstatus)
    - [TransferDirection](#transferdirection)
- [Reference Implementation](#reference-implementation)

# Connecting to the IPC Endpoint

```python
# Import the socket library
import socket

# Connect to the QLocalServer IPC endpoint
ipc_socket = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)

# Connect to the socket path
ipc_socket.connect("/tmp/SpeekServerIPC")
```

This code demonstrates how to connect to the QLocalServer IPC endpoint using the Python socket library. The socket library is used to create a new socket of type AF_UNIX and type SOCK_STREAM, which is a reliable, stream-oriented, full-duplex communication channel. The connect() function is then used to connect to the socket path "/tmp/SpeekServerIPC".

# Data Format

The incoming communication must be encoded as a JSON string that includes a "com" key, specifying the desired command to be executed. Before the JSON string, the version and the size of the data must be prepended in the following format:

```python
#data in this case is a string
def encode_request_data(version, data):
    """
    Encode the data before sending it via socket
    """
    # Encode the data as UTF-8 with a Byte Order Mark (BOM)
    encoded_data = data.encode('utf-8')

    # Combine the version and message size into a single bytearray
    combined = bytearray(struct.pack('!I', version)) + bytearray(struct.pack('!I', len(encoded_data))) + bytearray(encoded_data)

    return combined
```
The encoding process transforms the data into a UTF-8 encoded string, and then combines it with additional information such as the version (4 bytes) and the message size in bytes (4 bytes) to form a bytearray. 

The structure of the received data adheres to this pattern.

```python
def read_all_messages(socket):
    """
    Read all messages sent through the socket connection.
    """
    # Read the version of the data stream
    version = struct.unpack('!I', socket.recv(4))[0]

    # Read the size of the message
    block_size = struct.unpack('!I', socket.recv(4))[0]

    # Read the data of the message
    block = b''
    while len(block) < block_size:
        block += socket.recv(block_size - len(block))

    # Decode the message
    data_decoded = block.decode('utf-8', 'ignore')

    # Load the decoded message as JSON
    return json.loads(data_decoded)

def receive_updates(ipc_socket):
    """
    Receive updates from the IPC endpoint.
    """
    while True:
        # Read incoming messages
        json_data = read_all_messages(ipc_socket)

        # Check for the "what" key in the JSON data
        if "what" in json_data:
            if json_data["what"] == "whatever":
                # Do something

        # Check for the "com" key in the JSON data
        elif "com" in json_data:
            if json_data["com"] == "whatever":
                # Do something
```

# API Methods

All requests and responses sent to and from the API are in JSON format. Each response will contain a "status" key, which indicates the success or failure of the executed command. If the status is "fail", there will also be a "reason" key with a description of the error.

The data sent and received over the IPC endpoint can optionally include a token to help track which request the response belongs to. This token can be added as an additional key-value pair in the JSON string, allowing the client to easily match the response with the correct request.

The following is a list of the supported IPC commands, along with their required parameters and the structure of their response.

## quit

Stops the current process.
#### Request
```json
{
    "com": "quit",
    "token": "<token>" (optional)
}
```
#### Response
```json
{
    "com": "quit",
    "token": "<token>" (optional),
    "status": "success"
}
```

## getContacts

Retrieves a list of all contacts.
#### Request
```json
{
    "com": "getContacts",
    "token": "<token>" (optional)
}
```

#### Response
```json
{
    "status": "success",
    "com": "getContacts",
    "token": "<token>" (optional),
    "out": [
        {
            "id": "<contact_id>",
            "name": "<contact_name>",
            "is_group": <is_group>,
            "status": <status>
        },
        ...
    ]
}
```
The "status" field in the response from the "getContacts" command represents the current status of the contact and is represented by the "Status" enumeration. The "Status" enumeration contains the following possible values:

- Online: This status indicates that the contact is currently online.
- Offline: This status indicates that the contact is currently offline.
- RequestPending: This status indicates that there is a pending contact request from this user (e.g. user has not accepted the request yet).
- RequestRejected: This status indicates that a previous contact request from this user has been rejected.
- Outdated: This status indicates that the contact information is outdated and needs to be updated. (never used currently)

## sendMessage

Sends a message to a specified contact.
#### Request
```json
{
    "com": "sendMessage",
    "id": "<contact_id>",
    "message": "<message>",
    "token": "<token>" (optional)
}
```
#### Response

```json
{
    "status": "success",
    "com": "sendMessage",
    "token": "<token>" (optional)
}
```

## getId

Retrieves the current user's ID.
#### Request
```json
{
    "com": "getId",
    "token": "<token>" (optional)
}
```
#### Response
```json
{
    "status": "success",
    "id": "<user_id>",
    "com": "getId",
    "token": "<token>" (optional)
}
```
## createContactRequest

Adds a new contact.
#### Request
```json
{
    "com": "createContactRequest",
    "id": "<contact_id>",
    "name": "<contact_name>",
    "icon": "<icon_base64_png>", (optional)
    "token": "<token>" (optional)
}
```
#### Response
```json
{
    "status": "success",
    "com": "createContactRequest",
    "token": "<token>" (optional)
}
```

## acceptFileTransfer

Receive a file and save it to the specified "destination". Make sure that "destination" includes the complete file name, including its extension. It's not added automatically.

#### Request
```json
{
    "com": "acceptFileTransfer",
    "id": "<contact_id>",
    "file_id": "<file_id>",
    "destination": "<destination>",
    "token": "<token>" (optional)
}
```
#### Response
```json
{
    "status": "success",
    "com": "acceptFileTransfer",
    "token": "<token>" (optional)
}
```

## cancelFileTransfer

Cancel/abort an already started file transfer.
#### Request
```json
{
    "com": "cancelFileTransfer",
    "id": "<contact_id>",
    "file_id": "<file_id>",
    "token": "<token>" (optional)
}
```
#### Response
```json
{
    "status": "success",
    "com": "cancelFileTransfer",
    "token": "<token>" (optional)
}
```

## rejectFileTransfer

Reject a file transfer.
#### Request
```json
{
    "com": "rejectFileTransfer",
    "id": "<contact_id>",
    "file_id": "<file_id>",
    "token": "<token>" (optional)
}
```
#### Response
```json
{
    "status": "success",
    "com": "rejectFileTransfer",
    "token": "<token>" (optional)
}
```

## sendFile

Send a file transfer request to a contact.
#### Request
```json
{
    "com": "sendFile",
    "id": "<contact_id>",
    "source_file": "<source_file_path>",
    "token": "<token>" (optional)
}
```
#### Response
```json
{
    "status": "success",
    "com": "sendFile",
    "token": "<token>" (optional)
}
```

## removeContact

Remove a Contact.
#### Request
```json
{
    "com": "removeContact",
    "id": "<contact_id>",
    "token": "<token>" (optional)
}
```
#### Response
```json
{
    "status": "success",
    "com": "removeContact",
    "token": "<token>" (optional)
}
```

## renameContact

Renames a contact with the specified id.
#### Request

```json
{
    "com": "renameContact",
    "token": "<token>" (optional),
    "id": "<contact_id>",
    "nickname": "<new_contact_name>"
}
```

#### Response

```json
{
    "status": "success",
    "com": "renameContact",
    "token": "<token>" (optional)
}
```

## setIconContact

Sets the icon of a contact.
#### Request

```json
{
    "com": "setIconContact",
    "id": "<contact_id>",
    "icon": "<icon_path>",
    "token": "<token>" (optional)
}
```

#### Response

```json
{
    "status": "success",
    "com": "setIconContact",
    "token": "<token>" (optional),
}
```

## acceptContactRequest

Accepts an incoming contact request and adds the requester to the contact list.
#### Request

```json
{
    "com": "acceptContactRequest",
    "id": "<contact_id>",
    "nickname": "<contact_nickname>",
    "token": "<token>" (optional)
}
```

#### Response

```json
{
    "status": "success",
    "com": "acceptContactRequest",
    "token": "<token>" (optional)
}
```

Note: If the contact request with the specified "id" is not found, the response will contain a "status" key with a value of "fail" and a "reason" key with a description of the error. The same behaviour is for refuseContactRequestAndBlockUser and refuseContactRequest e.g:

```json
{
    "status": "fail",
    "com": "refuseContactRequestAndBlockUser",
    "token": "<token>" (optional),
    "reason": "No user found with this id"
}
```

## refuseContactRequestAndBlockUser

Rejects an incoming contact request and blocks the user from further requests.
#### Request

```json
{
    "com": "refuseContactRequestAndBlockUser",
    "id": "<contact_id>",
    "token": "<token>" (optional)
}
```

#### Response

```json
{
    "status": "success",
    "com": "refuseContactRequestAndBlockUser",
    "token": "<token>" (optional)
}
```

## refuseContactRequest

Rejects an incoming contact request.
#### Request

```json
{
    "com": "refuseContactRequest",
    "id": "<contact_id>",
    "token": "<token>" (optional)
}
```

#### Response

```json
{
    "status": "success",
    "com": "refuseContactRequest",
    "token": "<token>" (optional)
}
```

## setNickname

Sets your own nickname.
#### Request

```json
{
    "com": "setNickname",
    "nickname": "<nickname>",
    "token": "<token>" (optional)
}
```

#### Response

```json
{
    "status": "success",
    "com": "setNickname",
    "token": "<token>" (optional)
}
```

## getConfigLocation

Retrieves the location of the configuration directory.

#### Request

```json
{
    "com": "getConfigLocation",
    "token": "<token>" (optional)
}
```

#### Response

```json
{
    "status": "success",
    "com": "getConfigLocation",
    "token": "<token>" (optional),
    "config_location": "<config_directory_path>"
}
```

## getAllContactRequests

Is emitting a "contact_request" response for every incoming contact request (as described in the "Data Updates" section).
#### Request

```json
{
    "com": "getAllContactRequests",
    "token": "<token>" (optional)
}
```

#### Response

```json
{
    "status": "success",
    "com": "getAllContactRequests",
    "token": "<token>" (optional),
}
```

## getAllMessages

Is emitting a "message_update" response for every message (as described in the "Data Updates" section).
#### Request

```json
{
    "com": "getAllMessages",
    "token": "<token>" (optional)
}
```

#### Response

```json
{
    "status": "success",
    "com": "getAllMessages",
    "token": "<token>" (optional),
}
```

## getTorManagerInfo

Retrieves information about the status of the Tor Manager.
#### Request

```json
{
    "com": "getTorManagerInfo",
    "token": "<token>" (optional)
}
```

#### Response

```json
{
    "status": "success",
    "com": "getTorManagerInfo",
    "token": "<token>" (optional),
    "messages": [
        "<message_1>",
        "<message_2>",
        ...
    ],
    "configuration_needed": <configuration_needed>,
    "error_message": "<error_message>",
    "has_error": <has_error>
}
```

Where:
- messages is a list of log messages related to the Tor Manager
- configuration_needed is a boolean indicating if the Tor Manager needs to be configured
- error_message is a string containing the error message, if there is any error
- has_error is a boolean indicating if there is any error with the Tor Manager.

## setPruneLimit
Not implemented yet.

## exportIdentity
Not implemented yet.

## Error Handling

In case of any errors during the processing of a request, the response will contain a status field set to fail, and a reason field explaining the error.

```json
{
    "status": "fail",
    "reason": "<error_message>"
}
```

# Updating Data

The server is also sending updates which include new contact requests and messages. These updates are sent in the form of JSON objects, with specific keys and values representing different aspects of the update.

## Contact Requests

When a new contact request is received, the server sends the following JSON object:

```json
{
    "what": "contact_request",
    "id": "<contact_id>",
    "name": "<nickname>",
    "message": "<message>",
    "is_group": <true/false>,
    "incoming_request": true (can't be false at the moment)
}
```

## Removing Contact Requests

When a contact request is removed, the server sends the following JSON object:

```json
{
    "what": "contact_request_removed",
    "id": "<contact_id>"
}
```

## Tor State Changed

When the state of the Tor connection changes, the server sends the following JSON object:

```json
{
    "what": "tor_status_changed",
    "tor_control_status": "<tor_control_status>",
    "tor_network_status": "<tor_network_status>",
    "progress": <progress>,
    "tag": "<tag>",
    "summary": "<summary>",
    "tor_version": "<tor_version>",
    "error_message": "<error_message>"
}
```

The keys in the JSON object are as follows:

- what: This key is always set to "tor_status_changed", indicating that the object represents a change in the Tor connection state.
- tor_control_status: This key represents the status of the Tor control connection and can have the following values:
+ TorControlNotConnected (0): The Tor control connection is not connected.
+ TorControlConnecting (1): The Tor control connection is in the process of connecting.
+ TorControlAuthenticating (2): The Tor control connection is authenticating.
+ TorControlConnected (3): The Tor control connection is connected.
- tor_network_status: This key represents the status of the Tor network connection and can have the following values:
+ TorNetworkUnknown (0): The status of the Tor network connection is unknown.
+ TorNetworkOffline (1): The Tor network connection is offline.
+ TorNetworkReady (2): The Tor network connection is ready.
+ TorNetworkError (3): There was an error in the Tor network connection.
- progress: This key represents the progress of the bootstrapping process, in percentage.
- tag: This key represents the current stage of the bootstrapping process.
- summary: This key provides a summary of the current stage of the bootstrapping process.
- tor_version: This key represents the version of the Tor software.
- error_message: This key provides an error message if there was an error in the connection process.

## Updating Contact Status

When the status of a contact changes (e.g. going online), the server sends the following JSON object:

```json
{
    "what": "update_contact_status",
    "id": "<contact_id>",
    "name": "<nickname>",
    "is_group": <true/false>,
    "status": <status>
}
```

The status in the update_contact_status JSON object is represented by the Status enum. The Status enum contains the following possible values:

- Online: This status indicates that the contact is currently online.
- Offline: This status indicates that the contact is currently offline.
- RequestPending: This status indicates that there is a pending contact request from this user (e.g. user has not accepted the request yet).
- RequestRejected: This status indicates that a previous contact request from this user has been rejected.
- Outdated: This status indicates that the contact information is outdated and needs to be updated. (never used currently)

## Messages

When a new message is received or a message is changed, the server sends the following JSON object:

```json
{
    "what": "message_update",
    "type": <MessageDataType_enum_value>,
    "text": "<message_text>",
    "plaintext": "<plaintext_message>",
    "prep_text": "<prepared_text>",
    "group_user_nickname": "<group_user_nickname>",
    "group_user_id_hash": "<group_user_id_hash>",
    "time": "<timestamp>",
    "identifier": <identifier>,
    "status": <MessageStatus_enum_value>,
    "attemptCount": <attempt_count>,
    "fileName": "<file_name>",
    "fileSize": <file_size>,
    "fileHash": "<file_hash>",
    "bytesTransferred": <bytes_transferred>,
    "transferDirection": <TransferDirection_enum_value>,
    "transferStatus": <TransferStatus_enum_value>,
    "from_id": "<contact_id>",
    "from_name": "<contact_name>",
    "filePath": "<file_path>",
    "fileTransferPath": "<file_transfer_path>" (might be different from filePath on android),
    "image_caption": "<image_caption>" (only if type == 2),
    "image": "<image_base64>" (only if type == 2, excluding the "data:image/jpg;base64," component in the base64 encoding.),
}
```

#### Enum Explanations

##### MessageStatus:
+ 0: None: Message status is not set.
+ 1: Received: Message has been received.
+ 2: Queued: Message is queued for sending.
+ 3: Sending: Message is being sent.
+ 4: Delivered: Message has been delivered.
+ 5: Error: Error occurred while sending the message.

##### MessageDataType:
+ -1: InvalidMessage: Message type is invalid.
+ 0: TextMessage: Message is a text message.
+ 1: TransferMessage: Message is a file transfer.
+ 2: ImageMessage: Message is a image.

##### TransferStatus:
+ 0: InvalidTransfer: File transfer status is invalid.
+ 1: Pending: File transfer is pending.
+ 2: Accepted: File transfer has been accepted.
+ 3: Rejected: File transfer has been rejected.
+ 4: InProgress: File transfer is in progress.
+ 5: Cancelled: File transfer has been cancelled.
+ 6: Finished: File transfer has finished.
+ 7: UnknownFailure: File transfer failed with an unknown error.
+ 8: BadFileHash: File transfer failed due to a bad file hash.
+ 9: NetworkError: File transfer failed due to a network error.
+ 10: FileSystemError: File transfer failed due to a file system error.

##### TransferDirection:
+ 0: InvalidDirection: File transfer direction is invalid.
+ 1: Uploading: File is being uploaded.
+ 2: Downloading: File is being downloaded.

# Reference Implementation

The reference implementation for this API is written using Python and the curses library. This implementation provides a visual interface for the user to interact with the server, and serves as an example of how to use the server's API. It can be used as a starting point for those who want to write their own client software, or simply as a way to test and demonstrate the functionality of the server. The reference implementation is located in the `reference_implementation_api/` directory, and can be run using the command `python3 speek.py`. It requires the `curses` and other libraries, which can be installed using pip.

The reference implementation uses the Python curses library because it offers a simple interface for developing text-based user interfaces (TUI) in a terminal window. This is advantageous for the reference implementation since it eliminates the need for a graphical user interface and enables user interaction with the program through a straightforward text-based interface. It also enables the user to observe the interactions between the system's many parts.
